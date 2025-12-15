import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:super_swipe/core/models/recipe.dart';
import 'package:super_swipe/core/providers/firestore_providers.dart';
import 'package:super_swipe/core/providers/user_data_providers.dart';

import 'package:super_swipe/core/router/app_router.dart';
import 'package:super_swipe/core/theme/app_theme.dart';
import 'package:super_swipe/features/auth/providers/auth_provider.dart';

class SwipeScreen extends ConsumerStatefulWidget {
  const SwipeScreen({super.key});

  @override
  ConsumerState<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends ConsumerState<SwipeScreen> {
  final AppinioSwiperController _swiperController = AppinioSwiperController();
  int _selectedEnergyLevel = 2; // Default to 'Okay'

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  // Mock Recipes with real Unsplash images
  final List<Recipe> _recipes = [
    Recipe(
      id: '1',
      title: 'Creamy Mushroom Pasta',
      imageUrl: 'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=800&q=80',
      description:
          'A rich and creamy pasta dish with fresh mushrooms and herbs.',
      ingredients: ['Pasta', 'Mushrooms', 'Cream', 'Garlic', 'Parsley'],
      energyLevel: 2,
      timeMinutes: 25,
      calories: 520,
      equipment: ['Stovetop', 'Pot'],
    ),
    Recipe(
      id: '2',
      title: 'Avocado Toast',
      imageUrl: 'https://images.unsplash.com/photo-1541519227354-08fa5d50c44d?w=800&q=80',
      description: 'Simple, healthy, and delicious avocado toast.',
      ingredients: ['Bread', 'Avocado', 'Salt', 'Pepper', 'Lemon'],
      energyLevel: 1,
      timeMinutes: 8,
      calories: 320,
      equipment: ['Toaster', 'Knife'],
    ),
    Recipe(
      id: '3',
      title: 'Spicy Chicken Curry',
      imageUrl: 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=800&q=80',
      description: 'Warming chicken curry with aromatic spices.',
      ingredients: ['Chicken', 'Curry Paste', 'Coconut Milk', 'Rice'],
      energyLevel: 3,
      timeMinutes: 40,
      calories: 640,
      equipment: ['Stovetop', 'Pan'],
    ),
    Recipe(
      id: '4',
      title: 'Greek Salad',
      imageUrl: 'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=800&q=80',
      description: 'Fresh and crisp greek salad with feta cheese.',
      ingredients: ['Cucumber', 'Tomato', 'Feta', 'Olives', 'Oregano'],
      energyLevel: 0,
      timeMinutes: 12,
      calories: 260,
      equipment: ['Bowl', 'Knife'],
    ),
    Recipe(
      id: '5',
      title: 'Berry Smoothie',
      imageUrl: 'https://images.unsplash.com/photo-1505252585461-04db1eb84625?w=800&q=80',
      description: 'Refreshing mixed berry smoothie.',
      ingredients: ['Mixed Berries', 'Yogurt', 'Honey', 'Milk'],
      energyLevel: 1,
      timeMinutes: 6,
      calories: 220,
      equipment: ['Blender'],
    ),
    Recipe(
      id: '6',
      title: 'One-Pan Veggie Stir Fry',
      imageUrl: 'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=800&q=80',
      description: 'Colorful veggies tossed in a tangy sauce.',
      ingredients: ['Broccoli', 'Peppers', 'Soy Sauce', 'Noodles'],
      energyLevel: 2,
      timeMinutes: 18,
      calories: 410,
      equipment: ['Stovetop', 'Pan'],
    ),
  ];

  void _onSwipeEnd(
    int previousIndex,
    int targetIndex,
    SwiperActivity activity,
  ) {
    if (activity is Swipe) {
      final filteredRecipes = _recipes
          .where((r) => r.energyLevel == _selectedEnergyLevel)
          .toList();
      if (previousIndex < filteredRecipes.length) {
        if (activity.direction == AxisDirection.right) {
          _handleRightSwipe(filteredRecipes[previousIndex]);
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

    final userProfile = ref.read(userProfileProvider).value;
    if (userProfile == null || userProfile.carrots.current <= 0) {
      _showOutOfCarrots();
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

      // Stats are now updated atomically in unlockRecipe

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recipe Unlocked & Saved! 🎉 -1 Carrot'),
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

  void _handleRightSwipe(Recipe recipe) async {
    await _promptUnlockFlow(recipe);
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
    final filteredRecipes = _recipes
        .where((r) => r.energyLevel == _selectedEnergyLevel)
        .toList();

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

        final carrotCount = userProfile.carrots.current;
        final maxCarrots = userProfile.carrots.max;
        final canUnlock = carrotCount > 0;

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
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
                      Text(
                        '$carrotCount/$maxCarrots',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text('🥕', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              const SizedBox(height: AppTheme.spacingS),
              // Energy Slider
              _buildEnergySlider(),

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
                                'No recipes for this energy level!',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        )
                      : AppinioSwiper(
                          key: ValueKey('${_selectedEnergyLevel}_$carrotCount'),
                          controller: _swiperController,
                          cardCount: filteredRecipes.length,
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
                      onPressed: () => _swiperController.swipeLeft(),
                    ),
                    const SizedBox(width: AppTheme.spacingXL),
                    _buildActionButton(
                      icon: Icons.info_outline_rounded,
                      color: Colors.blueGrey,
                      isSmall: true,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tap View Ingredients on the card.'),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: AppTheme.spacingXL),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: canUnlock ? 1.0 : 0.5,
                      child: _buildActionButton(
                        icon: Icons.favorite_rounded,
                        color: AppTheme.primaryColor,
                        onPressed: () {
                          final authUser = ref.read(authProvider).user;
                          if (authUser == null || authUser.isAnonymous) {
                            _showGuestRestrictedDialog();
                            return;
                          }
                          if (canUnlock) {
                            _swiperController.swipeRight();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Out of Carrots! 🥕'),
                              ),
                            );
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

  Widget _buildEnergySlider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Energy Level',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
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
      ),
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
                  Row(
                    children: [
                      _buildTag('${recipe.timeMinutes} min', Icons.access_time),
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
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (context) => _buildIngredientsModal(recipe),
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
                      child: const Text('View Ingredients'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _promptUnlockDirections(recipe),
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
    required VoidCallback onPressed,
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

  Widget _buildIngredientsModal(Recipe recipe) {
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
          Text('Ingredients', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recipe.ingredients
                .map((ing) => Chip(label: Text(ing)))
                .toList(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _promptUnlockDirections(Recipe recipe) {
    _promptUnlockFlow(recipe, fromDirections: true);
  }

  Future<void> _promptUnlockFlow(
    Recipe recipe, {
    bool fromDirections = false,
  }) async {
    final authUser = ref.read(authProvider).user;
    final userId = authUser?.uid;

    // Block guests from unlocking - per requirements spec
    if (userId == null || authUser?.isAnonymous == true) {
      _showGuestRestrictedDialog();
      return;
    }

    final userProfile = ref.read(userProfileProvider).value;
    if (userProfile == null || userProfile.carrots.current <= 0) {
      _showOutOfCarrots();
      return;
    }

    // Simple unlock confirmation
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Unlock Recipe'),
        content: const Text(
          'Unlock this recipe? This will use 1 carrot and save the recipe to your collection.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _unlockRecipe(recipe);
            },
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
  }
}
