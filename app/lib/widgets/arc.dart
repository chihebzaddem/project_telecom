import 'package:flutter/material.dart';
import 'dart:math';

class AzimuthArc extends StatelessWidget {
  final double size;
  final Color color;

  const AzimuthArc({
    super.key,
    this.size = 40,
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ArcPainter(color),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final Color color;

  _ArcPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color.withAlpha((255 * 0.5).toInt())
      ..style = PaintingStyle.fill;

    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawArc(
      rect,
      -30 * pi / 180, // Start at -15° to center around 0°
       60 * pi / 180,  // Sweep 30°
      true,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
