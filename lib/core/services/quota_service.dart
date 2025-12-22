import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:super_swipe/core/models/daily_quota_summary.dart';

/// Quota Service for managing Cloud Vision API usage and costs
/// Enforces daily/monthly limits with graceful degradation
/// Optimized for Firestore costs: O(1) reads, atomic writes
class QuotaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cost per Cloud Vision API call (approximate)
  static const double _costPerCloudVisionCall = 0.0015; // $1.50 per 1000 calls

  // Free user quotas (strict limits)
  static const int _freeDailyLimit = 10; // 10 scans/day for free users
  static const int _freeMonthlyLimit = 300; // 300 scans/month for free users

  // Premium user quotas (higher limits)
  static const int _premiumDailyLimit = 100; // 100 scans/day for premium
  static const int _premiumMonthlyLimit = 1000; // 1000 scans/month for premium

  // Fallback defaults
  static const int _defaultDailyLimit = 10;
  static const int _defaultMonthlyLimit = 100;

  /// Stream current daily quota usage (Real-time, O(1) read)
  Stream<DailyQuotaSummary> watchDailyQuota(String userId) {
    final todayKey = _getDateKey(DateTime.now());
    final docId = '${userId}_$todayKey';

    return _firestore
        .collection('vision_quota_summaries')
        .doc(docId)
        .snapshots()
        .map((doc) => DailyQuotaSummary.fromFirestore(doc));
  }

  /// Check if user can use Cloud Vision API (Optimized)
  Future<QuotaStatus> checkQuota(String userId) async {
    try {
      final now = DateTime.now();
      final todayKey = _getDateKey(now);

      // Get user's custom limits (Cached/One-time fetch usually)
      final userLimits = await _getUserLimits(userId);

      // Get O(1) summary for today
      // Note: For monthly, we might still need aggregation or a monthly summary doc.
      // For now, keeping monthly logic simple or assuming daily is the primary gate.
      final summaryDoc = await _firestore
          .collection('vision_quota_summaries')
          .doc('${userId}_$todayKey')
          .get();

      final dailySummary = DailyQuotaSummary.fromFirestore(summaryDoc);

      // Simple Monthly Estimation (if we don't have a monthly summary yet)
      // For strict cost control, we should ideally have a monthly summary too.
      // Falls back to legacy query if strictly needed, or just relying on daily limit for now.
      // Keeping legacy monthly check for safety but optimizing daily.
      final monthlyUsage = await _getMonthlyUsageCount(userId, now);
      // final monthlyUsage = 0; // Optimization: Disabled O(N) monthly check to save costs and unblock dev

      final dailyUsage = dailySummary.usedCloudVision;

      final status = QuotaStatus(
        canUseCloudVision:
            dailyUsage < userLimits['daily']! &&
            monthlyUsage < userLimits['monthly']!,
        dailyUsage: dailyUsage,
        dailyLimit: userLimits['daily']!,
        monthlyUsage: monthlyUsage,
        monthlyLimit: userLimits['monthly']!,
        estimatedMonthlyCost: monthlyUsage * _costPerCloudVisionCall,
        willDegrade:
            dailyUsage >= (userLimits['daily']! * 0.8) ||
            monthlyUsage >= (userLimits['monthly']! * 0.8),
      );

      return status;
    } catch (e) {
      // On error, fail safe (allow ML Kit only)
      return QuotaStatus(
        canUseCloudVision: false,
        dailyUsage: 0,
        dailyLimit: _defaultDailyLimit,
        monthlyUsage: 0,
        monthlyLimit: _defaultMonthlyLimit,
        estimatedMonthlyCost: 0,
        willDegrade: false,
      );
    }
  }

  // Helper to format date key
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Record a vision API usage (Atomic increment)
  Future<void> recordUsage({
    required String userId,
    required bool usedCloudVision,
    required int itemsDetected,
    required double confidence,
    required int processingTimeMs,
  }) async {
    try {
      final now = DateTime.now();
      final todayKey = _getDateKey(now);
      final summaryRef = _firestore
          .collection('vision_quota_summaries')
          .doc('${userId}_$todayKey');
      final logRef = _firestore.collection('vision_usage').doc();
      final userRef = _firestore.collection('users').doc(userId);

      // Get current limits to snapshot into summary
      final limits = await _getUserLimits(userId);
      final dailyLimit = limits['daily'] ?? _freeDailyLimit;

      await _firestore.runTransaction((transaction) async {
        // 1. Get current summary state (Read)
        final summarySnapshot = await transaction.get(summaryRef);
        int currentCloudVisionScans = 0;
        int currentMlKitScans = 0;
        int currentTotalScans = 0;

        if (summarySnapshot.exists && summarySnapshot.data() != null) {
          final data = summarySnapshot.data() as Map<String, dynamic>;
          currentCloudVisionScans =
              (data['cloudVisionScans'] ?? data['usedCloudVision'] ?? 0) as int;
          currentMlKitScans =
              (data['mlKitScans'] ?? data['usedMLKit'] ?? 0) as int;
          currentTotalScans = (data['totalScans'] ?? 0) as int;
        }

        // 2. Calculate new values
        final newCloudVisionScans =
            currentCloudVisionScans + (usedCloudVision ? 1 : 0);
        final newMlKitScans = currentMlKitScans + (usedCloudVision ? 0 : 1);
        final newTotalScans = currentTotalScans + 1;
        final newQuotaRemaining = dailyLimit - newCloudVisionScans;

        // 3. Create Immutable Log matches legacy naming if possible
        transaction.set(logRef, {
          'userId': userId,
          'usedCloudVision': usedCloudVision,
          'cloudVisionScans': usedCloudVision ? 1 : 0, // Legacy compat
          'itemsDetected': itemsDetected,
          'averageConfidence': confidence,
          'processingTimeMs': processingTimeMs,
          'timestamp': FieldValue.serverTimestamp(),
          'cost': usedCloudVision ? _costPerCloudVisionCall : 0.0,
        });

        // 4. Write Summary with calculated fields
        transaction.set(summaryRef, {
          'userId': userId,
          'dateKey': todayKey,
          'date': FieldValue.serverTimestamp(),
          'totalScans': newTotalScans,
          'cloudVisionScans': newCloudVisionScans,
          'mlKitScans': newMlKitScans,
          'dailyLimit': dailyLimit,
          'quotaRemaining': newQuotaRemaining > 0 ? newQuotaRemaining : 0,
          'estimatedCost': newCloudVisionScans * _costPerCloudVisionCall,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // 5. Update User Aggregate Stats
        transaction.set(userRef, {
          'stats': {'scanCount': FieldValue.increment(1)},
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    } catch (e) {
      print('❌ Failed to record usage: $e');
      rethrow;
    }
  }

  /// Get monthly usage (Keep this O(N) for now but cache result if needed, or implement monthly summary later)
  /// Optimized to only count cloud vision docs
  Future<int> _getMonthlyUsageCount(String userId, DateTime now) async {
    try {
      final monthStart = DateTime(now.year, now.month, 1);

      // Optimization: This is still O(N) but run less frequently (only on start check)
      // Ideally move to 'vision_quota_monthly_summaries' in future.
      final snapshot = await _firestore
          .collection('vision_usage')
          .where('userId', isEqualTo: userId)
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart),
          )
          .where(
            'usedCloudVision',
            isEqualTo: true,
          ) // Only count expensive ones
          .count() // Use count() aggregation query which is cheaper than get()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get user's subscription status from users collection
  Future<String> _getUserSubscriptionStatus(String userId) async {
    try {
      // Use efficient source: cache first?
      // For subscription, we want fresh data usually.
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final data = userDoc.data();
        final subscriptionStatus =
            data?['subscriptionStatus'] as String? ?? 'free';
        return subscriptionStatus;
      }
    } catch (e) {
      // ignore
    }
    return 'free';
  }

  /// Get user's custom limits or defaults
  Future<Map<String, int>> _getUserLimits(String userId) async {
    try {
      // Check custom quota overrides (Cached if possible)
      final quotaDoc = await _firestore
          .collection('user_quotas')
          .doc(userId)
          .get(const GetOptions(source: Source.serverAndCache)); // Optimization

      if (quotaDoc.exists) {
        final data = quotaDoc.data()!;
        final customDaily = data['dailyLimit'] as int?;
        final customMonthly = data['monthlyLimit'] as int?;

        if (customDaily != null && customMonthly != null) {
          return {'daily': customDaily, 'monthly': customMonthly};
        }
      }

      final subscriptionStatus = await _getUserSubscriptionStatus(userId);

      if (subscriptionStatus == 'premium' || subscriptionStatus == 'pro') {
        return {'daily': _premiumDailyLimit, 'monthly': _premiumMonthlyLimit};
      } else {
        return {'daily': _freeDailyLimit, 'monthly': _freeMonthlyLimit};
      }
    } catch (e) {
      // ignore
    }

    return {'daily': _defaultDailyLimit, 'monthly': _defaultMonthlyLimit};
  }

  /// Get user's usage statistics
  Future<UsageStats> getStats(String userId) async {
    // Stats page can afford O(N) read since it's rarely accessed
    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);

      final snapshot = await _firestore
          .collection('vision_usage')
          .where('userId', isEqualTo: userId)
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart),
          )
          .get();

      int totalScans = snapshot.docs.length;
      int cloudVisionScans = 0;
      int mlKitScans = 0;
      double totalCost = 0.0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['usedCloudVision'] == true) {
          cloudVisionScans++;
          totalCost +=
              (data['cost'] as num?)?.toDouble() ?? _costPerCloudVisionCall;
        } else {
          mlKitScans++;
        }
      }

      return UsageStats(
        totalScans: totalScans,
        cloudVisionScans: cloudVisionScans,
        mlKitScans: mlKitScans,
        totalCost: totalCost,
        periodStart: monthStart,
      );
    } catch (e) {
      return UsageStats(
        totalScans: 0,
        cloudVisionScans: 0,
        mlKitScans: 0,
        totalCost: 0.0,
        periodStart: DateTime.now(),
      );
    }
  }

  /// Initialize default quota for a new user
  Future<void> initializeUserQuota(String userId) async {
    try {
      final quotaDoc = await _firestore
          .collection('user_quotas')
          .doc(userId)
          .get();

      if (!quotaDoc.exists) {
        await _firestore.collection('user_quotas').doc(userId).set({
          'dailyLimit': _freeDailyLimit,
          'monthlyLimit': _freeMonthlyLimit,
          'subscriptionTier': 'free',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // ignore
    }
  }

  /// Update user's custom limits (admin function)
  Future<void> updateUserLimits({
    required String userId,
    int? dailyLimit,
    int? monthlyLimit,
    String? subscriptionTier,
  }) async {
    try {
      await _firestore.collection('user_quotas').doc(userId).set({
        if (dailyLimit != null) 'dailyLimit': dailyLimit,
        if (monthlyLimit != null) 'monthlyLimit': monthlyLimit,
        if (subscriptionTier != null) 'subscriptionTier': subscriptionTier,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  /// Upgrade user to premium
  Future<void> upgradeToPremium(String userId) async {
    try {
      await updateUserLimits(
        userId: userId,
        dailyLimit: _premiumDailyLimit,
        monthlyLimit: _premiumMonthlyLimit,
        subscriptionTier: 'premium',
      );

      await _firestore.collection('users').doc(userId).update({
        'subscriptionStatus': 'premium',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }
}

/// Current quota status for a user
class QuotaStatus {
  final bool canUseCloudVision;
  final int dailyUsage;
  final int dailyLimit;
  final int monthlyUsage;
  final int monthlyLimit;
  final double estimatedMonthlyCost;
  final bool willDegrade; // Warning threshold (80% of limit)

  QuotaStatus({
    required this.canUseCloudVision,
    required this.dailyUsage,
    required this.dailyLimit,
    required this.monthlyUsage,
    required this.monthlyLimit,
    required this.estimatedMonthlyCost,
    required this.willDegrade,
  });

  double get dailyPercentage => dailyLimit > 0 ? dailyUsage / dailyLimit : 0.0;
  double get monthlyPercentage =>
      monthlyLimit > 0 ? monthlyUsage / monthlyLimit : 0.0;

  String get dailyStatus => '$dailyUsage / $dailyLimit scans today';
  String get monthlyStatus =>
      '$monthlyUsage / $monthlyLimit scans this month (\$${estimatedMonthlyCost.toStringAsFixed(2)})';
}

/// Usage statistics for a period
class UsageStats {
  final int totalScans;
  final int cloudVisionScans;
  final int mlKitScans;
  final double totalCost;
  final DateTime periodStart;

  UsageStats({
    required this.totalScans,
    required this.cloudVisionScans,
    required this.mlKitScans,
    required this.totalCost,
    required this.periodStart,
  });

  double get cloudVisionPercentage =>
      totalScans > 0 ? cloudVisionScans / totalScans : 0.0;
  double get mlKitPercentage => totalScans > 0 ? mlKitScans / totalScans : 0.0;
}
