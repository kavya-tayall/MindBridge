import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../widgets/grid.dart';
import '../widgets/homepage_top_bar.dart';
import '../widgets/edit_bar.dart';
import '../main.dart';
import '../widgets/buttons.dart';
import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../widgets/child_provider.dart';
import '../widgets/suggestionWidget.dart';


class GradientText extends StatelessWidget {
  const GradientText(
      this.text, {
        required this.gradient,
        this.style,
      });

  final String text;
  final TextStyle? style;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(text, style: style),
    );
  }
}



class GradientIcon extends StatelessWidget {
  const GradientIcon(
      {
        required this.icon,
        required this.gradient,
      });

  final Icon icon;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: icon,
    );
  }
}


class DataWidget extends InheritedWidget {
  const DataWidget({
    required super.child,
    required this.data,
    required this.onDataChange,
  });

  final Map<String, List> data;
  final Future<void> Function(Map<String, List> newData) onDataChange;

  static DataWidget? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DataWidget>();
  }

  @override
  bool updateShouldNotify(DataWidget oldWidget) {
    return oldWidget.data != data;
  }
}

class PathWidget extends InheritedWidget {
  const PathWidget({
    required super.child,
    required this.pathOfBoard,
    required this.onPathChange,
  });

  final List pathOfBoard;
  final void Function(List<dynamic> newPath) onPathChange;

  static PathWidget? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PathWidget>();
  }

  @override
  bool updateShouldNotify(PathWidget oldWidget) {
    return oldWidget.pathOfBoard != pathOfBoard;
  }
}


class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  FlutterTts flutterTts = FlutterTts();

  List<FirstButton> _selectedButtons = [];

  List<FirstButton> get selectedButtons => _selectedButtons;

  bool inRemovalState = false;

  @override
  void initState() {
    super.initState();
    flutterTts.setLanguage("en-US");
    flutterTts.setPitch(1.0);
    flutterTts.setSpeechRate(0.5);
  }

  void addPhraseToTopBar(String phrase, List imagePaths) {
    print("asdf1");
    List<String> words = phrase.split(' ');

    print("asdf");

    setState(() {
      _selectedButtons = [];
      for (int i=0; i<words.length; i++) {
        Uuid uuid = Uuid();
        print(i);
        FirstButton newButton = FirstButton(
          id: uuid.v4(),
          imagePath: imagePaths[i],
          text: words[i],
          size: 151.2,
          onPressed: ()=>{}
        );
        _selectedButtons.add(newButton);
      }
    });
  }

  void changeRemovalState() {
    setState(() {
      inRemovalState = !inRemovalState;
    });
  }

  void addButton(FirstButton button) async {
    setState(() {
      selectedButtons.add(button);
    });

  }
  void clearSelectedButtons() {
    setState(() {
      selectedButtons.clear();
    });
  }

  void backspaceSelectedButtons() {
    setState(() {
      _selectedButtons.removeLast();
    });
  }

  void removeVisibleButton(FirstButton button) {
    final dataWidget = DataWidget.of(context);
    final pathWidget = PathWidget.of(context);
    print("checkopint 1");
    if (dataWidget != null) {
      print("checkpoint 2");
      setState(() {

        dynamic nestedData = dataWidget.data;

        for (var folder in pathWidget!.pathOfBoard) {
          nestedData = nestedData[folder];
        }
        nestedData.removeWhere((b) => b['id'] == button.id);
        print("checkpoint 3");
        print(nestedData);

        dataWidget.onDataChange(dataWidget.data);
        context.findAncestorStateOfType<HomePageState>()?.saveUpdatedData(dataWidget.data);
        context.findAncestorStateOfType<HomePageState>()?.updateGrid();
      });
    } else {
      print('DataWidget is null');
    }

    print("Button with ID ${button.id} is removed");
  }

  Future<void> removeFolder(int folderIndex) async {
    final dataWidget = DataWidget.of(context);
    final pathWidget = PathWidget.of(context);

    dynamic nestedData = dataWidget?.data;
    for (var folder in pathWidget!.pathOfBoard) {
      nestedData = nestedData[folder];
    }


    bool? confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Folder"),
          content: Text("Are you sure you want to delete this folder and all its contents?"),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text("Delete"),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );


    if (confirmed == true) {
      setState(() {
        nestedData.removeAt(folderIndex);


        dataWidget?.onDataChange(dataWidget.data);


        context.findAncestorStateOfType<HomePageState>()?.saveUpdatedData(dataWidget!.data);


        context.findAncestorStateOfType<HomePageState>()?.updateGrid();
      });

      print("Folder at index $folderIndex removed");
    }
  }

  Future<void> updateGrid() async {
    final gridState = context.findAncestorStateOfType<GridState>();
    gridState?.updateVisibleButtons();
  }

  Future<void> saveUpdatedData(Map<String, dynamic> updatedData) async {
    String jsonString = jsonEncode(updatedData);
    await writeJsonToFile(jsonString);

    print('Data saved to board.json in documents directory');
  }

  Future<void> writeJsonToFile(String jsonString) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/board.json');
    await file.writeAsString(jsonString);
  }

  Function(FirstButton button) selectOnPressedFunction() {
    if (!inRemovalState) {
      return addButton;
    } else {
      return removeVisibleButton;
    }
  }


  Future<void> addPhraseToPlay(String phrase) async {
    final childProvider = Provider.of<ChildProvider>(context, listen: false);

    try {

      await childProvider.addSelectedButton(phrase, Timestamp.now());
      print('Phrase added successfully to Firebase');
    } catch (e) {
      print('Error adding phrase to Firebase: $e');
    }
  }


  List<Widget> getWidgetList(List suggestions){
    List<Widget> widgetList = [];
    for (String suggestion in suggestions){
      widgetList.add(Text(suggestion));
    }
    return widgetList;
  }

  @override
  Widget build(BuildContext context) {
    if (context.findAncestorStateOfType<BasePageState>()!.isLoading) {
      return Center(child: CircularProgressIndicator());
    } else {
      return Column(
        children: <Widget>[

          Container(
            height: 190,
            color: Colors.white,
            padding: EdgeInsets.all(8),
            child: HomeTopBar(clickedButtons: selectedButtons),
          ),
          Container(
            color: Colors.white,
            padding: EdgeInsetsDirectional.symmetric(horizontal: 10),
            child: Divider(
              thickness: 2,
              color: Colors.grey,
            ),
          ),
          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(vertical:3, horizontal: 6),
            child: SizedBox(
              height: 50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PathWidget(
                    onPathChange: context.findAncestorStateOfType<BasePageState>()!.updatePathOfBoard,
                    pathOfBoard: context.findAncestorStateOfType<BasePageState>()!.pathOfBoard,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3.0),
                      child: TextButton.icon(
                        icon: Icon(Icons.arrow_back_rounded),
                        onPressed: () => context.findAncestorStateOfType<BasePageState>()?.goBack(),
                        label: const Text('Back'),
                        style: TextButton.styleFrom(
                          backgroundColor: Color(0xffdde8ff),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3.0),
                      child: TextButton.icon(
                        icon: Icon(Icons.backspace),
                        onPressed: backspaceSelectedButtons,
                        label: const Text('Backspace'),
                        style: TextButton.styleFrom(
                          backgroundColor: Color(0xffdde8ff),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3.0),
                      child: TextButton.icon(
                        icon: Icon(Icons.clear),
                        onPressed: clearSelectedButtons,
                        label: const Text('Clear'),
                        style: TextButton.styleFrom(
                          backgroundColor: Color(0xffdde8ff),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3.0),
                      child: TextButton.icon(
                        icon: Icon(Icons.play_arrow),
                        onPressed: () async {
                          String fullPhrase = _selectedButtons.map((button) => button.text).join(' ');
                          print(fullPhrase);
                          await flutterTts.speak(fullPhrase);
                          await addPhraseToPlay(fullPhrase);
                        },
                        label: const Text('Play'),
                        style: TextButton.styleFrom(
                          backgroundColor: Color(0xffdde8ff),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3.0),
                      child: TextButton.icon(
                        icon: Icon(Icons.stop),
                        onPressed: () => flutterTts.stop(),
                        label: const Text('Stop'),
                        style: TextButton.styleFrom(
                          backgroundColor: Color(0xffdde8ff),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3.0),
                      child: TextButton.icon(
                        icon: GradientIcon(icon: Icon(Icons.assistant), gradient: LinearGradient(colors: [Color(
                            0xFFF64CD3), Color(
                            0xFFAF70FF)])),
                        onPressed: () => {
                          _showFormDialog(context)
                        },
                        label: const GradientText('Helper', gradient: LinearGradient(colors: [Color(
                            0xFFAC70F8), Color(
                            0xFF7000FF)])),
                        style: TextButton.styleFrom(
                          backgroundColor: Color(0xffdde8ff),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: Center(
                child: PathWidget(
                  onPathChange: context.findAncestorStateOfType<BasePageState>()!.updatePathOfBoard,
                  pathOfBoard: context.findAncestorStateOfType<BasePageState>()!.pathOfBoard,
                  child: DataWidget(
                    onDataChange: context.findAncestorStateOfType<BasePageState>()!.modifyData,
                    data: context.findAncestorStateOfType<BasePageState>()!.data,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Grid(onButtonPressed: selectOnPressedFunction()),
                    ),
                  ),
                ),
              ),
            ),
          ),
          PathWidget(
            onPathChange: context.findAncestorStateOfType<BasePageState>()!.updatePathOfBoard,
            pathOfBoard: context.findAncestorStateOfType<BasePageState>()!.pathOfBoard,
            child: DataWidget(
              data: context.findAncestorStateOfType<BasePageState>()!.data,
              onDataChange: context.findAncestorStateOfType<BasePageState>()!.modifyData,
              child: EditBar(
                data: context.findAncestorStateOfType<BasePageState>()?.data,
              ),
            ),
          ),
          SizedBox(height: 20),
        ],
      );
    }
  }

  void _showFormDialog(BuildContext context) {
    final basePageState = context.findAncestorStateOfType<BasePageState>();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AISuggestionDialog(currentPhrase: _selectedButtons.map((button) => button.text).join(' '), homePageKey: basePageState!.homePageKey,);
      },
    );
  }

}
