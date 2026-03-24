import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:rackup/core/theme/player_identity.dart';

/// Renders one of the 8 geometric player identity shapes.
class PlayerShapeWidget extends StatelessWidget {
  const PlayerShapeWidget({
    required this.shape,
    required this.color,
    this.size = 24,
    super.key,
  });

  /// The shape to render.
  final PlayerShape shape;

  /// The fill color.
  final Color color;

  /// The size (width and height) of the shape.
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _PlayerShapePainter(shape: shape, color: color),
    );
  }
}

class _PlayerShapePainter extends CustomPainter {
  _PlayerShapePainter({required this.shape, required this.color});

  final PlayerShape shape;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    switch (shape) {
      case PlayerShape.circle:
        canvas.drawCircle(center, radius, paint);
      case PlayerShape.square:
        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
      case PlayerShape.triangle:
        _drawRegularPolygon(canvas, center, radius, 3, paint, rotation: -90);
      case PlayerShape.diamond:
        _drawRegularPolygon(canvas, center, radius, 4, paint, rotation: 0);
      case PlayerShape.star:
        _drawStar(canvas, center, radius, paint);
      case PlayerShape.hexagon:
        _drawRegularPolygon(canvas, center, radius, 6, paint, rotation: 0);
      case PlayerShape.cross:
        _drawCross(canvas, center, radius, paint);
      case PlayerShape.pentagon:
        _drawRegularPolygon(canvas, center, radius, 5, paint, rotation: -90);
    }
  }

  void _drawRegularPolygon(
    Canvas canvas,
    Offset center,
    double radius,
    int sides,
    Paint paint, {
    required double rotation,
  }) {
    final path = Path();
    final angle = 2 * math.pi / sides;
    final rotationRad = rotation * math.pi / 180;

    for (var i = 0; i < sides; i++) {
      final x = center.dx + radius * math.cos(angle * i + rotationRad);
      final y = center.dy + radius * math.sin(angle * i + rotationRad);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    const points = 5;
    final innerRadius = radius * 0.4;
    const rotation = -math.pi / 2;

    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : innerRadius;
      final angle = (math.pi / points) * i + rotation;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawCross(Canvas canvas, Offset center, double radius, Paint paint) {
    final armWidth = radius * 0.6;
    final halfArm = armWidth / 2;

    final path = Path()
      ..moveTo(center.dx - halfArm, center.dy - radius)
      ..lineTo(center.dx + halfArm, center.dy - radius)
      ..lineTo(center.dx + halfArm, center.dy - halfArm)
      ..lineTo(center.dx + radius, center.dy - halfArm)
      ..lineTo(center.dx + radius, center.dy + halfArm)
      ..lineTo(center.dx + halfArm, center.dy + halfArm)
      ..lineTo(center.dx + halfArm, center.dy + radius)
      ..lineTo(center.dx - halfArm, center.dy + radius)
      ..lineTo(center.dx - halfArm, center.dy + halfArm)
      ..lineTo(center.dx - radius, center.dy + halfArm)
      ..lineTo(center.dx - radius, center.dy - halfArm)
      ..lineTo(center.dx - halfArm, center.dy - halfArm)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PlayerShapePainter oldDelegate) =>
      shape != oldDelegate.shape || color != oldDelegate.color;
}
