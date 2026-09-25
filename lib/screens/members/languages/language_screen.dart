import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

import '../../../../../core/storage/local_storage.dart';
import '../../../../../app/locale_controller.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  final LocalStorage _storage = LocalStorage();

  String _selectedLanguage = 'en';

  final List<String> _languageCodes = const [
    'en',
    'fr',
    'ar',
    'es',
    'de',
    'ha',
    'yo',
    'ig',
  ];

  final Map<String, String> _countryCodes = const {
    'en': 'US',
    'fr': 'FR',
    'ar': 'SA',
    'es': 'ES',
    'de': 'DE',
    'ha': 'NG',
    'yo': 'NG',
    'ig': 'NG',
  };

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final savedLanguage = await _storage.getLanguage();

    if (!mounted) return;

    if (savedLanguage != null &&
        _languageCodes.contains(savedLanguage)) {
      setState(() {
        _selectedLanguage = savedLanguage;
      });

      RhicLocaleController.instance.changeLocale(
        Locale(savedLanguage),
      );
    }
  }

  String _getLanguageName(
    String code,
    AppLocalizations l10n,
  ) {
    switch (code) {
      case 'en':
        return l10n.english;

      case 'fr':
        return l10n.french;

      case 'ar':
        return l10n.arabic;

      case 'es':
        return l10n.spanish;

      case 'de':
        return l10n.german;

      case 'ha':
        return l10n.hausa;

      case 'yo':
        return l10n.yoruba;

      case 'ig':
        return l10n.igbo;

      default:
        return l10n.english;
    }
  }

  Future<void> _selectLanguage(String code) async {
    setState(() {
      _selectedLanguage = code;
    });

    await _storage.saveLanguage(code);

    RhicLocaleController.instance.changeLocale(
      Locale(code),
    );
  }

  Future<void> _continue() async {
    await _storage.saveLanguage(_selectedLanguage);

    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      '/onboarding',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFEFB),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;

            // Responsive horizontal padding.
            final horizontalPadding = screenWidth < 360
                ? 16.0
                : screenWidth < 600
                    ? 24.0
                    : 40.0;

            // Responsive top spacing.
            final topSpacing = screenHeight < 600
                ? 16.0
                : screenWidth < 600
                    ? 30.0
                    : 40.0;

            // Responsive title size.
            final titleSize = screenWidth < 360
                ? 21.0
                : screenWidth < 600
                    ? 24.0
                    : 28.0;

            return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    top: topSpacing,
                    bottom: 24,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      // =====================================================
                      // TITLE
                      // =====================================================

                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        child: Text(
                          l10n.selectLanguage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: titleSize,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF330044),
                          ),
                        ),
                      ),

                      SizedBox(
                        height: screenHeight < 600
                            ? 18
                            : 30,
                      ),

                      // =====================================================
                      // LANGUAGE LIST
                      // =====================================================

                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        child: Column(
                          children: List.generate(
                            _languageCodes.length,
                            (index) {
                              final languageCode =
                                  _languageCodes[index];

                              final countryCode =
                                  _countryCodes[
                                      languageCode]!;

                              final languageName =
                                  _getLanguageName(
                                languageCode,
                                l10n,
                              );

                              return Padding(
                                padding:
                                    EdgeInsets.only(
                                  bottom:
                                      index ==
                                              _languageCodes
                                                      .length -
                                                  1
                                          ? 0
                                          : 14,
                                ),
                                child: _LanguageTile(
                                  languageName:
                                      languageName,
                                  countryCode:
                                      countryCode,
                                  isSelected:
                                      _selectedLanguage ==
                                          languageCode,
                                  onTap: () {
                                    _selectLanguage(
                                      languageCode,
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // =====================================================
                      // CONTINUE BUTTON
                      // =====================================================

                      SizedBox(
                        height: screenHeight < 600
                            ? 20
                            : 28,
                      ),

                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: screenWidth < 360
                              ? 56
                              : 64,
                          child: ElevatedButton(
                            onPressed: _continue,
                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(
                                0xFF3A064D,
                              ),
                              foregroundColor:
                                  Colors.white,
                              elevation: 0,
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  32,
                                ),
                              ),
                            ),
                            child: Text(
                              l10n.continueButton,
                              style: TextStyle(
                                fontSize:
                                    screenWidth < 360
                                        ? 15
                                        : 17,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================================
// LANGUAGE TILE
// ============================================================================

class _LanguageTile extends StatelessWidget {
  final String languageName;
  final String countryCode;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.languageName,
    required this.countryCode,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final horizontalPadding = width < 330
            ? 12.0
            : width < 400
                ? 16.0
                : 18.0;

        final flagSize = width < 330 ? 38.0 : 44.0;

        final fontSize = width < 330 ? 15.0 : 17.0;

        final radioSize = width < 330 ? 23.0 : 25.0;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(
                milliseconds: 220,
              ),
              curve: Curves.easeOut,

              // Responsive height.
              constraints: const BoxConstraints(
                minHeight: 70,
              ),

              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 12,
              ),

              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFF5EFF7)
                    : const Color(0xFFF7F7F7),
                borderRadius:
                    BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF6B1B7A)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),

              child: Row(
                children: [
                  // =========================================================
                  // COUNTRY FLAG
                  // =========================================================

                  SizedBox(
                    width: flagSize,
                    height: flagSize,
                    child:
                        CountryFlag.fromCountryCode(
                      countryCode,
                      theme: ImageTheme(
                        width: flagSize,
                        height: flagSize,
                        shape: const Circle(),
                      ),
                    ),
                  ),

                  SizedBox(
                    width: width < 330 ? 12 : 18,
                  ),

                  // =========================================================
                  // LANGUAGE NAME
                  // =========================================================

                  Expanded(
                    child: Text(
                      languageName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF292929),
                      ),
                    ),
                  ),

                  SizedBox(
                    width: width < 330 ? 10 : 14,
                  ),

                  // =========================================================
                  // SELECTION CIRCLE
                  // =========================================================

                  AnimatedContainer(
                    duration: const Duration(
                      milliseconds: 220,
                    ),
                    width: radioSize,
                    height: radioSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? const Color(0xFF6B1B7A)
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF6B1B7A)
                            : const Color(0xFF999999),
                        width: 1.8,
                      ),
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            color: Colors.white,
                            size: width < 330
                                ? 14
                                : 16,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}