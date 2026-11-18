import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../utils/external_utilities.dart';
import '../../utils/url_utilities.dart';

class UrlText extends StatefulWidget {
  static const int maxScanLength = 8192;

  static final RegExp _tokenRegExp = RegExp(
    r'#[A-Za-z0-9_\u00C0-\u024F]{1,100}|(?<=^|\s)@[A-Za-z0-9_.]{1,64}|https?://[-A-Za-z0-9+&@#/%?=~_|!:,.;]*[-A-Za-z0-9+&@#/%=~_|]',
  );

  final String text;
  final TextStyle? style;
  final TextStyle? urlStyle;
  final Function(String)? onHashTagPressed;

  const UrlText({
    this.text = '',
    this.style,
    this.urlStyle,
    this.onHashTagPressed,
    super.key,
  });

  List<InlineSpan> getTextSpans({List<TapGestureRecognizer>? gesturePool}) {
    if (text.isEmpty) return const <InlineSpan>[];
    final source = text.length > maxScanLength
        ? text.substring(0, maxScanLength)
        : text;
    final String overflowTail = text.length > maxScanLength
        ? text.substring(maxScanLength)
        : '';

    final widgets = <InlineSpan>[];
    final matches = _tokenRegExp.allMatches(source);
    final resultMatches = <_ResultMatch>[];
    int start = 0;
    for (final match in matches) {
      final token = match.group(0);
      if (token != null && token.isNotEmpty) {
        if (start != match.start) {
          resultMatches.add(
            _ResultMatch(
              isUrl: false,
              text: source.substring(start, match.start),
            ),
          );
        }
        resultMatches.add(_ResultMatch(isUrl: true, text: token));
        start = match.end;
      }
    }
    if (start < source.length) {
      resultMatches.add(
        _ResultMatch(
          isUrl: false,
          text: '${source.substring(start)}$overflowTail',
        ),
      );
    } else if (overflowTail.isNotEmpty) {
      resultMatches.add(_ResultMatch(isUrl: false, text: overflowTail));
    }

    final resolvedPlainStyle = style ?? const TextStyle(color: Colors.black);
    final resolvedUrlStyle =
        urlStyle ?? const TextStyle(color: Colors.lightBlueAccent);

    for (final result in resultMatches) {
      if (!result.isUrl) {
        widgets.add(TextSpan(text: result.text, style: resolvedPlainStyle));
        continue;
      }

      final token = result.text.trim();
      final isTagOrMention =
          token.startsWith('#') || token.startsWith('@');
      final String? safeExternalUrl = isTagOrMention
          ? null
          : UrlUtilities.normalizeSafeExternalUrl(token);

      final bool isInteractive =
          (isTagOrMention && onHashTagPressed != null) ||
              safeExternalUrl != null;

      if (!isInteractive) {
        widgets.add(TextSpan(text: result.text, style: resolvedUrlStyle));
        continue;
      }

      final recognizer = TapGestureRecognizer()
        ..onTap = () {
          if (isTagOrMention) {
            onHashTagPressed?.call(token);
          } else if (safeExternalUrl != null) {
            ExternalUtilities.launchURL(safeExternalUrl);
          }
        };
      gesturePool?.add(recognizer);

      widgets.add(
        TextSpan(
          text: result.text,
          style: resolvedUrlStyle,
          recognizer: recognizer,
        ),
      );
    }
    return widgets;
  }

  @override
  State<UrlText> createState() => _UrlTextState();
}

class _UrlTextState extends State<UrlText> {
  final List<TapGestureRecognizer> _recognizers = <TapGestureRecognizer>[];
  late List<InlineSpan> _spans;

  @override
  void initState() {
    super.initState();
    _spans = widget.getTextSpans(gesturePool: _recognizers);
  }

  @override
  void didUpdateWidget(covariant UrlText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.style != widget.style ||
        oldWidget.urlStyle != widget.urlStyle ||
        oldWidget.onHashTagPressed != widget.onHashTagPressed) {
      _disposeRecognizers();
      _spans = widget.getTextSpans(gesturePool: _recognizers);
    }
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(children: _spans),
    );
  }
}

class _ResultMatch {
  final bool isUrl;
  final String text;

  const _ResultMatch({required this.isUrl, required this.text});
}
