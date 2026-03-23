import 'package:flutter/material.dart';

/// Stub for non-web platforms — just uses Image.network
Widget buildWebNativeImage({
  required String imageUrl,
  BoxFit fit = BoxFit.cover,
  double? height,
  double? width,
  Widget? placeholder,
  Widget? errorWidget,
  bool circular = false,
}) {
  final child = Image.network(
    imageUrl,
    fit: fit,
    height: height,
    width: width,
    loadingBuilder: (context, child, loadingProgress) {
      if (loadingProgress == null) return child;
      return placeholder ?? const Center(child: CircularProgressIndicator(strokeWidth: 2));
    },
    errorBuilder: (context, error, stackTrace) =>
        errorWidget ?? const Icon(Icons.image_not_supported),
  );
  return circular ? ClipOval(child: child) : child;
}
