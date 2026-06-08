import 'package:flutter/material.dart';
import 'package:tune_bridge/core/di.dart';
import 'package:tune_bridge/core/services/auth_service.dart';
import 'package:tune_bridge/features/auth/ui/login_screen.dart';
import 'package:tune_bridge/ui/widgets/main_shell.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: getIt<AuthService>().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        final user = snapshot.data;
        if (user != null) {
          return const MainShell();
        } else {
          return const LoginScreen(isRoot: true);
        }
      },
    );
  }
}
