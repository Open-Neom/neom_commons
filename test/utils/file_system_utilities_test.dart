// Tests for `FileSystemUtilities.getFileNameWithExtension` (única función pura).
// Las demás (getLocalPath, getFileFromPath) requieren path_provider/File.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_commons/utils/file_system_utilities.dart';

void main() {
  group('FileSystemUtilities.getFileNameWithExtension', () {
    test('null → ""', () {
      expect(FileSystemUtilities.getFileNameWithExtension(null), '');
    });

    test('cadena vacía → ""', () {
      expect(FileSystemUtilities.getFileNameWithExtension(''), '');
    });

    test('path absoluto Unix devuelve solo el nombre', () {
      expect(
        FileSystemUtilities.getFileNameWithExtension('/Users/x/foo.mp3'),
        'foo.mp3',
      );
    });

    test('path relativo devuelve solo el nombre', () {
      expect(
        FileSystemUtilities.getFileNameWithExtension('docs/file.pdf'),
        'file.pdf',
      );
    });

    test('archivo sin path devuelve la cadena tal cual', () {
      expect(
        FileSystemUtilities.getFileNameWithExtension('image.png'),
        'image.png',
      );
    });

    test('preserva extensión', () {
      expect(
        FileSystemUtilities.getFileNameWithExtension('a/b/c.tar.gz'),
        'c.tar.gz',
      );
    });

    test('archivo sin extensión devuelve nombre completo', () {
      expect(
        FileSystemUtilities.getFileNameWithExtension('/x/Makefile'),
        'Makefile',
      );
    });
  });
}
