import 'package:flutter/material.dart';
import 'package:tictactoe/core/constants/app_colors.dart';
import 'package:tictactoe/core/constants/app_text_styles.dart';
import 'package:tictactoe/core/utils/progression_service.dart';
import 'package:tictactoe/shared/widgets/neon_back_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
        title: Text('PROFILE', style: AppTextStyles.headlineLarge),
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: ProgressionService(),
        builder: (context, _) {
          final profile = ProgressionService().profile;
          final double screenWidth = MediaQuery.of(context).size.width;
          final isWideScreen = screenWidth >= 600;

          final avatarSection = Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.surface,
                child: Text(
                  '${profile.level}',
                  style: AppTextStyles.displayMedium.copyWith(color: AppColors.neonPurple),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'TIER: ${profile.tier.name.toUpperCase()}',
                style: AppTextStyles.tierBadge.copyWith(color: AppColors.xpAccent),
              ),
            ],
          );

          final statsSection = Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.borderDefault,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StatRow(label: 'Level', value: '${profile.level}'),
                    _StatRow(label: 'XP', value: '${profile.xp}'),
                    _StatRow(label: 'Coins', value: '${profile.coins}'),
                  ],
                ),
              ),
            ),
          );

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: isWideScreen
                ? Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: avatarSection),
                          const SizedBox(width: 32),
                          Expanded(child: statsSection),
                        ],
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      avatarSection,
                      const SizedBox(height: 48),
                      statsSection,
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyLarge),
          Text(value, style: AppTextStyles.headlineMedium.copyWith(color: AppColors.neonCyan)),
        ],
      ),
    );
  }
}
