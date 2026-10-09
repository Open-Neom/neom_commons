import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:neom_core/app_properties.dart';
import 'package:url_launcher/url_launcher.dart';

import 'legal_document_data.dart';

enum LegalDocument {
  terms('assets/legal/terms_conditions.md', 'Términos y condiciones'),
  accountDeletion(
    'assets/legal/account_deletion.md',
    'Eliminar cuenta y datos',
  );

  final String asset;
  final String title;
  const LegalDocument(this.asset, this.title);
}

/// Public information only: never signs out or deletes an account.
class LegalPage extends StatefulWidget {
  final LegalDocument document;
  const LegalPage({super.key, required this.document});

  @override
  State<LegalPage> createState() => _LegalPageState();
}

class _LegalPageState extends State<LegalPage> {
  AssetBundle? _bundle;
  LegalDocumentData? _data;
  String? _content;
  bool _failed = false;
  int _loadVersion = 0;
  final Map<String, GlobalKey> _headings = {};
  final Map<String, GlobalKey> _headingKeys = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bundle = DefaultAssetBundle.of(context);
    if (!identical(bundle, _bundle)) {
      _bundle = bundle;
      _load();
    }
  }

  @override
  void didUpdateWidget(covariant LegalPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.document != widget.document) _load();
  }

  Future<void> _load() async {
    final version = ++_loadVersion;
    _content = null;
    _failed = false;
    try {
      final bundle = _bundle!;
      final markdown = await bundle.loadString(widget.document.asset);
      String? metadata;
      try {
        metadata = await bundle.loadString('assets/privacy_policy.json');
      } on FlutterError {
        // Older host apps may not bundle public legal metadata yet.
      }
      final properties = AppProperties.appProperties;
      String property(String name) =>
          properties is Map && properties[name] is String
          ? (properties[name] as String)
          : '';
      final data = LegalDocumentData.fromSources(
        metadataJson: metadata,
        privacyPolicyUrl: property('privacyPolicyUrl'),
        fallbackAppName: property('appName'),
        fallbackContactEmail: metadata == null ? property('contactEmail') : '',
        fallbackSiteUrl: property('siteUrl').trim().isNotEmpty
            ? property('siteUrl')
            : property('landingPageUrl'),
      );
      final content = data.render(markdown);
      if (!mounted || version != _loadVersion) return;
      setState(() {
        _data = data;
        _content = content;
        _headings.clear();
        _headingKeys.clear();
      });
    } catch (_) {
      if (!mounted || version != _loadVersion) return;
      setState(() => _failed = true);
    }
  }

  Future<void> _openLink(Uri uri) async {
    if (uri.scheme.isEmpty && uri.hasFragment) {
      final target = _headings[uri.fragment]?.currentContext;
      if (target != null) {
        await Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 200),
        );
      }
      return;
    }
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.platformDefault);
      if (!opened && mounted) _linkFailure();
    } catch (_) {
      if (mounted) _linkFailure();
    }
  }

  void _linkFailure() => ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('No se pudo abrir el enlace.')));

  @override
  Widget build(BuildContext context) {
    final background = Color(_data?.themeColor ?? 0xff111c41);
    final foreground =
        ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? Colors.white
        : Colors.black87;
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: foreground,
        title: Text(widget.document.title),
      ),
      body: _failed
          ? Center(
              child: Text(
                'No se pudo cargar este documento.',
                style: TextStyle(color: foreground),
              ),
            )
          : _content == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _blocks(foreground),
                  ),
                ),
              ),
            ),
    );
  }

  List<Widget> _blocks(Color foreground) {
    final widgets = <Widget>[];
    final anchorsUsed = <String>{};
    _headings.clear();
    for (final line in _content!.split('\n')) {
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 10));
        continue;
      }
      final heading = RegExp(r'^(#{1,3})\s+(.+)$').firstMatch(line);
      final bullet = RegExp(r'^(?:- |\d+\. )').firstMatch(line);
      var text = heading?.group(2) ?? line;
      GlobalKey? key;
      if (heading != null) {
        final base = legalHeadingAnchor(text);
        var anchor = base;
        var suffix = 2;
        while (!anchorsUsed.add(anchor)) {
          anchor = '$base-${suffix++}';
        }
        key = _headingKeys.putIfAbsent(anchor, GlobalKey.new);
        _headings[anchor] = key;
        final unnumbered = legalHeadingAnchor(
          text.replaceFirst(RegExp(r'^\d+\.\s*'), ''),
        );
        _headings.putIfAbsent(unnumbered, () => key!);
      } else if (bullet != null) {
        text = line.substring(bullet.end);
      }
      final inline = _LegalInlineText(
        text: text,
        onLink: _openLink,
        style: TextStyle(
          color: foreground,
          fontSize: heading == null
              ? 16
              : (heading.group(1)!.length == 1 ? 26 : 21),
          fontWeight: heading == null ? FontWeight.normal : FontWeight.bold,
          height: 1.55,
        ),
      );
      widgets.add(
        Padding(
          key: key,
          padding: EdgeInsets.only(top: heading == null ? 2 : 16, bottom: 6),
          child: bullet == null || heading != null
              ? inline
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.startsWith('- ') ? '•  ' : '${bullet.group(0)} ',
                      style: TextStyle(
                        color: foreground,
                        fontSize: 16,
                        height: 1.55,
                      ),
                    ),
                    Expanded(child: inline),
                  ],
                ),
        ),
      );
    }
    return widgets;
  }
}

class _LegalInlineText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final ValueChanged<Uri> onLink;
  const _LegalInlineText({
    required this.text,
    required this.style,
    required this.onLink,
  });

  @override
  State<_LegalInlineText> createState() => _LegalInlineTextState();
}

class _LegalInlineTextState extends State<_LegalInlineText> {
  final List<TapGestureRecognizer> _recognizers = [];
  late List<InlineSpan> _spans;

  @override
  void initState() {
    super.initState();
    _parse();
  }

  @override
  void didUpdateWidget(covariant _LegalInlineText oldWidget) {
    super.didUpdateWidget(oldWidget);
    _parse();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  void _parse() {
    _disposeRecognizers();
    _spans = [];
    final pattern = RegExp(r'\[([^\]]+)\]\(([^)\s]+)\)|\*\*(.+?)\*\*');
    var offset = 0;
    for (final match in pattern.allMatches(widget.text)) {
      if (match.start > offset) {
        _spans.add(TextSpan(text: widget.text.substring(offset, match.start)));
      }
      if (match.group(3) != null) {
        _spans.add(
          TextSpan(
            text: match.group(3),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      } else {
        final uri = legalLinkUri(match.group(2)!);
        TapGestureRecognizer? recognizer;
        if (uri != null) {
          recognizer = TapGestureRecognizer()..onTap = () => widget.onLink(uri);
          _recognizers.add(recognizer);
        }
        _spans.add(
          TextSpan(
            text: match.group(1),
            recognizer: recognizer,
            style: uri == null
                ? null
                : const TextStyle(
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w600,
                  ),
          ),
        );
      }
      offset = match.end;
    }
    if (offset < widget.text.length) {
      _spans.add(TextSpan(text: widget.text.substring(offset)));
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Text.rich(TextSpan(style: widget.style, children: _spans));
}
