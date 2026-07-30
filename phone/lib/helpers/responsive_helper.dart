import 'package:flutter/material.dart';

/// Breakpoint-aware values for building adaptive layouts.
class ResponsiveHelper {
  ResponsiveHelper._();

  /// Screen width breakpoints.
  static bool isSmallPhone(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 360;
  static bool isPhone(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 360 &&
      MediaQuery.sizeOf(context).width < 600;
  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 600 &&
      MediaQuery.sizeOf(context).width < 840;
  static bool isLarge(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 840;

  /// Max width for the main content area (prevents stretched content on large screens).
  static double maxContentWidth(BuildContext context) =>
      isTablet(context) || isLarge(context) ? 720 : double.infinity;

  /// Horizontal padding — wider on tablets.
  static double horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 840) return 64;
    if (width >= 600) return 32;
    return 16;
  }

  /// Vertical padding.
  static double verticalPadding(BuildContext context) {
    if (isTablet(context) || isLarge(context)) return 28;
    return 16;
  }

  /// Spacing between children.
  static double spacing(BuildContext context) {
    if (isLarge(context)) return 24;
    if (isTablet(context)) return 20;
    return 16;
  }

  /// Whether to use multi-column grid.
  static bool useGrid(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 600;

  /// Grid column count.
  static int gridColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1200) return 4;
    if (width >= 840) return 3;
    if (width >= 600) return 2;
    return 1;
  }

  /// Whether to show [NavigationRail] instead of [NavigationBar].
  static bool useSideNav(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 600;
}
