import 'package:flutter/material.dart';

class AppPanelCard extends StatelessWidget {
  const AppPanelCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.backgroundColor = const Color(0x0DFFFFFF),
    this.borderColor = const Color(0x0FFFFFFF),
    this.borderRadius = 24,
    this.gradient,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color backgroundColor;
  final Color borderColor;
  final double borderRadius;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? backgroundColor : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}
