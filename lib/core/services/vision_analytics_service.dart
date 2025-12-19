import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:super_swipe/core/models/vision_scan_log.dart';

/// Service for tracking vision API usage and analytics in Firestore
class VisionAnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Firestore collection references
  CollectionReference<Map<String, dynamic>> get _scanLogsCollection =>
      _firestore.collection('vision_scan_logs');

  CollectionReference<Map<String, dynamic>> get _quotaSummariesCollection =>
      _firestore.collection('vision_quota_summaries');

  CollectionReference<Map<String, dynamic>> get _userQuotaSettingsCollection =>
      _firestore.collection('vision_user_quota_settings');

  /// Log a scan to Firestore for analytics
  Future<void> logScan({
    required String userId,
    required VisionSourceType source,
    required int itemsDetected,
    required double averageConfidence,
    required int objectCount,
    String? escalationReason,
    required bool quotaAvailable,
    required double processingTimeMs,
  }) async {
    try {
      final log = VisionScanLog(
        id: '', // Will be auto-generated
        userId: userId,
        timestamp: DateTime.now(),
        source: source,
        itemsDetected: itemsDetected,
        averageConfidence: averageConfidence,
        objectCount: objectCount,
        escalationReason: escalationReason,
        quotaAvailable: quotaAvailable,
        processingTimeMs: processingTimeMs,
      );

      await _scanLogsCollection.add(log.toFirestore());

      // Update daily summary asynchronously
      _updateDailySummary(userId, source).ignore();

      if (kDebugMode) {
        debugPrint('📊 Vision scan logged: ${source.name} ($itemsDetected items)');
      }
    } catch (e) {
      // Don't fail the scan if logging fails
      debugPrint('⚠️ Failed to log vision scan: $e');
    }
  }

  /// Update daily quota summary
  Future<void> _updateDailySummary(
    String userId,
    VisionSourceType source,
  ) async {
    try {
      final today = DateTime.now();
      final dateKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final docId = '${userId}_$dateKey';

      final docRef = _quotaSummariesCollection.doc(docId);
      final doc = await docRef.get();

      if (doc.exists) {
        // Update existing summary
        final data = doc.data()!;
        final totalScans = (data['totalScans'] as int? ?? 0) + 1;
        final mlKitScans = source == VisionSourceType.mlKit ||
                source == VisionSourceType.mlKitFallback
            ? (data['mlKitScans'] as int? ?? 0) + 1
            : (data['mlKitScans'] as int? ?? 0);
        final cloudVisionScans = source == VisionSourceType.cloudVision
            ? (data['cloudVisionScans'] as int? ?? 0) + 1
            : (data['cloudVisionScans'] as int? ?? 0);
        final fallbackScans = source == VisionSourceType.mlKitFallback
            ? (data['fallbackScans'] as int? ?? 0) + 1
            : (data['fallbackScans'] as int? ?? 0);

        // Estimate cost: ~$0.0015 per Cloud Vision request
        final estimatedCost = cloudVisionScans * 0.0015;

        await docRef.update({
          'totalScans': totalScans,
          'mlKitScans': mlKitScans,
          'cloudVisionScans': cloudVisionScans,
          'fallbackScans': fallbackScans,
          'estimatedCost': estimatedCost,
        });
      } else {
        // Create new summary
        final summary = QuotaUsageSummary(
          id: docId,
          date: today,
          totalScans: 1,
          mlKitScans: source == VisionSourceType.mlKit ||
                  source == VisionSourceType.mlKitFallback
              ? 1
              : 0,
          cloudVisionScans: source == VisionSourceType.cloudVision ? 1 : 0,
          fallbackScans: source == VisionSourceType.mlKitFallback ? 1 : 0,
          estimatedCost: source == VisionSourceType.cloudVision ? 0.0015 : 0.0,
          quotaRemaining: 100 - (source == VisionSourceType.cloudVision ? 1 : 0),
        );

        await docRef.set(summary.toFirestore());
      }
    } catch (e) {
      debugPrint('⚠️ Failed to update daily summary: $e');
    }
  }

  /// Get user's quota settings (or create default)
  Future<UserQuotaSettings> getUserQuotaSettings(String userId) async {
    try {
      final doc = await _userQuotaSettingsCollection.doc(userId).get();

      if (doc.exists) {
        return UserQuotaSettings.fromFirestore(doc);
      } else {
        // Create default settings
        final defaultSettings = UserQuotaSettings.defaultSettings(userId);
        await _userQuotaSettingsCollection
            .doc(userId)
            .set(defaultSettings.toFirestore());
        return defaultSettings;
      }
    } catch (e) {
      debugPrint('⚠️ Failed to get quota settings: $e');
      return UserQuotaSettings.defaultSettings(userId);
    }
  }

  /// Update user's quota settings (for premium upgrades)
  Future<void> updateUserQuotaSettings(UserQuotaSettings settings) async {
    try {
      await _userQuotaSettingsCollection
          .doc(settings.userId)
          .set(settings.toFirestore(), SetOptions(merge: true));

      if (kDebugMode) {
        debugPrint(
          '✅ Updated quota settings for ${settings.userId}: daily=${settings.dailyLimit}, monthly=${settings.monthlyLimit}',
        );
      }
    } catch (e) {
      debugPrint('⚠️ Failed to update quota settings: $e');
    }
  }

  /// Get daily usage summary for a user
  Future<QuotaUsageSummary?> getDailySummary(String userId) async {
    try {
      final today = DateTime.now();
      final dateKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final docId = '${userId}_$dateKey';

      final doc = await _quotaSummariesCollection.doc(docId).get();

      if (doc.exists) {
        return QuotaUsageSummary.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('⚠️ Failed to get daily summary: $e');
      return null;
    }
  }

  /// Get scan history for analytics (last N days)
  Future<List<VisionScanLog>> getScanHistory({
    required String userId,
    int days = 7,
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      final snapshot = await _scanLogsCollection
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(cutoffDate))
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      return snapshot.docs.map((doc) => VisionScanLog.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('⚠️ Failed to get scan history: $e');
      return [];
    }
  }

  /// Get usage statistics for display
  Future<Map<String, dynamic>> getUsageStats(String userId) async {
    try {
      final summary = await getDailySummary(userId);

      if (summary != null) {
        return {
          'totalScans': summary.totalScans,
          'mlKitScans': summary.mlKitScans,
          'cloudVisionScans': summary.cloudVisionScans,
          'fallbackScans': summary.fallbackScans,
          'estimatedCost': summary.estimatedCost,
          'mlKitPercentage':
              summary.totalScans > 0 ? (summary.mlKitScans / summary.totalScans) * 100 : 0,
          'cloudVisionPercentage': summary.totalScans > 0
              ? (summary.cloudVisionScans / summary.totalScans) * 100
              : 0,
        };
      }

      return {
        'totalScans': 0,
        'mlKitScans': 0,
        'cloudVisionScans': 0,
        'fallbackScans': 0,
        'estimatedCost': 0.0,
        'mlKitPercentage': 0.0,
        'cloudVisionPercentage': 0.0,
      };
    } catch (e) {
      debugPrint('⚠️ Failed to get usage stats: $e');
      return {};
    }
  }

  /// Clean up old logs (call periodically, e.g., monthly)
  Future<void> cleanupOldLogs({int keepDays = 90}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: keepDays));

      final snapshot = await _scanLogsCollection
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .limit(500)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      if (kDebugMode) {
        debugPrint('🧹 Cleaned up ${snapshot.docs.length} old vision scan logs');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to cleanup old logs: $e');
    }
  }
}

