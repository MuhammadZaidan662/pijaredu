import 'package:flutter/material.dart';

/// PijarEdu logo mark (database disks + spark).
/// Needs `assets/images/logo.png` declared in pubspec.yaml.
class PijarLogo extends StatelessWidget {
  const PijarLogo({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: size,
      height: size,
      semanticLabel: 'PijarEdu logo',
      filterQuality: FilterQuality.high,
    );
  }
}