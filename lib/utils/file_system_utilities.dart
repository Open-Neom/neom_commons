import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:neom_core/utils/platform/core_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class FileSystemUtilities {
  static final RegExp _unsafeFilePathChars = RegExp(
    r'[\x00-\x1F\x7F-\x9F\u061C\u200B-\u200F\u202A-\u202E\u2066-\u2069\uFEFF]',
  );

  @visibleForTesting
  static bool isSafeLocalFilePathOrUri(String? rawPath) {
    if (rawPath == null) return false;
    final trimmed = rawPath.trim();
    if (trimmed.isEmpty ||
        trimmed.length > 1024 ||
        _unsafeFilePathChars.hasMatch(trimmed)) {
      return false;
    }
    if (RegExp(r'(?:^|[/\\])\.\.(?:[/\\]|$)|%2e%2e|%00', caseSensitive: false)
        .hasMatch(trimmed)) {
      return false;
    }
    final schemeMatch = RegExp(r'^([a-zA-Z][a-zA-Z0-9+.\-]*):').firstMatch(trimmed);
    if (schemeMatch != null) {
      final scheme = schemeMatch.group(1)!.toLowerCase();
      // Allow Windows drive letters (e.g. `C:\...`) or explicit `file://` URIs only.
      if (scheme.length == 1) return true;
      if (scheme != 'file') return false;
      final uri = Uri.tryParse(trimmed);
      if (uri == null || uri.scheme.toLowerCase() != 'file') return false;
      if (uri.pathSegments.any((s) => s == '..')) return false;
    }
    return true;
  }

  static Future<String> getLocalPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<File> getFileFromPath(String filePath) async {
    File file = File('');
    if (kIsWeb || !isSafeLocalFilePathOrUri(filePath)) {
      AppConfig.logger.w('Blocked unsafe or unsupported local file path');
      return file;
    }

    try {
      final trimmed = filePath.trim();
      if (trimmed.toLowerCase().startsWith('file:')) {
        file = await File.fromUri(Uri.parse(trimmed)).create();
      } else if (Platform.isAndroid) {
        file = File(trimmed);
      } else {
        file = await File.fromUri(Uri.file(trimmed)).create();
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_commons', operation: 'getFileFromPath');
    }

    return file;
  }

  static String getFileNameWithExtension(String? filePath) {
    if (filePath == null || filePath.isEmpty) {
      return '';
    }
    final cleaned = filePath.replaceAll(_unsafeFilePathChars, '').trim();
    if (cleaned.isEmpty) return '';
    final base = p.basename(cleaned);
    if (base == '.' || base == '..') return '';
    return base;
  }
}
