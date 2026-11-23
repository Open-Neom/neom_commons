import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ignore: depend_on_referenced_packages
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

/// Localized copy bundled with the installed app, never fetched remotely.
class ReleaseNoteText {
  const ReleaseNoteText({
    required this.en,
    required this.es,
    required this.de,
    required this.fr,
  });

  final String en;
  final String es;
  final String de;
  final String fr;

  String resolve(Locale locale) => switch (locale.languageCode) {
    'es' => es,
    'de' => de,
    'fr' => fr,
    _ => en,
  };
}

class ReleaseNoteItem {
  const ReleaseNoteItem({required this.title, required this.body});

  final ReleaseNoteText title;
  final ReleaseNoteText body;
}

/// [revision] identifies this bundled set of notes, including local changes
/// shipped before the next public version number. Bump it when copy changes.
class AppReleaseNotes {
  const AppReleaseNotes({
    required this.revision,
    required this.date,
    required this.items,
  });

  final String revision;
  final String date;
  final List<ReleaseNoteItem> items;
}

abstract interface class AppReleaseNotesPreferences {
  Future<bool> wasSeen(String key);
  Future<void> markSeen(String key);
}

class HiveAppReleaseNotesPreferences implements AppReleaseNotesPreferences {
  const HiveAppReleaseNotesPreferences();

  static const boxName = 'app_release_notes';

  Future<Box<dynamic>?> _boxGuarded() {
    if (Hive.isBoxOpen(boxName)) {
      return Future<Box<dynamic>?>.value(Hive.box<dynamic>(boxName));
    }
    final done = Completer<Box<dynamic>?>();
    runZonedGuarded(
      () async {
        try {
          final opened = await Hive.openBox<dynamic>(boxName);
          if (!done.isCompleted) done.complete(opened);
        } catch (_) {
          if (!done.isCompleted) done.complete(null);
        }
      },
      (Object _, StackTrace _) {
        if (!done.isCompleted) done.complete(null);
      },
    );
    return done.future;
  }

  @override
  Future<bool> wasSeen(String key) async {
    final box = await _boxGuarded();
    if (box == null) return false;
    final receipt = box.get(key);
    return receipt is Map && receipt['firstShownAt'] is num;
  }

  @override
  Future<void> markSeen(String key) async {
    final box = await _boxGuarded();
    if (box == null) return;
    final previous = box.get(key);
    final now = DateTime.now().millisecondsSinceEpoch;
    await box.put(key, {
      'firstShownAt': previous is Map ? previous['firstShownAt'] ?? now : now,
      'lastSeenAt': now,
    });
  }
}

/// Wrap the app's navigation root in its builder. Automatically offers bundled
/// notes once per app/version/revision when [autoShow] is enabled by the host.
/// No update checks, downloads, project edits or account access are performed.
class AppReleaseNotesHost extends StatefulWidget {
  const AppReleaseNotesHost({
    super.key,
    required this.appId,
    required this.appName,
    required this.version,
    required this.release,
    required this.child,
    this.locale,
    this.autoShow = false,
    this.preferences = const HiveAppReleaseNotesPreferences(),
  });

  final String appId;
  final String appName;
  final String version;
  final AppReleaseNotes release;
  final Widget child;
  final Locale? locale;
  final bool autoShow;
  final AppReleaseNotesPreferences preferences;

  static bool isAvailable(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ReleaseNotesScope>() != null;

  /// Includes the initial preference check, so first-run tutorials can wait
  /// until release notes have either been dismissed or were already seen.
  static bool isShowing(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_ReleaseNotesScope>()
          ?.blocking ??
      false;

  static void show(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_ReleaseNotesScope>()?.state.open();

  static String label(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_ReleaseNotesScope>();
    return _label.resolve(scope?.locale ?? Localizations.localeOf(context));
  }

  static const _label = ReleaseNoteText(
    en: "What's new",
    es: 'Novedades',
    de: 'Neuigkeiten',
    fr: 'Nouveautés',
  );

  @override
  State<AppReleaseNotesHost> createState() => _AppReleaseNotesHostState();
}

class _AppReleaseNotesHostState extends State<AppReleaseNotesHost> {
  final _focus = FocusNode(debugLabel: 'Release notes');
  bool _visible = false;
  bool _checking = false;
  int _generation = 0;

  String get _receiptKey =>
      '${widget.appId}:${widget.version}:${widget.release.revision}';

  @override
  void initState() {
    super.initState();
    _checking = widget.autoShow;
    WidgetsBinding.instance.addPostFrameCallback((_) => _offer());
  }

  @override
  void didUpdateWidget(covariant AppReleaseNotesHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.appId != widget.appId ||
        oldWidget.version != widget.version ||
        oldWidget.release.revision != widget.release.revision ||
        (!oldWidget.autoShow && widget.autoShow)) {
      _generation++;
      _checking = widget.autoShow;
      WidgetsBinding.instance.addPostFrameCallback((_) => _offer());
    } else if (oldWidget.autoShow && !widget.autoShow) {
      _generation++;
      _checking = false;
    }
  }

  Future<void> _offer() async {
    if (!mounted || !widget.autoShow || _visible) return;
    final generation = _generation;
    var seen = false;
    try {
      seen = await widget.preferences.wasSeen(_receiptKey);
    } catch (_) {
      // Unavailable preferences never prevent access to the app or the notes.
    }
    if (!mounted || generation != _generation) return;
    setState(() => _checking = false);
    if (!seen) open();
  }

  void open() {
    if (!mounted || _visible) return;
    _generation++;
    setState(() {
      _visible = true;
      _checking = false;
    });
    final key = _receiptKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_visible || key != _receiptKey) return;
      _focus.requestFocus();
      unawaited(_remember(key));
    });
  }

  Future<void> _remember(String key) async {
    try {
      await widget.preferences.markSeen(key);
    } catch (_) {
      // A storage failure must not trap the user in this informational dialog.
    }
  }

  void _close() {
    _generation++;
    _focus.unfocus();
    setState(() {
      _visible = false;
      _checking = false;
    });
  }

  @override
  void dispose() {
    _generation++;
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = widget.locale ?? Localizations.localeOf(context);
    final close = const ReleaseNoteText(
      en: 'Continue',
      es: 'Continuar',
      de: 'Weiter',
      fr: 'Continuer',
    ).resolve(locale);
    return _ReleaseNotesScope(
      state: this,
      blocking: _checking || _visible,
      locale: locale,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ExcludeFocus(
            excluding: _visible,
            child: ExcludeSemantics(excluding: _visible, child: widget.child),
          ),
          if (_visible) ...[
            ModalBarrier(color: Colors.black54, dismissible: false),
            SafeArea(
              child: CallbackShortcuts(
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.escape): _close,
                },
                child: FocusScope(
                  child: Focus(
                    focusNode: _focus,
                    child: Dialog(
                      key: const ValueKey('app-release-notes-dialog'),
                      insetPadding: const EdgeInsets.all(20),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 620),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${AppReleaseNotesHost._label.resolve(locale)} · ${widget.appName}',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${const ReleaseNoteText(en: 'Installed version', es: 'Versión instalada', de: 'Installierte Version', fr: 'Version installée').resolve(locale)} ${widget.version}',
                              ),
                              Text(
                                '${const ReleaseNoteText(en: 'Bundled notes', es: 'Notas incluidas', de: 'Enthaltene Hinweise', fr: 'Notes incluses').resolve(locale)} · ${widget.release.date}',
                              ),
                              const SizedBox(height: 16),
                              Flexible(
                                child: SingleChildScrollView(
                                  key: const ValueKey(
                                    'app-release-notes-scroll',
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      for (final item in widget.release.items)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 18,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.title.resolve(locale),
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.titleMedium,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(item.body.resolve(locale)),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: FilledButton(
                                  key: const ValueKey(
                                    'app-release-notes-close',
                                  ),
                                  onPressed: _close,
                                  child: Text(close),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReleaseNotesScope extends InheritedWidget {
  const _ReleaseNotesScope({
    required this.state,
    required this.blocking,
    required this.locale,
    required super.child,
  });

  final _AppReleaseNotesHostState state;
  final bool blocking;
  final Locale locale;

  @override
  bool updateShouldNotify(_ReleaseNotesScope oldWidget) =>
      state != oldWidget.state ||
      blocking != oldWidget.blocking ||
      locale != oldWidget.locale;
}
