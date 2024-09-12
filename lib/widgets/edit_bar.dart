import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:uuid/uuid.dart';

import '../child_pages/home_page.dart';
import 'buttons.dart';

class EditBar extends StatelessWidget {
  final dynamic data;

  EditBar({required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        AddButton(data: data),
        RemoveButton(),
      ],
    );
  }
}

class AddButton extends StatefulWidget {
  final Map<String, dynamic> data;

  AddButton({required this.data});

  @override
  State<AddButton> createState() => AddButtonState();
}

class AddButtonState extends State<AddButton> {
  // Define consistent colors and sizes
  final Color buttonColor = Colors.lightBlue;
  final Color iconColor = Colors.white;
  final double buttonSize = 60.0;

  void addVisibleButtons(FirstButton button) {
    final dataWidget = DataWidget.of(context);
    final pathWidget = PathWidget.of(context);

    if (dataWidget != null) {
      setState(() {
        dynamic nestedData = dataWidget.data;

        for (var folder in pathWidget!.pathOfBoard) {
          nestedData = nestedData[folder];
        }

        // Generate a unique ID for the new button
        final buttonId = Uuid().v4(); // Generate a UUID
        final newButton = button.toJson()..['id'] = buttonId;

        // Add the button to the top-level buttons list
        nestedData.add(newButton); // Add button to the list

        // Notify the widget that the data has changed
        dataWidget.onDataChange(dataWidget.data);

        // Save the updated data to file
        context.findAncestorStateOfType<HomePageState>()?.saveUpdatedData(dataWidget.data);

        // Update the UI
        context.findAncestorStateOfType<HomePageState>()?.updateGrid();
      });
    } else {
      print('DataWidget is null');
    }
  }

  void addFolder(String folderName) {
    final dataWidget = DataWidget.of(context);
    final pathWidget = PathWidget.of(context);

    if (dataWidget != null) {
      setState(() {
        dynamic nestedData = dataWidget.data;

        for (var folder in pathWidget!.pathOfBoard) {
          nestedData = nestedData[folder];
        }

        // Generate a unique ID for the new folder
        final folderId = Uuid().v4(); // Generate a UUID
        final newFolder = {
          "id": folderId,
          "image_url": "assets/imgs/OneDrive_Folder_Icon.png",
          "label": folderName,
          "folder": true,
          "buttons": [], // Empty list to hold buttons inside this folder
        };

        // Add the folder to the top-level buttons list
        nestedData.add(newFolder); // Add folder to the list

        // Notify the widget that the data has changed
        dataWidget.onDataChange(dataWidget.data);

        // Save the updated data to file
        context.findAncestorStateOfType<HomePageState>()?.saveUpdatedData(dataWidget.data);

        // Update the UI
        context.findAncestorStateOfType<HomePageState>()?.updateGrid();
      });
    } else {
      print('DataWidget is null');
    }
  }

  List<dynamic> pictogramsData = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    // Load the JSON string from the asset
    String jsonString = await rootBundle.loadString('assets/board_info/pictograms.json');
    // Parse the JSON string into a Dart object
    List<dynamic> data = jsonDecode(jsonString);

    setState(() {
      pictogramsData = data; // Store the parsed data
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: buttonColor, iconTheme:
      IconThemeData(color: iconColor),
        children: [
          SpeedDialChild(
            child: Icon(Icons.add, color: iconColor),
            backgroundColor: buttonColor,
            label: 'Add Button',
            onTap: () async {
              String? enteredText = await _showTextInputDialog(context, "Enter button label:");
              if (enteredText != null) {
                dynamic buttonData = searchButtonData(pictogramsData, enteredText);
                if (buttonData != null) {
                  FirstButton button = _createFirstButtonFromData(buttonData, enteredText);
                  addVisibleButtons(button);
                } else {
                  print("Button not found");
                }
              }
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.create_new_folder, color: iconColor),
            backgroundColor: buttonColor,
            label: 'Add Folder',
            onTap: () async {
              String? folderName = await _showTextInputDialog(context, "Enter folder name:");
              if (folderName != null) {
                addFolder(folderName);
              }
            },
          ),
        ],
        // Remove shadow
        elevation: 0,
      ),
    );
  }

  dynamic searchButtonData(List<dynamic> data, String keyword) {
    keyword = keyword.trim().toLowerCase(); // Trim and convert to lowercase
    for (var item in data) {
      if (item is Map<String, dynamic> && item.containsKey("keywords")) {
        for (var keywordData in item["keywords"]) {
          if (keywordData["keyword"].toString().toLowerCase() == keyword) {
            return item;
          }
        }
      }
    }
    return null;
  }

  FirstButton _createFirstButtonFromData(Map<String, dynamic> data, String enteredText) {
    // Construct the image URL using the _id and required resolution
    String imageUrl = "https://static.arasaac.org/pictograms/${data['_id']}/${data['_id']}_2500.png";

    // Get the keyword to use as the label
    String label = enteredText;

    return FirstButton(
      id: data["_id"].toString(), // Convert _id to string
      imagePath: imageUrl,
      text: label,
      size: 60.0,
      onPressed: () {
        // Implement what happens when the button is pressed
      },
    );
  }


  Future<String?> _showTextInputDialog(BuildContext context, String hintText) async {
    TextEditingController controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(hintText),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: "Type here"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Submit'),
              onPressed: () {
                Navigator.of(context).pop(controller.text);
              },
            ),
          ],
        );
      },
    );
  }
}

class RemoveButton extends StatefulWidget {
  @override
  State<RemoveButton> createState() => RemoveButtonState();
}

class RemoveButtonState extends State<RemoveButton> {
  bool isRemovalMode = false;

  // Define consistent colors and sizes
  final Color buttonColor = Colors.lightBlue;
  final Color iconColor = Colors.white;
  final double buttonSize = 60.0;

  void removeVisibleButton(FirstButton button) {
    final dataWidget = DataWidget.of(context);
    final pathWidget = PathWidget.of(context);

    if (dataWidget != null) {
      setState(() {
        dynamic nestedData = dataWidget.data;

        for (var folder in pathWidget!.pathOfBoard) {
          nestedData = nestedData[folder];
        }

        // Find and remove the button with the specified ID
        nestedData.removeWhere((b) => b['id'] == button.id);

        // Notify the widget that the data has changed
        dataWidget.onDataChange(dataWidget.data);

        // Save the updated data to file
        context.findAncestorStateOfType<HomePageState>()?.saveUpdatedData(dataWidget.data);

        // Update the UI
        context.findAncestorStateOfType<HomePageState>()?.updateGrid();
      });
    } else {
      print('DataWidget is null');
    }

    print("Button with ID ${button.id} is removed");
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: CircleBorder(),
          padding: EdgeInsets.all(16), // Adjust padding to fit the size
          backgroundColor: buttonColor, // Match the AddButton color
          minimumSize: Size(buttonSize, buttonSize), // Ensure button size is consistent
        ),
        onPressed: () {
          context.findAncestorStateOfType<HomePageState>()?.changeRemovalState();
          setState(() {
            isRemovalMode = !isRemovalMode;
          });
        },
        child: Icon(isRemovalMode ? Icons.check : Icons.delete, color: iconColor), // Match the AddButton icon color
      ),
    );
  }
}