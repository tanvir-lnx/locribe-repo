import 'package:flutter/material.dart';
import 'mac_desktop_layout.dart';
import 'mobile_layout.dart';

class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // If width is greater than 800, we treat it as a Desktop/Mac screen
        if (constraints.maxWidth > 800) {
          return const MacDesktopLayout();
        } else {
          // Otherwise, show the mobile layout
          return const MobileLayout();
        }
      },
    );
  }
}