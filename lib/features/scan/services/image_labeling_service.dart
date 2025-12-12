import 'package:flutter/foundation.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class ImageLabelingService {
  final ImageLabeler _imageLabeler;

  ImageLabelingService()
    : _imageLabeler = ImageLabeler(options: ImageLabelerOptions());

  Future<List<String>> processImage(InputImage inputImage) async {
    try {
      final labels = await _imageLabeler.processImage(inputImage);

      // Filter and map labels
      // We can filter by confidence here if needed
      return labels
          .where((label) => label.confidence > 0.5) // 50% confidence threshold
          .map((label) => label.label)
          .toList();
    } catch (e) {
      debugPrint('Error labeling image: $e');
      return [];
    }
  }

  void dispose() {
    _imageLabeler.close();
  }
}
