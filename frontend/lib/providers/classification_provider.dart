import 'package:flutter/material.dart';

import '../models/classification_record.dart';
import '../services/auth_service.dart';
import '../services/history_service.dart';

class ClassificationProvider extends ChangeNotifier {
  final HistoryService _historyService = const HistoryService();

  // Prevent duplicate requests for the same classification.
  final Set<int> _deletingClassificationIds = <int>{};

  // Full records with images/results available during this Flutter session.
  final List<ClassificationRecord> _records = [];

  // Saved summaries returned by the authenticated PostgreSQL History API.
  final List<SavedClassificationSummary> _savedSummaries = [];

  ClassificationRecord? _selectedRecord;
  bool _isLoadingHistory = false;
  String? _historyError;

  // Detect account/session changes and ignore outdated HTTP responses.
  String? _sessionToken;
  int _historyRequestVersion = 0;

  List<ClassificationRecord> get records => List.unmodifiable(
    _isCurrentSession ? _records : <ClassificationRecord>[],
  );

  ClassificationRecord? get selectedRecord =>
      _isCurrentSession ? _selectedRecord : null;

  bool get hasRecords => records.isNotEmpty;

  List<SavedClassificationSummary> get savedSummaries => List.unmodifiable(
    _isCurrentSession ? _savedSummaries : <SavedClassificationSummary>[],
  );

  bool get hasSavedHistory => hasRecords || savedSummaries.isNotEmpty;

  bool get isLoadingHistory => _isCurrentSession && _isLoadingHistory;

  bool isDeletingClassification(int classificationId) =>
      _isCurrentSession &&
      _deletingClassificationIds.contains(classificationId);

  String? get historyError => _isCurrentSession ? _historyError : null;

  bool get _isCurrentSession => _sessionToken == AuthService.accessToken;

  // Clear local records when another login session takes over.
  // No PostgreSQL records are deleted here.
  void _syncSession() {
    final token = AuthService.accessToken;
    if (_sessionToken == token) return;

    _sessionToken = token;
    _historyRequestVersion++;
    _records.clear();
    _savedSummaries.clear();
    _deletingClassificationIds.clear();
    _selectedRecord = null;
    _isLoadingHistory = false;
    _historyError = null;
  }

  // Called by the History screen after login or when the user refreshes History.
  Future<void> loadSavedHistory() async {
    _syncSession();

    final token = AuthService.accessToken;
    if (token == null || token.isEmpty) {
      _historyError = 'Please log in to view saved history.';
      _isLoadingHistory = false;
      notifyListeners();
      return;
    }

    final requestVersion = ++_historyRequestVersion;
    _isLoadingHistory = true;
    _historyError = null;
    notifyListeners();

    try {
      final response = await _historyService.fetchSavedHistory();
      if (!_isCurrentRequest(requestVersion, token)) return;

      final summaries = response
          .map((json) => SavedClassificationSummary.fromJson(json))
          .toList(growable: false);

      _savedSummaries
        ..clear()
        ..addAll(summaries);
    } catch (error) {
      if (!_isCurrentRequest(requestVersion, token)) return;
      _historyError = error.toString().replaceFirst('Exception: ', '');
    } finally {
      if (_isCurrentRequest(requestVersion, token)) {
        _isLoadingHistory = false;
        notifyListeners();
      }
    }
  }

  bool _isCurrentRequest(int version, String token) =>
      version == _historyRequestVersion &&
      _sessionToken == token &&
      AuthService.accessToken == token;

  // Existing full-record operations are retained for the current session.
  void addRecord(ClassificationRecord record) {
    _syncSession();
    _records.removeWhere((item) => item.id == record.id);
    _records.insert(0, record);
    _selectedRecord = record;
    notifyListeners();
  }

  void selectRecord(ClassificationRecord record) {
    _syncSession();
    if (!_records.any((item) => item.id == record.id)) return;
    _selectedRecord = record;
    notifyListeners();
  }

  void clearSelectedRecord() {
    _syncSession();
    _selectedRecord = null;
    notifyListeners();
  }

  // Permanently delete an owned, saved classification through FastAPI.
  // The local lists change only AFTER the server confirms deletion.
  Future<void> deleteSavedClassification(int classificationId) async {
    _syncSession();

    if (classificationId <= 0) {
      throw ArgumentError.value(
        classificationId,
        'classificationId',
        'Must be a positive database classification ID.',
      );
    }

    final token = AuthService.accessToken;
    if (token == null || token.isEmpty) {
      throw StateError('Please log in to delete a saved classification.');
    }

    if (_deletingClassificationIds.contains(classificationId)) {
      throw StateError('This classification is already being deleted.');
    }

    _deletingClassificationIds.add(classificationId);
    notifyListeners();

    try {
      await _historyService.deleteSavedClassification(classificationId);

      // A previous account's response must never change the new account's UI.
      if (_sessionToken != token || AuthService.accessToken != token) {
        return;
      }

      // Discard any History GET started before this confirmed deletion.
      // Otherwise a delayed response could bring the deleted record back.
      _historyRequestVersion++;
      _isLoadingHistory = false;

      final deletedId = classificationId.toString();
      _records.removeWhere((record) => record.id == deletedId);
      _savedSummaries.removeWhere((summary) => summary.id == classificationId);

      if (_selectedRecord?.id == deletedId) {
        _selectedRecord = _records.isNotEmpty ? _records.first : null;
      }

      _historyError = null;
    } finally {
      // On failure, leave all records untouched and let the UI show the error.
      if (_sessionToken == token && AuthService.accessToken == token) {
        _deletingClassificationIds.remove(classificationId);
        notifyListeners();
      }
    }
  }

  // Local-only removal (does not delete a record or image from PostgreSQL).
  // Use deleteSavedClassification() for the permanent user-facing action.
  void removeRecord(String recordId) {
    _syncSession();
    final wasSelected = _selectedRecord?.id == recordId;
    _records.removeWhere((record) => record.id == recordId);

    if (wasSelected) {
      _selectedRecord = _records.isNotEmpty ? _records.first : null;
    }

    notifyListeners();
  }

  // Clear in-memory state when logging out or changing accounts.
  // This does NOT erase saved records in PostgreSQL.
  void clearHistory() {
    _syncSession();
    _historyRequestVersion++;
    _records.clear();
    _savedSummaries.clear();
    _deletingClassificationIds.clear();
    _selectedRecord = null;
    _isLoadingHistory = false;
    _historyError = null;
    notifyListeners();
  }
}
