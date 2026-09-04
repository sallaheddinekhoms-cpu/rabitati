import 'dart:convert';
import 'package:flutter/material.dart';

ImageProvider? getAppImageProvider(String? urlOrBase64) {
  if (urlOrBase64 == null || urlOrBase64.isEmpty) return null;
  final trimmed = urlOrBase64.trim();
  if (trimmed.startsWith('data:image')) {
    try {
      final commaIndex = trimmed.indexOf(',');
      final base64Str = commaIndex != -1 ? trimmed.substring(commaIndex + 1) : trimmed;
      return MemoryImage(base64Decode(base64Str));
    } catch (_) {
      return null;
    }
  }
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return NetworkImage(trimmed);
  }
  return null;
}

class AppImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? fallback;
  final BorderRadius? borderRadius;

  const AppImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallback,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return fallback ?? const SizedBox();
    }

    Widget imageWidget;
    if (imageUrl.startsWith('data:image')) {
      try {
        final commaIndex = imageUrl.indexOf(',');
        final base64String = commaIndex != -1 ? imageUrl.substring(commaIndex + 1) : imageUrl;
        imageWidget = Image.memory(
          base64Decode(base64String),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => fallback ?? const SizedBox(),
        );
      } catch (_) {
        imageWidget = fallback ?? const SizedBox();
      }
    } else {
      imageWidget = Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => fallback ?? const SizedBox(),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
