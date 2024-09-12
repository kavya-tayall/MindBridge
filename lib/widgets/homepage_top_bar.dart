import 'package:flutter/material.dart';
import 'buttons.dart';



class HomeTopBar extends StatelessWidget {
  final List<FirstButton> clickedButtons;

  HomeTopBar({required this.clickedButtons});


  @override
  Widget build(BuildContext context) {

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
            child: Row(children: clickedButtons.map((button) {
              return Padding(
                padding: EdgeInsets.all(5),
                child: button,
              );
            }).toList(),)),
      ],
    );
  }
}


