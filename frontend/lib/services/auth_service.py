# import 'dart:convert';

# import 'package:http/http.dart' as http;


# class AuthService {
#   const AuthService();

#   static const String _baseUrl =
#       'http://127.0.0.1:8000';


#   Future<Map<String, dynamic>> register({
#     required String firstName,
#     required String lastName,
#     required String email,
#     required String contactNumber,
#     required String password,
#     required String confirmPassword,
#   }) async {

#     final uri = Uri.parse(
#       '$_baseUrl/auth/register',
#     );


#     final response = await http.post(
#       uri,

#       headers: {
#         'Content-Type': 'application/json',
#       },

#       body: jsonEncode({
#         'first_name': firstName.trim(),
#         'last_name': lastName.trim(),
#         'email': email.trim(),
#         'contact_num': contactNumber.trim(),
#         'password': password,
#         'confirm_password': confirmPassword,
#       }),
#     );


#     final dynamic decoded =
#         jsonDecode(response.body);


#     if (response.statusCode == 201) {

#       return Map<String, dynamic>.from(
#         decoded,
#       );
#     }


#     String message =
#         'Registration failed.';


#     if (decoded is Map &&
#         decoded['detail'] != null) {

#       final detail = decoded['detail'];

#       if (detail is String) {
#         message = detail;
#       }
#     }


#     throw Exception(message);
#   }
# }


import 'dart:convert';

import 'package:http/http.dart' as http;


class AuthService {
  const AuthService();

  static const String _baseUrl =
      'http://127.0.0.1:8000';


  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String contactNumber,
    required String password,
    required String confirmPassword,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/auth/register',
    );

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'email': email.trim(),
        'contact_num': contactNumber.trim(),
        'password': password,
        'confirm_password': confirmPassword,
      }),
    );

    final dynamic decoded =
        jsonDecode(response.body);

    if (response.statusCode == 201) {
      return Map<String, dynamic>.from(
        decoded,
      );
    }

    String message =
        'Registration failed.';

    if (decoded is Map &&
        decoded['detail'] != null) {
      final detail = decoded['detail'];

      if (detail is String) {
        message = detail;
      }
    }

    throw Exception(message);
  }
}