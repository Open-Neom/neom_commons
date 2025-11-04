import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_color.dart';
import '../theme/app_theme.dart';

// ignore: must_be_immutable
class AppBarChild extends StatelessWidget implements PreferredSizeWidget {

  Widget? preTitle;
  final String title;
  Color? color;
  Widget? leadingWidget;
  List<Widget>? actionWidgets;
  bool? centerTitle;
  double? titleSpacing;

  AppBarChild({this.title = "", this.preTitle, this.color, this.leadingWidget, this.actionWidgets, this.centerTitle, super.key});

  @override
  Size get preferredSize => AppTheme.appBarHeight;
  @override
  Widget build(BuildContext context) {

    color ??= AppColor.appBar;
    return AppBar(
      leading: leadingWidget,
      title: Row(
        children: [
          if(preTitle != null) Row(children: [preTitle!, AppTheme.widthSpace10],),
          Text(title.capitalize, style: TextStyle(color: Colors.white.withAlpha(204),
              fontWeight: FontWeight.bold),
          ),
        ],
      ),
      titleSpacing: titleSpacing,
      backgroundColor: color,
      elevation: 0.0,
      actions: actionWidgets,
      centerTitle: centerTitle,
    );
  }

}
