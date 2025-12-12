class PantryItem {
  final String id;
  final String name;
  final int quantity;

  const PantryItem({
    required this.id,
    required this.name,
    required this.quantity,
  });

  PantryItem copyWith({
    String? id,
    String? name,
    int? quantity,
  }) {
    return PantryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
    );
  }
}


