import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../utils/constants/translations/common_translation_constants.dart';

class GoSpotifyButton extends StatelessWidget {
  final AppMediaItem? appMediaItem;
  final double? size;
  final bool showSnack;
  final EdgeInsets? padding;

  const GoSpotifyButton({
    super.key,
    required this.appMediaItem,
    this.size,
    this.showSnack = false,
    this.padding
  });

  @override
  Widget build(BuildContext context) {
    try {

    } catch (e) {
      AppConfig.logger.e('Error in likeButton: $e');
    }
    return IconButton(
        padding: padding,
        icon: const Row(
          children: [Icon(FontAwesomeIcons.spotify, color: Colors.green),],
        ),
        iconSize: size ?? 24.0,
        tooltip: CommonTranslationConstants.listenOnSpotify.tr,
        onPressed: () async {
          await launchUrl(
            Uri.parse(appMediaItem!.permaUrl),
            mode: LaunchMode.externalApplication,
          );
        },
    );
  }
}
