import 'package:cloud_firestore/cloud_firestore.dart';

/// Lightweight recipe preview model for swipe deck cards.
/// Contains only essential info - no instructions (saves on AI costs).
/// Full recipe is generated only after carrot spend.
class RecipePreview {
  final String id;
  final String title;
  final String vibeDescription;
  final List<String> mainIngredients;
  final String? imageUrl;
  final int estimatedTimeMinutes;
  final String mealType;
  final int energyLevel;

  const RecipePreview({
    required this.id,
    required this.title,
    required this.vibeDescription,
    required this.mainIngredients,
    this.imageUrl,
    this.estimatedTimeMinutes = 30,
    this.mealType = 'dinner',
    this.energyLevel = 2,
  });

  /// Create from OpenAI JSON response
  factory RecipePreview.fromJson(Map<String, dynamic> json) {
    return RecipePreview(
      id: 'preview_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] ?? 'Chef\'s Special',
      vibeDescription: json['vibe_description'] ?? json['description'] ?? '',
      mainIngredients: List<String>.from(json['main_ingredients'] ?? []),
      estimatedTimeMinutes: json['estimated_time_minutes'] ?? 30,
      mealType: json['meal_type'] ?? 'dinner',
      energyLevel: json['energy_level'] ?? 2,
    );
  }

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'vibe_description': vibeDescription,
      'main_ingredients': mainIngredients,
      'estimated_time_minutes': estimatedTimeMinutes,
      'meal_type': mealType,
      'energy_level': energyLevel,
    };
  }

  /// Create from Firestore document
  factory RecipePreview.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
    return RecipePreview(
      id: doc.id,
      title: data['title'] ?? '',
      vibeDescription: data['vibeDescription'] ?? data['description'] ?? '',
      mainIngredients: List<String>.from(data['mainIngredients'] ?? []),
      imageUrl: data['imageUrl'],
      estimatedTimeMinutes: data['estimatedTimeMinutes'] ?? 30,
      mealType: data['mealType'] ?? 'dinner',
      energyLevel: data['energyLevel'] ?? 2,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'vibeDescription': vibeDescription,
      'mainIngredients': mainIngredients,
      'imageUrl': imageUrl,
      'estimatedTimeMinutes': estimatedTimeMinutes,
      'mealType': mealType,
      'energyLevel': energyLevel,
    };
  }

  RecipePreview copyWith({
    String? id,
    String? title,
    String? vibeDescription,
    List<String>? mainIngredients,
    String? imageUrl,
    int? estimatedTimeMinutes,
    String? mealType,
    int? energyLevel,
  }) {
    return RecipePreview(
      id: id ?? this.id,
      title: title ?? this.title,
      vibeDescription: vibeDescription ?? this.vibeDescription,
      mainIngredients: mainIngredients ?? this.mainIngredients,
      imageUrl: imageUrl ?? this.imageUrl,
      estimatedTimeMinutes: estimatedTimeMinutes ?? this.estimatedTimeMinutes,
      mealType: mealType ?? this.mealType,
      energyLevel: energyLevel ?? this.energyLevel,
    );
  }
}
