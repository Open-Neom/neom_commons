import 'package:flutter/material.dart';
import '../../app_flavour.dart';
import '../../utils/constants/app_assets.dart';
import '../theme/app_theme.dart';

class HeaderIntro extends StatelessWidget{

  final String title;
  final String subtitle;
  final bool showLogo;
  final bool showPreLogo;
  final int sizeRelation;

  const HeaderIntro({this.title = "", this.subtitle = "", this.showLogo = false, this.showPreLogo = false, this.sizeRelation = 3, super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = AppTheme.fullWidth(context);
    final isPortrait = MediaQuery.orientationOf(context) == Orientation.portrait;
    final preLogoHeight =
        (screenWidth / (isPortrait ? sizeRelation : 3)).clamp(48.0, 140.0);
    final preLogoWidth =
        (screenWidth / (isPortrait ? sizeRelation : 5)).clamp(48.0, 140.0);
    final logoMaxWidth = (screenWidth * 0.6).clamp(120.0, 260.0);
    final logoMaxHeight = isPortrait ? 150.0 : 110.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          showPreLogo ? Image.asset(AppAssets.isologoAppWhite,
            height: preLogoHeight,
            width: preLogoWidth,
            fit: BoxFit.contain,
          ) : const SizedBox.shrink(),
          AppTheme.heightSpace10,
          if (showLogo)
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: logoMaxWidth,
                maxHeight: logoMaxHeight,
              ),
              child: Image.asset(
                AppFlavour.getAppLogoPath(),
                fit: BoxFit.contain,
              ),
            ),
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
