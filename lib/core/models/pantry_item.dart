import 'package:cloud_firestore/cloud_firestore.dart';

/// Pantry item model with Firestore serialization
class PantryItem {
  final String id;
  final String userId;
  final String name;
  final String normalizedName;
  final String category;
  final int quantity;
  final String unit;
  final String source; // 'manual' | 'scanned' | 'ai-suggested'
  final double? detectionConfidence;
  final DateTime? expiresAt;
  final DateTime addedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PantryItem({
    required this.id,
    required this.userId,
    required this.name,
    required this.normalizedName,
    required this.category,
    required this.quantity,
    this.unit = 'pieces',
    this.source = 'manual',
    this.detectionConfidence,
    this.expiresAt,
    required this.addedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory constructor from Firestore document
  /// Fix #1 & #2: Null-safe with flexible type for compatibility
  factory PantryItem.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};

    if (!doc.exists || data.isEmpty) {
      throw StateError('Document does not exist or has no data: ${doc.id}');
    }

    return PantryItem(
      id: data['id'] ?? doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      normalizedName: data['normalizedName'] ?? '',
      category: data['category'] ?? 'other',
      quantity: data['quantity'] ?? 1,
      unit: data['unit'] ?? 'pieces',
      source: data['source'] ?? 'manual',
      detectionConfidence: data['detectionConfidence']?.toDouble(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      addedAt: (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'normalizedName': normalizedName,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'source': source,
      'detectionConfidence': detectionConfidence,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'addedAt': Timestamp.fromDate(addedAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  PantryItem copyWith({
    String? name,
    int? quantity,
    String? category,
    String? unit,
    DateTime? expiresAt,
  }) {
    return PantryItem(
      id: id,
      userId: userId,
      name: name ?? this.name,
      normalizedName: (name ?? this.name).toLowerCase().trim(),
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      source: source,
      detectionConfidence: detectionConfidence,
      expiresAt: expiresAt ?? this.expiresAt,
      addedAt: addedAt,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
