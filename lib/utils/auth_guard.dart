import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';

import '../ui/theme/app_color.dart';
import 'constants/translations/app_translation_constants.dart';

class AuthGuard {

  /// ÚNICO punto de acceso.
  ///
  /// [action]: La función que se ejecuta SI el usuario está autenticado.
  /// [redirectRoute]: (Opcional) Si es Guest, a dónde lo enviamos después de que se registre exitosamente.
  /// [arguments]: (Opcional) Argumentos para esa ruta de redirección.
  static void protect(BuildContext context, VoidCallback action, {String? redirectRoute, dynamic arguments}) {

    if (_userIsLoggedIn()) {
      // 1. Usuario Real: Pasa directo a la acción.
      action();
    } else {
      // 2. Usuario Guest: Se interrumpe la acción y se muestra el modal.
      showGuestModal(context, redirectRoute: redirectRoute, arguments: arguments);
    }
  }

  /// Verifica si el usuario está autenticado realmente.
  static bool _userIsLoggedIn() {
    try {
      // 1. Si el servicio no está inyectado, no hay usuario.
      if (!Get.isRegistered<UserService>()) return false;
      final userService = Get.find<UserService>();
      // 2. Debe tener un ID y NO estar en modo invitado explícito.
      return userService.user.id.isNotEmpty && !AppConfig.instance.isGuestMode;
    } catch (e) {
      AppConfig.logger.e("Error checking auth status: $e");
      return false;
    }
  }

  /// Muestra el diálogo y configura la redirección (Privado)
  static void showGuestModal(BuildContext context, {String? redirectRoute, dynamic arguments}) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColor.getMain(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(AppTranslationConstants.accountRequired.tr,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        ),
        content: Text(AppTranslationConstants.guestActionPrompt.tr,
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppTranslationConstants.continueExploring.tr, style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.bondiBlue,
                foregroundColor: Colors.white,
                shape: const StadiumBorder()
            ),
            onPressed: () {
              Navigator.pop(context);

              // 2. Apagar modo invitado (para que RootPage sepa que vamos al Login real)
              AppConfig.instance.isGuestMode = false;

              // 3. Ir al Login llevando la "Promesa" de redirección
              Get.toNamed(
                  AppRouteConstants.login,
                  arguments: {
                    'nextRoute': redirectRoute,
                    'nextArgs': arguments
                  }
              );
            },
            child: Text(AppTranslationConstants.loginSignup.tr,),
          ),
        ],
      ),
      barrierDismissible: true, // Permite cerrar tocando fuera
    );
  }

}
