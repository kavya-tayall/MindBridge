import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:test_app/parent_pages/ai_chatbot.dart';
import 'package:test_app/parent_pages/stats_page.dart';
import 'firebase_options.dart';
import 'package:test_app/parent_pages/child_management_page.dart';
import 'child_pages/music_page.dart';
import 'widgets/child_provider.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/bottom_nav_bar.dart';
import 'child_pages/home_page.dart';
import 'child_pages/settings_page.dart';
import 'parent_pages/parent_login_page.dart';
import 'child_pages/child_login_page.dart';
import 'parent_pages/parent_settings.dart';
import 'child_pages/feelings_page.dart';
import 'child_pages/fidget_spinner_suggestion.dart';
import 'child_pages/suggestions_page.dart';
import 'child_pages/coloring_suggestion.dart';
import 'child_pages/breathing_suggestion.dart';
import 'child_pages/54321_suggestion.dart';

typedef VoidCallBack = void Function();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Attempt to initialize Firebase only if no instance exists
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.ios);
    }
  } catch (e) {
    print("Firebase initialization error: $e");
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => ChildProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Color(0xffdde8ff)),
        ),
        initialRoute: '/child_login',
        routes: {
          '/parent_login': (_) => ParentLoginPage(),
          '/child_login': (_) => ChildLoginPage(),
          '/base': (_) => BasePage(),
          '/feelings': (_) => FeelingsPage(),
          '/music': (_) => MusicPage(),
          '/suggestions': (_) => SuggestionsPage(),
          '/fidget': (_) => FidgetSpinnerHome(),
          '/coloring': (_) => ColoringHome(),
          '/breathing': (_) => BreathingHome(),
          '/54321': (_) => FiveCalmDownHome(),
          '/parent_base': (_) => ParentBasePage(),
        },
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {}

class BasePage extends StatefulWidget {
  const BasePage({super.key});

  @override
  State<BasePage> createState() => BasePageState();
}

class BasePageState extends State<BasePage> {
  int selectedIndex = 0;
  List<dynamic> pathOfBoard = ["buttons"];
  Map<String, List> data = {};
  bool isLoading = true;
  final GlobalKey<HomePageState> homePageKey = GlobalKey<HomePageState>();

  @override
  void initState() {
    super.initState();
    _loadJsonData();
  }

  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  Future<void> _loadJsonData() async {
    String? jsonString =
    await Provider.of<ChildProvider>(context, listen: false)
        .fetchJson('board.json');

    final jsonData = jsonDecode(jsonString!);

    setState(() {
      data = Map.from(jsonData);
      isLoading = false;
    });
  }

  void updatePathOfBoard(List<dynamic> newPath) {
    setState(() {
      pathOfBoard = List.from(newPath);
    });
  }

  void goBack() {
    setState(() {
      if (pathOfBoard.length > 1) {
        pathOfBoard.removeLast();
        pathOfBoard.removeLast();

        updatePathOfBoard(pathOfBoard);
      }
    });
  }

  Future<void> modifyData(Map<String, List> newData) async {
    setState(() {
      data = Map.from(newData);
    });
    await Provider.of<ChildProvider>(context, listen: false)
        .changeGridJson(newData);
  }



  @override
  Widget build(BuildContext context) {
    Widget page;
    if (Provider.of<ChildProvider>(context, listen: false).childData?['settings']['emotion handling'] == false && Provider.of<ChildProvider>(context, listen: false).childData?['settings']['audio page'] == false){
      switch (selectedIndex) {
        case 0:
          page = DataWidget(
              data: data,
              onDataChange: (Map<String, List> newData) async {
                modifyData;
              },
              child: PathWidget(
                  onPathChange: updatePathOfBoard,
                  pathOfBoard: pathOfBoard,
                  child: HomePage(key: homePageKey)));
        case 1:
          page = CustomSettings();
        default:
          throw UnimplementedError('no widget for $selectedIndex');
      }
    } else if(Provider.of<ChildProvider>(context, listen: false).childData?['settings']['emotion handling'] == true && Provider.of<ChildProvider>(context, listen: false).childData?['settings']['audio page'] == false){
      switch (selectedIndex) {
        case 0:
          page = DataWidget(
              data: data,
              onDataChange: (Map<String, List> newData) async {
                modifyData;
              },
              child: PathWidget(
                  onPathChange: updatePathOfBoard,
                  pathOfBoard: pathOfBoard,
                  child: HomePage(key: homePageKey)));
        case 1:
          page = FeelingsPage();
        case 2:
          page = CustomSettings();
        default:
          throw UnimplementedError('no widget for $selectedIndex');
      }
    } else if (Provider.of<ChildProvider>(context, listen: false).childData?['settings']['emotion handling'] == false && Provider.of<ChildProvider>(context, listen: false).childData?['settings']['audio page'] == true){
      switch (selectedIndex) {
        case 0:
          page = DataWidget(
              data: data,
              onDataChange: (Map<String, List> newData) async {
                modifyData;
              },
              child: PathWidget(
                  onPathChange: updatePathOfBoard,
                  pathOfBoard: pathOfBoard,
                  child: HomePage(key: homePageKey)));
        case 1:
          page = MusicPage();
        case 2:
          page = CustomSettings();
        default:
          throw UnimplementedError('no widget for $selectedIndex');
      }
    } else{
      switch (selectedIndex) {
        case 0:
          page = DataWidget(
              data: data,
              onDataChange: (Map<String, List> newData) async {
                modifyData;
              },
              child: PathWidget(
                  onPathChange: updatePathOfBoard,
                  pathOfBoard: pathOfBoard,
                  child: HomePage(key: homePageKey)));
        case 1:
          page = FeelingsPage();
        case 2:
          page = MusicPage();
        case 3:
          page = CustomSettings();
        default:
          throw UnimplementedError('no widget for $selectedIndex');
      }
    }

    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(child: page),
          CustomNavigationBar(
            selectedIndex: selectedIndex,
            onItemTapped: onItemTapped,
          ),
        ],
      ),
    );
  }
}

class ParentBasePage extends StatefulWidget {
  const ParentBasePage({super.key});

  @override
  ParentBasePageState createState() => ParentBasePageState();
}

class ParentBasePageState extends State<ParentBasePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> _widgetOptions = <Widget>[
      ChildManagementPage(
        onNavigate: (int index) {
          _onItemTapped(index);
        },
      ),
      StatsPage(),
      ChatPage(),
      ParentSettingsPage(),
    ];

    return Scaffold(
      body: Container(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        selectedIconTheme: IconThemeData(
          size: 30,
        ),
        unselectedIconTheme: IconThemeData(
          size: 25,
        ),
        onTap: _onItemTapped,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        backgroundColor: Colors.white,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        iconSize: 20,
        selectedFontSize: 0,
        unselectedFontSize: 0,
      ),
    );
  }
}