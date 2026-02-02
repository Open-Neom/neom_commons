import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sint/sint.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/verification_level.dart';

import '../../app_flavour.dart';
import '../../utils/constants/translations/app_translation_constants.dart';
import '../../utils/constants/translations/common_translation_constants.dart';
import '../theme/app_theme.dart';

class EarningProfileTile extends StatelessWidget {

  final AppProfile mate;
  final double profit;

  const EarningProfileTile({
    super.key,
    required this.mate,
    required this.profit,
  });

  @override
  Widget build(BuildContext context) {

    double appCoinProfit = profit / double.parse(AppProperties.getAppCoinValue());
    return ListTile(
      leading: CachedNetworkImage(
        imageUrl: mate.photoUrl.isNotEmpty ? mate.photoUrl : AppProperties.getAppLogoUrl(),
        placeholder: (context, url) => const CircleAvatar(
          child: CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) {
          AppConfig.logger.w("Error loading image: $error");
          return CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(AppProperties.getAppLogoUrl()),
          );
        },
        imageBuilder: (context, imageProvider) => CircleAvatar(
          backgroundImage: imageProvider,
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(mate.name.capitalize, overflow: TextOverflow.ellipsis,),
          ),
          if(mate.verificationLevel != VerificationLevel.none) AppTheme.widthSpace5,
          if(mate.verificationLevel != VerificationLevel.none)
            AppFlavour.getVerificationIcon(mate.verificationLevel, size: 18)
        ],
      ),
      subtitle: getSubtitleText(mate.verificationLevel),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(appCoinProfit.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleMedium?.color, // Mantén el color del tema
            ),
          ),
          Text(AppTranslationConstants.appCoin.tr.capitalize),
        ],
      ),
      onTap: () => mate.id.isNotEmpty
          ? Sint.toNamed(AppRouteConstants.mateDetails, arguments: mate.id)
          : {},
    );
  }

  Widget? getSubtitleText(VerificationLevel level) {
    if(mate.id.isEmpty) {
      return Text(AppTranslationConstants.profileNotFound.tr, style: TextStyle(color: Colors.red));
    } else {
      switch (level) {
        case VerificationLevel.artist:
        case VerificationLevel.ambassador:
          return Text(CommonTranslationConstants.testPeriod.tr, style: TextStyle(color: Colors.orange));
        case VerificationLevel.professional:
        case VerificationLevel.premium:
        case VerificationLevel.platinum:
          return Text(AppTranslationConstants.appMember.tr, style: TextStyle(color: Colors.blue));
        default:
          return Text(CommonTranslationConstants.testPeriod.tr, style: TextStyle(color: Colors.orange));
      }

    }
  }

}
