import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class AppIcon extends StatelessWidget {
  const AppIcon(
    this.icon, {
    super.key,
    this.size = 22,
    this.color,
    this.strokeWidth = 2,
  });

  final List<List<dynamic>> icon;
  final double size;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return HugeIcon(
      icon: icon,
      size: size,
      color: color ?? Theme.of(context).colorScheme.onSurface,
      strokeWidth: strokeWidth,
    );
  }
}
