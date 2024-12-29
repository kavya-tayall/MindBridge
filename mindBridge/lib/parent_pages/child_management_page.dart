import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test_app/cache_utility.dart';
import 'package:test_app/widgets/child_provider.dart';
import '../widgets/parent_music_page.dart';
import 'edit_child_grid.dart';

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

class ChildManagementPage extends StatefulWidget {
  final Function(int) onNavigate;

  ChildManagementPage({required this.onNavigate});

  @override
  _ChildManagementPageState createState() => _ChildManagementPageState();
}

class _ChildManagementPageState extends State<ChildManagementPage> {
  Map<String, String> childIdToUsername = {};
  bool isLoading = true;
  String parentEmailasUserName = "";
  String adminName = "";
  bool isFetchingData = false;

  @override
  void initState() {
    super.initState();
    print("inside init state");
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _fetchAndStoreChildrenDataInBackground();
    //  fetchChildren();
  }

  Future<void> _fetchAndStoreChildrenDataInBackground() async {
    setState(() {
      isFetchingData = true;
    });

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      print('current user: $currentUser');
      if (currentUser != null) {
        String parentId = currentUser.uid;
        print('parent id: $parentId');
        DocumentSnapshot parentSnapshot = await FirebaseFirestore.instance
            .collection('parents')
            .doc(parentId)
            .get();

        if (parentSnapshot.exists) {
          Map<String, dynamic>? parentData =
              parentSnapshot.data() as Map<String, dynamic>?;
          parentEmailasUserName = parentData?['email'];
          if (parentData != null && parentData['children'] != null) {
            List<String> childIds = List<String>.from(parentData['children']);
            print('inside _fetchAndStoreChildrenDataInBackground');
            await fetchAndStoreChildrenData(
                parentId, childIds, context, parentEmailasUserName, true,
                refreshButtons: true);
          }
        }
        print('done fetching children now prepin to child list');
        setState(() {
          isLoading = true;
        });

        try {
          User? currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            childIdToUsername.clear();
            var childCollection = ChildCollectionWithKeys.instance;
            for (var record in childCollection.allRecords) {
              if (record.username != null && record.childuid.isNotEmpty) {
                childIdToUsername[record.childuid] = record.username!;
              }
            }
          }
          print('completed fetching children');
          // Trigger UI rebuild after the data is updated
          setState(() {});
        } catch (e) {
          print('Error fetching children: $e');
        } finally {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error in background data fetching: $e');
    } finally {
      setState(() {
        isFetchingData = false;
      });
    }
  }

  Future<void> fetchChildren() async {
    setState(() {
      isLoading = true;
    });

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        childIdToUsername.clear();
        var childCollection = ChildCollectionWithKeys.instance;
        for (var record in childCollection.allRecords) {
          if (record.username != null && record.childuid.isNotEmpty) {
            childIdToUsername[record.childuid] = record.username!;
          }
        }
      }
      print('completed fetching children');
      // Trigger UI rebuild after the data is updated
      setState(() {});
    } catch (e) {
      print('Error fetching children: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: PreferredSize(
          preferredSize: Size.fromHeight(75.0),
          child: AppBar(
            backgroundColor: Colors.white,
            elevation: 0, // Removes shadow
            automaticallyImplyLeading: false,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.home, color: Colors.black, size: 30),
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 3.0),
                      child: Image.asset("assets/imgs/logo_without_text.png",
                          width: 60),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: GradientText(
                        "Voxigo",
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue,
                            Colors.blueAccent,
                            Colors.deepPurpleAccent,
                          ],
                        ),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 30,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            toolbarHeight: 80,
          )),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hello $adminName! 👋",
                          style: TextStyle(
                            color: theme.textTheme.titleMedium!.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 30,
                          ),
                        ),
                        SizedBox(height: 30),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Quick Actions ⚡️',
                            style: TextStyle(
                                color: theme.textTheme.titleMedium!.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 25),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: EdgeInsets.zero,
                                  elevation: 4),
                              onPressed: () {
                                widget.onNavigate(2);
                              },
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFFF64CD3),
                                      Color(0xFFAF70FF)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Container(
                                  width: 150,
                                  height: 200,
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Icon(Icons.chat,
                                          size: 75, color: Color(0xA6000000)),
                                      Text(
                                        "Chat with VoxiBot",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                          color: Color(0xA6000000),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.black,
                                  backgroundColor: Colors.lightBlue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: EdgeInsets.zero,
                                  elevation: 4),
                              onPressed: () {
                                setState(() {
                                  widget.onNavigate(1);
                                });
                              },
                              child: Container(
                                width: 150,
                                height: 200,
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(Icons.bar_chart,
                                        size: 75, color: Color(0xA6000000)),
                                    Text(
                                      "Button & Feeling Stats",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        color: Color(0xA6000000),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 30),
                        AbsorbPointer(
                          absorbing: isFetchingData,
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10)),
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.primaryColorLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'Manage Your Children 👥',
                                    style: TextStyle(
                                        color:
                                            theme.textTheme.titleMedium!.color,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 25),
                                  ),
                                ),
                                SizedBox(height: 16.0),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: childIdToUsername.length,
                                  itemBuilder: (context, index) {
                                    String key =
                                        childIdToUsername.keys.elementAt(index);
                                    String value = childIdToUsername[key]!;
                                    return Container(
                                      margin: EdgeInsets.only(
                                          bottom: 16.0, left: 6, right: 6),
                                      decoration: BoxDecoration(
                                        color: theme.primaryColorDark,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: ExpansionTile(
                                        title: Text(value),
                                        children: <Widget>[
                                          ListTile(
                                            title: Text('Edit Grid'),
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      ChildGridPage(
                                                          username: value,
                                                          childId: key),
                                                ),
                                              );
                                            },
                                          ),
                                          ListTile(
                                            title: Text('Edit Music'),
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      ParentMusicPage(
                                                    username: value,
                                                    childId: key,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          ListTile(
                                            title:
                                                Text('Edit Username/Password'),
                                            onTap: () {},
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ]),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isFetchingData)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: LinearProgressIndicator(),
                  ),
              ],
            ),
    );
  }
}
