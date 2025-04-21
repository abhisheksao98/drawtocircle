import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ImageProcessor {
  static Future<void> searchOnGoogleWithImage(
    Uint8List imageBytes,
    BuildContext context,
  ) async {
    try {
      // Step 1: Upload image to temporary online storage
      final tempUrl = await _uploadImageToTempStorage(imageBytes);

      // Step 2: Launch Google Search with image URL
      final googleSearchUrl =
          "https://www.google.com/searchbyimage?image_url=$tempUrl";

      if (await canLaunchUrl(Uri.parse(googleSearchUrl))) {
        await launchUrl(
          Uri.parse(googleSearchUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Fallback: Use standard share dialog
        await _shareImage(imageBytes, context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      await _shareImage(imageBytes, context); // Fallback
    }
  }

  static Future<String> _uploadImageToTempStorage(Uint8List imageBytes) async {
    // In a real app, you'd upload to your server or use Firebase Storage
    // For demo purposes, we'll save locally and use a mock URL
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/search_image_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(imageBytes);

    // Note: For production, replace with actual image upload logic
    return "https://your-server.com/temp/${file.path.split('/').last}";
  }

  static Future<void> _shareImage(
    Uint8List imageBytes,
    BuildContext context,
  ) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/search_image.png');
    await file.writeAsBytes(imageBytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Search this image on Google',
      sharePositionOrigin: Rect.fromLTWH(
        0,
        0,
        MediaQuery.of(context).size.width,
        MediaQuery.of(context).size.height / 2,
      ),
    );
  }
}
