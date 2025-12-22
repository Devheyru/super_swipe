import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:super_swipe/core/providers/user_data_providers.dart';
import 'package:super_swipe/core/providers/recipe_providers.dart';
import 'package:super_swipe/core/router/app_router.dart';
import 'package:super_swipe/core/theme/app_theme.dart';
import 'package:super_swipe/features/auth/providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userProfileAsync = ref.watch(userProfileProvider);
    final pantryCount = ref.watch(pantryCountProvider);
    final savedRecipesAsync = ref.watch(savedRecipesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5), // Warm cream background
      body: SafeArea(
        child: userProfileAsync.when(
          loading: () => _buildLoadingState(),
          error: (error, stack) => _buildErrorState(context, error, ref),
          data: (userProfile) {
            if (userProfile == null) {
              return _buildErrorState(
                context,
                'Profile not found. Please sign in.',
                ref,
              );
            }

            // Get display name
            String displayName;
            if (authState.user?.isAnonymous == true) {
              displayName = 'Guest User';
            } else {
              displayName = userProfile.displayName.split(' ').first;
            }

            // Get real-time data from Firestore
            final carrotCount = userProfile.carrots.current;
            final maxCarrots = userProfile.carrots.max;
            final scanCount = userProfile.stats.scanCount;
            final recipesUnlocked = userProfile.stats.recipesUnlocked;
            final totalCarrotsSpent = userProfile.stats.totalCarrotsSpent;
            final subscription = userProfile.subscriptionStatus.toLowerCase();
            final isPremium =
                subscription == 'premium' || subscription == 'pro';

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),

                  // 1. Header with personalized greeting
                  Center(
                    child: Text(
                      'Welcome back,\n$displayName',
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 40,
                        height: 1.1,
                        color: const Color(0xFF2D2621),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ready to find your next meal?',
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 2. Swipe for Supper Button
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton(
                      onPressed: () => context.push(AppRoutes.swipe),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Swipe for Supper',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'Unlimited swipes, Unlock instructions\nwhen you\'re ready to cook.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6B6B6B),
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 2.5 Continue Recipe Section (if available)
                  savedRecipesAsync.when(
                    data: (recipes) {
                      if (recipes.isEmpty) return const SizedBox.shrink();

                      // Treat a recipe as “in progress” if it has steps and user has started.
                      final inProgress = recipes.firstWhere(
                        (r) =>
                            r.instructions.isNotEmpty &&
                            r.currentStep > 0 &&
                            r.currentStep < r.instructions.length,
                        orElse: () => recipes.first,
                      );

                      final isActuallyInProgress =
                          inProgress.instructions.isNotEmpty &&
                          inProgress.currentStep > 0 &&
                          inProgress.currentStep <
                              inProgress.instructions.length;

                      if (!isActuallyInProgress) return const SizedBox.shrink();

                      return Column(
                        children: [
                          _buildContinueRecipeCard(context, inProgress),
                          const SizedBox(height: 32),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  // 3. Pantry Summary Card (Real-time data)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.kitchen_rounded,
                              size: 32,
                              color: Colors.orange[700],
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your Pantry',
                                  style: GoogleFonts.dmSerifDisplay(
                                    fontSize: 20,
                                    color: const Color(0xFF2D2621),
                                  ),
                                ),
                                Text(
                                  '$pantryCount ingredient${pantryCount == 1 ? '' : 's'}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => context.go(AppRoutes.pantry),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[50],
                              foregroundColor: Colors.orange[700],
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Manage Pantry'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 4. Weekly Activity (Real-time carrots)
                  Text(
                    'Your Weekly Activity',
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 24,
                      color: const Color(0xFF2D2621),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!isPremium) ...[
                    // Free users: 5 carrots/week + upsell placeholder
                    _buildCarrotDisplay(carrotCount, maxCarrots),
                    const SizedBox(height: 12),
                    Text(
                      '$carrotCount of $maxCarrots unlocks remaining this week ',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.orange),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Upgrade to Premium for unlimited unlocks (no carrot limit).',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Premium upgrade coming soon.'),
                                ),
                              );
                            },
                            child: const Text('Learn More'),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Premium users: unlimited unlocks (no carrot UX)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text('⭐', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Premium: Unlimited unlocks • $recipesUnlocked unlocked',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),

                  // 5. Statistics Card (Real-time from Firestore)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Stats',
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 20,
                            color: const Color(0xFF2D2621),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              icon: Icons.camera_alt_rounded,
                              label: 'Scans',
                              value: '$scanCount',
                              color: Colors.blue,
                            ),
                            _buildStatItem(
                              icon: Icons.restaurant_rounded,
                              label: 'Recipes',
                              value: '$recipesUnlocked',
                              color: Colors.orange,
                            ),
                            _buildStatItem(
                              icon: Icons.eco_rounded,
                              label: 'Spent',
                              value: '$totalCarrotsSpent',
                              color: Colors.green,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D2621),
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  /// Fix #10: Build carrot display with cap for premium users
  Widget _buildCarrotDisplay(int current, int max) {
    // Cap at 20 to prevent overflow on premium
    if (max > 20) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange.withValues(alpha: 0.1),
              Colors.orange.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🥕', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Text(
              '$current / $max',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      );
    }

    // Normal display for <= 20 carrots
    final displayMax = max.clamp(0, 20);
    return Row(
      children: List.generate(displayMax, (index) {
        final isActive = index < current;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: isActive ? 1.0 : 0.25,
            child: const Text('🥕', style: TextStyle(fontSize: 26)),
          ),
        );
      }),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Couldn\'t Load Profile',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 24,
                color: const Color(0xFF2D2621),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please sign in again to continue.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                // Sign out first to clear state
                await ref.read(authProvider.notifier).signOut();
                if (context.mounted) {
                  context.go(AppRoutes.login);
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Sign In Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueRecipeCard(BuildContext context, recipe) {
    // `recipe` comes from Firestore saved recipes stream.
    // It should be a `Recipe`, but keep this defensive for legacy data.
    final int currentStep = (recipe.currentStep as int?) ?? 0;
    final int totalSteps = (recipe.instructions as List?)?.length ?? 0;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: recipe.imageUrl.startsWith('http')
                  ? CachedNetworkImage(
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
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : Image.asset(
                      recipe.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.broken_image,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.restaurant_rounded,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Continue Recipe',
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 18,
                        color: const Color(0xFF2D2621),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  recipe.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2621),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${recipe.timeMinutes} min',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.format_list_numbered_rounded,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Step $currentStep/$totalSteps',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.local_fire_department_rounded,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${recipe.calories} kcal',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push(
                      '${AppRoutes.recipes}/${recipe.id}',
                      extra: recipe,
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Continue Recipe'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
