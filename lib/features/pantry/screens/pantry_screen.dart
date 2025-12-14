import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:super_swipe/core/providers/user_data_providers.dart';
import 'package:super_swipe/core/providers/firestore_providers.dart';
import 'package:super_swipe/features/auth/providers/auth_provider.dart';
import 'package:super_swipe/core/router/app_router.dart';
import 'package:super_swipe/core/theme/app_theme.dart';

class PantryScreen extends ConsumerStatefulWidget {
  const PantryScreen({super.key});

  @override
  ConsumerState<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends ConsumerState<PantryScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final pantryItemsAsync = ref.watch(pantryItemsProvider);

    return pantryItemsAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading your pantry...',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
      error: (error, stack) => _buildErrorScreen(context, error, stack),
      data: (allItems) {
        final filtered = allItems
            .where(
              (item) =>
                  item.name.toLowerCase().contains(_searchQuery.toLowerCase()),
            )
            .toList();

        return _buildScreen(context, authState, filtered);
      },
    );
  }

  Widget _buildScreen(BuildContext context, authState, filtered) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_requireAuth()) return;
          _showAddEditDialog();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Ingredients'),
        elevation: 4,
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingL,
                  AppTheme.spacingXL,
                  AppTheme.spacingL,
                  AppTheme.spacingM,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'My Pantry',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 32,
                            ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingL),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceColor,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextField(
                              onChanged: (value) =>
                                  setState(() => _searchQuery = value),
                              decoration: InputDecoration(
                                hintText: 'Search ingredients...',
                                filled: false,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.only(
                                  left: 26,
                                  right: 20,
                                ),
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.search_rounded,
                              color: AppTheme.textPrimary,
                            ),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingL,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final item = filtered[index];
                  return Dismissible(
                    key: Key(item.id),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) async {
                      if (_requireAuth()) return false;
                      return true;
                    },
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      color: AppTheme.errorColor.withValues(alpha: 0.1),
                      child: const Icon(
                        Icons.delete_forever,
                        color: AppTheme.errorColor,
                      ),
                    ),
                    onDismissed: (_) async {
                      final authState = ref.read(authProvider);
                      if (authState.user == null) return;
                      final pantryService = ref.read(pantryServiceProvider);
                      await pantryService.deletePantryItem(
                        authState.user!.uid,
                        item.id,
                      );
                    },
                    child: InkWell(
                      onTap: () {
                        if (_requireAuth()) return;
                        _showAddEditDialog(
                          itemId: item.id,
                          initialName: item.name,
                          initialQuantity: item.quantity,
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            _buildIconForItem(item.name),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.quantity}',
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Row(
                                  children: [
                                    Text(
                                      'Edit',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Icon(
                                      Icons.chevron_right,
                                      color: AppTheme.textLight,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      'Swipe to delete',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.textSecondary
                                            .withValues(alpha: 0.4),
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Icon(
                                      Icons.swipe_left_sharp,
                                      size: 12,
                                      color: AppTheme.textSecondary.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }, childCount: filtered.length),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddEditDialog({
    String? itemId,
    String initialName = '',
    int initialQuantity = 1,
  }) async {
    final nameController = TextEditingController(text: initialName);
    final qtyController = TextEditingController(
      text: initialQuantity.toString(),
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(itemId == null ? 'Add Ingredient' : 'Edit Ingredient'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: AppTheme.spacingXL),
            TextField(
              controller: qtyController,
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final qty = int.tryParse(qtyController.text.trim()) ?? 1;
              if (name.isEmpty) return;
              if (_requireAuth()) return;

              final authState = ref.read(authProvider);
              if (authState.user == null) return;

              final pantryService = ref.read(pantryServiceProvider);

              try {
                if (itemId == null) {
                  // Add new item
                  await pantryService.addPantryItem(
                    authState.user!.uid,
                    name,
                    quantity: qty,
                    category: 'other',
                    source: 'manual',
                  );
                } else {
                  // Edit existing item
                  await pantryService.updatePantryItem(
                    authState.user!.uid,
                    itemId,
                    name: name,
                    quantity: qty,
                  );
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  bool _requireAuth() {
    final authState = ref.read(authProvider);
    if (authState.user == null || authState.user!.isAnonymous) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Login Required'),
          content: const Text('Saving pantry changes requires login.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
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
      return true;
    }
    return false;
  }

  Widget _buildIconForItem(String name) {
    IconData icon = Icons.local_grocery_store;
    Color color = Colors.orange;
    final lower = name.toLowerCase();
    if (lower.contains('egg')) {
      icon = Icons.egg_outlined;
      color = Colors.brown;
    } else if (lower.contains('carrot')) {
      icon = Icons.emoji_food_beverage;
      color = Colors.deepOrange;
    } else if (lower.contains('bread')) {
      icon = Icons.bakery_dining;
      color = Colors.brown.shade400;
    } else if (lower.contains('chicken')) {
      icon = Icons.set_meal;
      color = Colors.deepOrangeAccent;
    } else if (lower.contains('spinach') || lower.contains('leaf')) {
      icon = Icons.eco_outlined;
      color = Colors.green;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(child: Icon(icon, color: color)),
    );
  }

  /// Expert-level error handling with user-friendly messages
  Widget _buildErrorScreen(
    BuildContext context,
    Object error,
    StackTrace stack,
  ) {
    // Parse error to determine specific issue
    final errorString = error.toString().toLowerCase();

    String title;
    String message;
    IconData icon;
    Color iconColor;
    String actionText;
    VoidCallback? onAction;

    if (errorString.contains('failed-precondition') ||
        errorString.contains('index')) {
      // Missing Firestore Index Error
      title = 'Database Setup Required';
      message =
          'Your pantry needs a database index to organize items by category.\n\n'
          'This is a one-time setup that takes 2-3 minutes to complete.';
      icon = Icons.construction_rounded;
      iconColor = Colors.orange;
      actionText = 'Create Index in Firebase';

      // Extract the index creation URL from error
      final urlMatch = RegExp(r'https://[^\s]+').firstMatch(errorString);
      if (urlMatch != null) {
        final url = urlMatch.group(0)!;
        onAction = () async {
          // Try to open URL
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening Firebase Console...'),
              action: SnackBarAction(
                label: 'Copy URL',
                onPressed: () {
                  // In a real app, you'd copy to clipboard
                  debugPrint('Index URL: $url');
                },
              ),
            ),
          );
          debugPrint('Create index at: $url');
        };
      }
    } else if (errorString.contains('permission') ||
        errorString.contains('denied')) {
      // Permission Error
      title = 'Access Denied';
      message =
          'You don\'t have permission to access the pantry.\n\n'
          'This usually means:\n'
          '• Security rules aren\'t deployed yet\n'
          '• You need to sign in again\n'
          '• Your account needs verification';
      icon = Icons.lock_rounded;
      iconColor = Colors.red;
      actionText = 'Sign In Again';
      onAction = () {
        context.go(AppRoutes.login);
      };
    } else if (errorString.contains('network') ||
        errorString.contains('unavailable')) {
      // Network Error
      title = 'Connection Issue';
      message =
          'Can\'t connect to the database.\n\n'
          'Please check your internet connection and try again.';
      icon = Icons.wifi_off_rounded;
      iconColor = Colors.grey;
      actionText = 'Retry';
      onAction = () {
        setState(() {
          // Trigger rebuild which will retry provider
        });
      };
    } else {
      // Unknown Error
      title = 'Something Went Wrong';
      message =
          'We encountered an unexpected error while loading your pantry.\n\n'
          'Error details: ${error.toString().substring(0, error.toString().length > 100 ? 100 : error.toString().length)}...';
      icon = Icons.error_outline_rounded;
      iconColor = Colors.deepOrange;
      actionText = 'Go Back';
      onAction = () {
        context.go(AppRoutes.home);
      };
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Pantry'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Error Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 50, color: iconColor),
                ),
                const SizedBox(height: 32),

                // Error Title
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Error Message
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Action Buttons
                Column(
                  children: [
                    if (onAction != null)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: onAction,
                          icon: Icon(
                            errorString.contains('index')
                                ? Icons.open_in_new
                                : Icons.refresh,
                          ),
                          label: Text(actionText),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () {
                        context.go(AppRoutes.home);
                      },
                      icon: const Icon(Icons.home),
                      label: const Text('Go to Home'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),

                // Technical Details (Expandable)
                const SizedBox(height: 32),
                ExpansionTile(
                  title: const Text(
                    'Technical Details',
                    style: TextStyle(fontSize: 14, color: AppTheme.textLight),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SelectableText(
                        error.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
