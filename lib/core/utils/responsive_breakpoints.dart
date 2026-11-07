import 'package:flutter/material.dart';

/// Screen size classification following the multi-platform responsive rules:
/// - Compact (< 600px - Phones)
/// - Medium (600px - 1024px - Tablets / small windows)
/// - Expanded (> 1024px - Desktop browsers)
enum ScreenSizeClass { compact, medium, expanded }

abstract final class ResponsiveBreakpoints {
  static const double compactMaxWidth = 600;
  static const double mediumMaxWidth = 1024;

  static ScreenSizeClass ofWidth(double width) {
    if (width < compactMaxWidth) {
      return ScreenSizeClass.compact;
    } else if (width <= mediumMaxWidth) {
      return ScreenSizeClass.medium;
    } else {
      return ScreenSizeClass.expanded;
    }
  }

  static ScreenSizeClass of(BuildContext context) {
    return ofWidth(MediaQuery.sizeOf(context).width);
  }

  static bool isCompact(BuildContext context) =>
      of(context) == ScreenSizeClass.compact;

  static bool isMedium(BuildContext context) =>
      of(context) == ScreenSizeClass.medium;

  static bool isExpanded(BuildContext context) =>
      of(context) == ScreenSizeClass.expanded;

  static bool usesSideNavigation(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= compactMaxWidth;
}
