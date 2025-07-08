import 'package:flutter/material.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import '../../app_flavour.dart';
import '../../utils/constants/app_assets.dart';
import '../theme/app_theme.dart';

class HeaderIntro extends StatelessWidget{

  final String title;
  final String subtitle;
  final bool showLogo;
  final bool showPreLogo;
  final int sizeRelation;

  const HeaderIntro({this.title = "", this.subtitle = "", this.showLogo = true, this.showPreLogo = true, this.sizeRelation = 3, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          (AppConfig.instance.appInUse == AppInUse.e && showPreLogo)
              ? Image.asset(AppAssets.logoAppWhite,
            height: AppTheme.fullWidth(context)/(MediaQuery.of(context).orientation == Orientation.portrait ? sizeRelation:5),
            width: AppTheme.fullWidth(context)/(MediaQuery.of(context).orientation == Orientation.portrait ? sizeRelation:5),
          ) : const SizedBox.shrink(),
          AppTheme.heightSpace10,
          showLogo ? Image.asset(AppFlavour.getAppLogoPath(),
            width: AppTheme.fullWidth(context)*(AppConfig.instance.appInUse != AppInUse.e ? 0.75 : (MediaQuery.of(context).orientation == Orientation.portrait ? 0.25:0.15)),
            fit: BoxFit.fitWidth,
          ) : const SizedBox.shrink(),
          title.isEmpty ? const SizedBox.shrink() : Column(
            children: [
              showLogo ? const SizedBox.shrink() : AppTheme.heightSpace20,
              Text(title,
                textAlign: TextAlign.center,
                style: AppTheme.headerTitleStyle
              ),
            ],
          ),
          subtitle.isEmpty ? const SizedBox.shrink() : Column(
            children: [
              (showLogo && title.isNotEmpty)
                  ? AppTheme.heightSpace10 : showLogo ? AppTheme.heightSpace20 : const SizedBox.shrink(),
              Text(subtitle,
                textAlign: TextAlign.center,
                style: AppTheme.headerSubtitleStyle
              ),
            ],
          )
      ]),
    );
  }
}
