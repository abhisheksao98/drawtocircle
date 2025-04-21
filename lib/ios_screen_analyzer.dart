import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:drawtosearch/circle_drawer.dart';

class IOSScreenAnalyzer extends StatelessWidget {
  const IOSScreenAnalyzer({super.key});

  // Update the image picker to include camera option
  Future<void> _pickImage(BuildContext context) async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Select Image Source'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, ImageSource.camera),
                child: const Text('Camera'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, ImageSource.gallery),
                child: const Text('Gallery'),
              ),
            ],
          ),
    );

    if (source == null) return;

    final image = await ImagePicker().pickImage(source: source);
    if (image == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CircleDrawer(imagePath: image.path, isOverlay: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Circle to Search (iOS)')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _pickImage(context),
              child: const Text('Select Screenshot'),
            ),
            const SizedBox(height: 20),
            const Text('Select a screenshot to analyze'),
          ],
        ),
      ),
    );
  }
}
