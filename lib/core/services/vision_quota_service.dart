import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages Cloud Vision API quota with predictable cost controls.
/// 
/// **Cost Management Strategy:**
/// - Daily quota: 100 requests (adjustable)
/// - Monthly quota: 2000 requests (adjustable)
/// - Graceful degradation: ML Kit fallback when quota exhausted
/// - Reset schedule: Daily at midnight, monthly on 1st
/// 
/// **Estimated Costs** (as of Dec 2024):
/// - Cloud Vision: ~$1.50 per 1000 requests
/// - Daily limit (100): ~$0.15/day = ~$4.50/month
/// - Monthly limit (2000): ~$3/month total
class VisionQuotaService {
  static const String _keyDailyCount = 'vision_daily_count';
  static const String _keyDailyDate = 'vision_daily_date';
  static const String _keyMonthlyCount = 'vision_monthly_count';
  static const String _keyMonthlyMonth = 'vision_monthly_month';
  
  // Cost control limits (adjust based on budget)
  static const int dailyQuota = 100;    // ~$0.15/day
  static const int monthlyQuota = 2000; // ~$3/month
  
  // Warning thresholds for UI feedback
  static const double warningThreshold = 0.8;  // 80%
  static const double criticalThreshold = 0.95; // 95%
  
  SharedPreferences? _prefs;
  
  /// Initialize the quota service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _checkAndResetQuotas();
  }
  
  /// Check if Cloud Vision can be used (quota available)
  Future<bool> canUseCloudVision() async {
    await _checkAndResetQuotas();
    
    final dailyCount = await getDailyCount();
    final monthlyCount = await getMonthlyCount();
    
    final hasDaily = dailyCount < dailyQuota;
    final hasMonthly = monthlyCount < monthlyQuota;
    
    if (!hasDaily || !hasMonthly) {
      debugPrint('🚫 Cloud Vision quota exhausted: daily=$dailyCount/$dailyQuota, monthly=$monthlyCount/$monthlyQuota');
    }
    
    return hasDaily && hasMonthly;
  }
  
  /// Increment usage count (call after successful Cloud Vision request)
  Future<void> incrementUsage() async {
    final dailyCount = await getDailyCount();
    final monthlyCount = await getMonthlyCount();
    
    await _prefs?.setInt(_keyDailyCount, dailyCount + 1);
    await _prefs?.setInt(_keyMonthlyCount, monthlyCount + 1);
    
    debugPrint('☁️ Cloud Vision used: daily=${dailyCount + 1}/$dailyQuota, monthly=${monthlyCount + 1}/$monthlyQuota');
    
    // Log warnings when approaching limits
    final dailyPercent = (dailyCount + 1) / dailyQuota;
    final monthlyPercent = (monthlyCount + 1) / monthlyQuota;
    
    if (dailyPercent >= criticalThreshold || monthlyPercent >= criticalThreshold) {
      debugPrint('⚠️ CRITICAL: Cloud Vision quota nearly exhausted!');
    } else if (dailyPercent >= warningThreshold || monthlyPercent >= warningThreshold) {
      debugPrint('⚠️ WARNING: Cloud Vision quota at 80%+');
    }
  }
  
  /// Get current daily usage count
  Future<int> getDailyCount() async {
    return _prefs?.getInt(_keyDailyCount) ?? 0;
  }
  
  /// Get current monthly usage count
  Future<int> getMonthlyCount() async {
    return _prefs?.getInt(_keyMonthlyCount) ?? 0;
  }
  
  /// Get quota status for UI display
  Future<QuotaStatus> getQuotaStatus() async {
    await _checkAndResetQuotas();
    
    final dailyCount = await getDailyCount();
    final monthlyCount = await getMonthlyCount();
    
    final dailyPercent = dailyCount / dailyQuota;
    final monthlyPercent = monthlyCount / monthlyQuota;
    
    final level = _getQuotaLevel(dailyPercent, monthlyPercent);
    
    return QuotaStatus(
      dailyUsed: dailyCount,
      dailyLimit: dailyQuota,
      monthlyUsed: monthlyCount,
      monthlyLimit: monthlyQuota,
      level: level,
      canUseCloudVision: dailyCount < dailyQuota && monthlyCount < monthlyQuota,
    );
  }
  
  QuotaLevel _getQuotaLevel(double dailyPercent, double monthlyPercent) {
    final maxPercent = dailyPercent > monthlyPercent ? dailyPercent : monthlyPercent;
    
    if (maxPercent >= 1.0) return QuotaLevel.exhausted;
    if (maxPercent >= criticalThreshold) return QuotaLevel.critical;
    if (maxPercent >= warningThreshold) return QuotaLevel.warning;
    return QuotaLevel.normal;
  }
  
  /// Check if quotas need to be reset (daily/monthly)
  Future<void> _checkAndResetQuotas() async {
    final now = DateTime.now();
    
    // Check daily reset
    final lastDaily = _prefs?.getString(_keyDailyDate);
    final todayKey = '${now.year}-${now.month}-${now.day}';
    
    if (lastDaily != todayKey) {
      debugPrint('🔄 Resetting daily Cloud Vision quota');
      await _prefs?.setInt(_keyDailyCount, 0);
      await _prefs?.setString(_keyDailyDate, todayKey);
    }
    
    // Check monthly reset
    final lastMonthly = _prefs?.getString(_keyMonthlyMonth);
    final monthKey = '${now.year}-${now.month}';
    
    if (lastMonthly != monthKey) {
      debugPrint('🔄 Resetting monthly Cloud Vision quota');
      await _prefs?.setInt(_keyMonthlyCount, 0);
      await _prefs?.setString(_keyMonthlyMonth, monthKey);
    }
  }
  
  /// Reset quotas manually (for testing)
  Future<void> resetQuotas() async {
    await _prefs?.setInt(_keyDailyCount, 0);
    await _prefs?.setInt(_keyMonthlyCount, 0);
    debugPrint('🔄 Quotas reset manually');
  }
}

/// Current quota status
class QuotaStatus {
  final int dailyUsed;
  final int dailyLimit;
  final int monthlyUsed;
  final int monthlyLimit;
  final QuotaLevel level;
  final bool canUseCloudVision;
  
  QuotaStatus({
    required this.dailyUsed,
    required this.dailyLimit,
    required this.monthlyUsed,
    required this.monthlyLimit,
    required this.level,
    required this.canUseCloudVision,
  });
  
  double get dailyPercent => dailyUsed / dailyLimit;
  double get monthlyPercent => monthlyUsed / monthlyLimit;
  
  String get statusMessage {
    switch (level) {
      case QuotaLevel.normal:
        return 'Using enhanced AI scanning';
      case QuotaLevel.warning:
        return 'Enhanced AI: ${dailyLimit - dailyUsed} scans remaining today';
      case QuotaLevel.critical:
        return 'Enhanced AI: Almost at daily limit';
      case QuotaLevel.exhausted:
        return 'Using standard AI (quota refreshes daily)';
    }
  }
}

enum QuotaLevel {
  normal,    // < 80%
  warning,   // 80-95%
  critical,  // 95-100%
  exhausted, // 100%+
}


