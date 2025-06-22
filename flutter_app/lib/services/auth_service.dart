import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_app/user_provider.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static Future<bool> login(
      BuildContext context, String username, String password) async {
    final url = Uri.parse('http://127.0.0.1:3050/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final token = json['access_token'];

      final int userId = json['user_id'] is int
          ? json['user_id']
          : int.parse(json['user_id'].toString());

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', token);

      // ✅ context 넘겨받아 Provider에 저장
      Provider.of<UserProvider>(context, listen: false).setUserId(userId);

      return true;
    } else {
      return false;
    }
  }

  // 토큰 가져오기
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // 로그인 여부 확인
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('access_token');
  }

  // 로그아웃
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }
}
