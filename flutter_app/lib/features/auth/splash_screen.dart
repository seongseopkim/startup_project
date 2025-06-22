import 'package:flutter/material.dart';
import 'package:flutter_app/features/auth/login_screen.dart';
import 'package:flutter_app/features/main/main_screen.dart';
import 'package:flutter_app/services/auth_service.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService.isLoggedIn(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final isLoggedIn = snapshot.data!;
        return isLoggedIn ? MainScreen() : LoginScreen();
      },
    );
  }
}
