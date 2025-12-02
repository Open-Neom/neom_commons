import 'package:flutter/material.dart';

import '../theme/app_color.dart';
import '../theme/app_theme.dart';

class HeadlineContainer extends StatelessWidget {

  final String title;

  const HeadlineContainer({
    this.title = '',
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppTheme.fullHeight(context)/15,
      decoration: const BoxDecoration(
        color: AppColor.bondiBlue75,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(15),
          bottomRight: Radius.circular(15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: Text(title,
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
              color: AppColor.white,
              fontSize: title.length > 25
                  ? Theme.of(context).textTheme.titleMedium!.fontSize
                  : Theme.of(context).textTheme.headlineSmall!.fontSize,
            ),
          ),
        ),
      ),
    );
  }

}
