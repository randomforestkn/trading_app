import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

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
          color: isPositive ? AppTheme.primary : AppTheme.danger,
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
    final range = maxValue == minValue ? 1 : maxValue - minValue;
    final path = Path();

    for (var i = 0; i < points.length; i++) {
      final x = size.width * i / (points.length - 1);
      final y = size.height - ((points[i] - minValue) / range * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

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
}
