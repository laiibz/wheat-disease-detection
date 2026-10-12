import 'package:flutter/material.dart';

class LeafOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final darkPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Create a path for the background (the whole screen)
    Path backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Create a leaf-shaped path in the center
    Path leafPath = Path();
    double w = size.width;
    double h = size.height;
    
    // Center of the screen
    double cx = w / 2;
    double cy = h / 2;
    
    // Leaf dimensions
    double leafW = w * 0.4;
    double leafH = h * 0.6;

    // Simple elliptical leaf shape
    leafPath.moveTo(cx, cy - leafH / 2);
    leafPath.quadraticBezierTo(cx + leafW, cy, cx, cy + leafH / 2);
    leafPath.quadraticBezierTo(cx - leafW, cy, cx, cy - leafH / 2);
    leafPath.close();

    // Combine paths to create a "hole" in the background
    Path overlayPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      leafPath,
    );

    canvas.drawPath(overlayPath, darkPaint);
    canvas.drawPath(leafPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
