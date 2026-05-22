// Tests for `ContentModerationHelper.canModerate` (única función pura).
// Las demás funciones requieren Firestore mocks.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_commons/utils/content_moderation_helper.dart';
import 'package:neom_core/utils/enums/user_role.dart';

void main() {
  group('ContentModerationHelper.canModerate', () {
    test('subscriber NO puede moderar', () {
      expect(
        ContentModerationHelper.canModerate(UserRole.subscriber),
        isFalse,
      );
    });

    test('editor SÍ puede moderar', () {
      expect(
        ContentModerationHelper.canModerate(UserRole.editor),
        isTrue,
      );
    });

    test('todos los roles con value >= editor.value pueden moderar', () {
      final editorValue = UserRole.editor.value;
      for (final role in UserRole.values) {
        final canMod = ContentModerationHelper.canModerate(role);
        if (role.value >= editorValue) {
          expect(canMod, isTrue,
              reason: '$role (value=${role.value}) debe poder moderar');
        } else {
          expect(canMod, isFalse,
              reason: '$role (value=${role.value}) NO debe poder moderar');
        }
      }
    });
  });
}
