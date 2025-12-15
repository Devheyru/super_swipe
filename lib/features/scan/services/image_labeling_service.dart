import 'package:flutter/foundation.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

class ImageLabelingService {
  final ImageLabeler _imageLabeler;
  final ObjectDetector _objectDetector;

  ImageLabelingService()
    : _imageLabeler = ImageLabeler(
        options: ImageLabelerOptions(confidenceThreshold: 0.5),
      ),
      _objectDetector = ObjectDetector(
        options: ObjectDetectorOptions(
          mode: DetectionMode.single,
          classifyObjects: true,
          multipleObjects: true,
        ),
      );

  Future<List<String>> processImage(InputImage inputImage) async {
    try {
      // Run both object detection and image labeling in parallel
      final results = await Future.wait([
        _objectDetector.processImage(inputImage),
        _imageLabeler.processImage(inputImage),
      ]);

      final detectedObjects = results[0] as List<DetectedObject>;
      final imageLabels = results[1] as List<ImageLabel>;

      if (kDebugMode) {
        debugPrint('════════════════════════════════════════');
        debugPrint(
          '🔍 OBJECT DETECTION: Found ${detectedObjects.length} objects',
        );
        for (var obj in detectedObjects) {
          for (var label in obj.labels) {
            debugPrint(
              '  - ${label.text} (${(label.confidence * 100).toStringAsFixed(1)}%)',
            );
          }
        }
        debugPrint('🏷️  IMAGE LABELS:');
        for (var label in imageLabels) {
          debugPrint(
            '  - ${label.label} (${(label.confidence * 100).toStringAsFixed(1)}%)',
          );
        }
        debugPrint('════════════════════════════════════════');
      }

      // Extract all labels with confidence
      final allLabels = <Map<String, dynamic>>[];

      // Add object detection labels
      for (var obj in detectedObjects) {
        for (var label in obj.labels) {
          allLabels.add({
            'label': label.text.toLowerCase(),
            'confidence': label.confidence,
            'source': 'object',
          });
        }
      }

      // Add image labeling labels
      for (var label in imageLabels.where((l) => l.confidence > 0.4)) {
        allLabels.add({
          'label': label.label.toLowerCase(),
          'confidence': label.confidence,
          'source': 'image',
        });
      }

      // Refine to specific ingredients with count
      final refined = _refineLabelsToIngredients(
        allLabels,
        objectCount: detectedObjects.length,
      );

      if (kDebugMode) {
        debugPrint('✅ FINAL INGREDIENTS: $refined');
        debugPrint('════════════════════════════════════════');
      }

      return refined;
    } catch (e) {
      debugPrint('❌ Error processing image: $e');
      return [];
    }
  }

  /// Intelligently refines generic ML labels to specific ingredient names with quantity
  List<String> _refineLabelsToIngredients(
    List<Map<String, dynamic>> labelData, {
    required int objectCount,
  }) {
    final labels = labelData.map((l) => l['label'] as String).toList();

    // Create a label set for quick lookups
    final labelSet = labels.toSet();

    // ============ SPECIFIC FOOD DETECTION ============

    // Check for specific items with high confidence
    final detectedItems = <String, int>{};

    // CARROTS - High priority detection
    if (_matchesAny(labelSet, ['carrot', 'carrots', 'root vegetable']) ||
        (labelSet.contains('orange') &&
            (labelSet.contains('vegetable') || labelSet.contains('food')))) {
      int count = _estimateCount(objectCount, labelSet, 'carrot');
      detectedItems['Carrots'] = count;
    }

    // TOMATOES - High priority detection
    if (_matchesAny(labelSet, ['tomato', 'tomatoes', 'cherry tomato']) ||
        (labelSet.contains('red') &&
            labelSet.contains('food') &&
            !labelSet.contains('meat'))) {
      int count = _estimateCount(objectCount, labelSet, 'tomato');
      detectedItems['Tomatoes'] = count;
    }

    // LEAFY GREENS - Identify specific type
    if (_matchesAny(labelSet, [
      'leaf',
      'leafy',
      'green',
      'greens',
      'lettuce',
      'cabbage',
      'spinach',
      'kale',
      'chard',
      'beet greens',
    ])) {
      String leafyType = 'Leafy Greens';

      if (labelSet.contains('cabbage')) {
        leafyType = 'Cabbage';
      } else if (labelSet.contains('lettuce')) {
        leafyType = 'Lettuce';
      } else if (labelSet.contains('spinach')) {
        leafyType = 'Spinach';
      } else if (labelSet.contains('kale')) {
        leafyType = 'Kale';
      } else if (_matchesAny(labelSet, ['chard', 'beet'])) {
        leafyType = 'Beet Greens';
      }

      int count = _estimateCount(objectCount, labelSet, 'leaf');
      detectedItems[leafyType] = count;
    }

    // POTATOES
    if (_matchesAny(labelSet, ['potato', 'potatoes', 'tuber'])) {
      detectedItems['Potatoes'] = _estimateCount(
        objectCount,
        labelSet,
        'potato',
      );
    }

    // ONIONS
    if (_matchesAny(labelSet, ['onion', 'onions'])) {
      detectedItems['Onions'] = _estimateCount(objectCount, labelSet, 'onion');
    }

    // GARLIC
    if (_matchesAny(labelSet, ['garlic'])) {
      detectedItems['Garlic'] = _estimateCount(objectCount, labelSet, 'garlic');
    }

    // PEPPERS
    if (_matchesAny(labelSet, [
      'pepper',
      'peppers',
      'bell pepper',
      'capsicum',
    ])) {
      detectedItems['Bell Peppers'] = _estimateCount(
        objectCount,
        labelSet,
        'pepper',
      );
    }

    // BROCCOLI
    if (_matchesAny(labelSet, ['broccoli'])) {
      detectedItems['Broccoli'] = _estimateCount(
        objectCount,
        labelSet,
        'broccoli',
      );
    }

    // CAULIFLOWER
    if (_matchesAny(labelSet, ['cauliflower'])) {
      detectedItems['Cauliflower'] = _estimateCount(
        objectCount,
        labelSet,
        'cauliflower',
      );
    }

    // ZUCCHINI
    if (_matchesAny(labelSet, ['zucchini', 'courgette'])) {
      detectedItems['Zucchini'] = _estimateCount(
        objectCount,
        labelSet,
        'zucchini',
      );
    }

    // CUCUMBER
    if (_matchesAny(labelSet, ['cucumber'])) {
      detectedItems['Cucumber'] = _estimateCount(
        objectCount,
        labelSet,
        'cucumber',
      );
    }

    // FRUITS
    if (_matchesAny(labelSet, ['apple', 'apples'])) {
      detectedItems['Apples'] = _estimateCount(objectCount, labelSet, 'apple');
    }
    if (_matchesAny(labelSet, ['orange', 'oranges']) &&
        labelSet.contains('fruit')) {
      detectedItems['Oranges'] = _estimateCount(
        objectCount,
        labelSet,
        'orange',
      );
    }
    if (_matchesAny(labelSet, ['banana', 'bananas'])) {
      detectedItems['Bananas'] = _estimateCount(
        objectCount,
        labelSet,
        'banana',
      );
    }
    if (_matchesAny(labelSet, ['lemon', 'lemons'])) {
      detectedItems['Lemons'] = _estimateCount(objectCount, labelSet, 'lemon');
    }
    if (_matchesAny(labelSet, ['lime', 'limes'])) {
      detectedItems['Limes'] = _estimateCount(objectCount, labelSet, 'lime');
    }
    if (_matchesAny(labelSet, ['avocado', 'avocados'])) {
      detectedItems['Avocados'] = _estimateCount(
        objectCount,
        labelSet,
        'avocado',
      );
    }
    if (_matchesAny(labelSet, [
      'berry',
      'berries',
      'strawberry',
      'blueberry',
    ])) {
      String berryType = 'Mixed Berries';
      if (labelSet.contains('strawberry'))
        berryType = 'Strawberries';
      else if (labelSet.contains('blueberry'))
        berryType = 'Blueberries';
      detectedItems[berryType] = _estimateCount(objectCount, labelSet, 'berry');
    }

    // PROTEINS
    if (_matchesAny(labelSet, ['chicken', 'poultry'])) {
      detectedItems['Chicken'] = _estimateCount(
        objectCount,
        labelSet,
        'chicken',
      );
    }
    if (_matchesAny(labelSet, ['beef', 'steak'])) {
      detectedItems['Beef'] = _estimateCount(objectCount, labelSet, 'beef');
    }
    if (_matchesAny(labelSet, ['pork'])) {
      detectedItems['Pork'] = _estimateCount(objectCount, labelSet, 'pork');
    }
    if (_matchesAny(labelSet, ['fish', 'seafood'])) {
      detectedItems['Fish'] = _estimateCount(objectCount, labelSet, 'fish');
    }
    if (_matchesAny(labelSet, ['egg', 'eggs'])) {
      detectedItems['Eggs'] = _estimateCount(objectCount, labelSet, 'egg');
    }

    // DAIRY
    if (_matchesAny(labelSet, ['milk'])) {
      detectedItems['Milk'] = 1;
    }
    if (_matchesAny(labelSet, ['cheese'])) {
      detectedItems['Cheese'] = 1;
    }
    if (_matchesAny(labelSet, ['yogurt', 'yoghurt'])) {
      detectedItems['Yogurt'] = _estimateCount(objectCount, labelSet, 'yogurt');
    }
    if (_matchesAny(labelSet, ['butter'])) {
      detectedItems['Butter'] = 1;
    }

    // GRAINS
    if (_matchesAny(labelSet, ['bread'])) {
      detectedItems['Bread'] = 1;
    }
    if (_matchesAny(labelSet, ['rice'])) {
      detectedItems['Rice'] = 1;
    }
    if (_matchesAny(labelSet, ['pasta', 'noodle', 'noodles'])) {
      detectedItems['Pasta'] = 1;
    }

    // PANTRY STAPLES
    if (_matchesAny(labelSet, ['oil'])) {
      detectedItems['Cooking Oil'] = 1;
    }
    if (_matchesAny(labelSet, ['sauce'])) {
      detectedItems['Sauce'] = 1;
    }

    // Convert to result format: "Item (count)"
    final result = <String>[];
    for (var entry in detectedItems.entries) {
      if (entry.value > 1) {
        result.add('${entry.key} (${entry.value})');
      } else {
        result.add(entry.key);
      }
    }

    // Fallback: if nothing detected, use generic categories
    if (result.isEmpty) {
      if (labelSet.contains('vegetable') || labelSet.contains('produce')) {
        result.add('Mixed Vegetables');
      } else if (labelSet.contains('fruit')) {
        result.add('Fresh Fruit');
      } else if (labelSet.contains('food')) {
        result.add('Food Item');
      }
    }

    return result;
  }

  /// Check if any of the patterns match any label
  bool _matchesAny(Set<String> labels, List<String> patterns) {
    for (var pattern in patterns) {
      if (labels.any((l) => l.contains(pattern))) {
        return true;
      }
    }
    return false;
  }

  /// Estimate count based on detected objects and context
  int _estimateCount(int objectCount, Set<String> labels, String itemType) {
    // If multiple objects detected, assume most are the same type
    if (objectCount >= 3) {
      // For clustered items (tomatoes, carrots), estimate higher
      if (['tomato', 'carrot', 'berry'].any((t) => itemType.contains(t))) {
        return (objectCount * 0.8).round().clamp(2, 20);
      }
      return (objectCount * 0.6).round().clamp(2, 10);
    } else if (objectCount == 2) {
      return 2;
    }

    // Check for plural indicators
    if (labels.any(
      (l) => l.endsWith('s') || l.contains('multiple') || l.contains('bunch'),
    )) {
      return 3; // Estimate
    }

    return 1;
  }

  void dispose() {
    _imageLabeler.close();
    _objectDetector.close();
  }
}
