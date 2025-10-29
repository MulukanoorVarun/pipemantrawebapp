import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

class ImageUtils {
  static Future<File?> compressImage(File file) async {
    try {
      // Print original image size
      int originalSizeInKB = await file.length() ~/ 1024;
      print("Original image size: $originalSizeInKB KB");

      // Define the output file path (temporary directory)
      final String targetPath = '${file.path}_compressed.jpg';

      int quality = 85;

      XFile? compressedXFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path, // Input file path
        targetPath, // Output file path
        quality: quality, // Initial quality (0-100)
        minHeight: 800, // Optional: Set minimum height
        minWidth: 800, // Optional: Set minimum width
      );

      if (compressedXFile == null) return null;

      // Check file size and adjust quality if necessary
      File compressedFile = File(compressedXFile.path);
      int fileSizeInKB = await compressedFile.length() ~/ 1024;

      // If still larger than 500KB, reduce quality further
      while (fileSizeInKB > 500 && quality > 10) {
        quality -= 10; // Reduce quality incrementally
        final XFile? reCompressedXFile =
            await FlutterImageCompress.compressAndGetFile(
              file.absolute.path,
              targetPath,
              quality: quality,
              minHeight: 800,
              minWidth: 800,
            );
        if (reCompressedXFile == null) return null;
        compressedFile = File(reCompressedXFile.path);
        fileSizeInKB = await compressedFile.length() ~/ 1024;
      }

      // Print the final image size
      print("Final compressed image size: $fileSizeInKB KB");

      return compressedFile;
    } catch (e) {
      print("Error compressing image: $e");
      return null;
    }
  }
}

class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();
  static Future<File?> pickImage(
    BuildContext context, {
    Color? iconColor,
  }) async {
    return await showModalBottomSheet<File?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.photo_library,
                  color: iconColor ?? Colors.blue,
                ),
                title: const Text("Choose from Gallery"),
                onTap: () async {
                  Navigator.pop(context, await _pickImageFromGallery());
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.camera_alt,
                  color: iconColor ?? Colors.blue,
                ),
                title: const Text("Take a Photo"),
                onTap: () async {
                  Navigator.pop(context, await _pickImageFromCamera());
                },
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<File?> _pickImageFromGallery() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      return await ImageUtils.compressImage(File(pickedFile.path));
    }
    return null;
  }

  static Future<File?> _pickImageFromCamera() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
    );
    if (pickedFile != null) {
      return await ImageUtils.compressImage(File(pickedFile.path));
    }
    return null;
  }
}
