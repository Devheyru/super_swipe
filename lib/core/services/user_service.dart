import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:super_swipe/core/models/user_profile.dart';
import 'package:super_swipe/core/services/firestore_service.dart';

/// Service for user profile management in Firestore
class UserService {
  final FirestoreService _firestoreService;

  UserService(this._firestoreService);

  /// Create user profile on signup or first login
  Future<void> createUserProfile(User firebaseUser) async {
    final userDoc = _firestoreService.users.doc(firebaseUser.uid);

    final snapshot = await userDoc.get();
    if (!snapshot.exists) {
      await userDoc.set({
        'uid': firebaseUser.uid,
        'email': firebaseUser.email,
        'displayName': firebaseUser.displayName ?? 'User',
        'isAnonymous': firebaseUser.isAnonymous,
        'subscriptionStatus': 'free',
        'accountCreatedAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'carrots': {
          'current': 5,
          'max': 5,
          'lastResetAt': FieldValue.serverTimestamp(),
        },
        'preferences': {
          'dietaryRestrictions': [],
          'allergies': [],
          'defaultEnergyLevel': 2,
          'preferredCuisines': [],
        },
        'appState': {
          'hasSeenOnboarding': false,
          'hasSeenTutorials': {'swipe': false, 'pantry': false, 'scan': false},
        },
        'stats': {'recipesUnlocked': 0, 'scanCount': 0, 'totalCarrotsSpent': 0},
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Update last login
      await userDoc.update({'lastLoginAt': FieldValue.serverTimestamp()});
    }
  }

  /// Get user profile (one-time fetch)
  Future<UserProfile?> getUserProfile(String userId) async {
    final doc = await _firestoreService.users.doc(userId).get();
    if (doc.exists) {
      return UserProfile.fromFirestore(doc);
    }
    return null;
  }

  /// Stream user profile (real-time updates)
  Stream<UserProfile?> watchUserProfile(String userId) {
    return _firestoreService.users.doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Update user profile
  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    await _firestoreService.users.doc(userId).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update dietary preferences
  Future<void> updatePreferences(
    String userId,
    UserPreferences preferences,
  ) async {
    await updateUserProfile(userId, {'preferences': preferences.toMap()});
  }

  /// Spend carrots (with transaction to prevent race conditions)
  Future<bool> spendCarrots(String userId, int amount) async {
    final userRef = _firestoreService.users.doc(userId);

    return await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) return false;

      final data = snapshot.data() as Map<String, dynamic>?;
      final currentCarrots =
          (data?['carrots'] as Map<String, dynamic>?)?['current'] as int? ?? 0;

      if (currentCarrots >= amount) {
        transaction.update(userRef, {
          'carrots.current': currentCarrots - amount,
          'stats.totalCarrotsSpent': FieldValue.increment(amount),
          'stats.recipesUnlocked': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return true;
      }
      return false;
    });
  }

  /// Reset carrots (weekly reset or manual)
  Future<void> resetCarrots(String userId) async {
    await _firestoreService.users.doc(userId).update({
      'carrots.current': 5,
      'carrots.lastResetAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Mark onboarding as complete
  Future<void> markOnboardingComplete(String userId) async {
    await updateUserProfile(userId, {'appState.hasSeenOnboarding': true});
  }

  /// Mark tutorial as complete
  Future<void> markTutorialComplete(String userId, String tutorialKey) async {
    await updateUserProfile(userId, {
      'appState.hasSeenTutorials.$tutorialKey': true,
    });
  }

  /// Increment scan count
  Future<void> incrementScanCount(String userId) async {
    await _firestoreService.users.doc(userId).update({
      'stats.scanCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Increment recipes unlocked count
  Future<void> incrementRecipesUnlocked(String userId) async {
    await _firestoreService.users.doc(userId).update({
      'stats.recipesUnlocked': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
