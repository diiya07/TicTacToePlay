import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tictactoe/core/constants/app_colors.dart';
import 'package:tictactoe/core/constants/app_text_styles.dart';

class NeonBackButton extends StatefulWidget {
  const NeonBackButton({
    super.key,
    this.color = AppColors.neonPurple,
    this.onPressed,
    this.icon = Icons.arrow_back_ios_new_rounded,
    this.label = 'BACK',
  });

  final Color color;
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;

  @override
  State<NeonBackButton> createState() => _NeonBackButtonState();
}

class _NeonBackButtonState extends State<NeonBackButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final isWide = width >= 600;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          if (widget.onPressed != null) {
            widget.onPressed!();
          } else {
            context.pop();
          }
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.94 : (_isHovered ? 1.05 : 1.0),
          duration: const Duration(milliseconds: 150),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 14 : 10,
              vertical: isWide ? 6 : 10,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: _isHovered ? 0.4 : 0.2),
              borderRadius: BorderRadius.circular(isWide ? 12 : 24),
              border: Border.all(
                color: widget.color.withValues(alpha: _isHovered ? 0.9 : 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: _isHovered ? 0.25 : 0.08),
                  blurRadius: _isHovered ? 12 : 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: isWide ? 13 : 15,
                  color: widget.color,
                ),
                if (isWide) ...[
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: widget.color,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
