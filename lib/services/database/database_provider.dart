import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_swipe/services/database/database_service.dart';

/// Global provider for the DatabaseService singleton.
/// Use this instead of the legacy UserService, RecipeService, PantryService.
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

/// Alias for backwards compatibility during migration.
/// TODO: Remove this once all old service references are updated.
final dbProvider = databaseServiceProvider;
