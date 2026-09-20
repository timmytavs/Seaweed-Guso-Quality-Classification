
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../widgets/classification/image_upload_area.dart';

import '../../models/classification_result.dart';
import '../../widgets/classification/classification_summary.dart';
import '../../widgets/classification/characteristics_panel.dart';
import '../../widgets/classification/result_actions.dart';
import '../../models/selected_image.dart';

import 'package:provider/provider.dart';

import '../../models/classification_record.dart';
import '../../providers/classification_provider.dart';

import '../../providers/settings_provider.dart';
import '../../widgets/common/error_message.dart';
import '../../services/classification_service.dart';

class ClassificationScreen extends StatefulWidget {
  const ClassificationScreen({super.key});

  @override
  State<ClassificationScreen> createState() =>
      _ClassificationScreenState();
}

class _ClassificationScreenState
    extends State<ClassificationScreen> {
  
  final ClassificationService _classificationService =
    const ClassificationService();

  SelectedImage? _selectedImage;

  bool _isAnalyzing = false;
  bool _isSaved = false;
  ClassificationResult? _result;
  String? _errorMessage;

  bool get _hasImage => _selectedImage != null;
  bool get _hasResult => _result != null;

  void _handleImageChanged(SelectedImage? image) {
    setState(() {
      _selectedImage = image;
      _result = null;
      _isSaved = false;
      _errorMessage = null;
    });

    context
        .read<ClassificationProvider>()
        .clearSelectedRecord();
  }

  void _uploadNext() {
    final settings = context.read<SettingsProvider>();

    if (
        _hasResult &&
        !_isSaved &&
        settings.confirmBeforeDiscard
    ) {
      _showUnsavedWarning();
      return;
    }

    _resetClassification();
  }

  void _saveResult() {
    if (!_hasResult || _isSaved || _selectedImage == null) {
      return;
    }

    final record = ClassificationRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      fileName: _selectedImage!.fileName,
      imageBytes: _selectedImage!.bytes,
      result: _result!,
      createdAt: DateTime.now(),
    );

    context.read<ClassificationProvider>().addRecord(record);

    setState(() {
      _isSaved = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Classification record saved successfully.',
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _resetClassification() {
    setState(() {
      _selectedImage = null;
      _result = null;
      _isSaved = false;
      _isAnalyzing = false;
      _errorMessage = null;
    });

    context
        .read<ClassificationProvider>()
        .clearSelectedRecord();
  }

  Future<void> _showUnsavedWarning() async {
    final shouldContinue = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Unsaved Result',
            style: TextStyle(
              color: AppColors.textPrimary,
            ),
          ),
          content: const Text(
            'This classification result has not been saved yet. '
            'Do you want to continue and upload another image?',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('CONTINUE'),
            ),
          ],
        );
      },
    );

    if (shouldContinue == true) {
      _resetClassification();
    }
  }

  Future<void> _classifyImage() async {
    if (!_hasImage || _isAnalyzing) {
      return;
    }

    final image = _selectedImage;

    if (image == null) {
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _result = null;
      _errorMessage = null;
    });

    try {
      final result =
          await _classificationService.classifyImage(
        image,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _result = result;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            'Unable to classify this image. '
            'Please try again or upload a clearer image.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius:
                  BorderRadius.circular(AppRadius.large),
              border: Border.all(
                color: AppColors.borderPrimary,
                width: 1.5,
              ),
            ),
            
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.image_search_outlined,
                  color: AppColors.primary,
                  size: 32,
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Classify Guso Quality',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        _isAnalyzing
                            ? 'Analyzing the uploaded Guso image. '
                                'Please wait while the system processes the image.'
                            : _hasResult
                                ? 'Classification completed successfully. '
                                    'Review the classification result and observed characteristics below.'
                                : _hasImage
                                    ? 'Image ready for classification. '
                                        'Review the selected image, then press Classify.'
                                    : 'Upload a clear image of Guso seaweed to begin classification. '
                                        'For better results, use an image with good lighting '
                                        'and minimal background obstruction.',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 16),

            ErrorMessage(
              message: _errorMessage!,
              onDismiss: () {
                setState(() {
                  _errorMessage = null;
                });
              },
            ),
          ],

          const SizedBox(height: 24),

          ImageUploadArea(
            onImageChanged: _handleImageChanged,
            isAnalyzing: _isAnalyzing,
          ),
          
          if (_hasResult) ...[
            const SizedBox(height: 24),

            ClassificationSummary(
              result: _result!,
            ),

            const SizedBox(height: 24),

            CharacteristicsPanel(
              result: _result!,
            ),

            const SizedBox(height: 24),

            ResultActions(
              onUploadNext: _uploadNext,
              onSave: _saveResult,
              isSaved: _isSaved,
            ),
          ],

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  _hasImage && !_isAnalyzing
                      ? _classifyImage
                      : null,
              icon: _isAnalyzing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(
                      Icons.auto_awesome_outlined,
                    ),
              label: Text(
                _isAnalyzing
                    ? 'ANALYZING...'
                    : 'CLASSIFY',
              ),
            ),
          ),
        ],
      ),
    );
  }
}