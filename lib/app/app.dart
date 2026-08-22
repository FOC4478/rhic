import 'package:flutter/material.dart';

import 'package:church_app/l10n/app_localizations.dart';
import 'package:church_app/app/locale_controller.dart';
import 'package:church_app/screens/giving/giving_screen.dart';
import 'package:church_app/screens/giving/giving_currency_screen.dart';
import 'package:church_app/screens/giving/giving_payment_details_screen.dart';
import 'package:church_app/screens/giving/giving_confirmation_screen.dart';
import 'package:church_app/screens/teachings/teachings_screen.dart';
import 'package:church_app/screens/splash/splash_screen.dart';
import 'package:church_app/screens/languages/language_screen.dart';
import 'package:church_app/screens/onboarding/onboarding_screen.dart';
import 'package:church_app/screens/home/home_screen.dart';

import 'package:church_app/screens/auth/login_screen.dart';
import 'package:church_app/screens/auth/registration_screen.dart';
import 'package:church_app/screens/auth/verification_screen.dart';

import 'package:church_app/screens/events/events_screen.dart';
import 'package:church_app/screens/gallery/gallery_screen.dart';

import 'package:church_app/screens/community/community_screen.dart';
import 'package:church_app/screens/community/community_group_details_screen.dart';
import 'package:church_app/screens/community/community_group_members_screen.dart';

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
            // ====================================================
            // SPLASH
            // ====================================================

            '/splash': (context) =>
                const SplashScreen(),

            // ====================================================
            // LANGUAGE
            // ====================================================

            '/language': (context) =>
                const LanguageScreen(),

            // ====================================================
            // ONBOARDING
            // ====================================================

            '/onboarding': (context) =>
                const OnboardingScreen(),

            // ====================================================
            // AUTH
            // ====================================================

            '/login': (context) =>
                const LoginScreen(),

            '/registration': (context) =>
                const RegisterScreen(),

            '/verification': (context) =>
                const VerificationScreen(),

            // ====================================================
            // MAIN APP
            // ====================================================

            '/home': (context) =>
                const HomeScreen(),

            '/events': (context) =>
                const EventsScreen(),

            '/teachings': (context) =>
                const TeachingsScreen(),

            '/gallery': (context) =>
                const GalleryScreen(),

                '/giving': (context) =>
    const GivingScreen(),

'/giving-currency': (context) {
  final givingType =
      ModalRoute.of(context)!.settings.arguments as String;

  return GivingCurrencyScreen(
    givingType: givingType,
  );
},

'/giving-payment-details': (context) {
  final args =
      ModalRoute.of(context)!.settings.arguments
          as Map<String, dynamic>;

  return GivingPaymentDetailsScreen(
    givingType: args['givingType'] as String,
    currency: args['currency'] as String,
  );
},

'/giving-confirmation': (context) {
  final args =
      ModalRoute.of(context)!.settings.arguments
          as Map<String, dynamic>;

  return GivingConfirmationScreen(
    givingType: args['givingType'] as String,
    currency: args['currency'] as String,
  );
},

            '/community': (context) =>
                const CommunityScreen(),

            // ====================================================
            // COMMUNITY GROUP MEMBERS
            // ====================================================

            '/community-group-members': (context) {
              final arguments =
                  ModalRoute.of(context)
                      ?.settings
                      .arguments;

              if (arguments is! String ||
                  arguments.isEmpty) {
                return const Scaffold(
                  body: Center(
                    child: Text(
                      'Community group ID is missing.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }

              return CommunityGroupMembersScreen(
                groupId: arguments,
              );
            },

            // ====================================================
            // COMMUNITY GROUP DETAILS
            // ====================================================

            '/community-group': (context) {
              final arguments =
                  ModalRoute.of(context)
                      ?.settings
                      .arguments;

              if (arguments is! String ||
                  arguments.isEmpty) {
                return const Scaffold(
                  body: Center(
                    child: Text(
                      'Community group ID is missing.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }

              return CommunityGroupDetailsScreen(
                groupId: arguments,
              );
            },
          },
        );
      },
    );
  }
}