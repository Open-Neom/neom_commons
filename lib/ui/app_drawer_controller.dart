import 'package:sint/sint.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/domain/model/app_user.dart';
import 'package:neom_core/domain/use_cases/app_drawer_service.dart';
import 'package:neom_core/domain/use_cases/home_service.dart';
import 'package:neom_core/domain/use_cases/subscription_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';

class AppDrawerController extends SintController implements AppDrawerService {

  final userServiceImpl = Sint.isRegistered<UserService>() ? Sint.find<UserService>() : null;
  SubscriptionService? subscriptionServiceImpl;

  AppUser? user;
  Rx<AppProfile?> appProfile = AppProfile().obs;

  RxBool isButtonDisabled = false.obs;

  @override
  void onInit() async {
    super.onInit();
    AppConfig.logger.t("Drawer Controller Init");
    user = userServiceImpl?.user;
    appProfile.value = userServiceImpl?.profile;

    Sint.find<HomeService>().mediaPlayerEnabled = false;
    if(user?.subscriptionId.isEmpty ?? true) initializeSubscriptionService();
  }

  @override
  void updateProfile(AppProfile profile) {
    appProfile.value = profile;
    update();
  }

  @override
  void onClose() {
    super.onClose();
    AppConfig.logger.t("Drawer Controller Closed");
    if(AppConfig.instance.appInfo.mediaPlayerEnabled) {
      Sint.find<HomeService>().mediaPlayerEnabled = true;
    }
  }

  @override
  Future<void> initializeSubscriptionService() async {
    if(Sint.isRegistered<SubscriptionService>()) {
      subscriptionServiceImpl = Sint.find<SubscriptionService>();
    }
  }

}
