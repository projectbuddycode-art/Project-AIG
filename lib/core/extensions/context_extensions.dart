import 'package:flutter/material.dart';

extension ContextExtensions on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  double get screenHeight => MediaQuery.sizeOf(this).height;

  bool get isTablet => screenWidth >= 600;

  EdgeInsets horizontalEdgeInsets([double factor = 0.05]) {
    return EdgeInsets.symmetric(horizontal: screenWidth * factor);
  }
}
