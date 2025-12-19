import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:image_picker/image_picker.dart';
import 'package:super_swipe/core/theme/app_theme.dart';
import 'package:super_swipe/features/auth/providers/auth_provider.dart';
import 'package:super_swipe/features/scan/services/image_labeling_service.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  final ImageLabelingService _labelingService = ImageLabelingService();
  bool _isProcessing = false;
  int _selectedMode = 0; // 0: Fridge, 1: Pantry

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    final authUser = ref.read(currentUserProvider);
    if (authUser != null && !authUser.isAnonymous) {
      await _labelingService.init(userId: authUser.uid);
    } else {
      await _labelingService.init();
    }
  }

  @override
  void dispose() {
    _labelingService.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        await _processImage(image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<void> _processImage(XFile image) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final inputImage = InputImage.fromFilePath(image.path);
      final labels = await _labelingService.processImage(inputImage);

      if (mounted) {
        if (labels.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No ingredients detected. Try again.'),
            ),
          );
        } else {
          // Get quota status and vision source for UI feedback
          final quotaStatus = await _labelingService.getQuotaStatus();
          final visionSource = _labelingService.lastUsedSource;

          // Navigate to results with metadata
          context.goNamed(
            'scanResults',
            extra: {
              'labels': labels,
              'quotaStatus': quotaStatus,
              'visionSource': visionSource,
            },
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error processing image: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: const Text('Add Ingredients'),
        backgroundColor: AppTheme.surfaceColor,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.history_rounded),
            tooltip: 'History',
          ),
        ],
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: AppTheme.spacingM),

                // 1. Mode Selector (Fridge vs Pantry)
                _buildModeSelector(),

                const SizedBox(height: AppTheme.spacingL),

                // 2. Camera Viewfinder (Clickable)
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickImage(ImageSource.camera),
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingL,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: AppTheme.borderRadiusXLarge,
                        boxShadow: AppTheme.mediumShadow,
                      ),
                      child: Stack(
                        children: [
                          // Camera Preview Placeholder
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _selectedMode == 0
                                      ? Icons.kitchen
                                      : Icons.shelves,
                                  size: 64,
                                  color: Colors.white24,
                                ),
                                const SizedBox(height: AppTheme.spacingM),
                                Text(
                                  _selectedMode == 0
                                      ? 'Tap to scan fridge 🥬'
                                      : 'Tap to scan pantry 🥫',
                                  style: const TextStyle(color: Colors.white54),
                                ),
                              ],
                            ),
                          ),

                          // Scanning Corners Overlay
                          _buildScannerOverlay(),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppTheme.spacingL),

                // 3. Scan Controls
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  decoration: const BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(AppTheme.radiusXLarge),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'AI Object Detection Active ✨',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Gallery
                          _buildCircleButton(
                            icon: Icons.photo_library_outlined,
                            onTap: () => _pickImage(ImageSource.gallery),
                            color: AppTheme.textSecondary,
                          ),

                          // Shutter
                          GestureDetector(
                            onTap: () => _pickImage(ImageSource.camera),
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primaryColor,
                                border: Border.all(
                                  color: AppTheme.surfaceColor,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),

                          // Manual Entry
                          _buildCircleButton(
                            icon: Icons.edit_note_rounded,
                            onTap: () {
                              // TODO: Implement manual entry
                            },
                            color: AppTheme.textSecondary,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingL),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXL),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.secondaryLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: [_buildModeTab('Fridge', 0), _buildModeTab('Pantry', 1)],
      ),
    );
  }

  Widget _buildModeTab(String text, int index) {
    final isSelected = _selectedMode == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMode = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.surfaceColor : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.backgroundColor,
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Stack(
      children: [
        // Corners
        _buildCorner(top: 20, left: 20),
        _buildCorner(top: 20, right: 20),
        _buildCorner(bottom: 20, left: 20),
        _buildCorner(bottom: 20, right: 20),
      ],
    );
  }

  Widget _buildCorner({
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border(
            top: top != null
                ? const BorderSide(color: Colors.white, width: 3)
                : BorderSide.none,
            bottom: bottom != null
                ? const BorderSide(color: Colors.white, width: 3)
                : BorderSide.none,
            left: left != null
                ? const BorderSide(color: Colors.white, width: 3)
                : BorderSide.none,
            right: right != null
                ? const BorderSide(color: Colors.white, width: 3)
                : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: top != null && left != null
                ? const Radius.circular(8)
                : Radius.zero,
            topRight: top != null && right != null
                ? const Radius.circular(8)
                : Radius.zero,
            bottomLeft: bottom != null && left != null
                ? const Radius.circular(8)
                : Radius.zero,
            bottomRight: bottom != null && right != null
                ? const Radius.circular(8)
                : Radius.zero,
          ),
        ),
      ),
    );
  }
}
