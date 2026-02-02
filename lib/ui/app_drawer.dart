import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sint/sint.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/domain/use_cases/login_service.dart';
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
    return SintBuilder<AppDrawerController>(
    id: AppPageIdConstants.appDrawer,
    init: AppDrawerController(),
    builder: (controller) {
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
                      _menuHeader(context, controller),
                      const Divider(),
                      // if(Sint.isRegistered<ProfileService>()) drawerRowOption(AppDrawerMenu.profile,  const Icon(Icons.person), context),
                      if(AppFlavour.showBlog())
                        drawerRowOption(AppDrawerMenu.inspiration, const Icon(FontAwesomeIcons.filePen), context),
                      if(AppFlavour.showBands() && controller.appProfile.value?.type == ProfileType.appArtist && controller.user?.userRole != UserRole.subscriber)
                        drawerRowOption(AppDrawerMenu.bands, const Icon(Icons.people), context),
                      if(AppFlavour.isNeomApp())
                        Column(
                          children: [
                            drawerRowOption(AppDrawerMenu.frequencies, Icon(AppFlavour.getInstrumentIcon()), context),
                            if(Sint.isRegistered<UserService>()) drawerRowOption(AppDrawerMenu.presets, const Icon(Icons.surround_sound_outlined), context),
                          ],
                        ),
                      if(!AppFlavour.isNeomApp()) //TODO Not implemented on "C" app yet
                        drawerRowOption(AppDrawerMenu.requests, const Icon(Icons.email), context),
                      if(
                      ///DEPRECATED - AS VERIFICATIONLEVEL IS BEING USED NOW AND ITS MORE RELEVANT
                      // (controller.userServiceImpl?.subscriptionLevel.value
                      //     ?? SubscriptionLevel.freemium.value) >= SubscriptionLevel.creator.value
                      (controller.userServiceImpl?.profile.verificationLevel.value
                              ?? VerificationLevel.none.value) >= VerificationLevel.creator.value
                          || (controller.user?.userRole.value ?? UserRole.subscriber.value) >= UserRole.support.value)
                        Column(
                          children: [
                            if(AppFlavour.showNupale())
                            drawerRowOption(AppDrawerMenu.nupale, const Icon(FontAwesomeIcons.bookOpenReader), context),
                            if(AppFlavour.showCasete())
                            drawerRowOption(AppDrawerMenu.casete, const Icon(FontAwesomeIcons.solidFileAudio), context),
                          ],
                        ),
                      Column(
                        children: [
                          const Divider(),
                          if(AppFlavour.showReleaseUpload()
                              && (controller.user?.userRole.value ?? UserRole.subscriber.value) >= UserRole.support.value)
                            drawerRowOption(AppDrawerMenu.releaseUpload, Icon(AppFlavour.getAppItemIcon()), context),
                          if(AppFlavour.showServices())
                            Column(
                              children: [
                                drawerRowOption(AppDrawerMenu.appItemQuotation, const Icon(Icons.attach_money), context),
                                drawerRowOption(AppDrawerMenu.services, const Icon(Icons.room_service), context),
                                const Divider(),
                              ],
                            ),
                          ///NOT READY FOR THIS FUNCITONALITY OF CROWDFUNDING - AppInUse.e Usage
                          // _menuListRowButton(AppConstants.crowdfunding, const Icon(FontAwesomeIcons.gifts), true, context),
                        ],
                      ),
                      if(AppFlavour.showWallet() && ((controller.userServiceImpl?.profile.verificationLevel.value
                          ?? VerificationLevel.none.value) >= VerificationLevel.creator.value
                          || (controller.user?.userRole.value ?? UserRole.subscriber.value) >= UserRole.support.value)
                      ) Column(
                        children: [
                          drawerRowOption(AppDrawerMenu.wallet, const Icon(FontAwesomeIcons.coins), context),
                          const Divider(),
                        ],
                      ),
                      if(Sint.isRegistered<SettingsService>()) drawerRowOption(AppDrawerMenu.settings, const Icon(Icons.settings), context),
                      if(Sint.isRegistered<LoginService>()) Column(
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

  Widget _menuHeader(BuildContext context, AppDrawerController controller) {

    if(controller.user?.id.isNotEmpty ?? false) {
      return Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if(controller.appProfile.value != null) GestureDetector(
              child: Container(
                height: 56,
                width: 56,
                margin: const EdgeInsets.only(left: 20, top: 15),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(28),
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(controller.appProfile.value!.photoUrl.isNotEmpty
                        ? controller.appProfile.value!.photoUrl : AppProperties.getAppLogoUrl()),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              onTap: ()=> Sint.toNamed(AppRouteConstants.profile),
            ),
            ListTile(
              onTap: () {
                Sint.toNamed(AppRouteConstants.profile);
              },
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if(controller.appProfile.value != null) Text(TextUtilities.capitalizeFirstLetter(controller.appProfile.value!.name.length > AppConstants.maxDrawerNameLength
                          ? "${controller.appProfile.value!.name.substring(0,AppConstants.maxDrawerNameLength)}..." : controller.appProfile.value!.name,),
                        style: AppTheme.primaryTitleText,
                        overflow: TextOverflow.fade,
                      ),
                      if(controller.userServiceImpl != null && controller.user != null && controller.user!.userRole != UserRole.subscriber) IconButton(
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.keyboard_arrow_down_outlined),
                          onPressed: ()=> controller.isButtonDisabled.value ? {} : AppAlerts.selectProfileModal(context: context,
                              profiles: controller.user!.profiles, currentProfileId: controller.appProfile.value?.id ?? '',
                              onChangeProfile: controller.userServiceImpl!.changeProfile,
                              onCreateProfile: controller.userServiceImpl!.createProfile
                          )
                      )
                    ],
                  ),
                  if(controller.userServiceImpl != null && controller.userServiceImpl!.user.userRole != UserRole.subscriber)
                    Text(controller.userServiceImpl!.user.userRole.name.tr, style: const TextStyle(fontSize: 14)),
                ],
              ),
              subtitle: AppConfig.instance.appInUse != AppInUse.c ? buildVerifyProfile(controller,context) : null,
            ),
          ],
        ),
      );
    } else {
      bool isLoginEnable = Sint.isRegistered<LoginService>();
      return customInkWell(
        context: context,
        onPressed: () {
          if(isLoginEnable) {
            Sint.offAllNamed(AppRouteConstants.login);
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

  Widget buildVerifyProfile(AppDrawerController controller, BuildContext context) {
    List<Widget> widgets = [];

    if(controller.appProfile.value != null && controller.appProfile.value?.verificationLevel != VerificationLevel.none) {
      widgets.add(customText(CoreUtilities.getProfileMainFeature(controller.appProfile.value!).tr.capitalize,
          style: AppTheme.primarySubtitleText.copyWith(
              color: Colors.white70, fontSize: 15),
          context: context));
      widgets.add(AppTheme.widthSpace5);
      widgets.add(AppFlavour.getVerificationIcon(controller.appProfile.value!.verificationLevel));
    } else if(controller.user?.subscriptionId.isEmpty ?? true) {
      if(controller.appProfile.value?.type == ProfileType.general) {
        widgets.add(TextButton(
          onPressed: () => AppAlerts.getSubscriptionAlert(controller.subscriptionServiceImpl, context, AppRouteConstants.home),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero, // Remove padding here
            textStyle: const TextStyle(decoration: TextDecoration.underline), // Keep your underline style
          ),
          child: Text(CommonTranslationConstants.acquireSubscription.tr,),
        ));
      } else if(controller.appProfile.value != null) {
        widgets.add(customText(CoreUtilities.getProfileMainFeature(controller.appProfile.value!).tr.capitalize,
            style: AppTheme.primarySubtitleText.copyWith(
                color: Colors.white70, fontSize: 15),
            context: context));
        widgets.add(AppTheme.widthSpace5);
        widgets.add(const Icon(Icons.verified_outlined, color: Colors.white70));
        widgets.add(TextButton(
            onPressed: () => AppAlerts.getSubscriptionAlert(controller.subscriptionServiceImpl, context, AppRouteConstants.home),
            child: Text(CommonTranslationConstants.verifyProfile.tr,
              style: const TextStyle(decoration: TextDecoration.underline),
            )
        ));
      }
    } else {
      if(controller.user?.subscriptionId == SubscriptionLevel.basic.name) {
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
              Sint.toNamed(AppRouteConstants.profile);
              break;
            case AppDrawerMenu.instruments:
              Sint.toNamed(AppRouteConstants.instrumentsFav);
              break;
            case AppDrawerMenu.genres:
              if (isEnabled) Sint.toNamed(AppRouteConstants.genresFav);
              break;
            case AppDrawerMenu.bands:
              Sint.toNamed(AppRouteConstants.bands);
              break;
            case AppDrawerMenu.events:
              Sint.toNamed(AppRouteConstants.events);
              break;
            case AppDrawerMenu.inbox:
              Sint.toNamed(AppRouteConstants.inbox);
              break;
            case AppDrawerMenu.calendar:
              Sint.toNamed(AppRouteConstants.calendar);
              break;
            case AppDrawerMenu.services:
              Sint.toNamed(AppRouteConstants.services);
              break;
            case AppDrawerMenu.requests:
              Sint.toNamed(AppRouteConstants.request);
              break;
            case AppDrawerMenu.booking:
              Sint.toNamed(AppRouteConstants.booking);
              break;
            case AppDrawerMenu.directory:
              Sint.toNamed(AppRouteConstants.directory);
              break;
            case AppDrawerMenu.wallet:
              Sint.toNamed(AppRouteConstants.wallet);
              break;
            case AppDrawerMenu.settings:
              Sint.toNamed(AppRouteConstants.settingsPrivacy);
              break;
            case AppDrawerMenu.crowdfunding:
              ExternalUtilities.launchURL(AppProperties.getCrowdfundingUrl());
              break;
            case AppDrawerMenu.appItemQuotation:
              Sint.toNamed(AppRouteConstants.quotation);
              break;
            case AppDrawerMenu.logout:
              Sint.toNamed(AppRouteConstants.logout,
                  arguments: [AppRouteConstants.logout]
              );
              break;
            case AppDrawerMenu.releaseUpload:
              Sint.toNamed(AppRouteConstants.releaseUpload);
              break;
            case AppDrawerMenu.digitalLibrary:
              // TODO: Handle this case.
              break;
            case AppDrawerMenu.frequencies:
              Sint.toNamed(AppRouteConstants.frequencyFav);
              break;
            case AppDrawerMenu.presets:
              Sint.toNamed(AppRouteConstants.chamber);
              break;
            case AppDrawerMenu.inspiration:
              Sint.toNamed(AppRouteConstants.blog);
            case AppDrawerMenu.nupale:
              Sint.toNamed(AppRouteConstants.nupaleHome);
            case AppDrawerMenu.casete:
              Sint.toNamed(AppRouteConstants.caseteHome);
              // Sint.toNamed(AppRouteConstants.caseteStats);
              // TODO: Handle this case.
          }
        }
      },
      leading: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: icon
      ),
      title: customText(
        selectedMenu.name.tr,
        textAlign: TextAlign.start,
        style: TextStyle(
          fontSize: 20,
          color: isEnabled ? AppColor.lightGrey : AppColor.secondary,
        ), context: context,
      ),
    );
  }

}
