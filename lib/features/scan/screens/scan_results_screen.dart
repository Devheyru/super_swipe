import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:super_swipe/core/providers/firestore_providers.dart';
import 'package:super_swipe/core/router/app_router.dart';
import 'package:super_swipe/features/auth/providers/auth_provider.dart';
import 'package:super_swipe/core/theme/app_theme.dart';
import 'package:super_swipe/core/services/vision_quota_service.dart';
import 'package:super_swipe/core/services/hybrid_vision_service.dart';

class DetectedItem {
  String name;
  int quantity;

  DetectedItem({required this.name, this.quantity = 1});
}

class ScanResultsScreen extends ConsumerStatefulWidget {
  final List<String> detectedItems;
  final VisionSource? visionSource;
  final QuotaStatus? quotaStatus;

  const ScanResultsScreen({
    super.key,
    required this.detectedItems,
    this.visionSource,
    this.quotaStatus,
  });

  @override
  ConsumerState<ScanResultsScreen> createState() => _ScanResultsScreenState();
}

class _ScanResultsScreenState extends ConsumerState<ScanResultsScreen> {
  late List<DetectedItem> _items;

  // Track which suggestions have been used for each generic item
  final Map<int, Set<String>> _usedSuggestions = {};

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
      // Clean up tracking for this index
      _usedSuggestions.remove(index);
      // Shift down tracking for items after this one
      final newMap = <int, Set<String>>{};
      _usedSuggestions.forEach((key, value) {
        if (key > index) {
          newMap[key - 1] = value;
        } else if (key < index) {
          newMap[key] = value;
        }
      });
      _usedSuggestions.clear();
      _usedSuggestions.addAll(newMap);
    });
  }

  /// Check if item name is generic and needs suggestions
  bool _isGenericLabel(String name) {
    final generic = [
      'mixed vegetables',
      'vegetable',
      'vegetables',
      'food',
      'food item',
      'fresh fruit',
      'fruit',
      'fruits',
      'leafy greens',
      'produce',
    ];
    return generic.contains(name.toLowerCase());
  }

  /// Get smart suggestions based on generic label
  List<Map<String, String>> _getSuggestionsFor(String genericLabel) {
    final label = genericLabel.toLowerCase();

    // Vegetables suggestions
    if (label.contains('vegetable') || label.contains('produce')) {
      return [
        {'emoji': '🥕', 'name': 'Carrots'},
        {'emoji': '🍅', 'name': 'Tomatoes'},
        {'emoji': '🥬', 'name': 'Cabbage'},
        {'emoji': '🥒', 'name': 'Cucumber'},
        {'emoji': '🧅', 'name': 'Onions'},
        {'emoji': '🫑', 'name': 'Bell Peppers'},
        {'emoji': '🥦', 'name': 'Broccoli'},
        {'emoji': '🥔', 'name': 'Potatoes'},
      ];
    }

    // Fruits suggestions
    if (label.contains('fruit')) {
      return [
        {'emoji': '🍎', 'name': 'Apples'},
        {'emoji': '🍊', 'name': 'Oranges'},
        {'emoji': '🍌', 'name': 'Bananas'},
        {'emoji': '🍇', 'name': 'Grapes'},
        {'emoji': '🍓', 'name': 'Strawberries'},
        {'emoji': '🫐', 'name': 'Blueberries'},
        {'emoji': '🍋', 'name': 'Lemons'},
        {'emoji': '🥑', 'name': 'Avocados'},
      ];
    }

    // Leafy greens suggestions
    if (label.contains('leaf') || label.contains('green')) {
      return [
        {'emoji': '🥬', 'name': 'Cabbage'},
        {'emoji': '🥗', 'name': 'Lettuce'},
        {'emoji': '🌿', 'name': 'Spinach'},
        {'emoji': '🥬', 'name': 'Kale'},
        {'emoji': '🌿', 'name': 'Beet Greens'},
      ];
    }

    // Generic food suggestions - most common ingredients
    return [
      {'emoji': '🥕', 'name': 'Carrots'},
      {'emoji': '🍅', 'name': 'Tomatoes'},
      {'emoji': '🥬', 'name': 'Cabbage'},
      {'emoji': '🧅', 'name': 'Onions'},
      {'emoji': '🥔', 'name': 'Potatoes'},
      {'emoji': '🍎', 'name': 'Apples'},
    ];
  }

  /// Add specific item from suggestion (allows multiple selections)
  void _addFromSuggestion(int genericIndex, String itemName) {
    setState(() {
      // Add the new specific item
      _items.insert(
        genericIndex + 1,
        DetectedItem(name: itemName, quantity: 1),
      );

      // Track this suggestion as used for this generic item
      _usedSuggestions.putIfAbsent(genericIndex, () => {}).add(itemName);
    });

    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $itemName'),
        duration: const Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  /// Remove the generic placeholder after adding specific items
  void _removeGenericPlaceholder(int index) {
    setState(() {
      _items.removeAt(index);
      // Clean up tracking for this index
      _usedSuggestions.remove(index);
      // Shift down tracking for items after this one
      final newMap = <int, Set<String>>{};
      _usedSuggestions.forEach((key, value) {
        if (key > index) {
          newMap[key - 1] = value;
        } else if (key < index) {
          newMap[key] = value;
        }
      });
      _usedSuggestions.clear();
      _usedSuggestions.addAll(newMap);
    });
  }

  Future<void> _confirmItems() async {
    final authState = ref.read(authProvider);
    final user = authState.user;

    // Block guests from saving scan results - per requirements spec
    if (user == null || user.isAnonymous) {
      _showGuestRestrictedDialog();
      return;
    }

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

  void _showGuestRestrictedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Guest Mode Restriction'),
        content: const Text(
          'Guest users cannot save scanned items to pantry.\n\n'
          'Create a free account to:\n'
          '• Save scanned ingredients\n'
          '• Build your pantry inventory\n'
          '• Get personalized recipe suggestions\n\n'
          'Sign up now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go(AppRoutes.signup);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Sign Up'),
          ),
        ],
      ),
    );
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
          // Quota status banner (if available)
          if (widget.quotaStatus != null) _buildQuotaStatusBanner(),
          
          // Vision source indicator (if available)
          if (widget.visionSource != null) _buildVisionSourceBadge(),
          
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
  
  Widget _buildQuotaStatusBanner() {
    final status = widget.quotaStatus!;
    
    // Only show banner if approaching limits or exhausted
    if (status.level == QuotaLevel.normal) return const SizedBox.shrink();
    
    Color bgColor;
    Color textColor;
    IconData icon;
    
    switch (status.level) {
      case QuotaLevel.warning:
        bgColor = Colors.amber.shade50;
        textColor = Colors.amber.shade900;
        icon = Icons.info_outline;
        break;
      case QuotaLevel.critical:
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade900;
        icon = Icons.warning_amber_rounded;
        break;
      case QuotaLevel.exhausted:
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade900;
        icon = Icons.error_outline;
        break;
      default:
        return const SizedBox.shrink();
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      color: bgColor,
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(
            child: Text(
              status.statusMessage,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildVisionSourceBadge() {
    final source = widget.visionSource!;
    
    String label;
    Color bgColor;
    Color textColor;
    IconData icon;
    
    switch (source) {
      case VisionSource.mlKit:
        label = 'Standard AI Detection';
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade900;
        icon = Icons.smartphone;
        break;
      case VisionSource.cloudVision:
        label = 'Enhanced AI Detection ☁️';
        bgColor = Colors.purple.shade50;
        textColor = Colors.purple.shade900;
        icon = Icons.auto_awesome;
        break;
      case VisionSource.mlKitFallback:
        label = 'Standard AI (Quota Reached)';
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        icon = Icons.smartphone;
        break;
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingXS,
      ),
      color: bgColor,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(DetectedItem item, int index) {
    final isGeneric = _isGenericLabel(item.name);
    final allSuggestions = isGeneric
        ? _getSuggestionsFor(item.name)
        : <Map<String, String>>[];

    // Filter out already used suggestions
    final usedForThisItem = _usedSuggestions[index] ?? {};
    final suggestions = allSuggestions
        .where((s) => !usedForThisItem.contains(s['name']))
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: AppTheme.borderRadiusMedium,
        boxShadow: AppTheme.softShadow,
        border: isGeneric
            ? Border.all(
                color: AppTheme.accentColor.withValues(alpha: 0.3),
                width: 2,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showEditItemDialog(item, index),
          borderRadius: AppTheme.borderRadiusMedium,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isGeneric
                            ? AppTheme.accentColor.withValues(alpha: 0.2)
                            : AppTheme.secondaryLight.withValues(alpha: 0.3),
                        borderRadius: AppTheme.borderRadiusSmall,
                      ),
                      child: Center(
                        child: Icon(
                          isGeneric
                              ? Icons.help_outline_rounded
                              : Icons.restaurant_menu_rounded,
                          color: isGeneric
                              ? AppTheme.accentColor
                              : AppTheme.secondaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isGeneric
                                        ? AppTheme.accentColor
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              if (isGeneric)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentColor.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Generic',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.accentColor,
                                    ),
                                  ),
                                ),
                            ],
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
                if (isGeneric) ...[
                  const SizedBox(height: AppTheme.spacingM),
                  const Divider(height: 1),
                  const SizedBox(height: AppTheme.spacingM),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tap to add items:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => _removeGenericPlaceholder(index),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Remove placeholder',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.errorColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  suggestions.isEmpty
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.successColor.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 16,
                                color: AppTheme.successColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'All items added! Remove placeholder to continue.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.successColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: suggestions.map((suggestion) {
                            return InkWell(
                              onTap: () => _addFromSuggestion(
                                index,
                                suggestion['name']!,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.add_circle_outline,
                                      size: 16,
                                      color: AppTheme.primaryColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      suggestion['emoji']!,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      suggestion['name']!,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                  const SizedBox(height: AppTheme.spacingS),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.touch_app_rounded,
                          size: 14,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Select multiple items from your scan',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
