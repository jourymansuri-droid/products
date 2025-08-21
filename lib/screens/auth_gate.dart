// lib/screens/auth_gate.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import '../providers/theme_notifier.dart';

class AuthGate extends StatelessWidget {
  final ThemeNotifier themeNotifier;
  const AuthGate({super.key, required this.themeNotifier});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Still waiting for Firebase to reply
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If user is logged in
        if (snapshot.hasData) {
          return HomePage(themeNotifier: themeNotifier);
        }

        // If user is not logged in
        return LoginScreen(themeNotifier: themeNotifier);
      },
    );
  }
}
