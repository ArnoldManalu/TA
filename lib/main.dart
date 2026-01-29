import 'dart:io' show Platform;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'screens/home_screen.dart';
import 'helper/model_helper.dart';
import 'theme/app_theme.dart';

void main() {
  // Pastikan binding, load model, dan runApp berjalan di zona yang sama untuk hindari peringatan Zone mismatch.
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    debugPrint('🚀 Starting Cataract Detection App...');

    // Load TFLite model
    bool modelLoaded = false;
    try {
      debugPrint('📦 Loading AI model...');
      await ModelHelper.loadModel();
      modelLoaded = ModelHelper.isLoaded;
      debugPrint('✅ Model loaded successfully');
    } catch (e) {
      debugPrint('❌ Model loading failed: $e');
      modelLoaded = false;
    }

    // Dapatkan daftar kamera
    List<CameraDescription> cameras = const [];
    try {
      debugPrint('📷 Getting available cameras...');
      if (Platform.isAndroid || Platform.isIOS) {
        cameras = await availableCameras();
        debugPrint('✅ Cameras obtained: ${cameras.length}');
      } else {
        debugPrint('⚠️ Camera not supported on this platform');
      }
    } catch (e) {
      debugPrint('⚠️ Camera error: $e');
      cameras = const [];
    }

    runApp(MyApp(cameras: cameras, modelLoaded: modelLoaded));
  }, (error, stackTrace) {
    debugPrint('💥 Global error caught: $error');
  });
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  final bool modelLoaded;

  const MyApp({super.key, required this.cameras, required this.modelLoaded});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Deteksi Katarak',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: HomeScreen(cameras: cameras, modelLoaded: modelLoaded),
    );
  }
}
