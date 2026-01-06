import 'package:flutter/material.dart';
import 'package:super_swipe/core/theme/app_theme.dart';

/// A reusable "Type & Add" chip input widget.
/// Users type text, press Enter or tap (+), and items appear as deletable chips.
class MasterChipInput extends StatefulWidget {
  final String label;
  final String hint;
  final List<String> items;
  final ValueChanged<List<String>> onChanged;
  final Color chipColor;
  final Color chipTextColor;
  final IconData? leadingIcon;

  const MasterChipInput({
    super.key,
    required this.label,
    required this.hint,
    required this.items,
    required this.onChanged,
    this.chipColor = const Color(0xFFE8F5E9),
    this.chipTextColor = const Color(0xFF2E7D32),
    this.leadingIcon,
  });

  @override
  State<MasterChipInput> createState() => _MasterChipInputState();
}

class _MasterChipInputState extends State<MasterChipInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addItem(String value) {
    final trimmed = value.toLowerCase().trim();
    if (trimmed.isEmpty) return;
    if (widget.items.contains(trimmed)) return;

    final newList = [...widget.items, trimmed];
    widget.onChanged(newList);
    _controller.clear();
  }

  void _removeItem(String value) {
    final newList = widget.items.where((i) => i != value).toList();
    widget.onChanged(newList);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with icon
        if (widget.leadingIcon != null || widget.label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                if (widget.leadingIcon != null) ...[
                  Icon(
                    widget.leadingIcon,
                    color: AppTheme.primaryColor,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D2621),
                  ),
                ),
              ],
            ),
          ),

        // Input field
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onSubmitted: _addItem,
                  textInputAction: TextInputAction.done,
                ),
              ),
              Material(
                color: Colors.transparent,
                child: IconButton(
                  icon: Icon(
                    Icons.add_circle,
                    color: AppTheme.primaryColor,
                    size: 28,
                  ),
                  onPressed: () => _addItem(_controller.text),
                ),
              ),
            ],
          ),
        ),

        // Chips display
        if (widget.items.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.items
                .map(
                  (item) => Chip(
                    label: Text(item),
                    backgroundColor: widget.chipColor,
                    deleteIcon: const Icon(Icons.close, size: 18),
                    deleteIconColor: widget.chipTextColor,
                    onDeleted: () => _removeItem(item),
                    labelStyle: TextStyle(
                      color: widget.chipTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}
