import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_swipe/core/models/draft_recipe.dart';
import 'package:super_swipe/core/models/recipe.dart';
import 'package:super_swipe/services/image/image_search_service.dart';

/// Manages draft recipe state across navigation.
/// NOT auto-disposed to persist across tab switches.
class DraftRecipeNotifier extends StateNotifier<DraftRecipe?> {
  DraftRecipeNotifier() : super(null);

  /// Set a new draft from initial generation
  void setDraft(Recipe recipe, {UnsplashImageResult? imageResult}) {
    state = DraftRecipe(
      recipe: imageResult != null
          ? recipe.copyWith(imageUrl: imageResult.imageUrl)
          : recipe,
      imageUrl: imageResult?.imageUrl,
      photographerName: imageResult?.photographerName,
      photographerUrl: imageResult?.photographerUrl,
      unsplashPhotoUrl: imageResult?.unsplashPhotoUrl,
      refinementCount: 0,
      createdAt: DateTime.now(),
    );
  }

  /// Update draft with refined recipe (preserves image)
  void updateWithRefinement(Recipe refinedRecipe) {
    if (state == null) return;

    // Preserve the original image URL in the refined recipe
    final updatedRecipe = refinedRecipe.copyWith(
      imageUrl: state!.imageUrl ?? refinedRecipe.imageUrl,
    );

    state = state!.copyWithRecipe(updatedRecipe);
  }

  /// Clear draft (on Save or Cancel)
  void clearDraft() {
    state = null;
  }

  /// Check if refinement is allowed
  bool get canRefine => state?.canRefine ?? false;

  /// Get current refinement count
  int get refinementCount => state?.refinementCount ?? 0;
}

/// Non-autodispose provider for draft recipe persistence across tabs
final draftRecipeProvider =
    StateNotifierProvider<DraftRecipeNotifier, DraftRecipe?>((ref) {
      return DraftRecipeNotifier();
    });
