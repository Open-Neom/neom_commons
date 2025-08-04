import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/domain/use_cases/inbox_service.dart';
import 'package:neom_core/domain/use_cases/login_service.dart';
import 'package:neom_core/domain/use_cases/profile_service.dart';
import 'package:neom_core/domain/use_cases/settings_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/core_utilities.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_core/utils/enums/profile_type.dart';
import 'package:neom_core/utils/enums/subscription_level.dart';
import 'package:neom_core/utils/enums/user_role.dart';
import 'package:neom_core/utils/enums/verification_level.dart';

import '../app_flavour.dart';
import '../utils/app_alerts.dart';
import '../utils/constants/app_constants.dart';
import '../utils/constants/app_page_id_constants.dart';
import '../utils/constants/translations/common_translation_constants.dart';
import '../utils/enums/app_drawer_menu.dart';
import '../utils/external_utilities.dart';
import '../utils/text_utilities.dart';
import 'app_drawer_controller.dart';
import 'theme/app_color.dart';
import 'theme/app_theme.dart';
import 'widgets/custom_widgets.dart';


class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppDrawerController>(
    id: AppPageIdConstants.appDrawer,
    init: AppDrawerController(),
    builder: (_) {
      return Drawer(
        child: Container(
          decoration: AppTheme.appBoxDecoration,
          child: SafeArea(
            child: Stack(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: <Widget>[
                      AppTheme.heightSpace10,
                      _menuHeader(context, _),
                      const Divider(),
                      if(Get.isRegistered<ProfileService>()) drawerRowOption(AppDrawerMenu.profile,  const Icon(Icons.person), context),
                      if(AppConfig.instance.appInUse == AppInUse.e)
                        Column(
                          children: [
                            drawerRowOption(AppDrawerMenu.inspiration, const Icon(FontAwesomeIcons.filePen), context),
                          ],
                        ),
                      if(AppConfig.instance.appInUse == AppInUse.g && _.appProfile.value?.type == ProfileType.appArtist && _.user?.userRole != UserRole.subscriber)
                        drawerRowOption(AppDrawerMenu.bands, const Icon(Icons.people), context),
                      if(AppFlavour.isNeomApp())
                        Column(
                          children: [
                            drawerRowOption(AppDrawerMenu.frequencies, Icon(AppFlavour.getInstrumentIcon()), context),
                            if(Get.isRegistered<UserService>()) drawerRowOption(AppDrawerMenu.presets, const Icon(Icons.surround_sound_outlined), context),
                            const Divider(),
                            if(Get.isRegistered<InboxService>()) drawerRowOption(AppDrawerMenu.inbox, const Icon(FontAwesomeIcons.comments), context),
                          ],
                        ),
                      // drawerRowOption(AppDrawerMenu.calendar, const Icon(FontAwesomeIcons.calendar), context),
                      if(!AppFlavour.isNeomApp()) //TODO Not implemented on "C" app yet
                        drawerRowOption(AppDrawerMenu.requests, const Icon(Icons.email), context),
                      Column(
                        children: [
                          const Divider(),
                          if(_.user?.userRole != UserRole.subscriber && !AppFlavour.isNeomApp())
                            drawerRowOption(AppDrawerMenu.releaseUpload, Icon(AppFlavour.getAppItemIcon()), context),
                          if(AppConfig.instance.appInUse == AppInUse.e)
                            Column(
                              children: [
                                if((_.userServiceImpl?.subscriptionLevel.value ?? SubscriptionLevel.freemium.value)
                                    >= SubscriptionLevel.creator.value ||
                                    ( _.user?.userRole.value ?? UserRole.subscriber.value) > UserRole.subscriber.value)
                                  drawerRowOption(AppDrawerMenu.nupale, const Icon(FontAwesomeIcons.bookOpenReader), context),
                                //TODO Working on it with similar views as NUPALE but analysing caseteSessions
                                // drawerRowOption(AppDrawerMenu.casete, const Icon(FontAwesomeIcons.tape), context),
                                drawerRowOption(AppDrawerMenu.directory, const Icon(FontAwesomeIcons.building), context),
                                const Divider(),
                                drawerRowOption(AppDrawerMenu.appItemQuotation, const Icon(Icons.attach_money), context),
                                drawerRowOption(AppDrawerMenu.services, const Icon(Icons.room_service), context),
                                const Divider(),
                              ],
                            )
                          ///NOT READY FOR THIS FUNCITONALITY OF CROWDFUNDING - AppInUse.e Usage
                          // _menuListRowButton(AppConstants.crowdfunding, const Icon(FontAwesomeIcons.gifts), true, context),
                        ],
                      ),
                      if(!AppFlavour.isNeomApp() && ((_.userServiceImpl?.subscriptionLevel.value ?? SubscriptionLevel.freemium.value)
                              >= SubscriptionLevel.creator.value || (_.user?.userRole.value ?? UserRole.subscriber.value) > UserRole.subscriber.value)
                      ) Column(
                        children: [
                          drawerRowOption(AppDrawerMenu.wallet, const Icon(FontAwesomeIcons.coins), context),
                          const Divider(),
                        ],
                      ),
                      if(Get.isRegistered<SettingsService>()) drawerRowOption(AppDrawerMenu.settings, const Icon(Icons.settings), context),
                      if(Get.isRegistered<LoginService>()) Column(
                        children: [
                          const Divider(),
                          drawerRowOption(AppDrawerMenu.logout, const Icon(Icons.logout), context),
                      ],)

                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _menuHeader(BuildContext context, AppDrawerController _) {

    if(_.user?.id.isNotEmpty ?? false) {
      return Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if(_.appProfile.value != null) GestureDetector(
              child: Container(
                height: 56,
                width: 56,
                margin: const EdgeInsets.only(left: 20, top: 15),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(28),
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(_.appProfile.value!.photoUrl.isNotEmpty
                        ? _.appProfile.value!.photoUrl : AppProperties.getAppLogoUrl()),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              onTap: ()=> Get.toNamed(AppRouteConstants.profile),
            ),
            ListTile(
              onTap: () {
                Get.toNamed(AppRouteConstants.profile);
              },
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if(_.appProfile.value != null) Text(TextUtilities.capitalizeFirstLetter(_.appProfile.value!.name.length > AppConstants.maxDrawerNameLength
                          ? "${_.appProfile.value!.name.substring(0,AppConstants.maxDrawerNameLength)}..." : _.appProfile.value!.name,),
                        style: AppTheme.primaryTitleText,
                        overflow: TextOverflow.fade,
                      ),
                      if(_.userServiceImpl != null && _.user != null && _.user!.userRole != UserRole.subscriber) IconButton(
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.keyboard_arrow_down_outlined),
                          onPressed: ()=> _.isButtonDisabled.value ? {} : AppAlerts.selectProfileModal(context: context,
                              profiles: _.user!.profiles, currentProfileId: _.appProfile.value?.id ?? '',
                              onChangeProfile: _.userServiceImpl!.changeProfile,
                              onCreateProfile: _.userServiceImpl!.createProfile
                          )
                      )
                    ],
                  ),
                  if(_.userServiceImpl != null && _.userServiceImpl!.user.userRole != UserRole.subscriber)
                    Text(_.userServiceImpl!.user.userRole.name.tr, style: const TextStyle(fontSize: 14)),
                ],
              ),
              subtitle: AppConfig.instance.appInUse != AppInUse.c ? buildVerifyProfile(_,context) : null,
            ),
          ],
        ),
      );
    } else {
      bool isLoginEnable = Get.isRegistered<LoginService>();
      return customInkWell(
        context: context,
        onPressed: () {
          if(isLoginEnable) {
            Get.offAllNamed(AppRouteConstants.login);
          }
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 200, minHeight: 100),
          child: Center(
            child: Text(
              isLoginEnable ?
              CommonTranslationConstants.loginToContinue.tr :
              CommonTranslationConstants.integrateLoginModule.tr,
              style: AppTheme.primaryTitleText,
            ),
          ),
        ),
      );
    }
  }

  Widget buildVerifyProfile(AppDrawerController _, BuildContext context) {
    List<Widget> widgets = [];

    if(_.appProfile.value != null && _.appProfile.value?.verificationLevel != VerificationLevel.none) {
      widgets.add(customText(CoreUtilities.getProfileMainFeature(_.appProfile.value!).tr.capitalize,
          style: AppTheme.primarySubtitleText.copyWith(
              color: Colors.white70, fontSize: 15),
          context: context));
      widgets.add(AppTheme.widthSpace5);
      widgets.add(AppFlavour.getVerificationIcon(_.appProfile.value!.verificationLevel));
    } else if(_.user?.subscriptionId.isEmpty ?? true) {
      if(_.appProfile.value?.type == ProfileType.general) {
        widgets.add(TextButton(
          onPressed: () => AppAlerts.getSubscriptionAlert(_.subscriptionServiceImpl, context, AppRouteConstants.home),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero, // Remove padding here
            textStyle: const TextStyle(decoration: TextDecoration.underline), // Keep your underline style
          ),
          child: Text(CommonTranslationConstants.acquireSubscription.tr,),
        ));
      } else if(_.appProfile.value != null) {
        widgets.add(customText(CoreUtilities.getProfileMainFeature(_.appProfile.value!).tr.capitalize,
            style: AppTheme.primarySubtitleText.copyWith(
                color: Colors.white70, fontSize: 15),
            context: context));
        widgets.add(AppTheme.widthSpace5);
        widgets.add(const Icon(Icons.verified_outlined, color: Colors.white70));
        widgets.add(TextButton(
            onPressed: () => AppAlerts.getSubscriptionAlert(_.subscriptionServiceImpl!, context, AppRouteConstants.home),
            child: Text(CommonTranslationConstants.verifyProfile.tr,
              style: const TextStyle(decoration: TextDecoration.underline),
            )
        ));
      }
    } else {
      if(_.user?.subscriptionId == SubscriptionLevel.basic.name) {
        widgets.add(Text(CommonTranslationConstants.enjoyTheApp.tr,));
      } else {
        widgets.add(Text(CommonTranslationConstants.activeSubscription.tr,));
      }

    }


    return Row(children: widgets);
  }

  ListTile drawerRowOption(AppDrawerMenu selectedMenu, Icon icon, BuildContext context, {bool isEnabled = true}) {
    return ListTile(
      onTap: () {
        if(isEnabled) {
          switch(selectedMenu) {
            case AppDrawerMenu.profile:
              Get.toNamed(AppRouteConstants.profile);
              break;
            case AppDrawerMenu.instruments:
              Get.toNamed(AppRouteConstants.instrumentsFav);
              break;
            case AppDrawerMenu.genres:
              if (isEnabled) Get.toNamed(AppRouteConstants.genresFav);
              break;
            case AppDrawerMenu.bands:
              Get.toNamed(AppRouteConstants.bands);
              break;
            case AppDrawerMenu.events:
              Get.toNamed(AppRouteConstants.events);
              break;
            case AppDrawerMenu.inbox:
              Get.toNamed(AppRouteConstants.inbox);
              break;
            case AppDrawerMenu.calendar:
              Get.toNamed(AppRouteConstants.calendar);
              break;
            case AppDrawerMenu.services:
              Get.toNamed(AppRouteConstants.services);
              break;
            case AppDrawerMenu.requests:
              Get.toNamed(AppRouteConstants.request);
              break;
            case AppDrawerMenu.booking:
              Get.toNamed(AppRouteConstants.booking);
              break;
            case AppDrawerMenu.directory:
              Get.toNamed(AppRouteConstants.directory);
              break;
            case AppDrawerMenu.wallet:
              Get.toNamed(AppRouteConstants.wallet);
              break;
            case AppDrawerMenu.settings:
              Get.toNamed(AppRouteConstants.settingsPrivacy);
              break;
            case AppDrawerMenu.crowdfunding:
              ExternalUtilities.launchURL(AppProperties.getCrowdfundingUrl());
              break;
            case AppDrawerMenu.appItemQuotation:
              Get.toNamed(AppRouteConstants.quotation);
              break;
            case AppDrawerMenu.logout:
              Get.toNamed(AppRouteConstants.logout,
                  arguments: [AppRouteConstants.logout]
              );
              break;
            case AppDrawerMenu.releaseUpload:
              Get.toNamed(AppRouteConstants.releaseUpload);
              break;
            case AppDrawerMenu.digitalLibrary:
              // TODO: Handle this case.
              break;
            case AppDrawerMenu.frequencies:
              Get.toNamed(AppRouteConstants.frequencyFav);
              break;
            case AppDrawerMenu.presets:
              Get.toNamed(AppRouteConstants.chamber);
              break;
            case AppDrawerMenu.inspiration:
              Get.toNamed(AppRouteConstants.blog);
            case AppDrawerMenu.nupale:
              Get.toNamed(AppRouteConstants.nupaleHome);
            case AppDrawerMenu.casete:
              Get.toNamed(AppRouteConstants.nupaleStats2);
              // Get.toNamed(AppRouteConstants.caseteStats);
              // TODO: Handle this case.
          }
        }
      },
      leading: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: icon
      ),
      title: customText(
        selectedMenu.name.tr.capitalize,
        textAlign: TextAlign.start,
        style: TextStyle(
          fontSize: 20,
          color: isEnabled ? AppColor.lightGrey : AppColor.secondary,
        ), context: context,
      ),
    );
  }

}
