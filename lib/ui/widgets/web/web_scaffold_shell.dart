import 'package:flutter/material.dart';

import 'web_breakpoints.dart';

class WebScaffoldShell extends StatelessWidget {

  final Widget? leftPanel;
  final double leftPanelWidth;
  final Widget center;
  final double? centerMaxWidth;
  final Widget? rightPanel;
  final double rightPanelWidth;

  const WebScaffoldShell({
    super.key,
    this.leftPanel,
    this.leftPanelWidth = 280,
    required this.center,
    this.centerMaxWidth = 900,
    this.rightPanel,
    this.rightPanelWidth = 300,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final showRight = rightPanel != null
        && WebBreakpoints.showRightPanel(screenWidth);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leftPanel != null)
          SizedBox(width: leftPanelWidth, child: leftPanel),
        Expanded(
          child: centerMaxWidth != null
              ? Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: centerMaxWidth!),
                    child: center,
                  ),
                )
              : center,
        ),
        if (showRight)
          SizedBox(width: rightPanelWidth, child: rightPanel),
      ],
    );
  }
}
