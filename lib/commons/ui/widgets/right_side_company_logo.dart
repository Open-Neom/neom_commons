import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../app_flavour.dart';
import '../../utils/app_alerts.dart';
import '../../utils/constants/app_assets.dart';
import '../../utils/constants/app_translation_constants.dart';

class RightSideCompanyLogo extends StatelessWidget {
  const RightSideCompanyLogo({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        child: Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Center(child: Image.asset(
            AppAssets.logoCompanyWhite,
            height: 22.5,
            fit: BoxFit.fitHeight,
          ),),
        ),
        onTap: () async {
          AppAlerts.showAlert(context, message: "${AppTranslationConstants.version.tr} "
              "${AppFlavour.appVersion}${kDebugMode ? " - Dev Mode" : ""}");
        }
    );
  }
}
