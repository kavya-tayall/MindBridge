import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'homepage_top_bar.dart';
import 'Buttons.dart';
import 'EditBar.dart';
import 'main.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var selectedButtons = context.watch<MyAppState>().selectedButtons;
    var visibleButtonsVar = context.watch<MyAppState>().visibleButtons;
    var pathOfBoardVar = context.watch<MyAppState>().pathOfBoard;


    List<FirstButton> buttons = [
      //list of buttons to pass into grid
      FirstButton(imagePath: 'assets/Screenshot 2024-07-29 at 4.31.43 PM.png',
          text: 'Button 1'),
      FirstButton(imagePath: 'assets/Screenshot 2024-07-29 at 4.31.43 PM.png',
          text: 'Button 2'),
      FirstButton(imagePath: 'assets/Screenshot 2024-07-29 at 4.31.43 PM.png',
          text: 'Button 2'),
      FirstButton(imagePath: 'assets/Screenshot 2024-07-29 at 4.31.43 PM.png',
          text: 'Button 2'),
      FirstButton(imagePath: 'assets/Screenshot 2024-07-29 at 4.31.43 PM.png',
          text: 'Button 2'),
      FirstButton(imagePath: 'assets/Screenshot 2024-07-29 at 4.31.43 PM.png',
          text: 'Button 1'),
      FirstButton(imagePath: 'assets/Screenshot 2024-07-29 at 4.31.43 PM.png',
          text: 'Button 1'),
      FirstButton(imagePath: 'assets/Screenshot 2024-07-29 at 4.31.43 PM.png',
          text: 'Button 1'),
      FirstButton(imagePath: 'assets/Screenshot 2024-07-29 at 4.31.43 PM.png',
          text: 'Button 1'),
      FirstButton(imagePath: 'assets/Screenshot 2024-07-29 at 4.31.43 PM.png',
          text: 'Button 1'),
      FirstButton(imagePath: 'assets/Screenshot 2024-07-29 at 4.31.43 PM.png',
          text: 'Button 1'),
      FirstButton(imagePath: 'assets/Screenshot 2024-07-29 at 4.31.43 PM.png',
          text: 'Button 1'),
      FirstButton(imagePath: 'assets/Screenshot 2024-07-29 at 4.31.43 PM.png',
          text: 'Button 1'),
      FirstButton(imagePath: 'assets/Screenshot 2024-07-29 at 4.31.43 PM.png',
          text: 'Button 1'),

      // Add more buttons as needed
    ];
    return Column(children: <Widget>[
      Container(
          color: Colors.blueAccent,
          padding: EdgeInsets.all(8),
          child: HomeTopBar(clickedButtons: selectedButtons)),
      Expanded(
          child: Container(
              color: Colors.transparent,
              child: Center(child: Grid(visibleButtons: visibleButtonsVar, pathOfBoard: pathOfBoardVar)))),
      EditBar(),
      SizedBox(height: 20),
    ]);
  }
}
