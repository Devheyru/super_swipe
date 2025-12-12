import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_swipe/core/models/recipe.dart';

class CarrotState {
  final int carrotCount;
  final List<Recipe> unlockedRecipes;

  CarrotState({
    required this.carrotCount,
    required this.unlockedRecipes,
  });

  CarrotState copyWith({
    int? carrotCount,
    List<Recipe>? unlockedRecipes,
  }) {
    return CarrotState(
      carrotCount: carrotCount ?? this.carrotCount,
      unlockedRecipes: unlockedRecipes ?? this.unlockedRecipes,
    );
  }
}

class CarrotNotifier extends Notifier<CarrotState> {
  @override
  CarrotState build() {
    return CarrotState(
      carrotCount: 5, // Initialized to 5 as per requirements
      unlockedRecipes: [],
    );
  }

  bool canSwipe() {
    return state.carrotCount > 0;
  }

  bool unlockRecipe(Recipe recipe) {
    if (state.carrotCount > 0) {
      // Check if already unlocked to avoid double spending (optional logic, but good UX)
      if (state.unlockedRecipes.any((r) => r.id == recipe.id)) {
        return true;
      }

      state = state.copyWith(
        carrotCount: state.carrotCount - 1,
        unlockedRecipes: [...state.unlockedRecipes, recipe],
      );
      return true;
    }
    return false;
  }

  void resetCarrots() {
    state = state.copyWith(carrotCount: 5);
  }
}

final carrotProvider = NotifierProvider<CarrotNotifier, CarrotState>(CarrotNotifier.new);


