import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🎨 Generating Vynco logo...');
  
  // Generate different sizes
  final sizes = [
    {'name': 'vynco_logo', 'size': 1024},
    {'name': 'vynco_logo_512', 'size': 512},
    {'name': 'vynco_logo_256', 'size': 256},
    {'name': 'vynco_logo_192', 'size': 192},
    {'name': 'vynco_logo_144', 'size': 144},
    {'name': 'vynco_logo_96', 'size': 96},
    {'name': 'vynco_logo_72', 'size': 72},
    {'name': 'vynco_logo_48', 'size': 48},
  ];
  
  for (final config in sizes) {
    final size = config['size'] as int;
    final name = config['name'] as String;
    
    final image = await _generateVyncoLogo(size);
    final file = File('assets/icons/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(image);
    
    print('✅ Generated: $name.png (${size}x$size)');
  }
  
  print('🎉 All logos generated successfully!');
}

Future<Uint8List> _generateVyncoLogo(int size) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint();
  
  final centerX = size / 2;
  final centerY = size / 2;
  final logoSize = size * 0.6;
  
  // Draw background (transparent)
  canvas.drawRect(
    Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    Paint()..color = Colors.transparent,
  );
  
  // Draw the "V" shape with gradient - more volumetric
  final vPath = Path();
  final vWidth = logoSize * 0.55;
  final vHeight = logoSize * 0.75;
  final vTopY = centerY - vHeight / 2;
  final vBottomY = centerY + vHeight / 2;
  final vLeftX = centerX - vWidth / 2;
  final vRightX = centerX + vWidth / 2;
  
  // Create a more pronounced V shape
  vPath.moveTo(vLeftX, vTopY);
  vPath.quadraticBezierTo(
    vLeftX + vWidth * 0.1,
    vTopY + vHeight * 0.2,
    centerX - vWidth * 0.12,
    vBottomY,
  );
  vPath.lineTo(centerX, vBottomY - vHeight * 0.08);
  vPath.lineTo(centerX + vWidth * 0.12, vBottomY);
  vPath.quadraticBezierTo(
    vRightX - vWidth * 0.1,
    vTopY + vHeight * 0.2,
    vRightX,
    vTopY,
  );
  vPath.close();
  
  // Create vibrant gradient for V (blue to purple)
  final gradient = ui.Gradient.linear(
    Offset(vLeftX, vTopY),
    Offset(vRightX, vTopY),
    [
      const Color(0xFF3B82F6), // Bright Blue
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFA855F7), // Bright Purple
    ],
  );
  
  paint
    ..shader = gradient
    ..style = PaintingStyle.fill;
  
  // Draw shadow first for depth
  final shadowPath = Path();
  shadowPath.addPath(vPath, const Offset(2, 3));
  final shadowPaint = Paint()
    ..color = Colors.black.withOpacity(0.3)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  canvas.drawPath(shadowPath, shadowPaint);
  
  // Draw main V shape
  canvas.drawPath(vPath, paint);
  
  // Add highlight for 3D effect
  final highlightPath = Path();
  highlightPath.moveTo(vLeftX + vWidth * 0.1, vTopY + vHeight * 0.1);
  highlightPath.quadraticBezierTo(
    vLeftX + vWidth * 0.15,
    vTopY + vHeight * 0.3,
    centerX - vWidth * 0.05,
    vBottomY - vHeight * 0.15,
  );
  highlightPath.lineTo(centerX, vBottomY - vHeight * 0.2);
  highlightPath.lineTo(centerX + vWidth * 0.05, vBottomY - vHeight * 0.15);
  highlightPath.quadraticBezierTo(
    vRightX - vWidth * 0.15,
    vTopY + vHeight * 0.3,
    vRightX - vWidth * 0.1,
    vTopY + vHeight * 0.1,
  );
  highlightPath.close();
  
  final highlightGradient = ui.Gradient.linear(
    Offset(vLeftX, vTopY),
    Offset(vRightX, vTopY),
    [
      Colors.white.withOpacity(0.4),
      Colors.white.withOpacity(0.1),
      Colors.transparent,
    ],
  );
  
  final highlightPaint = Paint()
    ..shader = highlightGradient
    ..style = PaintingStyle.fill;
  
  canvas.drawPath(highlightPath, highlightPaint);
  
  // Draw corner brackets
  final bracketSize = logoSize * 0.18;
  final bracketThickness = size * 0.03;
  
  // Top-left bracket (bright blue)
  final leftBracketPaint = Paint()
    ..color = const Color(0xFF60A5FA) // Lighter blue
    ..style = PaintingStyle.stroke
    ..strokeWidth = bracketThickness
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  
  final leftBracketX = vLeftX - bracketSize * 0.4;
  final leftBracketY = vTopY - bracketSize * 0.4;
  
  // L-shaped bracket (horizontal then vertical)
  canvas.drawLine(
    Offset(leftBracketX, leftBracketY),
    Offset(leftBracketX + bracketSize, leftBracketY),
    leftBracketPaint,
  );
  canvas.drawLine(
    Offset(leftBracketX, leftBracketY),
    Offset(leftBracketX, leftBracketY + bracketSize),
    leftBracketPaint,
  );
  
  // Top-right bracket (bright purple)
  final rightBracketPaint = Paint()
    ..color = const Color(0xFFA855F7) // Bright purple
    ..style = PaintingStyle.stroke
    ..strokeWidth = bracketThickness
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  
  final rightBracketX = vRightX + bracketSize * 0.4;
  final rightBracketY = vTopY - bracketSize * 0.4;
  
  // L-shaped bracket (mirrored - horizontal then vertical)
  canvas.drawLine(
    Offset(rightBracketX, rightBracketY),
    Offset(rightBracketX - bracketSize, rightBracketY),
    rightBracketPaint,
  );
  canvas.drawLine(
    Offset(rightBracketX, rightBracketY),
    Offset(rightBracketX, rightBracketY + bracketSize),
    rightBracketPaint,
  );
  
  // Convert to image
  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  
  return byteData!.buffer.asUint8List();
}

