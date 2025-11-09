import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class FilePermissionScreen extends StatelessWidget {
  const FilePermissionScreen({super.key});

  Future<void> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      // For Android 11 and above (MANAGE_EXTERNAL_STORAGE)
      if (await Permission.manageExternalStorage.isGranted) {
        print("✅ Permission already granted");
      } else {
        final status = await Permission.manageExternalStorage.request();

        if (status.isGranted) {
          print("✅ Permission granted");
        } else if (status.isDenied) {
          print("❌ Permission denied");
        } else if (status.isPermanentlyDenied) {
          // Open app settings
          openAppSettings();
        }
      }
    } else {
      // For iOS or others
      final status = await Permission.storage.request();
      if (status.isGranted) {
        print("✅ iOS storage permission granted");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Storage Permission")),
      body: Center(
        child: ElevatedButton(
          onPressed: _requestStoragePermission,
          child: const Text("Request Storage Permission"),
        ),
      ),
    );
  }
}
