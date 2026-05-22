import 'package:flutter/material.dart';

import '../../../utils/palette_utilities.dart';
import '../../theme/app_color.dart';
import 'handled_cached_network_image.dart';

/// An image widget that extracts the dominant color on load and
/// exposes it via [onColorExtracted].
///
/// Wraps [HandledCachedNetworkImage] with an opt-in color extraction
/// pass using [PaletteGenerator]. Modules can use the extracted color
/// for dynamic header tints, gradient backgrounds, or accent styling
/// without depending on neom_audio_player's ArtworkColorController.
///
/// The extraction runs once per [imageUrl] and caches results in a
/// module-scoped static map (max 50 entries).
class ArtworkColorAwareImage extends StatefulWidget {

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final ValueChanged<Color>? onColorExtracted;

  const ArtworkColorAwareImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.onColorExtracted,
  });

  @override
  State<ArtworkColorAwareImage> createState() => _ArtworkColorAwareImageState();

}

class _ArtworkColorAwareImageState extends State<ArtworkColorAwareImage> {

  static final Map<String, Color> _cache = {};
  static const int _maxCacheSize = 50;

  @override
  void initState() {
    super.initState();
    if (widget.onColorExtracted != null && widget.imageUrl.isNotEmpty) {
      _extractColor();
    }
  }

  @override
  void didUpdateWidget(covariant ArtworkColorAwareImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl &&
        widget.onColorExtracted != null &&
        widget.imageUrl.isNotEmpty) {
      _extractColor();
    }
  }

  Future<void> _extractColor() async {
    final url = widget.imageUrl;

    // Check cache first
    final cached = _cache[url];
    if (cached != null) {
      widget.onColorExtracted?.call(cached);
      return;
    }

    try {
      final palette = await PaletteUtilities.fromImageProvider(
        NetworkImage(url),
        size: const Size(80, 80),
        maximumColorCount: 8,
      );
      final color = palette.vibrantColor?.color
          ?? palette.dominantColor?.color
          ?? palette.mutedColor?.color
          ?? AppColor.getMain();

      // Enforce cache limit
      if (_cache.length >= _maxCacheSize) {
        _cache.remove(_cache.keys.first);
      }
      _cache[url] = color;

      if (mounted) {
        widget.onColorExtracted?.call(color);
      }
    } catch (_) {
      // Silently use fallback — image may not be loadable
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = HandledCachedNetworkImage(
      widget.imageUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      enableFullScreen: false,
    );

    if (widget.borderRadius != null) {
      return ClipRRect(
        borderRadius: widget.borderRadius!,
        child: child,
      );
    }
    return child;
  }

  /// Clears the static color cache. Intended for tests or memory pressure.
  static void clearCache() => _cache.clear();


}
