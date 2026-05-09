import 'package:flutter/material.dart';

import '../design/app_colors.dart';

class MiniTrendChart extends StatelessWidget {
  const MiniTrendChart({
    required this.points,
    required this.isPositive,
    this.width = 64,
    this.height = 36,
    super.key,
  });

  final List<double> points;
  final bool isPositive;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _MiniTrendPainter(
          points: points,
          color: isPositive ? AppColors.primary : AppColors.danger,
        ),
      ),
    );
  }
}

class _MiniTrendPainter extends CustomPainter {
  const _MiniTrendPainter({required this.points, required this.color});

  final List<double> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) {
      return;
    }

    final minValue = points.reduce((a, b) => a < b ? a : b);
    final maxValue = points.reduce((a, b) => a > b ? a : b);
    final range = (maxValue == minValue ? 1 : maxValue - minValue).toDouble();
    final path = _smoothPath(size, minValue, range);

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniTrendPainter oldDelegate) {
    return points != oldDelegate.points || color != oldDelegate.color;
  }

  Path _smoothPath(Size size, double minValue, double range) {
    final path = Path();
    final pointsList = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final x = size.width * i / (points.length - 1);
      final y = size.height - (((points[i] - minValue) / range) * size.height);
      pointsList.add(Offset(x, y));
    }

    if (pointsList.isEmpty) {
      return path;
    }

    path.moveTo(pointsList.first.dx, pointsList.first.dy);
    for (var i = 0; i < pointsList.length - 1; i++) {
      final current = pointsList[i];
      final next = pointsList[i + 1];
      final controlPoint = Offset((current.dx + next.dx) / 2, current.dy);
      final endPoint = Offset((current.dx + next.dx) / 2, next.dy);
      path.quadraticBezierTo(
        controlPoint.dx,
        controlPoint.dy,
        endPoint.dx,
        endPoint.dy,
      );
    }
    path.lineTo(pointsList.last.dx, pointsList.last.dy);
    return path;
  }
}
