import 'package:flutter/material.dart';
import 'package:tictactoe/core/constants/app_colors.dart';
import 'package:tictactoe/core/constants/app_text_styles.dart';
import 'package:tictactoe/core/models/game_models.dart';
import 'package:tictactoe/core/utils/score_service.dart';
import 'package:tictactoe/shared/widgets/neon_back_button.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final ScoreService _scoreService = ScoreService();
  List<ScoreEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await _scoreService.getLeaderboard();
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderActive),
        ),
        title: Text('CLEAR LEADERBOARD?', style: AppTextStyles.headlineLarge),
        content: Text(
          'All records will be permanently deleted.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'CANCEL',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'CLEAR',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.neonPink,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _scoreService.clearLeaderboard();
      await _load();
    }
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
        title: Text('LEADERBOARD', style: AppTextStyles.headlineLarge),
        centerTitle: true,
        actions: [
          if (_entries.isNotEmpty)
            IconButton(
              icon: const Icon(
                Icons.delete_sweep_rounded,
                color: AppColors.neonPink,
              ),
              onPressed: _clearAll,
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.neonPurple),
            )
          : _entries.isEmpty
              ? _EmptyState()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final double width = MediaQuery.of(context).size.width;
                    final bool useTwoColumns = width >= 750;

                    final int totalPlayers = _entries.length;
                    final int totalGames = _entries.fold(0, (sum, entry) => sum + entry.totalGames);
                    final int totalWins = _entries.fold(0, (sum, entry) => sum + entry.wins);
                    final double avgWinRate = totalGames == 0 ? 0.0 : totalWins / totalGames;

                    final summaryWidget = Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 380),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.borderDefault, width: 1.5),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'BOARD SUMMARY',
                                style: AppTextStyles.displaySmall.copyWith(color: AppColors.neonPurple),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              _LeaderboardStatRow(label: 'Total Players', value: '$totalPlayers'),
                              const SizedBox(height: 12),
                              _LeaderboardStatRow(label: 'Total Matches', value: '$totalGames'),
                              const SizedBox(height: 12),
                              _LeaderboardStatRow(label: 'Total Wins', value: '$totalWins'),
                              const SizedBox(height: 12),
                              _LeaderboardStatRow(
                                label: 'Avg Win Rate',
                                value: '${(avgWinRate * 100).toStringAsFixed(0)}%',
                              ),
                            ],
                          ),
                        ),
                      ),
                    );

                    final listWidget = ListView.builder(
                      shrinkWrap: useTwoColumns,
                      physics: useTwoColumns ? const BouncingScrollPhysics() : null,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      itemCount: _entries.length,
                      itemBuilder: (ctx, i) =>
                          _LeaderboardRow(entry: _entries[i], rank: i + 1),
                    );

                    if (useTwoColumns) {
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 960),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 10, child: summaryWidget),
                                const SizedBox(width: 32),
                                Expanded(flex: 12, child: listWidget),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 700),
                        child: listWidget,
                      ),
                    );
                  },
                ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.emoji_events_rounded,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text('NO RECORDS YET', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Play a game to get on the board',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final ScoreEntry entry;
  final int rank;

  const _LeaderboardRow({required this.entry, required this.rank});

  Color get _rankColor {
    switch (rank) {
      case 1:
        return AppColors.neonYellow;
      case 2:
        return const Color(0xFFB0B0B0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final winPct = (entry.winRate * 100).toStringAsFixed(0);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: rank <= 3
              ? _rankColor.withValues(alpha: 0.3)
              : AppColors.borderDefault,
        ),
        boxShadow: rank <= 3
            ? [
                BoxShadow(
                  color: _rankColor.withValues(alpha: 0.08),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 36,
            child: Text(
              rank <= 3 ? _trophy(rank) : '#$rank',
              style: AppTextStyles.displaySmall.copyWith(
                color: _rankColor,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),

          // Name & win rate
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.playerName, style: AppTextStyles.headlineLarge),
                const SizedBox(height: 4),
                Text(
                  '${entry.totalGames} games · $winPct% win rate',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),

          // W / L / D
          Row(
            children: [
              _StatPill(
                value: entry.wins,
                label: 'W',
                color: AppColors.neonGreen,
              ),
              const SizedBox(width: 6),
              _StatPill(
                value: entry.losses,
                label: 'L',
                color: AppColors.neonPink,
              ),
              const SizedBox(width: 6),
              _StatPill(
                value: entry.draws,
                label: 'D',
                color: AppColors.textMuted,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _trophy(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '#$rank';
    }
  }
}

class _StatPill extends StatelessWidget {
  final int value;
  final String label;
  final Color color;

  const _StatPill({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Compact format prevents overflow for large numbers (e.g. 1000 → 1K)
    final String display = value >= 1000
        ? '${(value / 1000).toStringAsFixed(1)}K'
        : '$value';
    return Container(
      constraints: const BoxConstraints(minWidth: 36),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            display,
            style: AppTextStyles.headlineLarge.copyWith(color: color),
          ),
          Text(label, style: AppTextStyles.labelLarge.copyWith(fontSize: 9)),
        ],
      ),
    );
  }
}

class _LeaderboardStatRow extends StatelessWidget {
  final String label;
  final String value;
  const _LeaderboardStatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium),
        Text(
          value,
          style: AppTextStyles.headlineLarge.copyWith(
            color: AppColors.neonCyan,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
