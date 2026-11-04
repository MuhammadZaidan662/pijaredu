import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../app/theme.dart';
import '../../core/widgets/pijar_logo.dart';
import '../auth/login_page.dart';

/// Decides what a signed-out user sees: onboarding (first launch only) or Login.
class WelcomeGate extends StatefulWidget {
  const WelcomeGate({super.key});

  @override
  State<WelcomeGate> createState() => _WelcomeGateState();
}

class _WelcomeGateState extends State<WelcomeGate> {
  static const _prefsKey = 'onboarding_done';

  bool? _seen;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    var seen = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      seen = prefs.getBool(_prefsKey) ?? false;
    } catch (_) {
      seen = false;
    }
    if (!mounted) return;
    setState(() => _seen = seen);
  }

  Future<void> _finish() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, true);
    } catch (_) {
      // Not critical: onboarding will simply show again next launch.
    }
    if (!mounted) return;
    setState(() => _seen = true);
  }

  @override
  Widget build(BuildContext context) {
    final seen = _seen;
    if (seen == null) {
      return const Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(child: PijarLogo(size: 96)),
      );
    }
    if (seen) return const LoginPage();
    return OnboardingPage(onFinished: _finish);
  }
}

class _Slide {
  const _Slide(this.icon, this.title, this.text);

  final IconData icon;
  final String title;
  final String text;
}

const _slides = [
  _Slide(
    Icons.menu_book_rounded,
    'Learn databases anywhere',
    'Read materials and watch video lessons on Database Systems right from your phone.',
  ),
  _Slide(
    Icons.terminal_rounded,
    'Run SQL instantly',
    'Write a query, tap run, and see the result at once. Practice without installing anything.',
  ),
  _Slide(
    Icons.fact_check_rounded,
    'Test your knowledge',
    'Take the pretest before you start and the posttest when you finish, then see how far you have come.',
  ),
];

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  bool get _isLast => _index == _slides.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLast) {
      widget.onFinished();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Widget _panel() {
    final slide = _slides[_index];
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.sheet),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            slide.text,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 22),
          SmoothPageIndicator(
            controller: _controller,
            count: _slides.length,
            effect: ExpandingDotsEffect(
              dotHeight: 8,
              dotWidth: 8,
              expansionFactor: 3,
              activeDotColor: Colors.white,
              dotColor: Colors.white.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
              ),
              child: Text(_isLast ? 'Get Started' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pager = PageView.builder(
      controller: _controller,
      itemCount: _slides.length,
      onPageChanged: (i) => setState(() => _index = i),
      itemBuilder: (_, i) => _Illustration(icon: _slides[i].icon),
    );

    final skip = Align(
      alignment: Alignment.centerRight,
      child: Visibility(
        visible: !_isLast,
        maintainSize: true,
        maintainAnimation: true,
        maintainState: true,
        child: TextButton(
          onPressed: widget.onFinished,
          style: TextButton.styleFrom(foregroundColor: Colors.white),
          child: const Text('Skip'),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final landscape = constraints.maxWidth > constraints.maxHeight;
            if (landscape) {
              return Row(
                children: [
                  Expanded(child: pager),
                  Expanded(
                    child: Column(
                      children: [
                        skip,
                        Expanded(
                          child: Center(
                            child: SingleChildScrollView(child: _panel()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: skip,
                ),
                Expanded(child: pager),
                _panel(),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Placeholder illustration: icon on a white tile with floating accents.
/// Swap for a 3D asset later without touching the rest of the page.
class _Illustration extends StatelessWidget {
  const _Illustration({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final side = math.min(c.maxWidth, c.maxHeight) * 0.86;
        if (side <= 0) return const SizedBox.shrink();
        return Center(
          child: SizedBox(
            width: side,
            height: side,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                Container(
                  width: side * 0.78,
                  height: side * 0.78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 2,
                    ),
                  ),
                ),
                Container(
                  width: side * 0.52,
                  height: side * 0.52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(side * 0.14),
                  ),
                  child: Icon(icon, size: side * 0.28, color: AppColors.primary),
                ),
                Positioned(
                  top: side * 0.10,
                  right: side * 0.14,
                  child: Icon(Icons.auto_awesome_rounded,
                      size: side * 0.13, color: AppColors.spark),
                ),
                Positioned(
                  bottom: side * 0.16,
                  left: side * 0.10,
                  child: Container(
                    width: side * 0.09,
                    height: side * 0.09,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFF8FB1),
                    ),
                  ),
                ),
                Positioned(
                  top: side * 0.22,
                  left: side * 0.12,
                  child: Container(
                    width: side * 0.05,
                    height: side * 0.05,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}