import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_swipe/core/models/pantry_item.dart';
import 'package:super_swipe/services/database/database_service.dart';

/// Local state for Guest users (Shadow State).
/// Data lives in memory only and is NOT persisted to Firestore.
/// Upon sign up, this state is migrated to Firestore.
class GuestState {
  final List<PantryItem> pantry;
  final List<String> likedRecipeIds;
  final List<String> skippedRecipeIds;
  final int sessionSwipeCount;

  const GuestState({
    this.pantry = const [],
    this.likedRecipeIds = const [],
    this.skippedRecipeIds = const [],
    this.sessionSwipeCount = 0,
  });

  GuestState copyWith({
    List<PantryItem>? pantry,
    List<String>? likedRecipeIds,
    List<String>? skippedRecipeIds,
    int? sessionSwipeCount,
  }) {
    return GuestState(
      pantry: pantry ?? this.pantry,
      likedRecipeIds: likedRecipeIds ?? this.likedRecipeIds,
      skippedRecipeIds: skippedRecipeIds ?? this.skippedRecipeIds,
      sessionSwipeCount: sessionSwipeCount ?? this.sessionSwipeCount,
    );
  }
}

/// Notifier for managing Guest Shadow State.
class GuestStateNotifier extends StateNotifier<GuestState> {
  GuestStateNotifier() : super(const GuestState());

  // ============================================================
  // PANTRY MANAGEMENT (Local Only)
  // ============================================================

  /// Adds an item to the local guest pantry.
  void addPantryItem({
    required String name,
    String category = 'other',
    int quantity = 1,
    String unit = 'pieces',
  }) {
    final newItem = PantryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Temp ID
      userId: 'guest',
      name: name,
      normalizedName: name.toLowerCase().trim(),
      category: category,
      quantity: quantity,
      unit: unit,
      source: 'manual',
      addedAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    state = state.copyWith(pantry: [...state.pantry, newItem]);
  }

  /// Updates a pantry item.
  void updatePantryItem(String itemId, {int? quantity, String? name}) {
    final updatedPantry = state.pantry.map((item) {
      if (item.id == itemId) {
        return item.copyWith(quantity: quantity, name: name);
      }
      return item;
    }).toList();

    state = state.copyWith(pantry: updatedPantry);
  }

  /// Removes a pantry item.
  void removePantryItem(String itemId) {
    final updatedPantry = state.pantry
        .where((item) => item.id != itemId)
        .toList();
    state = state.copyWith(pantry: updatedPantry);
  }

  /// Clears all pantry items.
  void clearPantry() {
    state = state.copyWith(pantry: []);
  }

  // ============================================================
  // SWIPE TRACKING (Local Only)
  // ============================================================

  /// Records a right swipe (like) - Guest can't unlock, just track.
  void recordLike(String recipeId) {
    if (state.likedRecipeIds.contains(recipeId)) return;

    state = state.copyWith(
      likedRecipeIds: [...state.likedRecipeIds, recipeId],
      sessionSwipeCount: state.sessionSwipeCount + 1,
    );
  }

  /// Records a left swipe (skip).
  void recordSkip(String recipeId) {
    if (state.skippedRecipeIds.contains(recipeId)) return;

    state = state.copyWith(
      skippedRecipeIds: [...state.skippedRecipeIds, recipeId],
      sessionSwipeCount: state.sessionSwipeCount + 1,
    );
  }

  /// Checks if a recipe was already swiped.
  bool hasSwipedRecipe(String recipeId) {
    return state.likedRecipeIds.contains(recipeId) ||
        state.skippedRecipeIds.contains(recipeId);
  }

  // ============================================================
  // MIGRATION TO FIRESTORE
  // ============================================================

  /// Migrates all guest data to Firestore after sign up.
  /// Called once after AuthService.signUp() succeeds.
  /// Uses ATOMIC single-batch write to prevent partial migration.
  Future<void> migrateToFirestore(String userId) async {
    final db = DatabaseService();

    // Migrate all guest data in a SINGLE atomic operation
    await db.migrateGuestData(
      userId,
      guestPantry: state.pantry,
      likedRecipeIds: state.likedRecipeIds,
    );

    // Clear local state after successful migration
    reset();
  }

  /// Resets all guest state (after migration or logout).
  void reset() {
    state = const GuestState();
  }
}

// ============================================================
// PROVIDERS
// ============================================================

/// Provider for Guest State management.
final guestStateProvider =
    StateNotifierProvider<GuestStateNotifier, GuestState>((ref) {
      return GuestStateNotifier();
    });

/// Convenience provider for guest pantry items.
final guestPantryProvider = Provider<List<PantryItem>>((ref) {
  return ref.watch(guestStateProvider).pantry;
});

/// Provider to check if user is a guest (based on auth state).
/// This should be used in conjunction with AuthProvider.
final isGuestModeProvider = Provider<bool>((ref) {
  // This will be connected to the actual auth provider
  // For now, return false - actual implementation will check auth state
  return false;
});
