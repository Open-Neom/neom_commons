import 'package:flutter/material.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/firestore/app_media_item_firestore.dart';
import 'package:neom_core/data/firestore/activity_feed_firestore.dart';
import 'package:neom_core/data/firestore/app_release_item_firestore.dart';
import 'package:neom_core/data/firestore/constants/app_firestore_constants.dart';
import 'package:neom_core/data/firestore/itemlist_firestore.dart';
import 'package:neom_core/data/firestore/request_firestore.dart';
import 'package:neom_core/data/firestore/user_firestore.dart';
import 'package:neom_core/domain/model/activity_feed.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/model/app_request.dart';
import 'package:neom_core/utils/constants/core_constants.dart';
import 'package:neom_core/utils/enums/activity_feed_type.dart';
import 'package:neom_core/utils/enums/owner_type.dart';
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
          onPressed: () => Sint.back(),
          child: Text(AppTranslationConstants.cancel.tr,
            style: const TextStyle(fontSize: 15),
          ),
        ),
        DialogButton(
          color: Colors.orange[700]!,
          onPressed: () async {
            Sint.back();
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

  /// Permanently deletes an AppReleaseItem and cleans up every embedded
  /// reference held by the owner (resolved via [AppReleaseItem.ownerEmail]).
  ///
  /// Steps:
  ///   1. Removes the doc from `appReleaseItems`.
  ///   2. Resolves the owning [AppUser] via email and walks each profile.
  ///   3. For every Itemlist owned by those profiles, drops the embedded
  ///      copy of the release item so the author's library stays consistent.
  ///
  /// Returns `true` if step 1 succeeded; embedded cleanup is best-effort
  /// and logs errors but does not fail the deletion.
  static Future<bool> deleteReleaseItemWithOwnerCleanup(AppReleaseItem item) async {
    AppConfig.logger.d("Deleting AppReleaseItem ${item.id} (${item.name}) with owner cleanup");

    final removed = await AppReleaseItemFirestore().remove(item);
    if (!removed) {
      AppConfig.logger.w("Top-level removal failed for ${item.id}; skipping owner cleanup");
      return false;
    }

    final ownerEmail = item.ownerEmail;
    if (ownerEmail.isEmpty) {
      AppConfig.logger.d("No ownerEmail on release ${item.id}; nothing else to clean");
      return true;
    }

    try {
      final owner = await UserFirestore().getByEmail(ownerEmail, getProfile: true);
      if (owner == null || owner.profiles.isEmpty) {
        AppConfig.logger.d("No owner profiles found for $ownerEmail");
        return true;
      }

      final itemlistFirestore = ItemlistFirestore();
      for (final profile in owner.profiles) {
        if (profile.id.isEmpty) continue;
        final itemlists = await itemlistFirestore.getByOwnerId(
          profile.id,
          ownerType: OwnerType.profile,
          excludeMyFavorites: false,
        );
        for (final itemlistId in itemlists.keys) {
          await itemlistFirestore.deleteReleaseItem(
            itemlistId: itemlistId,
            itemId: item.id,
          );
        }
        AppConfig.logger.d("Cleaned ${itemlists.length} itemlists for owner profile ${profile.id}");
      }
    } catch (e, st) {
      // Best-effort cleanup; the canonical doc is already gone.
      AppConfig.logger.w("Owner cleanup partial failure for ${item.id}: $e");
      AppConfig.logger.t(st);
    }

    return true;
  }

  /// Updates editable metadata of an AppReleaseItem (title, description,
  /// cover, author display name, categories, language, pages). Only the
  /// non-null arguments are written. Used by admin/editor edit flows so a
  /// published work can be corrected without re-running the upload wizard.
  static Future<bool> updateReleaseItemMetadata(
    String releaseItemId, {
    String? name,
    String? description,
    String? imgUrl,
    String? ownerName,
    List<String>? categories,
    String? language,
    int? duration,
  }) async {
    AppConfig.logger.d("Updating AppReleaseItem $releaseItemId metadata");
    final fields = <String, dynamic>{
      AppFirestoreConstants.modifiedTime: DateTime.now().millisecondsSinceEpoch,
    };
    if (name != null) fields[AppFirestoreConstants.name] = name;
    if (description != null) fields[AppFirestoreConstants.description] = description;
    if (imgUrl != null) fields[AppFirestoreConstants.imgUrl] = imgUrl;
    if (ownerName != null) fields['ownerName'] = ownerName;
    if (categories != null) fields['categories'] = categories;
    if (language != null) fields['language'] = language;
    if (duration != null) fields['duration'] = duration;
    return await AppReleaseItemFirestore().updateFields(releaseItemId, fields);
  }

  // ── Change-approval flow (approval layer for non-admin edits) ──────

  /// Whether [role] can apply sensitive changes directly (admin+).
  static bool canApplyDirectly(UserRole role) => role.value >= UserRole.admin.value;

  /// Whether [role] may propose changes that require approval (above
  /// subscriber, i.e. editor and up, but below admin who applies directly).
  static bool canRequestChange(UserRole role) =>
      role.value > UserRole.subscriber.value;

  /// Submits a change-approval request for an AppReleaseItem edit that the
  /// requester is allowed to propose but not apply directly. Returns the new
  /// request id (empty on failure).
  static Future<String> submitReleaseEditApproval({
    required String requesterProfileId,
    required String releaseItemId,
    required String releaseName,
    required Map<String, dynamic> changes,
  }) async {
    AppConfig.logger.d("Submitting edit approval for release $releaseItemId");
    if (changes.isEmpty) return '';
    final request = AppRequest.changeApproval(
      from: requesterProfileId,
      to: CoreConstants.appBot,
      targetType: 'releaseItem',
      targetId: releaseItemId,
      targetName: releaseName,
      module: 'neom_books',
      changes: changes,
    );
    final id = await RequestFirestore().insert(request);
    // Mirror every generated request as a notification for the requester.
    if (id.isNotEmpty) {
      try {
        await ActivityFeedFirestore().insert(ActivityFeed.fromAppBot(
          toProfileId: requesterProfileId,
          referenceId: id,
          type: ActivityFeedType.sentRequest,
          message: 'Tu cambio en "$releaseName" fue enviado a aprobación.',
        ));
      } catch (e, st) {
        AppConfig.logger.w('submitReleaseEditApproval notification failed: $e');
        AppConfig.logger.t(st);
      }
    }
    return id;
  }

  /// Applies an approved change request to its target entity. Returns true on
  /// success. Currently handles 'releaseItem'; other target types (e.g. ERP)
  /// are handled by their own modules.
  static Future<bool> applyChangeApproval(AppRequest request) async {
    AppConfig.logger.d("Applying change approval ${request.id} (${request.changeTargetType})");
    final changes = request.changes;
    if (changes.isEmpty) return false;

    switch (request.changeTargetType) {
      case 'releaseItem':
        final fields = Map<String, dynamic>.from(changes);
        fields[AppFirestoreConstants.modifiedTime] = DateTime.now().millisecondsSinceEpoch;
        return await AppReleaseItemFirestore().updateFields(request.changeTargetId, fields);
      default:
        AppConfig.logger.w("Unhandled change target type: ${request.changeTargetType}");
        return false;
    }
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
