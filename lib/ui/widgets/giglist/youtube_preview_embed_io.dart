import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../custom_image.dart';
import 'youtube_preview_embed.dart';

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

  final supportsMobileWebView =
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  if (embedUrl.isEmpty || !supportsMobileWebView) {
    return _DesktopPreviewFallback(
      fallbackImgUrl: fallbackImgUrl,
      videoId: videoId,
    );
  }

  return _MobileYoutubePreviewWebView(
    embedUrl: embedUrl,
    fallbackImgUrl: fallbackImgUrl,
  );
}

class _MobileYoutubePreviewWebView extends StatefulWidget {
  final String embedUrl;
  final String fallbackImgUrl;

  const _MobileYoutubePreviewWebView({
    required this.embedUrl,
    required this.fallbackImgUrl,
  });

  @override
  State<_MobileYoutubePreviewWebView> createState() =>
      _MobileYoutubePreviewWebViewState();
}

class _MobileYoutubePreviewWebViewState
    extends State<_MobileYoutubePreviewWebView> {
  WebViewController? _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    try {
      final ctrl = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.black)
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (request) {
              final uri = Uri.tryParse(request.url);
              final host = uri?.host.toLowerCase() ?? '';
              // Keep the user strictly inside the official YouTube embed frame.
              if (host == 'www.youtube.com' &&
                  (uri?.path.startsWith('/embed/') ?? false)) {
                return NavigationDecision.navigate;
              }
              if (host.endsWith('googlevideo.com') ||
                  host.endsWith('ytimg.com') ||
                  host == 'about:blank') {
                return NavigationDecision.navigate;
              }
              return NavigationDecision.prevent;
            },
            onWebResourceError: (_) {
              if (mounted) setState(() => _hasError = true);
            },
          ),
        )
        ..loadRequest(
          Uri.parse(widget.embedUrl),
          headers: const {'Referer': 'https://www.gigmeout.com/'},
        );
      _controller = ctrl;
    } catch (_) {
      _hasError = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError || _controller == null) {
      return _DesktopPreviewFallback(
        fallbackImgUrl: widget.fallbackImgUrl,
        videoId: '',
      );
    }
    return WebViewWidget(controller: _controller!);
  }
}

class _DesktopPreviewFallback extends StatelessWidget {
  final String fallbackImgUrl;
  final String videoId;

  const _DesktopPreviewFallback({
    required this.fallbackImgUrl,
    required this.videoId,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (fallbackImgUrl.isNotEmpty)
          platformNetworkImage(
            imageUrl: fallbackImgUrl,
            fit: BoxFit.cover,
          )
        else
          Container(color: Colors.black54),
        Container(
          color: Colors.black.withValues(alpha: 0.55),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(16),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.ondemand_video_rounded, color: Colors.redAccent, size: 42),
              SizedBox(height: 8),
              Text(
                'Preview de referencia (YouTube Music)',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
