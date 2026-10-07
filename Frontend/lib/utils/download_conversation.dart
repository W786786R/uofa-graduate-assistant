import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';

/*
This is the class that contains the download utils of the app.
It is used to download the conversation as a text file.
*/
class DownloadUtils {
  /*
  This is the method that is called to request the permission to the user to manage the external storage.
  If the permission is not granted, the user is asked to grant the permission each time the user wants to download a conversation.
  If the permission is granted, the conversation is downloaded to the external storage.
  */
  static Future<void> requestPermission() async {
    var status = await Permission.manageExternalStorage.status;
    if (!status.isGranted) {
      status = await Permission.manageExternalStorage.request();
      if (!status.isGranted) {
        throw Exception("Storage permission denied");
      }
    }
  }

  /*
  This is the method that is called to download the conversation as a text file.
  It calls the API service to get the conversation text.
  It then saves the conversation text to the external storage.
  */
  static Future<void> downloadConversation({
    required BuildContext context,
    required int conversationId,
    required String title,
  }) async {
    try {
      await requestPermission(); // Request permission to manage external storage

      final text = await ApiService.getConversationText(conversationId); // Get the conversation text

      // Use raw Android Download directory
      final downloadsPath = "/storage/emulated/0/Download";
      final file = File('$downloadsPath/$title.txt');

      await file.writeAsString(text);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Saved to Downloads: $downloadsPath/$title.txt")),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Download failed: $e")),
      );
    }
  }
}
