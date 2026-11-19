import 'package:flutter/widgets.dart';

import 'youtube_preview_embed_io.dart'
    if (dart.library.js_interop) 'youtube_preview_embed_web.dart' as impl;

/// Validates and extracts an 11-character YouTube video ID from either a raw
/// video ID or a YouTube / YouTube Music URL (`watch?v=`, `youtu.be/`, `embed/`).
String extractYoutubeVideoId(String idOrUrl) {
  final raw = idOrUrl.trim();
  if (raw.isEmpty) return '';

  final directId = RegExp(r'^[A-Za-z0-9_-]{11}$');
  if (directId.hasMatch(raw)) return raw;

  final uri = Uri.tryParse(raw);
  if (uri == null) return '';

  final host = uri.host.toLowerCase();
  if (host == 'youtu.be' && uri.pathSegments.isNotEmpty) {
    final candidate = uri.pathSegments.first;
    return directId.hasMatch(candidate) ? candidate : '';
  }

  if (host.endsWith('youtube.com')) {
    final v = uri.queryParameters['v']?.trim() ?? '';
    if (directId.hasMatch(v)) return v;
    if (uri.pathSegments.length >= 2 &&
        (uri.pathSegments[0] == 'embed' || uri.pathSegments[0] == 'shorts')) {
      final candidate = uri.pathSegments[1];
      if (directId.hasMatch(candidate)) return candidate;
    }
  }

  return '';
}

/// Builds the official YouTube IFrame Embed URL constrained strictly to a
/// 30-second preview window (`start`..`end`) for musician repertoire matching.
String buildYoutubePreviewEmbedUrl(
  String videoId, {
  int startSeconds = 30,
  int durationSeconds = 30,
}) {
  final safeId = extractYoutubeVideoId(videoId);
  if (safeId.isEmpty) return '';
  final safeStart = startSeconds < 0 ? 0 : startSeconds;
  final safeEnd = safeStart + durationSeconds.clamp(5, 30);
  return 'https://www.youtube.com/embed/$safeId'
      '?autoplay=1'
      '&start=$safeStart'
      '&end=$safeEnd'
      '&controls=1'
      '&modestbranding=1'
      '&rel=0'
      '&fs=0'
      '&playsinline=1';
}

/// Platform-aware official YouTube IFrame Embed constrained to a preview clip.
Widget buildYoutubePreviewEmbed({
  required String videoId,
  required int startSeconds,
  required int previewSeconds,
  required String fallbackImgUrl,
}) {
  return impl.buildYoutubePreviewEmbedImpl(
    videoId: videoId,
    startSeconds: startSeconds,
    previewSeconds: previewSeconds,
    fallbackImgUrl: fallbackImgUrl,
  );
}
