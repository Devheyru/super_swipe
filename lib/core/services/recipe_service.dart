import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:super_swipe/core/models/recipe.dart';
import 'package:super_swipe/core/services/firestore_service.dart';

/// Service for managing recipe operations in Firestore
class RecipeService {
  final FirestoreService _firestoreService;

  // Pagination state
  DocumentSnapshot? _lastRecipeDocument;

  RecipeService(this._firestoreService);

  /// Save a recipe to user's saved recipes
  Future<void> saveRecipe(String userId, Recipe recipe) async {
    await _firestoreService.userSavedRecipes(userId).doc(recipe.id).set({
      'recipeId': recipe.id,
      'title': recipe.title,
      'imageUrl': recipe.imageUrl,
      'cookTime': recipe.cookTime ?? '${recipe.timeMinutes} min',
      'servings': recipe.servings ?? '${recipe.timeMinutes ~/ 20} servings',
      'difficulty': recipe.difficulty ?? 'Medium',
      'calories': recipe.calories,
      'savedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get all saved recipes for a user (one-time fetch)
  Future<List<Recipe>> getSavedRecipes(String userId) async {
    final snapshot = await _firestoreService
        .userSavedRecipes(userId)
        .orderBy('savedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList();
  }

  /// Stream saved recipes (real-time updates)
  Stream<List<Recipe>> watchSavedRecipes(String userId) {
    return _firestoreService
        .userSavedRecipes(userId)
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList();
        });
  }

  /// Remove a recipe from saved recipes
  Future<void> unsaveRecipe(String userId, String recipeId) async {
    await _firestoreService.userSavedRecipes(userId).doc(recipeId).delete();
  }

  /// Check if a recipe is saved
  Future<bool> isRecipeSaved(String userId, String recipeId) async {
    final doc = await _firestoreService
        .userSavedRecipes(userId)
        .doc(recipeId)
        .get();
    return doc.exists;
  }

  /// Add recipe to history
  Future<void> addToHistory(String userId, String recipeId) async {
    await _firestoreService.userRecipeHistory(userId).add({
      'recipeId': recipeId,
      'viewedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get recipe history
  Future<List<Map<String, dynamic>>> getRecipeHistory(String userId) async {
    final snapshot = await _firestoreService
        .userRecipeHistory(userId)
        .orderBy('viewedAt', descending: true)
        .limit(20)
        .get();

    return snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
        .toList();
  }

  /// Delete all saved recipes for a user
  Future<void> clearSavedRecipes(String userId) async {
    final batch = _firestoreService.instance.batch();
    final snapshot = await _firestoreService.userSavedRecipes(userId).get();

    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // ============================================
  // RECIPE DISCOVERY & PAGINATION
  // ============================================

  /// Get recipes by energy level with pagination
  Future<List<Recipe>> getRecipesByEnergyLevel({
    required int energyLevel,
    int limit = 10,
    bool loadMore = false,
  }) async {
    Query query = _firestoreService.recipes
        .where('isActive', isEqualTo: true)
        .where('energyLevel', isEqualTo: energyLevel)
        .orderBy('stats.popularityScore', descending: true)
        .limit(limit);

    // If loading more, start after last document
    if (loadMore && _lastRecipeDocument != null) {
      query = query.startAfterDocument(_lastRecipeDocument!);
    } else {
      // Reset pagination for new query
      _lastRecipeDocument = null;
    }

    final snapshot = await query.get();

    if (snapshot.docs.isNotEmpty) {
      _lastRecipeDocument = snapshot.docs.last;
    }

    return snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList();
  }

  /// Stream recipes by energy level (real-time, first page only)
  Stream<List<Recipe>> watchRecipesByEnergyLevel({
    required int energyLevel,
    int limit = 10,
  }) {
    return _firestoreService.recipes
        .where('isActive', isEqualTo: true)
        .where('energyLevel', isEqualTo: energyLevel)
        .orderBy('stats.popularityScore', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList();
        });
  }

  /// Get all recipes (for admin/seeding purposes)
  Future<List<Recipe>> getAllRecipes() async {
    final snapshot = await _firestoreService.recipes
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList();
  }

  /// Search recipes by title or ingredients
  Future<List<Recipe>> searchRecipes(String query) async {
    final normalizedQuery = query.toLowerCase().trim();

    final snapshot = await _firestoreService.recipes
        .where('isActive', isEqualTo: true)
        .orderBy('title')
        .startAt([normalizedQuery])
        .endAt(['$normalizedQuery\uf8ff'])
        .limit(20)
        .get();

    return snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList();
  }

  /// Get recipe by ID
  Future<Recipe?> getRecipeById(String recipeId) async {
    final doc = await _firestoreService.recipes.doc(recipeId).get();
    if (doc.exists) {
      return Recipe.fromFirestore(doc);
    }
    return null;
  }

  /// Reset pagination (call when changing filters)
  void resetPagination() {
    _lastRecipeDocument = null;
  }

  /// Check if more recipes are available
  bool get hasMoreRecipes => _lastRecipeDocument != null;
}
