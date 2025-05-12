// lib/services/api_service.dart
// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  // Get token from shared preferences
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Save token to shared preferences
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // Save user info to shared preferences
  Future<void> saveUserInfo(int userId, String name, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userId', userId);
    await prefs.setString('userName', name);
    await prefs.setString('userEmail', email);
  }

  // Get user info from shared preferences
  Future<Map<String, dynamic>> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getInt('userId'),
      'name': prefs.getString('userName'),
      'email': prefs.getString('userEmail')
    };
  }

  // Remove token from shared preferences (logout)
  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userId');
    await prefs.remove('userName');
    await prefs.remove('userEmail');
  }

  // Get headers with token
  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': token != null ? 'Bearer $token' : '',
    };
  }

  // Register
  Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        await saveToken(data['token']);
        await saveUserInfo(
            data['user']['id'], data['user']['name'], data['user']['email']);
        return data;
      } else {
        throw Exception(data['message'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await saveToken(data['token']);
        await saveUserInfo(
            data['user']['id'], data['user']['name'], data['user']['email']);
        return data;
      } else {
        throw Exception(data['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    await removeToken();
  }

  // Update app usage
  Future<void> updateAppUsage() async {
    try {
      final headers = await _getHeaders();
      await http.post(
        Uri.parse('$baseUrl/api/auth/app-usage'),
        headers: headers,
      );
    } catch (e) {
      print('Failed to update app usage: $e');
    }
  }

  // Get Statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/statistics'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load statistics');
      }
    } catch (e) {
      throw Exception('Failed to load statistics: $e');
    }
  }

  // Get Notes
  Future<List<Map<String, dynamic>>> getNotes() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/notes'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((note) => note as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to load notes');
      }
    } catch (e) {
      throw Exception('Failed to load notes: $e');
    }
  }

  // Create Note
  Future<Map<String, dynamic>> createNote(String title, String body) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/notes'),
        headers: headers,
        body: jsonEncode({
          'title': title,
          'body': body,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create note');
      }
    } catch (e) {
      throw Exception('Failed to create note: $e');
    }
  }

  // Update Note
  Future<Map<String, dynamic>> updateNote(
      int id, String title, String body) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/api/notes/$id'),
        headers: headers,
        body: jsonEncode({
          'title': title,
          'body': body,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update note');
      }
    } catch (e) {
      throw Exception('Failed to update note: $e');
    }
  }

  // Delete Note
  Future<void> deleteNote(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/api/notes/$id'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete note');
      }
    } catch (e) {
      throw Exception('Failed to delete note: $e');
    }
  }

  // Get Reminders
  Future<List<Map<String, dynamic>>> getReminders() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/reminders'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data
            .map((reminder) => reminder as Map<String, dynamic>)
            .toList();
      } else {
        throw Exception('Failed to load reminders');
      }
    } catch (e) {
      throw Exception('Failed to load reminders: $e');
    }
  }

  // Get Today's Reminders
  Future<List<Map<String, dynamic>>> getTodayReminders() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/reminders/today'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data
            .map((reminder) => reminder as Map<String, dynamic>)
            .toList();
      } else {
        throw Exception('Failed to load today\'s reminders');
      }
    } catch (e) {
      throw Exception('Failed to load today\'s reminders: $e');
    }
  }

  // Create Reminder
  Future<Map<String, dynamic>> createReminder(
      String title, String description, DateTime dateTime) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/reminders'),
        headers: headers,
        body: jsonEncode({
          'title': title,
          'description': description,
          'dateTime': dateTime.toIso8601String(),
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create reminder');
      }
    } catch (e) {
      throw Exception('Failed to create reminder: $e');
    }
  }

  // Update Reminder
  Future<Map<String, dynamic>> updateReminder(
      int id, String title, String description, DateTime dateTime) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/api/reminders/$id'),
        headers: headers,
        body: jsonEncode({
          'title': title,
          'description': description,
          'dateTime': dateTime.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update reminder');
      }
    } catch (e) {
      throw Exception('Failed to update reminder: $e');
    }
  }

  // Delete Reminder
  Future<void> deleteReminder(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/api/reminders/$id'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete reminder');
      }
    } catch (e) {
      throw Exception('Failed to delete reminder: $e');
    }
  }

  // Update profile
  Future<void> updateProfile(String name, String email) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/api/profile'),
        headers: headers,
        body: jsonEncode({
          'name': name,
          'email': email,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  // Request password reset code
  Future<String?> requestResetCode(String email) async {
    try {
      print('Requesting reset code for: $email');
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/request-reset-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // In production, the code would be sent to the email
        // For testing, we return it from the response
        return data['code'];
      } else if (response.statusCode == 404) {
        throw Exception('Email not found in our system');
      } else {
        throw Exception('Failed to request reset code');
      }
    } catch (e) {
      print('Exception in requestResetCode: $e');
      throw Exception('Error requesting reset code: $e');
    }
  }

  // Verify reset code
  Future<bool> verifyResetCode(String email, String code) async {
    try {
      print('Verifying code: $code for email: $email');
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/verify-reset-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'code': code,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['valid'] ?? false;
      } else {
        throw Exception('Invalid or expired code');
      }
    } catch (e) {
      print('Exception in verifyResetCode: $e');
      throw Exception('Error verifying code: $e');
    }
  }

  // Reset password with code
  Future<void> resetPasswordWithCode(
      String email, String code, String newPassword) async {
    try {
      print('Resetting password for: $email with code: $code');
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
            {'email': email, 'code': code, 'newPassword': newPassword}),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to reset password');
      }
    } catch (e) {
      print('Exception in resetPasswordWithCode: $e');
      throw Exception('Error resetting password: $e');
    }
  }
}
