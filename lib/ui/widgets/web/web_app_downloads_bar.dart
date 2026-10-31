import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:neom_core/app_properties.dart';
import 'package:url_launcher/url_launcher.dart';

/// Live release metadata resolved from `/downloads/version.json` (served by
/// Firebase Hosting after each CI/CD build) with fallback to `AppProperties`.
class AppReleaseDownloadInfo {
  final String versionLabel;
  final String windowsUrl;
  final String macosUrl;
  final String linuxUrl;
  final String apkUrl;
  final String playStoreUrl;
  final String appStoreUrl;

  const AppReleaseDownloadInfo({
    this.versionLabel = '',
    this.windowsUrl = '',
    this.macosUrl = '',
    this.linuxUrl = '',
    this.apkUrl = '',
    this.playStoreUrl = '',
    this.appStoreUrl = '',
  });

  factory AppReleaseDownloadInfo.fromAppProperties() {
    return AppReleaseDownloadInfo(
      windowsUrl: AppProperties.getWindowsUrl(),
      macosUrl: AppProperties.getMacosUrl(),
      linuxUrl: AppProperties.getLinuxUrl(),
      apkUrl: AppProperties.getApkUrl(),
      playStoreUrl: AppProperties.getPlayStoreUrl(),
      appStoreUrl: AppProperties.getAppStoreUrl(),
    );
  }

  static Future<AppReleaseDownloadInfo> fetchLive({
    String relativeManifestPath = '/downloads/version.json',
  }) async {
    final fallback = AppReleaseDownloadInfo.fromAppProperties();
    if (!kIsWeb) return fallback;

    try {
      final uri = Uri.base.resolve(relativeManifestPath);
      final response = await http
          .get(uri, headers: const {'Cache-Control': 'no-cache'})
          .timeout(const Duration(seconds: 4));

      if (response.statusCode != 200) return fallback;
      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) return fallback;

      final downloads = data['downloads'] is Map<String, dynamic>
          ? data['downloads'] as Map<String, dynamic>
          : const <String, dynamic>{};

      String pick(String primary, String secondary) =>
          secondary.isNotEmpty ? secondary : primary;

      return AppReleaseDownloadInfo(
        versionLabel: (data['version'] ?? '').toString(),
        windowsUrl: pick(
          (downloads['windows'] ?? '').toString(),
          fallback.windowsUrl,
        ),
        macosUrl: pick(
          (downloads['macos'] ?? '').toString(),
          fallback.macosUrl,
        ),
        linuxUrl: pick(
          (downloads['linux'] ?? '').toString(),
          fallback.linuxUrl,
        ),
        apkUrl: pick(
          (downloads['androidApk'] ?? '').toString(),
          fallback.apkUrl,
        ),
        playStoreUrl: fallback.playStoreUrl,
        appStoreUrl: fallback.appStoreUrl,
      );
    } catch (_) {
      return fallback;
    }
  }
}

class _PlatformDownloadOption {
  final String id;
  final String label;
  final String badge;
  final FaIconData icon;
  final String url;

  const _PlatformDownloadOption({
    required this.id,
    required this.label,
    required this.badge,
    required this.icon,
    required this.url,
  });
}

/// Smart OS-aware download bar for Open Neom web apps.
///
/// Automatically highlights the native installer matching the visitor's OS
/// (`.exe` on Windows, `.dmg` on macOS, `.AppImage` on Linux, Google Play / `.apk`
/// on Android, App Store on iOS) while keeping secondary download links accessible.
class WebAppDownloadsBar extends StatefulWidget {
  final bool showDesktopInstallers;
  final Color? accentColor;

  const WebAppDownloadsBar({
    super.key,
    this.showDesktopInstallers = true,
    this.accentColor,
  });

  @override
  State<WebAppDownloadsBar> createState() => _WebAppDownloadsBarState();
}

class _WebAppDownloadsBarState extends State<WebAppDownloadsBar> {
  late Future<AppReleaseDownloadInfo> _infoFuture;

  @override
  void initState() {
    super.initState();
    _infoFuture = AppReleaseDownloadInfo.fetchLive();
  }

  List<_PlatformDownloadOption> _buildOptions(AppReleaseDownloadInfo info) {
    final options = <_PlatformDownloadOption>[];

    if (widget.showDesktopInstallers && info.windowsUrl.isNotEmpty) {
      options.add(_PlatformDownloadOption(
        id: 'windows',
        label: 'Windows',
        badge: '.exe',
        icon: FontAwesomeIcons.windows,
        url: info.windowsUrl,
      ));
    }
    if (widget.showDesktopInstallers && info.macosUrl.isNotEmpty) {
      options.add(_PlatformDownloadOption(
        id: 'macos',
        label: 'macOS',
        badge: '.dmg',
        icon: FontAwesomeIcons.apple,
        url: info.macosUrl,
      ));
    }
    if (widget.showDesktopInstallers && info.linuxUrl.isNotEmpty) {
      options.add(_PlatformDownloadOption(
        id: 'linux',
        label: 'Linux',
        badge: '.AppImage',
        icon: FontAwesomeIcons.linux,
        url: info.linuxUrl,
      ));
    }
    if (info.playStoreUrl.isNotEmpty) {
      options.add(_PlatformDownloadOption(
        id: 'android_store',
        label: 'Google Play',
        badge: 'Android',
        icon: FontAwesomeIcons.googlePlay,
        url: info.playStoreUrl,
      ));
    } else if (info.apkUrl.isNotEmpty) {
      options.add(_PlatformDownloadOption(
        id: 'android_apk',
        label: 'Android',
        badge: '.apk',
        icon: FontAwesomeIcons.android,
        url: info.apkUrl,
      ));
    }
    if (info.appStoreUrl.isNotEmpty) {
      options.add(_PlatformDownloadOption(
        id: 'ios_store',
        label: 'App Store',
        badge: 'iOS',
        icon: FontAwesomeIcons.appStoreIos,
        url: info.appStoreUrl,
      ));
    }
    return options;
  }

  String _preferredPlatformId() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.android:
        return 'android_store';
      case TargetPlatform.iOS:
        return 'ios_store';
      case TargetPlatform.fuchsia:
        return 'linux';
    }
  }

  Future<void> _openDownload(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = widget.accentColor ?? theme.colorScheme.primary;

    return FutureBuilder<AppReleaseDownloadInfo>(
      future: _infoFuture,
      builder: (context, snapshot) {
        final info = snapshot.data ?? AppReleaseDownloadInfo.fromAppProperties();
        final options = _buildOptions(info);
        if (options.isEmpty) return const SizedBox.shrink();

        final preferredId = _preferredPlatformId();
        final primaryIndex = options.indexWhere(
          (o) =>
              o.id == preferredId ||
              (preferredId == 'android_store' && o.id == 'android_apk'),
        );
        final primary = options[primaryIndex >= 0 ? primaryIndex : 0];
        final others = options.where((o) => o.id != primary.id).toList();
        final versionSuffix =
            info.versionLabel.isNotEmpty ? ' • v${info.versionLabel}' : '';

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
              ),
              onPressed: () => _openDownload(primary.url),
              icon: FaIcon(primary.icon, size: 16),
              label: Text(
                'Descargar para ${primary.label} (${primary.badge})$versionSuffix',
              ),
            ),
            for (final opt in others)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                onPressed: () => _openDownload(opt.url),
                icon: FaIcon(opt.icon, size: 14),
                label: Text('${opt.label} (${opt.badge})'),
              ),
          ],
        );
      },
    );
  }
}
