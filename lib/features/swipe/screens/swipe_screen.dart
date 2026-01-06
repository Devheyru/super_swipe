import 'dart:async';

import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:super_swipe/core/models/pantry_item.dart';
import 'package:super_swipe/core/models/recipe.dart';
import 'package:super_swipe/core/providers/app_state_provider.dart';
import 'package:super_swipe/core/providers/firestore_providers.dart';
import 'package:super_swipe/core/providers/recipe_providers.dart';
import 'package:super_swipe/core/providers/user_data_providers.dart';

import 'package:super_swipe/core/router/app_router.dart';
import 'package:super_swipe/core/theme/app_theme.dart';
import 'package:super_swipe/core/models/recipe_preview.dart';
import 'package:super_swipe/core/widgets/dialogs/confirm_unlock_dialog.dart';
import 'package:super_swipe/features/auth/providers/auth_provider.dart';
import 'package:super_swipe/services/database/database_provider.dart';

class SwipeScreen extends ConsumerStatefulWidget {
  const SwipeScreen({super.key});

  @override
  ConsumerState<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends ConsumerState<SwipeScreen> {
  final AppinioSwiperController _swiperController = AppinioSwiperController();
  int _selectedEnergyLevel = 2; // Default to 'Okay'
  bool _unlockFlowInProgress = false;

  // Filter Panel state (PDF spec)
  final TextEditingController _customPreferenceController =
      TextEditingController();
  final Set<String> _selectedMealTypes = {};
  final Set<String> _selectedDietaryTags = {};
  int? _maxMinutes;
  int? _maxCalories;
  final Set<String> _selectedFlavorProfiles = {};
  final Set<String> _selectedCuisines = {};
  final Set<String> _selectedEquipment = {};
  String _pantryFlex = 'show_all'; // exact | allow_1 | allow_2 | show_all
  final Set<String> _selectedSkillLevels = {};
  final Set<String> _selectedPrepTags = {};

  @override
  void dispose() {
    _swiperController.dispose();
    _customPreferenceController.dispose();
    super.dispose();
  }

  // Mock Recipes with real Unsplash images
  final List<Recipe> _recipes = [
    Recipe(
      id: '1',
      title: 'Creamy Mushroom Pasta',
      imageUrl:
          'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=800&q=80',
      description:
          'A rich and creamy pasta dish with fresh mushrooms and herbs.',
      ingredients: [
        '8 oz pasta',
        '2 cups sliced mushrooms',
        '1/2 cup cream',
        '2 cloves garlic',
        '1 tbsp parsley',
      ],
      instructions: [
        'Boil pasta in salted water until al dente. Reserve a splash of pasta water.',
        'Sauté sliced mushrooms in a pan until browned. Add minced garlic for 30 seconds.',
        'Add cream and a splash of pasta water, then toss in pasta until glossy.',
        'Finish with parsley, season to taste, and serve warm.',
      ],
      ingredientIds: const ['pasta', 'mushrooms', 'cream', 'garlic', 'parsley'],
      energyLevel: 2,
      timeMinutes: 25,
      calories: 520,
      equipment: ['Stovetop', 'Pot'],
      mealType: 'dinner',
      skillLevel: 'moderate',
      cuisine: 'italian',
      dietaryTags: const ['vegetarian'],
      flavorProfiles: const ['savory', 'comfort food'],
      prepTags: const ['minimal prep'],
    ),
    Recipe(
      id: '2',
      title: 'Avocado Toast',
      imageUrl:
          'https://images.unsplash.com/photo-1541519227354-08fa5d50c44d?w=800&q=80',
      description: 'Simple, healthy, and delicious avocado toast.',
      ingredients: [
        '2 slices bread',
        '1 ripe avocado',
        'Pinch of salt',
        'Pinch of pepper',
        '1/2 lemon',
      ],
      instructions: [
        'Toast the bread to your preferred crispness.',
        'Mash avocado with salt, pepper, and a squeeze of lemon.',
        'Spread on toast and serve immediately.',
      ],
      ingredientIds: const ['bread', 'avocado', 'lemon'],
      energyLevel: 1,
      timeMinutes: 8,
      calories: 320,
      equipment: ['Toaster', 'Knife'],
      mealType: 'breakfast',
      skillLevel: 'beginner',
      cuisine: 'american',
      dietaryTags: const ['vegetarian'],
      flavorProfiles: const ['savory', 'fresh and light'],
      prepTags: const ['minimal prep', 'no bake'],
    ),
    Recipe(
      id: '3',
      title: 'Spicy Chicken Curry',
      imageUrl:
          'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=800&q=80',
      description: 'Warming chicken curry with aromatic spices.',
      ingredients: [
        '1 lb chicken',
        '2 tbsp curry paste',
        '1 can coconut milk',
        '1 cup rice',
      ],
      instructions: [
        'Brown chicken pieces in a pan. Remove and set aside.',
        'Cook curry paste briefly until fragrant, then add coconut milk.',
        'Simmer chicken in sauce until cooked through. Serve with rice.',
      ],
      ingredientIds: const ['chicken', 'curry paste', 'coconut milk', 'rice'],
      energyLevel: 3,
      timeMinutes: 40,
      calories: 640,
      equipment: ['Stovetop', 'Pan'],
      mealType: 'dinner',
      skillLevel: 'advanced',
      cuisine: 'indian',
      dietaryTags: const ['gluten free', 'dairy free'],
      flavorProfiles: const ['spicy', 'savory', 'comfort food'],
      prepTags: const ['one pan'],
    ),
    Recipe(
      id: '4',
      title: 'Greek Salad',
      imageUrl:
          'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=800&q=80',
      description: 'Fresh and crisp greek salad with feta cheese.',
      ingredients: [
        '1 cucumber',
        '2 tomatoes',
        '1/2 cup feta',
        '1/4 cup olives',
        '1 tsp oregano',
      ],
      instructions: [
        'Chop cucumber and tomato and add to a bowl.',
        'Add olives and crumbled feta.',
        'Season with oregano and toss gently.',
      ],
      ingredientIds: const ['cucumber', 'tomato', 'feta', 'olives', 'oregano'],
      energyLevel: 0,
      timeMinutes: 12,
      calories: 260,
      equipment: ['Bowl', 'Knife'],
      mealType: 'lunch',
      skillLevel: 'beginner',
      cuisine: 'mediterranean',
      dietaryTags: const ['vegetarian', 'gluten free'],
      flavorProfiles: const ['fresh and light', 'savory'],
      prepTags: const ['no bake'],
    ),
    Recipe(
      id: '5',
      title: 'Berry Smoothie',
      imageUrl:
          'https://images.unsplash.com/photo-1505252585461-04db1eb84625?w=800&q=80',
      description: 'Refreshing mixed berry smoothie.',
      ingredients: [
        '1 cup mixed berries',
        '1/2 cup yogurt',
        '1 tbsp honey',
        '1/2 cup milk',
      ],
      instructions: [
        'Add berries, yogurt, honey, and milk to a blender.',
        'Blend until smooth. Add more milk to thin if needed.',
        'Pour into a glass and enjoy.',
      ],
      ingredientIds: const ['berries', 'yogurt', 'honey', 'milk'],
      energyLevel: 1,
      timeMinutes: 6,
      calories: 220,
      equipment: ['Blender'],
      mealType: 'drinks',
      skillLevel: 'beginner',
      cuisine: 'american',
      dietaryTags: const ['vegetarian', 'gluten free'],
      flavorProfiles: const ['sweet', 'fresh and light'],
      prepTags: const ['minimal prep', 'no bake'],
    ),
    Recipe(
      id: '6',
      title: 'One-Pan Veggie Stir Fry',
      imageUrl:
          'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=800&q=80',
      description: 'Colorful veggies tossed in a tangy sauce.',
      ingredients: [
        '2 cups broccoli florets',
        '1 bell pepper',
        '2 tbsp soy sauce',
        '8 oz noodles',
      ],
      instructions: [
        'Stir-fry broccoli and peppers in a hot pan until crisp-tender.',
        'Add cooked noodles and soy sauce, then toss to coat.',
        'Serve immediately while hot.',
      ],
      ingredientIds: const ['broccoli', 'peppers', 'soy sauce', 'noodles'],
      energyLevel: 2,
      timeMinutes: 18,
      calories: 410,
      equipment: ['Stovetop', 'Pan'],
      mealType: 'dinner',
      skillLevel: 'moderate',
      cuisine: 'chinese',
      dietaryTags: const ['vegetarian'],
      flavorProfiles: const ['savory', 'umami'],
      prepTags: const ['one pan'],
    ),
  ];

  String _norm(String value) => value.toLowerCase().trim();

  Set<String> _pantryKeySet(List<PantryItem> pantryItems) {
    return pantryItems
        .map((i) => _norm(i.normalizedName))
        .where((n) => n.isNotEmpty)
        .toSet();
  }

  bool _pantryHas(Set<String> pantry, String ingredientId) {
    final needle = _norm(ingredientId);
    if (needle.isEmpty) return true;
    if (pantry.contains(needle)) return true;

    // Fuzzy contains match (helps “tomato” vs “cherry tomato”)
    for (final item in pantry) {
      if (item.contains(needle) || needle.contains(item)) return true;
    }
    return false;
  }

  int _missingIngredientCount(Recipe recipe, Set<String> pantry) {
    final ids = recipe.ingredientIds.isNotEmpty
        ? recipe.ingredientIds
        : recipe.ingredients.map(_norm).toList();

    var missing = 0;
    for (final id in ids) {
      if (!_pantryHas(pantry, id)) missing++;
    }
    return missing;
  }

  bool _passesPantryFlex(Recipe recipe, Set<String> pantry) {
    final missing = _missingIngredientCount(recipe, pantry);
    switch (_pantryFlex) {
      case 'exact':
        return missing == 0;
      case 'allow_1':
        return missing <= 1;
      case 'allow_2':
        return missing <= 2;
      case 'show_all':
      default:
        return true;
    }
  }

  /// Returns filtered recipes from the given source list.
  /// If [sourceRecipes] is empty, falls back to mock [_recipes].
  List<Recipe> _getFilteredRecipes(
    Set<String> pantry, {
    List<Recipe>? sourceRecipes,
  }) {
    // Use Firestore recipes if available, otherwise fallback to mock data
    final recipesToFilter = (sourceRecipes != null && sourceRecipes.isNotEmpty)
        ? sourceRecipes
        : _recipes;

    Iterable<Recipe> results = recipesToFilter.where(
      (r) => r.energyLevel == _selectedEnergyLevel,
    );

    // 1) Pantry matching
    results = results.where((r) => _passesPantryFlex(r, pantry));

    // 2) Meal type
    if (_selectedMealTypes.isNotEmpty) {
      results = results.where(
        (r) => _selectedMealTypes.contains(_norm(r.mealType)),
      );
    }

    // 3) Time constraints
    if (_maxMinutes != null) {
      results = results.where((r) => r.timeMinutes <= _maxMinutes!);
    }

    // 3.5) Prep level
    if (_selectedPrepTags.isNotEmpty) {
      results = results.where((r) {
        final tags = r.prepTags.map(_norm).toSet();
        return _selectedPrepTags.any(tags.contains);
      });
    }

    // 4) Dietary requirements (must include all selected tags)
    if (_selectedDietaryTags.isNotEmpty) {
      results = results.where((r) {
        final tags = r.dietaryTags.map(_norm).toSet();
        return _selectedDietaryTags.every(tags.contains);
      });
    }

    // 5) Flavor and cuisine preferences
    if (_selectedFlavorProfiles.isNotEmpty) {
      results = results.where((r) {
        final flavors = r.flavorProfiles.map(_norm).toSet();
        return _selectedFlavorProfiles.any(flavors.contains);
      });
    }
    if (_selectedCuisines.isNotEmpty) {
      results = results.where(
        (r) => _selectedCuisines.contains(_norm(r.cuisine)),
      );
    }

    // 6) Equipment + Skill level
    if (_selectedEquipment.isNotEmpty) {
      results = results.where((r) {
        final equip = r.equipment.map(_norm).toSet();
        return _selectedEquipment.any(equip.contains);
      });
    }
    if (_selectedSkillLevels.isNotEmpty) {
      results = results.where(
        (r) => _selectedSkillLevels.contains(_norm(r.skillLevel)),
      );
    }

    // Calories filter (simple cap)
    if (_maxCalories != null) {
      results = results.where((r) => r.calories <= _maxCalories!);
    }

    // Rank: pantry match first (fewest missing ingredients)
    final list = results.toList();
    list.sort((a, b) {
      final aMissing = _missingIngredientCount(a, pantry);
      final bMissing = _missingIngredientCount(b, pantry);
      if (aMissing != bMissing) return aMissing.compareTo(bMissing);

      final timeCmp = a.timeMinutes.compareTo(b.timeMinutes);
      if (timeCmp != 0) return timeCmp;

      final aScore = _customPreferenceScore(a);
      final bScore = _customPreferenceScore(b);
      if (aScore != bScore) return bScore.compareTo(aScore);

      return 0;
    });
    return list;
  }

  int _customPreferenceScore(Recipe recipe) {
    final raw = _customPreferenceController.text.trim().toLowerCase();
    if (raw.isEmpty) return 0;

    final haystack = [
      recipe.title,
      recipe.description,
      ...recipe.ingredients,
      recipe.cuisine,
      recipe.mealType,
      recipe.skillLevel,
      ...recipe.flavorProfiles,
      ...recipe.equipment,
      ...recipe.prepTags,
    ].join(' ').toLowerCase();

    final tokens = raw
        .split(RegExp(r'\\s+'))
        .map((t) => t.trim())
        .where((t) => t.length >= 3)
        .toSet();

    var score = 0;
    for (final t in tokens) {
      if (haystack.contains(t)) score++;
    }
    return score;
  }

  void _onSwipeEnd(
    int previousIndex,
    int targetIndex,
    SwiperActivity activity,
  ) {
    if (activity is Swipe) {
      final pantryItems =
          ref.read(pantryItemsProvider).value ?? const <PantryItem>[];
      final firestoreRecipes =
          ref.read(swipeDeckRecipesProvider).value ?? const <Recipe>[];
      final filteredRecipes = _getFilteredRecipes(
        _pantryKeySet(pantryItems),
        sourceRecipes: firestoreRecipes,
      );
      if (previousIndex < filteredRecipes.length) {
        if (activity.direction == AxisDirection.right) {
          unawaited(_handleRightSwipe(filteredRecipes[previousIndex]));
        } else {
          // Left swipe - just dismiss
        }
      }
    }
  }

  Future<bool> _unlockRecipe(Recipe recipe) async {
    final authUser = ref.read(authProvider).user;
    final userId = authUser?.uid;

    // Block guests from unlocking - per requirements spec
    if (userId == null || authUser?.isAnonymous == true) {
      _showGuestRestrictedDialog();
      return false;
    }

    try {
      // Fix #15: Use atomic transaction for unlocking
      final success = await ref
          .read(userServiceProvider)
          .unlockRecipe(userId, recipe);

      if (!success) {
        _showOutOfCarrots();
        return false;
      }

      if (mounted) {
        final userProfile = ref.read(userProfileProvider).value;
        final isPremium =
            (userProfile?.subscriptionStatus.toLowerCase() == 'premium') ||
            (userProfile?.subscriptionStatus.toLowerCase() == 'pro');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isPremium
                  ? 'Recipe Unlocked & Saved! 🎉'
                  : 'Recipe Unlocked & Saved! 🎉 -1 Carrot',
            ),
            backgroundColor: AppTheme.primaryColor,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
      return false;
    }
  }

  void _openRecipeDetail(Recipe recipe) {
    context.push('${AppRoutes.recipes}/${recipe.id}', extra: recipe);
  }

  Future<void> _handleRightSwipe(Recipe recipe) async {
    if (_unlockFlowInProgress) return;
    setState(() => _unlockFlowInProgress = true);

    Future<void> undoLastSwipe() async {
      try {
        await _swiperController.unswipe();
      } catch (_) {
        // If there's no swipe history yet, unswipe is a no-op.
      }
    }

    try {
      final authUser = ref.read(authProvider).user;
      final userId = authUser?.uid;

      if (userId == null) {
        if (mounted) context.go(AppRoutes.login);
        await undoLastSwipe();
        return;
      }

      // Guests can swipe, but cannot unlock (must authenticate).
      if (authUser?.isAnonymous == true) {
        await undoLastSwipe();
        _showGuestRestrictedDialog();
        return;
      }

      // If already unlocked, just open the recipe page.
      final isUnlocked = await ref
          .read(recipeServiceProvider)
          .isRecipeSaved(userId, recipe.id);
      if (isUnlocked) {
        if (mounted) _openRecipeDetail(recipe);
        return;
      }

      final profile = ref.read(userProfileProvider).value;
      final subscription = profile?.subscriptionStatus.toLowerCase() ?? 'free';
      final isPremium = subscription == 'premium' || subscription == 'pro';

      // Build RecipePreview from existing recipe for dialog
      final preview = RecipePreview(
        id: recipe.id,
        title: recipe.title,
        vibeDescription: recipe.description,
        mainIngredients: recipe.ingredientIds.isNotEmpty
            ? recipe.ingredientIds.take(4).toList()
            : recipe.ingredients.take(4).toList(),
        imageUrl: recipe.imageUrl,
        estimatedTimeMinutes: recipe.timeMinutes,
        mealType: recipe.mealType,
        energyLevel: recipe.energyLevel,
      );

      final carrotsObj = profile?.carrots;
      final maxCarrots = carrotsObj?.max ?? 5;
      final currentCarrots = carrotsObj?.current ?? 0;
      final lastResetAt = carrotsObj?.lastResetAt;
      final needsReset =
          lastResetAt == null ||
          DateTime.now().difference(lastResetAt).inDays >= 7;
      final availableCarrots = needsReset ? maxCarrots : currentCarrots;

      if (!mounted) return;

      // Show ConfirmUnlockDialog immediately on swipe right
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return ConfirmUnlockDialog(
            preview: preview,
            currentCarrots: isPremium ? 999 : availableCarrots,
            maxCarrots: isPremium ? 999 : maxCarrots,
            onCancel: () => Navigator.of(dialogContext).pop(false),
            onUnlock: () => Navigator.of(dialogContext).pop(true),
          );
        },
      );

      if (confirmed != true) {
        await undoLastSwipe();
        return;
      }

      // Deduct carrot atomically (free users only)
      if (!isPremium) {
        final db = ref.read(databaseServiceProvider);
        final success = await db.deductCarrot(userId);
        if (!success) {
          _showOutOfCarrots();
          await undoLastSwipe();
          return;
        }
      }

      // Unlock and save the recipe
      final unlocked = await _unlockRecipe(recipe);
      if (unlocked && mounted) {
        _openRecipeDetail(recipe);
        return;
      }

      // Unlock failed; restore the card
      await undoLastSwipe();
    } catch (e) {
      await undoLastSwipe();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to unlock: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _unlockFlowInProgress = false);
      }
    }
  }

  void _showGuestRestrictedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Account to Unlock'),
        content: const Text(
          'Guest users can browse recipes but cannot unlock instructions.\n\n'
          'Create a free account to:\n'
          '• Unlock 5 recipes per week\n'
          '• Save your pantry\n'
          '• Track your progress\n\n'
          'Sign up now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              GoRouter.of(context).go(AppRoutes.signup);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Sign Up'),
          ),
        ],
      ),
    );
  }

  void _showOutOfCarrots() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Out of Carrots! 🥕'),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final pantryItems =
        ref.watch(pantryItemsProvider).value ?? const <PantryItem>[];
    final pantry = _pantryKeySet(pantryItems);
    final appState = ref.watch(appStateProvider);

    // Watch Firestore recipes (empty if no data, fallback to mock in _getFilteredRecipes)
    final firestoreRecipes =
        ref.watch(swipeDeckRecipesProvider).value ?? const <Recipe>[];
    final filteredRecipes = _getFilteredRecipes(
      pantry,
      sourceRecipes: firestoreRecipes,
    );

    return userProfileAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(title: const Text('Swipe for Supper')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(title: const Text('Swipe for Supper')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading profile: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
      data: (userProfile) {
        if (userProfile == null) {
          return Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            appBar: AppBar(title: const Text('Swipe for Supper')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Please sign in to continue'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go(AppRoutes.login),
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            ),
          );
        }

        final subscription = userProfile.subscriptionStatus.toLowerCase();
        final isPremium = subscription == 'premium' || subscription == 'pro';

        // Carrot economy (spec): 5/week for free users, unlimited for premium.
        // We treat a due weekly reset as "refilled" immediately so users are never stuck at 0.
        final carrots = userProfile.carrots;
        final maxCarrots = carrots.max;
        final needsReset =
            !isPremium &&
            (carrots.lastResetAt == null ||
                DateTime.now().difference(carrots.lastResetAt!).inDays >= 7);
        final carrotCount = needsReset ? maxCarrots : carrots.current;
        final canUnlock = isPremium || carrotCount > 0;

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            title: const Text('Swipe for Supper'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(
                  right: AppTheme.spacingL,
                  top: AppTheme.spacingS,
                  bottom: AppTheme.spacingS,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isPremium) ...[
                        const Text('⭐', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          'Premium',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                        ),
                      ] else ...[
                        Text(
                          '$carrotCount/$maxCarrots',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                        ),
                        const SizedBox(width: 4),
                        const Text('🥕', style: TextStyle(fontSize: 16)),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              const SizedBox(height: AppTheme.spacingS),

              // Energy Level Slider (always visible)
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingM,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppTheme.softShadow,
                ),
                child: _buildEnergySlider(),
              ),

              const SizedBox(height: AppTheme.spacingS),

              // Filter Panel (collapsed by default, state remembered)
              _buildFilterPanel(isExpanded: appState.filterExpanded),

              const SizedBox(height: AppTheme.spacingM),

              // Card Stack
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  child: filteredRecipes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.search_off_rounded,
                                size: 48,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No recipes match your filters.',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        )
                      : AppinioSwiper(
                          key: ValueKey(
                            '${Object.hashAll(filteredRecipes.map((r) => r.id))}_$carrotCount',
                          ),
                          controller: _swiperController,
                          cardCount: filteredRecipes.length,
                          isDisabled: _unlockFlowInProgress,
                          onSwipeEnd: _onSwipeEnd,
                          swipeOptions: SwipeOptions.only(
                            left: true,
                            right: canUnlock,
                          ),
                          cardBuilder: (context, index) {
                            if (index >= filteredRecipes.length) {
                              return const SizedBox();
                            }
                            return _buildRecipeCard(filteredRecipes[index]);
                          },
                        ),
                ),
              ),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingL),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildActionButton(
                      icon: Icons.close_rounded,
                      color: AppTheme.errorColor,
                      onPressed: _unlockFlowInProgress
                          ? null
                          : () => _swiperController.swipeLeft(),
                    ),
                    const SizedBox(width: AppTheme.spacingXL),
                    _buildActionButton(
                      icon: Icons.info_outline_rounded,
                      color: Colors.blueGrey,
                      isSmall: true,
                      onPressed: _unlockFlowInProgress
                          ? null
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Tap “Show Ingredients Needed” on the card to preview without unlocking.',
                                  ),
                                ),
                              );
                            },
                    ),
                    const SizedBox(width: AppTheme.spacingXL),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: canUnlock ? 1.0 : 0.5,
                      child: _buildActionButton(
                        icon: Icons.arrow_forward_rounded,
                        color: AppTheme.primaryColor,
                        onPressed: _unlockFlowInProgress
                            ? null
                            : () {
                                final authUser = ref.read(authProvider).user;
                                if (authUser == null) {
                                  context.go(AppRoutes.login);
                                  return;
                                }

                                if (canUnlock) {
                                  _swiperController.swipeRight();
                                } else {
                                  _showOutOfCarrots();
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterPanel({required bool isExpanded}) {
    const mealTypes = [
      'Breakfast',
      'Lunch',
      'Dinner',
      'Snacks',
      'Desserts',
      'Drinks',
    ];
    const dietary = [
      'High Protein',
      'Low Carb',
      'Low Fat',
      'Low Calorie',
      'High Fiber',
      'Gluten Free',
      'Dairy Free',
      'Vegetarian',
      'Vegan',
      'Nut Free',
    ];
    const flavors = [
      'Sweet',
      'Savory',
      'Spicy',
      'Mild',
      'Umami',
      'Comfort food',
      'Fresh and light',
    ];
    const cuisines = [
      'American',
      'Italian',
      'Mexican',
      'Mediterranean',
      'Japanese',
      'Chinese',
      'Thai',
      'Indian',
      'Middle Eastern',
      'French',
      'Latin inspired',
    ];
    const equipment = [
      'Microwave',
      'Stovetop',
      'Oven',
      'Air fryer',
      'Blender',
      'No equipment',
    ];
    const skillLevels = ['Beginner', 'Moderate', 'Advanced'];
    const timeCaps = [10, 20, 30, 45, 60];
    const calorieCaps = [300, 500, 700, 1000];
    const prepLevels = [
      'Minimal prep',
      'Microwave friendly',
      'One pan',
      'No chopping',
      'No bake',
    ];

    Widget sectionTitle(String text) => Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppTheme.textPrimary,
        ),
      ),
    );

    FilterChip chip({
      required String label,
      required bool selected,
      required VoidCallback onToggle,
    }) {
      return FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onToggle(),
        selectedColor: AppTheme.primaryLight.withValues(alpha: 0.35),
        checkmarkColor: AppTheme.primaryDark,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w700,
          color: selected ? AppTheme.primaryDark : AppTheme.textPrimary,
        ),
      );
    }

    ChoiceChip choice({
      required String label,
      required bool selected,
      required VoidCallback onSelect,
    }) {
      return ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelect(),
        selectedColor: AppTheme.primaryLight.withValues(alpha: 0.35),
        labelStyle: TextStyle(
          fontWeight: FontWeight.w700,
          color: selected ? AppTheme.primaryDark : AppTheme.textPrimary,
        ),
      );
    }

    Widget hScroll({required List<Widget> children}) {
      if (children.isEmpty) return const SizedBox.shrink();
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (int i = 0; i < children.length; i++) ...[
              children[i],
              if (i != children.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () async {
              await ref
                  .read(appStateProvider.notifier)
                  .setFilterExpanded(!isExpanded);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.tune_rounded, size: 18),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Filters',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  // Prevent overflow on small screens by allowing internal scroll.
                  maxHeight: MediaQuery.of(context).size.height * 0.42,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      sectionTitle('Pantry Flexibility'),
                      hScroll(
                        children: [
                          choice(
                            label: 'Exact match',
                            selected: _pantryFlex == 'exact',
                            onSelect: () =>
                                setState(() => _pantryFlex = 'exact'),
                          ),
                          choice(
                            label: 'Allow 1 missing',
                            selected: _pantryFlex == 'allow_1',
                            onSelect: () =>
                                setState(() => _pantryFlex = 'allow_1'),
                          ),
                          choice(
                            label: 'Allow 2 missing',
                            selected: _pantryFlex == 'allow_2',
                            onSelect: () =>
                                setState(() => _pantryFlex = 'allow_2'),
                          ),
                          choice(
                            label: 'Show all meals',
                            selected: _pantryFlex == 'show_all',
                            onSelect: () =>
                                setState(() => _pantryFlex = 'show_all'),
                          ),
                        ],
                      ),

                      sectionTitle('Meal Type'),
                      hScroll(
                        children: mealTypes.map((label) {
                          final key = _norm(label);
                          return chip(
                            label: label,
                            selected: _selectedMealTypes.contains(key),
                            onToggle: () => setState(() {
                              if (_selectedMealTypes.contains(key)) {
                                _selectedMealTypes.remove(key);
                              } else {
                                _selectedMealTypes.add(key);
                              }
                            }),
                          );
                        }).toList(),
                      ),

                      sectionTitle('Time (Total)'),
                      hScroll(
                        children: [
                          choice(
                            label: 'Any',
                            selected: _maxMinutes == null,
                            onSelect: () => setState(() => _maxMinutes = null),
                          ),
                          ...timeCaps.map(
                            (m) => choice(
                              label: 'Under $m min',
                              selected: _maxMinutes == m,
                              onSelect: () => setState(() => _maxMinutes = m),
                            ),
                          ),
                        ],
                      ),

                      sectionTitle('Prep level'),
                      hScroll(
                        children: prepLevels.map((label) {
                          final key = _norm(label);
                          return chip(
                            label: label,
                            selected: _selectedPrepTags.contains(key),
                            onToggle: () => setState(() {
                              if (_selectedPrepTags.contains(key)) {
                                _selectedPrepTags.remove(key);
                              } else {
                                _selectedPrepTags.add(key);
                              }
                            }),
                          );
                        }).toList(),
                      ),

                      sectionTitle('Calories'),
                      hScroll(
                        children: [
                          choice(
                            label: 'Any',
                            selected: _maxCalories == null,
                            onSelect: () => setState(() => _maxCalories = null),
                          ),
                          ...calorieCaps.map(
                            (c) => choice(
                              label: 'Under $c',
                              selected: _maxCalories == c,
                              onSelect: () => setState(() => _maxCalories = c),
                            ),
                          ),
                        ],
                      ),

                      sectionTitle('Dietary Filters'),
                      hScroll(
                        children: dietary.map((label) {
                          final key = _norm(label);
                          return chip(
                            label: label,
                            selected: _selectedDietaryTags.contains(key),
                            onToggle: () => setState(() {
                              if (_selectedDietaryTags.contains(key)) {
                                _selectedDietaryTags.remove(key);
                              } else {
                                _selectedDietaryTags.add(key);
                              }
                            }),
                          );
                        }).toList(),
                      ),

                      sectionTitle('Flavor Profile'),
                      hScroll(
                        children: flavors.map((label) {
                          final key = _norm(label);
                          return chip(
                            label: label,
                            selected: _selectedFlavorProfiles.contains(key),
                            onToggle: () => setState(() {
                              if (_selectedFlavorProfiles.contains(key)) {
                                _selectedFlavorProfiles.remove(key);
                              } else {
                                _selectedFlavorProfiles.add(key);
                              }
                            }),
                          );
                        }).toList(),
                      ),

                      sectionTitle('Cuisine Types'),
                      hScroll(
                        children: cuisines.map((label) {
                          final key = _norm(label);
                          return chip(
                            label: label,
                            selected: _selectedCuisines.contains(key),
                            onToggle: () => setState(() {
                              if (_selectedCuisines.contains(key)) {
                                _selectedCuisines.remove(key);
                              } else {
                                _selectedCuisines.add(key);
                              }
                            }),
                          );
                        }).toList(),
                      ),

                      sectionTitle('Equipment'),
                      hScroll(
                        children: equipment.map((label) {
                          final key = _norm(label);
                          return chip(
                            label: label,
                            selected: _selectedEquipment.contains(key),
                            onToggle: () => setState(() {
                              if (_selectedEquipment.contains(key)) {
                                _selectedEquipment.remove(key);
                              } else {
                                _selectedEquipment.add(key);
                              }
                            }),
                          );
                        }).toList(),
                      ),

                      sectionTitle('Skill Level'),
                      hScroll(
                        children: skillLevels.map((label) {
                          final key = _norm(label);
                          return chip(
                            label: label,
                            selected: _selectedSkillLevels.contains(key),
                            onToggle: () => setState(() {
                              if (_selectedSkillLevels.contains(key)) {
                                _selectedSkillLevels.remove(key);
                              } else {
                                _selectedSkillLevels.add(key);
                              }
                            }),
                          );
                        }).toList(),
                      ),

                      sectionTitle('Custom Preference (120 chars max)'),
                      TextField(
                        controller: _customPreferenceController,
                        maxLength: 120,
                        decoration: const InputDecoration(
                          hintText: 'e.g., Something warm and cheesy',
                        ),
                      ),

                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => setState(() {
                            _selectedMealTypes.clear();
                            _selectedDietaryTags.clear();
                            _selectedFlavorProfiles.clear();
                            _selectedCuisines.clear();
                            _selectedEquipment.clear();
                            _selectedSkillLevels.clear();
                            _selectedPrepTags.clear();
                            _maxMinutes = null;
                            _maxCalories = null;
                            _pantryFlex = 'show_all';
                            _customPreferenceController.clear();
                          }),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Clear Filters'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEnergySlider() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Energy Level',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: AppTheme.textSecondary),
              ),
              Text(
                _getEnergyLabel(_selectedEnergyLevel),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            activeTrackColor: AppTheme.primaryColor,
            inactiveTrackColor: Colors.grey.shade200,
            thumbColor: AppTheme.primaryColor,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
          ),
          child: Slider(
            value: _selectedEnergyLevel.toDouble(),
            min: 0,
            max: 3,
            divisions: 3,
            onChanged: (value) =>
                setState(() => _selectedEnergyLevel = value.round()),
          ),
        ),
      ],
    );
  }

  String _getEnergyLabel(int level) {
    switch (level) {
      case 0:
        return 'Sleepy 💤';
      case 1:
        return 'Low 🔋';
      case 2:
        return 'Okay ⚡';
      case 3:
        return 'High 🔥';
      default:
        return '';
    }
  }

  Widget _buildRecipeCard(Recipe recipe) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.mediumShadow,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (recipe.imageUrl.startsWith('http'))
                  CachedNetworkImage(
                    imageUrl: recipe.imageUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: 800,
                    placeholder: (context, url) => Container(
                      color: Colors.grey.shade200,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.broken_image,
                        size: 80,
                        color: Colors.grey,
                      ),
                    ),
                  )
                else
                  Image.asset(
                    recipe.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.image,
                        size: 80,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                // Gradient Overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.8),
                        ],
                        stops: const [0.6, 1.0],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildTag(
                          '${recipe.timeMinutes} min',
                          Icons.access_time,
                        ),
                        const SizedBox(width: 8),
                        _buildTag(
                          '${recipe.ingredients.length} items',
                          Icons.list,
                        ),
                        const SizedBox(width: 8),
                        _buildTag(
                          '${recipe.calories} cal',
                          Icons.local_fire_department,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recipe.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: recipe.equipment
                        .map((e) => _buildTag(e, Icons.kitchen_outlined))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final pantryItems =
                            ref.read(pantryItemsProvider).value ??
                            const <PantryItem>[];
                        final pantry = _pantryKeySet(pantryItems);
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (context) =>
                              _buildIngredientsModal(recipe, pantry),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Show Ingredients Needed'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _handleShowDirections(recipe),
                      icon: const Icon(
                        Icons.menu_book_outlined,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Show Directions',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    VoidCallback? onPressed,
    bool isSmall = false,
  }) {
    final size = isSmall ? 50.0 : 64.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: AppTheme.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Center(
            child: Icon(icon, color: color, size: size * 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildIngredientsModal(Recipe recipe, Set<String> pantry) {
    final ids = recipe.ingredientIds.isNotEmpty
        ? recipe.ingredientIds
        : recipe.ingredients.map(_norm).toList();

    String pretty(String raw) {
      final parts = raw.split(RegExp(r'\\s+')).where((p) => p.isNotEmpty);
      return parts
          .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
          .join(' ');
    }

    String stripQuantity(String value) {
      final v = value.trim();
      final stripped = v.replaceFirst(
        RegExp(r'^(?:\\d+(?:\\.\\d+)?|\\d+\\/\\d+)\\s+[^A-Za-z]*'),
        '',
      );
      return stripped.isEmpty ? v : stripped.trim();
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ingredients Needed',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            'Preview only — this does not use a carrot.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          ...List.generate(recipe.ingredients.length, (index) {
            final rawKey = (index < ids.length)
                ? ids[index]
                : _norm(recipe.ingredients[index]);
            final display = (index < ids.length)
                ? pretty(ids[index])
                : pretty(stripQuantity(recipe.ingredients[index]));
            final key = rawKey;
            final hasIt = _pantryHas(pantry, key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(
                    hasIt ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: hasIt ? AppTheme.successColor : AppTheme.errorColor,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      display,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hasIt ? 'Have' : 'Missing',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: hasIt
                          ? AppTheme.successColor
                          : AppTheme.errorColor,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _handleShowDirections(Recipe recipe) async {
    final authUser = ref.read(authProvider).user;
    final userId = authUser?.uid;

    if (userId == null) {
      if (mounted) context.go(AppRoutes.login);
      return;
    }

    // Guests must authenticate before unlocking directions (spec)
    if (authUser?.isAnonymous == true) {
      _showGuestRestrictedDialog();
      return;
    }

    final profile = ref.read(userProfileProvider).value;
    final subscription = profile?.subscriptionStatus.toLowerCase() ?? 'free';
    final isPremium = subscription == 'premium' || subscription == 'pro';

    // Premium users bypass the reminder and can view directions instantly.
    if (isPremium) {
      final ok = await _unlockRecipe(recipe);
      if (ok && mounted) _openRecipeDetail(recipe);
      return;
    }

    // If already unlocked, go straight to the recipe page.
    final isUnlocked = await ref
        .read(recipeServiceProvider)
        .isRecipeSaved(userId, recipe.id);
    if (isUnlocked) {
      if (mounted) _openRecipeDetail(recipe);
      return;
    }

    final appState = ref.read(appStateProvider);
    final skipReminder = appState.skipUnlockReminder;
    bool doNotShowAgain = skipReminder;

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Unlock Recipe'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    skipReminder
                        ? 'Unlock this recipe? This will use 1 carrot.'
                        : 'Unlock to view directions. This will use 1 carrot and save the recipe to your collection.',
                  ),
                  if (!skipReminder) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Checkbox(
                          value: doNotShowAgain,
                          onChanged: (value) => setDialogState(
                            () => doNotShowAgain = value ?? false,
                          ),
                        ),
                        const Expanded(
                          child: Text('Do not show this reminder again'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    if (doNotShowAgain && !skipReminder) {
                      await ref
                          .read(appStateProvider.notifier)
                          .setSkipUnlockReminder(true);
                    }
                    final ok = await _unlockRecipe(recipe);
                    if (ok && mounted) _openRecipeDetail(recipe);
                  },
                  child: const Text('Unlock Recipe'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
