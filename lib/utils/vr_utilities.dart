import 'package:flutter/services.dart';
import 'package:neom_core/app_config.dart';

class VrUtilities {

  static void enableVrMode() {
    AppConfig.logger.d('VR Mode Enabled');
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  static void disableVrMode() {
    AppConfig.logger.d('VR Mode Restored');
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

}
