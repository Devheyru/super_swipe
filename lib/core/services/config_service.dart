import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:super_swipe/core/config/pantry_constants.dart';

/// Service to manage remote configuration and app settings
/// Uses aggressive caching for cost optimization
class ConfigService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch pantry categories from 'app_config/pantry_categories'
  /// Falls back to local constants if offline or missing
  Future<List<PantryCategory>> getPantryCategories() async {
    try {
      // Use cache first if available (Cost optimization)
      final doc = await _firestore
          .collection('app_config')
          .doc('pantry_categories')
          .get(const GetOptions(source: Source.serverAndCache));

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['categories'] is List) {
          final List<dynamic> rawList = data['categories'];

          return rawList
              .map((e) => PantryCategory.fromMap(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      // debugPrint('⚠️ Failed to load config, using default: $e');
    }

    // Fallback to local constant
    return kPantryCategories;
  }
}
