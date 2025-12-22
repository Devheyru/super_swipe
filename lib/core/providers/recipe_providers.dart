import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_swipe/core/models/recipe.dart';
import 'package:super_swipe/core/providers/firestore_providers.dart';
import 'package:super_swipe/core/services/recipe_service.dart';
import 'package:super_swipe/features/auth/providers/auth_provider.dart';

/// Provider for RecipeService
final recipeServiceProvider = Provider<RecipeService>((ref) {
  return RecipeService(ref.read(firestoreServiceProvider));
});

/// StreamProvider for user's saved recipes (real-time)
final savedRecipesProvider = StreamProvider<List<Recipe>>((ref) {
  final userId = ref.watch(authProvider).user?.uid;

  if (userId == null) {
    return Stream.value([]);
  }

  return ref.read(recipeServiceProvider).watchSavedRecipes(userId);
});

/// StreamProvider for a single saved recipe document (used for Recipe Detail page)
final savedRecipeProvider = StreamProvider.family<Recipe?, String>((
  ref,
  recipeId,
) {
  final userId = ref.watch(authProvider).user?.uid;
  if (userId == null) return Stream.value(null);

  final firestore = ref.watch(firestoreServiceProvider);
  return firestore
      .userSavedRecipes(userId)
      .doc(recipeId)
      .snapshots()
      .map((doc) => doc.exists ? Recipe.fromFirestore(doc) : null);
});

/// Provider to check if a specific recipe is saved
final isRecipeSavedProvider = FutureProvider.family<bool, String>((
  ref,
  recipeId,
) async {
  final userId = ref.watch(authProvider).user?.uid;

  if (userId == null) {
    return false;
  }

  return ref.read(recipeServiceProvider).isRecipeSaved(userId, recipeId);
});

/// Provider for saved recipes count
final savedRecipesCountProvider = Provider<int>((ref) {
  final savedRecipes = ref.watch(savedRecipesProvider);
  return savedRecipes.when(
    data: (recipes) => recipes.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});
