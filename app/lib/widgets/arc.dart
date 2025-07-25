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
      ..color = color.withAlpha((255 * 0.5).toInt())  // 50% opacity
      ..style = PaintingStyle.fill;

    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Draw arc from -30° to +30° (60° sweep)
    canvas.drawArc(
      rect,
      -30 * pi / 180,  // start angle in radians
      60 * pi / 180,   // sweep angle in radians
      true,            // use center to fill sector shape
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
