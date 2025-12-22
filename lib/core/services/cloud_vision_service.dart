import 'dart:convert';
import 'dart:io';

// import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Cloud Vision Service for food detection using Google Cloud Vision API
/// Intelligently filters and processes results for any food type
class CloudVisionService {
  static const String _baseUrl =
      'https://vision.googleapis.com/v1/images:annotate';

  String? _apiKey;

  /// Initialize the service
  Future<void> init() async {
    _apiKey = dotenv.env['GOOGLE_VISION_API_KEY'];
    if (_apiKey == null || _apiKey!.isEmpty) {
  // debugPrint('⚠️ GOOGLE_VISION_API_KEY not found in .env');
    } else {
  // debugPrint('✅ Cloud Vision Service initialized');
    }
  }

  /// Process an image file and detect food items
  Future<List<FoodDetectionResult>> detectFoodItems(String imagePath) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('GOOGLE_VISION_API_KEY not configured');
    }

  // debugPrint('🔍 Processing image with Cloud Vision API...');
    final stopwatch = Stopwatch()..start();

    try {
      // Read and encode image
      final imageFile = File(imagePath);
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Make API request
      final url = Uri.parse('$_baseUrl?key=$_apiKey');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'requests': [
                {
                  'image': {'content': base64Image},
                  'features': [
                    {'type': 'LABEL_DETECTION', 'maxResults': 50},
                    {'type': 'OBJECT_LOCALIZATION', 'maxResults': 30},
                  ],
                },
              ],
            }),
          )
          .timeout(const Duration(seconds: 15));

      stopwatch.stop();
  // debugPrint('⏱️ API response in ${stopwatch.elapsedMilliseconds}ms');

      if (response.statusCode != 200) {
  // debugPrint('❌ API Error: ${response.statusCode}');
  // debugPrint('Response: ${response.body}');
        throw Exception('Cloud Vision API error: ${response.statusCode}');
      }

      // Parse response
      final result = jsonDecode(response.body);
      return _parseResponse(result);
    } catch (e) {
  // debugPrint('❌ Error processing image: $e');
      rethrow;
    }
  }

  /// Parse API response and extract food items
  List<FoodDetectionResult> _parseResponse(Map<String, dynamic> response) {
    final results = <FoodDetectionResult>[];

    try {
      final annotations = response['responses']?[0];
      if (annotations == null) return results;

      // Collect all labels with scores
      final allLabels = <String, double>{};

      // Process label annotations
      final labelAnnotations = annotations['labelAnnotations'] as List?;
      if (labelAnnotations != null) {
        for (final label in labelAnnotations) {
          final description = (label['description'] as String).trim();
          final score = (label['score'] as num).toDouble();
          allLabels[description] = score;
        }
      }

      // Process object localization for quantity
      final objectAnnotations =
          annotations['localizedObjectAnnotations'] as List?;
      final objectCounts = <String, int>{};

      if (objectAnnotations != null) {
        // Track object positions to avoid counting same object multiple times
        final processedPositions = <String>{};

        for (final obj in objectAnnotations) {
          final name = (obj['name'] as String).trim();
          final lower = name.toLowerCase();
          
          // Get bounding box to identify unique objects
          final vertices = obj['boundingPoly']?['normalizedVertices'] as List?;
          if (vertices != null && vertices.length >= 3) {
            // Create a position signature from center point
            final x1 = (vertices[0]['x'] as num?)?.toDouble() ?? 0.0;
            final y1 = (vertices[0]['y'] as num?)?.toDouble() ?? 0.0;
            final x2 = (vertices[2]['x'] as num?)?.toDouble() ?? 0.0;
            final y2 = (vertices[2]['y'] as num?)?.toDouble() ?? 0.0;
            
            final centerX = (x1 + x2) / 2;
            final centerY = (y1 + y2) / 2;
            final positionKey = '${centerX.toStringAsFixed(3)}_${centerY.toStringAsFixed(3)}';

            // Skip if we've already counted an object at this position
            if (processedPositions.contains(positionKey)) {
              continue;
            }
            processedPositions.add(positionKey);
          }

          objectCounts[lower] = (objectCounts[lower] ?? 0) + 1;

          // Also add to labels if not present
          final score = (obj['score'] as num?)?.toDouble() ?? 0.7;
          if (!allLabels.containsKey(name) || allLabels[name]! < score) {
            allLabels[name] = score;
          }
        }

  // debugPrint('📦 Object counts: ${objectCounts.entries.map((e) => '${e.key}=${e.value}').join(', ')}');
      }

  // debugPrint('📊 Raw labels: ${allLabels.length}');

      // Step 1: Filter to only food-related items
      final foodLabels = <String, double>{};
      for (final entry in allLabels.entries) {
        if (_isActualFood(entry.key) && entry.value > 0.5) {
          foodLabels[entry.key] = entry.value;
        }
      }

  // debugPrint('🍎 Food labels: ${foodLabels.length}');

      // Step 2: Normalize and deduplicate
      final normalizedLabels = <String, double>{};
      for (final entry in foodLabels.entries) {
        final normalized = _normalizeToFoodItem(entry.key);
        if (normalized != null) {
          // Keep the highest confidence for each normalized name
          if (!normalizedLabels.containsKey(normalized) ||
              normalizedLabels[normalized]! < entry.value) {
            normalizedLabels[normalized] = entry.value;
          }
        }
      }

  // debugPrint('✨ Normalized labels: ${normalizedLabels.length}');

      // Step 3: Remove redundant items (generic vs specific)
      final finalLabels = _removeRedundantItems(normalizedLabels);

  // debugPrint('🎯 Final labels: ${finalLabels.length}');

      // Step 4: Build results with quantity
      for (final entry in finalLabels.entries) {
        // Try to find quantity from object detection
        int quantity = _findBestQuantity(entry.key, objectCounts);

        results.add(
          FoodDetectionResult(
            name: entry.key,
            confidence: entry.value,
            quantity: quantity,
          ),
        );
      }

      // Sort by confidence
      results.sort((a, b) => b.confidence.compareTo(a.confidence));

  // debugPrint('✅ Detected ${results.length} food items:');
      for (final item in results) {
  // debugPrint(
        //   '  - ${item.name} x${item.quantity} (${(item.confidence * 100).toStringAsFixed(1)}%)',
        // );
      }

      return results;
    } catch (e) {
  // debugPrint('❌ Error parsing response: $e');
      return results;
    }
  }

  /// Check if a label represents an actual food item (not a category or descriptor)
  bool _isActualFood(String label) {
    final lower = label.toLowerCase();

    // Skip these generic/non-food terms
    const skipExact = {
      // Generic categories
      'food', 'foods', 'ingredient', 'ingredients', 'produce', 'grocery',
      'vegetable', 'vegetables', 'fruit', 'fruits', 'meat', 'meats',
      'dairy', 'protein', 'grain', 'grains', 'legume', 'legumes',

      // Descriptive terms
      'fresh', 'raw', 'cooked', 'organic', 'natural', 'whole', 'local',
      'ripe', 'unripe', 'dried', 'frozen', 'canned', 'pickled',

      // Abstract food concepts
      'nutrition', 'diet', 'meal', 'dish', 'cuisine', 'recipe',
      'breakfast', 'lunch', 'dinner', 'snack', 'appetizer', 'dessert',

      // Colors (unless part of food name)
      'red', 'green', 'yellow', 'orange', 'white', 'brown', 'purple',

      // Photography/presentation terms
      'still life', 'close up', 'macro', 'photography', 'arrangement',
      'display', 'presentation', 'platter', 'plate', 'bowl', 'basket',
    };

    if (skipExact.contains(lower)) return false;

    // Skip phrases containing these generic terms
    const skipContains = [
      'food group',
      'food item',
      'food product',
      'food type',
      'natural food',
      'staple food',
      'whole food',
      'comfort food',
      'health food',
      'diet food',
      'fast food',
      'junk food',
      'superfood',
      'super food',
      'vegan',
      'vegetarian',
      'gluten',
      'nutrition',
      'nutritious',
      'healthy',
      'seedless',
      'accessory fruit',
      'citrus fruit',
      'root vegetable',
      'leafy green',
      'cruciferous',
      'nightshade',
      'allium',
      'brassica',
    ];

    for (final term in skipContains) {
      if (lower.contains(term)) return false;
    }

    // Must contain at least one food-related word
    const foodIndicators = [
      // Vegetables
      'carrot', 'tomato', 'potato', 'onion', 'garlic', 'pepper', 'lettuce',
      'spinach', 'cabbage', 'broccoli', 'cauliflower', 'cucumber', 'zucchini',
      'squash', 'pumpkin', 'eggplant', 'celery', 'asparagus', 'artichoke',
      'corn', 'pea', 'bean', 'lentil', 'chickpea', 'mushroom', 'kale',
      'chard', 'arugula', 'radish', 'turnip', 'beet', 'parsnip', 'leek',
      'scallion', 'shallot', 'ginger', 'turmeric', 'fennel', 'okra',

      // Fruits
      'apple', 'orange', 'banana', 'grape', 'strawberry', 'blueberry',
      'raspberry', 'blackberry', 'cranberry', 'cherry', 'peach', 'plum',
      'apricot', 'nectarine', 'pear', 'mango', 'papaya', 'pineapple',
      'kiwi', 'watermelon', 'cantaloupe', 'honeydew', 'melon', 'fig',
      'date', 'pomegranate', 'passion', 'guava', 'lychee', 'dragon',
      'coconut', 'avocado', 'olive', 'lemon', 'lime', 'grapefruit',
      'tangerine', 'clementine', 'mandarin', 'persimmon', 'starfruit',

      // Proteins
      'chicken', 'beef', 'pork', 'lamb', 'turkey', 'duck', 'goose',
      'fish', 'salmon', 'tuna', 'cod', 'tilapia', 'trout', 'bass',
      'shrimp', 'prawn', 'lobster', 'crab', 'scallop', 'mussel', 'clam',
      'oyster', 'squid', 'octopus', 'egg', 'tofu', 'tempeh', 'seitan',
      'bacon', 'sausage', 'ham', 'steak', 'chop', 'fillet', 'wing',
      'thigh', 'breast', 'rib', 'roast',

      // Dairy
      'milk', 'cheese', 'yogurt', 'butter', 'cream', 'curd', 'whey',
      'mozzarella', 'cheddar', 'parmesan', 'brie', 'feta', 'gouda',

      // Grains & Carbs
      'bread', 'rice', 'pasta', 'noodle', 'wheat', 'flour', 'oat',
      'cereal', 'quinoa', 'barley', 'couscous', 'bulgur', 'millet',
      'tortilla', 'pita', 'bagel', 'croissant', 'baguette', 'roll',

      // Nuts & Seeds
      'almond', 'walnut', 'cashew', 'peanut', 'pistachio', 'pecan',
      'hazelnut', 'macadamia', 'chestnut', 'sunflower', 'pumpkin seed',
      'sesame', 'flax', 'chia',

      // Herbs & Spices
      'basil', 'oregano', 'thyme', 'rosemary', 'parsley', 'cilantro',
      'mint', 'dill', 'sage', 'chive', 'tarragon', 'bay leaf',
      'cinnamon', 'cumin', 'paprika', 'cayenne', 'chili', 'curry',

      // Condiments & Others
      'sauce', 'ketchup', 'mustard', 'mayonnaise', 'vinegar', 'oil',
      'honey', 'syrup', 'jam', 'jelly', 'pickle', 'salsa', 'hummus',
    ];

    return foodIndicators.any((food) => lower.contains(food));
  }

  /// Normalize a label to a clean food item name
  String? _normalizeToFoodItem(String rawName) {
    String name = rawName.trim();
    final lower = name.toLowerCase();

    // Remove common prefixes/suffixes that don't add value
    const removePatterns = [
      'fresh ',
      'raw ',
      'organic ',
      'natural ',
      'whole ',
      'ripe ',
      'sliced ',
      'chopped ',
      'diced ',
      'minced ',
      'grated ',
      'shredded ',
      'cooked ',
      'grilled ',
      'roasted ',
      'baked ',
      'fried ',
      'steamed ',
      'baby ',
      'mini ',
      'large ',
      'small ',
      'medium ',
      'big ',
    ];

    String cleaned = lower;
    for (final pattern in removePatterns) {
      cleaned = cleaned.replaceAll(pattern, '');
    }
    cleaned = cleaned.trim();

    if (cleaned.isEmpty) return null;

    // Capitalize properly
    return cleaned
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  /// Remove redundant items where we have both generic and specific versions
  Map<String, double> _removeRedundantItems(Map<String, double> labels) {
    final result = Map<String, double>.from(labels);
    final toRemove = <String>{};

    final items = labels.keys.toList();

    for (int i = 0; i < items.length; i++) {
      for (int j = i + 1; j < items.length; j++) {
        final item1 = items[i];
        final item2 = items[j];
        final lower1 = item1.toLowerCase();
        final lower2 = item2.toLowerCase();

        // Check if one contains the other (e.g., "Tomato" vs "Cherry Tomato")
        if (lower1.contains(lower2)) {
          // item1 is more specific, remove item2
          toRemove.add(item2);
        } else if (lower2.contains(lower1)) {
          // item2 is more specific, remove item1
          toRemove.add(item1);
        }
        // Check for singular/plural (e.g., "Tomato" vs "Tomatoes")
        else if (_areSingularPlural(lower1, lower2)) {
          // Keep the one with higher confidence
          if (labels[item1]! >= labels[item2]!) {
            toRemove.add(item2);
          } else {
            toRemove.add(item1);
          }
        }
        // Check for same base food (e.g., "Cherry Tomato" vs "Plum Tomato")
        else if (_areSameBaseFood(lower1, lower2)) {
          // Keep the one with higher confidence
          if (labels[item1]! >= labels[item2]!) {
            toRemove.add(item2);
          } else {
            toRemove.add(item1);
          }
        }
      }
    }

    for (final item in toRemove) {
      result.remove(item);
    }

    return result;
  }

  /// Check if two items are variations of the same base food
  /// e.g., "Cherry Tomato" and "Plum Tomato" both have "Tomato"
  bool _areSameBaseFood(String a, String b) {
    // Extract base food words
    final wordsA = a.split(' ').where((w) => w.length > 2).toSet();
    final wordsB = b.split(' ').where((w) => w.length > 2).toSet();

    // Common base foods to check
    const baseFoods = [
      'tomato',
      'tomatoes',
      'pepper',
      'peppers',
      'onion',
      'onions',
      'apple',
      'apples',
      'potato',
      'potatoes',
      'lettuce',
      'bean',
      'beans',
      'berry',
      'berries',
      'melon',
      'cheese',
      'mushroom',
      'mushrooms',
      'squash',
      'cabbage',
      'grape',
      'grapes',
      'orange',
      'oranges',
    ];

    for (final base in baseFoods) {
      final aHasBase = wordsA.any((w) => w.contains(base) || base.contains(w));
      final bHasBase = wordsB.any((w) => w.contains(base) || base.contains(w));

      if (aHasBase && bHasBase) {
        return true;
      }
    }

    return false;
  }

  /// Check if two strings are singular/plural versions of same word
  bool _areSingularPlural(String a, String b) {
    if (a == b) return true;
    if ('${a}s' == b || '${a}es' == b) return true;
    if ('${b}s' == a || '${b}es' == a) return true;
    if (a.endsWith('ies') && '${b}y' == '${a.substring(0, a.length - 3)}y') {
      return true;
    }
    if (b.endsWith('ies') && '${a}y' == '${b.substring(0, b.length - 3)}y') {
      return true;
    }
    return false;
  }

  /// Find the best quantity match from object detection
  /// Find the best quantity match from object detection with improved accuracy
  int _findBestQuantity(String foodName, Map<String, int> objectCounts) {
    if (objectCounts.isEmpty) {
  // debugPrint('  ℹ️ No object counts available for "$foodName"');
      return 1;
    }

    final lowerName = foodName.toLowerCase();
    int bestQuantity = 1;
    String? matchedObject;

    // Extract food words (skip articles, colors, descriptors)
    final foodWords = lowerName
        .split(' ')
        .where((word) =>
            word.length > 3 &&
            !['fresh', 'raw', 'organic', 'whole', 'red', 'green', 'yellow']
                .contains(word))
        .toList();

  // debugPrint('  🔍 Finding quantity for "$foodName" (words: $foodWords)');

    // Priority 1: Exact match
    for (final objEntry in objectCounts.entries) {
      final objName = objEntry.key.toLowerCase();
      final objCount = objEntry.value;

      if (objName == lowerName) {
        bestQuantity = objCount;
        matchedObject = objName;
  // debugPrint(
        //   '  ✓ Exact match: "$objName" → ${objCount}x',
        // );
        break;
      }
    }

    if (matchedObject != null) return bestQuantity;

    // Priority 2: Singular/Plural match
    for (final objEntry in objectCounts.entries) {
      final objName = objEntry.key.toLowerCase();
      final objCount = objEntry.value;

      if (_areSingularPlural(objName, lowerName)) {
        if (objCount > bestQuantity) {
          bestQuantity = objCount;
          matchedObject = objName;
      // debugPrint(
          //   '  ✓ Singular/plural match: "$objName" → ${objCount}x',
          // );
        }
      }
    }

    if (matchedObject != null) return bestQuantity;

    // Priority 3: Contains match (one contains the other)
    for (final objEntry in objectCounts.entries) {
      final objName = objEntry.key.toLowerCase();
      final objCount = objEntry.value;

      if (lowerName.contains(objName) || objName.contains(lowerName)) {
        if (objCount > bestQuantity) {
          bestQuantity = objCount;
          matchedObject = objName;
      // debugPrint(
          //   '  ✓ Contains match: "$objName" ↔ "$lowerName" → ${objCount}x',
          // );
        }
      }
    }

    if (matchedObject != null) return bestQuantity;

    // Priority 4: Word-level matching (e.g., "cherry tomatoes" matches "tomato")
    for (final objEntry in objectCounts.entries) {
      final objName = objEntry.key.toLowerCase();
      final objCount = objEntry.value;
      final objWords = objName.split(' ').where((w) => w.length > 3).toList();

      // Check if any food word matches any object word
      for (final foodWord in foodWords) {
        for (final objWord in objWords) {
          if (foodWord == objWord ||
              _areSingularPlural(foodWord, objWord) ||
              foodWord.contains(objWord) ||
              objWord.contains(foodWord)) {
            if (objCount > bestQuantity) {
              bestQuantity = objCount;
              matchedObject = objName;
          // debugPrint(
              //   '  ✓ Word match: "$foodWord" ↔ "$objWord" in "$objName" → ${objCount}x',
              // );
              break;
            }
          }
        }
        if (matchedObject != null) break;
      }
      if (matchedObject != null) break;
    }

    if (bestQuantity == 1) {
  // debugPrint('  ℹ️ No quantity match found, defaulting to 1x');
    }

    return bestQuantity;
  }
}

/// Result of food detection
class FoodDetectionResult {
  final String name;
  final double confidence;
  final int quantity;

  FoodDetectionResult({
    required this.name,
    required this.confidence,
    this.quantity = 1,
  });

  /// Convert to display string
  String toDisplayString() {
    if (quantity > 1) {
      return '$quantity× $name';
    }
    return name;
  }
}
