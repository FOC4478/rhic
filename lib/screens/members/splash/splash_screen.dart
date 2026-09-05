import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _animationController;

  final List<String> _words = const [
    'Welcome',
    'to',
    'the',
    'RHIC',
    'App',
  ];

  @override
  void initState() {
    super.initState();

    // Controls the word-by-word animation.
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 2200,
      ),
    );

    _animationController.forward();

    // Move from Splash → Language automatically.
    _goToLanguageScreen();
  }

  Future<void> _goToLanguageScreen() async {
    await Future.delayed(
      const Duration(
        seconds: 4,
      ),
    );

    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed(
      '/language',
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF310044),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ==========================================
              // RHIC LOGO
              // ==========================================
              Image.asset(
                'assets/images/coza_logo.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 35),

              // ==========================================
              // ANIMATED TEXT
              //
              // The words remain on ONE horizontal line.
              // Each word enters from the RIGHT separately.
              // ==========================================
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    _words.length,
                    (index) {
                      return _AnimatedWord(
                        word: _words[index],
                        index: index,
                        controller: _animationController,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================================
// ANIMATED WORD
// ==========================================================

class _AnimatedWord extends StatelessWidget {
  final String word;
  final int index;
  final AnimationController controller;

  const _AnimatedWord({
    required this.word,
    required this.index,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    /*
      Each word gets a slightly different section
      of the animation timeline.

      Word 1 → enters first
      Word 2 → enters second
      Word 3 → enters third
      Word 4 → enters fourth
      Word 5 → enters fifth
    */

    final double start = index * 0.12;

    final double end = start + 0.32;

    final Animation<double> animation = CurvedAnimation(
      parent: controller,
      curve: Interval(
        start.clamp(0.0, 1.0),
        end.clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
        ),
        child: Text(
          word,
          maxLines: 1,
          softWrap: false,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 27,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      builder: (context, child) {
        final double progress = animation.value;

        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(
              80 * (1 - progress),
              0,
            ),
            child: child,
          ),
        );
      },
    );
  }
}