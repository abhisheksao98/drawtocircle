import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:drawtosearch/circle_drawer.dart';
import 'package:permission_handler/permission_handler.dart';

class AndroidOverlayScreen extends StatefulWidget {
  const AndroidOverlayScreen({super.key});

  @override
  State<AndroidOverlayScreen> createState() => _AndroidOverlayScreenState();
}

class _AndroidOverlayScreenState extends State<AndroidOverlayScreen> {
  bool _overlayActive = false;

  Future<void> _toggleOverlay() async {
    // 1. Check and request overlay permission
    if (!await FlutterOverlayWindow.isPermissionGranted()) {
      await FlutterOverlayWindow.requestPermission();
      if (!await FlutterOverlayWindow.isPermissionGranted()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Overlay permission required')),
        );
        return;
      }
    }

    // 2. Check and request other necessary permissions
    await [
      Permission.systemAlertWindow,
      Permission.camera,
      Permission.storage,
    ].request();

    // 3. Toggle overlay state
    if (!_overlayActive) {
      try {
        await FlutterOverlayWindow.showOverlay(
          enableDrag: true,
          overlayTitle: "Circle to Search",
          overlayContent: "Draw a circle to search anything",
          flag: OverlayFlag.defaultFlag,
          visibility: NotificationVisibility.visibilityPublic,
          height: 60,
          width: 60,
        );

        // Listen for overlay events
        FlutterOverlayWindow.overlayListener.listen((event) {
          debugPrint("Overlay event: $event");
          if (event == "close") {
            setState(() => _overlayActive = false);
          }
        });
      } catch (e) {
        debugPrint("Overlay error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to show overlay: ${e.toString()}")),
        );
        return;
      }
    } else {
      await FlutterOverlayWindow.closeOverlay();
    }

    setState(() => _overlayActive = !_overlayActive);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Circle to Search (Android)')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _toggleOverlay,
              child: Text(
                _overlayActive ? 'Disable Overlay' : 'Enable Overlay',
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _overlayActive
                  ? 'Overlay is active. Long press the overlay icon to draw.'
                  : 'Enable overlay to start',
            ),
          ],
        ),
      ),
    );
  }
}

class OverlayCircleSearch extends StatefulWidget {
  const OverlayCircleSearch({super.key});

  @override
  State<OverlayCircleSearch> createState() => _OverlayCircleSearchState();
}

class _OverlayCircleSearchState extends State<OverlayCircleSearch> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Listener(
        onPointerDown: (event) {
          setState(() => _isPressed = true);
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              setState(() => _isPressed = false);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CircleDrawer(isOverlay: true),
                  fullscreenDialog: true,
                ),
              );
            }
          });
        },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 100),
          opacity: _isPressed ? 0.7 : 1.0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.search, size: 40, color: Colors.blue),
            ),
          ),
        ),
      ),
    );
  }
}
