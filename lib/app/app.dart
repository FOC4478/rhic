import 'package:flutter/material.dart';

import 'package:church_app/l10n/app_localizations.dart';
import 'package:church_app/app/locale_controller.dart';

import 'package:church_app/screens/splash/splash_screen.dart';
import 'package:church_app/screens/languages/language_screen.dart';
import 'package:church_app/screens/onboarding/onboarding_screen.dart';
import 'package:church_app/screens/home/home_screen.dart';
import 'package:church_app/screens/auth/login_screen.dart';
import 'package:church_app/screens/auth/registration_screen.dart';
import 'package:church_app/screens/auth/verification_screen.dart';
import 'package:church_app/screens/events/events_screen.dart';

class ChurchApp extends StatelessWidget {
  const ChurchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: RhicLocaleController.instance,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,

          title: 'RHIC',

          locale: RhicLocaleController.instance.locale,

          localizationsDelegates:
              AppLocalizations.localizationsDelegates,

          supportedLocales:
              AppLocalizations.supportedLocales,

          initialRoute: '/splash',

          routes: {
            '/splash': (context) =>
                const SplashScreen(),

            '/language': (context) =>
                const LanguageScreen(),

            '/onboarding': (context) =>
                const OnboardingScreen(),

            // AUTH
            '/login': (context) =>
                const LoginScreen(),

            '/registration': (context) =>
                const RegisterScreen(),

            '/verification': (context) =>
                const VerificationScreen(),

                '/home': (context) => 
                const HomeScreen(),

                '/events': (context) =>
                 const EventsScreen(),
          },
        );
      },
    );
  }
}