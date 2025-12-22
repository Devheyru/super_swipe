import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:super_swipe/core/models/daily_quota_summary.dart';
import 'package:super_swipe/core/providers/user_data_providers.dart';
import 'package:super_swipe/core/services/hybrid_vision_service.dart';
import 'package:super_swipe/core/theme/app_theme.dart';
import 'package:super_swipe/features/auth/providers/auth_provider.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  final HybridVisionService _visionService = HybridVisionService();

  bool _isProcessing = false;
  bool _isInitialized = false;
  int _selectedMode = 0; // 0: Fridge, 1: Pantry
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    await _visionService.init();
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (!_isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service initializing, please wait...')),
      );
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

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
    final user = ref.read(authProvider).user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to use scan feature')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Analyzing with Cloud Vision AI...';
    });

    try {
      // Use Cloud Vision service
      final result = await _visionService.detectFoodItems(
        imagePath: image.path,
        userId: user.uid,
      );

      // Note: Quota status in UI updates automatically via StreamProvider

      if (mounted) {
        // Check if quota was exhausted during this scan attempt
        if (result.quotaExhausted) {
          setState(() {
            _statusMessage = null;
          });

          // Show quota exhausted dialog
          final shouldAddManually = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Scan Limit Reached'),
              content: const Text(
                'You\'ve used all your AI scans for today.\n\n'
                'Would you like to add items manually instead?\n\n'
                'Your scan quota resets daily.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: const Text('Add Manually'),
                ),
              ],
            ),
          );

          if (shouldAddManually == true && mounted) {
            context.goNamed(
              'scanResults',
              extra: {
                'labels': <String>[],
                'aiSource': result.aiSource,
                // 'quotaStatus': result.quotaStatus, // Optional, UI uses stream now
              },
            );
          }
          return;
        }

        if (result.items.isEmpty) {
          setState(() {
            _statusMessage = null;
          });

          // Show dialog with option to add manually
          final shouldAddManually = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('No Food Detected'),
              content: const Text(
                'Could not detect any food items in this image.\n\n'
                'Would you like to add items manually?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: const Text('Add Manually'),
                ),
              ],
            ),
          );

          if (shouldAddManually == true && mounted) {
            context.goNamed(
              'scanResults',
              extra: {'labels': <String>[], 'aiSource': result.aiSource},
            );
          }
        } else {
          // Convert results to string list for navigation
          final labels = result.items
              .map((item) => item.toDisplayString())
              .toList();

          context.goNamed(
            'scanResults',
            extra: {
              'labels': labels,
              'aiSource': result.aiSource,
              // 'quotaStatus': result.quotaStatus, // Pass if needed by next screen
            },
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch real-time quota
    final dailyQuotaAsync = ref.watch(dailyQuotaSummaryProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: const Text('Scan Ingredients'),
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
          ? _buildProcessingView()
          : Column(
              children: [
                // Quota Status Banner (Real-time)
                dailyQuotaAsync.when(
                  data: (summary) => _buildQuotaStatusBanner(summary),
                  loading: () => const SizedBox.shrink(), // Or skeleton
                  error: (_, __) => const SizedBox.shrink(),
                ),

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
                                const SizedBox(height: AppTheme.spacingS),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.auto_awesome,
                                        size: 14,
                                        color: AppTheme.primaryColor,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'AI Powered',
                                        style: TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
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
                        'Take a photo to detect ingredients',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Gallery
                          _buildCircleButton(
                            icon: Icons.photo_library_outlined,
                            label: 'Gallery',
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
                            label: 'Manual',
                            onTap: () {
                              context.goNamed(
                                'scanResults',
                                extra: {'labels': <String>[]},
                              );
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

  Widget _buildQuotaStatusBanner(DailyQuotaSummary summary) {
    // Logic adapted for DailyQuotaSummary
    // Assuming CloudVision usage is mapped to the cost or limit.
    // The previous logic compared dailyUsage vs dailyLimit.
    // dailySummary.usedCloudVision or dailySummary.totalScans?
    // Limits usually apply to AI usage (Cloud Vision or similar).
    // Let's use totalScans or relevant metric.
    // If strict on Cloud Vision cost, track usedCloudVision.
    // Assuming limit is total scans for now based on QuotaService logic.
    final usage = summary.usedCloudVision; // Or summary.totalScans
    final limit = summary.dailyLimit;

    final isLimitReached = usage >= limit;
    final scansRemaining = limit - usage;

    // Always show the quota status for AI scans
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppTheme.spacingL,
        AppTheme.spacingM,
        AppTheme.spacingL,
        0,
      ),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: isLimitReached ? Colors.orange.shade100 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: isLimitReached ? Colors.orange.shade300 : Colors.blue.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isLimitReached ? Icons.warning_amber_rounded : Icons.auto_awesome,
            color: isLimitReached
                ? Colors.orange.shade700
                : Colors.blue.shade700,
            size: 20,
          ),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLimitReached
                      ? 'Daily Scan Limit Reached'
                      : 'AI Scans: ${scansRemaining > 0 ? scansRemaining : 0} remaining today',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isLimitReached
                        ? Colors.orange.shade700
                        : Colors.blue.shade700,
                  ),
                ),
                Text(
                  isLimitReached
                      ? 'Use manual entry below or wait for daily reset'
                      : '',
                  style: TextStyle(
                    fontSize: 11,
                    color: isLimitReached
                        ? Colors.orange.shade600
                        : Colors.blue.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          Text(
            _statusMessage ?? 'Processing...',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('☁️', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                'Cloud Vision AI detecting food items',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.textLight),
              ),
            ],
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
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
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
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ],
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
