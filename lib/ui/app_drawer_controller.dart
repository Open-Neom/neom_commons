import 'package:get/get.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/domain/model/app_user.dart';
import 'package:neom_core/domain/use_cases/app_drawer_service.dart';
import 'package:neom_core/domain/use_cases/subscription_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';

class AppDrawerController extends GetxController implements AppDrawerService {

  final userServiceImpl = Get.isRegistered<UserService>() ? Get.find<UserService>() : null;
  SubscriptionService? subscriptionServiceImpl;

  AppUser? user;
  Rx<AppProfile?> appProfile = AppProfile().obs;

  RxBool isButtonDisabled = false.obs;

  @override
  void onInit() async {
    super.onInit();
    AppConfig.logger.t("SideBar Controller Init");
    user = userServiceImpl?.user;
    appProfile.value = userServiceImpl?.profile;

    if(user?.subscriptionId.isEmpty ?? true) initializeSubscriptionService();
  }

  @override
  void updateProfile(AppProfile profile) {
    appProfile.value = profile;
    update();
  }

  @override
  Future<void> initializeSubscriptionService() async {
    if(Get.isRegistered<SubscriptionService>()) {
      subscriptionServiceImpl = Get.find<SubscriptionService>();
    }
  }

}
