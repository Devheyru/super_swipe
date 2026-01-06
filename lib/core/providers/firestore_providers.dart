import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_swipe/core/services/firestore_service.dart';
import 'package:super_swipe/core/services/user_service.dart';
import 'package:super_swipe/core/services/pantry_service.dart';
import 'package:super_swipe/core/services/config_service.dart';

/// Base Firestore service provider
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// User service provider
final userServiceProvider = Provider<UserService>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return UserService(firestoreService);
});

/// Pantry service provider
final pantryServiceProvider = Provider<PantryService>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return PantryService(firestoreService);
});

/// Config service provider
final configServiceProvider = Provider<ConfigService>((ref) {
  return ConfigService();
});
