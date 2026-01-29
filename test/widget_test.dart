// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camera/camera.dart';

import 'package:cataract/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Mock cameras list
    final List<CameraDescription> mockCameras = [];

    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(cameras: mockCameras, modelLoaded: true));

    // Verify that the app builds without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('App builds with model not loaded', (WidgetTester tester) async {
    // Mock cameras list
    final List<CameraDescription> mockCameras = [];

    // Build our app with model not loaded and trigger a frame.
    await tester.pumpWidget(MyApp(cameras: mockCameras, modelLoaded: false));

    // Verify that the app still builds without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('HomeScreen displays model status indicator', (
    WidgetTester tester,
  ) async {
    // Mock cameras list
    final List<CameraDescription> mockCameras = [];

    // Build our app with model loaded
    await tester.pumpWidget(MyApp(cameras: mockCameras, modelLoaded: true));

    // Verify that the model status indicator is present
    expect(find.text('Model AI Siap'), findsOneWidget);
  });

  testWidgets('HomeScreen shows warning when model not loaded', (
    WidgetTester tester,
  ) async {
    // Mock cameras list
    final List<CameraDescription> mockCameras = [];

    // Build our app with model not loaded
    await tester.pumpWidget(MyApp(cameras: mockCameras, modelLoaded: false));

    // Verify that the model warning indicator is present
    expect(find.text('Model AI Belum Siap'), findsOneWidget);
  });
}
