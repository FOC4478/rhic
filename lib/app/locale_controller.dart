import 'package:flutter/material.dart';

class RhicLocaleController extends ChangeNotifier {
  RhicLocaleController._();

  static final RhicLocaleController instance =
      RhicLocaleController._();

  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  void changeLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }
}