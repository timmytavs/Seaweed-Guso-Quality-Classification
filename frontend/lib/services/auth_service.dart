import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  const AuthService();

  static const String _baseUrl = 'http://127.0.0.1:8000';
  static const String _tokenStorageKey = 'guso_access_token';
  static final SharedPreferencesAsync _storage = SharedPreferencesAsync();

  static String? _accessToken;

  static String? get accessToken => _accessToken;

  static bool get hasAccessToken =>
      _accessToken != null && _accessToken!.isNotEmpty;

  static Map<String, String> get authorizationHeaders {
    if (!hasAccessToken) {
      throw StateError('No login session. Please log in.');
    }
    return {'Authorization': 'Bearer $_accessToken'};
  }

  // Restore the JWT after a Flutter Web browser refresh.
  static Future<bool> restoreSession() async {
    final storedToken = await _storage.getString(_tokenStorageKey);
    if (storedToken == null || storedToken.isEmpty) {
      _accessToken = null;
      return false;
    }
    _accessToken = storedToken;
    return true;
  }

  // Clear both the active token and the persisted copy.
  static Future<void> clearSession() async {
    _accessToken = null;
    await _storage.remove(_tokenStorageKey);
  }

  // A restored token must be checked by the backend, not just trusted
  // because it exists in the browser.
  Future<bool> validateSession() async {
    if (!hasAccessToken) return false;

    final response = await http.get(
      Uri.parse('$_baseUrl/history/me'),
      headers: authorizationHeaders,
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) return true;

    if (response.statusCode == 401) {
      await clearSession();
      return false;
    }

    throw Exception(
      'Unable to validate login (HTTP ${response.statusCode}).',
    );
  }

  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String contactNumber,
    required String password,
    required String confirmPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'email': email.trim().isEmpty ? null : email.trim(),
        'contact_num': contactNumber.trim(),
        'password': password,
        'confirm_password': confirmPassword,
      }),
    );

    final dynamic decoded = jsonDecode(response.body);
    if (response.statusCode == 201 && decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }

    throw Exception(_errorMessage(decoded, 'Registration failed.'));
  }

  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    await clearSession();

    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'identifier': identifier.trim(),
        'password': password,
      }),
    );

    final dynamic decoded = jsonDecode(response.body);
    if (response.statusCode == 200 && decoded is Map) {
      final result = Map<String, dynamic>.from(decoded);
      final token = result['access_token'];

      if (token is! String || token.isEmpty) {
        throw Exception('Login succeeded, but no JWT was returned.');
      }

      _accessToken = token;
      await _storage.setString(_tokenStorageKey, token);
      return result;
    }

    throw Exception(_errorMessage(decoded, 'Login failed.'));
  }

  Future<void> logout() => clearSession();

  static String _errorMessage(dynamic decoded, String fallback) {
    if (decoded is Map && decoded['detail'] is String) {
      return decoded['detail'] as String;
    }
    return fallback;
  }
}
