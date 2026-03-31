
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/data/firestore/app_release_item_firestore.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/model/playable_item.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_core/utils/enums/app_locale.dart';
import 'package:neom_core/utils/enums/itemlist_type.dart';
import 'package:neom_core/utils/enums/media_item_type.dart';
import 'package:neom_core/utils/enums/media_search_type.dart';
import 'package:neom_core/utils/enums/profile_type.dart';
import 'package:neom_core/utils/enums/subscription_level.dart';
import 'package:neom_core/utils/enums/verification_level.dart';
import 'package:sint/sint.dart';

import 'ui/splash_animations.dart';
import 'ui/theme/app_color.dart';
import 'ui/theme/app_theme.dart';
import 'ui/widgets/title_subtitle_row.dart';
import 'utils/app_locale_utilities.dart';
import 'utils/app_utilities.dart';
import 'utils/constants/app_assets.dart';
import 'utils/constants/app_page_id_constants.dart';
import 'utils/constants/translations/app_translation_constants.dart';
import 'utils/constants/translations/common_translation_constants.dart';
import 'utils/external_utilities.dart';

class AppFlavour {

  /// Whether the current user has admin-level access.
  /// Set via `AppConfig.instance.isAdminMode` after login.
  static bool _isAdminOrAbove() => AppConfig.instance.isAdminMode;

  static Widget getSplashImage() {
    return Image.asset(
      AppAssets.isologoAppWhite,
      height: AppConfig.instance.appInUse == AppInUse.g ? 50 : 150,
      width: 150,
    );
  }

  /// Returns the splash animation delegate for the current app flavour.
  ///
  /// Each app has a unique visual effect:
  /// - **Gigmeout** (g): Sound wave rings expanding outward
  /// - **Emxi** (e): Rising page particles with sway
  /// - **Cyberneom** (c): Nebula stardust spirals
  /// - **Srznik** (d): Digital pulse rings with grid dots
  /// - **neom_app_lite** (o): Breathing circle with minimal particles
  static SplashAnimationDelegate getSplashAnimation() {
    switch (AppConfig.instance.appInUse) {
      case AppInUse.g:
        return SoundWaveDelegate();
      case AppInUse.e:
        return RisingPagesDelegate();
      case AppInUse.c:
        return NebulaDelegate();
      case AppInUse.d:
        return DigitalPulseDelegate();
      case AppInUse.o:
        return BreathingCircleDelegate();
      default:
        return OrbitingParticlesDelegate();
    }
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

  static String getMainItemDetailsRoute(String id, {MediaItemType? type, String slug = ''}) {
    switch (AppConfig.instance.appInUse) {
      case AppInUse.g:
        return AppRouteConstants.audioPlayerMedia;
      case AppInUse.e:
      // Lógica inteligente para EMXI:
      // Si el formato es audio (MP3/Audiolibro), enviamos al reproductor.
        if (type == MediaItemType.audiobook ||
            type == MediaItemType.song ||
            type == MediaItemType.podcast) {
          return AppRouteConstants.audioPlayerMedia;
        }
        // Por defecto para libros o PDF
        return AppRouteConstants.bookPath(id, slug: slug);
      case AppInUse.c:
        return AppRouteConstants.audioPlayerMedia;
      default:
        return '';
    }
  }

  static String getSecondaryItemDetailsRoute(String id, {MediaItemType? type, String slug = ''}) {
    switch (AppConfig.instance.appInUse) {
      case AppInUse.e:
      // Si el item secundario es un PDF, vamos a detalles, si no, al player.
        if (type == MediaItemType.book || type == MediaItemType.pdf) {
          return AppRouteConstants.bookPath(id, slug: slug);
        }
        return AppRouteConstants.audioPlayerMedia;
      case AppInUse.g:
      case AppInUse.c:
      default:
        return AppRouteConstants.audioPlayerMedia;
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

  static IconData getThirdTabIcon() {
    switch (AppConfig.instance.appInUse) {
      case AppInUse.c:
        return FontAwesomeIcons.building;
      case AppInUse.d:
        return FontAwesomeIcons.shop;
        //TODO return Icons.radio;
      case AppInUse.e:
        return FontAwesomeIcons.shop;
      // case AppInUse.g:
      //   return FontAwesomeIcons.building;
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
      // case AppInUse.g:
      //   return AppTranslationConstants.directory;
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
      // case AppInUse.g:
      //   return Icons.play_circle_fill;
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
      // case AppInUse.g:
      //   return AppTranslationConstants.music;

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
      // case AppInUse.g:
      //   return Icons.add_box_outlined;
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
      // case AppInUse.g:
      default:
        return AppTranslationConstants.apps;
    }
  }

  static bool activateHomeActionBtn() {
    switch (AppConfig.instance.appInUse) {
      // case AppInUse.g:
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
        return AppLocaleUtilities.languageFromLocale(Sint.locale!)
            == AppLocale.spanish.name ? AppAssets.logoSloganSpanish
            : AppAssets.logoSloganEnglish;
      case AppInUse.e:
      return AppAssets.logoCompanyWhite;
      case AppInUse.c:
        return AppLocaleUtilities.languageFromLocale(Sint.locale!)
            == AppLocale.spanish.name ? AppAssets.logoSloganSpanish
            : AppAssets.logoSloganEnglish;
      default:
        return AppAssets.isologoAppWhite;
    }
  }

  static String getAppPreLogoPath() {
    switch (AppConfig.instance.appInUse) {
      case AppInUse.g:
      case AppInUse.e:
      case AppInUse.c:
        return AppAssets.isologoAppWhite;
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

  /// Returns the search bar hint text for the audio player, customized per app.
  /// Each app has content aligned with its brand identity.
  static String getAudioSearchHint() {
    switch (AppConfig.instance.appInUse) {
      case AppInUse.g:
        return AppTranslationConstants.searchHintGigmeout.tr;
      case AppInUse.e:
        return AppTranslationConstants.searchHintEmxi.tr;
      case AppInUse.c:
        return AppTranslationConstants.searchHintCyberneom.tr;
      default:
        return AppTranslationConstants.searchHintDefault.tr;
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
        profileTypes = [ProfileType.appArtist, ProfileType.facilitator, ProfileType.host, ProfileType.band, ProfileType.broadcaster];
        break;
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
    return AppColor.scaffold;
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

  static bool showAppBarAddBtn() {

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

    return false;
  }
  
  static bool showAppBarDirectoryBtn() {

    switch(AppConfig.instance.appInUse) {
      case AppInUse.c:
        return false;
      case AppInUse.e:
        return true;
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
        //TODO implement for spiritual core
      case AppInUse.e:
        Sint.toNamed(AppRouteConstants.readingPath(suggestedItem.id, slug: suggestedItem.slug), arguments: [suggestedItem, true, true]);
      case AppInUse.g:
        //TODO implement for music core
      case AppInUse.o:
        //TODO implement for neom core
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

  static bool hasCoverInEvents() {

    switch(AppConfig.instance.appInUse) {
      case AppInUse.c:
        return false;
      case AppInUse.e:
        return false;
      case AppInUse.g:
        return false;
      case AppInUse.o:
        return false;
      default:
        return false;
    }

  }

  static bool showLogoInEvents() {

    switch(AppConfig.instance.appInUse) {
      case AppInUse.c:
        return false;
      case AppInUse.e:
        return false;
      case AppInUse.g:
        return false;
      case AppInUse.o:
        return false;
      default:
        return false;
    }

  }

  static bool showCasete() {
    switch(AppConfig.instance.appInUse) {
      case AppInUse.c:
        return false;
      case AppInUse.e:
        return true;
      case AppInUse.g:
        return true;
      case AppInUse.o:
        return false;
      default:
        return false;
    }
  }

  static bool showBlog() {
    switch(AppConfig.instance.appInUse) {
      case AppInUse.c:
        return false;
      case AppInUse.e:
        return true;
      case AppInUse.g:
        return false;
      case AppInUse.o:
        return false;
      default:
        return false;
    }
  }

  static bool showVst() {
    if (AppConfig.instance.appInUse != AppInUse.g) return false;
    return kDebugMode || _isAdminOrAbove();
  }

  static bool showDaw() {
    if (AppConfig.instance.appInUse != AppInUse.g) return false;
    return kDebugMode || _isAdminOrAbove();
  }

  static bool showLearning() {
    switch(AppConfig.instance.appInUse) {
      case AppInUse.e:
      case AppInUse.g:
        return true;
      default:
        return false;
    }
  }

  static bool showBands() {
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
        return false;
    }
  }

  static bool showNupale() {
    switch(AppConfig.instance.appInUse) {
      case AppInUse.c:
        return true;
      case AppInUse.e:
        return true;
      case AppInUse.g:
        return false;
      case AppInUse.o:
        return false;
      default:
        return false;
    }
  }

  static bool showServices() {
    switch(AppConfig.instance.appInUse) {
      case AppInUse.c:
        return false;
      case AppInUse.e:
        return true;
      case AppInUse.g:
        return false;
      case AppInUse.o:
        return false;
      default:
        return false;
    }
  }

  /// Whether this app shows ads. EMXI is exempt (brand sovereignty).
  /// Cyberneom and Gigmeout show ads to non-subscribers.
  static bool showAds() {
    switch(AppConfig.instance.appInUse) {
      case AppInUse.c: // Cyberneom
        return true;
      case AppInUse.g: // Gigmeout
        return true;
      case AppInUse.e: // EMXI — ad-free sovereignty
        return false;
      default:
        return false;
    }
  }

  static bool showWallet() {
    switch(AppConfig.instance.appInUse) {
      case AppInUse.c:
        return false;
      case AppInUse.e:
        return true;
      case AppInUse.g:
        return true;
      case AppInUse.o:
        return false;
      default:
        return false;
    }
  }

  static bool showReleaseUpload() {
    switch(AppConfig.instance.appInUse) {
      case AppInUse.c:
        return true;
      case AppInUse.e:
        return true;
      case AppInUse.g:
        return true;
      case AppInUse.i:
        return false;
      default:
        return false;
    }
  }

  /// Whether singles in this app accept PDF files (books/articles)
  /// vs audio files (songs/meditations).
  static bool singleAcceptsPdf() {
    switch (AppConfig.instance.appInUse) {
      case AppInUse.e: // EMXI — books, articles
      case AppInUse.c: // Cyberneom — research, articles
        return true;
      default:
        return false; // Gigmeout, others — audio singles
    }
  }

  /// Icon for the release single type based on app context.
  static IconData getSingleIcon() {
    switch (AppConfig.instance.appInUse) {
      case AppInUse.c:
        return Icons.self_improvement_outlined;
      case AppInUse.e:
        return Icons.menu_book;
      default:
        return Icons.album_outlined;
    }
  }

  /// Icon for the release album type based on app context.
  static IconData getAlbumIcon() {
    switch (AppConfig.instance.appInUse) {
      case AppInUse.c:
        return Icons.self_improvement_outlined;
      case AppInUse.e:
        return Icons.headphones_outlined;
      default:
        return Icons.album_outlined;
    }
  }

  /// Whether cover images should use vertical (portrait) aspect ratio.
  /// Books/articles use vertical covers; music uses square.
  static bool useVerticalCover() {
    return singleAcceptsPdf();
  }

  /// Available album subtypes per app.
  /// Returns the ItemlistType options shown when user selects "Album".
  static List<({ItemlistType type, IconData icon, String nameKey, String descKey})> getAlbumSubtypes() {
    switch (AppConfig.instance.appInUse) {
      case AppInUse.e:
        return [
          (type: ItemlistType.audiobook, icon: Icons.headphones, nameKey: 'audiobook', descKey: 'audiobookDesc'),
          (type: ItemlistType.podcast, icon: Icons.podcasts, nameKey: 'podcast', descKey: 'podcastDesc'),
        ];
      case AppInUse.g:
        return [
          (type: ItemlistType.ep, icon: Icons.album, nameKey: 'ep', descKey: 'epDesc'),
          (type: ItemlistType.album, icon: Icons.library_music, nameKey: 'album', descKey: 'albumDesc'),
          (type: ItemlistType.demo, icon: Icons.mic_external_on, nameKey: 'demo', descKey: 'demoDesc'),
          (type: ItemlistType.podcast, icon: Icons.podcasts, nameKey: 'podcast', descKey: 'podcastDesc'),
        ];
      case AppInUse.c:
        return [
          (type: ItemlistType.meditation, icon: Icons.self_improvement, nameKey: 'meditation', descKey: 'meditationDesc'),
          (type: ItemlistType.podcast, icon: Icons.podcasts, nameKey: 'podcast', descKey: 'podcastDesc'),
        ];
      default:
        return [
          (type: ItemlistType.album, icon: Icons.album, nameKey: 'album', descKey: 'albumDesc'),
        ];
    }
  }

  /// Directory is available in all main apps (e, c, g).
  static bool showDirectory() {
    switch(AppConfig.instance.appInUse) {
      case AppInUse.e:
        return true;
      case AppInUse.c:
        return true;
      case AppInUse.g:
        return true;
      default:
        return false;
    }
  }

  /// Booking is only available in Gigmeout (venue/rehearsal booking).
  static bool showBooking() {
    switch(AppConfig.instance.appInUse) {
      case AppInUse.g:
        return true;
      default:
        return false;
    }
  }

  static Object? getCaseteItem() {
    switch(AppConfig.instance.appInUse) {
      case AppInUse.c:
        return AppReleaseItem();
      case AppInUse.e:
        return AppMediaItem();
      case AppInUse.g:
        return AppReleaseItem();
      case AppInUse.o:
        return AppReleaseItem();
      default:
        return null;
    }
  }

  static SubscriptionLevel getCaseteSubscription() {
    switch(AppConfig.instance.appInUse) {
      case AppInUse.c:
        return SubscriptionLevel.basic;
      case AppInUse.e:
        return SubscriptionLevel.plus;
      case AppInUse.g:
        return SubscriptionLevel.basic;
      case AppInUse.o:
        return SubscriptionLevel.basic;
      default:
        return SubscriptionLevel.basic;
    }

  }

  static Future<void> navigateToShelfItem(PlayableItem item) async {
    if(Sint.isRegistered(tag: AppPageIdConstants.mediaPlayer)) {
      Sint.delete(tag: AppPageIdConstants.mediaPlayer);
    }

    // If streamUrl is empty and it's an AppReleaseItem, try fetching complete data
    AppReleaseItem? releaseItem = item is AppReleaseItem ? item : null;
    if (item.streamUrl.isEmpty && item.id.isNotEmpty && releaseItem != null) {
      try {
        final fullItem = await AppReleaseItemFirestore().retrieve(item.id);
        if (fullItem.id.isNotEmpty) {
          releaseItem = fullItem;
        }
      } catch (_) {}
    }

    final PlayableItem navItem = releaseItem ?? item;

    switch(AppConfig.instance.appInUse) {
      case AppInUse.e:
        if(navItem.streamUrl.isNotEmpty && navItem.isBookContent) {
          Sint.toNamed(AppRouteConstants.readingPath(navItem.id, slug: navItem.slug), arguments: [navItem, true], preventDuplicates: false);
        } else if(navItem.streamUrl.isNotEmpty) {
          AppUtilities.gotoItemDetails(navItem);
        } else if (releaseItem?.webPreviewUrl?.isNotEmpty ?? false) {
          ExternalUtilities.launchURL(releaseItem!.webPreviewUrl!);
        } else {
          Sint.toNamed(AppFlavour.getMainItemDetailsRoute(navItem.id, slug: navItem.slug), arguments: [navItem], preventDuplicates: false);
        }
      case AppInUse.c:
      case AppInUse.g:
      case AppInUse.o:
      default:
        AppUtilities.gotoItemDetails(navItem);
    }
  }

  static Future<void> navigateToReleaseItem(String referenceId) async {
    if(Sint.isRegistered(tag: AppPageIdConstants.mediaPlayer)) {
      Sint.delete(tag: AppPageIdConstants.mediaPlayer);
    }
    try {
      final releaseItem = await AppReleaseItemFirestore().retrieve(referenceId);
      if (releaseItem.id.isNotEmpty) {
        navigateToShelfItem(releaseItem);
      } else {
        Sint.toNamed(AppFlavour.getMainItemDetailsRoute(referenceId), arguments: [referenceId], preventDuplicates: false);
      }
    } catch (e) {
      Sint.toNamed(AppFlavour.getMainItemDetailsRoute(referenceId), arguments: [referenceId], preventDuplicates: false);
    }
  }

  static Widget getSalesModelInfoWidget(BuildContext context) {
    switch(AppConfig.instance.appInUse) {
      case AppInUse.c:
        return SizedBox.shrink();
      case AppInUse.e:
        return Column(
          children: [
            TitleSubtitleRow(AppTranslationConstants.digitalSalesModel.tr,
              subtitle: AppTranslationConstants.digitalSalesModelMsg.tr,
              showDivider: false,
            ),
            AppTheme.heightSpace10,
            SizedBox(
              width: AppTheme.fullWidth(context)*0.5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Image.asset(AppAssets.releaseUploadIntro,
                  fit: BoxFit.cover,),
              ),
            ),
            AppTheme.heightSpace10,
            TitleSubtitleRow(AppTranslationConstants.physicalSalesModel.tr,
                subtitle: AppTranslationConstants.physicalSalesModelMsg.tr,
                showDivider: false
            ),
            AppTheme.heightSpace10,
          ],
        );
      case AppInUse.g:
        return SizedBox.shrink();
      case AppInUse.o:
        return SizedBox.shrink();
      default:
        return SizedBox.shrink();
    }

  }

  /// Returns the translation key for the single release type name per app flavour.
  static String getSingleTypeName() {
    switch (AppConfig.instance.appInUse) {
      case AppInUse.e: return 'singleTypeNameE';
      case AppInUse.c: return 'singleTypeNameC';
      default: return 'singleTypeNameG';
    }
  }

  /// Returns the translation key for the album release type name per app flavour.
  static String getAlbumTypeName() {
    switch (AppConfig.instance.appInUse) {
      case AppInUse.e: return 'albumTypeNameE';
      case AppInUse.c: return 'albumTypeNameC';
      default: return 'albumTypeNameG';
    }
  }

  /// Returns the translation key for the single release type description per app flavour.
  static String getSingleTypeDesc() {
    switch (AppConfig.instance.appInUse) {
      case AppInUse.e: return 'singleTypeDescE';
      case AppInUse.c: return 'singleTypeDescC';
      default: return 'singleTypeDescG';
    }
  }

  /// Returns the translation key for the album release type description per app flavour.
  static String getAlbumTypeDesc() {
    switch (AppConfig.instance.appInUse) {
      case AppInUse.e: return 'albumTypeDescE';
      case AppInUse.c: return 'albumTypeDescC';
      default: return 'albumTypeDescG';
    }
  }

}
