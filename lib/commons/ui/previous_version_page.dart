import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_core/core/utils/constants/core_constants.dart';

import 'theme/app_theme.dart';


class PreviousVersionPage extends StatelessWidget {
  const PreviousVersionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
        padding: const EdgeInsets.all(50),
        decoration: AppTheme.boxDecoration,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
              Text("${CoreConstants.prevVersion1.tr} ${CoreConstants.prevVersion2.tr}",
                style: const TextStyle(fontSize: 20), textAlign: TextAlign.justify,),
              AppTheme.heightSpace20,
              Text(CoreConstants.prevVersion4.tr,
                style: const TextStyle(fontSize: 20), textAlign: TextAlign.end),
            ]
        ),
      ),
    );
  }
}
