import 'package:app_links/app_links.dart';
import 'package:sint/sint.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';


class DeeplinkUtilities {

  // Ejemplo conceptual en tu controlador principal o main
  Future<void> initDeepLinks() async {
    // Escuchar links entrantes
    final appLinks = AppLinks(); // Usando paquete app_links

    appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        AppConfig.logger.d("DeepLink recibido: $uri");
        handleDeepLink(uri);
      }
    });
  }

  void handleDeepLink(Uri uri) {
    // Si tu link es: https://neom.app/share?type=post&id=123
    List<String> segments = uri.pathSegments;
    String? type = uri.queryParameters['type'];
    String? id = uri.queryParameters['id'];

// Lógica robusta para encontrar el tipo y el ID en la ruta
    if (segments.contains('post')) {
      type = 'post';
      int index = segments.indexOf('post');
      if (index + 1 < segments.length) id = segments[index + 1];
    } else if (segments.contains('media')) {
      type = 'media';
      int index = segments.indexOf('media');
      if (index + 1 < segments.length) id = segments[index + 1];
    }

    if (type == 'post' && id != null) {
      Sint.toNamed(AppRouteConstants.postDetails, arguments: id);
    } else if (type == 'media' && id != null) {
      Sint.toNamed(AppRouteConstants.itemDetails, arguments: id);
    } else {
      // Fallback: Si no reconocemos la ruta, vamos al home
      Sint.offAllNamed(AppRouteConstants.home);
    }
  }

  static String generateDeepLink({required String host,
    required String type, required String id}) {
    // Define tu esquema único aquí (debe ser único para tu app)

    String myScheme = AppProperties.getAppName().toLowerCase();
    const String myHost = 'share';

    // Generamos: emxi://share/post/123
    return "$myScheme://$myHost/$type/$id";
  }

}
