import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:super_swipe/core/providers/app_state_provider.dart';
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
    final appState = ref.watch(appStateProvider);
    final appNotifier = ref.read(appStateProvider.notifier);
    final filtered = appState.pantryItems
        .where((item) =>
            item.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

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
                padding: const EdgeInsets.fromLTRB(AppTheme.spacingL,
                    AppTheme.spacingXL, AppTheme.spacingL, AppTheme.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'My Pantry',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
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
                                hintStyle:
                                    TextStyle(color: Colors.grey.shade400),
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
                            icon: const Icon(Icons.search_rounded,
                                color: AppTheme.textPrimary),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
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
                        child: const Icon(Icons.delete_forever,
                            color: AppTheme.errorColor),
                      ),
                      onDismissed: (_) => appNotifier.deletePantryItem(item.id),
                      child: InkWell(
                        onTap: () {
                          if (_requireAuth()) return;
                          _showAddEditDialog(
                              itemId: item.id,
                              initialName: item.name,
                              initialQuantity: item.quantity);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
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
                                          fontWeight: FontWeight.w500),
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
                                            fontWeight: FontWeight.w600),
                                      ),
                                      SizedBox(width: 6),
                                      Icon(Icons.chevron_right,
                                          color: AppTheme.textLight),
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
                                        color: AppTheme.textSecondary
                                            .withValues(alpha: 0.4),
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
                  },
                  childCount: filtered.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddEditDialog(
      {String? itemId,
      String initialName = '',
      int initialQuantity = 1}) async {
    final appNotifier = ref.read(appStateProvider.notifier);
    final nameController = TextEditingController(text: initialName);
    final qtyController =
        TextEditingController(text: initialQuantity.toString());

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
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final qty = int.tryParse(qtyController.text.trim()) ?? 1;
              if (name.isEmpty) return;
              if (_requireAuth()) return;
              if (itemId == null) {
                appNotifier.addPantryItem(name, qty);
              } else {
                appNotifier.editPantryItem(itemId, name, qty);
              }
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  bool _requireAuth() {
    final appState = ref.read(appStateProvider);
    if (appState.isGuest) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Login Required'),
          content: const Text('Saving pantry changes requires login.'),
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
      child: Center(
        child: Icon(icon, color: color),
      ),
    );
  }
}
