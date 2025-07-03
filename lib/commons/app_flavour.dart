
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:neom_core/core/app_config.dart';
import 'package:neom_core/core/utils/constants/app_route_constants.dart';
import 'package:neom_core/core/utils/enums/app_in_use.dart';
import 'package:neom_core/core/utils/enums/profile_type.dart';
import 'package:neom_core/core/utils/enums/verification_level.dart';

import 'utils/constants/app_assets.dart';
import 'utils/constants/app_locale_constants.dart';
import 'utils/constants/app_page_id_constants.dart';
import 'utils/constants/app_translation_constants.dart';

class AppFlavour {

  static final AppFlavour _instance = AppFlavour._internal();

  factory AppFlavour({required AppInUse inUse, required String version}) {
    _instance._init(inUse, version);
    return _instance;
  }

  AppFlavour._internal(); // Constructor privado para Singleton

  static AppInUse appInUse = AppInUse.o;
  static String appVersion = "";

  /// Inicializa las propiedades si aún no se han leído
  Future<void> _init(AppInUse inUse, String version) async {
    appInUse = inUse;
    appVersion = version;
  }


  static Widget getSplashImage() {
    return Image.asset(
      AppAssets.logoAppWhite,
      height: AppConfig.appInUse == AppInUse.g ? 50 : 150,
      width: 150,
    );
  }
  static IconData getAppItemIcon() {
    switch (appInUse) {
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
    switch (appInUse) {
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
    switch (appInUse) {
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
    switch (appInUse) {
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
    switch (appInUse) {
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
    switch (appInUse) {
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
    switch (appInUse) {
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
    switch (appInUse) {
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
    switch (appInUse) {
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
    switch (appInUse) {
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
    switch (appInUse) {
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
    switch (appInUse) {
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
    switch (appInUse) {
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
    switch (appInUse) {
      case AppInUse.g:
        return AppTranslationConstants.music;
      case AppInUse.e:
        return AppTranslationConstants.audioLibrary;
      case AppInUse.c:
        return AppTranslationConstants.audioLibrary;
      default:
        return AppTranslationConstants.audioLibrary;
    }
  }

  static IconData getHomeActionBtnIcon() {
    switch (appInUse) {
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

  static String getAppLogoPath() {
    switch (appInUse) {
      case AppInUse.g:
        return AppLocaleConstants.languageFromLocale(Get.locale!)
            == AppTranslationConstants.spanish ? AppAssets.logoSloganSpanish
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
    switch (appInUse) {
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
    switch (appInUse) {
      case AppInUse.g:
        return AppTranslationConstants.music.tr;
      default:
        return AppTranslationConstants.audioLibrary.tr;
    }
  }

  static Widget getVerificationIcon(VerificationLevel level, {double? size}) {

    Widget icon = Icon(Icons.check_circle_outline, size: size);

    switch (appInUse) {
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

    switch(AppConfig.appInUse) {
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

    switch(AppConfig.appInUse) {
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
