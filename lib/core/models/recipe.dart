import 'package:cloud_firestore/cloud_firestore.dart';

class Recipe {
  final String id;
  final String title;
  final String imageUrl;
  final String description;
  final List<String> ingredients; // Display strings
  final List<String> ingredientIds; // IDs for matching
  final int energyLevel; // 0-3
  final int timeMinutes;
  final int calories;
  final List<String> equipment;

  // New Fields for Firestore Schema
  final bool isPremium;
  final List<String> dietaryTags;
  final String cuisine;
  final String timeTier; // 'under_30_min', etc.
  final RecipeStats stats;

  // Additional UI fields
  final String? cookTime;
  final String? servings;
  final String? difficulty;

  Recipe({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.description,
    required this.ingredients,
    this.ingredientIds = const [],
    this.energyLevel = 2,
    required this.timeMinutes,
    required this.calories,
    required this.equipment,
    this.isPremium = false,
    this.dietaryTags = const [],
    this.cuisine = 'other',
    this.timeTier = 'medium',
    this.stats = const RecipeStats(),
    this.cookTime,
    this.servings,
    this.difficulty,
  });

  /// Create Recipe from Firestore document
  factory Recipe.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Recipe(
      id: doc.id,
      title: data['title'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'] ?? '',
      ingredients: List<String>.from(data['ingredients'] ?? []),
      ingredientIds: List<String>.from(data['ingredientIds'] ?? []),
      energyLevel: data['energyLevel'] ?? 2,
      timeMinutes: data['timeMinutes'] ?? 30,
      calories: data['calories'] ?? 300,
      equipment: List<String>.from(data['equipment'] ?? []),
      isPremium: data['isPremium'] ?? false,
      dietaryTags: List<String>.from(data['dietaryTags'] ?? []),
      cuisine: data['cuisine'] ?? 'other',
      timeTier: data['timeTier'] ?? 'medium',
      stats: data['stats'] != null
          ? RecipeStats.fromMap(data['stats'])
          : const RecipeStats(),
      cookTime: data['cookTime'],
      servings: data['servings'],
      difficulty: data['difficulty'],
    );
  }

  /// Convert Recipe to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'imageUrl': imageUrl,
      'description': description,
      'ingredients': ingredients,
      'ingredientIds': ingredientIds,
      'energyLevel': energyLevel,
      'timeMinutes': timeMinutes,
      'calories': calories,
      'equipment': equipment,
      'isPremium': isPremium,
      'dietaryTags': dietaryTags,
      'cuisine': cuisine,
      'timeTier': timeTier,
      'stats': stats.toMap(),
      if (cookTime != null) 'cookTime': cookTime,
      if (servings != null) 'servings': servings,
      if (difficulty != null) 'difficulty': difficulty,
    };
  }
}

class RecipeStats {
  final int likes;
  final int popularityScore;

  const RecipeStats({this.likes = 0, this.popularityScore = 0});

  Map<String, dynamic> toMap() {
    return {'likes': likes, 'popularityScore': popularityScore};
  }

  factory RecipeStats.fromMap(Map<String, dynamic> map) {
    return RecipeStats(
      likes: map['likes'] ?? 0,
      popularityScore: map['popularityScore'] ?? 0,
    );
  }
}

extension RecipeExtension on Recipe {
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'description': description,
      'ingredients': ingredients,
      'ingredientIds': ingredientIds,
      'energyLevel': energyLevel,
      'timeMinutes': timeMinutes,
      'calories': calories,
      'equipment': equipment,
      'isPremium': isPremium,
      'dietaryTags': dietaryTags,
      'cuisine': cuisine,
      'timeTier': timeTier,
      'stats': stats.toMap(),
      if (cookTime != null) 'cookTime': cookTime,
      if (servings != null) 'servings': servings,
      if (difficulty != null) 'difficulty': difficulty,
    };
  }
}
