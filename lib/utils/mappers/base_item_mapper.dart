import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/model/base_item.dart';
import 'package:neom_core/domain/model/external_item.dart';
import 'package:neom_core/domain/model/neom/neom_chamber_preset.dart';
import 'package:neom_core/domain/model/playable_item.dart';

class BaseItemMapper {

  static BaseItem fromAppReleaseItem(AppReleaseItem releaseItem) {
    try {
      return BaseItem(
        id: releaseItem.id,
        name: releaseItem.name,
        description: releaseItem.description,
        imgUrl: releaseItem.imgUrl,
        galleryUrls: releaseItem.galleryUrls,
        url: releaseItem.previewUrl,
        duration: releaseItem.duration,
        state: releaseItem.state,
        permaUrl: releaseItem.externalUrl ?? '',
        ownerId: releaseItem.ownerEmail,
        ownerName: releaseItem.ownerName,
        categories: releaseItem.categories,
        metaOwner: releaseItem.metaOwner,
        publishedYear: releaseItem.createdTime
      );
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_commons', operation: 'fromAppReleaseItem');
      throw Exception('Error parsing item: $e');
    }
  }

  static BaseItem fromAppMediaItem(AppMediaItem mediaItem) {
    try {
      return BaseItem(
          id: mediaItem.id,
          name: mediaItem.name,
          description: mediaItem.description,
          imgUrl: mediaItem.imgUrl,
          galleryUrls: mediaItem.galleryUrls,
          url: mediaItem.url,
          duration: mediaItem.duration,
          state: mediaItem.state,
          permaUrl: mediaItem.permaUrl,
          ownerId: mediaItem.ownerId ?? '',
          ownerName: mediaItem.ownerName,
          categories: mediaItem.categories ?? [],
          metaOwner: mediaItem.metaOwner,
          publishedYear: mediaItem.publishedYear ?? 0
      );
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_commons', operation: 'fromAppMediaItem');
      throw Exception('Error mapping external item to BaseItem: $e');
    }
  }

  static BaseItem fromExternalItem(ExternalItem externalItem) {
    try {
      return BaseItem(
        id: externalItem.id,
        name: externalItem.name,
        description: externalItem.description,
        imgUrl: externalItem.imgUrl,
        galleryUrls: externalItem.galleryUrls,
        url: externalItem.url,
        duration: externalItem.duration,
        state: externalItem.state,
        permaUrl: externalItem.permaUrl,
        ownerId: externalItem.ownerId ?? '',
        ownerName: externalItem.ownerName,
        categories: externalItem.categories ?? [],
        metaOwner: externalItem.metaOwner,
        publishedYear: externalItem.publishedYear ?? 0
      );
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_commons', operation: 'fromExternalItem');
      throw Exception('Error mapping external item to BaseItem: $e');
    }
  }

  static BaseItem fromChamberPreset(NeomChamberPreset chamberPreset) {
    try {
      return BaseItem(
        id: chamberPreset.id,
        name: chamberPreset.name,
        description: chamberPreset.description,
        imgUrl: chamberPreset.imgUrl,
        // ChamberPreset no tiene galería, usamos null
        galleryUrls: null,
        // ChamberPreset no tiene URL de vista previa directa (es un preset de audio)
        url: "",
        duration: chamberPreset.mainFrequency?.frequency.ceil() ?? 0,
        state: chamberPreset.state,
        permaUrl: chamberPreset.imgUrl, // Usamos la URL de imagen como permaUrl
        ownerId: chamberPreset.ownerId,
        ownerName: "", // ChamberPreset no tiene ownerName explícito
        categories: [],
        metaOwner: null,
        publishedYear: 0,
      );
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_commons', operation: 'fromChamberPreset');
      throw Exception('Error mapping chamber preset to BaseItem: $e');
    }
  }

  /// Converts any PlayableItem to BaseItem using the interface fields.
  static BaseItem fromPlayableItem(PlayableItem item) {
    try {
      if (item is AppReleaseItem) return fromAppReleaseItem(item);
      if (item is AppMediaItem) return fromAppMediaItem(item);
      return BaseItem(
        id: item.id,
        name: item.name,
        description: item.description ?? '',
        imgUrl: item.imgUrl,
        galleryUrls: item.galleryUrls,
        url: item.streamUrl,
        duration: item.duration,
        state: item.state,
        permaUrl: '',
        ownerId: item.ownerId ?? '',
        ownerName: item.ownerName,
        categories: item.categories ?? [],
        metaOwner: null,
        publishedYear: item.publishedYear ?? 0,
      );
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_commons', operation: 'fromPlayableItem');
      throw Exception('Error mapping PlayableItem to BaseItem: $e');
    }
  }

  static BaseItem fromDynamicItem(dynamic item) {

    BaseItem? baseItem = BaseItem();

    try {
      if (item is PlayableItem) {
        baseItem = fromPlayableItem(item);
      } else if(item is ExternalItem) {
        baseItem = fromExternalItem(item);
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_commons', operation: 'fromDynamicItem');
      throw Exception('Error mapping item to BaseItem: $e');
    }

    return baseItem;
  }

}
