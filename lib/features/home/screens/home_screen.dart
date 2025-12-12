import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:super_swipe/core/providers/app_state_provider.dart';
import 'package:super_swipe/core/router/app_router.dart';
import 'package:super_swipe/core/theme/app_theme.dart';
import 'package:super_swipe/features/auth/providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final appState = ref.watch(appStateProvider);

    String displayName;
    if (authState.user?.isAnonymous == true) {
      displayName = 'Guest User';
    } else {
      final fullName =
          authState.displayName ?? authState.user?.displayName ?? 'User';
      displayName = fullName.split(' ').first;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5), // Warm cream background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              // 1. Header
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
                    backgroundColor: AppTheme.primaryColor, // Golden yellow
                    foregroundColor: const Color.fromARGB(255, 255, 255, 255),
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
                      fontWeight: FontWeight.w600),
                ),
              ),

              const SizedBox(height: 40),

              // 3. Active Recipe Card
              if (appState.unlockedRecipes.isNotEmpty) ...[
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
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            // Recipe Image/Icon
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF8E1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFFEBB238), width: 2),
                              ),
                              child: ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl:
                                      appState.unlockedRecipes.first.imageUrl,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 200,
                                  memCacheHeight: 200,
                                  placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator()),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.local_pizza_rounded,
                                          color: Color(0xFF2E5C38), size: 32),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    appState.unlockedRecipes.first.title,
                                    style: GoogleFonts.dmSerifDisplay(
                                      fontSize: 24,
                                      color: const Color(0xFF2D2621),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Step 2 of 4',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFF0F0F0)),
                      InkWell(
                        onTap: () {},
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: const Text(
                            'Continue Recipe',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF8B4513), // Brownish text
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
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
                  width: double.infinity,
                  child: Column(
                    children: [
                      Icon(Icons.menu_book_rounded,
                          size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'No active recipes',
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 20,
                          color: const Color(0xFF2D2621),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start swiping to find your next meal!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 40),

              // 4. Weekly Activity
              Text(
                'Your Weekly Activity',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 24,
                  color: const Color(0xFF2D2621),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: List.generate(5, (index) {
                  final remaining = appState.carrotCount;
                  // Show remaining carrots from left to right
                  // e.g. if 4 remaining: indices 0,1,2,3 are active, 4 is used
                  final isActive = index < remaining;

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
                'Unlimited unlocks with Premium',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
