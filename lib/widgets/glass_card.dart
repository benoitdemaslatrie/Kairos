import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final bool showCyanBorder;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 16,
    this.showCyanBorder = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border(
                top: BorderSide(
                  color: showCyanBorder
                      ? KairosColors.cyan.withOpacity(0.8)
                      : Colors.white.withOpacity(0.25),
                  width: showCyanBorder ? 2 : 1,
                ),
                left: BorderSide(color: Colors.white.withOpacity(0.25), width: 1),
                right: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
                bottom: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
              ),
              boxShadow: showCyanBorder
                  ? [
                      BoxShadow(
                        color: KairosColors.cyan.withOpacity(0.15),
                        blurRadius: 20,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
