import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dart:math' as math;

class BotanicalBackground extends StatefulWidget {
  final Widget child;
  const BotanicalBackground({super.key, required this.child});

  @override
  State<BotanicalBackground> createState() => _BotanicalBackgroundState();
}

class _BotanicalBackgroundState extends State<BotanicalBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        Positioned.fill(child: Container(color: theme.scaffoldBackgroundColor)),
        // Animated Leaves
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              children: List.generate(5, (index) {
                final angle = _controller.value * 2 * math.pi + (index * 1.2);
                return Positioned(
                  top: 100 + (index * 150) + math.sin(angle) * 30,
                  left: (index % 2 == 0 ? -50 : null),
                  right: (index % 2 != 0 ? -50 : null),
                  child: Transform.rotate(
                    angle: math.sin(angle) * 0.2,
                    child: Opacity(
                      opacity: isDark ? 0.12 : 0.08,
                      child: Icon(
                        Icons.grass, 
                        size: 200, 
                        color: isDark ? AppTheme.sageGreen : theme.colorScheme.primary.withOpacity(0.2)
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
        widget.child,
      ],
    );
  }
}
