import 'dart:io';
import 'package:provider/provider.dart';
import '../../models/classification_record.dart';
import '../../providers/classification_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../app/theme.dart';
import '../../models/classification_result.dart';
import '../../services/classification_service.dart';
import '../../providers/settings_provider.dart';

import '../../data/seaweed_data.dart';
import '../../models/seaweed_info.dart';

class ClassificationScreen extends StatefulWidget {
  const ClassificationScreen({super.key});

  @override
  State<ClassificationScreen> createState() => _ClassificationScreenState();
}

class _ClassificationScreenState extends State<ClassificationScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final ClassificationService _classificationService =
      const ClassificationService();
  XFile? _selectedImage;
  ClassificationResult? _result;
  bool _isPickingImage = false;
  bool _isClassifying = false;
  bool _isSaving = false;
  bool _isSaved = false;
  int? _lastDiscardVersion;
  String? _classificationError;

  Future<void> _pickImage(ImageSource source) async {
    if (_isPickingImage || _isClassifying || _isSaving) {
      return;
    }
    setState(() {
      _isPickingImage = true;
    });
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 90,
      );
      if (!mounted) return;
      if (image != null) {
        setState(() {
          _selectedImage = image;
          _result = null;
          _classificationError = null;
          _isSaved = false;
        });
        context
            .read<ClassificationProvider>()
            .setUnsavedResult(false);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to select image: $error',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  Future<void> _classifyImage() async {
    final image = _selectedImage;
    if (image == null || _isClassifying) return;
    setState(() {
      _isClassifying = true;
      _classificationError = null;
      _result = null;
      _isSaved = false;
    });
    try {
      final result = await _classificationService.classifyImage(image);
      if (!mounted) return;
      setState(() {
        _result = result;
      });
      context.read<ClassificationProvider>().setUnsavedResult(true);
    } on ClassificationServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        _classificationError = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _classificationError =
            'An unexpected error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isClassifying = false;
        });
      }
    }
  }

  Future<void> _saveResult() async {
    final result = _result;
    final image = _selectedImage;
    if (result == null ||
        image == null ||
        _isSaving ||
        _isSaved) {
      return;
    }
    setState(() {
      _isSaving = true;
    });
    await Future.delayed(
      const Duration(milliseconds: 500),
    );
    if (!mounted) return;
    final record = ClassificationRecord(
      id: DateTime.now().millisecondsSinceEpoch,
      imagePath: image.path,
      result: result,
      createdAt: DateTime.now(),
    );
    context.read<ClassificationProvider>().addRecord(record);
    context.read<ClassificationProvider>().setUnsavedResult(false);
    setState(() {
      _isSaving = false;
      _isSaved = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Classification saved to history.',
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _uploadNext() {
    if (_isClassifying || _isSaving) return;
    setState(() {
      _selectedImage = null;
      _result = null;
      _classificationError = null;
      _isSaved = false;
    });
    context.read<ClassificationProvider>().setUnsavedResult(false);
  }

  void _removeSelectedImage() {
    if (_isClassifying || _isSaving) return;
    setState(() {
      _selectedImage = null;
      _result = null;
      _classificationError = null;
      _isSaved = false;
    });
    context.read<ClassificationProvider>().setUnsavedResult(false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.watch<ClassificationProvider>();
    final currentDiscardVersion = provider.discardVersion;
    if (_lastDiscardVersion == null) {
      _lastDiscardVersion = currentDiscardVersion;
      return;
    }
    if (currentDiscardVersion != _lastDiscardVersion) {
      _lastDiscardVersion = currentDiscardVersion;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _selectedImage = null;
          _result = null;
          _classificationError = null;
          _isSaved = false;
          _isClassifying = false;
          _isSaving = false;
          _isPickingImage = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: AppSpacing.xl),
              if (_selectedImage == null)
                _buildUploadCard(context)
              else
                _buildSelectedImageCard(context),
              if (_classificationError != null) ...[
                const SizedBox(height: AppSpacing.lg),
                _buildErrorCard(context),
              ],
              if (_result != null) ...[
                _buildResultCard(
                  context,
                  showConfidence: settingsProvider.showConfidence,
                  showImageQuality: settingsProvider.showImageQuality,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              _buildInstructionCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(
              color: AppColors.primary,
            ),
          ),
          child: const Icon(
            Icons.image_search_outlined,
            color: AppColors.primary,
            size: 25,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Classify Seaweed',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Capture or upload a seaweed image for species classification.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUploadCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 36,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(
          color: AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary,
              ),
            ),
            child: const Icon(
              Icons.add_photo_alternate_outlined,
              color: AppColors.primary,
              size: 34,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Upload Seaweed Image',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Choose an image from your gallery or capture a new photo using your camera.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isPickingImage
                  ? null
                  : () => _pickImage(ImageSource.camera),
              icon: _isPickingImage
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.camera_alt_outlined,
                    ),
              label: const Text('Take Photo'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isPickingImage
                  ? null
                  : () => _pickImage(ImageSource.gallery),
              icon: const Icon(
                Icons.photo_library_outlined,
              ),
              label: const Text(
                'Choose from Gallery',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedImageCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(
          color: AppColors.primary,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Image.file(
                    File(_selectedImage!.path),
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (
                      context,
                      error,
                      stackTrace,
                    ) {
                      return Container(
                        color: AppColors.surfaceDark,
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.broken_image_outlined,
                                color: AppColors.error,
                                size: 44,
                              ),
                              SizedBox(
                                height: AppSpacing.sm,
                              ),
                              Text(
                                'Unable to display image',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                if (!_isClassifying)
                Positioned(
                  top: AppSpacing.sm,
                  left: AppSpacing.sm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark.withValues(
                        alpha: 0.90,
                      ),
                      borderRadius: BorderRadius.circular(
                        AppRadius.large,
                      ),
                      border: Border.all(
                        color: AppColors.borderLight,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _result != null
                              ? Icons.check_circle_outline
                              : Icons.image_outlined,
                          color: _result != null
                              ? AppColors.success
                              : AppColors.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _result != null
                              ? 'Analysis Complete'
                              : 'Ready for Classification',
                          style: TextStyle(
                            color: _result != null
                                ? AppColors.success
                                : AppColors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (_isClassifying)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(
                        alpha: 0.66,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.lg,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark.withValues(
                            alpha: 0.78,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppRadius.large,
                          ),
                          border: Border.all(
                            color: AppColors.borderLight,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 36,
                              height: 36,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: AppColors.primary,
                              ),
                            ),

                            const SizedBox(height: AppSpacing.md),

                            Text(
                              'ANALYZING...',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.1,
                                  ),
                            ),

                            const SizedBox(height: AppSpacing.sm),

                            Text(
                              'Processing the uploaded image',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(
                _result != null
                    ? Icons.check_circle_outline
                    : Icons.image_outlined,
                color: _result != null
                    ? AppColors.success
                    : AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                   _result != null
                    ? 'Analysis complete'
                    : 'Ready for classification',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _isPickingImage || _isClassifying || _isSaving
                          ? null
                          : () => _pickImage(ImageSource.gallery),
                  icon: const Icon(
                    Icons.swap_horiz_outlined,
                  ),
                  label: const Text(
                    'Change Image',
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _isClassifying || _isSaving
                          ? null
                          : _removeSelectedImage,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                  ),
                  label: const Text(
                    'Remove',
                    style: TextStyle(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (_result == null) ...[
            const SizedBox(height: AppSpacing.md),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    _isClassifying || _isSaving
                        ? null
                        : _classifyImage,
                icon: _isClassifying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.auto_awesome_outlined,
                      ),
                label: Text(
                  _isClassifying
                      ? 'Analyzing...'
                      : 'Classify Seaweed',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultCard(
    BuildContext context, {
    required bool showConfidence,
    required bool showImageQuality,
  }) {
    final result = _result!;
    final SeaweedInfo? seaweed =
      SeaweedData.findByClassificationLabel(result.species);

    return
    Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(
          color: AppColors.primary,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(
                    AppRadius.medium,
                  ),
                  border: Border.all(
                    color: AppColors.primary,
                  ),
                ),
                child: const Icon(
                  Icons.fact_check_outlined,
                  color: AppColors.primary,
                  size: 23,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Classification Result',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Seaweed image analysis completed',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(
                    AppRadius.large,
                  ),
                  border: Border.all(
                    color: AppColors.primary,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: AppColors.primary,
                      size: 15,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Complete',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        const SizedBox(height: AppSpacing.lg),
        const Divider(
          color: AppColors.borderLight,
          height: 1,
        ),
        const SizedBox(height: AppSpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(
                AppRadius.medium,
              ),
              border: Border.all(
                color: AppColors.borderLight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detected Species',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  result.species,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),

          

          const SizedBox(height: AppSpacing.md),

          if (result.hasQualityGrade || result.hasFreshness) ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final useSingleColumn = constraints.maxWidth < 300;

                final qualityCard = _buildResultMetricCard(
                  context,
                  icon: Icons.workspace_premium_outlined,
                  label: 'Quality Grade',
                  value: result.qualityGrade ?? 'Not Available',
                );

                final freshnessCard = _buildResultMetricCard(
                  context,
                  icon: Icons.eco_outlined,
                  label: 'Freshness',
                  value: result.freshness ?? 'Not Available',
                );

                if (useSingleColumn) {
                  return Column(
                    children: [
                      qualityCard,
                      const SizedBox(height: AppSpacing.sm),
                      freshnessCard,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: qualityCard),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: freshnessCard),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          if (showConfidence ||
              (showImageQuality && result.hasImageQuality))
            LayoutBuilder(
              builder: (context, constraints) {
                final useSingleColumn = constraints.maxWidth < 300;

                final confidenceCard = showConfidence
                    ? _buildResultMetricCard(
                        context,
                        icon: Icons.analytics_outlined,
                        label: 'Confidence',
                        value: result.formattedConfidence,
                      )
                    : null;

                final imageQualityCard =
                    showImageQuality && result.hasImageQuality
                        ? _buildResultMetricCard(
                            context,
                            icon: Icons.image_outlined,
                            label: 'Image Quality',
                            value: result.imageQuality!,
                          )
                        : null;

                if (useSingleColumn) {
                  return Column(
                    children: [
                      ?confidenceCard,

                      if (confidenceCard != null &&
                          imageQualityCard != null)
                        const SizedBox(height: AppSpacing.sm),

                      ?imageQualityCard,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (confidenceCard != null)
                      Expanded(child: confidenceCard),

                    if (confidenceCard != null &&
                        imageQualityCard != null)
                      const SizedBox(width: AppSpacing.sm),

                    if (imageQualityCard != null)
                      Expanded(child: imageQualityCard),
                  ],
                );
              },
            ),

            if (seaweed != null) ...[
              const SizedBox(height: AppSpacing.md),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(
                    AppRadius.medium,
                  ),
                  border: Border.all(
                    color: AppColors.borderLight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seaweed Information',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    Text(
                      'Common Name',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      seaweed.englishName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    Text(
                      'Local Name',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      seaweed.bisayaName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    Text(
                      'Scientific Name',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      seaweed.scientificName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (result.hasSummary) ...[
              const SizedBox(height: AppSpacing.md),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(
                    AppRadius.medium,
                  ),
                  border: Border.all(
                    color: AppColors.borderLight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.description_outlined,
                          color: AppColors.primary,
                          size: 21,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Summary',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),

                    Text(
                      result.summary!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                    ),
                  ],
                ),
              ),
            ],

            if (result.hasObservedCharacteristics) ...[
              const SizedBox(height: AppSpacing.md),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(
                    AppRadius.medium,
                  ),
                  border: Border.all(
                    color: AppColors.borderLight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.visibility_outlined,
                          color: AppColors.primary,
                          size: 21,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Observed Characteristics',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),

                    if (result.hasColor) ...[
                      const SizedBox(height: AppSpacing.md),
                      _buildCharacteristicCard(
                        context,
                        icon: Icons.palette_outlined,
                        label: 'Color',
                        value: result.color!,
                      ),
                    ],

                    if (result.hasVisualTexture) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _buildCharacteristicCard(
                        context,
                        icon: Icons.texture_outlined,
                        label: 'Visual Texture',
                        value: result.visualTexture!,
                      ),
                    ],

                    if (result.hasSurfaceCondition) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _buildCharacteristicCard(
                        context,
                        icon: Icons.layers_outlined,
                        label: 'Surface Condition',
                        value: result.surfaceCondition!,
                      ),
                    ],

                    if (result.hasVisibleDefects) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _buildCharacteristicCard(
                        context,
                        icon: Icons.report_problem_outlined,
                        label: 'Visible Defects',
                        value: result.visibleDefects!,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          
          const SizedBox(height: AppSpacing.xl),
          const Divider(
            color: AppColors.borderLight,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSaving
                      ? null
                      : _uploadNext,
                  icon: const Icon(
                    Icons.add_photo_alternate_outlined,
                  ),
                  label: const Text(
                    'Upload Next',
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSaving || _isSaved
                      ? null
                      : _saveResult,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          _isSaved
                              ? Icons.check_outlined
                              : Icons.bookmark_add_outlined,
                        ),
                  label: Text(
                    _isSaving
                        ? 'Saving...'
                        : _isSaved
                            ? 'Saved'
                            : 'Save',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultMetricCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 118,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(
          AppRadius.medium,
        ),
        border: Border.all(
          color: AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 22,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacteristicCard(
  BuildContext context, {
  required IconData icon,
  required String label,
  required String value,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(
        AppRadius.medium,
      ),
      border: Border.all(
        color: AppColors.borderLight,
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: BorderRadius.circular(
              AppRadius.medium,
            ),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 19,
          ),
        ),

        const SizedBox(width: AppSpacing.md),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildErrorCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(
          color: AppColors.error,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.error,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _classificationError!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(
          color: AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: AppColors.primary,
                size: 21,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'For better results',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildTip(
            context,
            'Make sure the seaweed is clearly visible.',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildTip(
            context,
            'Use good lighting and avoid heavy shadows.',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildTip(
            context,
            'Keep the image focused and avoid excessive blur.',
          ),
        ],
      ),
    );
  }

  Widget _buildTip(
    BuildContext context,
    String text,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 5),
          child: Icon(
            Icons.circle,
            color: AppColors.primary,
            size: 6,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),
        ),
      ],
    );
  }
}
