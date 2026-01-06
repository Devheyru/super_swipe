import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:super_swipe/core/models/pantry_item.dart';
import 'package:super_swipe/core/services/firestore_service.dart';

/// Service for pantry management in Firestore
class PantryService {
  final FirestoreService _firestoreService;

  PantryService(this._firestoreService);

  /// Get all pantry items for a user (one-time fetch, alphabetically sorted)
  Future<List<PantryItem>> getUserPantry(String userId) async {
    final snapshot = await _firestoreService
        .userPantry(userId)
        .orderBy('name')
        .get();

    return snapshot.docs.map((doc) => PantryItem.fromFirestore(doc)).toList();
  }

  /// Stream pantry items (real-time updates, alphabetically sorted)
  Stream<List<PantryItem>> watchUserPantry(String userId) {
    return _firestoreService
        .userPantry(userId)
        .orderBy('name') // Single field ordering - no index needed
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PantryItem.fromFirestore(doc))
              .toList();
        });
  }

  /// Add a single pantry item
  Future<void> addPantryItem(
    String userId,
    String name, {
    int quantity = 1,
    String category = 'other',
    String unit = 'pieces',
    String source = 'manual',
    double? detectionConfidence,
  }) async {
    // Let Firestore generate safe IDs (Fix #1)
    final docRef = _firestoreService.userPantry(userId).doc();
    final now = DateTime.now();

    final item = PantryItem(
      id: docRef.id, // Use Firestore's auto-generated safe ID
      userId: userId,
      name: name,
      normalizedName: name.toLowerCase().trim(),
      category: category,
      quantity: quantity,
      unit: unit,
      source: source,
      detectionConfidence: detectionConfidence,
      addedAt: now,
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(item.toFirestore());
  }

  /// Batch add pantry items
  Future<void> batchAddPantryItems(
    String userId,
    List<Map<String, dynamic>> items,
  ) async {
    final batch = FirebaseFirestore.instance.batch();
    final now = DateTime.now();

    for (var i = 0; i < items.length; i++) {
      final itemData = items[i];
      final name = itemData['name'] as String;
      final docRef = _firestoreService.userPantry(userId).doc();

      final item = PantryItem(
        id: docRef.id,
        userId: userId,
        name: name,
        normalizedName: name.toLowerCase().trim(),
        category: itemData['category'] ?? 'other',
        quantity: itemData['quantity'] ?? 1,
        unit: itemData['unit'] ?? 'pieces',
        source: itemData['source'] ?? 'manual',
        addedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      batch.set(docRef, item.toFirestore());
    }

    await batch.commit();
  }

  /// Update pantry item
  Future<void> updatePantryItem(
    String userId,
    String itemId, {
    String? name,
    int? quantity,
    String? category,
    String? unit,
  }) async {
    final updates = <String, dynamic>{};

    if (name != null) {
      updates['name'] = name;
      updates['normalizedName'] = name.toLowerCase().trim();
    }
    if (quantity != null) updates['quantity'] = quantity;
    if (category != null) updates['category'] = category;
    if (unit != null) updates['unit'] = unit;

    updates['updatedAt'] = FieldValue.serverTimestamp();

    await _firestoreService.userPantry(userId).doc(itemId).update(updates);
  }

  /// Delete pantry item
  Future<void> deletePantryItem(String userId, String itemId) async {
    await _firestoreService.userPantry(userId).doc(itemId).delete();
  }

  /// Clear all pantry items
  Future<void> clearPantry(String userId) async {
    // Fix #4: Handle batch limit of 500 documents
    const batchSize = 500;
    final snapshot = await _firestoreService.userPantry(userId).get();

    for (var i = 0; i < snapshot.docs.length; i += batchSize) {
      final batch = FirebaseFirestore.instance.batch();
      final end = (i + batchSize < snapshot.docs.length)
          ? i + batchSize
          : snapshot.docs.length;

      for (var j = i; j < end; j++) {
        batch.delete(snapshot.docs[j].reference);
      }

      await batch.commit();
    }
  }

  /// Search pantry items by name
  Future<List<PantryItem>> searchPantry(String userId, String query) async {
    final normalizedQuery = query.toLowerCase().trim();

    final snapshot = await _firestoreService
        .userPantry(userId)
        .where('normalizedName', isGreaterThanOrEqualTo: normalizedQuery)
        .where('normalizedName', isLessThanOrEqualTo: '$normalizedQuery\uf8ff')
        .get();

    return snapshot.docs.map((doc) => PantryItem.fromFirestore(doc)).toList();
  }

  /// Get pantry items by category
  Future<List<PantryItem>> getPantryByCategory(
    String userId,
    String category,
  ) async {
    final snapshot = await _firestoreService
        .userPantry(userId)
        .where('category', isEqualTo: category)
        .orderBy('name')
        .get();

    return snapshot.docs.map((doc) => PantryItem.fromFirestore(doc)).toList();
  }

  /// Get recently added items
  Future<List<PantryItem>> getRecentlyAdded(
    String userId, {
    int limit = 10,
  }) async {
    final snapshot = await _firestoreService
        .userPantry(userId)
        .orderBy('addedAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => PantryItem.fromFirestore(doc)).toList();
  }
}
