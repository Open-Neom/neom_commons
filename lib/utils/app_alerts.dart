import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/domain/model/subscription_plan.dart';
import 'package:neom_core/domain/use_cases/mate_service.dart';
import 'package:neom_core/domain/use_cases/report_service.dart';
import 'package:neom_core/domain/use_cases/subscription_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/core_utilities.dart';
import 'package:neom_core/utils/enums/profile_type.dart';
import 'package:neom_core/utils/enums/reference_type.dart';
import 'package:neom_core/utils/enums/report_type.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

import '../app_flavour.dart';
import '../ui/theme/app_color.dart';
import '../ui/theme/app_theme.dart';
import '../ui/widgets/images/handled_cached_network_image.dart';
import 'app_utilities.dart';
import 'constants/translations/app_translation_constants.dart';
import 'constants/translations/common_translation_constants.dart';
import 'constants/translations/message_translation_constants.dart';

class AppAlerts {

  static void showAlert(BuildContext context, {String title = '',  String message = ''}) {
    if(title.isEmpty) title = AppProperties.getAppName();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColor.getMain(),
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text(AppTranslationConstants.close.tr,
                  style: const TextStyle(color: AppColor.white)
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  static Future<bool> showExitConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColor.getMain(),
        title: Text(AppProperties.getAppName().capitalize),
        content: Text(CommonTranslationConstants.wantToCloseApp.tr),
        actions: <Widget>[
          TextButton(
            child: Text(
              AppTranslationConstants.no.tr,
              style: const TextStyle(color: AppColor.white),
            ),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: Text(
              AppTranslationConstants.yes.tr,
              style: const TextStyle(color: AppColor.white),
            ),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    ) ?? false;
  }

  static Future<void> selectProfileModal({
    required BuildContext context, required List<AppProfile> profiles,
    required String currentProfileId, required Future<void> Function(AppProfile) onChangeProfile,
    required void Function() onCreateProfile,}) async {

    try {
      UserService userServiceImpl = Get.find<UserService>();
      await userServiceImpl.getProfiles();
      await showModalBottomSheet(
          elevation: 0,
          backgroundColor: AppTheme.canvasColor25(context),
          context: context,
          builder: (BuildContext context) {
            return SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.only(top: 10),
                      margin: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                          color: AppColor.main95,
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(10.0), topRight: Radius.circular(10.0))
                      ),
                      child: ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          separatorBuilder:  (context, index) => const Divider(),
                          itemCount: userServiceImpl.user.profiles.length,
                          itemBuilder: (ctx, index) {
                            AppProfile profile = userServiceImpl.user.profiles.elementAt(index);
                            return ListTile(
                              leading: IconButton(
                                icon: CircleAvatar(
                                    maxRadius: 60,
                                    backgroundImage: CachedNetworkImageProvider(
                                        profile.photoUrl.isNotEmpty
                                            ? profile.photoUrl
                                            : AppProperties.getNoImageUrl()
                                    )
                                ),
                                onPressed: () async {
                                  Navigator.pop(context);
                                  if(currentProfileId != profile.id) {
                                    Navigator.pop(context);
                                    await userServiceImpl.changeProfile(profile);
                                  }
                                },
                              ),
                              trailing: Icon(currentProfileId == profile.id
                                  ? FontAwesomeIcons.circleDot : Icons.circle_outlined,
                                  size: 30
                              ),
                              title: Text(profile.name,
                                style: const TextStyle(fontSize: 18),
                              ),
                              subtitle: Text("${profile.type.name.tr.capitalize} - ${profile.mainFeature.tr.capitalize}"),
                              onTap: () async {
                                Navigator.pop(context);
                                if(currentProfileId != profile.id) {
                                  Navigator.pop(context);
                                  await userServiceImpl.changeProfile(profile);
                                }
                              },
                            );
                          }
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 15),
                      color: AppColor.main95,
                      child: ListTile(
                        leading: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(Radius.circular(30)),
                            color: Colors.teal[100],
                          ),
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 15,),
                        title: const Text("Crear perfil adicional",
                          style: TextStyle(color: Colors.white, fontSize: 15),
                        ),
                        subtitle: const Text("Agrega un perfil adicional para manejar distintas cuentas."),
                        onTap: () {
                          Navigator.pop(context);
                          Get.toNamed(AppRouteConstants.introProfile);
                        },
                      ),
                    ),
                  ],
                ));
          });
    } catch(e) {
      AppConfig.logger.e(e.toString());
    }
  }

  static Future<bool?> getSubscriptionAlert(SubscriptionService? _, BuildContext context, String fromRoute) async {
    AppConfig.logger.d("getSubscriptionAlert");

    List<ProfileType> profileTypes = AppFlavour.getProfileTypes();

    if(_ == null) return null;

    if(_.subscriptionPlans.isEmpty) await _.initializeSubscriptions();

    return Alert(
        context: context,
        style: AlertStyle(
            backgroundColor: AppColor.main50,
            titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            titleTextAlign: TextAlign.justify
        ),
        content: Obx(() => _.isLoading ? const Center(child: CircularProgressIndicator()) : Column(
          children: <Widget>[
            AppTheme.heightSpace20,
            Text(('${_.selectedPlanName}Msg').tr,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),textAlign: TextAlign.justify,),
            AppTheme.heightSpace20,
            HandledCachedNetworkImage(_.selectedPlanImgUrl),
            AppTheme.heightSpace20,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${AppTranslationConstants.profileType.tr}: ",
                  style: const TextStyle(fontSize: 15),
                ),
                DropdownButton<ProfileType>(
                  items: profileTypes.map((ProfileType type) {
                    return DropdownMenuItem<ProfileType>(
                      value: type,
                      child: Text(type.value.tr.capitalize),
                    );
                  }).toList(),
                  onChanged: (ProfileType? selectedType) {
                    if (selectedType == null) return;
                    _.selectProfileType(selectedType);
                  },
                  value: _.profileType,
                  alignment: Alignment.center,
                  icon: const Icon(Icons.arrow_downward),
                  iconSize: 20,
                  elevation: 16,
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: AppColor.getMain(),
                  underline: Container(
                    height: 1,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${AppTranslationConstants.subscription.tr}: ",
                  style: const TextStyle(fontSize: 15),
                ),
                DropdownButton<String>(
                  items: _.profilePlans.values.map((SubscriptionPlan plan) {
                    return DropdownMenuItem<String>(
                      value: plan.id,
                      child: Text(plan.name.tr),
                    );
                  }).toList(),
                  onChanged: (String? plan) {
                    if(plan != null) {
                      _.changeSubscriptionPlan(plan);
                    }
                  },
                  value: _.selectedPlan.id,
                  alignment: Alignment.center,
                  icon: const Icon(Icons.arrow_downward),
                  iconSize: 20,
                  elevation: 16,
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: AppColor.getMain(),
                  underline: Container(
                    height: 1,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            AppTheme.heightSpace20,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${CommonTranslationConstants.totalToPay.tr.capitalizeFirst}:",
                  style: const TextStyle(fontSize: 15),
                ),
                Row(
                  children: [
                    Text("${CoreUtilities.getCurrencySymbol(_.selectedPrice.currency)} ${_.selectedPrice.amount} ${_.selectedPrice.currency.name.tr.toUpperCase()}",
                      style: const TextStyle(fontSize: 15),
                    ),
                    AppTheme.widthSpace5,
                  ],
                ),
              ],
            ),
          ],),
        ),
        buttons: [
          DialogButton(
            color: AppColor.bondiBlue75,
            onPressed: () async {
              await _.paySubscription(_.selectedPlan, fromRoute);
            },
            child: Text(CommonTranslationConstants.confirmAndProceed.tr,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ]
    ).show();
  }

  static Future<void> showBlockProfileAlert(MateService mateServiceImpl, BuildContext context, String postOwnerId) async {
    Alert(
        context: context,
        style: AlertStyle(
          backgroundColor: AppColor.main50,
          titleStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
        title: CommonTranslationConstants.blockProfile.tr,
        content: Column(
          children: [
            Text(MessageTranslationConstants.blockProfileMsg.tr,
              style: const TextStyle(fontSize: 15),
            ),
            AppTheme.heightSpace10,
            Text(MessageTranslationConstants.blockProfileMsg2.tr,
              style: const TextStyle(fontSize: 15),
            ),
          ],),
        buttons: [
          DialogButton(
            color: AppColor.bondiBlue75,
            onPressed: () => Navigator.pop(context),
            child: Text(AppTranslationConstants.goBack.tr,
              style: const TextStyle(fontSize: 15),
            ),
          ),
          DialogButton(
            color: AppColor.bondiBlue75,
            onPressed: () async {
              await mateServiceImpl.block(postOwnerId);
                Navigator.pop(context);
                Navigator.pop(context);
                AppUtilities.showSnackBar(message: MessageTranslationConstants.blockedProfileMsg);
            },
            child: Text(AppTranslationConstants.toBlock.tr,
              style: const TextStyle(fontSize: 15),
            ),
          )
        ]
    ).show();
  }

  static Future<void> showSendReportAlert(BuildContext context, String referenceId,
      {ReferenceType referenceType = ReferenceType.post}) async {

    ReportService reportServiceImpl = Get.find<ReportService>();
    Alert(
        context: context,
        style: AlertStyle(
          backgroundColor: AppColor.main50,
          titleStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
        title: AppTranslationConstants.sendReport.tr,
        content: Column(
          children: <Widget>[
            Obx(()=>
                DropdownButton<ReportType>(
                  dropdownColor: AppColor.getMain(),
                  items: ReportType.values.map((ReportType reportType) {
                    return DropdownMenuItem<ReportType>(
                      value: reportType,
                      child: Text(reportType.name.tr),
                    );
                  }).toList(),
                  onChanged: (ReportType? reportType) {
                    if(reportType != null) {
                      reportServiceImpl.setReportType(reportType);
                    }

                  },
                  value: reportServiceImpl.reportType,
                  alignment: Alignment.center,
                  icon: const Icon(Icons.arrow_downward),
                  iconSize: 20,
                  elevation: 16,
                  style: const TextStyle(color: Colors.white),
                  underline: Container(height: 1, color: Colors.grey,),
                ),
            ),
            TextField(
              onChanged: (text) {
                reportServiceImpl.setMessage(text);
              },
              decoration: InputDecoration(
                  labelText: AppTranslationConstants.message.tr
              ),
            ),
          ],
        ),
        buttons: [
          DialogButton(
            color: AppColor.bondiBlue75,
            onPressed: () async {
              if(!reportServiceImpl.isButtonDisabled) {
                reportServiceImpl.sendReport(referenceType, referenceId);
                Navigator.pop(context);
                Navigator.pop(context);
                AppUtilities.showSnackBar(message: CommonTranslationConstants.hasSentReport);
              }
            },
            child: Text(AppTranslationConstants.send.tr,
              style: const TextStyle(fontSize: 15),
            ),
          )
        ]
    ).show();
  }

}
