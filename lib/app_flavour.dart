
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_core/utils/enums/app_locale.dart';
import 'package:neom_core/utils/enums/profile_type.dart';
import 'package:neom_core/utils/enums/verification_level.dart';

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
      case AppInUse.g:
        return FontAwesomeIcons.calendar;
      case AppInUse.e:
        return FontAwesomeIcons.calendar;
      case AppInUse.c:
        return FontAwesomeIcons.calendar;
      default:
        return FontAwesomeIcons.calendar;
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
      case AppInUse.g:
        return FontAwesomeIcons.building;
      case AppInUse.e:
        return FontAwesomeIcons.shop;
      case AppInUse.c:
        return FontAwesomeIcons.building;
      default:
        return FontAwesomeIcons.shop;
    }
  }

  static String getThirdTabTitle() {
    switch (AppConfig.instance.appInUse) {
      case AppInUse.g:
        return AppTranslationConstants.directory;
      case AppInUse.e:
        return AppTranslationConstants.bookShop;
      case AppInUse.c:
        return AppTranslationConstants.directory;
      default:
        return AppTranslationConstants.shop;
    }
  }

  static IconData getForthTabIcon() {
    switch (AppConfig.instance.appInUse) {
      case AppInUse.g:
        return Icons.play_circle_fill;
      case AppInUse.e:
        return FontAwesomeIcons.headphones;
      case AppInUse.c:
        return LucideIcons.audioWaveform;
      default:
        return LucideIcons.headphones;
    }
  }

  static String getFortTabTitle() {
    switch (AppConfig.instance.appInUse) {
      case AppInUse.g:
        return AppTranslationConstants.music;
      case AppInUse.e:
        return CommonTranslationConstants.audioLibrary;
      case AppInUse.c:
        return CommonTranslationConstants.audioLibrary;
      default:
        return CommonTranslationConstants.audioLibrary;
    }
  }

  static IconData getHomeActionBtnIcon() {
    switch (AppConfig.instance.appInUse) {
      case AppInUse.g:
        return CupertinoIcons.add;
      case AppInUse.e:
        return CupertinoIcons.add;
      case AppInUse.c:
      case AppInUse.o:
        return FontAwesomeIcons.om;
      default:
        return CupertinoIcons.add;
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
        return CommonTranslationConstants.audioLibrary.tr;
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

}
