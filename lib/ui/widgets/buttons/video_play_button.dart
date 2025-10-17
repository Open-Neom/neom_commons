import 'package:flutter/material.dart';

class VideoPlayButton extends StatelessWidget {

  final bool isPlaying;
  final Function? controllerFunction;

  const VideoPlayButton({this.isPlaying = false, this.controllerFunction, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [
                  const Color(0x36FFFFFF).withAlpha(26),
                  const Color(0x0FFFFFFF).withAlpha(26)
                ],
                begin: FractionalOffset.topLeft,
                end: FractionalOffset.bottomRight
            ),
            borderRadius: BorderRadius.circular(50)
        ),
        child: IconButton(
          icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow,),
          iconSize: 75,
          color: Colors.white54,
          onPressed: () {
            if(controllerFunction != null) {
              controllerFunction!();
            }
          },
        ),
      ),
    );
  }

}
