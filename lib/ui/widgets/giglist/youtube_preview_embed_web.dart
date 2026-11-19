import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

import 'youtube_preview_embed.dart';

int _nextEmbedId = 0;

JSObject? _createIframeElement(String embedUrl) {
  final doc = globalContext['document'];
  if (doc == null || !doc.isA<JSObject>()) return null;
  final iframeAny = (doc as JSObject).callMethod<JSAny?>(
    'createElement'.toJS,
    'iframe'.toJS,
  );
  if (iframeAny == null || !iframeAny.isA<JSObject>()) return null;
  final iframe = iframeAny as JSObject;
  iframe['src'] = embedUrl.toJS;
  iframe['allow'] = 'autoplay; encrypted-media; picture-in-picture'.toJS;
  iframe['referrerPolicy'] = 'strict-origin-when-cross-origin'.toJS;
  iframe.callMethod<JSAny?>(
    'setAttribute'.toJS,
    'frameborder'.toJS,
    '0'.toJS,
  );
  final styleAny = iframe['style'];
  if (styleAny != null && styleAny.isA<JSObject>()) {
    final style = styleAny as JSObject;
    style['width'] = '100%'.toJS;
    style['height'] = '100%'.toJS;
    style['border'] = '0'.toJS;
    style['display'] = 'block'.toJS;
    style['borderRadius'] = '12px'.toJS;
  }
  return iframe;
}

Widget buildYoutubePreviewEmbedImpl({
  required String videoId,
  required int startSeconds,
  required int previewSeconds,
  required String fallbackImgUrl,
}) {
  final embedUrl = buildYoutubePreviewEmbedUrl(
    videoId,
    startSeconds: startSeconds,
    durationSeconds: previewSeconds,
  );
  if (embedUrl.isEmpty) {
    return const Center(
      child: Icon(Icons.music_note_rounded, color: Colors.white54, size: 48),
    );
  }

  return _WebYoutubeIframe(embedUrl: embedUrl);
}

class _WebYoutubeIframe extends StatefulWidget {
  final String embedUrl;

  const _WebYoutubeIframe({required this.embedUrl});

  @override
  State<_WebYoutubeIframe> createState() => _WebYoutubeIframeState();
}

class _WebYoutubeIframeState extends State<_WebYoutubeIframe> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'neom-yt-preview-${++_nextEmbedId}';
    final url = widget.embedUrl;
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int _) {
      return _createIframeElement(url) ?? JSObject();
    });
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
