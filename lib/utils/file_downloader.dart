import 'dart:convert' show latin1;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:http/http.dart' as http;
import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/core_utilities.dart';
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:neom_core/utils/platform/core_io.dart';
import 'package:neom_core/utils/secure_logger.dart';
import 'package:path_provider/path_provider.dart';

import 'file_system_utilities.dart';

class FileDownloader {
  static const int maxDownloadBytes = 50 * 1024 * 1024; // 50 MiB
  static const Duration _downloadTimeout = Duration(seconds: 30);

  static final RegExp _idnDotHomoglyphs = RegExp(r'[\u3002\uFF0E\uFF61]');
  static final RegExp _rawEncodedTraversalOrNull = RegExp(
    r'(?:^|/)\.\.(?:/|$|\?|#)|%00|%2e%2e|%2e\.|\.%2e|%2f|%5c|%25',
    caseSensitive: false,
  );
  static final RegExp _windowsReservedStem = RegExp(
    r'^(?:con|prn|aux|nul|com[1-9]|lpt[1-9]|__proto__|constructor|prototype)$',
    caseSensitive: false,
  );
  static final RegExp _activePolyglotSignature = RegExp(
    r'(?:<!doctype\s+html|<html\b|<script\b|<iframe\b|<svg\b|<object\b|<embed\b|\bon(?:load|error|click)\s*=|javascript\s*:)',
    caseSensitive: false,
  );

  static bool _hasUnsafeDownloadUrlChars(String value, {bool allowAsciiSpace = false}) {
    for (int i = 0; i < value.length; i++) {
      final unit = value.codeUnitAt(i);
      if (allowAsciiSpace && unit == 0x20) continue;
      if (unit <= 0x20 ||
          (unit >= 0x7F && unit <= 0x9F) ||
          unit == 0x061C ||
          (unit >= 0x200B && unit <= 0x200F) ||
          unit == 0x2028 ||
          unit == 0x2029 ||
          (unit >= 0x202A && unit <= 0x202E) ||
          (unit >= 0x2060 && unit <= 0x2069) ||
          unit == 0xFEFF) {
        return true;
      }
    }
    return false;
  }

  @visibleForTesting
  static bool isSafeRemoteDownloadUrl(String? rawUrl) {
    if (rawUrl == null ||
        _hasUnsafeDownloadUrlChars(rawUrl, allowAsciiSpace: true)) {
      return false;
    }
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty ||
        trimmed.length > 4096 ||
        trimmed.contains('\\') ||
        _idnDotHomoglyphs.hasMatch(trimmed) ||
        _rawEncodedTraversalOrNull.hasMatch(trimmed) ||
        _hasUnsafeDownloadUrlChars(trimmed)) {
      return false;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || uri.userInfo.isNotEmpty) {
      return false;
    }
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'https' && scheme != 'http') {
      return false;
    }

    String host = uri.host.trim().toLowerCase();
    if (host.startsWith('[') && host.endsWith(']') && host.length > 2) {
      host = host.substring(1, host.length - 1);
    }
    if (host.isEmpty ||
        host == 'localhost' ||
        host == 'instance-data' ||
        host.endsWith('.localhost') ||
        host.endsWith('.local') ||
        host.endsWith('.internal') ||
        host.endsWith('.corp') ||
        host.endsWith('.lan') ||
        host.endsWith('.invalid') ||
        host.endsWith('.home.arpa') ||
        host.endsWith('.onion') ||
        host.endsWith('.ts.net') ||
        host.endsWith('.metadata.azure.com') ||
        host.endsWith('.')) {
      return false;
    }

    if (_isPrivateOrReservedIp(host) ||
        !CoreUtilities.isSafePublicMediaUri(uri)) {
      return false;
    }

    return host.contains('.');
  }

  static bool _isPrivateOrReservedIp(String host) {
    // IPv4 check (and numeric-only host rejection)
    final ipv4Parts = host.split('.');
    if (ipv4Parts.length == 4 &&
        ipv4Parts.every((p) => p.isNotEmpty && int.tryParse(p) != null)) {
      final octets = ipv4Parts.map(int.parse).toList(growable: false);
      if (octets.any((o) => o < 0 || o > 255)) return true;
      final a = octets[0];
      final b = octets[1];
      if (a == 0 || a == 10 || a == 127) return true;
      if (a == 169 && b == 254) return true; // Cloud metadata / link-local
      if (a == 172 && b >= 16 && b <= 31) return true;
      if (a == 192 && b == 168) return true;
      if (a == 100 && b >= 64 && b <= 127) return true; // CGNAT
      if (a >= 224) return true; // Multicast / reserved
      return false;
    }

    // Reject single-integer / octal / hex IPv4 tricks without TLD letters
    if (!host.contains(':') && RegExp(r'^[0-9.xX]+$').hasMatch(host)) {
      return true;
    }

    // IPv6 check
    if (host.contains(':')) {
      final normalized = host.split('%').first;
      if (normalized == '::' || normalized == '::1' || normalized == '0:0:0:0:0:0:0:1') {
        return true;
      }
      if (normalized.startsWith('fc') ||
          normalized.startsWith('fd') ||
          normalized.startsWith('fe8') ||
          normalized.startsWith('fe9') ||
          normalized.startsWith('fea') ||
          normalized.startsWith('feb')) {
        return true;
      }
      if (normalized.startsWith('::ffff:')) {
        final mapped = normalized.substring('::ffff:'.length);
        if (mapped.contains('.')) {
          return _isPrivateOrReservedIp(mapped);
        }
        return true;
      }
      // Block raw IPv6 literals without public DNS validation
      return true;
    }

    return false;
  }

  @visibleForTesting
  static String sanitizeDownloadFileName(
    String raw, {
    required String defaultExtension,
  }) {
    final cleanExtChars = defaultExtension
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        .toLowerCase();
    final normalizedExt =
        '.${cleanExtChars.isEmpty ? 'bin' : (cleanExtChars.length > 10 ? cleanExtChars.substring(0, 10) : cleanExtChars)}';

    String candidate = raw.trim();
    final qIdx = candidate.indexOf('?');
    if (qIdx != -1) candidate = candidate.substring(0, qIdx);
    final hIdx = candidate.indexOf('#');
    if (hIdx != -1) candidate = candidate.substring(0, hIdx);

    candidate = candidate.replaceAll('\\', '/');
    final segments = candidate
        .split('/')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s != '.' && s != '..')
        .toList();
    String base = segments.isNotEmpty ? segments.last : '';
    try {
      base = Uri.decodeComponent(base);
    } catch (_) {
      // keep raw segment on malformed percent encoding
    }

    final buffer = StringBuffer();
    for (int i = 0; i < base.length; i++) {
      final unit = base.codeUnitAt(i);
      if (unit < 0x20 ||
          (unit >= 0x7F && unit <= 0x9F) ||
          unit == 0x0085 ||
          unit == 0x061C ||
          (unit >= 0x200B && unit <= 0x200F) ||
          (unit >= 0x2028 && unit <= 0x202E) ||
          (unit >= 0x2060 && unit <= 0x2069) ||
          unit == 0xFEFF) {
        continue;
      }
      final ch = base[i];
      if ('<>:"/\\|?*'.contains(ch)) {
        buffer.write('_');
      } else {
        buffer.write(ch);
      }
    }

    String cleaned = buffer.toString().trim();
    while (cleaned.startsWith('.')) {
      cleaned = cleaned.substring(1).trim();
    }
    while (cleaned.endsWith('.')) {
      cleaned = cleaned.substring(0, cleaned.length - 1).trim();
    }

    if (cleaned.toLowerCase().endsWith(normalizedExt)) {
      cleaned = cleaned.substring(0, cleaned.length - normalizedExt.length);
    }
    cleaned = cleaned.replaceAll('.', '_').trim();
    if (cleaned.isEmpty) {
      cleaned = 'download';
    }
    if (_windowsReservedStem.hasMatch(cleaned)) {
      cleaned = '_$cleaned';
    }
    if (cleaned.length > 120) {
      var cut = 120;
      final lastUnit = cleaned.codeUnitAt(cut - 1);
      if (lastUnit >= 0xD800 && lastUnit <= 0xDBFF) {
        cut -= 1;
      }
      cleaned = cleaned.substring(0, cut);
    }
    return '$cleaned$normalizedExt';
  }

  @visibleForTesting
  static bool hasActivePolyglotPayload(Uint8List bytes) {
    if (bytes.isEmpty) return false;
    final sampleLen = bytes.length < 4096 ? bytes.length : 4096;
    final head = latin1.decode(
      Uint8List.sublistView(bytes, 0, sampleLen),
      allowInvalid: true,
    );
    if (_activePolyglotSignature.hasMatch(head)) return true;
    if (head.contains('\x00')) {
      final deinterleaved = head.replaceAll('\x00', '');
      if (_activePolyglotSignature.hasMatch(deinterleaved)) return true;
    }
    return false;
  }

  @visibleForTesting
  static bool hasUnsafeDestinationPath(String filePath) {
    if (kIsWeb) return false;
    if (filePath.isEmpty || filePath.contains('\x00')) return true;
    final normalized = filePath.replaceAll('\\', '/');
    if (RegExp(r'(?:^|/)\.\.(?:/|$)').hasMatch(normalized) ||
        normalized.indexOf(':') > 1) {
      return true;
    }
    final segments = normalized.split('/');
    final bool isAbs = normalized.startsWith('/');
    var current = isAbs ? '' : '.';
    for (var i = 0; i < segments.length - 1; i++) {
      final seg = segments[i];
      if (seg.isEmpty) continue;
      current =
          isAbs ? '$current/$seg' : (current == '.' ? seg : '$current/$seg');
      if (current == '/tmp' || current == '/var' || current == '/etc') {
        continue;
      }
      if (FileSystemEntity.typeSync(current, followLinks: false) ==
          FileSystemEntityType.link) {
        return true;
      }
    }
    final existingType = FileSystemEntity.typeSync(
      filePath,
      followLinks: false,
    );
    return existingType != FileSystemEntityType.notFound &&
        existingType != FileSystemEntityType.file;
  }

  @visibleForTesting
  static Future<Uint8List> readBoundedResponseStream(
    Stream<List<int>> stream, {
    int? contentLength,
  }) async {
    if (contentLength != null &&
        (contentLength < 0 || contentLength > maxDownloadBytes)) {
      throw StateError('Remote file exceeds maxDownloadBytes ($contentLength)');
    }

    final builder = BytesBuilder(copy: false);
    int total = 0;
    await for (final chunk in stream.timeout(_downloadTimeout)) {
      total += chunk.length;
      if (total > maxDownloadBytes) {
        throw StateError('Remote stream exceeded maxDownloadBytes ($total)');
      }
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  static Future<Uint8List?> _downloadBytes(
    Uri uri, {
    http.Client? client,
    Stream<List<int>> Function(Uri uri)? debugResponseStream,
    int? debugContentLength,
  }) async {
    if (debugResponseStream != null) {
      return readBoundedResponseStream(
        debugResponseStream(uri),
        contentLength: debugContentLength,
      );
    }
    final bool ownsClient = client == null;
    final http.Client activeClient = client ?? http.Client();
    try {
      final request = http.Request('GET', uri)..followRedirects = false;
      final response =
          await activeClient.send(request).timeout(_downloadTimeout);
      if (response.statusCode != 200) {
        final sub = response.stream.listen((_) {});
        await sub.cancel();
        return null;
      }
      if (response.contentLength != null &&
          response.contentLength! > maxDownloadBytes) {
        final sub = response.stream.listen((_) {});
        await sub.cancel();
        throw StateError(
          'Remote file exceeds maxDownloadBytes (${response.contentLength})',
        );
      }
      return await readBoundedResponseStream(
        response.stream,
        contentLength: response.contentLength,
      );
    } finally {
      if (ownsClient) {
        activeClient.close();
      }
    }
  }

  static Future<File> getPdfFromUrl(
    String pdfUrl, {
    http.Client? client,
    String? targetDirectoryPath,
    @visibleForTesting Stream<List<int>> Function(Uri uri)? debugResponseStream,
    @visibleForTesting int? debugContentLength,
  }) async {
    AppConfig.logger.d('getPdfFromUrl ${SecureLogger.sanitize(pdfUrl)}');
    File file = File('');
    try {
      if (!isSafeRemoteDownloadUrl(pdfUrl)) {
        throw ArgumentError('Unsafe remote PDF URL');
      }
      final uri = Uri.parse(pdfUrl.trim());
      final filename = sanitizeDownloadFileName(
        uri.path,
        defaultExtension: '.pdf',
      );
      final bytes = await _downloadBytes(
        uri,
        client: client,
        debugResponseStream: debugResponseStream,
        debugContentLength: debugContentLength,
      );
      if (bytes != null) {
        if (hasActivePolyglotPayload(bytes)) {
          throw ArgumentError('Active HTML/script polyglot payload rejected');
        }
        final dirPath = targetDirectoryPath ??
            (await getApplicationDocumentsDirectory()).path;
        final destPath = '$dirPath/$filename';
        if (hasUnsafeDestinationPath(destPath)) {
          throw ArgumentError('Unsafe local PDF destination path');
        }
        AppConfig.logger.d('File loaded and buffered');
        file = File(destPath);
        await file.writeAsBytes(bytes, flush: true);
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_commons', operation: 'getPdfFromUrl');
      throw Exception('Error parsing asset file!');
    }

    return file;
  }

  static Future<String> downloadImage(
    String imgUrl, {
    String imgName = '',
    http.Client? client,
    String? targetDirectoryPath,
    @visibleForTesting Stream<List<int>> Function(Uri uri)? debugResponseStream,
    @visibleForTesting int? debugContentLength,
  }) async {
    AppConfig.logger.d('Entering downloadImage method');
    String localPath = '';
    try {
      if (!isSafeRemoteDownloadUrl(imgUrl)) {
        throw ArgumentError('Unsafe remote image URL');
      }
      final uri = Uri.parse(imgUrl.trim());
      final bytes = await _downloadBytes(
        uri,
        client: client,
        debugResponseStream: debugResponseStream,
        debugContentLength: debugContentLength,
      );
      if (bytes != null) {
        if (hasActivePolyglotPayload(bytes)) {
          throw ArgumentError('Active HTML/script polyglot payload rejected');
        }
        final safeFileName = sanitizeDownloadFileName(
          imgName.trim().isNotEmpty ? imgName : uri.path,
          defaultExtension: '.jpeg',
        );
        final baseDir = targetDirectoryPath ??
            await FileSystemUtilities.getLocalPath();
        final candidatePath = '$baseDir/$safeFileName';
        if (hasUnsafeDestinationPath(candidatePath)) {
          throw ArgumentError('Unsafe local image destination path');
        }
        localPath = candidatePath;
        final File jpegFileRef = File(localPath);
        await jpegFileRef.writeAsBytes(bytes);
        AppConfig.logger.i('Image downloaded successfully ($safeFileName).');
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_commons', operation: 'downloadImage');
      localPath = '';
    }
    return localPath;
  }

}
