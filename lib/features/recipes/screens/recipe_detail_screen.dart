import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:super_swipe/core/models/recipe.dart';
import 'package:super_swipe/core/providers/recipe_providers.dart';
import 'package:super_swipe/core/providers/user_data_providers.dart';
import 'package:super_swipe/core/router/app_router.dart';
import 'package:super_swipe/core/theme/app_theme.dart';
import 'package:super_swipe/features/auth/providers/auth_provider.dart';

class RecipeDetailScreen extends ConsumerStatefulWidget {
  final String recipeId;
  final Recipe? initialRecipe;

  const RecipeDetailScreen({
    super.key,
    required this.recipeId,
    this.initialRecipe,
  });

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  bool _isUpdatingProgress = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    if (user == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(title: const Text('Recipe')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline_rounded, size: 56),
                const SizedBox(height: AppTheme.spacingM),
                const Text(
                  'Sign in required',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppTheme.spacingS),
                const Text(
                  'Please sign in to view unlocked recipes and track progress.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingL),
                ElevatedButton(
                  onPressed: () => context.go(AppRoutes.login),
                  child: const Text('Sign In'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final savedRecipeAsync = ref.watch(savedRecipeProvider(widget.recipeId));
    final userProfileAsync = ref.watch(userProfileProvider);

    // Check if user is premium (can view without unlock)
    final userProfile = userProfileAsync.value;
    final subscription = userProfile?.subscriptionStatus.toLowerCase() ?? 'free';
    final isPremium = subscription == 'premium' || subscription == 'pro';

    return savedRecipeAsync.when(
      // CRITICAL FIX: Loading state shows spinner only, not recipe content
      loading: () => Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Text(widget.initialRecipe?.title ?? 'Recipe'),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
      ),
      error: (error, stack) => _buildError(context, error),
      data: (savedRecipe) {
        // CRITICAL FIX: Free users MUST have recipe in savedRecipes (unlocked via carrot)
        // Premium users can use initialRecipe as fallback
        final recipe = isPremium
            ? (savedRecipe ?? widget.initialRecipe)
            : savedRecipe;

        if (recipe == null) {
          return Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            appBar: AppBar(title: const Text('Recipe')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 56,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    const Text(
                      'Recipe Not Unlocked',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    const Text(
                      'Swipe right on this recipe to unlock it using a carrot.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacingL),
                    ElevatedButton.icon(
                      onPressed: () => context.go(AppRoutes.swipe),
                      icon: const Icon(Icons.swipe_rounded),
                      label: const Text('Swipe for Supper'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return _buildScaffoldForRecipe(context, recipe);
      },
    );
  }

  Scaffold _buildError(BuildContext context, Object error) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Recipe')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: AppTheme.errorColor,
              ),
              const SizedBox(height: AppTheme.spacingM),
              const Text(
                'Couldn’t load recipe',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: AppTheme.spacingL),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.recipes),
                child: const Text('Back to Recipes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Scaffold _buildScaffoldForRecipe(
    BuildContext context,
    Recipe? recipe, {
    bool isLoading = false,
  }) {
    final safeRecipe = recipe;
    final instructions = safeRecipe?.instructions ?? const <String>[];
    final currentStep = safeRecipe?.currentStep ?? 0;
    final totalSteps = instructions.length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(safeRecipe?.title ?? 'Recipe'),
        centerTitle: true,
      ),
      body: safeRecipe == null
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: AppTheme.borderRadiusLarge,
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: safeRecipe.imageUrl.startsWith('http')
                          ? Image.network(
                              safeRecipe.imageUrl,
                              fit: BoxFit.cover,
                            )
                          : Image.asset(safeRecipe.imageUrl, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingL),

                  // Progress
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: AppTheme.borderRadiusLarge,
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.playlist_add_check_rounded,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: AppTheme.spacingS),
                        Expanded(
                          child: Text(
                            totalSteps == 0
                                ? 'Directions coming soon'
                                : 'Step $currentStep of $totalSteps',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (isLoading) const SizedBox(width: 16),
                        if (isLoading)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingL),

                  // Ingredients
                  Text(
                    'Ingredients',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  ...safeRecipe.ingredients.map(
                    (ing) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '•  ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Expanded(child: Text(ing)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingL),

                  // Directions
                  Text(
                    'Directions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  if (instructions.isEmpty)
                    const Text(
                      'Directions are not available for this recipe yet.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    )
                  else
                    Column(
                      children: List.generate(instructions.length, (index) {
                        final stepNumber = index + 1;
                        final isCompleted = stepNumber <= currentStep;
                        final isNext = stepNumber == currentStep + 1;

                        return Container(
                          margin: const EdgeInsets.only(
                            bottom: AppTheme.spacingS,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: AppTheme.borderRadiusMedium,
                            boxShadow: AppTheme.softShadow,
                            border: Border.all(
                              color: isNext
                                  ? AppTheme.primaryColor.withValues(alpha: 0.6)
                                  : Colors.transparent,
                            ),
                          ),
                          child: ListTile(
                            leading: Icon(
                              isCompleted
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color: isCompleted
                                  ? AppTheme.successColor
                                  : (isNext
                                        ? AppTheme.primaryColor
                                        : AppTheme.textLight),
                            ),
                            title: Text(
                              'Step $stepNumber',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(instructions[index]),
                            onTap: (!isNext || _isUpdatingProgress)
                                ? null
                                : () => _markStepComplete(stepNumber),
                            trailing: isNext && !_isUpdatingProgress
                                ? const Icon(Icons.chevron_right_rounded)
                                : (_isUpdatingProgress && isNext)
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : null,
                          ),
                        );
                      }),
                    ),
                ],
              ),
            ),
    );
  }

  Future<void> _markStepComplete(int stepNumber) async {
    final userId = ref.read(authProvider).user?.uid;
    if (userId == null) return;

    setState(() => _isUpdatingProgress = true);
    try {
      await ref
          .read(recipeServiceProvider)
          .updateSavedRecipeProgress(
            userId: userId,
            recipeId: widget.recipeId,
            currentStep: stepNumber,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update progress: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingProgress = false);
    }
  }
}
