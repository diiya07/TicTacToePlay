import 'package:flutter/material.dart';
import 'package:tictactoe/core/constants/app_colors.dart';
import 'package:tictactoe/core/constants/app_text_styles.dart';
import 'package:tictactoe/core/utils/daily_challenge_service.dart';
import 'package:tictactoe/shared/widgets/neon_back_button.dart';

class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DailyChallengeService().fetchDailyChallenge();
    });
  }

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
        title: Text('DAILY CHALLENGE', style: AppTextStyles.headlineLarge),
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: DailyChallengeService(),
        builder: (context, _) {
          final service = DailyChallengeService();
          if (service.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final challenge = service.currentChallenge;
          if (challenge == null) {
            return Center(
              child: Text(
                'No challenge available today.',
                style: AppTextStyles.bodyLarge,
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Variant: ${challenge.variant.name.toUpperCase()}',
                  style: AppTextStyles.headlineMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Reward: ${challenge.rewardCoins} Coins, ${challenge.rewardXp} XP',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    // Play challenge logic
                  },
                  child: const Text('PLAY NOW'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
