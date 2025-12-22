import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_swipe/core/models/user_profile.dart';
import 'package:super_swipe/core/models/pantry_item.dart';
import 'package:super_swipe/core/models/daily_quota_summary.dart';
import 'package:super_swipe/core/config/pantry_constants.dart';
import 'package:super_swipe/core/providers/firestore_providers.dart';
import 'package:super_swipe/features/auth/providers/auth_provider.dart';

/// Stream user profile (real-time updates)
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final authState = ref.watch(authProvider);
  final userService = ref.watch(userServiceProvider);

  if (authState.user == null) {
    return Stream.value(null);
  }

  return userService.watchUserProfile(authState.user!.uid);
});

/// Stream pantry items (real-time updates)
final pantryItemsProvider = StreamProvider<List<PantryItem>>((ref) {
  final authState = ref.watch(authProvider);
  final pantryService = ref.watch(pantryServiceProvider);

  if (authState.user == null) {
    return Stream.value([]);
  }

  return pantryService.watchUserPantry(authState.user!.uid);
});

/// Get pantry items count
final pantryCountProvider = Provider<int>((ref) {
  final pantryItems = ref.watch(pantryItemsProvider);
  return pantryItems.maybeWhen(data: (items) => items.length, orElse: () => 0);
});

/// Stream daily quota summary (real-time usage)
final dailyQuotaSummaryProvider = StreamProvider<DailyQuotaSummary>((ref) {
  final authState = ref.watch(authProvider);
  final quotaService = ref.watch(quotaServiceProvider);

  if (authState.user == null) {
    return Stream.value(
      DailyQuotaSummary.empty(_getDateKey(DateTime.now()), userId: ''),
    );
  }

  return quotaService.watchDailyQuota(authState.user!.uid);
});

/// Helper to get date key in provider (dup logic but safe)
String _getDateKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

/// Fetch pantry categories (Cached & Server-updated)
final pantryCategoriesProvider = FutureProvider<List<PantryCategory>>((ref) {
  final configService = ref.watch(configServiceProvider);
  return configService.getPantryCategories();
});
