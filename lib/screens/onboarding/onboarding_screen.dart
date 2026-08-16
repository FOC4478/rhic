import 'package:flutter/material.dart';

import 'package:church_app/l10n/app_localizations.dart';


class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();

  int _currentPage = 0;

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final List<OnboardingPageData> _pages = const [
    OnboardingPageData(
      image: 'assets/images/onboarding_1.png',
      title: 'welcome',
      description: 'welcomeDescription',
    ),
    OnboardingPageData(
      image: 'assets/images/onboarding_2.png',
      title: 'welcome',
      description: 'liveDescription',
    ),
    OnboardingPageData(
      image: 'assets/images/onboarding_3.png',
      title: 'designed',
      description: 'secureDescription',
    ),
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.9, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _restartTextAnimation() {
    _animationController
      ..reset()
      ..forward();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    } else {
      _getStarted();
    }
  }

  void _skip() {
    _getStarted();
  }

  void _getStarted() {
    Navigator.pushReplacementNamed(
      context,
      '/login',
    );
  }

  String _getTitle(
    AppLocalizations l10n,
    String key,
  ) {
    switch (key) {
      case 'welcome':
        return l10n.welcomeToRhicApp;

      case 'designed':
        return l10n.designedWithYouInMind;

      default:
        return '';
    }
  }

  String _getDescription(
    AppLocalizations l10n,
    String key,
  ) {
    switch (key) {
      case 'welcomeDescription':
        return l10n.rhicWelcomeDescription;

      case 'liveDescription':
        return l10n.rhicLiveDescription;

      case 'secureDescription':
        return l10n.rhicSecureDescription;

      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF310044),
      body: PageView.builder(
        controller: _pageController,
        itemCount: _pages.length,

        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });

          _restartTextAnimation();
        },

        itemBuilder: (context, index) {
          return _buildOnboardingPage(
            context,
            l10n,
            _pages[index],
          );
        },
      ),
    );
  }

  Widget _buildOnboardingPage(
    BuildContext context,
    AppLocalizations l10n,
    OnboardingPageData page,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ------------------------------------------------
        // BACKGROUND IMAGE
        // ------------------------------------------------
        Image.asset(
          page.image,
          fit: BoxFit.cover,
        ),

        // ------------------------------------------------
        // PURPLE GRADIENT
        // ------------------------------------------------
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [
                0.0,
                0.30,
                0.60,
                1.0,
              ],
              colors: [
                Color(0x22000000),
                Color(0x33000000),
                Color(0x990D0015),
                Color(0xF5310045),
              ],
            ),
          ),
        ),

        // ------------------------------------------------
        // EXTRA PURPLE TINT
        // ------------------------------------------------
        Container(
          color: Color(0x260E001A),
        ),

        // ------------------------------------------------
        // CONTENT
        // ------------------------------------------------
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 26,
            ),
            child: Column(
              children: [
                // ==========================================
                // TOP
                // ==========================================
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // RHIC LOGO
                    Image.asset(
                      'assets/images/coza_logo.png',
                      width: 64,
                      height: 64,
                      fit: BoxFit.contain,
                    ),

                    // SKIP
                    GestureDetector(
                      onTap: _skip,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: 16,
                        ),
                        child: Row(
                          children: [
                            Text(
                              l10n.skip,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 23,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // ==========================================
                // ANIMATED TEXT
                // ==========================================
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getTitle(
                              l10n,
                              page.title,
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 29,
                              height: 1.15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 14),

                          Text(
                            _getDescription(
                              l10n,
                              page.description,
                            ),
                            style: const TextStyle(
                              color: Color(0xFFE7DDEB),
                              fontSize: 17,
                              height: 1.4,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // ==========================================
                // BOTTOM CONTROLS
                // ==========================================
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.center,
                  children: [
                    // INDICATORS
                    Expanded(
                      child: Row(
                        children: [
                          _buildIndicator(0),
                          const SizedBox(width: 10),
                          _buildIndicator(1),
                          const SizedBox(width: 10),
                          _buildIndicator(2),
                        ],
                      ),
                    ),

                    // ACTION BUTTON
                    _buildActionButton(l10n),
                  ],
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ======================================================
  // PAGE INDICATOR
  // ======================================================

  Widget _buildIndicator(int index) {
    final bool active = _currentPage == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      width: active ? 39 : 9,
      height: 9,
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFFFF8A00)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  // ======================================================
  // NEXT / GET STARTED BUTTON
  // ======================================================

  Widget _buildActionButton(
    AppLocalizations l10n,
  ) {
    final bool lastPage =
        _currentPage == _pages.length - 1;

    if (lastPage) {
      return GestureDetector(
        onTap: _nextPage,
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(
            horizontal: 27,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(38),
          ),
          child: Row(
            children: [
              Text(
                l10n.getStarted,
                style: const TextStyle(
                  color: Color(0xFF72009B),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 9),
              const Icon(
                Icons.arrow_forward,
                color: Color(0xFF72009B),
                size: 23,
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _nextPage,
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: .45),
              blurRadius: 0,
              spreadRadius: 5,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: .15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_forward,
          color: Color(0xFF72009B),
          size: 29,
        ),
      ),
    );
  }
}

// ========================================================
// ONBOARDING DATA
// ========================================================

class OnboardingPageData {
  final String image;
  final String title;
  final String description;

  const OnboardingPageData({
    required this.image,
    required this.title,
    required this.description,
  });
}