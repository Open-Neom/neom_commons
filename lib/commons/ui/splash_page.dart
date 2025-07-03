import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app_flavour.dart';
import '../utils/constants/app_page_id_constants.dart';
import '../utils/constants/app_translation_constants.dart';
import 'splash_controller.dart';
import 'theme/app_color.dart';
import 'theme/app_theme.dart';

class SplashPage extends StatelessWidget {

  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SplashController>(
      init: SplashController(),
      id: AppPageIdConstants.splash,
      builder: (_) => Scaffold(
        backgroundColor: AppColor.main50,
        body: Container(
          decoration: AppTheme.appBoxDecoration,
          child: Center(
            child:Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppFlavour.getSplashImage(),
                Column(
                  children: [
                    const SizedBox(height: 20,),
                    Text(AppTranslationConstants.splashSubtitle.tr,
                      style: TextStyle(
                          color: Colors.white.withOpacity(1.0),
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 20,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30,),
                const CircularProgressIndicator(),
                const SizedBox(height: 30,),
                Obx(() => Text(_.subtitle.value.tr,
                    style: TextStyle(
                      color: Colors.white.withOpacity(1.0),
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 15.0,
                    ),
                  ),
                ),
              ]
            ),
          ),
        ),
      ),
    );
  }

}
