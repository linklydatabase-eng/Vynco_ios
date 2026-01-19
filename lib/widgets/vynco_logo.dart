import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class VyncoLogo extends StatelessWidget {
  final double size;
  final bool showBrackets;

  const VyncoLogo({
    super.key,
    this.size = 60,
    this.showBrackets = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _VyncoLogoPainter(showBrackets: showBrackets),
    );
  }
}

class _VyncoLogoPainter extends CustomPainter {
  final bool showBrackets;

  _VyncoLogoPainter({this.showBrackets = true});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final logoSize = size.width * 0.65;

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

    final vPaint = Paint()
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
    canvas.drawPath(vPath, vPaint);

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

    // Draw corner brackets if enabled
    if (showBrackets) {
      final bracketSize = logoSize * 0.18;
      final bracketThickness = size.width * 0.03;

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
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

