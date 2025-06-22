import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

TextEditingController usernameCtrl = TextEditingController();
TextEditingController passwordCtrl = TextEditingController();
TextEditingController emailCtrl = TextEditingController();

Future<bool> signUp(String username, String password, String email) async {
  final response = await http.post(Uri.parse('http://127.0.0.1:3050/signup'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "password": password,
        "email": email,
      }));

  if (response.statusCode == 200) {
    print("로그인 해주세요");
    return true;
  } else {
    print("에러 : ${response.body}");
    return false;
  }
}
