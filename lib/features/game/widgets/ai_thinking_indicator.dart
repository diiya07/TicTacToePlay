import 'package:flutter/material.dart';
import 'package:tictactoe/core/constants/app_colors.dart';

/// Three pulsing dots that appear when the AI is computing its move.
class AIThinkingIndicator extends StatefulWidget {
  final bool visible;

  const AIThinkingIndicator({super.key, required this.visible});

  @override
  State<AIThinkingIndicator> createState() => _AIThinkingIndicatorState();
}

class _AIThinkingIndicatorState extends State<AIThinkingIndicator>
    with TickerProviderStateMixin {
  final List<AnimationController> _controllers = [];
  final List<Animation<double>> _animations = [];

  static const int _dotCount = 3;
  static const Duration _dotDuration = Duration(milliseconds: 500);
  static const Duration _dotStagger = Duration(milliseconds: 150);

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _dotCount; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: _dotDuration,
      );
      final animation = Tween<double>(
        begin: 0.3,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
      _controllers.add(controller);
      _animations.add(animation);
    }
    _startAnimations();
  }

  void _startAnimations() async {
    for (int i = 0; i < _dotCount; i++) {
      await Future.delayed(_dotStagger);
      if (!mounted) return;
      _controllers[i].repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: widget.visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(_dotCount, (i) {
          return AnimatedBuilder(
            animation: _animations[i],
            builder: (context, _) {
              return Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.playerO.withValues(
                    alpha: _animations[i].value,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.playerO.withValues(
                        alpha: _animations[i].value * 0.6,
                      ),
                      blurRadius: 6,
                    ),
                  ],
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
