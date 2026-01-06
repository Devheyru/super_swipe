import 'package:super_swipe/core/models/recipe.dart';

/// Represents a recipe draft during AI generation, including Unsplash attribution.
/// This state persists across tab navigation until explicitly saved or cleared.
class DraftRecipe {
  final Recipe recipe;

  /// Unsplash image attribution (for legal compliance)
  final String? imageUrl;
  final String? photographerName;
  final String? photographerUrl;
  final String? unsplashPhotoUrl;

  /// Number of refinements applied to this draft (max 2)
  final int refinementCount;

  /// When this draft was created
  final DateTime createdAt;

  const DraftRecipe({
    required this.recipe,
    this.imageUrl,
    this.photographerName,
    this.photographerUrl,
    this.unsplashPhotoUrl,
    this.refinementCount = 0,
    required this.createdAt,
  });

  /// Create a new draft with an updated recipe (preserves image/attribution)
  DraftRecipe copyWithRecipe(Recipe newRecipe) {
    return DraftRecipe(
      recipe: newRecipe,
      imageUrl: imageUrl,
      photographerName: photographerName,
      photographerUrl: photographerUrl,
      unsplashPhotoUrl: unsplashPhotoUrl,
      refinementCount: refinementCount + 1,
      createdAt: createdAt,
    );
  }

  /// Create with initial image data
  DraftRecipe copyWithImage({
    required String? imageUrl,
    String? photographerName,
    String? photographerUrl,
    String? unsplashPhotoUrl,
  }) {
    return DraftRecipe(
      recipe: recipe.copyWith(imageUrl: imageUrl ?? recipe.imageUrl),
      imageUrl: imageUrl,
      photographerName: photographerName,
      photographerUrl: photographerUrl,
      unsplashPhotoUrl: unsplashPhotoUrl,
      refinementCount: refinementCount,
      createdAt: createdAt,
    );
  }

  /// Check if refinement limit reached
  bool get canRefine => refinementCount < 2;

  /// Get formatted attribution string
  String? get attributionText {
    if (photographerName == null) return null;
    return 'Photo by $photographerName on Unsplash';
  }
}
