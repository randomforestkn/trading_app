import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppElevation {
  const AppElevation._();

  static List<BoxShadow> get soft => const [
    BoxShadow(color: AppColors.shadow, blurRadius: 20, offset: Offset(0, 8)),
  ];

  static List<BoxShadow> get subtle => const [
    BoxShadow(color: Color(0x66000000), blurRadius: 14, offset: Offset(0, 6)),
  ];
}
