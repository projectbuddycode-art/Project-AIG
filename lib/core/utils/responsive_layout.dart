import 'package:flutter/material.dart';

class ResponsiveLayout {
  const ResponsiveLayout._();

  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600;
  }

  static EdgeInsets screenPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1024) {
      return const EdgeInsets.symmetric(horizontal: 48, vertical: 24);
    }
    if (width >= 600) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 20);
    }
    return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
  }
}
