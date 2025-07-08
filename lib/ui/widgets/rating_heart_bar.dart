import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:neom_core/app_config.dart';
import '../../utils/app_utilities.dart';
import '../../utils/constants/app_assets.dart';

class RatingHeartBar extends StatelessWidget {

  final double state;

  const RatingHeartBar({required this.state, super.key});

  @override
  Widget build(BuildContext context) {
    return RatingBar(
      initialRating: state,
      minRating: 1,
      ignoreGestures: true,
      direction: Axis.horizontal,
      allowHalfRating: false,
      itemCount: 5,
      ratingWidget: RatingWidget(
        full: AppUtilities.ratingImage(AppAssets.heart),
        half: AppUtilities.ratingImage(AppAssets.heartHalf),
        empty: AppUtilities.ratingImage(AppAssets.heartBorder),
      ),
      itemPadding: const EdgeInsets.symmetric(horizontal: 1.0),
      itemSize: 12,
      onRatingUpdate: (rating) {
        AppConfig.logger.d("New Rating set to $rating");
      },
    );
  }

}
