import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../widgets/parent_music_page.dart';
import 'edit_child_grid.dart';

class ChildManagementPage extends StatefulWidget {
  @override
  _ChildManagementPageState createState() => _ChildManagementPageState();
}

class _ChildManagementPageState extends State<ChildManagementPage> {
  Map<String, String> childIdToUsername = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchChildren();
  }

  Future<void> fetchChildren() async {
    setState(() {
      isLoading = true;
    });

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        String parentId = currentUser.uid;
        DocumentSnapshot parentSnapshot = await FirebaseFirestore.instance
            .collection('parents')
            .doc(parentId)
            .get();

        if (parentSnapshot.exists) {
          Map<String, dynamic>? parentData =
          parentSnapshot.data() as Map<String, dynamic>?;
          if (parentData != null && parentData['children'] != null) {
            List<String> childIds = List<String>.from(parentData['children']);

            for (String childId in childIds) {
              DocumentSnapshot childSnapshot = await FirebaseFirestore.instance
                  .collection('children')
                  .doc(childId)
                  .get();

              if (childSnapshot.exists) {
                Map<String, dynamic>? childData =
                childSnapshot.data() as Map<String, dynamic>?;
                if (childData != null && childData['username'] != null) {
                  setState(() {
                    childIdToUsername[childId] = childData['username'];
                  });
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching children: $e');
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
        padding: EdgeInsets.all(16.0), // Padding around the entire list
        children: childIdToUsername.entries.map((entry) {
          return Container(
            margin: EdgeInsets.only(bottom: 16.0), // Space between each rectangle
            decoration: BoxDecoration(
              color: Colors.white, // Background color for each rectangle
              borderRadius: BorderRadius.circular(10), // Rounded corners
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1), // Slight shadow effect
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ExpansionTile(
              title: Text(entry.value),
              children: <Widget>[
                ListTile(
                  title: Text('Edit Grid'),
                  onTap: () {
                    // Navigate to ChildGridPage and pass the username
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChildGridPage(username: entry.value),
                      ),
                    );
                  },
                ),

                ListTile(
                  title: Text('Edit Music'),
                  onTap: () {
                    // Placeholder for edit music functionality

                    Navigator.push(
                        context,
                        MaterialPageRoute(
                        builder: (context) => ParentMusicPage(username: entry.value),
                    ),
                    );
                  },
                ),
                ListTile(
                  title: Text('Edit Username/Password'),
                  onTap: () {
                    // Placeholder for edit username/password functionality
                  },
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
