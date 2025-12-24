import 'package:neom_core/app_config.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/model/external_item.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/utils/enums/app_media_source.dart';
import 'package:neom_core/utils/enums/media_item_type.dart';
import 'package:neom_core/utils/enums/release_type.dart';
import '../text_utilities.dart';

class AppMediaItemMapper {

  static List<AppMediaItem> listFromMap(Map<String, List<dynamic>> map) {
    List<AppMediaItem> items = [];
    try {

    } catch (e) {
      throw Exception('Error parsing item: $e');
    }

    return items;
  }

  static List<AppMediaItem> listFromList(List<dynamic>? list) {
    List<AppMediaItem> items = [];
    try {

    } catch (e) {
      throw Exception('Error parsing item: $e');
    }

    return items;
  }

  static AppMediaItem fromAppReleaseItem(AppReleaseItem releaseItem) {
    try {
      return AppMediaItem(
        id: releaseItem.id,
        name: releaseItem.name,
        description: releaseItem.description,
        lyrics: releaseItem.lyrics ?? '',
        language: releaseItem.language,
        album: releaseItem.metaName ?? TextUtilities.getMediaName(releaseItem.ownerName),
        albumId: releaseItem.metaId,
        externalArtists: releaseItem.featInternalArtists?.values.toList(),
        duration: releaseItem.duration,
        categories: releaseItem.tags,
        imgUrl: releaseItem.imgUrl,
        galleryUrls: releaseItem.galleryUrls,
        url: releaseItem.previewUrl,
        metaOwner: releaseItem.metaOwner,
        publishedYear: releaseItem.publishedYear,
        releaseDate: releaseItem.createdTime,
        permaUrl: releaseItem.externalUrl ?? '',
        featInternalArtists: releaseItem.featInternalArtists,
        ownerName: TextUtilities.getArtistName(releaseItem.ownerName),
        ownerId: releaseItem.ownerEmail,
        likes: releaseItem.likedProfiles?.length ?? 0,
        state: releaseItem.state,
        mediaSource: AppMediaSource.internal,
        type: releaseItem.type == ReleaseType.episode ? MediaItemType.podcast : releaseItem.type == ReleaseType.chapter ? MediaItemType.audiobook : releaseItem.mediaType
      );
    } catch (e) {
      throw Exception('Error parsing item: $e');
    }
  }

  static AppMediaItem fromExternalItem(ExternalItem externalItem, {MediaItemType itemType = MediaItemType.neomPreset}) {
    try {
      // Mapeamos los campos de ExternalItem (que ahora heredan de BaseItem)
      // a la estructura de AppMediaItem.
      return AppMediaItem(
          id: externalItem.id,
          name: externalItem.name,
          description: externalItem.description,
          lyrics: externalItem.lyrics,
          language: externalItem.language,
          album: externalItem.album,
          albumId: externalItem.albumId,
          externalArtists: externalItem.externalArtists,
          duration: externalItem.duration,
          categories: externalItem.categories,
          imgUrl: externalItem.imgUrl,
          galleryUrls: externalItem.galleryUrls,
          url: externalItem.url,
          metaOwner: externalItem.metaOwner,
          publishedYear: externalItem.publishedYear,
          releaseDate: externalItem.releaseDate,
          permaUrl: externalItem.permaUrl,
          ownerName: externalItem.ownerName,
          ownerId: externalItem.ownerId,
          likes: externalItem.likes,
          state: externalItem.state,
          // La fuente es externa, pero AppMediaItem solo tiene AppMediaSource.
          // Asumimos que si viene de ExternalItem, se marca como external.
          mediaSource: AppMediaSource.external,
          type: externalItem.type
      );
    } catch (e) {
      AppConfig.logger.e(e.toString());
      throw Exception('Error mapping external item to AppMediaItem: $e');
    }
  }

  static List<AppMediaItem> mapItemsFromItemlist(Itemlist itemlist) {

    List<AppMediaItem> appMediaItems = [];

    if(itemlist.appMediaItems != null) {
      appMediaItems.addAll(itemlist.appMediaItems!);
    }

    if(itemlist.appReleaseItems != null) {
      for (var element in itemlist.appReleaseItems!) {
        appMediaItems.add(AppMediaItemMapper.fromAppReleaseItem(element));
      }
    }

    if(itemlist.externalItems != null) {
      for (var element in itemlist.externalItems!) {
        appMediaItems.add(AppMediaItemMapper.fromExternalItem(element));
      }
    }

    AppConfig.logger.t("Retrieving ${appMediaItems.length} total AppMediaItems.");
    return appMediaItems;
  }

  ///DEPRECATED
  // static AppMediaItem fromChamberPreset(NeomChamberPreset chamberPreset) {
  //   return AppMediaItem(
  //       id: chamberPreset.id,
  //       name: chamberPreset.name,
  //       ownerName: "",
  //       ownerId: chamberPreset.ownerId,
  //       album: "",
  //       imgUrl: chamberPreset.imgUrl,
  //       duration:  chamberPreset.mainFrequency?.frequency.ceil() ?? 0,
  //       url: "",
  //       description: chamberPreset.description.isNotEmpty ? chamberPreset.description : chamberPreset.mainFrequency?.description ?? "",
  //       metaOwner: "",
  //       state: chamberPreset.state,
  //       categories: [],
  //       mediaSource: AppMediaSource.internal,
  //       releaseDate: 0,
  //       is320Kbps: true,
  //       likes: 0,
  //       lyrics: '',
  //       permaUrl: chamberPreset.imgUrl,
  //       publishedYear: 0,
  //       type: MediaItemType.neomPreset
  //   );

}
