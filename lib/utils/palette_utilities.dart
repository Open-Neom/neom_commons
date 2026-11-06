import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../ui/theme/app_color.dart';

/// Extractor perceptual de paletas de color (`OKLab` + recorte automático de bordes).
///
/// Corrige el empaquetado RGBA, evita fugas de listeners en `ImageStream`,
/// recorta barras uniformes (`letterbox`/`pillarbox` hasta 20% por borde) y
/// puntúa acentos cromáticos en espacio perceptual `OKLab`.
class PaletteUtilities {
  const PaletteUtilities._();

  /// Extrae paleta perceptual desde un [ImageProvider].
  static Future<PaletteInfo> fromImageProvider(
    ImageProvider provider, {
    Size size = const Size(80, 80),
    int maximumColorCount = 8,
  }) async {
    try {
      final imageInfo = await _getImageInfo(provider);
      final image = imageInfo.image;
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return const PaletteInfo._({});

      return fromRgbaBytes(
        byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
        image.width,
        image.height,
        sampleSize: size,
        maximumColorCount: maximumColorCount,
      );
    } catch (_) {
      return const PaletteInfo._({});
    }
  }

  /// Extrae paleta perceptual desde un [ui.Image] ya cargado en memoria.
  static Future<PaletteInfo> fromImage(
    ui.Image image, {
    int maximumColorCount = 8,
  }) async {
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return const PaletteInfo._({});

      return fromRgbaBytes(
        byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
        image.width,
        image.height,
        sampleSize: const Size(80, 80),
        maximumColorCount: maximumColorCount,
      );
    } catch (_) {
      return const PaletteInfo._({});
    }
  }

  /// Extracción síncrona determinista desde bytes `RGBA` (`4` bytes por píxel).
  ///
  /// Ideal para miniaturas de video (`Tezcatl 1.0 Beta`), carátulas de audio
  /// y pruebas unitarias sin depender de `ui.Image`.
  static PaletteInfo fromRgbaBytes(
    Uint8List rgba,
    int width,
    int height, {
    Size sampleSize = const Size(80, 80),
    int maximumColorCount = 8,
    bool trimUniformBorders = true,
  }) {
    if (width <= 0 || height <= 0 || rgba.length < width * height * 4) {
      return const PaletteInfo._({});
    }

    final bounds = trimUniformBorders
        ? _trimUniformEdges(rgba, width, height)
        : _RectInt(0, 0, width, height);

    final bins = _quantizeRegion(
      rgba,
      width: width,
      bounds: bounds,
      sampleSize: sampleSize,
    );
    if (bins.isEmpty) return const PaletteInfo._({});

    final palette = _selectRoles(bins, math.max(1, maximumColorCount));
    return PaletteInfo._(palette);
  }

  /// Obtiene el color principal para acentos o fondos adaptativos.
  static Future<Color> getDominantColor(ImageProvider provider) async {
    final palette = await fromImageProvider(provider);
    return palette.dominantColor?.color ?? AppColor.getMain();
  }

  static Future<ImageInfo> _getImageInfo(ImageProvider provider) {
    final completer = Completer<ImageInfo>();
    final stream = provider.resolve(const ImageConfiguration());
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.complete(info);
      },
      onError: (Object error, StackTrace? stackTrace) {
        stream.removeListener(listener);
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      },
    );
    stream.addListener(listener);
    return completer.future;
  }

  /// Recorta barras uniformes (`letterbox`/`pillarbox`) hasta 20% por borde.
  static _RectInt _trimUniformEdges(Uint8List rgba, int width, int height) {
    if (width < 8 || height < 8) return _RectInt(0, 0, width, height);

    final maxTrimX = (width * 0.20).floor();
    final maxTrimY = (height * 0.20).floor();

    bool isUniformRow(int y) {
      final base = y * width * 4;
      final r0 = rgba[base];
      final g0 = rgba[base + 1];
      final b0 = rgba[base + 2];
      final step = math.max(1, width ~/ 16);
      for (var x = step; x < width; x += step) {
        final idx = base + x * 4;
        if ((rgba[idx] - r0).abs() > 14 ||
            (rgba[idx + 1] - g0).abs() > 14 ||
            (rgba[idx + 2] - b0).abs() > 14) {
          return false;
        }
      }
      return true;
    }

    bool isUniformCol(int x, int top, int bottom) {
      final base = (top * width + x) * 4;
      final r0 = rgba[base];
      final g0 = rgba[base + 1];
      final b0 = rgba[base + 2];
      final span = bottom - top;
      final step = math.max(1, span ~/ 16);
      for (var y = top + step; y < bottom; y += step) {
        final idx = (y * width + x) * 4;
        if ((rgba[idx] - r0).abs() > 14 ||
            (rgba[idx + 1] - g0).abs() > 14 ||
            (rgba[idx + 2] - b0).abs() > 14) {
          return false;
        }
      }
      return true;
    }

    var top = 0;
    while (top < maxTrimY && isUniformRow(top)) {
      top++;
    }
    var bottom = height;
    while (height - bottom < maxTrimY && bottom - 1 > top && isUniformRow(bottom - 1)) {
      bottom--;
    }
    // Si toda la imagen es uniforme, conservar el área completa.
    if (top == maxTrimY && height - bottom == maxTrimY) {
      final midY = height ~/ 2;
      if (isUniformRow(midY)) {
        top = 0;
        bottom = height;
      }
    }

    var left = 0;
    while (left < maxTrimX && isUniformCol(left, top, bottom)) {
      left++;
    }
    var right = width;
    while (width - right < maxTrimX &&
        right - 1 > left &&
        isUniformCol(right - 1, top, bottom)) {
      right--;
    }
    if (left == maxTrimX && width - right == maxTrimX) {
      final midX = width ~/ 2;
      if (isUniformCol(midX, top, bottom)) {
        left = 0;
        right = width;
      }
    }

    final trimmedW = right - left;
    final trimmedH = bottom - top;
    if (trimmedW <= 0 || trimmedH <= 0) return _RectInt(0, 0, width, height);
    return _RectInt(left, top, trimmedW, trimmedH);
  }

  static List<_OkSwatch> _quantizeRegion(
    Uint8List rgba, {
    required int width,
    required _RectInt bounds,
    required Size sampleSize,
  }) {
    final targetW = sampleSize.width.toInt().clamp(1, bounds.width);
    final targetH = sampleSize.height.toInt().clamp(1, bounds.height);
    final stepX = bounds.width / targetW;
    final stepY = bounds.height / targetH;

    // Agrupación fina de 5 bits por canal (32x32x32) acumulando promedios reales RGB.
    final accumulators = <int, _RgbAccumulator>{};

    for (var sy = 0; sy < targetH; sy++) {
      final py = bounds.top + (sy * stepY).floor().clamp(0, bounds.height - 1);
      final rowOffset = py * width * 4;
      for (var sx = 0; sx < targetW; sx++) {
        final px = bounds.left + (sx * stepX).floor().clamp(0, bounds.width - 1);
        final idx = rowOffset + px * 4;
        final a = rgba[idx + 3];
        if (a <= 128) continue;

        final r = rgba[idx];
        final g = rgba[idx + 1];
        final b = rgba[idx + 2];

        final key = ((r >> 3) << 10) | ((g >> 3) << 5) | (b >> 3);
        (accumulators[key] ??= _RgbAccumulator()).add(r, g, b);
      }
    }

    if (accumulators.isEmpty) return const [];

    final rawSwatches = accumulators.values.map((acc) => acc.toOkSwatch()).toList()
      ..sort((a, b) => b.population.compareTo(a.population));

    // Fusión perceptual en espacio OKLab (ΔE_OK < 0.055) para eliminar duplicados visuales.
    final merged = <_OkSwatch>[];
    for (final candidate in rawSwatches) {
      var absorbed = false;
      for (var i = 0; i < merged.length; i++) {
        if (merged[i].distanceTo(candidate) < 0.055) {
          merged[i] = merged[i].mergeWith(candidate);
          absorbed = true;
          break;
        }
      }
      if (!absorbed) merged.add(candidate);
    }

    merged.sort((a, b) => b.population.compareTo(a.population));
    return merged;
  }

  static Map<PaletteColorType, PaletteColor> _selectRoles(
    List<_OkSwatch> swatches,
    int maximumColorCount,
  ) {
    final pool = swatches.take(math.max(maximumColorCount * 2, 12)).toList();
    if (pool.isEmpty) return const {};

    final totalPop = pool.fold<int>(0, (sum, s) => sum + s.population);
    final result = <PaletteColorType, PaletteColor>{
      PaletteColorType.dominant: pool.first.toPaletteColor(),
    };

    _OkSwatch? pickBest({
      required double minL,
      required double maxL,
      required double targetL,
      required double minC,
      required double maxC,
      required double targetC,
      required bool penalizeSkinTone,
      Set<int> usedRgb = const {},
    }) {
      _OkSwatch? best;
      var bestScore = -1.0;

      for (final s in pool) {
        if (usedRgb.contains(s.rgbKey)) continue;
        if (s.l < minL || s.l > maxL || s.chroma < minC || s.chroma > maxC) {
          continue;
        }

        final lSpan = math.max(0.05, math.max(targetL - minL, maxL - targetL));
        final cSpan = math.max(0.04, math.max(targetC - minC, maxC - targetC));
        final lScore = (1.0 - (s.l - targetL).abs() / lSpan).clamp(0.0, 1.0);
        final cScore = (1.0 - (s.chroma - targetC).abs() / cSpan).clamp(0.0, 1.0);
        final popScore = math.sqrt(s.population / math.max(1, totalPop));

        var score = cScore * 0.48 + lScore * 0.30 + popScore * 0.22;
        if (penalizeSkinTone && s.isLikelySkinTone) {
          score *= 0.55;
        }

        if (score > bestScore) {
          bestScore = score;
          best = s;
        }
      }
      return best;
    }

    final used = <int>{};
    void assign(PaletteColorType role, _OkSwatch? swatch) {
      if (swatch == null) return;
      result[role] = swatch.toPaletteColor();
      used.add(swatch.rgbKey);
    }

    assign(
      PaletteColorType.vibrant,
      pickBest(
        minL: 0.40,
        maxL: 0.80,
        targetL: 0.60,
        minC: 0.085,
        maxC: 0.40,
        targetC: 0.20,
        penalizeSkinTone: true,
        usedRgb: used,
      ),
    );
    assign(
      PaletteColorType.lightVibrant,
      pickBest(
        minL: 0.70,
        maxL: 0.96,
        targetL: 0.82,
        minC: 0.075,
        maxC: 0.40,
        targetC: 0.16,
        penalizeSkinTone: true,
        usedRgb: used,
      ),
    );
    assign(
      PaletteColorType.darkVibrant,
      pickBest(
        minL: 0.16,
        maxL: 0.46,
        targetL: 0.32,
        minC: 0.070,
        maxC: 0.40,
        targetC: 0.16,
        penalizeSkinTone: true,
        usedRgb: used,
      ),
    );
    assign(
      PaletteColorType.muted,
      pickBest(
        minL: 0.38,
        maxL: 0.76,
        targetL: 0.56,
        minC: 0.0,
        maxC: 0.085,
        targetC: 0.04,
        penalizeSkinTone: false,
        usedRgb: used,
      ),
    );
    assign(
      PaletteColorType.lightMuted,
      pickBest(
        minL: 0.72,
        maxL: 0.98,
        targetL: 0.85,
        minC: 0.0,
        maxC: 0.080,
        targetC: 0.03,
        penalizeSkinTone: false,
        usedRgb: used,
      ),
    );
    assign(
      PaletteColorType.darkMuted,
      pickBest(
        minL: 0.06,
        maxL: 0.42,
        targetL: 0.24,
        minC: 0.0,
        maxC: 0.080,
        targetC: 0.03,
        penalizeSkinTone: false,
        usedRgb: used,
      ),
    );

    return result;
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

final class _RectInt {
  final int left;
  final int top;
  final int width;
  final int height;

  const _RectInt(this.left, this.top, this.width, this.height);
}

final class _RgbAccumulator {
  int sumR = 0;
  int sumG = 0;
  int sumB = 0;
  int count = 0;

  void add(int r, int g, int b) {
    sumR += r;
    sumG += g;
    sumB += b;
    count++;
  }

  _OkSwatch toOkSwatch() {
    final r = (sumR / count).round().clamp(0, 255);
    final g = (sumG / count).round().clamp(0, 255);
    final b = (sumB / count).round().clamp(0, 255);
    return _OkSwatch.fromRgb(r, g, b, count);
  }
}

final class _OkSwatch {
  final int r;
  final int g;
  final int b;
  final int population;
  final double l;
  final double a;
  final double bOk;

  const _OkSwatch({
    required this.r,
    required this.g,
    required this.b,
    required this.population,
    required this.l,
    required this.a,
    required this.bOk,
  });

  factory _OkSwatch.fromRgb(int r, int g, int b, int population) {
    final rl = _srgbToLinear(r / 255.0);
    final gl = _srgbToLinear(g / 255.0);
    final bl = _srgbToLinear(b / 255.0);

    final lCone = 0.4122214708 * rl + 0.5363325363 * gl + 0.0514459929 * bl;
    final mCone = 0.2119034982 * rl + 0.6806995451 * gl + 0.1073969566 * bl;
    final sCone = 0.0883024619 * rl + 0.2817188376 * gl + 0.6299787005 * bl;

    final lRoot = _cbrt(lCone);
    final mRoot = _cbrt(mCone);
    final sRoot = _cbrt(sCone);

    return _OkSwatch(
      r: r,
      g: g,
      b: b,
      population: population,
      l: 0.2104542553 * lRoot + 0.7936177850 * mRoot - 0.0040720468 * sRoot,
      a: 1.9779984951 * lRoot - 2.4285922050 * mRoot + 0.4505937099 * sRoot,
      bOk: 0.0259040371 * lRoot + 0.7827717662 * mRoot - 0.8086757660 * sRoot,
    );
  }

  int get rgbKey => (r << 16) | (g << 8) | b;

  double get chroma => math.sqrt(a * a + bOk * bOk);

  double get hueDegrees {
    var deg = math.atan2(bOk, a) * (180.0 / math.pi);
    if (deg < 0) deg += 360.0;
    return deg;
  }

  /// Detecta banda estrecha de tonos piel en `OKLab` para evitar botones durazno apagados
  /// cuando existe un acento gráfico real en la portada.
  bool get isLikelySkinTone {
    final c = chroma;
    if (l < 0.42 || l > 0.85 || c < 0.03 || c > 0.13) return false;
    final h = hueDegrees;
    return h >= 35.0 && h <= 75.0;
  }

  double distanceTo(_OkSwatch other) {
    final dl = l - other.l;
    final da = a - other.a;
    final db = bOk - other.bOk;
    return math.sqrt(dl * dl + da * da + db * db);
  }

  _OkSwatch mergeWith(_OkSwatch other) {
    final total = population + other.population;
    final nr = ((r * population + other.r * other.population) / total).round();
    final ng = ((g * population + other.g * other.population) / total).round();
    final nb = ((b * population + other.b * other.population) / total).round();
    return _OkSwatch.fromRgb(nr, ng, nb, total);
  }

  PaletteColor toPaletteColor() =>
      PaletteColor(Color.fromARGB(255, r, g, b), population);

  static double _srgbToLinear(double c) =>
      c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

  static double _cbrt(double x) =>
      x <= 0.0 ? 0.0 : math.pow(x, 1.0 / 3.0).toDouble();
}
