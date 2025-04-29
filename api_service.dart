// services/api_service.dart
// ignore_for_file: unused_element, deprecated_member_use

import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  // Helper to get auth token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Save token locally
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Clear token (logout)
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Register new user
  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String securityQuestion,
    String securityAnswer,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': name,
        'email': email,
        'password': password,
        'securityQuestion': securityQuestion,
        'securityAnswer': securityAnswer,
      }),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      await saveToken(data['token']);
      return data;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Registration failed');
    }
  }

  // Login user
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await saveToken(data['token']);
      return data;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Login failed');
    }
  }

  // Logout
  Future<void> logout() async {
    await clearToken();
  }

  // Get user's security question
  Future<String> getSecurityQuestion(String email) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/auth/security-question/$email'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['securityQuestion'];
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get security question');
    }
  }

  // Verify security answer
  Future<bool> verifySecurityAnswer(String email, String securityAnswer) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/verify-security-answer'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'securityAnswer': securityAnswer,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['verified'] ?? false;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Verification failed');
    }
  }

  // Reset password with security answer
  Future<void> resetPasswordWithSecurityAnswer(
      String email, String securityAnswer, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/reset-password/security'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'securityAnswer': securityAnswer,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Password reset failed');
    }
  }

  // Request password reset code
  Future<String> requestResetCode(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/request-reset-code'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['code'];
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to request reset code');
    }
  }

  // Verify reset code
  Future<bool> verifyResetCode(String email, String code) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/verify-reset-code'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'code': code,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['verified'] ?? false;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Code verification failed');
    }
  }

  // Reset password with code
  Future<void> resetPasswordWithCode(
      String email, String code, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/reset-password/code'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'code': code,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Password reset failed');
    }
  }

  // Get statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/api/statistics'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get statistics');
    }
  }

  // Update app usage
  Future<void> updateAppUsage() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/app-usage'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to update app usage');
    }
  }

  // Get notes
  Future<List<Map<String, dynamic>>> getNotes() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/api/notes'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> notesList = json.decode(response.body);
      return notesList.cast<Map<String, dynamic>>();
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get notes');
    }
  }

  // Create note with formatting
  Future<Map<String, dynamic>> createNote(String title, String body,
      {Color? textColor, String? fontFamily, double? fontSize}) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/api/notes'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'title': title,
        'body': body,
        // ignore: duplicate_ignore
        // ignore: deprecated_member_use
        'textColor': textColor?.value,
        'fontFamily': fontFamily,
        'fontSize': fontSize,
      }),
    );
// Update note with formatting
    Future<Map<String, dynamic>> updateNote(
        int noteId, String title, String body,
        {Color? textColor, String? fontFamily, double? fontSize}) async {
      final token = await getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/api/notes/$noteId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'title': title,
          'body': body,
          'textColor': textColor?.value,
          'fontFamily': fontFamily,
          'fontSize': fontSize,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to update note');
      }
    }

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to create note');
    }
  }

  // Delete note
  Future<void> deleteNote(int noteId) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required');
    }

    final response = await http.delete(
      Uri.parse('$baseUrl/api/notes/$noteId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to delete note');
    }
  }

  // Get reminders
  Future<List<Map<String, dynamic>>> getReminders() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/api/reminders'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> remindersList = json.decode(response.body);
      return remindersList.cast<Map<String, dynamic>>();
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to get reminders');
    }
  }

  // Create reminder
  Future<Map<String, dynamic>> createReminder(
      String title, String description, DateTime dateTime) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/api/reminders'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'title': title,
        'description': description,
        'dateTime': dateTime.toIso8601String(),
      }),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to create reminder');
    }
  }

  // Delete reminder
  Future<void> deleteReminder(int reminderId) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required');
    }

    final response = await http.delete(
      Uri.parse('$baseUrl/api/reminders/$reminderId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to delete reminder');
    }
  }
}
