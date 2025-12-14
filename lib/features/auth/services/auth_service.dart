import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:super_swipe/core/services/firestore_service.dart';
import 'package:super_swipe/core/services/user_service.dart';

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
  final GoogleSignIn _googleSignIn;

  AuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
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

        // Create Firestore user profile
        final userService = UserService(FirestoreService());
        await userService.createUserProfile(updatedUser!);

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
        // Create or update Firestore user profile
        final userService = UserService(FirestoreService());
        await userService.createUserProfile(user);

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
        // Create Firestore user profile for anonymous user
        final userService = UserService(FirestoreService());
        await userService.createUserProfile(userCredential.user!);

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
