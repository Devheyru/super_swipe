import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Result wrapper for authentication operations
class AuthResult {
  final bool success;
  final String? errorMessage;
  final User? user;

  const AuthResult({required this.success, this.errorMessage, this.user});

  factory AuthResult.success(User user) =>
      AuthResult(success: true, user: user);
  factory AuthResult.failure(String message) =>
      AuthResult(success: false, errorMessage: message);
}

/// Service class that handles all Firebase Authentication operations
class AuthService {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn();

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  Stream<User?> get userChanges => _firebaseAuth.userChanges();
  User? get currentUser => _firebaseAuth.currentUser;
  bool get isSignedIn => currentUser != null;

  /// Sign in with email and password
  Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (credential.user != null) {
        return AuthResult.success(credential.user!);
      }
      return AuthResult.failure('Sign in failed. Please try again.');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseAuthError(e.code));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred: $e');
    }
  }

  /// Create a new account with email and password
  Future<AuthResult> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (credential.user != null) {
        await credential.user!.updateDisplayName(displayName.trim());

        // Reload user to ensure displayName is updated in the local object
        await credential.user!.reload();
        final updatedUser = _firebaseAuth.currentUser;

        await _createUserProfile(
          uid: updatedUser!.uid,
          email: email.trim(),
          displayName: displayName.trim(),
        );
        return AuthResult.success(updatedUser);
      }
      return AuthResult.failure('Account creation failed. Please try again.');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseAuthError(e.code));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred: $e');
    }
  }

  /// Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return AuthResult.failure('Sign in cancelled by user');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // Check if user exists in Firestore, if not create profile
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        if (!userDoc.exists) {
          await _createUserProfile(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? 'User',
          );
        }
        return AuthResult.success(user);
      }

      return AuthResult.failure('Google sign in failed. Please try again.');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseAuthError(e.code));
    } catch (e) {
      return AuthResult.failure(
        'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Sign in anonymously
  Future<AuthResult> signInAnonymously() async {
    try {
      final userCredential = await _firebaseAuth.signInAnonymously();
      if (userCredential.user != null) {
        return AuthResult.success(userCredential.user!);
      }
      return AuthResult.failure('Anonymous sign in failed.');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseAuthError(e.code));
    } catch (e) {
      return AuthResult.failure(
        'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    await Future.wait([_firebaseAuth.signOut(), _googleSignIn.signOut()]);
  }

  /// Send password reset email
  Future<AuthResult> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
      return const AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseAuthError(e.code));
    } catch (e) {
      return AuthResult.failure(
        'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Create user profile document in Firestore
  Future<void> _createUserProfile({
    required String uid,
    required String email,
    required String displayName,
  }) async {
    final userDoc = _firestore.collection('users').doc(uid);
    await userDoc.set({
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'dietary_preferences': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'profileCompleted': false,
      'avatarUrl': null,
    });
  }

  /// Update user profile in Firestore
  Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    List<String>? dietaryPreferences,
    String? avatarUrl,
  }) async {
    final userDoc = _firestore.collection('users').doc(uid);
    final updateData = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (displayName != null) updateData['displayName'] = displayName;
    if (dietaryPreferences != null) {
      updateData['dietary_preferences'] = dietaryPreferences;
    }
    if (avatarUrl != null) updateData['avatarUrl'] = avatarUrl;
    await userDoc.update(updateData);
  }

  /// Get user profile from Firestore
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  /// Map Firebase Auth error codes to user-friendly messages
  String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered. Try signing in instead.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled. Please contact support.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'user-not-found':
        return 'No account found with this email. Please sign up first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password. Please check and try again.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'channel-error':
        return 'Please fill in all fields correctly.';
      default:
        return 'An error occurred ($code). Please try again.';
    }
  }
}
