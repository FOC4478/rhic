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
        child: Column(
          children: [
            const SizedBox(height: 30),

            Text(
              l10n.selectLanguage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF330044),
              ),
            ),

            const SizedBox(height: 30),

            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                ),
                itemCount: _languageCodes.length,
                separatorBuilder: (_, __) {
                  return const SizedBox(height: 14);
                },
                itemBuilder: (context, index) {
                  final languageCode =
                      _languageCodes[index];

                  final countryCode =
                      _countryCodes[languageCode]!;

                  final languageName =
                      _getLanguageName(
                    languageCode,
                    l10n,
                  );

                  return _LanguageTile(
                    languageName: languageName,
                    countryCode: countryCode,
                    isSelected:
                        _selectedLanguage == languageCode,
                    onTap: () {
                      _selectLanguage(languageCode);
                    },
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                32,
                16,
                32,
                28,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF3A064D),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(32),
                    ),
                  ),
                  child: Text(
                    l10n.continueButton,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

          height: 76,

          padding: const EdgeInsets.symmetric(
            horizontal: 18,
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
              CountryFlag.fromCountryCode(
                countryCode,
                theme: const ImageTheme(
                  width: 44,
                  height: 44,
                  shape: Circle(),
                ),
              ),

              const SizedBox(width: 18),

              Expanded(
                child: Text(
                  languageName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF292929),
                  ),
                ),
              ),

              AnimatedContainer(
                duration: const Duration(
                  milliseconds: 220,
                ),

                width: 25,
                height: 25,

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
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}