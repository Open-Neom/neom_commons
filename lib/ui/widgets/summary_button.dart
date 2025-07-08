import 'package:flutter/material.dart';

import '../theme/app_color.dart';
import '../theme/app_theme.dart';

class SummaryButton extends StatelessWidget {
  final String text;
  final Function()? onPressed;
  final bool isEnabled;
  final Color? color;
  final double fontSize;

  const SummaryButton(this.text,{
    super.key, this.onPressed,
    this.isEnabled = true, this.color, this.fontSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: color ?? AppColor.main75,
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(0, 2),
              blurRadius: 10.0,
            )
          ]
      ),
      child: TextButton(
          onPressed: onPressed,
          child: SizedBox(
            width: AppTheme.fullWidth(context)/2,
            child: Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: fontSize,
                  color: AppColor.white,
                  fontWeight: FontWeight.bold
              ),
            ),
          )
      ),
    );
  }
}
