import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:super_swipe/core/models/recipe.dart';
import 'package:super_swipe/core/providers/app_state_provider.dart';
import 'package:super_swipe/core/router/app_router.dart';
import 'package:super_swipe/core/theme/app_theme.dart';

class SwipeScreen extends ConsumerStatefulWidget {
  const SwipeScreen({super.key});

  @override
  ConsumerState<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends ConsumerState<SwipeScreen> {
  final AppinioSwiperController _swiperController = AppinioSwiperController();
  int _selectedEnergyLevel = 2; // Default to 'Okay'

  // Mock Recipes
  final List<Recipe> _recipes = [
    Recipe(
      id: '1',
      title: 'Creamy Mushroom Pasta',
      imageUrl: 'assets/images/pasta.jpg', // Placeholder
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
      imageUrl: 'assets/images/toast.jpg',
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
      imageUrl: 'assets/images/curry.jpg',
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
      imageUrl: 'assets/images/salad.jpg',
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
      imageUrl: 'assets/images/smoothie.jpg',
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
      imageUrl: 'assets/images/stirfry.jpg',
      description: 'Colorful veggies tossed in a tangy sauce.',
      ingredients: ['Broccoli', 'Peppers', 'Soy Sauce', 'Noodles'],
      energyLevel: 2,
      timeMinutes: 18,
      calories: 410,
      equipment: ['Stovetop', 'Pan'],
    ),
  ];

  void _onSwipeEnd(
      int previousIndex, int targetIndex, SwiperActivity activity) {
    if (activity is Swipe) {
      final filteredRecipes =
          _recipes.where((r) => r.energyLevel == _selectedEnergyLevel).toList();
      if (previousIndex < filteredRecipes.length) {
        if (activity.direction == AxisDirection.right) {
          _handleRightSwipe(filteredRecipes[previousIndex]);
        } else {
          // Left swipe - just dismiss
        }
      }
    }
  }

  bool _unlockRecipe(Recipe recipe) {
    final appNotifier = ref.read(appStateProvider.notifier);
    final appState = ref.read(appStateProvider);

    if (appState.isGuest) {
      _showLoginPrompt();
      return false;
    }
    if (!appNotifier.canSwipeRight()) {
      _showOutOfCarrots();
      return false;
    }
    appNotifier.unlockRecipe(recipe);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recipe Unlocked! 🎉 -1 Carrot'),
        backgroundColor: AppTheme.primaryColor,
        duration: Duration(seconds: 1),
      ),
    );
    return true;
  }

  void _handleRightSwipe(Recipe recipe) {
    _promptUnlockFlow(recipe);
  }

  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content:
            const Text('Unlocking recipes requires login. Continue to login?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              GoRouter.of(context).go(AppRoutes.login);
            },
            child: const Text('Login'),
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
    final appState = ref.watch(appStateProvider);
    final appNotifier = ref.read(appStateProvider.notifier);
    final filteredRecipes =
        _recipes.where((r) => r.energyLevel == _selectedEnergyLevel).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Swipe for Supper'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(
                right: AppTheme.spacingL,
                top: AppTheme.spacingS,
                bottom: AppTheme.spacingS),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${appState.carrotCount}/5',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary),
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
          _buildFilterPanel(appState, appNotifier),
          const SizedBox(height: AppTheme.spacingS),
          // Energy Slider (Refactored from RecipesScreen)
          _buildEnergySlider(context),

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
                          const Icon(Icons.search_off_rounded,
                              size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'No recipes for this energy level!',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    )
                  : AppinioSwiper(
                      key: ValueKey(
                          '${_selectedEnergyLevel}_${appState.carrotCount}_${appState.isGuest}'),
                      controller: _swiperController,
                      cardCount: filteredRecipes.length,
                      onSwipeEnd: _onSwipeEnd,
                      swipeOptions: SwipeOptions.only(
                          left: true, right: appNotifier.canSwipeRight()),
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
                          content: Text('Tap View Ingredients on the card.')),
                    );
                  },
                ),
                const SizedBox(width: AppTheme.spacingXL),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: appNotifier.canSwipeRight() ? 1.0 : 0.5,
                  child: _buildActionButton(
                    icon: Icons.favorite_rounded,
                    color: AppTheme.primaryColor,
                    onPressed: () {
                      if (appState.isGuest) {
                        _showLoginPrompt();
                        return;
                      }
                      if (appNotifier.canSwipeRight()) {
                        _swiperController.swipeRight();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Out of Carrots! 🥕')),
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
  }

  Widget _buildEnergySlider(BuildContext context) {
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
                Text('Energy Level',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: AppTheme.textSecondary)),
                Text(_getEnergyLabel(_selectedEnergyLevel),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor)),
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

  Widget _buildFilterPanel(AppState appState, AppStateNotifier appNotifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM, vertical: AppTheme.spacingS),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: AppTheme.borderRadiusLarge,
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          children: [
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
              title: const Text('Filters'),
              trailing: IconButton(
                onPressed: () =>
                    appNotifier.setFilterExpanded(!appState.filterExpanded),
                icon: Icon(
                  Icons.filter_list_rounded,
                  color: appState.filterExpanded
                      ? AppTheme.primaryColor
                      : Colors.grey.shade400,
                ),
                tooltip: appState.filterExpanded
                    ? 'Collapse Filters'
                    : 'Expand Filters',
              ),
            ),
            if (appState.filterExpanded)
              const Padding(
                padding: EdgeInsets.fromLTRB(
                    AppTheme.spacingM, 0, AppTheme.spacingM, AppTheme.spacingM),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _FilterChip(label: 'Breakfast'),
                    _FilterChip(label: 'Lunch'),
                    _FilterChip(label: 'Dinner'),
                    _FilterChip(label: 'Sweet'),
                    _FilterChip(label: 'Savory'),
                    _FilterChip(label: 'Spicy'),
                    _FilterChip(label: 'Under 30 min'),
                    _FilterChip(label: 'High Protein'),
                    _FilterChip(label: 'Low Cal'),
                  ],
                ),
              ),
          ],
        ),
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
                      child: const Icon(Icons.broken_image,
                          size: 80, color: Colors.grey),
                    ),
                  )
                else
                  Image.asset(
                    recipe.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey.shade200,
                      child:
                          const Icon(Icons.image, size: 80, color: Colors.grey),
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
                          Colors.black.withValues(alpha: 0.8)
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
                          '${recipe.ingredients.length} items', Icons.list),
                      const SizedBox(width: 8),
                      _buildTag('${recipe.calories} cal',
                          Icons.local_fire_department),
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
                            borderRadius: BorderRadius.circular(14)),
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
                      icon: const Icon(Icons.menu_book_outlined,
                          size: 18, color: Colors.white),
                      label: const Text('Show Directions',
                          style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.6)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
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
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      {required IconData icon,
      required Color color,
      required VoidCallback onPressed,
      bool isSmall = false}) {
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

  void _promptUnlockFlow(Recipe recipe, {bool fromDirections = false}) {
    final appState = ref.read(appStateProvider);
    final appNotifier = ref.read(appStateProvider.notifier);

    if (appState.isGuest) {
      _showLoginPrompt();
      return;
    }

    // If user chose to skip reminder, show reduced modal
    if (appState.skipUnlockReminder) {
      _showReducedUnlockModal(recipe);
      return;
    }

    // Full reminder with checkbox
    showDialog(
      context: context,
      builder: (context) {
        bool skip = appState.skipUnlockReminder;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Unlock Recipe'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Unlock directions? This will use one carrot.'),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: skip,
                  onChanged: (val) => setState(() => skip = val ?? false),
                  title: const Text('Do not show this reminder again'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ref
                      .read(appStateProvider.notifier)
                      .setSkipUnlockReminder(skip);
                  if (appNotifier.canSwipeRight()) {
                    _unlockRecipe(recipe);
                  } else {
                    _showOutOfCarrots();
                  }
                },
                child: const Text('Unlock'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReducedUnlockModal(Recipe recipe) {
    final appNotifier = ref.read(appStateProvider.notifier);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlock recipe?'),
        content: const Text('Uses one carrot.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (appNotifier.canSwipeRight()) {
                _unlockRecipe(recipe);
              } else {
                _showOutOfCarrots();
              }
            },
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.15),
      labelStyle: const TextStyle(
          color: AppTheme.primaryDark, fontWeight: FontWeight.w600),
    );
  }
}
