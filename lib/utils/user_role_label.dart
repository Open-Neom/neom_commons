import 'package:neom_core/utils/enums/user_role.dart';
import 'package:sint/sint.dart';

import 'constants/translations/app_translation_constants.dart';
import 'constants/translations/common_translation_constants.dart';

/// Human-readable, localized label for a [UserRole].
///
/// Used in profile/account cards so staff accounts (admin, developer, ERP…)
/// show their role instead of "free account" — they don't pay a subscription
/// but they are not "free" users.
extension UserRoleLabel on UserRole {
  String get label {
    switch (this) {
      case UserRole.superAdmin:
        return AppTranslationConstants.superAdmin.tr;
      case UserRole.admin:
        return AppTranslationConstants.admin.tr;
      case UserRole.developer:
        return AppTranslationConstants.roleDeveloper.tr;
      case UserRole.pos:
        return AppTranslationConstants.rolePos.tr;
      case UserRole.erp:
        return AppTranslationConstants.roleErp.tr;
      case UserRole.support:
        return AppTranslationConstants.roleSupport.tr;
      case UserRole.editor:
        return AppTranslationConstants.roleEditor.tr;
      case UserRole.subscriber:
        return CommonTranslationConstants.freeAccount.tr;
    }
  }

  /// Whether this role is staff (above a regular subscriber) — i.e. an account
  /// whose status should be shown as a role rather than "free account".
  bool get isStaff => value > UserRole.subscriber.value;
}
