import 'package:flutter/material.dart';
import 'package:tictactoe/core/constants/app_colors.dart';
import 'package:tictactoe/core/constants/app_text_styles.dart';
import 'package:tictactoe/shared/widgets/neon_back_button.dart';

class ReplayScreen extends StatelessWidget {
  const ReplayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: isWide ? 110 : 56,
        leading: Padding(
          padding: EdgeInsets.only(
            left: isWide ? 16.0 : 8.0,
            top: isWide ? 10.0 : 6.0,
            bottom: isWide ? 10.0 : 6.0,
          ),
          child: const NeonBackButton(),
        ),
        title: Text('MATCH REPLAY', style: AppTextStyles.headlineLarge),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          'Replay feature coming soon.',
          style: AppTextStyles.bodyLarge,
        ),
      ),
    );
  }
}
