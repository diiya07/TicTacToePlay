import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tictactoe/core/constants/app_colors.dart';
import 'package:tictactoe/core/constants/app_text_styles.dart';
import 'package:tictactoe/core/models/game_models.dart';
import 'package:tictactoe/core/utils/ad_service.dart';
import 'package:tictactoe/core/utils/responsive_layout.dart';
import 'package:tictactoe/features/game/controllers/game_controller.dart';
import 'package:tictactoe/features/game/widgets/ai_thinking_indicator.dart';
import 'package:tictactoe/features/game/widgets/board_size_selector.dart';
import 'package:tictactoe/features/game/widgets/difficulty_selector.dart';
import 'package:tictactoe/features/game/widgets/game_board.dart';
import 'package:tictactoe/features/game/widgets/game_mode_selector.dart';
import 'package:tictactoe/features/game/widgets/game_status_banner.dart';
import 'package:tictactoe/features/game/widgets/player_name_dialog.dart';
import 'package:tictactoe/shared/widgets/neon_back_button.dart';

class GameScreen extends StatefulWidget {
  final Object? arguments;
  const GameScreen({super.key, this.arguments});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController _controller;
  late final ConfettiController _confetti;
  late final AdService _adService;

  bool _didCelebrate = false;
  bool _adsLoaded = false;
  int _lastGamesCompleted = 0;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    _controller = GameController();
    _adService = AdService();
    // Listen for game-state side effects OUTSIDE of build()
    _controller.addListener(_onGameStateChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_adsLoaded) {
      final double width = MediaQuery.of(context).size.width;
      _adService.loadAll(width);
      _adsLoaded = true;
    }
    if (!_initialized) {
      final args = widget.arguments ?? ModalRoute.of(context)?.settings.arguments;
      if (args is GameConfig) {
        _controller.applyConfig(args);
      } else if (args is GameMode) {
        if (args != _controller.gameMode) _controller.setGameMode(args);
      }
      _controller.init();
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onGameStateChanged);
    _controller.dispose();
    _confetti.dispose();
    super.dispose();
  }
  // ── Ad / confetti hooks ──────────────────────────────────────────────────

  void _onGameStateChanged() {
    if (_controller.result.status == GameStatus.xWon && !_didCelebrate) {
      _confetti.play();
      _didCelebrate = true;
    }
    if (_controller.result.status == GameStatus.playing) {
      _didCelebrate = false;
    }

    final int completed = _controller.gamesCompleted;
    if (completed != _lastGamesCompleted && _controller.result.isOver) {
      _lastGamesCompleted = completed;
      _adService.onGameCompleted();
    }
  }

  // ── Modals ───────────────────────────────────────────────────────────────

  Future<void> _editPlayerName(bool isX) async {
    if (!mounted) return;
    final String current = isX
        ? _controller.playerXName
        : _controller.playerOName;
    final String? newName = await showPlayerNameDialog(
      context,
      currentName: current,
      isPlayerX: isX,
    );
    if (newName != null) _controller.setPlayerName(isX, newName);
  }

  void _showGameSettings() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _MidGameSettingsSheet(controller: _controller),
    );
  }

  // ── Monetization Actions ──────────────────────────────────────────────────

  void _requestHint() {
    _adService.showRewarded(
      onRewarded: () {
        if (mounted) _controller.applyHint();
      },
      onNotAvailable: () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Watch an ad to unlock hint. Try again shortly.',
              // 'Ad not available — showing hint anyway.'
            ),
          ),
        );
        // _controller.applyHint();
      },
    );
  }

  void _requestUndo() {
    if (!_controller.canUndo) return;
    _adService.showRewarded(
      onRewarded: () {
        if (mounted) _controller.undoMove();
      },

      onNotAvailable: () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Watch an ad to undo move. Try again shortly.',
              // 'Ad not available — undoing move anyway.'
            ),
          ),
        );
        // _controller.undoMove();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(),
          bottomNavigationBar: ListenableBuilder(
            listenable: _adService,
            builder: (context, _) => BannerAdWidget(adService: _adService),
          ),
          body: SafeArea(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                // Side effects are handled via addListener — build stays pure
                return _MainGameContent(
                  controller: _controller,
                  onEditName: _editPlayerName,
                  onResetScores: _showResetScoresDialog,
                  onRequestHint: _requestHint,
                  onRequestUndo: _requestUndo,
                );
              },
            ),
          ),
        ),

        // Confetti overlay
        ConfettiWidget(
          confettiController: _confetti,
          blastDirectionality: BlastDirectionality.explosive,
          colors: const [
            AppColors.neonPink,
            AppColors.neonCyan,
            AppColors.neonPurple,
            AppColors.neonYellow,
            AppColors.neonGreen,
          ],
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 600;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leadingWidth: isWide ? 110 : 56,
      leading: Padding(
        padding: EdgeInsets.only(
          left: isWide ? 16.0 : 8.0,
          top: isWide ? 10.0 : 6.0,
          bottom: isWide ? 10.0 : 6.0,
        ),
        child: NeonBackButton(color: _controller.themeColor),
      ),
      title: Text('TIC TAC TOE', style: AppTextStyles.headlineLarge),
      actions: [
        if (!_controller.isPremiumUnlocked)
          IconButton(
            icon: const Icon(
              Icons.workspace_premium_rounded,
              color: AppColors.neonYellow,
            ),
            tooltip: 'Premium',
            onPressed: () => _handlePremiumTap(),
          ),
        IconButton(
          icon: Icon(
            Icons.settings_suggest_rounded,
            color: _controller.isPremiumUnlocked
                ? AppColors.neonGold
                : AppColors.neonCyan,
          ),
          onPressed: _showGameSettings,
        ),
        IconButton(
          icon: Icon(Icons.leaderboard_rounded, color: _controller.themeColor),
          onPressed: () => context.push('/leaderboard'),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  void _handlePremiumTap() {
    // Show "coming soon" dialog — IAP will replace this in next update
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.neonYellow, width: 1.5),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.workspace_premium_rounded,
              color: AppColors.neonYellow,
            ),
            const SizedBox(width: 10),
            Text(
              'PREMIUM',
              style: AppTextStyles.headlineLarge.copyWith(
                color: AppColors.neonYellow,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Coming in the next update!', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 12),
            _PremiumFeatureRow(
              icon: Icons.block_rounded,
              label: 'Remove all ads',
            ),
            _PremiumFeatureRow(
              icon: Icons.lightbulb_rounded,
              label: 'Unlimited hints',
            ),
            _PremiumFeatureRow(
              icon: Icons.undo_rounded,
              label: 'Unlimited undos',
            ),
            _PremiumFeatureRow(
              icon: Icons.palette_rounded,
              label: 'Gold neon theme',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'GOT IT',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.neonYellow,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetScoresDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderActive),
        ),
        title: Text('RESET SCORES?', style: AppTextStyles.headlineLarge),
        content: Text(
          'Session scores will be cleared.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'CANCEL',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              _controller.resetScores();
              context.pop();
            },
            child: Text(
              'RESET',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.neonPink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN GAME CONTENT — non-scrollable
// ─────────────────────────────────────────────────────────────────────────────

class _MainGameContent extends StatelessWidget {
  final GameController controller;
  final Future<void> Function(bool) onEditName;
  final VoidCallback onResetScores;
  final VoidCallback onRequestHint;
  final VoidCallback onRequestUndo;

  const _MainGameContent({
    required this.controller,
    required this.onEditName,
    required this.onResetScores,
    required this.onRequestHint,
    required this.onRequestUndo,
  });

  @override
  Widget build(BuildContext context) {
    final double hPad = ResponsiveLayout.horizontalPadding(context);
    final bool isMobile = ResponsiveLayout.isMobile(context);
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool useTwoColumns = screenWidth >= 750;
    final double maxW = useTwoColumns ? 900.0 : ResponsiveLayout.maxContentWidth(context);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxW,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final boardColumn = ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ScoreBoard(controller: controller, onEditName: onEditName),
                    const SizedBox(height: 16),
                    Center(
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: GameBoard(
                          board: controller.board,
                          winningCells: controller.result.winningLine,
                          gridSize: controller.gridSize,
                          hintIndex: controller.hintIndex,
                          currentPlayer: controller.currentPlayer,
                          isEnabled:
                              controller.isPlayerTurn &&
                              !controller.result.isOver &&
                              !controller.isAIThinking,
                          themeColor: controller.themeColor,
                          onCellTap: controller.handleTap,
                        ),
                      ),
                    ),
                  ],
                ),
              );

              final actionsPanel = Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
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
                        _StatusArea(controller: controller),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _ActionIconButton(
                                onPressed: onRequestUndo,
                                icon: Icons.undo_rounded,
                                label: 'UNDO',
                                color: AppColors.neonCyan,
                                isEnabled: controller.canUndo,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ActionIconButton(
                                onPressed: onRequestHint,
                                icon: Icons.lightbulb_outline_rounded,
                                label: 'HINT',
                                color: AppColors.neonYellow,
                                isEnabled:
                                    !controller.result.isOver &&
                                    !controller.isAIThinking &&
                                    controller.hintIndex == null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: _NeonButton(
                                onPressed: controller.resetGame,
                                icon: Icons.refresh_rounded,
                                label: 'NEW GAME',
                                color: AppColors.neonPurple,
                                expand: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: _NeonButton(
                                onPressed: onResetScores,
                                icon: Icons.bar_chart_rounded,
                                label: 'RESET',
                                color: AppColors.textMuted,
                                outlined: true,
                                expand: true,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );

              if (useTwoColumns) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: boardColumn),
                        const SizedBox(width: 40),
                        Expanded(child: actionsPanel),
                      ],
                    ),
                  ),
                );
              }

              // Allow scrolling only on very small screens (<580px height)
              // so content isn’t silently clipped on iPhone SE etc.
              final physics = constraints.maxHeight < 580
                  ? const BouncingScrollPhysics()
                  : const NeverScrollableScrollPhysics();
              return SingleChildScrollView(
                physics: physics,
                child: Column(
                  children: [
                    // 1. Scores
                    _ScoreBoard(controller: controller, onEditName: onEditName),

                    SizedBox(height: isMobile ? 8 : 16),

                    // 2. Board
                    Center(
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: GameBoard(
                          board: controller.board,
                          winningCells: controller.result.winningLine,
                          gridSize: controller.gridSize,
                          hintIndex: controller.hintIndex,
                          currentPlayer: controller.currentPlayer,
                          isEnabled:
                              controller.isPlayerTurn &&
                              !controller.result.isOver &&
                              !controller.isAIThinking,
                          themeColor: controller.themeColor,
                          onCellTap: controller.handleTap,
                        ),
                      ),
                    ),
                    SizedBox(height: isMobile ? 8 : 16),

                    // 3. Status
                    _StatusArea(controller: controller),

                    const SizedBox(height: 16),

                    // 4. Monetization Actions (Undo / Hint)
                    Row(
                      children: [
                        Expanded(
                          child: _ActionIconButton(
                            onPressed: onRequestUndo,
                            icon: Icons.undo_rounded,
                            label: 'UNDO',
                            color: AppColors.neonCyan,
                            isEnabled: controller.canUndo,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionIconButton(
                            onPressed: onRequestHint,
                            icon: Icons.lightbulb_outline_rounded,
                            label: 'HINT',
                            color: AppColors.neonYellow,
                            isEnabled:
                                !controller.result.isOver &&
                                !controller.isAIThinking &&
                                controller.hintIndex == null,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 5. Main Buttons
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _NeonButton(
                            onPressed: controller.resetGame,
                            icon: Icons.refresh_rounded,
                            label: 'NEW GAME',
                            color: AppColors.neonPurple,
                            expand: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _NeonButton(
                            onPressed: onResetScores,
                            icon: Icons.bar_chart_rounded,
                            label: 'RESET',
                            color: AppColors.textMuted,
                            outlined: true,
                            expand: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _MidGameSettingsSheet extends StatefulWidget {
  final GameController controller;
  const _MidGameSettingsSheet({required this.controller});

  @override
  State<_MidGameSettingsSheet> createState() => _MidGameSettingsSheetState();
}

class _MidGameSettingsSheetState extends State<_MidGameSettingsSheet> {
  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final double hPad = ResponsiveLayout.horizontalPadding(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 32),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: AppColors.neonCyan, width: 2)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'GAME SETTINGS',
              style: AppTextStyles.displaySmall.copyWith(
                color: AppColors.neonCyan,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Text(
              'MODE',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textMuted,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 12),
            GameModeSelector(
              selected: c.gameMode,
              onChanged: (m) => setState(() => c.setGameMode(m)),
            ),
            const SizedBox(height: 24),
            Text(
              'BOARD SIZE',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textMuted,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 12),
            BoardSizeSelector(
              selected: c.boardSize,
              onChanged: (s) => setState(() => c.setBoardSize(s)),
            ),
            if (c.gameMode == GameMode.pvAI) ...[
              const SizedBox(height: 24),
              Text(
                'DIFFICULTY',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 12),
              DifficultySelector(
                selected: c.difficulty,
                onChanged: (d) => setState(() => c.setDifficulty(d)),
              ),
            ],
            const SizedBox(height: 32),
            _NeonButton(
              onPressed: () => context.pop(),
              icon: Icons.check_circle_outline_rounded,
              label: 'APPLY & CLOSE',
              color: AppColors.neonCyan,
              expand: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color color;
  final bool isEnabled;

  const _ActionIconButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.4,
      child: IgnorePointer(
        ignoring: !isEnabled,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          splashColor: color.withValues(alpha: 0.2),
          highlightColor: color.withValues(alpha: 0.1),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.3)),
              color: color.withValues(alpha: 0.05),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: color,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.play_circle_fill_rounded,
                  size: 12,
                  color: color.withValues(alpha: 0.6),
                ), // Ad symbol
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreBoard extends StatelessWidget {
  final GameController controller;
  final Future<void> Function(bool) onEditName;
  const _ScoreBoard({required this.controller, required this.onEditName});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => onEditName(true),
            child: _ScoreCard(
              label: controller.playerXName,
              score: controller.scoreX,
              color: AppColors.playerX,
              editable: true,
            ),
          ),
        ),
        _DrawIndicator(draws: controller.draws),
        Expanded(
          child: GestureDetector(
            onTap: controller.gameMode == GameMode.pvp
                ? () => onEditName(false)
                : null,
            child: _ScoreCard(
              label: controller.playerOName,
              score: controller.scoreO,
              color: AppColors.playerO,
              editable: controller.gameMode == GameMode.pvp,
            ),
          ),
        ),
      ],
    );
  }
}

class _DrawIndicator extends StatelessWidget {
  final int draws;
  const _DrawIndicator({required this.draws});

  @override
  Widget build(BuildContext context) {
    final double hPad =
        ResponsiveLayout.isMobile(context) ? 6 : 12;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Column(
        children: [
          Text(
            'DRAW',
            style: AppTextStyles.labelLarge.copyWith(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              '$draws',
              key: ValueKey(draws),
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final String label;
  final int score;
  final Color color;
  final bool editable;

  const _ScoreCard({
    required this.label,
    required this.score,
    required this.color,
    this.editable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: color,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (editable) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.edit_rounded,
                  size: 8,
                  color: color.withValues(alpha: 0.5),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              '$score',
              key: ValueKey(score),
              style: AppTextStyles.displaySmall.copyWith(
                color: color,
                fontSize: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusArea extends StatelessWidget {
  final GameController controller;
  const _StatusArea({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GameStatusBanner(
          result: controller.result,
          isAIThinking: controller.isAIThinking,
          currentPlayer: controller.currentPlayer,
          playerXName: controller.playerXName,
          playerOName: controller.playerOName,
        ),
        const SizedBox(height: 4),
        AIThinkingIndicator(visible: controller.isAIThinking),
      ],
    );
  }
}

class _NeonButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color color;
  final bool outlined;
  final bool expand;

  const _NeonButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
    this.outlined = false,
    this.expand = false,
  });

  @override
  State<_NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<_NeonButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.expand ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: widget.outlined
                ? Colors.transparent
                : widget.color.withValues(alpha: _pressed ? 0.25 : 0.13),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.color.withValues(alpha: _pressed ? 0.9 : 0.6),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 16, color: widget.color),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: AppTextStyles.labelLarge.copyWith(color: widget.color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumFeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PremiumFeatureRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.neonYellow),
          const SizedBox(width: 8),
          Text(label, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
