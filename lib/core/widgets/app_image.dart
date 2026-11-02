import 'dart:convert';
import 'package:flutter/material.dart';

/// Normalize any image URL or path coming from API / local storage / base64
/// Ensures that relative paths or localhost URLs are correctly resolved to the production server.
String resolveFullImageUrl(String? urlOrPath) {
  if (urlOrPath == null || urlOrPath.trim().isEmpty) return '';
  String trimmed = urlOrPath.trim();
  if (trimmed.startsWith('data:image')) return trimmed;

  // Replace any local or insecure domain variants
  trimmed = trimmed
      .replaceAll('http://localhost:8080', 'https://lrf-blida.dz')
      .replaceAll('http://localhost', 'https://lrf-blida.dz')
      .replaceAll('http://127.0.0.1:8080', 'https://lrf-blida.dz')
      .replaceAll('http://127.0.0.1', 'https://lrf-blida.dz')
      .replaceAll('http://lrf-blida.dz', 'https://lrf-blida.dz');

  if (trimmed.startsWith('https://') || trimmed.startsWith('http://')) {
    return trimmed;
  }

  // Handle relative paths
  if (trimmed.startsWith('/storage/')) {
    return 'https://lrf-blida.dz$trimmed';
  }
  if (trimmed.startsWith('storage/')) {
    return 'https://lrf-blida.dz/$trimmed';
  }
  if (trimmed.startsWith('articles-images/') || trimmed.startsWith('articles/')) {
    return 'https://lrf-blida.dz/storage/$trimmed';
  }
  if (trimmed.startsWith('/images/')) {
    return 'https://lrf-blida.dz$trimmed';
  }
  if (trimmed.startsWith('images/')) {
    return 'https://lrf-blida.dz/$trimmed';
  }
  if (trimmed.startsWith('/')) {
    return 'https://lrf-blida.dz$trimmed';
  }

  return 'https://lrf-blida.dz/storage/$trimmed';
}

/// Returns an [ImageProvider] for either Base64 data or full remote URLs.
ImageProvider? getAppImageProvider(String? urlOrBase64) {
  if (urlOrBase64 == null || urlOrBase64.trim().isEmpty) return null;
  final resolved = resolveFullImageUrl(urlOrBase64);

  if (resolved.startsWith('data:image')) {
    try {
      final commaIndex = resolved.indexOf(',');
      final base64Str = commaIndex != -1 ? resolved.substring(commaIndex + 1) : resolved;
      return MemoryImage(base64Decode(base64Str));
    } catch (_) {
      return null;
    }
  }

  if (resolved.startsWith('http://') || resolved.startsWith('https://')) {
    return NetworkImage(resolved);
  }

  return null;
}

/// Unified widget for displaying app images with caching, fallback, and rounded corners.
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
    final resolvedUrl = resolveFullImageUrl(imageUrl);
    if (resolvedUrl.isEmpty) {
      return fallback ?? const SizedBox();
    }

    Widget imageWidget;
    if (resolvedUrl.startsWith('data:image')) {
      try {
        final commaIndex = resolvedUrl.indexOf(',');
        final base64String = commaIndex != -1 ? resolvedUrl.substring(commaIndex + 1) : resolvedUrl;
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
        resolvedUrl,
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
