import 'package:flutter/material.dart';
import '../theme/app_color.dart';
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
                const Icon(Icons.public, size: 15, color: AppColor.dodgetBlue),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    (Uri.tryParse(url)?.host.isNotEmpty ?? false)
                        ? Uri.tryParse(url)!.host : url,
                    style: const TextStyle(
                      color: AppColor.dodgetBlue,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColor.dodgetBlue,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 5),
                Icon(Icons.open_in_new, size: 12, color: AppColor.dodgetBlue.withAlpha(180)),
              ],
            ),
          ),
        ),
        if(showBottomDivider) const Divider(),
      ],
    ) : const SizedBox.shrink();
  }

}
