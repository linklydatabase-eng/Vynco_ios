import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Generate app icons with the Vynco logo design
  await generateAppIcons();
}

Future<void> generateAppIcons() async {
  print('🎨 Generating Vynco app icons...');
  
  // Define icon sizes for different platforms
  final iconSizes = [
    {'name': 'android-48', 'size': 48},
    {'name': 'android-72', 'size': 72},
    {'name': 'android-96', 'size': 96},
    {'name': 'android-144', 'size': 144},
    {'name': 'android-192', 'size': 192},
    {'name': 'web-192', 'size': 192},
    {'name': 'web-512', 'size': 512},
    {'name': 'ios-1024', 'size': 1024},
  ];
  
  for (final iconConfig in iconSizes) {
    final name = iconConfig['name'] as String;
    final size = iconConfig['size'] as int;
    
    print('📱 Generating $name (${size}x$size)...');
    
    final image = await _generateVyncoIcon(size);
    
    // Save the icon
    final directory = Directory('assets/icons/generated');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    
    final file = File('${directory.path}/$name.png');
    await file.writeAsBytes(image);
    
    print('✅ Generated ${file.path}');
  }
  
  print('🎉 All icons generated successfully!');
  print('📝 Next steps:');
  print('   1. Copy the generated icons to their respective platform directories');
  print('   2. Update pubspec.yaml to include the new icons');
  print('   3. Run flutter pub get and rebuild your app');
}

Future<Uint8List> _generateVyncoIcon(int size) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  
  // Background - white rounded rectangle (like splash screen)
  final backgroundPaint = Paint()
    ..color = const Color(0xFF0175C2) // AppColors.primary equivalent
    ..style = PaintingStyle.fill;
  
  final borderRadius = size * 0.15; // 15% of size for rounded corners
  final rect = RRect.fromRectAndRadius(
    Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    Radius.circular(borderRadius),
  );
  
  canvas.drawRRect(rect, backgroundPaint);
  
  // Draw the link icon in white
  final iconSize = size * 0.5; // 50% of the icon size
  final iconPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;
  
  // Draw a simplified link icon
  final centerX = size / 2;
  final centerY = size / 2;
  
  // Draw two overlapping circles to represent a link
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
  
  // Connect the circles with lines
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
