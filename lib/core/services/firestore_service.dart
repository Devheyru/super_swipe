import 'package:cloud_firestore/cloud_firestore.dart';

/// Base Firestore service providing access to all collections
class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Root collection references
  CollectionReference get users => _firestore.collection('users');
  CollectionReference get recipes => _firestore.collection('recipes');
  CollectionReference get ingredients => _firestore.collection('ingredients');

  /// User-specific sub-collection references
  CollectionReference userPantry(String userId) =>
      users.doc(userId).collection('pantry');

  CollectionReference userSavedRecipes(String userId) =>
      users.doc(userId).collection('savedRecipes');

  CollectionReference userRecipeHistory(String userId) =>
      users.doc(userId).collection('recipeHistory');

  /// Get Firestore instance (for advanced operations)
  FirebaseFirestore get instance => _firestore;
}
