import 'package:flutter/material.dart';

class DotContainer extends StatelessWidget {

  final Color? color;

  const DotContainer({this.color, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      margin: const EdgeInsets.symmetric(horizontal: 5.0),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(50.0)),
    );
  }
}
