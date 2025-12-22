import 'package:super_swipe/core/services/cloud_vision_service.dart';
import 'package:super_swipe/core/services/quota_service.dart';

/// Vision Service - Uses Cloud Vision API for accurate food detection
/// 
/// Strategy:
/// 1. Check quota before scanning (5 scans/week for free users)
/// 2. Use Cloud Vision for high-accuracy detection
/// 3. Require user confirmation before adding to pantry
/// 4. Track usage for cost control
class HybridVisionService {
  final CloudVisionService _cloudVision = CloudVisionService();
  final QuotaService _quotaService = QuotaService();

  bool _isInitialized = false;

  /// Initialize the service
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await _cloudVision.init();
      _isInitialized = true;
    } catch (e) {
      rethrow;
    }
  }

  /// Initialize user quota (call on first scan)
  Future<void> initializeUserQuota(String userId) async {
    await _quotaService.initializeUserQuota(userId);
  }

  /// Detect food items using Cloud Vision API
  /// Returns empty result if quota is exhausted
  Future<HybridDetectionResult> detectFoodItems({
    required String imagePath,
    required String userId,
  }) async {
    if (!_isInitialized) {
      throw Exception('Service not initialized. Call init() first.');
    }

    final overallStopwatch = Stopwatch()..start();

    try {
      // Step 1: Check quota status
      final quotaStatus = await _quotaService.checkQuota(userId);

      // Step 2: Check if user can use Cloud Vision
      if (!quotaStatus.canUseCloudVision) {
        overallStopwatch.stop();
        
        return HybridDetectionResult(
          items: [],
          aiSource: AISource.cloudVision,
          quotaStatus: quotaStatus,
          processingTimeMs: overallStopwatch.elapsedMilliseconds,
          degradationReason: 'You\'ve used all your scans for this week. '
              'Try adding items manually or wait for your quota to reset.',
          quotaExhausted: true,
        );
      }

      // Step 3: Use Cloud Vision for accurate detection
      final cloudVisionResult = await _cloudVision.detectFoodItems(imagePath);

      final result = HybridDetectionResult(
        items: cloudVisionResult
            .map(
              (item) => HybridFoodItem(
                name: item.name,
                confidence: item.confidence,
                quantity: item.quantity,
              ),
            )
            .toList(),
        aiSource: AISource.cloudVision,
        quotaStatus: quotaStatus,
        processingTimeMs: overallStopwatch.elapsedMilliseconds,
        degradationReason: null,
        quotaExhausted: false,
      );

      // Record usage
      await _quotaService.recordUsage(
        userId: userId,
        usedCloudVision: true,
        itemsDetected: result.items.length,
        confidence: result.averageConfidence,
        processingTimeMs: result.processingTimeMs,
      );

      overallStopwatch.stop();

      return result;
    } catch (e) {
      rethrow;
    }
  }

  /// Get user's usage statistics
  Future<UsageStats> getUserStats(String userId) async {
    return await _quotaService.getStats(userId);
  }

  /// Get current quota status
  Future<QuotaStatus> getQuotaStatus(String userId) async {
    return await _quotaService.checkQuota(userId);
  }

  /// Dispose resources
  Future<void> dispose() async {
    _isInitialized = false;
  }
}

/// Result from detection
class HybridDetectionResult {
  final List<HybridFoodItem> items;
  final AISource aiSource;
  final QuotaStatus quotaStatus;
  final int processingTimeMs;
  final String? degradationReason;
  final bool quotaExhausted;

  HybridDetectionResult({
    required this.items,
    required this.aiSource,
    required this.quotaStatus,
    required this.processingTimeMs,
    this.degradationReason,
    this.quotaExhausted = false,
  });

  double get averageConfidence {
    if (items.isEmpty) return 0.0;
    return items.map((item) => item.confidence).reduce((a, b) => a + b) /
        items.length;
  }

  bool get isDegraded => degradationReason != null;
}

/// Food item from detection
class HybridFoodItem {
  final String name;
  final double confidence;
  final int quantity;

  HybridFoodItem({
    required this.name,
    required this.confidence,
    required this.quantity,
  });

  String toDisplayString() {
    return quantity > 1 ? '$name x$quantity' : name;
  }
}

/// AI source used for detection
enum AISource {
  cloudVision('Cloud Vision AI', '☁️');

  final String displayName;
  final String icon;

  const AISource(this.displayName, this.icon);
}
