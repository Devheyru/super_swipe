import 'package:cloud_firestore/cloud_firestore.dart';

/// User profile model with Firestore serialization
class UserProfile {
  final String uid;
  final String? email;
  final String displayName;
  final bool isAnonymous;
  final String subscriptionStatus;
  final Carrots carrots;
  final UserPreferences preferences;
  final AppState appState;
  final UserStats stats;
  final DateTime? accountCreatedAt;
  final DateTime? lastLoginAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.uid,
    this.email,
    required this.displayName,
    required this.isAnonymous,
    this.subscriptionStatus = 'free',
    required this.carrots,
    required this.preferences,
    required this.appState,
    required this.stats,
    this.accountCreatedAt,
    this.lastLoginAt,
    this.updatedAt,
  });

  /// Factory constructor from Firestore document
  /// Fix #2: Null-safe with flexible type for compatibility
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};

    if (!doc.exists || data.isEmpty) {
      throw StateError('Document does not exist: ${doc.id}');
    }

    return UserProfile(
      uid: data['uid'] ?? doc.id,
      email: data['email'],
      displayName: data['displayName'] ?? 'User',
      isAnonymous: data['isAnonymous'] ?? false,
      subscriptionStatus: data['subscriptionStatus'] ?? 'free',
      carrots: Carrots.fromMap(data['carrots'] ?? {}),
      preferences: UserPreferences.fromMap(data['preferences'] ?? {}),
      appState: AppState.fromMap(data['appState'] ?? {}),
      stats: UserStats.fromMap(data['stats'] ?? {}),
      accountCreatedAt: (data['accountCreatedAt'] as Timestamp?)?.toDate(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'isAnonymous': isAnonymous,
      'subscriptionStatus': subscriptionStatus,
      'carrots': carrots.toMap(),
      'preferences': preferences.toMap(),
      'appState': appState.toMap(),
      'stats': stats.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  UserProfile copyWith({
    String? displayName,
    String? subscriptionStatus,
    Carrots? carrots,
    UserPreferences? preferences,
    AppState? appState,
    UserStats? stats,
  }) {
    return UserProfile(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      isAnonymous: isAnonymous,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      carrots: carrots ?? this.carrots,
      preferences: preferences ?? this.preferences,
      appState: appState ?? this.appState,
      stats: stats ?? this.stats,
      accountCreatedAt: accountCreatedAt,
      lastLoginAt: lastLoginAt,
      updatedAt: updatedAt,
    );
  }
}

/// Carrot economy sub-model
class Carrots {
  final int current;
  final int max;
  final DateTime? lastResetAt;

  const Carrots({required this.current, required this.max, this.lastResetAt});

  factory Carrots.fromMap(Map<String, dynamic> map) {
    return Carrots(
      current: map['current'] ?? 5,
      max: map['max'] ?? 5,
      lastResetAt: (map['lastResetAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'current': current,
      'max': max,
      'lastResetAt': lastResetAt != null
          ? Timestamp.fromDate(lastResetAt!)
          : null,
    };
  }

  Carrots copyWith({int? current, int? max, DateTime? lastResetAt}) {
    return Carrots(
      current: current ?? this.current,
      max: max ?? this.max,
      lastResetAt: lastResetAt ?? this.lastResetAt,
    );
  }
}

/// User preferences sub-model
class UserPreferences {
  final List<String> dietaryRestrictions;
  final List<String> allergies;
  final int defaultEnergyLevel;
  final List<String> preferredCuisines;

  const UserPreferences({
    this.dietaryRestrictions = const [],
    this.allergies = const [],
    this.defaultEnergyLevel = 2,
    this.preferredCuisines = const [],
  });

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      dietaryRestrictions: List<String>.from(map['dietaryRestrictions'] ?? []),
      allergies: List<String>.from(map['allergies'] ?? []),
      defaultEnergyLevel: map['defaultEnergyLevel'] ?? 2,
      preferredCuisines: List<String>.from(map['preferredCuisines'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dietaryRestrictions': dietaryRestrictions,
      'allergies': allergies,
      'defaultEnergyLevel': defaultEnergyLevel,
      'preferredCuisines': preferredCuisines,
    };
  }

  UserPreferences copyWith({
    List<String>? dietaryRestrictions,
    List<String>? allergies,
    int? defaultEnergyLevel,
    List<String>? preferredCuisines,
  }) {
    return UserPreferences(
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      allergies: allergies ?? this.allergies,
      defaultEnergyLevel: defaultEnergyLevel ?? this.defaultEnergyLevel,
      preferredCuisines: preferredCuisines ?? this.preferredCuisines,
    );
  }
}

/// App state sub-model
class AppState {
  final bool hasSeenOnboarding;
  final Map<String, bool> hasSeenTutorials;

  const AppState({
    this.hasSeenOnboarding = false,
    this.hasSeenTutorials = const {},
  });

  factory AppState.fromMap(Map<String, dynamic> map) {
    return AppState(
      hasSeenOnboarding: map['hasSeenOnboarding'] ?? false,
      hasSeenTutorials: Map<String, bool>.from(map['hasSeenTutorials'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hasSeenOnboarding': hasSeenOnboarding,
      'hasSeenTutorials': hasSeenTutorials,
    };
  }

  AppState copyWith({
    bool? hasSeenOnboarding,
    Map<String, bool>? hasSeenTutorials,
  }) {
    return AppState(
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
      hasSeenTutorials: hasSeenTutorials ?? this.hasSeenTutorials,
    );
  }
}

/// User statistics sub-model
class UserStats {
  final int recipesUnlocked;
  final int scanCount;
  final int totalCarrotsSpent;

  const UserStats({
    this.recipesUnlocked = 0,
    this.scanCount = 0,
    this.totalCarrotsSpent = 0,
  });

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      recipesUnlocked: map['recipesUnlocked'] ?? 0,
      scanCount: map['scanCount'] ?? 0,
      totalCarrotsSpent: map['totalCarrotsSpent'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recipesUnlocked': recipesUnlocked,
      'scanCount': scanCount,
      'totalCarrotsSpent': totalCarrotsSpent,
    };
  }

  UserStats copyWith({
    int? recipesUnlocked,
    int? scanCount,
    int? totalCarrotsSpent,
  }) {
    return UserStats(
      recipesUnlocked: recipesUnlocked ?? this.recipesUnlocked,
      scanCount: scanCount ?? this.scanCount,
      totalCarrotsSpent: totalCarrotsSpent ?? this.totalCarrotsSpent,
    );
  }
}
