import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:http/http.dart' as http;
import 'package:super_swipe/core/models/vision_scan_log.dart';
import 'package:super_swipe/core/services/vision_analytics_service.dart';
import 'package:super_swipe/core/services/vision_quota_service.dart';

/// Hybrid vision service that intelligently chooses between:
/// - **ML Kit** (free, on-device): Fast, good for single items, basic detection
/// - **Cloud Vision** (paid, cloud): Accurate, great for multi-item, complex scenes
/// 
/// **Decision Logic:**
/// 1. Try ML Kit first (always free)
/// 2. Analyze ML Kit results:
///    - Low confidence? → Escalate to Cloud Vision
///    - Many objects detected? → Escalate to Cloud Vision
///    - Generic labels only? → Escalate to Cloud Vision
/// 3. Check quota before using Cloud Vision
/// 4. Fallback gracefully if quota exhausted
class HybridVisionService {
  final VisionQuotaService _quotaService;
  final VisionAnalyticsService _analyticsService = VisionAnalyticsService();
  
  late ImageLabeler _imageLabeler;
  late ObjectDetector _objectDetector;
  
  bool _isInitialized = false;
  String? _currentUserId; // For analytics tracking
  
  // Confidence thresholds for escalation
  static const double mlKitConfidenceThreshold = 0.75;  // Below this → try Cloud Vision
  static const int multiItemThreshold = 3;               // 3+ objects → use Cloud Vision
  
  // Generic labels that trigger Cloud Vision escalation
  static const Set<String> genericLabels = {
    'food', 'fruit', 'vegetable', 'produce', 'ingredient',
    'dish', 'cuisine', 'plant', 'natural foods', 'whole food',
    'leaf vegetable', 'vegan nutrition', 'staple food',
    'mixed vegetables', 'mixed', 'assorted',
  };
  
  HybridVisionService(this._quotaService);
  
  /// Initialize both ML Kit detectors
  Future<void> init() async {
    if (_isInitialized) return;
    
    // Initialize ML Kit Image Labeler with optimized settings
    _imageLabeler = ImageLabeler(
      options: ImageLabelerOptions(
        confidenceThreshold: 0.5, // Balanced threshold
      ),
    );
    
    // Initialize ML Kit Object Detector with performance optimization
    final options = ObjectDetectorOptions(
      mode: DetectionMode.single, // Faster for single-frame processing
      classifyObjects: true,
      multipleObjects: true,
    );
    _objectDetector = ObjectDetector(options: options);
    
    // Initialize quota service
    await _quotaService.init();
    
    _isInitialized = true;
    debugPrint('✅ Hybrid Vision Service initialized');
  }
  
  /// Set user ID for analytics tracking
  void setUserId(String userId) {
    _currentUserId = userId;
  }
  
  /// Process image with intelligent hybrid approach
  Future<VisionResult> processImage(InputImage image) async {
    if (!_isInitialized) await init();
    
    // Start performance timer
    final stopwatch = Stopwatch()..start();
    
    debugPrint('🔍 Starting hybrid vision analysis...');
    
    // Step 1: Try ML Kit first (always free, on-device)
    final mlKitResult = await _processMlKit(image);
    
    debugPrint(
      '📊 ML Kit: ${mlKitResult.items.length} items, confidence=${mlKitResult.averageConfidence.toStringAsFixed(2)}',
    );
    
    // Step 2: Decide if we need Cloud Vision
    final needsCloudVision = _shouldEscalateToCloudVision(mlKitResult);
    
    if (!needsCloudVision) {
      stopwatch.stop();
      debugPrint('✅ ML Kit results sufficient, using free on-device detection');
      
      final result = mlKitResult.copyWith(
        source: VisionSource.mlKit,
        reason: 'High confidence ML Kit detection',
      );
      
      // Log to analytics (non-blocking)
      _logScanAnalytics(
        result: result,
        processingTimeMs: stopwatch.elapsedMilliseconds.toDouble(),
        quotaAvailable: true,
      ).ignore();
      
      return result;
    }
    
    // Step 3: Check quota before using Cloud Vision
    final canUseCloud = await _quotaService.canUseCloudVision();
    
    if (!canUseCloud) {
      stopwatch.stop();
      debugPrint('⚠️ Cloud Vision quota exhausted, using ML Kit fallback');
      
      final result = mlKitResult.copyWith(
        source: VisionSource.mlKitFallback,
        reason: 'Quota exhausted, using ML Kit',
      );
      
      // Log to analytics (non-blocking)
      _logScanAnalytics(
        result: result,
        processingTimeMs: stopwatch.elapsedMilliseconds.toDouble(),
        quotaAvailable: false,
      ).ignore();
      
      return result;
    }
    
    // Step 4: Use Cloud Vision for better accuracy
    debugPrint('☁️ Escalating to Cloud Vision for enhanced accuracy...');
    
    try {
      final cloudResult = await _processCloudVision(image);
      
      // Increment quota usage
      await _quotaService.incrementUsage();
      
      stopwatch.stop();
      debugPrint('✅ Cloud Vision: ${cloudResult.items.length} items detected');
      debugPrint('⏱️ Total processing time: ${stopwatch.elapsedMilliseconds}ms');
      
      final result = cloudResult.copyWith(
        source: VisionSource.cloudVision,
        reason: 'Enhanced detection with Cloud Vision AI',
      );
      
      // Log to analytics (non-blocking)
      _logScanAnalytics(
        result: result,
        processingTimeMs: stopwatch.elapsedMilliseconds.toDouble(),
        quotaAvailable: true,
      ).ignore();
      
      return result;
    } catch (e) {
      stopwatch.stop();
      debugPrint('❌ Cloud Vision failed: $e, using ML Kit fallback');
      
      final result = mlKitResult.copyWith(
        source: VisionSource.mlKitFallback,
        reason: 'Cloud Vision error, using ML Kit',
      );
      
      // Log to analytics (non-blocking)
      _logScanAnalytics(
        result: result,
        processingTimeMs: stopwatch.elapsedMilliseconds.toDouble(),
        quotaAvailable: true,
      ).ignore();
      
      return result;
    }
  }
  
  /// Log scan analytics to Firestore (non-blocking)
  Future<void> _logScanAnalytics({
    required VisionResult result,
    required double processingTimeMs,
    required bool quotaAvailable,
  }) async {
    // Only log if user is authenticated
    if (_currentUserId == null || _currentUserId!.isEmpty) return;
    
    try {
      await _analyticsService.logScan(
        userId: _currentUserId!,
        source: _mapVisionSource(result.source),
        itemsDetected: result.items.length,
        averageConfidence: result.averageConfidence,
        objectCount: result.objectCount,
        escalationReason: result.reason,
        quotaAvailable: quotaAvailable,
        processingTimeMs: processingTimeMs,
      );
    } catch (e) {
      // Don't fail the scan if analytics logging fails
      debugPrint('⚠️ Analytics logging failed: $e');
    }
  }
  
  VisionSourceType _mapVisionSource(VisionSource source) {
    switch (source) {
      case VisionSource.mlKit:
        return VisionSourceType.mlKit;
      case VisionSource.cloudVision:
        return VisionSourceType.cloudVision;
      case VisionSource.mlKitFallback:
        return VisionSourceType.mlKitFallback;
    }
  }
  
  /// Process image with ML Kit (free, on-device)
  /// Optimized for performance with parallel processing
  Future<VisionResult> _processMlKit(InputImage image) async {
    // Run both labeler and detector in parallel for better performance
    final results = await Future.wait([
      _imageLabeler.processImage(image),
      _objectDetector.processImage(image),
    ]);
    
    final labels = results[0] as List<ImageLabel>;
    final objects = results[1] as List<DetectedObject>;
    
    final items = <VisionItem>[];
    
    // Combine and refine results
    // Use confidence threshold of 0.5 for balanced accuracy/recall
    for (final label in labels) {
      if (label.confidence > 0.5) {
        items.add(VisionItem(
          label: label.label,
          confidence: label.confidence,
          count: _estimateCount(label.label, objects),
        ));
      }
    }
    
    // Apply refinement logic to filter non-food items
    final refinedItems = _refineLabels(items);
    
    // Calculate average confidence
    final avgConfidence = refinedItems.isEmpty
        ? 0.0
        : refinedItems.map((e) => e.confidence).reduce((a, b) => a + b) /
            refinedItems.length;
    
    return VisionResult(
      items: refinedItems,
      source: VisionSource.mlKit,
      averageConfidence: avgConfidence,
      objectCount: objects.length,
    );
  }
  
  /// Process image with Google Cloud Vision API
  Future<VisionResult> _processCloudVision(InputImage image) async {
    final apiKey = dotenv.env['GOOGLE_VISION_API_KEY'];
    
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GOOGLE_VISION_API_KEY not found in .env');
    }
    
    // Read image bytes
    final bytes = await _getImageBytes(image);
    final base64Image = base64Encode(bytes);
    
    // Call Cloud Vision API
    final url = Uri.parse(
      'https://vision.googleapis.com/v1/images:annotate?key=$apiKey',
    );
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'requests': [
          {
            'image': {'content': base64Image},
            'features': [
              {'type': 'LABEL_DETECTION', 'maxResults': 20},
              {'type': 'OBJECT_LOCALIZATION', 'maxResults': 20},
            ],
          }
        ]
      }),
    ).timeout(const Duration(seconds: 10));
    
    if (response.statusCode != 200) {
      throw Exception('Cloud Vision API error: ${response.statusCode} ${response.body}');
    }
    
    final result = jsonDecode(response.body);
    final items = <VisionItem>[];
    
    // Parse label annotations
    final labelAnnotations = result['responses'][0]['labelAnnotations'] as List?;
    if (labelAnnotations != null) {
      for (final annotation in labelAnnotations) {
        final label = annotation['description'] as String;
        final score = (annotation['score'] as num).toDouble();
        
        if (score > 0.5) {
          items.add(VisionItem(
            label: label,
            confidence: score,
            count: 1,
          ));
        }
      }
    }
    
    // Parse object localization
    final objectAnnotations = result['responses'][0]['localizedObjectAnnotations'] as List?;
    final objectCount = objectAnnotations?.length ?? 0;
    
    // Refine and merge results
    final refinedItems = _refineLabels(items);
    
    final avgConfidence = refinedItems.isEmpty 
        ? 0.0 
        : refinedItems.map((e) => e.confidence).reduce((a, b) => a + b) / refinedItems.length;
    
    return VisionResult(
      items: refinedItems,
      source: VisionSource.cloudVision,
      averageConfidence: avgConfidence,
      objectCount: objectCount,
    );
  }
  
  /// Decide if we should escalate to Cloud Vision
  bool _shouldEscalateToCloudVision(VisionResult mlKitResult) {
    // Reason 1: Low confidence
    if (mlKitResult.averageConfidence < mlKitConfidenceThreshold) {
      debugPrint('📈 Escalation reason: Low confidence (${mlKitResult.averageConfidence.toStringAsFixed(2)})');
      return true;
    }
    
    // Reason 2: Multiple objects (complex scene)
    if (mlKitResult.objectCount >= multiItemThreshold) {
      debugPrint('📈 Escalation reason: Multi-item scene (${mlKitResult.objectCount} objects)');
      return true;
    }
    
    // Reason 3: Generic labels only
    final hasOnlyGeneric = mlKitResult.items.isNotEmpty &&
        mlKitResult.items.every((item) => _isGenericLabel(item.label));
    
    if (hasOnlyGeneric) {
      debugPrint('📈 Escalation reason: Generic labels only');
      return true;
    }
    
    // Reason 4: No items detected
    if (mlKitResult.items.isEmpty) {
      debugPrint('📈 Escalation reason: No items detected');
      return true;
    }
    
    return false;
  }
  
  /// Check if a label is generic
  bool _isGenericLabel(String label) {
    final lower = label.toLowerCase();
    return genericLabels.any((generic) => lower.contains(generic));
  }
  
  /// Refine labels to be more specific for food items
  List<VisionItem> _refineLabels(List<VisionItem> items) {
    final refined = <VisionItem>[];
    
    for (final item in items) {
      final lower = item.label.toLowerCase();
      
      // Skip non-food items
      if (_isNonFood(lower)) continue;
      
      // Capitalize properly
      final capitalizedLabel = _capitalizeLabel(item.label);
      
      refined.add(item.copyWith(label: capitalizedLabel));
    }
    
    return refined;
  }
  
  bool _isNonFood(String label) {
    const nonFoodKeywords = [
      'person', 'hand', 'finger', 'arm', 'face',
      'table', 'plate', 'bowl', 'container', 'package',
      'background', 'surface', 'counter', 'kitchen',
    ];
    
    return nonFoodKeywords.any((keyword) => label.contains(keyword));
  }
  
  String _capitalizeLabel(String label) {
    return label.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
  
  int _estimateCount(String searchLabel, List<DetectedObject> objects) {
    if (objects.isEmpty) return 1;
    
    // Count objects that match the label
    int count = 0;
    final searchLower = searchLabel.toLowerCase();
    
    for (final obj in objects) {
      for (final label in obj.labels) {
        if (label.text.toLowerCase().contains(searchLower)) {
          count++;
          break;
        }
      }
    }
    
    return count > 0 ? count : 1;
  }
  
  Future<List<int>> _getImageBytes(InputImage image) async {
    if (image.bytes != null) {
      return image.bytes!;
    }
    
    if (image.filePath != null) {
      return await File(image.filePath!).readAsBytes();
    }
    
    throw Exception('Cannot get image bytes: no bytes or filePath');
  }
  
  void dispose() {
    _imageLabeler.close();
    _objectDetector.close();
  }
}

/// Result from vision processing
class VisionResult {
  final List<VisionItem> items;
  final VisionSource source;
  final double averageConfidence;
  final int objectCount;
  final String? reason;
  
  VisionResult({
    required this.items,
    required this.source,
    required this.averageConfidence,
    required this.objectCount,
    this.reason,
  });
  
  VisionResult copyWith({
    List<VisionItem>? items,
    VisionSource? source,
    double? averageConfidence,
    int? objectCount,
    String? reason,
  }) {
    return VisionResult(
      items: items ?? this.items,
      source: source ?? this.source,
      averageConfidence: averageConfidence ?? this.averageConfidence,
      objectCount: objectCount ?? this.objectCount,
      reason: reason ?? this.reason,
    );
  }
}

/// Individual detected item
class VisionItem {
  final String label;
  final double confidence;
  final int count;
  
  VisionItem({
    required this.label,
    required this.confidence,
    required this.count,
  });
  
  VisionItem copyWith({
    String? label,
    double? confidence,
    int? count,
  }) {
    return VisionItem(
      label: label ?? this.label,
      confidence: confidence ?? this.confidence,
      count: count ?? this.count,
    );
  }
}

/// Source of vision detection
enum VisionSource {
  mlKit,           // ML Kit provided good results
  cloudVision,     // Escalated to Cloud Vision
  mlKitFallback,   // Wanted Cloud Vision but quota exhausted
}

