import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

class ChangeText extends StatelessWidget {
  const ChangeText(this.value, {this.compact = false, super.key});

  final double value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final positive = value >= 0;
    final color = positive ? AppTheme.primary : AppTheme.danger;
    final prefix = positive ? '+' : '';

    return Text(
      '$prefix${value.toStringAsFixed(2)}%',
      style: TextStyle(
        color: color,
        fontSize: compact ? 13 : 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
