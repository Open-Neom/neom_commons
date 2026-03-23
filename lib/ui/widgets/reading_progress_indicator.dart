import 'package:flutter/material.dart';
import 'package:neom_commons/utils/datetime_utilities.dart';
import 'package:neom_core/domain/model/nupale/reading_progress.dart';

class ReadingProgressIndicator extends StatelessWidget {
  final ReadingProgress progress;

  const ReadingProgressIndicator({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final percent = (progress.completionPercent * 100).toInt();
    final color = progress.isComplete ? Colors.green : Colors.blueAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.completionPercent,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _buildLabel(percent),
          style: TextStyle(
            fontSize: 11,
            color: color.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }

  String _buildLabel(int percent) {
    final buffer = StringBuffer('$percent%');
    if (progress.hasReReads) buffer.write('  x${progress.sessionCount}');
    if (progress.lastReadTime > 0) {
      final lastRead = DateTime.fromMillisecondsSinceEpoch(progress.lastReadTime);
      buffer.write('  ${DateTimeUtilities.formatTimeAgo(lastRead)}');
    }
    return buffer.toString();
  }
}
