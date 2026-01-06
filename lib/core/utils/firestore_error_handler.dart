import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Utility class for handling Firestore errors with user-friendly messages
class FirestoreErrorHandler {
  /// Convert a Firestore exception to a user-friendly message
  static String getUserFriendlyMessage(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'You don\'t have permission to perform this action. Please sign in again.';
        case 'unavailable':
          return 'Service temporarily unavailable. Please check your internet connection.';
        case 'not-found':
          return 'The requested data was not found.';
        case 'already-exists':
          return 'This item already exists.';
        case 'unauthenticated':
          return 'Please sign in to continue.';
        case 'resource-exhausted':
          return 'Too many requests. Please try again in a moment.';
        case 'cancelled':
          return 'Operation was cancelled.';
        case 'data-loss':
          return 'Data loss occurred. Please try again.';
        case 'deadline-exceeded':
          return 'Request timed out. Please try again.';
        case 'aborted':
          return 'Operation was aborted. Please try again.';
        default:
          return 'An error occurred. Please try again.';
      }
    }

    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('permission') || errorStr.contains('denied')) {
      return 'You don\'t have permission to perform this action.';
    }
    if (errorStr.contains('network') || errorStr.contains('connection')) {
      return 'Network error. Please check your internet connection.';
    }
    if (errorStr.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }

    return 'Something went wrong. Please try again.';
  }

  /// Show a user-friendly error snackbar
  static void showErrorSnackbar(
    BuildContext context,
    dynamic error, {
    String? customMessage,
  }) {
    final message = customMessage ?? getUserFriendlyMessage(error);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  /// Show a success snackbar
  static void showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
