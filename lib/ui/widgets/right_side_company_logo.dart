import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:neom_core/app_config.dart';
import 'package:sint/sint.dart';

import '../../utils/app_alerts.dart';
import '../../utils/constants/app_assets.dart';
import '../../utils/constants/translations/app_translation_constants.dart';

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
              "${AppConfig.instance.appVersion}${kDebugMode ? " - Dev Mode" : ""}");
        }
    );
  }
}
