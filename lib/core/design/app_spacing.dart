import 'package:flutter/widgets.dart';

class AppSpacing {
  const AppSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;

  static const EdgeInsets screenCompact = EdgeInsets.symmetric(
    horizontal: md,
    vertical: 12,
  );
  static const EdgeInsets screenRegular = EdgeInsets.symmetric(
    horizontal: xl,
    vertical: 12,
  );
  static const EdgeInsets screenWide = EdgeInsets.symmetric(
    horizontal: xxl,
    vertical: 16,
  );

  static EdgeInsets screenPaddingForWidth(double width) {
    return width > 980
        ? screenWide
        : width > 680
        ? screenRegular
        : screenCompact;
  }

  static const EdgeInsets cardPadding = EdgeInsets.all(16);
  static const EdgeInsets cardPaddingDense = EdgeInsets.all(12);
  static const EdgeInsets tilePadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 12,
  );
  static const EdgeInsets bannerPadding = EdgeInsets.all(14);
  static const EdgeInsets statTilePadding = EdgeInsets.all(14);
}
