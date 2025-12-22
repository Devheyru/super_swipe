import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a daily summary of scan usage for O(1) reads
class DailyQuotaSummary {
  final String userId;
  final String dateKey; // Format: YYYY-MM-DD
  final int totalScans;
  final int usedCloudVision;
  final int usedMLKit;
  final int dailyLimit;
  final DateTime updatedAt;

  DailyQuotaSummary({
    required this.userId,
    required this.dateKey,
    required this.totalScans,
    required this.usedCloudVision,
    required this.usedMLKit,
    required this.dailyLimit,
    required this.updatedAt,
  });

  factory DailyQuotaSummary.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null)
      return empty(
        doc.id,
        userId: doc.reference.parent.parent?.id ?? '',
      ); // aggressive fallback

    // userId might be in data or inferred from ID/path
    // ID format: {userId}_{date}
    final docIdParts = doc.id.split('_');
    final dateKey = docIdParts.length > 1 ? docIdParts.last : doc.id;

    return DailyQuotaSummary(
      userId:
          data['userId'] as String? ??
          (docIdParts.isNotEmpty ? docIdParts.first : ''),
      dateKey: data['dateKey'] as String? ?? dateKey,
      totalScans: data['totalScans'] as int? ?? 0,
      usedCloudVision:
          (data['usedCloudVision'] ?? data['cloudVisionScans']) as int? ?? 0,
      usedMLKit: (data['usedMLKit'] ?? data['mlKitScans']) as int? ?? 0,
      dailyLimit: data['dailyLimit'] as int? ?? 10,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static DailyQuotaSummary empty(String dateKey, {required String userId}) {
    return DailyQuotaSummary(
      userId: userId,
      dateKey: dateKey,
      totalScans: 0,
      usedCloudVision: 0,
      usedMLKit: 0,
      dailyLimit: 10, // Default to free tier, updated later
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'dateKey': dateKey,
      'totalScans': totalScans,
      'usedCloudVision': usedCloudVision,
      'usedMLKit': usedMLKit,
      'dailyLimit': dailyLimit,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
