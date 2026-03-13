import 'package:flutter/material.dart';
import 'package:neom_commons/ui/widgets/images/handled_cached_network_image.dart';
import 'package:sint/sint.dart';

class CachedNetworkRoutingImage extends StatelessWidget {

  final String toNamed;
  final String mediaUrl;
  final String referenceId;
  final BoxFit fit;

  const CachedNetworkRoutingImage(BuildContext context, {super.key,
    required this.toNamed, required this.mediaUrl,
    this.referenceId = "", this.fit = BoxFit.fitHeight});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
            child: HandledCachedNetworkImage(
              mediaUrl,
              fit: fit,
              enableFullScreen: false,
            ),
          onTap: () => {
            if(toNamed.isNotEmpty)
              Sint.toNamed(toNamed, arguments: [referenceId]),
          }

      );
    }
}
