import 'package:flutter/material.dart';
import '../../utils/external_utilities.dart';
import '../../utils/url_utilities.dart';

class ExternalUrlViewer extends StatelessWidget {

  final String url;
  final bool showTopDivider;
  final bool showBottomDivider;

  const ExternalUrlViewer({required this.url, this.showTopDivider = true, this.showBottomDivider = false, super.key});

  @override
  Widget build(BuildContext context) {
    bool isValid = UrlUtilities.isValidExternalDomain(url);
    return isValid ? Column(
      children: [
        if(showTopDivider) const Divider(),
        Padding(
          padding: const EdgeInsets.only(top: 5.0),
          child: InkWell(
            onTap: () => ExternalUtilities.launchURL(url),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.public, size: 15, color: Colors.blue), // Icono pequeño de mundo
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    (Uri.tryParse(url)?.host.isNotEmpty ?? false)
                        ? Uri.tryParse(url)!.host : url,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline, // Subrayado clásico de link
                      decorationColor: Colors.blue,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(Icons.open_in_new, size: 12, color: Colors.blueGrey), // Icono de "abrir externo"
              ],
            ),
          ),
        ),
        if(showBottomDivider) const Divider(),
      ],
    ) : const SizedBox.shrink();
  }

}
