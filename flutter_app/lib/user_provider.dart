import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  int? _userId;

  // ✅ 생성자에 인자 없음!
  UserProvider();

  int? get userId => _userId;

  void setUserId(int id) {
    _userId = id;
    notifyListeners();
  }
}
