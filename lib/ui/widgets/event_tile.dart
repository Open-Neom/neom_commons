import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:neom_commons/ui/widgets/images/handled_cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/domain/model/event.dart';
import 'package:neom_core/utils/enums/app_locale.dart';
import 'package:sint/sint.dart';

import '../../utils/constants/translations/app_translation_constants.dart';
import '../../utils/constants/translations/common_translation_constants.dart';
import '../theme/app_color.dart';
import '../theme/app_theme.dart';


class EventTile extends StatelessWidget {

  final Event event;
  const EventTile(this.event, {super.key});

  bool get _isEventEnded => event.eventDate > 0
      && DateTime.now().isAfter(DateTime.fromMillisecondsSinceEpoch(event.eventDate));

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 120),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: _isEventEnded ? AppColor.surfaceElevated.withValues(alpha: 0.7) : AppColor.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.only(left: 5, right: 5, top: 10, bottom: 10),
                  width: MediaQuery.of(context).size.width,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      kDebugMode && event.isTest ? Text('(${AppTranslationConstants.test.tr})',
                          style: const TextStyle(fontWeight: FontWeight.bold)
                      ) : const SizedBox.shrink(),
                      Row(
                        children: [
                          Flexible(
                            child: Text(event.name.capitalizeFirst,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 2, overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if(event.isEdited) ...[
                            AppTheme.widthSpace5,
                            Text('· ${CommonTranslationConstants.edited.tr}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                      AppTheme.heightSpace5,
                      Text(event.description
                          .replaceAll(RegExp(r'\s+'), ' ')
                          .trim()
                          .capitalizeFirst,
                        style: const TextStyle(fontSize: 14),
                        maxLines: 3, overflow: TextOverflow.ellipsis,
                      ),
                      AppTheme.heightSpace5,
                      _buildDateRow(),
                      AppTheme.heightSpace5,
                      event.place?.name.isEmpty ?? true ? const SizedBox.shrink() :
                      Row(
                        children: <Widget>[
                          const Icon(Icons.location_on, size: 12),
                          AppTheme.widthSpace5,
                          Expanded(
                            child: Text(
                              event.place!.name,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      /// Attendee count preview
                      if((event.goingProfiles?.isNotEmpty ?? false))
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.people_outline, size: 13, color: Colors.grey),
                              AppTheme.widthSpace5,
                              Text(
                                '${event.goingProfiles!.length} ${CommonTranslationConstants.attending.tr}',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: ClipRRect(
                    borderRadius: const BorderRadius.only(topRight: Radius.circular(20), bottomRight: Radius.circular(20)),
                    child: ColorFiltered(
                      colorFilter: _isEventEnded
                          ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                          : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                      child: HandledCachedNetworkImage(
                              event.imgUrl.isNotEmpty ? event.imgUrl
                                  : AppProperties.getNoImageUrl(),
                              fit: BoxFit.cover,
                              enableFullScreen: false,
                            ),
                    ),
                ),
              )
            ],
          ),
        ),
        /// "Finalizado" badge or countdown badge
        if(_isEventEnded)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                CommonTranslationConstants.eventFinished.tr.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          )
        else if(event.eventDate > 0)
          Positioned(
            top: 6,
            right: 6,
            child: _buildCountdownBadge(),
          ),
      ],
    );
  }

  Widget _buildDateRow() {
    return Row(
      children: <Widget>[
        const Icon(Icons.calendar_today, size: 12),
        AppTheme.widthSpace5,
        Text(DateFormat.yMMMd(AppLocale.spanish.code)
              .format(DateTime.fromMillisecondsSinceEpoch(event.eventDate)),
          style: TextStyle(
            fontSize: 12,
            color: _isEventEnded ? Colors.grey : null,
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownBadge() {
    final eventDateTime = DateTime.fromMillisecondsSinceEpoch(event.eventDate);
    final now = DateTime.now();
    final difference = eventDateTime.difference(now);

    String label;
    Color badgeColor;

    if(difference.inDays > 7) {
      return const SizedBox.shrink();
    } else if(difference.inDays > 1) {
      label = '${difference.inDays} ${CommonTranslationConstants.daysLeft.tr}';
      badgeColor = AppColor.bondiBlue75;
    } else if(difference.inDays == 1) {
      label = '1 ${CommonTranslationConstants.daysLeft.tr}';
      badgeColor = Colors.orange;
    } else if(difference.inHours > 0) {
      label = CommonTranslationConstants.startsToday.tr;
      badgeColor = Colors.deepOrange;
    } else {
      label = CommonTranslationConstants.startsSoon.tr;
      badgeColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
