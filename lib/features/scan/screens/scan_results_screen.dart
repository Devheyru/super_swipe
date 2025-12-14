import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:super_swipe/core/providers/firestore_providers.dart';
import 'package:super_swipe/features/auth/providers/auth_provider.dart';
import 'package:super_swipe/core/theme/app_theme.dart';

class DetectedItem {
  String name;
  int quantity;

  DetectedItem({required this.name, this.quantity = 1});
}

class ScanResultsScreen extends ConsumerStatefulWidget {
  final List<String> detectedItems;

  const ScanResultsScreen({super.key, required this.detectedItems});

  @override
  ConsumerState<ScanResultsScreen> createState() => _ScanResultsScreenState();
}

class _ScanResultsScreenState extends ConsumerState<ScanResultsScreen> {
  late List<DetectedItem> _items;

  @override
  void initState() {
    super.initState();
    _items = widget.detectedItems
        .map((name) => DetectedItem(name: name))
        .toList();
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _confirmItems() async {
    final authState = ref.read(authProvider);
    if (authState.user == null) return;

    final pantryService = ref.read(pantryServiceProvider);
    final userService = ref.read(userServiceProvider);

    try {
      // Batch add all scanned items to Firestore
      await pantryService.batchAddPantryItems(
        authState.user!.uid,
        _items
            .map(
              (item) => {
                'name': item.name,
                'quantity': item.quantity,
                'category': _categorizeIngredient(item.name),
                'source': 'scanned',
                'confidence': 0.8, // Default confidence for manual additions
              },
            )
            .toList(),
      );

      // Increment scan count in user profile
      await userService.incrementScanCount(authState.user!.uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${_items.length} items to pantry! 🥕'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate back after successful add
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding items: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Categorize ingredient based on name (simple categorization)
  String _categorizeIngredient(String name) {
    final lowerName = name.toLowerCase();

    // Vegetables
    if (lowerName.contains('tomato') ||
        lowerName.contains('lettuce') ||
        lowerName.contains('spinach') ||
        lowerName.contains('carrot') ||
        lowerName.contains('onion') ||
        lowerName.contains('pepper')) {
      return 'vegetables';
    }

    // Fruits
    if (lowerName.contains('apple') ||
        lowerName.contains('banana') ||
        lowerName.contains('orange') ||
        lowerName.contains('berry')) {
      return 'fruits';
    }

    // Dairy
    if (lowerName.contains('milk') ||
        lowerName.contains('cheese') ||
        lowerName.contains('yogurt') ||
        lowerName.contains('butter')) {
      return 'dairy';
    }

    // Protein
    if (lowerName.contains('chicken') ||
        lowerName.contains('beef') ||
        lowerName.contains('fish') ||
        lowerName.contains('egg') ||
        lowerName.contains('tofu')) {
      return 'protein';
    }

    // Grains
    if (lowerName.contains('rice') ||
        lowerName.contains('bread') ||
        lowerName.contains('pasta') ||
        lowerName.contains('flour')) {
      return 'grains';
    }

    return 'other';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Detected Items'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: _items.isEmpty ? null : _confirmItems,
            icon: const Icon(Icons.check_rounded, color: AppTheme.primaryColor),
            label: const Text(
              'Save',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _items.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    itemCount: _items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppTheme.spacingS),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return _buildItemCard(item, index);
                    },
                  ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_basket_outlined,
            size: 64,
            color: AppTheme.textLight,
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            'No items detected',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: AppTheme.spacingS),
          const Text(
            'Add items manually below',
            style: TextStyle(color: AppTheme.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(DetectedItem item, int index) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: AppTheme.borderRadiusMedium,
        boxShadow: AppTheme.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showEditItemDialog(item, index),
          borderRadius: AppTheme.borderRadiusMedium,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryLight.withValues(alpha: 0.3),
                    borderRadius: AppTheme.borderRadiusSmall,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.restaurant_menu_rounded,
                      color: AppTheme.secondaryDark,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Quantity: ${item.quantity}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: AppTheme.errorColor,
                  onPressed: () => _removeItem(index),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _showAddManualItemDialog,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Manually'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: AppTheme.borderRadiusLarge,
              ),
              elevation: 2,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAddManualItemDialog() async {
    await showDialog(
      context: context,
      builder: (context) => _ItemDialog(
        title: 'Add Item',
        actionLabel: 'Add',
        onConfirm: (name, quantity) {
          setState(() {
            _items.add(DetectedItem(name: name, quantity: quantity));
          });
        },
      ),
    );
  }

  Future<void> _showEditItemDialog(DetectedItem item, int index) async {
    await showDialog(
      context: context,
      builder: (context) => _ItemDialog(
        title: 'Edit Item',
        initialName: item.name,
        initialQuantity: item.quantity,
        actionLabel: 'Save',
        onConfirm: (name, quantity) {
          setState(() {
            item.name = name;
            item.quantity = quantity;
          });
        },
      ),
    );
  }
}

class _ItemDialog extends StatefulWidget {
  final String title;
  final String? initialName;
  final int initialQuantity;
  final String actionLabel;
  final Function(String name, int quantity) onConfirm;

  const _ItemDialog({
    required this.title,
    this.initialName,
    this.initialQuantity = 1,
    required this.actionLabel,
    required this.onConfirm,
  });

  @override
  State<_ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<_ItemDialog> {
  late TextEditingController _nameController;
  late TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _quantityController = TextEditingController(
      text: widget.initialQuantity.toString(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusLarge),
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Item Name',
              hintText: 'e.g., Apples',
              border: OutlineInputBorder(
                borderRadius: AppTheme.borderRadiusMedium,
              ),
              filled: true,
              fillColor: AppTheme.backgroundColor,
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: AppTheme.spacingM),
          TextField(
            controller: _quantityController,
            decoration: InputDecoration(
              labelText: 'Quantity',
              border: OutlineInputBorder(
                borderRadius: AppTheme.borderRadiusMedium,
              ),
              filled: true,
              fillColor: AppTheme.backgroundColor,
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.trim().isNotEmpty) {
              widget.onConfirm(
                _nameController.text.trim(),
                int.tryParse(_quantityController.text) ?? 1,
              );
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: AppTheme.borderRadiusMedium,
            ),
          ),
          child: Text(widget.actionLabel),
        ),
      ],
    );
  }
}
