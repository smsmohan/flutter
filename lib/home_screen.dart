import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'main.dart';

class HomeScreen extends StatefulWidget {
  final User user;

  const HomeScreen({required this.user});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  late String? _imageURL;

  @override
  void initState() {
    super.initState();
    _loadImageURL();
  }

  void _loadImageURL() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(widget.user.uid)
          .get();

      setState(() {
        _imageURL = snapshot.data()?['imageURL'];
      });
    } catch (e) {
      print('Error loading image URL: $e');
    }
  }

  void _pickImage() async {
    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      final File imageFile = File(pickedImage.path);

      try {
        final uploadTask = _storage
            .ref('profile_images/${widget.user.uid}')
            .putFile(imageFile);

        final snapshot = await uploadTask.whenComplete(() {});

        if (snapshot.state == TaskState.success) {
          final imageURL = await snapshot.ref.getDownloadURL();
          await _firestore
              .collection('users')
              .doc(widget.user.uid)
              .set({'imageURL': imageURL});
          setState(() {
            _imageURL = imageURL;
          });
        }
      } catch (e) {
        print('Error uploading image: $e');
      }
    }
  }

  void _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AuthWrapper()),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: _imageURL != null ? NetworkImage(_imageURL!) : null,
              child: _imageURL == null ? Icon(Icons.person) : null,
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Edit'),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () => _signOut(context),
              child: Text('Log Out'),
            ),
          ],
        ),
      ),
    );
  }
}