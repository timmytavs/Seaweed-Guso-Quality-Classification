import 'package:flutter/foundation.dart';

import '../models/classification_record.dart';

class ClassificationProvider extends ChangeNotifier {
  final List<ClassificationRecord> _records = [];

  ClassificationRecord? _selectedRecord;

  bool _isLoadingHistory = false;
  String? _historyError;

  bool _hasUnsavedResult = false;
  int _discardVersion = 0;

  List<ClassificationRecord> get records {
    return List.unmodifiable(_records);
  }

  ClassificationRecord? get selectedRecord => _selectedRecord;

  bool get isLoadingHistory => _isLoadingHistory;

  String? get historyError => _historyError;

  bool get hasUnsavedResult => _hasUnsavedResult;
  int get discardVersion => _discardVersion;

  void discardCurrentResult() {
    _hasUnsavedResult = false;
    _discardVersion++;
    notifyListeners();
  }

  void addRecord(ClassificationRecord record) {
    _records.insert(0, record);
    notifyListeners();
  }

  void removeRecord(int id) {
    _records.removeWhere(
      (record) => record.id == id,
    );

    if (_selectedRecord?.id == id) {
      _selectedRecord = null;
    }

    notifyListeners();
  }

  void clearHistory() {
    _records.clear();
    _selectedRecord = null;
    notifyListeners();
  }

  void selectRecord(ClassificationRecord? record) {
    _selectedRecord = record;
    notifyListeners();
  }

  void setUnsavedResult(bool value) {
    if (_hasUnsavedResult == value) return;

    _hasUnsavedResult = value;
    notifyListeners();
  }

  void startHistoryLoading() {
    _isLoadingHistory = true;
    _historyError = null;
    notifyListeners();
  }

  void finishHistoryLoading() {
    _isLoadingHistory = false;
    notifyListeners();
  }

  void setHistoryError(String message) {
    _isLoadingHistory = false;
    _historyError = message;
    notifyListeners();
  }

  void clearHistoryError() {
    _historyError = null;
    notifyListeners();
  }

  void retryHistory() {
    _historyError = null;
    _isLoadingHistory = true;
    notifyListeners();

    Future.delayed(
      const Duration(milliseconds: 500),
      () {
        _isLoadingHistory = false;
        notifyListeners();
      },
    );
  }
}