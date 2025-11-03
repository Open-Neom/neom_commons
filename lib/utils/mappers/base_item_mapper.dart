import 'package:neom_core/app_config.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/model/base_item.dart';
import 'package:neom_core/domain/model/external_item.dart';
import 'package:neom_core/domain/model/neom/chamber_preset.dart';

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
    } catch (e) {
      AppConfig.logger.e("Error mapping AppReleaseItem to BaseItem: $e");
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
    } catch (e) {
      AppConfig.logger.e(e.toString());
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
    } catch (e) {
      AppConfig.logger.e(e.toString());
      throw Exception('Error mapping external item to BaseItem: $e');
    }
  }

  static BaseItem fromChamberPreset(ChamberPreset chamberPreset) {
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
        duration: chamberPreset.neomFrequency?.frequency.ceil() ?? 0,
        state: chamberPreset.state,
        permaUrl: chamberPreset.imgUrl, // Usamos la URL de imagen como permaUrl
        ownerId: chamberPreset.ownerId,
        ownerName: "", // ChamberPreset no tiene ownerName explícito
        categories: [],
        metaOwner: null,
        publishedYear: 0,
      );
    } catch (e) {
      AppConfig.logger.e("Error mapping ChamberPreset to BaseItem: $e");
      throw Exception('Error mapping chamber preset to BaseItem: $e');
    }
  }

  static BaseItem fromDynamicItem(dynamic item) {

    BaseItem? baseItem = BaseItem();

    try {
      if(item is AppReleaseItem) {
        baseItem = fromAppReleaseItem(item);
      } else if(item is AppMediaItem) {
        baseItem = fromAppMediaItem(item);
      } else if(item is ExternalItem) {
        baseItem = fromExternalItem(item);
      }
    } catch (e) {
      AppConfig.logger.e("Error mapping ChamberPreset to BaseItem: $e");
      throw Exception('Error mapping chamber preset to BaseItem: $e');
    }

    return baseItem;
  }

}
