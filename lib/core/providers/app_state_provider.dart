import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_swipe/core/models/pantry_item.dart';
import 'package:super_swipe/core/models/recipe.dart';
import 'package:super_swipe/features/auth/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState {
  final int carrotCount;
  final List<Recipe> unlockedRecipes;
  final List<PantryItem> pantryItems;
  final bool isGuest;
  final bool hasSeenWelcome;
  final bool filterExpanded;
  final bool skipUnlockReminder;

  const AppState({
    required this.carrotCount,
    required this.unlockedRecipes,
    required this.pantryItems,
    required this.isGuest,
    required this.hasSeenWelcome,
    required this.filterExpanded,
    required this.skipUnlockReminder,
  });

  AppState copyWith({
    int? carrotCount,
    List<Recipe>? unlockedRecipes,
    List<PantryItem>? pantryItems,
    bool? isGuest,
    bool? hasSeenWelcome,
    bool? filterExpanded,
    bool? skipUnlockReminder,
  }) {
    return AppState(
      carrotCount: carrotCount ?? this.carrotCount,
      unlockedRecipes: unlockedRecipes ?? this.unlockedRecipes,
      pantryItems: pantryItems ?? this.pantryItems,
      isGuest: isGuest ?? this.isGuest,
      hasSeenWelcome: hasSeenWelcome ?? this.hasSeenWelcome,
      filterExpanded: filterExpanded ?? this.filterExpanded,
      skipUnlockReminder: skipUnlockReminder ?? this.skipUnlockReminder,
    );
  }
}

class AppStateNotifier extends Notifier<AppState> {
  static const _welcomeKey = 'has_seen_welcome';
  static const _filterExpandedKey = 'filter_panel_expanded';
  static const _skipUnlockReminderKey = 'skip_unlock_reminder';

  String _getCarrotKey(String? uid) =>
      (uid == null || uid.isEmpty) ? 'carrot_count' : 'carrot_count_$uid';
  String _getResetKey(String? uid) =>
      (uid == null || uid.isEmpty) ? 'last_reset_date' : 'last_reset_date_$uid';

  @override
  AppState build() {
    _loadPersistedFlags();

    // Sync isGuest with AuthProvider and reload data on user change
    ref.listen(authProvider, (previous, next) {
      final previousUid = previous?.user?.uid;
      final nextUid = next.user?.uid;

      if (previousUid != nextUid) {
        _loadPersistedFlags();
      }

      final isGuest = next.user?.isAnonymous ?? true;
      // Only update if changed to avoid unnecessary rebuilds
      if (state.isGuest != isGuest) {
        state = state.copyWith(isGuest: isGuest);
      }
    });

    final authState = ref.read(authProvider);
    final isGuest = authState.user?.isAnonymous ?? true;

    return AppState(
      carrotCount: 5,
      unlockedRecipes: const [],
      pantryItems:
          const [], // Pantry items loaded from Firestore via pantryItemsProvider
      isGuest: isGuest,
      hasSeenWelcome: false,
      filterExpanded: false,
      skipUnlockReminder: false,
    );
  }

  Future<void> _loadPersistedFlags() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(_welcomeKey) ?? false;
    final expanded = prefs.getBool(_filterExpandedKey) ?? false;
    final skipReminder = prefs.getBool(_skipUnlockReminderKey) ?? false;

    // Carrot Economy Logic
    final user = ref.read(authProvider).user;
    // If anonymous, use generic key (or maybe they shouldn't have persistent carrots?)
    // For now, we treat anonymous users as having a local 'carrot_count'
    final uid = user?.isAnonymous == true ? null : user?.uid;

    final carrotKey = _getCarrotKey(uid);
    final resetKey = _getResetKey(uid);

    final lastResetMillis = prefs.getInt(resetKey) ?? 0;
    int currentCarrots = 5;

    if (lastResetMillis == 0) {
      // First run for this user, initialize
      await prefs.setInt(resetKey, DateTime.now().millisecondsSinceEpoch);
      await prefs.setInt(carrotKey, 5);
    } else {
      final lastReset = DateTime.fromMillisecondsSinceEpoch(lastResetMillis);
      final now = DateTime.now();
      final difference = now.difference(lastReset).inDays;

      if (difference >= 7) {
        // Weekly Reset
        currentCarrots = 5;
        await prefs.setInt(resetKey, now.millisecondsSinceEpoch);
        await prefs.setInt(carrotKey, 5);
      } else {
        // Load persisted count
        currentCarrots = prefs.getInt(carrotKey) ?? 5;
      }
    }

    state = state.copyWith(
      hasSeenWelcome: seen,
      filterExpanded: expanded,
      skipUnlockReminder: skipReminder,
      carrotCount: currentCarrots,
    );
  }

  Future<void> markWelcomeSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_welcomeKey, true);
    state = state.copyWith(hasSeenWelcome: true);
  }

  Future<void> setFilterExpanded(bool expanded) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_filterExpandedKey, expanded);
    state = state.copyWith(filterExpanded: expanded);
  }

  Future<void> setSkipUnlockReminder(bool skip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_skipUnlockReminderKey, skip);
    state = state.copyWith(skipUnlockReminder: skip);
  }

  void setGuestMode(bool value) {
    state = state.copyWith(isGuest: value);
  }

  bool canSwipeRight() => !state.isGuest && state.carrotCount > 0;

  bool unlockRecipe(Recipe recipe) {
    if (!canSwipeRight()) return false;
    if (state.unlockedRecipes.any((r) => r.id == recipe.id)) {
      return true;
    }
    final newCount = state.carrotCount - 1;
    state = state.copyWith(
      carrotCount: newCount,
      unlockedRecipes: [...state.unlockedRecipes, recipe],
    );
    _persistCarrotCount(newCount);
    return true;
  }

  Future<void> _persistCarrotCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    final user = ref.read(authProvider).user;
    final uid = user?.isAnonymous == true ? null : user?.uid;
    await prefs.setInt(_getCarrotKey(uid), count);
  }

  void resetCarrots() {
    state = state.copyWith(carrotCount: 5);
    _persistCarrotCount(5);
  }

  // Note: Pantry CRUD operations have been moved to PantryService
  // Use pantryServiceProvider in your UI instead
}

final appStateProvider = NotifierProvider<AppStateNotifier, AppState>(
  AppStateNotifier.new,
);
