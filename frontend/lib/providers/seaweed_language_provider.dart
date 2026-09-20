import 'package:flutter/material.dart';

enum SeaweedLanguage {
  english,
  filipino,
  bisaya,
}

extension SeaweedLanguageExtension on SeaweedLanguage {
  String get label {
    switch (this) {
      case SeaweedLanguage.english:
        return 'English';

      case SeaweedLanguage.filipino:
        return 'Filipino';

      case SeaweedLanguage.bisaya:
        return 'Bisaya';
    }
  }
}

class SeaweedLanguageProvider extends ChangeNotifier {
  SeaweedLanguage _language = SeaweedLanguage.english;

  SeaweedLanguage get language => _language;

  void setLanguage(SeaweedLanguage language) {
    if (_language == language) {
      return;
    }

    _language = language;

    notifyListeners();
  }
}