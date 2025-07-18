import 'package:get/get.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/implementations/user_controller.dart';
import 'package:neom_core/domain/use_cases/login_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/auth_status.dart';
import '../utils/app_utilities.dart';
import '../utils/constants/translations/common_translation_constants.dart';

class SplashController extends GetxController {
  
  final loginController = Get.find<LoginService>();
  final userController = Get.find<UserController>();

  RxString subtitle = "".obs;

  String fromRoute = "";
  String toRoute = "";

  @override
  void onInit() {
    AppConfig.logger.t("onInit Splash");
    super.onInit();

    try {
      if (Get.arguments != null) {
        List<dynamic> arguments = Get.arguments;
        fromRoute = arguments.elementAt(0);
        if(arguments.length > 1) toRoute = arguments.elementAt(1);
      }

      switch(fromRoute){
        case AppRouteConstants.home:
          break;
        case AppRouteConstants.logout:
          break;
        case AppRouteConstants.introRequiredPermissions:
          break;
        case AppRouteConstants.accountSettings:
          if(toRoute == AppRouteConstants.accountRemove) {
            subtitle.value = CommonTranslationConstants.removingAccount;
          } else if (toRoute == AppRouteConstants.profileRemove) {
            subtitle.value = CommonTranslationConstants.removingProfile;
          }
          break;
        case AppRouteConstants.forgotPassword:
          subtitle.value = CommonTranslationConstants.sendingPasswordRecovery;
          break;
        case AppRouteConstants.introReason:
          subtitle.value = CommonTranslationConstants.creatingAccount;
          break;
        case AppRouteConstants.signup:
          subtitle.value = CommonTranslationConstants.creatingAccount;
          break;
        case AppRouteConstants.paymentGateway:
          subtitle.value = CommonTranslationConstants.paymentProcessing;
          break;
        case AppRouteConstants.finishingSpotifySync:
          subtitle.value = CommonTranslationConstants.finishingSpotifySync;
          break;
        case AppRouteConstants.mediaUpload:
          subtitle.value = CommonTranslationConstants.updatingApp;
          break;
        case "":
          AppConfig.logger.t("There is no fromRoute");
          break;
      }

    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

  }

  @override
  void onReady() {
    super.onReady();
    AppConfig.logger.t("onReady Splash");

    switch(fromRoute){
      case AppRouteConstants.home:
        Get.offAndToNamed(toRoute);
        break;
      case AppRouteConstants.logout:
        loginController.signOut();
        break;
      case AppRouteConstants.introRequiredPermissions:
        loginController.signOut();
        break;
      case AppRouteConstants.accountSettings:
        handleAccountSettings();
        break;
      case AppRouteConstants.forgotPassword:
        handleForgotPassword();
        break;
      case AppRouteConstants.introReason:
        changeSubtitle(CommonTranslationConstants.creatingAccount);
        userController.createUser();
        break;
      case AppRouteConstants.signup:
        changeSubtitle(CommonTranslationConstants.creatingAccount);
        break;
      case AppRouteConstants.createAdditionalProfile:
        changeSubtitle(CommonTranslationConstants.creatingProfile);
        userController.createProfile();
        break;
      case AppRouteConstants.paymentGateway:
        handlePaymentGateway();
        break;
      case AppRouteConstants.finishingSpotifySync:
        AppUtilities.showSnackBar(message: CommonTranslationConstants.playlistSynchFinished.tr);
        Get.offAllNamed(AppRouteConstants.home);
        break;
      case "":
        AppConfig.logger.t("There is no fromRoute");
        break;
    }

    if(loginController.getAuthStatus() == AuthStatus.loggingIn) {
      loginController.setAuthStatus(AuthStatus.loggedIn);
    }

    update();
  }

  Future<void> handlePaymentGateway() async {
    changeSubtitle(CommonTranslationConstants.paymentProcessed);
    update();
    await Get.offAllNamed(AppRouteConstants.home, arguments: [toRoute]);
  }

  Future<void> handleAccountSettings() async {
    if(toRoute == AppRouteConstants.accountRemove) {
      changeSubtitle(CommonTranslationConstants.removingAccount);
      await userController.removeAccount();
    } else if (toRoute == AppRouteConstants.profileRemove) {
      changeSubtitle(CommonTranslationConstants.removingProfile);
      await userController.removeProfile();
      Get.offAllNamed(AppRouteConstants.home);
    }
  }

  Future<void> handleForgotPassword() async {
    changeSubtitle(CommonTranslationConstants.sendingPasswordRecovery);
    Get.offAllNamed(AppRouteConstants.login);
    Get.snackbar(
      CommonTranslationConstants.passwordReset.tr,
      CommonTranslationConstants.passwordEmailResetSent.tr,
      snackPosition: SnackPosition.bottom,);
  }

  void changeSubtitle(String newSubtitle) {
    subtitle.value = newSubtitle;
  }

}
