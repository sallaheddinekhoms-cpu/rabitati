import 'dart:convert';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ClubLogoWidget extends StatelessWidget {
  final String logoUrl;
  final double size;
  final Color fallbackColor;

  const ClubLogoWidget({
    super.key,
    required this.logoUrl,
    this.size = 40,
    this.fallbackColor = AppColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    if (logoUrl.isEmpty) {
      return Icon(Icons.shield, size: size, color: fallbackColor);
    }

    if (logoUrl.startsWith('data:image')) {
      try {
        final commaIndex = logoUrl.indexOf(',');
        final base64String = commaIndex != -1 ? logoUrl.substring(commaIndex + 1) : logoUrl;
        return Image.memory(
          base64Decode(base64String),
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(Icons.shield, size: size, color: fallbackColor),
        );
      } catch (_) {
        return Icon(Icons.shield, size: size, color: fallbackColor);
      }
    }

    return Image.network(
      logoUrl,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(Icons.shield, size: size, color: fallbackColor),
    );
  }
}
