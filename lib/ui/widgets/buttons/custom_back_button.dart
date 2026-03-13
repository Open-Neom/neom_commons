import 'package:flutter/material.dart';
import 'package:sint/sint.dart';

import '../../theme/app_color.dart';
import '../../theme/app_theme.dart';

class CustomBackButton extends StatelessWidget {
  const CustomBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 4,
      top: 26,
      child: GestureDetector(
        onTap: () => Sint.back(),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.padding10),
          child: Container(
            decoration: BoxDecoration(
              color: AppColor.surfaceDim,
              border: Border.all(
                color: AppColor.surfaceCard,
              ),
              borderRadius: BorderRadius.circular(20.0)
            ),
            child: const BackButton()
          ),
        ),
      ),
    );
  }
}
