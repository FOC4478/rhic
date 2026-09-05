import 'package:church_app/screens/members/auth/login_screen.dart';
import 'package:church_app/screens/members/auth/verification_screen.dart';
import 'package:church_app/screens/members/home/home_screen.dart';
import 'package:church_app/services/auth_service.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        
        // Firebase is checking the current authentication state.
       

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const _AuthLoadingScreen();
        }

        // No authenticated user
     

        final user = snapshot.data;

        if (user == null) {
          return const LoginScreen();
        }

        // User is authenticated but email is not verified.
          if (!user.emailVerified) {
          return const VerificationScreen();
        }

        // User is authenticated and verified.


        return const HomeScreen();
      },
    );
  }
}


// AUTH LOADING SCREEN


class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF3D004D),
        ),
      ),
    );
  }
}