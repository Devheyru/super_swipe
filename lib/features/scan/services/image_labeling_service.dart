import 'package:flutter/foundation.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:super_swipe/core/services/hybrid_vision_service.dart';
import 'package:super_swipe/core/services/vision_quota_service.dart';

/// Image labeling service using hybrid AI approach:
/// - ML Kit (free) for standard scans
/// - Cloud Vision (paid) for complex/low-confidence scans
/// - Intelligent cost controls and graceful degradation
class ImageLabelingService {
  late final HybridVisionService _hybridVision;
  late final VisionQuotaService _quotaService;

  VisionSource? lastUsedSource;
  String? lastResultReason;

  ImageLabelingService() {
    _quotaService = VisionQuotaService();
    _hybridVision = HybridVisionService(_quotaService);
  }

  /// Initialize the service with user ID for analytics
  Future<void> init({String? userId}) async {
    await _hybridVision.init();
    if (userId != null) {
      _hybridVision.setUserId(userId);
    }
  }

  /// Set user ID for analytics tracking
  void setUserId(String userId) {
    _hybridVision.setUserId(userId);
  }

  /// Get current quota status for UI display
  Future<QuotaStatus> getQuotaStatus() async {
    return await _quotaService.getQuotaStatus();
  }

  /// Process image and return detected food items
  Future<List<String>> processImage(InputImage inputImage) async {
    try {
      if (kDebugMode) {
        debugPrint('════════════════════════════════════════');
        debugPrint('🔍 HYBRID VISION: Starting image analysis...');
      }

      // Use hybrid vision service (intelligently chooses ML Kit or Cloud Vision)
      final result = await _hybridVision.processImage(inputImage);

      // Store metadata for UI display
      lastUsedSource = result.source;
      lastResultReason = result.reason;

      if (kDebugMode) {
        final sourceIcon = _getSourceIcon(result.source);
        debugPrint('$sourceIcon Source: ${_getSourceName(result.source)}');
        debugPrint(
          '📊 Confidence: ${(result.averageConfidence * 100).toStringAsFixed(1)}%',
        );
        debugPrint('📦 Items detected: ${result.items.length}');
        if (result.reason != null) {
          debugPrint('💡 Reason: ${result.reason}');
        }

        for (var item in result.items) {
          debugPrint(
            '  - ${item.label} x${item.count} (${(item.confidence * 100).toStringAsFixed(1)}%)',
          );
        }
        debugPrint('════════════════════════════════════════');
      }

      // Convert to legacy format for compatibility
      final refinedItems = <String>[];
      for (var item in result.items) {
        final countPrefix = item.count > 1 ? '${item.count}x ' : '';
        refinedItems.add('$countPrefix${item.label}');
      }

      return refinedItems;
    } catch (e) {
      debugPrint('❌ Error processing image: $e');
      return [];
    }
  }

  String _getSourceIcon(VisionSource source) {
    switch (source) {
      case VisionSource.mlKit:
        return '📱';
      case VisionSource.cloudVision:
        return '☁️';
      case VisionSource.mlKitFallback:
        return '⚠️';
    }
  }

  String _getSourceName(VisionSource source) {
    switch (source) {
      case VisionSource.mlKit:
        return 'ML Kit (on-device)';
      case VisionSource.cloudVision:
        return 'Cloud Vision AI (enhanced)';
      case VisionSource.mlKitFallback:
        return 'ML Kit (quota limit reached)';
    }
  }

  void dispose() {
    _hybridVision.dispose();
  }
}
