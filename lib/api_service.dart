import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Global navigator key for logout from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ApiService {
  // Get token from SharedPreferences
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  // Save token to SharedPreferences
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  // Clear token and user data (logout)
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_data');
  }

  // Logout and go to login screen
  static Future<void> logout() async {
    await clearToken();
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }

  // GET request with auto token handling
  static Future<Map<String, dynamic>?> get(String url) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      await logout();
      return null;
    }

    try {
      final res = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      // Token expired or invalid
      if (res.statusCode == 401) {
        await logout();
        return null;
      }

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print('API Error: $e');
    }
    return null;
  }

  // POST request with auto token handling
  static Future<Map<String, dynamic>?> post(
    String url,
    Map<String, dynamic> body,
  ) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      await logout();
      return null;
    }

    try {
      final res = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      // Token expired or invalid
      if (res.statusCode == 401) {
        await logout();
        return null;
      }

      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print('API Error: $e');
    }
    return null;
  }

  // PUT request with auto token handling
  static Future<Map<String, dynamic>?> put(
    String url, [
    Map<String, dynamic>? body,
  ]) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      await logout();
      return null;
    }

    try {
      final res = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body != null ? jsonEncode(body) : null,
      );

      // Token expired or invalid
      if (res.statusCode == 401) {
        await logout();
        return null;
      }

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print('API Error: $e');
    }
    return null;
  }
}
