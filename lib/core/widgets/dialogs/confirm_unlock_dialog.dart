import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:super_swipe/core/models/recipe_preview.dart';
import 'package:super_swipe/core/theme/app_theme.dart';

/// Reusable dialog for confirming recipe unlock with carrot spend.
/// Shows recipe preview, carrot balance, and unlock/cancel actions.
class ConfirmUnlockDialog extends StatelessWidget {
  final RecipePreview preview;
  final int currentCarrots;
  final int maxCarrots;
  final VoidCallback onCancel;
  final VoidCallback onUnlock;
  final bool isLoading;

  const ConfirmUnlockDialog({
    super.key,
    required this.preview,
    required this.currentCarrots,
    required this.maxCarrots,
    required this.onCancel,
    required this.onUnlock,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasCarrots = currentCarrots > 0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  const Text('🥕', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 8),
                  Text(
                    'Unlock Recipe',
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recipe title
                  Text(
                    preview.title,
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 20,
                      color: const Color(0xFF2D2621),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Vibe description
                  Text(
                    preview.vibeDescription,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Main ingredients preview
                  if (preview.mainIngredients.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: preview.mainIngredients.take(4).map((ing) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            ing,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Unlock prompt
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: hasCarrots ? Colors.orange[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasCarrots
                            ? Colors.orange[200]!
                            : Colors.red[200]!,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          hasCarrots
                              ? 'This looks delicious!'
                              : 'Out of Carrots! 🥕',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: hasCarrots
                                ? Colors.orange[800]
                                : Colors.red[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasCarrots
                              ? 'Use 1 carrot to unlock the full recipe?'
                              : 'Wait for your weekly carrot refresh or upgrade to Premium.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: hasCarrots
                                ? Colors.orange[700]
                                : Colors.red[700],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Carrot balance indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🥕', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 6),
                            Text(
                              '$currentCarrots / $maxCarrots',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: hasCarrots
                                    ? Colors.orange[800]
                                    : Colors.red[800],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isLoading ? null : onCancel,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: hasCarrots && !isLoading ? onUnlock : null,
                      icon: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.lock_open_rounded, size: 20),
                      label: Text(
                        isLoading ? 'Unlocking...' : 'Unlock (-1 🥕)',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasCarrots
                            ? AppTheme.primaryColor
                            : Colors.grey.shade400,
                        foregroundColor: Colors.white,
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
      ),
    );
  }
}
