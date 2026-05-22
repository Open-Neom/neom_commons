import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../ui/theme/app_color.dart';

class PaletteUtilities {
  /// Extract color palette from an image provider
  static Future<PaletteInfo> fromImageProvider(
      ImageProvider provider, {
        Size size = const Size(80, 80),
        int maximumColorCount = 8,
      }) async {
    try {
      // Obtain image from provider
      final imageInfo = await _getImageInfo(provider);
      final image = imageInfo.image;

      // Sample image pixels at reduced resolution
      final pixels = await _sampleImagePixels(image, size);

      // Extract palette using quantization
      final palette = _extractPalette(pixels, maximumColorCount);

      return PaletteInfo._(palette);
    } catch (e) {
      // Return empty palette on error
      return PaletteInfo._({});
    }
  }

  /// Synchronous version for already loaded images
  static Future<PaletteInfo> fromImage(ui.Image image, {int maximumColorCount = 8}) async {
    try {
      final pixels = await _sampleImagePixels(image, Size(image.width.toDouble(), image.height.toDouble()));
      final palette = _extractPalette(pixels, maximumColorCount);
      return PaletteInfo._(palette);
    } catch (e) {
      return PaletteInfo._({});
    }
  }

  /// Get dominant color from an image (simplified API)
  static Future<Color> getDominantColor(ImageProvider provider) async {
    final palette = await fromImageProvider(provider);
    return palette.dominantColor?.color ?? AppColor.getMain();
  }

  static Future<ImageInfo> _getImageInfo(ImageProvider provider) async {
    final completer = Completer<ImageInfo>();
    final stream = provider.resolve(const ImageConfiguration());
    final listener = ImageStreamListener((info, _) {
      completer.complete(info);
    });
    stream.addListener(listener);
    return completer.future;
  }

  static Future<Map<int, int>> _sampleImagePixels(ui.Image image, Size sampleSize) async {
    final width = image.width;
    final height = image.height;

    // Calculate sampling step
    final targetWidth = sampleSize.width.toInt().clamp(1, width);
    final targetHeight = sampleSize.height.toInt().clamp(1, height);
    final stepX = width / targetWidth;
    final stepY = height / targetHeight;

    final pixels = <int, int>{}; // ARGB color -> count

    // Extract raw pixel data
    final byteData = await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );

    if (byteData == null) return {};

    final stride = width * 4;
    final sampledPixels = <int>[];

    // Sample pixels at regular intervals
    for (var y = 0; y < targetHeight; y++) {
      final pixelY = (y * stepY).toInt().clamp(0, height - 1);
      final rowStart = pixelY * stride;

      for (var x = 0; x < targetWidth; x++) {
        final pixelX = (x * stepX).toInt().clamp(0, width - 1);
        final index = rowStart + pixelX * 4;

        if (index + 3 < byteData.lengthInBytes) {
          final r = byteData.getUint8(index);
          final g = byteData.getUint8(index + 1);
          final b = byteData.getUint8(index + 2);
          final a = byteData.getUint8(index + 3);

          // Skip transparent pixels
          if (a > 128) {
            // Quantize colors to group similar shades
            final quantizedR = (r ~/ 16) * 16;
            final quantizedG = (g ~/ 16) * 16;
            final quantizedB = (b ~/ 16) * 16;
            final colorKey = (quantizedR << 16) | (quantizedG << 8) | quantizedB;

            sampledPixels.add((colorKey << 8) | a);
          }
        }
      }
    }

    // Count frequency of each color
    for (final pixel in sampledPixels) {
      pixels[pixel] = (pixels[pixel] ?? 0) + 1;
    }

    return pixels;
  }

  static Map<PaletteColorType, PaletteColor> _extractPalette(
      Map<int, int> pixels,
      int maximumColorCount,
      ) {
    if (pixels.isEmpty) return {};

    // Sort colors by frequency
    final sortedColors = pixels.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final paletteColors = <PaletteColor>[];
    final seenColors = <int>{};

    for (final entry in sortedColors.take(maximumColorCount)) {
      final argb = entry.key;
      final a = (argb >> 24) & 0xFF;
      final b = (argb >> 16) & 0xFF;
      final g = (argb >> 8) & 0xFF;
      final r = argb & 0xFF;

      final color = Color.fromARGB(a != 0 ? a : 255, r, g, b);

      // Avoid nearly duplicate colors
      bool isDuplicate = false;
      for (final existing in seenColors) {
        final existingR = (existing >> 16) & 0xFF;
        final existingG = (existing >> 8) & 0xFF;
        final existingB = existing & 0xFF;

        final diffR = (existingR - r).abs();
        final diffG = (existingG - g).abs();
        final diffB = (existingB - b).abs();

        if (diffR < 32 && diffG < 32 && diffB < 32) {
          isDuplicate = true;
          break;
        }
      }

      if (!isDuplicate) {
        seenColors.add((r << 16) | (g << 8) | b);
        paletteColors.add(PaletteColor(color, entry.value));
      }
    }

    final result = <PaletteColorType, PaletteColor>{};

    // Assign color roles based on characteristics
    for (int i = 0; i < paletteColors.length; i++) {
      final paletteColor = paletteColors[i];
      final type = _determineColorType(paletteColor.color, i);
      result[type] = paletteColor;
    }

    return result;
  }

  static PaletteColorType _determineColorType(Color color, int index) {
    final hsl = _rgbToHsl(color.red, color.green, color.blue);

    // Vibrant: high saturation and medium lightness
    if (hsl.saturation > 0.5 && hsl.lightness > 0.4 && hsl.lightness < 0.7) {
      return index == 0 ? PaletteColorType.vibrant : PaletteColorType.lightVibrant;
    }

    // Muted: low saturation
    if (hsl.saturation < 0.3) {
      return index == 0 ? PaletteColorType.muted : PaletteColorType.lightMuted;
    }

    // Default to dominant
    return PaletteColorType.dominant;
  }

  static _HslColor _rgbToHsl(int r, int g, int b) {
    final rd = r / 255;
    final gd = g / 255;
    final bd = b / 255;

    final max = [rd, gd, bd].reduce((a, b) => a > b ? a : b);
    final min = [rd, gd, bd].reduce((a, b) => a < b ? a : b);
    final delta = max - min;

    double lightness = (max + min) / 2;
    double saturation = 0;
    double hue = 0;

    if (delta != 0) {
      saturation = delta / (1 - (2 * lightness - 1).abs());

      if (max == rd) {
        hue = ((gd - bd) / delta) % 6;
      } else if (max == gd) {
        hue = ((bd - rd) / delta) + 2;
      } else {
        hue = ((rd - gd) / delta) + 4;
      }

      hue *= 60;
      if (hue < 0) hue += 360;
    }

    return _HslColor(hue, saturation, lightness);
  }
}

class PaletteInfo {
  final Map<PaletteColorType, PaletteColor> _palette;

  const PaletteInfo._(this._palette);

  PaletteColor? get dominantColor => _palette[PaletteColorType.dominant];
  PaletteColor? get vibrantColor => _palette[PaletteColorType.vibrant];
  PaletteColor? get mutedColor => _palette[PaletteColorType.muted];
  PaletteColor? get lightVibrantColor => _palette[PaletteColorType.lightVibrant];
  PaletteColor? get lightMutedColor => _palette[PaletteColorType.lightMuted];
  PaletteColor? get darkVibrantColor => _palette[PaletteColorType.darkVibrant];
  PaletteColor? get darkMutedColor => _palette[PaletteColorType.darkMuted];

  List<PaletteColor> get colors => _palette.values.toList();
}

class PaletteColor {
  final Color color;
  final int population;

  const PaletteColor(this.color, this.population);
}

enum PaletteColorType {
  dominant,
  vibrant,
  muted,
  lightVibrant,
  lightMuted,
  darkVibrant,
  darkMuted,
}

class _HslColor {
  final double hue;
  final double saturation;
  final double lightness;

  const _HslColor(this.hue, this.saturation, this.lightness);
}