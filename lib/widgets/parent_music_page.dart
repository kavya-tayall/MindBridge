import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart'; // For file selection
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';

class ParentMusicPage extends StatefulWidget {
  final String username;

  ParentMusicPage({required this.username});

  @override
  _ParentMusicPageState createState() => _ParentMusicPageState();
}

class _ParentMusicPageState extends State<ParentMusicPage> {
  List<Map<String, dynamic>> musicData = [];
  bool isLoading = true;
  AudioPlayer audioPlayer = AudioPlayer();
  String? currentAudioUrl;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;
  bool isPlaying = false; // Track if a song is playing

  Map<String, String> imageUrlCache = {};
  Map<String, String> audioUrlCache = {};

  @override
  void initState() {
    super.initState();
    loadMusicData(widget.username);
    audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        totalDuration = duration;
      });
    });
    audioPlayer.onPositionChanged.listen((position) {
      setState(() {
        currentPosition = position;
      });
    });
    audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        currentAudioUrl = null;
        isPlaying = false;
        currentPosition = Duration.zero;
      });
    });
  }

  Future<void> loadMusicData(String username) async {
    try {
      String path = 'user_folders/$username/music.json';

      Reference storageRef = FirebaseStorage.instance.ref().child(path);
      String downloadUrl = await storageRef.getDownloadURL();

      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        setState(() {
          musicData = data.cast<Map<String, dynamic>>();
          isLoading = false;
        });
        for (var item in musicData) {
          fetchImageAndAudioUrls(item['image'], item['link']);
        }
      } else {
        print("Error: Could not fetch data");
      }
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchImageAndAudioUrls(String imageName, String audioName) async {
    final imageUrl = await fetchImageFromStorage(imageName);
    final audioUrl = await fetchAudioFromStorage(audioName);

    print("Image URL: $imageUrl"); // Debug log
    print("Audio URL: $audioUrl"); // Debug log

    setState(() {
      imageUrlCache[imageName] = imageUrl;
      audioUrlCache[audioName] = audioUrl;
    });
  }


  Future<String> fetchImageFromStorage(String imageName) async {
    try {
      String storagePath = 'music_info/cover_images/$imageName';
      Reference storageRef = FirebaseStorage.instance.ref().child(storagePath);
      return await storageRef.getDownloadURL();
    } catch (e) {
      print("Error loading image for $imageName: $e");
      return '';
    }
  }

  Future<String> fetchAudioFromStorage(String audioName) async {
    try {
      String storagePath = 'music_info/mp3 files/$audioName';
      Reference storageRef = FirebaseStorage.instance.ref().child(storagePath);
      return await storageRef.getDownloadURL();
    } catch (e) {
      print("Error loading audio for $audioName: $e");
      return '';
    }
  }

  Future<void> playAudio(String audioUrl) async {
    if (currentAudioUrl == audioUrl && isPlaying) {
      audioPlayer.pause();
      setState(() {
        isPlaying = false;
      });
    } else {
      if (currentAudioUrl != audioUrl) {
        await audioPlayer.play(UrlSource(audioUrl));
        setState(() {
          currentAudioUrl = audioUrl;
          isPlaying = true;
        });
      } else {
        audioPlayer.resume();
        setState(() {
          isPlaying = true;
        });
      }
    }
  }

  Future<void> pauseAudio() async {
    await audioPlayer.pause();
    setState(() {
      isPlaying = false;
    });
  }

  Future<void> stopAudio() async {
    await audioPlayer.stop();
    setState(() {
      isPlaying = false;
      currentAudioUrl = null;
      currentPosition = Duration.zero;
    });
  }

  Future<void> seekAudio(Duration position) async {
    await audioPlayer.seek(position);
  }

  Future<void> rewindAudio() async {
    final newPosition = currentPosition - Duration(seconds: 10);
    await seekAudio(newPosition < Duration.zero ? Duration.zero : newPosition);
  }

  Future<void> fastForwardAudio() async {
    final newPosition = currentPosition + Duration(seconds: 10);
    await seekAudio(newPosition > totalDuration ? totalDuration : newPosition);
  }

  Future<void> addMusic() async {
    TextEditingController titleController = TextEditingController();
    PlatformFile? selectedImage;
    PlatformFile? selectedAudio;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Add Music'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Music title input
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(hintText: 'Enter Music Title'),
                  ),
                  SizedBox(height: 10),

                  // Image file picker
                  ElevatedButton(
                    onPressed: () async {
                      FilePickerResult? imageResult = await FilePicker.platform.pickFiles(type: FileType.image);
                      if (imageResult != null) {
                        setDialogState(() {
                          selectedImage = imageResult.files.first;
                        });
                      }
                    },
                    child: Text('Select Cover Image'),
                  ),
                  if (selectedImage != null)
                    Text('Image Selected: ${selectedImage!.name}', style: TextStyle(color: Colors.green)),

                  SizedBox(height: 10),

                  // Audio file picker
                  ElevatedButton(
                    onPressed: () async {
                      FilePickerResult? audioResult = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['mp3', 'wav'],
                      );

                      if (audioResult != null) {
                        setDialogState(() {
                          selectedAudio = audioResult.files.first;
                        });
                      }
                    },
                    child: Text('Select Audio File'),
                  ),
                  if (selectedAudio != null)
                    Text('Audio Selected: ${selectedAudio!.name}', style: TextStyle(color: Colors.green)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    if (titleController.text.isNotEmpty && selectedImage != null && selectedAudio != null) {
                      // Proceed to upload files
                      String imagePath = 'music_info/cover_images/${selectedImage!.name}';
                      String audioPath = 'music_info/mp3 files/${selectedAudio!.name}';

                      // Upload the files
                      await uploadFile(selectedImage!, imagePath);
                      await uploadFile(selectedAudio!, audioPath);

                      // Fetch the image and audio URLs immediately after upload
                      final imageUrl = await fetchImageFromStorage(selectedImage!.name);
                      final audioUrl = await fetchAudioFromStorage(selectedAudio!.name);

                      // Cache the URLs right away so that the UI can use them
                      setState(() {
                        imageUrlCache[selectedImage!.name] = imageUrl;
                        audioUrlCache[selectedAudio!.name] = audioUrl;
                      });

                      // Create the new music item
                      Map<String, dynamic> newMusicItem = {
                        'title': titleController.text.trim(),
                        'emotion': [], // Add default values or collect from user
                        'keywords': [], // Add default values or collect from user
                        'link': selectedAudio!.name, // Store only the audio file name
                        'image': selectedImage!.name, // Store only the image name
                      };

                      // Add the new song to the music data list
                      setState(() {
                        musicData.add(newMusicItem);
                      });

                      // Update Firebase JSON file with the new data
                      await updateMusicJson();

                      Navigator.of(context).pop(); // Close dialog
                    } else {
                      print("Error: Missing title, image, or audio file");
                    }
                  },
                  child: Text('Add Song'),
                ),
              ],
            );
          },
        );
      },
    );
  }





  Future<void> uploadFile(PlatformFile file, String path) async {
    try {
      print("Debug: Attempting to upload to path: $path");

      // Reference to Firebase storage path
      Reference ref = FirebaseStorage.instance.ref().child(path);

      // Check if the file has bytes (in-memory files)
      if (file.bytes != null) {
        print("Debug: Uploading file from memory: ${file.name}");

        // Upload file from memory
        await ref.putData(file.bytes!).then((taskSnapshot) {
          print("Debug: Upload completed: ${taskSnapshot.state}");
        });

      } else if (file.path != null) {
        // If bytes are not available, upload from local storage path
        final fileToUpload = File(file.path!);

        // Check if the file exists
        bool fileExists = await fileToUpload.exists();
        if (fileExists) {
          print("Debug: Uploading file from path: ${file.path}");

          // Upload file from the file system
          await ref.putFile(fileToUpload).then((taskSnapshot) {
            print("Debug: Upload completed: ${taskSnapshot.state}");
          });
        } else {
          print("Error: File does not exist at path: ${file.path}");
          return;
        }

      } else {
        print("Error: No valid file source found for ${file.name}");
        return;
      }

      print("Success: File uploaded successfully to path: $path");

    } on FirebaseException catch (e) {
      // Firebase-specific exceptions
      print("Firebase Error: ${e.message}");
      print("Error Code: ${e.code}");

    } catch (e, stackTrace) {
      // General exception handling
      print("General Error: $e");
      print("Stack Trace: $stackTrace");
    }
  }



  Future<void> updateMusicJson() async {
    String path = 'user_folders/${widget.username}/music.json';
    Reference ref = FirebaseStorage.instance.ref().child(path);
    await ref.putString(jsonEncode(musicData));
  }

  Future<void> deleteMusic(int index) async {
    var musicItem = musicData[index];
    String imageName = musicItem['image'];
    String audioName = musicItem['link'];

    // Remove from Firebase Storage
    await deleteFile('music_info/cover_images/$imageName');
    await deleteFile('music_info/mp3 files/$audioName');

    // Remove from local list and update Firebase
    musicData.removeAt(index);
    await updateMusicJson();
    setState(() {});
  }

  Future<void> deleteFile(String path) async {
    try {
      Reference ref = FirebaseStorage.instance.ref().child(path);
      await ref.delete();
    } catch (e) {
      print("Error deleting file: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Music List'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: addMusic,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: musicData.length,
        itemBuilder: (context, index) {
          final item = musicData[index];
          final imageUrl = imageUrlCache[item['image']] ?? '';
          final audioUrl = audioUrlCache[item['link']] ?? '';

          final isCurrentPlaying = currentAudioUrl == audioUrl;

          return Card(
            child: ListTile(
              leading: imageUrl.isNotEmpty
                  ? Image.network(imageUrl, width: 50, height: 50)
                  : Icon(Icons.music_note),
              title: Text(item['title']),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(isCurrentPlaying && isPlaying
                        ? Icons.pause
                        : Icons.play_arrow),
                    onPressed: () => playAudio(audioUrl),
                  ),
                  IconButton(
                    icon: Icon(Icons.stop),
                    onPressed: stopAudio,
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => deleteMusic(index),
                  ),
                ],
              ),
              subtitle: isCurrentPlaying
                  ? Column(
                children: [
                  Slider(
                    value: currentPosition.inSeconds.toDouble(),
                    max: totalDuration.inSeconds.toDouble(),
                    onChanged: (value) {
                      seekAudio(Duration(seconds: value.toInt()));
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${currentPosition.inMinutes}:${currentPosition.inSeconds.remainder(60).toString().padLeft(2, '0')}",
                      ),
                      Text(
                        "${totalDuration.inMinutes}:${totalDuration.inSeconds.remainder(60).toString().padLeft(2, '0')}",
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.replay_10),
                        onPressed: rewindAudio,
                      ),
                      IconButton(
                        icon: Icon(Icons.forward_10),
                        onPressed: fastForwardAudio,
                      ),
                    ],
                  )
                ],
              )
                  : null,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }
}