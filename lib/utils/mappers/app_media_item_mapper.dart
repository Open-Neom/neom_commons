import 'package:neom_core/app_config.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/domain/model/neom/chamber_preset.dart';
import 'package:neom_core/utils/enums/app_media_source.dart';
import 'package:neom_core/utils/enums/media_item_type.dart';
import 'package:neom_core/utils/enums/release_type.dart';
import '../text_utilities.dart';

class AppMediaItemMapper {

  static List<AppMediaItem> listFromMap(Map<String, List<dynamic>> map) {
    List<AppMediaItem> items = [];
    try {

    } catch (e) {
      throw Exception('Error parsing song item: $e');
    }

    return items;
  }

  static List<AppMediaItem> listFromList(List<dynamic>? list) {
    List<AppMediaItem> items = [];
    try {

    } catch (e) {
      throw Exception('Error parsing song item: $e');
    }

    return items;
  }

  static AppMediaItem fromAppReleaseItem(AppReleaseItem releaseItem, {MediaItemType itemType = MediaItemType.song}) {
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
        genres: releaseItem.tags,
        imgUrl: releaseItem.imgUrl,
        allImgs: releaseItem.galleryUrls,
        url: releaseItem.previewUrl,
        publisher: releaseItem.publisher,
        publishedYear: releaseItem.publishedYear,
        releaseDate: releaseItem.createdTime,
        permaUrl: releaseItem.externalUrl ?? '',
        featInternalArtists: releaseItem.featInternalArtists,
        artist: TextUtilities.getArtistName(releaseItem.ownerName),
        artistId: releaseItem.ownerEmail,
        likes: releaseItem.likedProfiles?.length ?? 0,
        state: releaseItem.state,
        mediaSource: AppMediaSource.internal,
        type: releaseItem.type == ReleaseType.episode ? MediaItemType.podcast : releaseItem.type == ReleaseType.chapter ? MediaItemType.audiobook : itemType
      );
    } catch (e) {
      throw Exception('Error parsing song item: $e');
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

    // if(itemlist.chamberPresets != null) {
    //   itemlist.chamberPresets!.forEach((element) {
    //     appMediaItems.add(AppMediaItem.fromAppItem(element));
    //   });
    // }

    AppConfig.logger.t("Retrieving ${appMediaItems.length} total AppMediaItems.");
    return appMediaItems;
  }

  static AppMediaItem fromChamberPreset(ChamberPreset chamberPreset) {
    return AppMediaItem(
        id: chamberPreset.id,
        name: chamberPreset.name,
        artist: "",
        artistId: chamberPreset.ownerId,
        album: "",
        imgUrl: chamberPreset.imgUrl,
        duration:  chamberPreset.neomFrequency?.frequency.ceil() ?? 0,
        url: "",
        description: chamberPreset.description.isNotEmpty ? chamberPreset.description : chamberPreset.neomFrequency?.description ?? "",
        publisher: "",
        state: chamberPreset.state,
        genres: [],
        mediaSource: AppMediaSource.internal,
        releaseDate: 0,
        is320Kbps: true,
        likes: 0,
        lyrics: '',
        permaUrl: chamberPreset.imgUrl,
        publishedYear: 0,
        type: MediaItemType.neomPreset
    );

  }

}
