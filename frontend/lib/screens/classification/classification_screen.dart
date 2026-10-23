import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
import '../../services/auth_service.dart';

class ClassificationScreen extends StatefulWidget {
  const ClassificationScreen({super.key});

  @override
  State<ClassificationScreen> createState() => _ClassificationScreenState();
}

class _ClassificationScreenState extends State<ClassificationScreen> {
  final ClassificationService _classificationService =
      const ClassificationService();

  SelectedImage? _selectedImage;

  bool _isAnalyzing = false;
  bool _isSaved = false;
  bool _isSaving = false;
  ClassificationResult? _result;
  String? _errorMessage;

  bool get _hasImage => _selectedImage != null;
  bool get _hasResult => _result != null;

  void _handleImageChanged(SelectedImage? image) {
    if (_isSaving) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait until saving finishes.')),
      );
      return;
    }

    setState(() {
      _selectedImage = image;
      _result = null;
      _isSaved = false;
      _errorMessage = null;
    });

    context.read<ClassificationProvider>().clearSelectedRecord();
  }

  void _uploadNext() {
    if (_isSaving) return;

    final settings = context.read<SettingsProvider>();

    if (_hasResult && !_isSaved && settings.confirmBeforeDiscard) {
      _showUnsavedWarning();
      return;
    }

    _resetClassification();
  }

  // Mark the classified record as saved in PostgreSQL first.
  Future<void> _saveResult() async {
    if (_isSaving || _isSaved || _isAnalyzing) return;

    final image = _selectedImage;
    final result = _result;

    if (image == null || result == null) return;

    final classificationId = result.classificationId;
    if (classificationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This result has no database ID and cannot be saved.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse(
          'http://127.0.0.1:8000/classifications/$classificationId/save',
        ),
        headers: AuthService.authorizationHeaders,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 401) {
        throw Exception('Your session expired. Please log in again.');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        String detail = 'Server returned ${response.statusCode}';
        try {
          final error = jsonDecode(response.body);
          if (error is Map && error['detail'] != null) {
            detail = error['detail'].toString();
          }
        } catch (_) {
          // Keep the status-code message if the response is not JSON.
        }
        throw Exception(detail);
      }

      // Only show a successful save once FastAPI confirms it.
      final responseData = jsonDecode(response.body);
      if (responseData is! Map || responseData['is_saved'] != true) {
        throw const FormatException(
          'The server did not confirm that the record was saved.',
        );
      }

      if (!mounted) return;

      final record = ClassificationRecord(
        id: classificationId.toString(),
        fileName: image.fileName,
        imageBytes: image.bytes,
        result: result,
        createdAt: DateTime.now(),
      );

      context.read<ClassificationProvider>().addRecord(record);

      setState(() {
        // Do not mark a newly selected result as saved by mistake.
        if (identical(_result, result)) {
          _isSaved = true;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Classification saved to PostgreSQL successfully.'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      final message = error.toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('FormatException: ', '');

      setState(() {
        _errorMessage = 'Could not save classification: $message';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $message')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _resetClassification() {
    if (_isSaving) return;

    setState(() {
      _selectedImage = null;
      _result = null;
      _isSaved = false;
      _isAnalyzing = false;
      _errorMessage = null;
    });

    context.read<ClassificationProvider>().clearSelectedRecord();
  }

  Future<void> _showUnsavedWarning() async {
    final shouldContinue = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Unsaved Result',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: const Text(
            'This classification result has not been saved yet. '
            'Do you want to continue and upload another image?',
            style: TextStyle(color: AppColors.textSecondary),
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

    if (shouldContinue == true && !_isSaving) {
      _resetClassification();
    }
  }

  Future<void> _classifyImage() async {
    if (!_hasImage || _isAnalyzing || _isSaving) {
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
      final result = await _classificationService.classifyImage(image);

      if (!mounted) {
        return;
      }

      setState(() {
        _result = result;
      });
    } catch (e) {
      debugPrint('CLASSIFICATION ERROR: $e');

      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Classification failed: $e';
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
              borderRadius: BorderRadius.circular(AppRadius.large),
              border: Border.all(color: AppColors.borderPrimary, width: 1.5),
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
            isAnalyzing: _isAnalyzing || _isSaving,
          ),

          if (_hasResult) ...[
            const SizedBox(height: 24),

            ClassificationSummary(result: _result!),

            const SizedBox(height: 24),

            CharacteristicsPanel(result: _result!),

            const SizedBox(height: 24),

            if (_isSaving) ...[
              const Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Saving classification to PostgreSQL...'),
                ],
              ),
              const SizedBox(height: 12),
            ],

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
              onPressed: _hasImage && !_isAnalyzing && !_isSaving
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
                  : const Icon(Icons.auto_awesome_outlined),
              label: Text(_isAnalyzing ? 'ANALYZING...' : 'CLASSIFY'),
            ),
          ),
        ],
      ),
    );
  }
}
