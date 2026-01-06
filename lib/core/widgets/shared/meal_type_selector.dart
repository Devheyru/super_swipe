import 'package:flutter/material.dart';
import 'package:super_swipe/core/theme/app_theme.dart';

/// A reusable meal type selector with horizontal scrollable chips.
/// Single-select only with primary color highlight.
class MealTypeSelector extends StatelessWidget {
  final String? selectedMealType;
  final ValueChanged<String> onChanged;
  final String? label;
  final bool scrollable;

  const MealTypeSelector({
    super.key,
    required this.selectedMealType,
    required this.onChanged,
    this.label,
    this.scrollable = true,
  });

  static const mealTypes = [
    'breakfast',
    'lunch',
    'dinner',
    'snack',
    'dessert',
    'drinks',
  ];

  static const mealIcons = {
    'breakfast': '🌅',
    'lunch': '🥗',
    'dinner': '🍽️',
    'snack': '🍿',
    'dessert': '🍰',
    'drinks': '🥤',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D2621),
            ),
          ),
          const SizedBox(height: 12),
        ],
        scrollable
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: _buildChips()),
              )
            : Wrap(spacing: 8, runSpacing: 8, children: _buildChips()),
      ],
    );
  }

  List<Widget> _buildChips() {
    return mealTypes.map((type) {
      final isSelected = selectedMealType == type;
      final emoji = mealIcons[type] ?? '';

      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                type[0].toUpperCase() + type.substring(1),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) onChanged(type);
          },
          selectedColor: AppTheme.primaryColor,
          backgroundColor: Colors.grey.shade100,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      );
    }).toList();
  }
}
