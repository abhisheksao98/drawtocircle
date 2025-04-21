import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:vector_math/vector_math.dart' as vm;
import 'package:drawtosearch/image_processor.dart';

class CircleDrawer extends StatefulWidget {
  final String? imagePath;
  final bool isOverlay;

  const CircleDrawer({super.key, this.imagePath, required this.isOverlay});

  @override
  State<CircleDrawer> createState() => _CircleDrawerState();
}

class _CircleDrawerState extends State<CircleDrawer> {
  List<Offset> _points = [];
  bool _isDrawing = false;
  ui.Image? _backgroundImage;

  @override
  void initState() {
    super.initState();
    if (widget.imagePath != null) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    final bytes = await File(widget.imagePath!).readAsBytes();
    final image = await decodeImageFromList(bytes);
    setState(() => _backgroundImage = image);
  }

  // Modify the _searchImage method
  Future<void> _searchImage() async {
    if (_points.isEmpty) return;

    try {
      final croppedImage = await _cropSelectedArea();
      if (croppedImage == null) return;

      // Replace the share method with Google Search integration
      await ImageProcessor.searchOnGoogleWithImage(croppedImage, context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<Uint8List?> _cropSelectedArea() async {
    // Implementation depends on overlay or screenshot mode
    if (widget.isOverlay) {
      return await _cropOverlayArea();
    } else {
      return await _cropScreenshotArea();
    }
  }

  Future<Uint8List?> _cropOverlayArea() async {
    // Implement overlay screenshot capture
    // This would use platform channels to capture the screen
    return null; // Placeholder
  }

  Future<Uint8List?> _cropScreenshotArea() async {
    if (_backgroundImage == null) return null;

    final byteData = await _backgroundImage!.toByteData(
      format: ui.ImageByteFormat.png,
    );
    final imageBytes = byteData!.buffer.asUint8List();
    final image = img.decodeImage(imageBytes)!;

    // Calculate bounding box
    double minX = _points.map((p) => p.dx).reduce((a, b) => a < b ? a : b);
    double maxX = _points.map((p) => p.dx).reduce((a, b) => a > b ? a : b);
    double minY = _points.map((p) => p.dy).reduce((a, b) => a < b ? a : b);
    double maxY = _points.map((p) => p.dy).reduce((a, b) => a > b ? a : b);

    final cropped = img.copyCrop(
      image,
      minX.toInt(),
      minY.toInt(),
      (maxX - minX).toInt(),
      (maxY - minY).toInt(),
    );

    return Uint8List.fromList(img.encodePng(cropped));
  }

  Future<void> _shareToGoogleLens(Uint8List imageBytes) async {
    final tempDir = await getTemporaryDirectory();
    final file = await File('${tempDir.path}/search_image.png').create();
    await file.writeAsBytes(imageBytes);

    await Share.shareXFiles([XFile(file.path)], text: 'Search this image');
  }

  bool _isCircle(List<Offset> points) {
    if (points.length < 10) return false;
    final vectors = points.map((p) => vm.Vector2(p.dx, p.dy)).toList();
    final centroid =
        vectors.fold(vm.Vector2.zero(), (sum, v) => sum + v) /
        vectors.length.toDouble();
    final avgRadius =
        vectors.map((v) => (v - centroid).length).reduce((a, b) => a + b) /
        vectors.length;
    final threshold = avgRadius * 0.3;

    return vectors.every(
      (v) => ((v - centroid).length - avgRadius).abs() < threshold,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Draw a Circle'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: _searchImage),
        ],
      ),
      body: GestureDetector(
        onPanStart: (details) {
          setState(() {
            _isDrawing = true;
            _points = [details.localPosition];
          });
        },
        onPanUpdate: (details) {
          setState(() => _points.add(details.localPosition));
        },
        onPanEnd: (details) {
          setState(() {
            _isDrawing = false;
            if (_isCircle(_points)) _searchImage();
          });
        },
        child: CustomPaint(
          foregroundPainter: _CirclePainter(_points, _isDrawing),
          size: Size.infinite,
          child:
              widget.imagePath != null && _backgroundImage != null
                  ? RawImage(image: _backgroundImage)
                  : Container(color: Colors.transparent),
        ),
      ),
    );
  }
}

class _CirclePainter extends CustomPainter {
  final List<Offset> points;
  final bool isDrawing;

  _CirclePainter(this.points, this.isDrawing);

  @override
  void paint(Canvas canvas, Size size) {
    if (!isDrawing || points.length < 2) return;

    final paint =
        Paint()
          ..color = Colors.blue.withOpacity(0.5)
          ..strokeWidth = 4.0
          ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
