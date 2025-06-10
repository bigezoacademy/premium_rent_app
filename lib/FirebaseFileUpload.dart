import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseFileUpload {
  static Future<void> uploadPdf(
      BuildContext context, String filePath, String selectedMonth) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp();

      // Get a reference to the Firebase Cloud Storage bucket
      final storageRef = FirebaseStorage.instance.ref();

      // Create a reference to the file in Cloud Storage
      final fileRef = storageRef.child('receipts/$selectedMonth/$filePath');

      // Get the file from device storage
      final File file = File(filePath);

      // Upload the file to Cloud Storage
      await fileRef.putFile(file);

      // Get the download URL of the uploaded file
      final downloadURL = await fileRef.getDownloadURL();

      // Show success message or handle next steps
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File uploaded successfully.'),
          backgroundColor: Color.fromARGB(255, 21, 136, 54),
        ),
      );
    } catch (e) {
      // Show error message or handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
