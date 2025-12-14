import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:super_swipe/core/providers/user_data_providers.dart';
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

                  // 2. Start Swiping Button
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
                        'Start Swiping',
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

                  const SizedBox(height: 40),

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
                  Row(
                    children: List.generate(maxCarrots, (index) {
                      final isActive = index < carrotCount;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: isActive ? 1.0 : 0.2,
                          child: const Text(
                            '🥕',
                            style: TextStyle(fontSize: 26),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$carrotCount of $maxCarrots unlocks remaining this week',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unlimited unlocks with Premium',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),

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
            color: color.withOpacity(0.1),
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
}
