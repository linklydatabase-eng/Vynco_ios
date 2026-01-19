import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await createVyncoLogo();
}

Future<void> createVyncoLogo() async {
  print('🎨 Creating Vynco logo...');
  
  // Create a 1024x1024 logo (high resolution for all platforms)
  const size = 1024;
  
  final image = await _generateVyncoLogo(size);
  
  // Create assets directory if it doesn't exist
  final assetsDir = Directory('assets/icons');
  if (!await assetsDir.exists()) {
    await assetsDir.create(recursive: true);
  }
  
  // Save the logo
  final file = File('assets/icons/vynco_logo.png');
  await file.writeAsBytes(image);
  
  print('✅ Vynco logo created at: ${file.path}');
  print('📱 Now you can run: flutter pub run flutter_launcher_icons');
}

Future<Uint8List> _generateVyncoLogo(int size) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  
  // Primary blue background (same as splash screen)
  final backgroundPaint = Paint()
    ..color = const Color(0xFF0175C2) // AppColors.primary
    ..style = PaintingStyle.fill;
  
  // Create rounded rectangle background
  final borderRadius = size * 0.15; // 15% rounded corners
  final rect = RRect.fromRectAndRadius(
    Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    Radius.circular(borderRadius),
  );
  
  canvas.drawRRect(rect, backgroundPaint);
  
  // Draw white link icon in the center
  final iconSize = size * 0.5; // 50% of the total size
  final iconPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;
  
  final centerX = size / 2;
  final centerY = size / 2;
  
  // Draw the link icon (two overlapping circles with connecting lines)
  final circleRadius = iconSize * 0.15;
  final linkWidth = iconSize * 0.4;
  
  // Left circle
  canvas.drawCircle(
    Offset(centerX - linkWidth / 2, centerY - circleRadius),
    circleRadius,
    iconPaint,
  );
  
  // Right circle
  canvas.drawCircle(
    Offset(centerX + linkWidth / 2, centerY + circleRadius),
    circleRadius,
    iconPaint,
  );
  
  // Connecting lines
  final linePaint = Paint()
    ..color = Colors.white
    ..strokeWidth = iconSize * 0.08
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  
  // Top connecting line
  canvas.drawLine(
    Offset(centerX - linkWidth / 2 + circleRadius * 0.7, centerY - circleRadius),
    Offset(centerX + linkWidth / 2 - circleRadius * 0.7, centerY + circleRadius),
    linePaint,
  );
  
  // Bottom connecting line
  canvas.drawLine(
    Offset(centerX - linkWidth / 2 + circleRadius * 0.7, centerY - circleRadius),
    Offset(centerX + linkWidth / 2 - circleRadius * 0.7, centerY + circleRadius),
    linePaint,
  );
  
  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  
  return byteData!.buffer.asUint8List();
}
