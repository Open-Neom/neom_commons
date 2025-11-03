
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_core/utils/enums/app_locale.dart';
import 'package:neom_core/utils/enums/itemlist_type.dart';
import 'package:neom_core/utils/enums/media_item_type.dart';
import 'package:neom_core/utils/enums/media_search_type.dart';
import 'package:neom_core/utils/enums/profile_type.dart';
import 'package:neom_core/utils/enums/verification_level.dart';

import 'ui/theme/app_color.dart';
import 'utils/app_locale_utilities.dart';
import 'utils/constants/app_assets.dart';
import 'utils/constants/app_page_id_constants.dart';
import 'utils/constants/translations/app_translation_constants.dart';
import 'utils/constants/translations/common_translation_constants.dart';

class AppFlavour {

  static Widget getSplashImage() {
    return Image.asset(
      AppAssets.logoAppWhite,
      height: AppConfig.instance.appInUse == AppInUse.g ? 50 : 150,
      width: 150,
    );
  }

  static IconData getAppItemIcon() {
    switch (AppConfig.instance.appInUse) {
      case AppInUse.g:
        return Icons.music_note;
      case AppInUse.e:
        return Icons.book;
      case AppInUse.c:
        return FontAwesomeIcons.waveSquare;
      default:
        return Icons.code;
    }
  }

  static IconData getInstrumentIcon() {
    switch (AppConfig.instance.appInUse) {
      case AppInUse.g:
        return FontAwesomeIcons.guitar;
      case AppInUse.e:
        return FontAwesomeIcons.pencil;
      case AppInUse.c:
        return FontAwesomeIcons.waveSquare;
      default:
        return Icons.device_unknown;
    }
  }

  static IconData getSyncIcon() {
    switch (AppConfig.instance.appInUse) {
      case AppInUse.g:
        return FontAwesomeIcons.spotify;
      case AppInUse.e:
        return FontAwesomeIcons.bookOpenReader;
      case AppInUse.c:
      case AppInUse.o:
        return Icons.sync;
      default:
        return Icons.sync;
    }
  }

  static String getMainItemDetailsRoute() {
    switch (AppConfig.instance.appInUse) {
      case AppInUse.g:
        return AppRouteConstants.audioPlayerMedia;
      case AppInUse.e:
        return AppRouteConstants.bookDetails;
      case AppInUse.c:
        return AppRouteConstants.audioPlayerMedia;
      default:
        return '';
    }
  }

  static String getSecondaryItemDetailsRoute() {
    switch (AppConfig.instance.appInUse) {
      case AppInUse.g:
        return AppRouteConstants.audioPlayerMedia;
      case AppInUse.e:
        return AppRouteConstants.audioPlayerMedia;
      case AppInUse.c:
        return AppRouteConstants.audioPlayerMedia;
      default:
          return '';
    }
  }

  static String getMainItemDetailsTag() {
    switch (AppConfig.instance.appInUse) {
      case AppInUse.g:
        return AppPageIdConstants.mediaPlayer;
      case AppInUse.e:
        return AppPageIdConstants.bookDetails;
      case AppInUse.c:
        return AppPageIdConstants.mediaPlayer;
      default:
        return '';
    }
  }

  static String getSecondaryItemDetailsTag() {
    switch (AppConfig.instance.appInUse) {
      case AppInUse.g:
        return AppPageIdConstants.mediaPlayer;
      case AppInUse.e:
        return AppPageIdConstants.mediaPlayer;
      case AppInUse.c:
        return AppPageIdConstants.mediaPlayer;
      default:
        return '';
    }
  }

  static String getEventVector() {
    switch (AppConfig.instance.appInUse) {
      case AppInUse.g:
        return AppAssets.bandVector01;
      case AppInUse.e:
        return AppAssets.eventVector01;
      case AppInUse.c:
        return AppAssets.spiritualWitchy;
      default:
        return '';
    }
  }

  static IconData getSecondTabIcon() {
    switch (AppConfig.instance.appInUse) {
      case AppInUse.c:
        return Icons.event;
      case AppInUse.d:
        return Icons.event;
      case AppInUse.e:
        return Icons.event;
      case AppInUse.g:
        return Icons.event;
      default:
        return Icons.event;
    }
  }

  static String getSecondTabTitle() {
    switch (AppConfig.instance.appInUse) {
      case AppInUse.g:
        return AppTranslationConstants.events;
      case AppInUse.e:
        return AppTranslationConstants.events;
      case AppInUse.c:
        return AppTranslationConstants.events;
      default:
        return AppTranslationConstants.events;
    }
  }

  static IconData getThirdTabIcon() {
    switch (AppConfig.instance.appInUse) {
      case AppInUse.c:
        return FontAwesomeIcons.building;
      case AppInUse.d:
        return FontAwesomeIcons.shop;
        //TODO return Icons.radio;
      case AppInUse.e:
        return FontAwesomeIcons.shop;
      case AppInUse.g:
        return FontAwesomeIcons.building;
      default:
        return FontAwesomeIcons.shop;
    }
  }

  static String getThirdTabTitle() {
    switch (AppConfig.instance.appInUse) {
      case AppInUse.c:
        return AppTranslationConstants.directory;
      case AppInUse.d:
        return AppTranslationConstants.shop;
      //TODO return AppTranslationConstants.radio
      case AppInUse.e:
        return AppTranslationConstants.bookShop;
      case AppInUse.g:
        return AppTranslationConstants.directory;
      default:
        return AppTranslationConstants.shop;
    }
  }

  static IconData getForthTabIcon() {
    switch (AppConfig.instance.appInUse) {
      case AppInUse.c:
        return LucideIcons.audioWaveform;
      case AppInUse.d:
        return Icons.chat_bubble;
        //TODO return Icons.tv;
      case AppInUse.e:
        return FontAwesomeIcons.headphones;
      case AppInUse.g:
        return Icons.play_circle_fill;
      default:
        return LucideIcons.headphones;
    }
  }

  static String getFortTabTitle() {
    switch (AppConfig.instance.appInUse) {
      case AppInUse.c:
        return AppTranslationConstants.audioLibrary;
      case AppInUse.d:
        return AppTranslationConstants.radio;
        //TODO return AppTranslationConstants.tv;
      case AppInUse.e:
        return AppTranslationConstants.audioLibrary;
      case AppInUse.g:
        return AppTranslationConstants.music;

      default:
        return AppTranslationConstants.audioLibrary;
    }
  }

  static IconData getCentralTabIcon() {
    switch (AppConfig.instance.appInUse) {
      case AppInUse.c:
        return Icons.add_box_outlined;
      case AppInUse.d:
        return Icons.apps;
      case AppInUse.e:
        return Icons.add_box_outlined;
      case AppInUse.g:
        return Icons.add_box_outlined;
      case AppInUse.o:
        return Icons.add_box_outlined;
      default:
        return Icons.apps;
    }
  }

  static String getCentralTabTitle() {
    switch (AppConfig.instance.appInUse) {
      case AppInUse.c:
      case AppInUse.d:
      case AppInUse.e:
      case AppInUse.g:
      default:
        return AppTranslationConstants.apps;
    }
  }

  static bool activateHomeActionBtn() {
    switch (AppConfig.instance.appInUse) {
      case AppInUse.g:
      case AppInUse.e:
        return false;
      case AppInUse.c:
      case AppInUse.o:
        return true;
      default:
        return false;
    }
  }

  static IconData getHomeActionBtnIcon() {
    switch (AppConfig.instance.appInUse) {
      case AppInUse.g:
        return Icons.add;
      case AppInUse.e:
        return Icons.add;
      case AppInUse.c:
      case AppInUse.o:
        return FontAwesomeIcons.om;
      default:
        return Icons.add;
    }
  }

  static String getHomeActionBtnTooltip() {
    switch (AppConfig.instance.appInUse) {
      case AppInUse.g:
        return CommonTranslationConstants.createPost.tr;
      case AppInUse.e:
        return CommonTranslationConstants.createPost.tr;
      case AppInUse.c:
      case AppInUse.o:
        return AppTranslationConstants.session.tr;
      default:
        return CommonTranslationConstants.createPost.tr;
    }
  }

  static String getAppLogoPath() {
    switch (AppConfig.instance.appInUse) {
      case AppInUse.g:
        return AppLocaleUtilities.languageFromLocale(Get.locale!)
            == AppLocale.spanish.name ? AppAssets.logoSloganSpanish
            : AppAssets.logoSloganEnglish;
      case AppInUse.e:
      return AppAssets.logoCompanyWhite;
      case AppInUse.c:
        return AppAssets.logoAppWhite;
      default:
        return AppAssets.logoAppWhite;
    }
  }

  static String getAppPreLogoPath() {
    switch (AppConfig.instance.appInUse) {
      case AppInUse.g:
        return '';
      case AppInUse.e:
        return AppAssets.logoAppWhite;
      case AppInUse.c:
        return '';
      default:
        return '';
    }
  }

  static String getIconPath() {
    return AppAssets.iconWhite;
  }

  static String getAudioPlayerHomeTitle() {
    switch (AppConfig.instance.appInUse) {
      case AppInUse.g:
        return AppTranslationConstants.music.tr;
      default:
        return AppTranslationConstants.audioLibrary.tr;
    }
  }

  static Widget getVerificationIcon(VerificationLevel level, {double? size}) {

    Widget icon = Icon(Icons.check_circle_outline, size: size);

    switch (AppConfig.instance.appInUse) {
      case AppInUse.e:
        switch(level) {
          case VerificationLevel.verified:
            icon = Icon(Icons.check_circle, size: size); // Sin verificación
          case VerificationLevel.ambassador:
            icon = Icon(Icons.verified_user, size: size); // Verificado como Embajador
          case VerificationLevel.artist:
            icon = Icon(Icons.verified, size: size); // Publicado o verificado completo
          case VerificationLevel.professional:
            icon = Icon(Icons.handshake, size: size); // Verificado como Profesional
          case VerificationLevel.premium:
            icon = Icon(Icons.auto_awesome, size: size); // Verificación Premium
          case VerificationLevel.platinum:
            icon = Icon(Icons.workspace_premium, size: size); // Verificación Platino
          default:
            icon = Icon(Icons.check_circle_outline, size: size); // Icono predeterminado
        }
      case AppInUse.g:
      case AppInUse.c:
      default:
        return Icon(Icons.verified, size: size); // Publicado o verificado completo
    }

    return icon;
  }

  static List<ProfileType> getProfileTypes() {

    List<ProfileType> profileTypes = List.from(ProfileType.values);
    profileTypes.removeWhere((type) => type == ProfileType.broadcaster);

    switch(AppConfig.instance.appInUse) {
      case AppInUse.g:
        profileTypes.removeWhere((type) => type == ProfileType.band);
        profileTypes.removeWhere((type) => type == ProfileType.researcher);
      case AppInUse.e:
        profileTypes.removeWhere((type) => type == ProfileType.band);
        profileTypes.removeWhere((type) => type == ProfileType.researcher);
      case AppInUse.c:
        profileTypes.removeWhere((type) => type == ProfileType.band);
      default:
        break;
    }

    return profileTypes;
  }

  static List<ProfileType> getDirectoryProfileTypes() {

    List<ProfileType> profileTypes = [];

    switch(AppConfig.instance.appInUse) {
      case AppInUse.g:
        profileTypes = [ProfileType.facilitator, ProfileType.host, ProfileType.band, ProfileType.appArtist];
      case AppInUse.e:
      case AppInUse.c:
      default:
      profileTypes = [ProfileType.facilitator, ProfileType.host];
        break;
    }

    return profileTypes;
  }

  static bool isNeomApp() {

    switch(AppConfig.instance.appInUse) {
      case AppInUse.c:
      case AppInUse.o:
        return true;
      case AppInUse.g:
      case AppInUse.e:
      default:
        break;
    }

    return false;
  }

  static Color getBackgroundColor() {

    switch(AppConfig.instance.appInUse) {
      case AppInUse.c:
        return AppColor.main50;
      case AppInUse.e:
        return AppColor.darkBackground;
      case AppInUse.g:
        break;
      case AppInUse.o:
        return AppColor.main50;
      default:
        break;
    }

    return AppColor.getMain();
  }

  static bool gotoDetails() {

    switch(AppConfig.instance.appInUse) {
      case AppInUse.c:
        return true;
      case AppInUse.e:
        return true;
      case AppInUse.g:
        return false;
      case AppInUse.o:
        return true;
      default:
        break;
    }

    return true;
  }

  static bool addAudioLimitation() {

    switch(AppConfig.instance.appInUse) {
      case AppInUse.c:
        return false;
      case AppInUse.e:
        return false;
      case AppInUse.g:
        return true;
      case AppInUse.o:
        return false;
      default:
        break;
    }

    return false;
  }

  static bool showAppBarAddButton() {

    switch(AppConfig.instance.appInUse) {
      case AppInUse.c:
        return true;
      case AppInUse.e:
        return false;
      case AppInUse.g:
        return false;
      case AppInUse.o:
        return true;
      default:
        break;
    }

    return false;
  }

  static MediaItemType getDefaultItemType() {

    switch(AppConfig.instance.appInUse) {
      case AppInUse.c:
        return MediaItemType.neomPreset;
      case AppInUse.e:
        return MediaItemType.book;
      case AppInUse.g:
        return MediaItemType.song;
      case AppInUse.o:
        return MediaItemType.neomPreset;
      default:
        break;
    }

    return MediaItemType.neomPreset;
  }

  static ItemlistType getDefaultItemlistType() {

    switch(AppConfig.instance.appInUse) {
      case AppInUse.c:
        return ItemlistType.playlist;
      case AppInUse.e:
        return ItemlistType.readlist;
      case AppInUse.g:
        return ItemlistType.playlist;
      case AppInUse.o:
        return ItemlistType.playlist;
      default:
        break;
    }
    return ItemlistType.playlist;
  }

  static MediaSearchType getDefaultMediaSearchType() {

    switch(AppConfig.instance.appInUse) {
      case AppInUse.c:
        return MediaSearchType.song;
      case AppInUse.e:
        return MediaSearchType.book;
      case AppInUse.g:
        return MediaSearchType.song;
      case AppInUse.o:
        return MediaSearchType.song;
      default:
        return MediaSearchType.song;
    }

  }


  static void gotoSuggestedItem() {
    AppReleaseItem suggestedItem = AppReleaseItem(
      previewUrl: AppConfig.instance.appInfo.suggestedUrl,
    );

    switch(AppConfig.instance.appInUse) {
      case AppInUse.c:
        //TODO implement for spiritual app
      case AppInUse.e:
        Get.toNamed(AppRouteConstants.pdfViewer, arguments: [suggestedItem, true, true]);
      case AppInUse.g:
        //TODO implement for music app
      case AppInUse.o:
        //TODO implement for neom app
      default:
        break;
    }

  }

  static String getSuggestedItemText() {

    switch(AppConfig.instance.appInUse) {
      case AppInUse.c:
        return CommonTranslationConstants.suggestedMeditation.tr;
      case AppInUse.e:
        return CommonTranslationConstants.suggestedReading.tr;
      case AppInUse.g:
        return CommonTranslationConstants.suggestedSong.tr;
      case AppInUse.o:
        return CommonTranslationConstants.suggestedArticle.tr;
      default:
        return '';
    }

  }

}
