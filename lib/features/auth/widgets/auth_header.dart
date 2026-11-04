import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/pijar_logo.dart';

/// Fixed indigo header shared by Login and Register.
/// Set [compact] to true while the keyboard is open to save space.
class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.showBack = false,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final bool showBack;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
        ),
        padding: EdgeInsets.fromLTRB(24, 12, 24, compact ? 16 : 32),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showBack)
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  tooltip: 'Back',
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white),
                )
              else
                const SizedBox(height: 8),
              const SizedBox(height: 8),
              Row(
                children: [
                  PijarLogo(size: compact ? 36 : 48),
                  const SizedBox(width: 12),
                  Text.rich(
                    TextSpan(
                      style: GoogleFonts.poppins(
                        fontSize: compact ? 20 : 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      children: const [
                        TextSpan(text: 'Pijar'),
                        TextSpan(
                          text: 'Edu',
                          style: TextStyle(color: AppColors.spark),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.topCenter,
                child: compact
                    ? const SizedBox(width: double.infinity)
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 28),
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.85),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}