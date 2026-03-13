import 'package:flutter/material.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/firestore/app_media_item_firestore.dart';
import 'package:neom_core/data/firestore/app_release_item_firestore.dart';
import 'package:neom_core/data/firestore/constants/app_firestore_constants.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/utils/enums/user_role.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:sint/sint.dart';

import '../ui/theme/app_color.dart';
import 'app_utilities.dart';
import 'constants/translations/app_translation_constants.dart';
import 'constants/translations/common_translation_constants.dart';

/// Shared content moderation utility for admin/editor actions.
/// Used by neom_books and neom_audio_player for suspend/delete operations.
class ContentModerationHelper {

  /// Returns true if the given role has moderation privileges (editor+).
  static bool canModerate(UserRole role) {
    return role.value >= UserRole.editor.value;
  }

  /// Shows suspend confirmation dialog with optional reason field.
  /// Calls [onConfirm] with the reason text if user confirms.
  static Future<void> showSuspendContentDialog(
    BuildContext context, {
    required String contentName,
    required Future<bool> Function(String? reason) onConfirm,
  }) async {
    String? reason;
    Alert(
      context: context,
      style: AlertStyle(
        backgroundColor: AppColor.scaffold,
        titleStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
      title: CommonTranslationConstants.confirmSuspend.tr,
      content: Column(
        children: [
          Text(
            '${CommonTranslationConstants.suspendContentMsg.tr}\n\n"$contentName"',
            style: const TextStyle(fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (text) => reason = text,
            decoration: InputDecoration(
              labelText: CommonTranslationConstants.suspendReason.tr,
              border: const OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ),
      buttons: [
        DialogButton(
          color: AppColor.bondiBlue75,
          onPressed: () => Navigator.pop(context),
          child: Text(AppTranslationConstants.cancel.tr,
            style: const TextStyle(fontSize: 15),
          ),
        ),
        DialogButton(
          color: Colors.orange[700]!,
          onPressed: () async {
            Navigator.pop(context);
            final success = await onConfirm(reason);
            if (success) {
              AppUtilities.showSnackBar(
                message: CommonTranslationConstants.contentSuspended,
              );
            }
          },
          child: Text(CommonTranslationConstants.suspendContent.tr,
            style: const TextStyle(fontSize: 15, color: Colors.white),
          ),
        ),
      ],
    ).show();
  }

  /// Shows delete confirmation dialog.
  /// Calls [onConfirm] if user confirms the permanent deletion.
  static Future<void> showDeleteContentDialog(
    BuildContext context, {
    required String contentName,
    required Future<bool> Function() onConfirm,
  }) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColor.scaffold,
        title: Text(CommonTranslationConstants.confirmDelete.tr,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          '${CommonTranslationConstants.deleteContentMsg.tr}\n\n"$contentName"',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppTranslationConstants.cancel.tr),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await onConfirm();
              if (success) {
                AppUtilities.showSnackBar(
                  message: CommonTranslationConstants.contentDeleted,
                );
              }
            },
            child: Text(CommonTranslationConstants.deleteContent.tr,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  // ── AppReleaseItem operations ──────────────────────────────────

  /// Suspends an AppReleaseItem (sets isSuspended=true with audit fields).
  static Future<bool> suspendReleaseItem(
    String releaseItemId,
    String moderatorId, {
    String? reason,
  }) async {
    AppConfig.logger.d("Suspending AppReleaseItem $releaseItemId by $moderatorId");
    return await AppReleaseItemFirestore().updateFields(releaseItemId, {
      AppFirestoreConstants.isSuspended: true,
      AppFirestoreConstants.suspendedBy: moderatorId,
      AppFirestoreConstants.suspendedReason: reason ?? '',
      AppFirestoreConstants.modifiedTime: DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Unsuspends an AppReleaseItem (reverses suspension).
  static Future<bool> unsuspendReleaseItem(String releaseItemId) async {
    AppConfig.logger.d("Unsuspending AppReleaseItem $releaseItemId");
    return await AppReleaseItemFirestore().updateFields(releaseItemId, {
      AppFirestoreConstants.isSuspended: false,
      AppFirestoreConstants.suspendedBy: null,
      AppFirestoreConstants.suspendedReason: null,
      AppFirestoreConstants.modifiedTime: DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Permanently deletes an AppReleaseItem from Firestore.
  static Future<bool> deleteReleaseItem(AppReleaseItem item) async {
    AppConfig.logger.d("Deleting AppReleaseItem ${item.id} (${item.name})");
    return await AppReleaseItemFirestore().remove(item);
  }

  // ── AppMediaItem operations ────────────────────────────────────

  /// Suspends an AppMediaItem (sets isSuspended=true with audit fields).
  static Future<bool> suspendMediaItem(
    String mediaItemId,
    String moderatorId, {
    String? reason,
  }) async {
    AppConfig.logger.d("Suspending AppMediaItem $mediaItemId by $moderatorId");
    return await AppMediaItemFirestore().updateFields(mediaItemId, {
      AppFirestoreConstants.isSuspended: true,
      AppFirestoreConstants.suspendedBy: moderatorId,
      AppFirestoreConstants.suspendedReason: reason ?? '',
    });
  }

  /// Unsuspends an AppMediaItem (reverses suspension).
  static Future<bool> unsuspendMediaItem(String mediaItemId) async {
    AppConfig.logger.d("Unsuspending AppMediaItem $mediaItemId");
    return await AppMediaItemFirestore().updateFields(mediaItemId, {
      AppFirestoreConstants.isSuspended: false,
      AppFirestoreConstants.suspendedBy: null,
      AppFirestoreConstants.suspendedReason: null,
    });
  }

  /// Permanently deletes an AppMediaItem from Firestore.
  static Future<bool> deleteMediaItem(AppMediaItem item) async {
    AppConfig.logger.d("Deleting AppMediaItem ${item.id} (${item.name})");
    return await AppMediaItemFirestore().remove(item);
  }
}
