import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class ChildGridPage extends StatefulWidget {
  final String username;
  final List<dynamic>? buttons;

  ChildGridPage({required this.username, this.buttons});

  @override
  _ChildGridPageState createState() => _ChildGridPageState();
}

class _ChildGridPageState extends State<ChildGridPage> {
  List<Map<String, dynamic>> gridData = [];
  List<String> currentFolderPath = [];  // Track folder path
  bool isLoading = true;
  bool isRemovalMode = false; // To track removal mode
  Directory? appDirectory;
  final ImagePicker _picker = ImagePicker();
  List<dynamic> pictogramsData = [];

  @override
  void initState() {
    super.initState();
    loadAppDirectory();
    loadData(); // Load pictogram data
    if (widget.buttons != null) {
      processBoardData(widget.buttons!);
    } else {
      fetchBoardInfo();
    }
  }

  Future<void> loadAppDirectory() async {
    try {
      appDirectory = await getApplicationDocumentsDirectory();
    } catch (e) {
      print("Error loading app directory: $e");
    }
    setState(() {});
  }

  // Load pictogram data from a local JSON file
  Future<void> loadData() async {
    String jsonString = await rootBundle.loadString('assets/board_info/pictograms.json');
    List<dynamic> data = jsonDecode(jsonString);
    setState(() {
      pictogramsData = data;
    });
  }

  Future<void> fetchBoardInfo() async {
    try {
      String path = 'user_folders/${widget.username}/board.json';
      Reference storageRef = FirebaseStorage.instance.ref().child(path);
      String downloadUrl = await storageRef.getDownloadURL();

      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode == 200) {
        Map<String, dynamic> boardData = jsonDecode(response.body);
        processBoardData(boardData['buttons']);
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void processBoardData(List<dynamic> buttons) async {
    List<Map<String, dynamic>> tempGridData = [];

    for (var button in buttons) {
      String imageFileName = button['image_url'];
      tempGridData.add({
        "image_url": imageFileName,
        "label": button['label'],
        "folder": button['folder'],
        "buttons": button['folder'] == true ? button['buttons'] : [], // Keep nested buttons for folders
        "id": button['id'],
      });
    }

    setState(() {
      gridData = tempGridData;
      isLoading = false;
    });
  }
  Future<String> fetchImageFromStorage(String imageName) async {
    try {
      // Check if the image is in Firebase Storage
      String storagePath = 'initial_board_images/$imageName';
      Reference storageRef = FirebaseStorage.instance.ref().child(storagePath);
      String downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      // If the image is not in Firebase, it might be a pictogram from the internet
      return '';
    }
  }


  // Search function for pictograms
  dynamic searchButtonData(List<dynamic> data, String keyword) {
    keyword = keyword.trim().toLowerCase();
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

  // Add button from pictogram or custom image
  Future<void> addCustomImageButton(String enteredText) async {
    bool? choosePictogram = await _showChoiceDialog(context);
    if (choosePictogram == true) {
      dynamic buttonData = searchButtonData(pictogramsData, enteredText);
      if (buttonData != null) {
        await _createFirstButtonFromData(buttonData, enteredText);
      } else {
        await _showConfirmationDialog(context, "Pictogram not found. Would you like to upload a custom image?");
        await uploadCustomImage(enteredText);
      }
    } else {
      await uploadCustomImage(enteredText);
    }
  }

  Future<void> uploadCustomImage(String enteredText) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      try {
        String fileName = Uuid().v4(); // Generate a unique file name
        Reference firebaseStorageRef = FirebaseStorage.instance.ref('initial_board_images/$fileName');

        // Upload the image file to Firebase Storage
        await firebaseStorageRef.putFile(File(image.path));

        // Get the download URL of the uploaded image
        String imageUrl = await firebaseStorageRef.getDownloadURL();

        Map<String, dynamic> currentFolder = getCurrentFolder();

        setState(() {
          currentFolder['buttons'].add({
            "id": Uuid().v4(),
            "image_url": fileName, // Store just the file name
            "label": enteredText,
            "folder": false,
            "buttons": [],
          });
        });

        await updateBoardInFirebase();
      } catch (e) {
        print("Error uploading image: $e");
      }
    }
  }

  Future<void> _createFirstButtonFromData(Map<String, dynamic> data, String enteredText) async {
    try {
      String imageUrl = "https://static.arasaac.org/pictograms/${data['_id']}/${data['_id']}_2500.png";

      // Download the pictogram from the URL
      http.Response response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        // Save the image to Firebase Storage
        String fileName = Uuid().v4();  // Generate a unique file name
        Reference firebaseStorageRef = FirebaseStorage.instance.ref('initial_board_images/$fileName');

        // Store the downloaded image
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName.png');
        await file.writeAsBytes(response.bodyBytes);

        await firebaseStorageRef.putFile(file);
        String firebaseImageUrl = await firebaseStorageRef.getDownloadURL();

        Map<String, dynamic> currentFolder = getCurrentFolder();

        setState(() {
          currentFolder['buttons'].add({
            "id": data["_id"].toString(),
            "image_url": fileName, // Store the file name instead of the URL
            "label": enteredText,
            "folder": false,
            "buttons": [],
          });
        });

        await updateBoardInFirebase();
      } else {
        throw Exception('Error downloading pictogram image');
      }
    } catch (e) {
      print("Error creating pictogram button: $e");
    }
  }

  Future<void> updateBoardInFirebase() async {
    try {
      String path = 'user_folders/${widget.username}/board.json';
      Reference storageRef = FirebaseStorage.instance.ref().child(path);

      // Convert the full gridData (including folders and their buttons) to JSON
      Map<String, dynamic> boardData = {
        "buttons": gridData, // Store the entire current gridData, including nested folders
      };

      // Upload the updated boardData to Firebase
      await storageRef.putString(jsonEncode(boardData), metadata: SettableMetadata(contentType: 'application/json'));
    } catch (e) {
      print("Error updating board in Firebase: $e");
    }
  }

  Map<String, dynamic> getCurrentFolder() {
    Map<String, dynamic> currentFolder = {"buttons": gridData};
    for (var folderId in currentFolderPath) {
      currentFolder = currentFolder['buttons'].firstWhere((folder) => folder['id'] == folderId);
    }
    return currentFolder;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.username}\'s Grid'),
        actions: [
          IconButton(
            icon: Icon(isRemovalMode ? Icons.check : Icons.delete),
            onPressed: () {
              setState(() {
                isRemovalMode = !isRemovalMode;
              });
            },
          ),
          if (currentFolderPath.isNotEmpty)
            IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: navigateBack,
            ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : gridData.isEmpty
          ? Center(child: Text("No data found for this child"))
          : Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: getCurrentFolder()['buttons'].length,
          itemBuilder: (context, index) {
            final item = getCurrentFolder()['buttons'][index];
            final imageFileName = item['image_url']; // This is just the file name
            final imageUrlFuture = fetchImageFromStorage(imageFileName);

            return FutureBuilder(
              future: imageUrlFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error loading image"));
                } else if (!snapshot.hasData || snapshot.data == '') {
                  return Center(child: Text("Image not found"));
                }

                return GestureDetector(
                  onTap: isRemovalMode
                      ? () {
                    // Handle removal of the item
                    removeButton(index);
                  }
                      : () {
                    // Handle tapping the button (e.g., opening folder or triggering action)
                  },
                  child: GridTile(
                    child: Image.network(snapshot.data!, fit: BoxFit.cover),
                    footer: GridTileBar(
                      backgroundColor: Colors.black45,
                      title: Text(item['label'] ?? ''),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        children: [
          SpeedDialChild(
            child: Icon(Icons.add),
            label: 'Add Button',
            onTap: () async {
              String? enteredText = await _showTextInputDialog(context, "Enter button label:");
              if (enteredText != null) {
                await addCustomImageButton(enteredText);
              }
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.folder),
            label: 'Add Folder',
            onTap: () async {
              String? folderName = await _showTextInputDialog(context, "Enter folder name:");
              if (folderName != null) {
                Map<String, dynamic> currentFolder = getCurrentFolder();

                setState(() {
                  currentFolder['buttons'].add({
                    "id": Uuid().v4(),
                    "image_url": null,
                    "label": folderName,
                    "folder": true,
                    "buttons": [], // Empty for now
                  });
                });

                await updateBoardInFirebase();
              }
            },
          ),
        ],
      ),
    );
  }

  Future<bool?> _showChoiceDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose Image Type'),
          content: Text('Would you like to search for a pictogram or upload a custom image?'),
          actions: <Widget>[
            TextButton(
              child: Text('Pictogram'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
            TextButton(
              child: Text('Custom Image'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
          ],
        );
      },
    );
  }

  Future<String?> _showTextInputDialog(BuildContext context, String title) async {
    TextEditingController _textFieldController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: _textFieldController,
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(_textFieldController.text);
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showConfirmationDialog(BuildContext context, String message) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmation'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  void navigateBack() {
    setState(() {
      currentFolderPath.removeLast(); // Move one folder back
    });
  }

  void removeButton(int index) {
    setState(() {
      getCurrentFolder()['buttons'].removeAt(index);
    });
    updateBoardInFirebase();
  }
}
