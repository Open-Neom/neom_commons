import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:neom_commons/utils/file_downloader.dart';

void main() {
  group('FileDownloader.isSafeRemoteDownloadUrl', () {
    test('allows standard Firebase Storage URLs with encoded %2F object paths', () {
      const firebasePdfUrl =
          'https://firebasestorage.googleapis.com/v0/b/emxi-9c5b5.appspot.com/o/releaseItems%2FViabilidad%20de%20Unir%20Segmentos%20Sociales%20y%20Expansio%CC%81n.pdf?alt=media&token=60f057d6-4e40-444e-9175-d5c972695c77';
      const firebaseNestedImgUrl =
          'https://firebasestorage.googleapis.com/v0/b/gig-me-out.appspot.com/o/RehearsalRooms%2FMexico%2FSolaz%2Frecepcion.jpg?alt=media&token=144ec983';

      expect(FileDownloader.isSafeRemoteDownloadUrl(firebasePdfUrl), isTrue);
      expect(FileDownloader.isSafeRemoteDownloadUrl(firebaseNestedImgUrl), isTrue);
      expect(
        FileDownloader.sanitizeDownloadFileName(
          Uri.parse(firebasePdfUrl).path,
          defaultExtension: '.pdf',
        ),
        endsWith('.pdf'),
      );
      expect(
        FileDownloader.sanitizeDownloadFileName(
          Uri.parse(firebasePdfUrl).path,
          defaultExtension: '.pdf',
        ),
        isNot(contains('/')),
      );
    });

    test('still rejects path traversal, null bytes, backslashes, double-encoding and SSRF hosts', () {
      const malicious = [
        'https://firebasestorage.googleapis.com/v0/b/emxi/o/releaseItems%2F..%2Fsecret.pdf',
        'https://firebasestorage.googleapis.com/v0/b/emxi/o/..%2Fsecret.pdf',
        'https://firebasestorage.googleapis.com/v0/b/emxi/o/%2e%2e%2Fsecret.pdf',
        'https://example.com/../secret.pdf',
        'https://example.com/%2e%2e/secret.pdf',
        'https://example.com/a%00.pdf',
        'https://example.com/a%5cb.pdf',
        'https://example.com/%252e%252e/secret.pdf',
        'https://example.com/%252fsecret.pdf',
        'http://127.0.0.1/book.pdf',
        'http://169.254.169.254/latest/meta-data',
        'http://localhost/book.pdf',
        'file:///etc/passwd',
      ];
      for (final url in malicious) {
        expect(
          FileDownloader.isSafeRemoteDownloadUrl(url),
          isFalse,
          reason: 'Expected URL to be rejected: $url',
        );
      }
    });
  });

  group('FileDownloader.getPdfFromUrl redirects', () {
    test('follows safe HTTPS redirect and rejects redirect to loopback', () async {
      final safeClient = MockClient((request) async {
        if (request.url.host == 'archive.org') {
          return http.Response(
            '',
            302,
            headers: {
              'location':
                  'https://firebasestorage.googleapis.com/v0/b/emxi-9c5b5.appspot.com/o/releaseItems%2Fsample.pdf?alt=media&token=ok',
            },
          );
        }
        return http.Response.bytes(Uint8List.fromList('%PDF-1.4\n%%EOF'.codeUnits), 200);
      });

      final tempDir = await Future.value('/tmp');
      final file = await FileDownloader.getPdfFromUrl(
        'https://archive.org/download/book/sample.pdf',
        client: safeClient,
        targetDirectoryPath: tempDir,
      );
      expect(await file.exists(), isTrue);
      await file.delete();

      final ssrfRedirectClient = MockClient((request) async {
        return http.Response(
          '',
          302,
          headers: {'location': 'http://127.0.0.1/secret.pdf'},
        );
      });
      await expectLater(
        () => FileDownloader.getPdfFromUrl(
          'https://archive.org/download/book/bad.pdf',
          client: ssrfRedirectClient,
          targetDirectoryPath: tempDir,
        ),
        throwsException,
      );
    });
  });
}
