import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:super_swipe/core/models/recipe.dart';
import 'package:super_swipe/core/theme/app_theme.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ready to Cook?',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Discover Recipes',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.tune_rounded),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Energy Level Slider
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How much energy do you have?',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),

                    // Custom Slider
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 8,
                              activeTrackColor: AppTheme.primaryColor,
                              inactiveTrackColor: Colors.grey.shade200,
                              thumbColor: AppTheme.primaryColor,
                              overlayColor:
                                  AppTheme.primaryColor.withValues(alpha: 0.1),
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 12, elevation: 4),
                              overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 24),
                              tickMarkShape: const RoundSliderTickMarkShape(
                                  tickMarkRadius: 0),
                            ),
                            child: Slider(
                              value: _selectedEnergyLevel.toDouble(),
                              min: 0,
                              max: 3,
                              divisions: 3,
                              onChanged: (value) {
                                setState(
                                    () => _selectedEnergyLevel = value.round());
                              },
                            ),
                          ),

                          // Labels
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildSliderLabel('Sleepy', '💤', 0),
                                _buildSliderLabel('Low', '🔋', 1),
                                _buildSliderLabel('Okay', '⚡', 2),
                                _buildSliderLabel('High', '🔥', 3),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(
                child: SizedBox(height: AppTheme.spacingL)),

            // 3. Cravings
            SliverToBoxAdapter(
              child: SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildCravingItem('Sweet', '🍩', Colors.pink.shade50),
                    _buildCravingItem('Salty', '🥨', Colors.orange.shade50),
                    _buildCravingItem('Fresh', '🥗', Colors.green.shade50),
                    _buildCravingItem('Comfort', '🍜', Colors.brown.shade50),
                    _buildCravingItem('Spicy', '🌶️', Colors.red.shade50),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(
                child: SizedBox(height: AppTheme.spacingL)),

            // 4. Section Title
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
                child: Text(
                  'Based on your pantry',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SliverToBoxAdapter(
                child: SizedBox(height: AppTheme.spacingM)),

            // 5. Recipe List
            SliverPadding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildRecipeCard(context, index),
                  childCount: _recipes.length,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderLabel(String label, String emoji, int index) {
    final isSelected = _selectedEnergyLevel == index;
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCravingItem(String label, String emoji, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 28))),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(BuildContext context, int index) {
    final recipe = _recipes[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Placeholder
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  child: recipe.imageUrl.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: recipe.imageUrl,
                          fit: BoxFit.cover,
                          memCacheHeight: 400,
                          placeholder: (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => const Icon(
                              Icons.broken_image,
                              size: 48,
                              color: Colors.grey),
                        )
                      : Image.asset(
                          recipe.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                            child: Icon(Icons.image_not_supported_rounded,
                                size: 48, color: Colors.grey),
                          ),
                        ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8),
                      ],
                    ),
                    child: const Icon(Icons.favorite_border_rounded,
                        size: 20, color: AppTheme.errorColor),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getEnergyLabel(recipe.energyLevel),
                        style: const TextStyle(
                            color: AppTheme.secondaryDark,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.star_rounded,
                        size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    const Text('4.8',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  recipe.title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text('${recipe.timeMinutes} min',
                        style: TextStyle(color: Colors.grey.shade500)),
                    const SizedBox(width: 16),
                    Icon(Icons.local_fire_department_rounded,
                        size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text('${recipe.calories} kcal',
                        style: TextStyle(color: Colors.grey.shade500)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getEnergyLabel(int level) {
    switch (level) {
      case 0:
        return 'Sleepy';
      case 1:
        return 'Low';
      case 2:
        return 'Okay';
      case 3:
        return 'High';
      default:
        return 'Okay';
    }
  }
}
