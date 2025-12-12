import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:super_swipe/core/providers/app_state_provider.dart';

class ScanResultsScreen extends ConsumerStatefulWidget {
  final List<String> detectedItems;

  const ScanResultsScreen({super.key, required this.detectedItems});

  @override
  ConsumerState<ScanResultsScreen> createState() => _ScanResultsScreenState();
}

class _ScanResultsScreenState extends ConsumerState<ScanResultsScreen> {
  late List<String> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.detectedItems);
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _confirmItems() {
    final notifier = ref.read(appStateProvider.notifier);
    for (final item in _items) {
      notifier.addPantryItem(item, 1);
    }

    context.pop(); // Go back
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added ${_items.length} items to pantry!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detected Items'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _confirmItems),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return ListTile(
                  title: Text(item),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeItem(index),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                // TODO: Show dialog to add custom item
              },
              child: const Text('Add Manually'),
            ),
          ),
        ],
      ),
    );
  }
}
