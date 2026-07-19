

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:tictactoe/core/constants/app_colors.dart';
import 'package:tictactoe/core/constants/app_text_styles.dart';
import 'package:tictactoe/core/models/game_models.dart';
import 'package:tictactoe/core/utils/ad_service.dart';
import 'package:tictactoe/core/utils/responsive_layout.dart';
import 'package:tictactoe/features/game/controllers/online_game_controller.dart';
import 'package:tictactoe/features/game/widgets/game_board.dart';
import 'package:tictactoe/shared/widgets/neon_grid_background.dart';
import 'package:tictactoe/shared/widgets/neon_back_button.dart';

/// Online multiplayer game screen. Same non-scrollable layout as [GameScreen].
class OnlineGameScreen extends StatefulWidget {
  final OnlineGameController controller;
  const OnlineGameScreen({super.key, required this.controller});

  @override
  State<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends State<OnlineGameScreen> {
  late final ConfettiController _confetti;
  bool _didCelebrate = false;

  OnlineGameController get _ctrl => widget.controller;
  late final AdService _adService;
  bool _adsLoaded = false;

  @override
  void initState() {
    super.initState();
    _adService = AdService();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    _ctrl.addListener(_onStateChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_adsLoaded) {
      final double width = MediaQuery.of(context).size.width;
      _adService.loadAll(width);
      _adsLoaded = true;
    }
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onStateChanged);
    _ctrl.leaveRoom(); // Safety: notify opponent if we haven't already
    _ctrl.dispose();
    _confetti.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (_ctrl.status == OnlineStatus.won && !_didCelebrate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _confetti.play();
        _didCelebrate = true;
      });
    }
    if (_ctrl.status == OnlineStatus.playing) {
      _didCelebrate = false;
    }
  }

  Future<bool> _onWillPop() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderActive),
        ),
        title: Text('LEAVE GAME?', style: AppTextStyles.headlineLarge),
        content: Text(
          'Your opponent will be notified.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'STAY',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'LEAVE',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.neonPink,
              ),
            ),
          ),
        ],
      ),
    );
    if (leave == true) await _ctrl.leaveRoom();
    return leave == true;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _ctrl,
      builder: (context, _) {
        return Stack(
          alignment: Alignment.topCenter,
          children: [
            PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, result) async {
                if (didPop) return;
                final leave = await _onWillPop();
                if (leave && context.mounted) {
                  context.go('/');
                }
              },
              child: Scaffold(
                bottomNavigationBar: ListenableBuilder(
                  listenable: _adService,
                  builder: (_, _) => BannerAdWidget(adService: _adService),
                ),
                backgroundColor: AppColors.background,
                appBar: _buildAppBar(),
                body: Stack(
                  children: [
                    const Positioned.fill(child: NeonGridBackground()),
                    SafeArea(child: _buildContent()),
                  ],
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
              numberOfParticles: 30,
              gravity: 0.2,
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent() {
    if (_ctrl.status == OnlineStatus.waiting) {
      return _WaitingView(code: _ctrl.roomCode ?? '');
    }

    if (_ctrl.status == OnlineStatus.error) {
      return _ErrorView(
        message: _ctrl.errorMessage,
        onBack: () => context.pop(),
      );
    }

    final hPad = ResponsiveLayout.horizontalPadding(context);
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
                    _OnlineScoreBoard(ctrl: _ctrl),
                    const SizedBox(height: 16),
                    Center(
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: GameBoard(
                          board: _ctrl.board,
                          winningCells: _ctrl.result.winningLine,
                          gridSize: _ctrl.gridSize,
                          isEnabled: _ctrl.isMyTurn,
                          themeColor: _ctrl.themeColor,
                          currentPlayer: _ctrl.myPlayer,
                          onCellTap: _ctrl.makeMove,
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
                        _OnlineStatusArea(ctrl: _ctrl),
                        const SizedBox(height: 24),
                        if (_ctrl.gameOver) ...[
                          _RematchButton(
                            requested: _ctrl.rematchRequested,
                            opponentRequested: _ctrl.opponentRematchRequested,
                            onPressed: _ctrl.requestRematch,
                            color: _ctrl.themeColor ?? AppColors.neonPurple,
                          ),
                          const SizedBox(height: 16),
                          IconButton(
                            onPressed: () => context.pop(),
                            icon: const Icon(
                              Icons.exit_to_app_rounded,
                              color: AppColors.textMuted,
                            ),
                            tooltip: 'Leave Room',
                          ),
                        ] else if (_ctrl.status == OnlineStatus.playing) ...[
                          const SizedBox(
                            height: 56,
                          ), // Placeholder to keep layout stable
                        ],
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

              // Allow scrolling on very short devices to prevent clipping
              final physics = constraints.maxHeight < 580
                  ? const BouncingScrollPhysics()
                  : const NeverScrollableScrollPhysics();
              return SingleChildScrollView(
                physics: physics,
                child: Column(
                  children: [
                    // 1. Better Scoreboard
                    _OnlineScoreBoard(ctrl: _ctrl),

                    SizedBox(height: ResponsiveLayout.isMobile(context) ? 8 : 16),

                    // 2. Board
                    Center(
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: GameBoard(
                          board: _ctrl.board,
                          winningCells: _ctrl.result.winningLine,
                          gridSize: _ctrl.gridSize,
                          isEnabled: _ctrl.isMyTurn,
                          themeColor: _ctrl.themeColor,
                          currentPlayer: _ctrl.myPlayer,
                          onCellTap: _ctrl.makeMove,
                        ),
                      ),
                    ),

                    SizedBox(height: ResponsiveLayout.isMobile(context) ? 8 : 16),

                    // 3. Status Area
                    _OnlineStatusArea(ctrl: _ctrl),

                    const SizedBox(height: 16),

                    // 4. Rematch / Action Buttons
                    if (_ctrl.gameOver) ...[
                      _RematchButton(
                        requested: _ctrl.rematchRequested,
                        opponentRequested: _ctrl.opponentRematchRequested,
                        onPressed: _ctrl.requestRematch,
                        color: _ctrl.themeColor ?? AppColors.neonPurple,
                      ),
                    ] else if (_ctrl.status == OnlineStatus.playing) ...[
                      const SizedBox(
                        height: 56,
                      ), // Placeholder to keep layout stable
                    ],

                    const SizedBox(height: 16),

                    // Leave Button (Secondary)
                    if (_ctrl.gameOver)
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(
                          Icons.exit_to_app_rounded,
                          color: AppColors.textMuted,
                        ),
                        tooltip: 'Leave Room',
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

  PreferredSizeWidget _buildAppBar() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 600;
    final themeColor = _ctrl.themeColor ?? AppColors.neonPurple;

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
        child: NeonBackButton(
          color: themeColor,
          icon: Icons.close_rounded,
          label: 'EXIT',
          onPressed: () async {
            final leave = await _onWillPop();
            if (leave && mounted) {
              context.go('/');
            }
          },
        ),
      ),
      title: Text(
        'ONLINE',
        style: AppTextStyles.headlineLarge.copyWith(
          color: _ctrl.themeColor ?? AppColors.neonPurple,
          letterSpacing: 4,
        ),
      ),
      actions: [
        if (_ctrl.roomCode != null)
          _RoomCodeChip(
            code: _ctrl.roomCode!,
            color: _ctrl.themeColor ?? AppColors.neonPurple,
          ),
      ],
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _RoomCodeChip extends StatelessWidget {
  final String code;
  final Color color;
  const _RoomCodeChip({required this.code, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          Clipboard.setData(ClipboardData(text: code));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.surface,
              behavior: SnackBarBehavior.floating,
              content: Text(
                'Room code copied!',
                style: AppTextStyles.bodyMedium,
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  code,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: color,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.copy_rounded, size: 12, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnlineScoreBoard extends StatelessWidget {
  final OnlineGameController ctrl;
  const _OnlineScoreBoard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final myColor = ctrl.myPlayer == Player.x
        ? AppColors.playerX
        : AppColors.playerO;
    final oppColor = ctrl.myPlayer == Player.x
        ? AppColors.playerO
        : AppColors.playerX;

    final myName = ctrl.myPlayer == Player.x ? ctrl.xName : ctrl.oName;
    final oppName = ctrl.myPlayer == Player.x ? ctrl.oName : ctrl.xName;

    return Row(
      children: [
        Expanded(
          child: _OnlineScoreCard(
            name: myName.isEmpty ? 'YOU' : myName,
            color: myColor,
            isActive: ctrl.currentTurn == ctrl.myPlayer && !ctrl.gameOver,
            isMe: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _OnlineScoreCard(
            name: oppName.isEmpty ? 'OPPONENT' : oppName,
            color: oppColor,
            isActive: ctrl.currentTurn != ctrl.myPlayer && !ctrl.gameOver,
            isMe: false,
          ),
        ),
      ],
    );
  }
}

class _OnlineScoreCard extends StatelessWidget {
  final String name;
  final Color color;
  final bool isActive;
  final bool isMe;

  const _OnlineScoreCard({
    required this.name,
    required this.color,
    required this.isActive,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.1) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: isActive ? 0.8 : 0.2),
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive
            ? [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 10)]
            : null,
      ),
      child: Column(
        children: [
          Text(
            isMe ? 'YOU' : 'OPPONENT',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textMuted,
              fontSize: 8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: AppTextStyles.headlineLarge.copyWith(
              color: color,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          if (isActive) ...[
            const SizedBox(height: 4),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ],
        ],
      ),
    );
  }
}

class _OnlineStatusArea extends StatelessWidget {
  final OnlineGameController ctrl;
  const _OnlineStatusArea({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    String text = '';
    Color color = AppColors.textPrimary;

    switch (ctrl.status) {
      case OnlineStatus.playing:
        text = ctrl.isMyTurn ? 'YOUR TURN' : 'WAITING FOR OPPONENT';
        color = ctrl.isMyTurn
            ? (ctrl.myPlayer == Player.x
                  ? AppColors.playerX
                  : AppColors.playerO)
            : AppColors.textMuted;
        break;
      case OnlineStatus.won:
        text = '🎉  VICTORY!';
        color = AppColors.neonGreen;
        break;
      case OnlineStatus.lost:
        text = 'DEFEAT';
        color = AppColors.neonPink;
        break;
      case OnlineStatus.draw:
        text = 'DRAW GAME';
        color = AppColors.neonYellow;
        break;
      case OnlineStatus.opponentLeft:
        text = 'OPPONENT LEFT';
        color = AppColors.neonPink;
        break;
      default:
        break;
    }

    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Text(
            text,
            key: ValueKey(text),
            style: AppTextStyles.displaySmall.copyWith(
              color: color,
              letterSpacing: 2,
              shadows: [
                Shadow(color: color.withValues(alpha: 0.5), blurRadius: 12),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
        if (ctrl.status == OnlineStatus.playing && !ctrl.isMyTurn) ...[
          const SizedBox(height: 12),
          const SizedBox(
            width: 24,
            height: 2,
            child: LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}

class _RematchButton extends StatefulWidget {
  final bool requested;
  final bool opponentRequested;
  final VoidCallback onPressed;
  final Color color;

  const _RematchButton({
    required this.requested,
    required this.opponentRequested,
    required this.onPressed,
    required this.color,
  });

  @override
  State<_RematchButton> createState() => _RematchButtonState();
}

class _RematchButtonState extends State<_RematchButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    String text = 'PLAY AGAIN';
    if (widget.requested && !widget.opponentRequested) text = 'WAITING...';
    if (!widget.requested && widget.opponentRequested) text = 'ACCEPT REMATCH';
    if (widget.requested && widget.opponentRequested) text = 'STARTING...';

    final bool enabled = !widget.requested;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onPressed();
            }
          : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            color: widget.requested
                ? widget.color.withValues(alpha: 0.05)
                : widget.color.withValues(alpha: _pressed ? 0.25 : 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.color.withValues(
                alpha: widget.requested ? 0.3 : 0.7,
              ),
              width: 2,
            ),
            boxShadow: !widget.requested && !_pressed
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.2),
                      blurRadius: 15,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.requested && !widget.opponentRequested)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textMuted,
                  ),
                ),
              if (!widget.requested || widget.opponentRequested)
                Icon(Icons.refresh_rounded, size: 20, color: widget.color),
              const SizedBox(width: 12),
              Text(
                text,
                style: AppTextStyles.headlineLarge.copyWith(
                  color: widget.requested ? AppColors.textMuted : widget.color,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaitingView extends StatelessWidget {
  final String code;
  const _WaitingView({required this.code});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _GlowLoadingIndicator(),
            const SizedBox(height: 48),
            Text(
              'WAITING FOR OPPONENT',
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Text(
              'SHARE THIS CODE',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textMuted,
                fontSize: 10,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Code copied!'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.neonPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.neonPurple.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      code,
                      style: AppTextStyles.displayLarge.copyWith(
                        color: AppColors.neonPurple,
                        letterSpacing: 8,
                        shadows: [
                          Shadow(
                            color: AppColors.neonPurple.withValues(alpha: 0.6),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.copy_rounded,
                      color: AppColors.neonPurple,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tap to copy',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowLoadingIndicator extends StatelessWidget {
  const _GlowLoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.neonPurple.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const CircularProgressIndicator(
        color: AppColors.neonPurple,
        strokeWidth: 3,
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onBack;
  const _ErrorView({required this.message, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.neonPink,
              size: 64,
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.neonPink,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            GestureDetector(
              onTap: onBack,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.neonPink.withValues(alpha: 0.6),
                    width: 2,
                  ),
                ),
                child: Text(
                  'GO BACK',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.neonPink,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
