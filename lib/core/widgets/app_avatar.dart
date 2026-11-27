import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Circular avatar showing up to two initials of [name].
class AppAvatar extends StatelessWidget {
  const AppAvatar({super.key, required this.name, this.size = 40});

  final String name;
  final double size;

  String get _initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2);
    final letters = parts
        .map((part) => String.fromCharCode(part.runes.first))
        .join();
    return letters.isEmpty ? '?' : letters.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceHover,
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: Text(
        _initials,
        style: TextStyle(
          color: AppColors.brand,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
