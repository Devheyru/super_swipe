import 'package:cloud_firestore/cloud_firestore.dart';

class Recipe {
  final String id;
  final String title;
  final String imageUrl;
  final String description;
  final List<String> ingredients; // Display strings
  final List<String> instructions; // Step-by-step directions
  final List<String> ingredientIds; // IDs for matching
  final int energyLevel; // 0-3
  final int timeMinutes;
  final int calories;
  final List<String> equipment;

  /// Discovery metadata (used by Swipe filters)
  final String
  mealType; // breakfast | lunch | dinner | snacks | desserts | drinks
  final String skillLevel; // beginner | moderate | advanced
  final List<String>
  flavorProfiles; // sweet | savory | spicy | mild | umami | comfort food | fresh and light
  final List<String>
  prepTags; // minimal prep | microwave friendly | one pan | no chopping | no bake

  // New Fields for Firestore Schema
  final bool isPremium;
  final List<String> dietaryTags;
  final String cuisine;
  final String timeTier; // 'under_30_min', etc.
  final RecipeStats stats;
  // Fix #8: Case-insensitivity
  final String titleLowercase;

  // Additional UI fields
  final String? cookTime;
  final String? servings;
  final String? difficulty;

  /// Saved-recipe progress (stored in `users/{uid}/savedRecipes/{recipeId}`)
  /// Step number last reached (0 = not started).
  final int currentStep;
  final DateTime? savedAt;
  final DateTime? lastStepAt;

  /// Favorite/Like status (heart icon)
  final bool isFavorite;

  Recipe({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.description,
    required this.ingredients,
    this.instructions = const [],
    this.ingredientIds = const [],
    this.energyLevel = 2,
    required this.timeMinutes,
    required this.calories,
    required this.equipment,
    this.mealType = 'dinner',
    this.skillLevel = 'beginner',
    this.flavorProfiles = const [],
    this.prepTags = const [],
    this.isPremium = false,
    this.dietaryTags = const [],
    this.cuisine = 'other',
    this.timeTier = 'medium',
    this.stats = const RecipeStats(),
    // Fix #8: Auto-generate if not provided
    String? titleLowercase,
    this.cookTime,
    this.servings,
    this.difficulty,
    this.currentStep = 0,
    this.savedAt,
    this.lastStepAt,
    this.isFavorite = false,
  }) : titleLowercase = titleLowercase ?? title.toLowerCase();

  /// Create Recipe from Firestore document
  factory Recipe.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};

    return Recipe(
      id: doc.id,
      title: data['title'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'] ?? '',
      ingredients: List<String>.from(data['ingredients'] ?? []),
      instructions: List<String>.from(data['instructions'] ?? []),
      ingredientIds: List<String>.from(data['ingredientIds'] ?? []),
      energyLevel: data['energyLevel'] ?? 2,
      timeMinutes: data['timeMinutes'] ?? 30,
      calories: data['calories'] ?? 300,
      equipment: List<String>.from(data['equipment'] ?? []),
      mealType: data['mealType'] ?? 'dinner',
      skillLevel: data['skillLevel'] ?? 'beginner',
      flavorProfiles: List<String>.from(data['flavorProfiles'] ?? []),
      prepTags: List<String>.from(data['prepTags'] ?? []),
      isPremium: data['isPremium'] ?? false,
      dietaryTags: List<String>.from(data['dietaryTags'] ?? []),
      cuisine: data['cuisine'] ?? 'other',
      timeTier: data['timeTier'] ?? 'medium',
      stats: data['stats'] != null
          ? RecipeStats.fromMap(data['stats'])
          : const RecipeStats(),
      // Fix #8: Parse lowercase title
      titleLowercase: data['titleLowercase'],
      cookTime: data['cookTime'],
      servings: data['servings'],
      difficulty: data['difficulty'],
      currentStep: (data['currentStep'] as num?)?.toInt() ?? 0,
      savedAt: (data['savedAt'] as Timestamp?)?.toDate(),
      lastStepAt: (data['lastStepAt'] as Timestamp?)?.toDate(),
      isFavorite: data['isFavorite'] ?? false,
    );
  }

  /// Convert Recipe to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'imageUrl': imageUrl,
      'description': description,
      'ingredients': ingredients,
      'instructions': instructions,
      'ingredientIds': ingredientIds,
      'energyLevel': energyLevel,
      'timeMinutes': timeMinutes,
      'calories': calories,
      'equipment': equipment,
      'mealType': mealType,
      'skillLevel': skillLevel,
      'flavorProfiles': flavorProfiles,
      'prepTags': prepTags,
      'isPremium': isPremium,
      'dietaryTags': dietaryTags,
      'cuisine': cuisine,
      'timeTier': timeTier,
      'stats': stats.toMap(),
      // Fix #8: Persist lowercase title
      'titleLowercase': titleLowercase,
      if (cookTime != null) 'cookTime': cookTime,
      if (servings != null) 'servings': servings,
      if (difficulty != null) 'difficulty': difficulty,
    };
  }

  /// Firestore map for `users/{uid}/savedRecipes/{recipeId}`
  /// Stores enough data to render the Recipe page offline and track progress.
  Map<String, dynamic> toSavedRecipeFirestore() {
    return {
      'recipeId': id,
      'title': title,
      'titleLowercase': titleLowercase,
      'imageUrl': imageUrl,
      'description': description,
      'ingredients': ingredients,
      'instructions': instructions,
      'ingredientIds': ingredientIds,
      'energyLevel': energyLevel,
      'timeMinutes': timeMinutes,
      'calories': calories,
      'equipment': equipment,
      'mealType': mealType,
      'skillLevel': skillLevel,
      'flavorProfiles': flavorProfiles,
      'prepTags': prepTags,
      'isPremium': isPremium,
      'dietaryTags': dietaryTags,
      'cuisine': cuisine,
      'timeTier': timeTier,
      'cookTime': cookTime,
      'servings': servings,
      'difficulty': difficulty,
      'currentStep': currentStep,
      'savedAt': FieldValue.serverTimestamp(),
      'lastStepAt': FieldValue.serverTimestamp(),
      'isFavorite': isFavorite,
    };
  }

  /// Create a copy with updated fields
  Recipe copyWith({
    String? id,
    String? title,
    String? imageUrl,
    String? description,
    List<String>? ingredients,
    List<String>? instructions,
    List<String>? ingredientIds,
    int? energyLevel,
    int? timeMinutes,
    int? calories,
    List<String>? equipment,
    String? mealType,
    String? skillLevel,
    List<String>? flavorProfiles,
    List<String>? prepTags,
    bool? isPremium,
    List<String>? dietaryTags,
    String? cuisine,
    String? timeTier,
    RecipeStats? stats,
    String? titleLowercase,
    String? cookTime,
    String? servings,
    String? difficulty,
    int? currentStep,
    DateTime? savedAt,
    DateTime? lastStepAt,
    bool? isFavorite,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      ingredientIds: ingredientIds ?? this.ingredientIds,
      energyLevel: energyLevel ?? this.energyLevel,
      timeMinutes: timeMinutes ?? this.timeMinutes,
      calories: calories ?? this.calories,
      equipment: equipment ?? this.equipment,
      mealType: mealType ?? this.mealType,
      skillLevel: skillLevel ?? this.skillLevel,
      flavorProfiles: flavorProfiles ?? this.flavorProfiles,
      prepTags: prepTags ?? this.prepTags,
      isPremium: isPremium ?? this.isPremium,
      dietaryTags: dietaryTags ?? this.dietaryTags,
      cuisine: cuisine ?? this.cuisine,
      timeTier: timeTier ?? this.timeTier,
      stats: stats ?? this.stats,
      titleLowercase: titleLowercase ?? this.titleLowercase,
      cookTime: cookTime ?? this.cookTime,
      servings: servings ?? this.servings,
      difficulty: difficulty ?? this.difficulty,
      currentStep: currentStep ?? this.currentStep,
      savedAt: savedAt ?? this.savedAt,
      lastStepAt: lastStepAt ?? this.lastStepAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
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
      'instructions': instructions,
      'ingredientIds': ingredientIds,
      'energyLevel': energyLevel,
      'timeMinutes': timeMinutes,
      'calories': calories,
      'equipment': equipment,
      'mealType': mealType,
      'skillLevel': skillLevel,
      'flavorProfiles': flavorProfiles,
      'prepTags': prepTags,
      'isPremium': isPremium,
      'dietaryTags': dietaryTags,
      'cuisine': cuisine,
      'timeTier': timeTier,
      'stats': stats.toMap(),
      // Fix #8: Include in map export
      'titleLowercase': titleLowercase,
      if (cookTime != null) 'cookTime': cookTime,
      if (servings != null) 'servings': servings,
      if (difficulty != null) 'difficulty': difficulty,
      'currentStep': currentStep,
      if (savedAt != null) 'savedAt': savedAt,
      if (lastStepAt != null) 'lastStepAt': lastStepAt,
    };
  }
}
