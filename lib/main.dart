import 'package:flutter/material.dart';
import 'package:drawtosearch/android_overlay.dart';
import 'package:drawtosearch/ios_screen_analyzer.dart';
import 'package:device_info_plus/device_info_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Circle to Search',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const PlatformSpecificHome(),
    );
  }
}

class PlatformSpecificHome extends StatelessWidget {
  const PlatformSpecificHome({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: DeviceInfoPlugin().deviceInfo,
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );

        final isAndroid = snapshot.data is AndroidDeviceInfo;
        return isAndroid
            ? const AndroidOverlayScreen()
            : const IOSScreenAnalyzer();
      },
    );
  }
}
