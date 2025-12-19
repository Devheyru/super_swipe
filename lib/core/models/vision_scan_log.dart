import 'package:cloud_firestore/cloud_firestore.dart';

/// Log entry for vision API usage tracking
class VisionScanLog {
  final String id;
  final String userId;
  final DateTime timestamp;
  final VisionSourceType source;
  final int itemsDetected;
  final double averageConfidence;
  final int objectCount;
  final String? escalationReason;
  final bool quotaAvailable;
  final double processingTimeMs;

  VisionScanLog({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.source,
    required this.itemsDetected,
    required this.averageConfidence,
    required this.objectCount,
    this.escalationReason,
    required this.quotaAvailable,
    required this.processingTimeMs,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
      'source': source.name,
      'itemsDetected': itemsDetected,
      'averageConfidence': averageConfidence,
      'objectCount': objectCount,
      'escalationReason': escalationReason,
      'quotaAvailable': quotaAvailable,
      'processingTimeMs': processingTimeMs,
    };
  }

  factory VisionScanLog.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return VisionScanLog(
      id: snapshot.id,
      userId: data['userId'] as String,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      source: VisionSourceType.values.byName(data['source'] as String),
      itemsDetected: data['itemsDetected'] as int,
      averageConfidence: (data['averageConfidence'] as num).toDouble(),
      objectCount: data['objectCount'] as int,
      escalationReason: data['escalationReason'] as String?,
      quotaAvailable: data['quotaAvailable'] as bool,
      processingTimeMs: (data['processingTimeMs'] as num).toDouble(),
    );
  }
}

enum VisionSourceType { mlKit, cloudVision, mlKitFallback }

/// Daily quota usage summary
class QuotaUsageSummary {
  final String id;
  final DateTime date;
  final int totalScans;
  final int mlKitScans;
  final int cloudVisionScans;
  final int fallbackScans;
  final double estimatedCost; // in USD
  final int quotaRemaining;

  QuotaUsageSummary({
    required this.id,
    required this.date,
    required this.totalScans,
    required this.mlKitScans,
    required this.cloudVisionScans,
    required this.fallbackScans,
    required this.estimatedCost,
    required this.quotaRemaining,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'date': Timestamp.fromDate(date),
      'totalScans': totalScans,
      'mlKitScans': mlKitScans,
      'cloudVisionScans': cloudVisionScans,
      'fallbackScans': fallbackScans,
      'estimatedCost': estimatedCost,
      'quotaRemaining': quotaRemaining,
    };
  }

  factory QuotaUsageSummary.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return QuotaUsageSummary(
      id: snapshot.id,
      date: (data['date'] as Timestamp).toDate(),
      totalScans: data['totalScans'] as int,
      mlKitScans: data['mlKitScans'] as int,
      cloudVisionScans: data['cloudVisionScans'] as int,
      fallbackScans: data['fallbackScans'] as int,
      estimatedCost: (data['estimatedCost'] as num).toDouble(),
      quotaRemaining: data['quotaRemaining'] as int,
    );
  }
}

/// User-specific quota settings
class UserQuotaSettings {
  final String userId;
  final int dailyLimit;
  final int monthlyLimit;
  final bool isPremium;
  final DateTime? premiumExpiresAt;

  UserQuotaSettings({
    required this.userId,
    required this.dailyLimit,
    required this.monthlyLimit,
    this.isPremium = false,
    this.premiumExpiresAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'dailyLimit': dailyLimit,
      'monthlyLimit': monthlyLimit,
      'isPremium': isPremium,
      'premiumExpiresAt': premiumExpiresAt != null
          ? Timestamp.fromDate(premiumExpiresAt!)
          : null,
    };
  }

  factory UserQuotaSettings.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return UserQuotaSettings(
      userId: snapshot.id,
      dailyLimit: data['dailyLimit'] as int,
      monthlyLimit: data['monthlyLimit'] as int,
      isPremium: data['isPremium'] as bool? ?? false,
      premiumExpiresAt: data['premiumExpiresAt'] != null
          ? (data['premiumExpiresAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Default settings
  factory UserQuotaSettings.defaultSettings(String userId) {
    return UserQuotaSettings(
      userId: userId,
      dailyLimit: 100,
      monthlyLimit: 2000,
      isPremium: false,
    );
  }

  // Premium settings
  factory UserQuotaSettings.premiumSettings(String userId, DateTime expiresAt) {
    return UserQuotaSettings(
      userId: userId,
      dailyLimit: 500,
      monthlyLimit: 10000,
      isPremium: true,
      premiumExpiresAt: expiresAt,
    );
  }
}

