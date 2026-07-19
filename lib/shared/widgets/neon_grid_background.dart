

import 'package:flutter/material.dart';
import 'package:tictactoe/core/constants/app_colors.dart';

class NeonGridBackground extends StatelessWidget {
  const NeonGridBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GridPainter());
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.borderDefault.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;

    const spacing = 40.0;

    // Vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Corner glow effects
    final glowPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              AppColors.neonPurple.withValues(alpha: 0.15),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(center: Offset.zero, radius: size.width * 0.5),
          );

    canvas.drawCircle(
      Offset(0, size.height * 0.25),
      size.width * 0.5,
      glowPaint,
    );

    final glowPaint2 = Paint()
      ..shader =
          RadialGradient(
            colors: [
              AppColors.neonCyan.withValues(alpha: 0.1),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width, size.height * 0.6),
              radius: size.width * 0.5,
            ),
          );

    canvas.drawCircle(
      Offset(size.width, size.height * 0.6),
      size.width * 0.5,
      glowPaint2,
    );
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}
