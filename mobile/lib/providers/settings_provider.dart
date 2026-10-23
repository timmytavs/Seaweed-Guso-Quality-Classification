import 'package:flutter/foundation.dart';

class SettingsProvider extends ChangeNotifier {
  bool _showConfidence = true;
  bool _showImageQuality = true;
  bool _confirmBeforeDiscard = true;

  bool get showConfidence => _showConfidence;
  bool get showImageQuality => _showImageQuality;
  bool get confirmBeforeDiscard => _confirmBeforeDiscard;

  void setShowConfidence(bool value) {
    if (_showConfidence == value) return;

    _showConfidence = value;
    notifyListeners();
  }

  void setShowImageQuality(bool value) {
    if (_showImageQuality == value) return;

    _showImageQuality = value;
    notifyListeners();
  }

  void setConfirmBeforeDiscard(bool value) {
    if (_confirmBeforeDiscard == value) return;

    _confirmBeforeDiscard = value;
    notifyListeners();
  }

  void resetToDefaults() {
    _showConfidence = true;
    _showImageQuality = true;
    _confirmBeforeDiscard = true;

    notifyListeners();
  }
}