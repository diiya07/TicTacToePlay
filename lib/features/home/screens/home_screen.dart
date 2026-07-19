
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tictactoe/core/constants/app_colors.dart';
import 'package:tictactoe/core/constants/app_text_styles.dart';
import 'package:tictactoe/core/models/game_models.dart';
import 'package:tictactoe/core/utils/progression_service.dart';
import 'package:tictactoe/core/utils/responsive_layout.dart';
import 'package:tictactoe/features/game/widgets/board_size_selector.dart';
import 'package:tictactoe/features/game/widgets/difficulty_selector.dart';
import 'package:tictactoe/features/game/widgets/game_mode_selector.dart';
import 'package:tictactoe/shared/widgets/neon_grid_background.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _subtitleFade;
  late Animation<double> _buttonsFade;
  late Animation<Offset> _buttonsSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );
    _subtitleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.65, curve: Curves.easeOut),
      ),
    );
    _buttonsFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 0.85, curve: Curves.easeOut),
      ),
    );
    _buttonsSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.55, 0.9, curve: Curves.easeOutCubic),
          ),
        );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showGameOptions(GameMode mode, {GameVariant variant = GameVariant.classic}) {
    if (mode == GameMode.online) {
      context.push('/online-lobby');
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _GameOptionsSheet(
        initialMode: mode,
        initialVariant: variant,
        onStart: (config) {
          context.pop();
          _startGame(config);
        },
      ),
    );
  }

  void _startGame(GameConfig config) {
    if (config.mode == GameMode.online) {
      context.push('/online-lobby');
      return;
    }

    context.push('/game', extra: config);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: NeonGridBackground()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveLayout.horizontalPadding(context),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 16),
                          // ── Top bar: Coins, XP, Profile, Shop ──────────
                          ListenableBuilder(
                            listenable: ProgressionService(),
                            builder: (context, _) {
                              final profile = ProgressionService().profile;
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Coins + XP
                                  Row(
                                    children: [
                                      const Icon(Icons.monetization_on_rounded,
                                          color: AppColors.coinGold, size: 18),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${profile.coins}',
                                        style: AppTextStyles.coinText,
                                      ),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.bolt_rounded,
                                          color: AppColors.xpAccent, size: 18),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Lv${profile.level}',
                                        style: AppTextStyles.xpText,
                                      ),
                                    ],
                                  ),
                                  // Tier badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: AppColors.neonPurple
                                              .withValues(alpha: 0.4)),
                                    ),
                                    child: Text(
                                      profile.tier.name.toUpperCase(),
                                      style: AppTextStyles.tierBadge.copyWith(
                                          fontSize: 10),
                                    ),
                                  ),
                                  // Profile + Shop icons
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                            Icons.shopping_bag_rounded,
                                            color: AppColors.neonYellow),
                                        tooltip: 'Shop',
                                        onPressed: () => context.push('/shop'),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.person_rounded,
                                            color: AppColors.neonCyan),
                                        tooltip: 'Profile',
                                        onPressed: () => context.push('/profile'),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          Builder(
                            builder: (context) {
                              final isWideScreen = constraints.maxWidth >= 600;

                              final logoSection = Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedBuilder(
                                    animation: _controller,
                                    builder: (context, child) => FadeTransition(
                                      opacity: _logoFade,
                                      child: ScaleTransition(
                                        scale: _logoScale,
                                        child: const _LogoWidget(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  AnimatedBuilder(
                                    animation: _subtitleFade,
                                    builder: (context, child) => FadeTransition(
                                      opacity: _subtitleFade,
                                      child: Text(
                                        'NEON EDITION',
                                        style: AppTextStyles.labelLarge.copyWith(
                                          color: AppColors.neonPurple,
                                          letterSpacing: 6,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );

                              final buttonsSection = AnimatedBuilder(
                                animation: _controller,
                                builder: (context, child) => FadeTransition(
                                  opacity: _buttonsFade,
                                  child: SlideTransition(
                                    position: _buttonsSlide,
                                    child: Center(
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 480,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              // ── Classic Modes ──────────
                                              _ModeButton(
                                                icon: Icons.smart_toy_rounded,
                                                label: 'PLAY VS AI',
                                                subtitle: 'Challenge the machine',
                                                color: AppColors.neonCyan,
                                                onTap: () =>
                                                    _showGameOptions(GameMode.pvAI),
                                              ),
                                              const SizedBox(height: 12),
                                              _ModeButton(
                                                icon: Icons.people_rounded,
                                                label: '1 VS 1',
                                                subtitle: 'Local two-player battle',
                                                color: AppColors.neonPink,
                                                onTap: () =>
                                                    _showGameOptions(GameMode.pvp),
                                              ),
                                              const SizedBox(height: 12),
                                              _ModeButton(
                                                icon: Icons.wifi_rounded,
                                                label: 'ONLINE',
                                                subtitle: 'Play with friends',
                                                color: AppColors.neonYellow,
                                                onTap: () => _showGameOptions(
                                                  GameMode.online,
                                                ),
                                              ),
                                              const SizedBox(height: 20),
                                              // ── Variant Modes Divider ──
                                              Row(
                                                children: [
                                                  const Expanded(
                                                      child: Divider(
                                                          color: AppColors.borderDefault)),
                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 12),
                                                    child: Text('VARIANTS',
                                                        style: AppTextStyles.labelLarge
                                                            .copyWith(
                                                                color: AppColors.textMuted,
                                                                fontSize: 10)),
                                                  ),
                                                  const Expanded(
                                                      child: Divider(
                                                          color: AppColors.borderDefault)),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              // Speed, Gravity, Power-up in a row
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: _VariantButton(
                                                      icon: Icons.timer_rounded,
                                                      label: 'SPEED',
                                                      color: AppColors.neonPink,
                                                      onTap: () => _showGameOptions(
                                                        GameMode.pvAI,
                                                        variant: GameVariant.speed,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: _VariantButton(
                                                      icon: Icons.arrow_downward_rounded,
                                                      label: 'GRAVITY',
                                                      color: AppColors.neonPurple,
                                                      onTap: () => _showGameOptions(
                                                        GameMode.pvAI,
                                                        variant: GameVariant.gravity,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: _VariantButton(
                                                      icon: Icons.flash_on_rounded,
                                                      label: 'POWER',
                                                      color: AppColors.neonGreen,
                                                      onTap: () => _showGameOptions(
                                                        GameMode.pvAI,
                                                        variant: GameVariant.powerUp,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              // ── Daily Challenge ──
                                              _ModeButton(
                                                icon: Icons.calendar_today_rounded,
                                                label: 'DAILY CHALLENGE',
                                                subtitle:
                                                    'Win 50 coins + 100 XP today',
                                                color: AppColors.coinGold,
                                                onTap: () => context.push('/daily-challenge'),
                                              ),
                                              const SizedBox(height: 12),
                                              // ── Leaderboard ──
                                              _ModeButton(
                                                icon: Icons.emoji_events_rounded,
                                                label: 'LEADERBOARD',
                                                subtitle: 'See the top players',
                                                color: AppColors.neonYellow,
                                                onTap: () => context.push('/leaderboard'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );

                              if (isWideScreen) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(child: logoSection),
                                    const SizedBox(width: 32),
                                    Expanded(child: buttonsSection),
                                  ],
                                );
                              } else {
                                return Column(
                                  children: [
                                    logoSection,
                                    const SizedBox(height: 32),
                                    buttonsSection,
                                  ],
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 32),
                          AnimatedBuilder(
                            animation: _buttonsFade,
                            builder: (context, child) => FadeTransition(
                              opacity: _buttonsFade,
                              child: Text(
                                'v1.0.0',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GameOptionsSheet extends StatefulWidget {
  final GameMode initialMode;
  final GameVariant initialVariant;
  final ValueChanged<GameConfig> onStart;

  const _GameOptionsSheet({
    required this.initialMode,
    this.initialVariant = GameVariant.classic,
    required this.onStart,
  });

  @override
  State<_GameOptionsSheet> createState() => _GameOptionsSheetState();
}

class _GameOptionsSheetState extends State<_GameOptionsSheet> {
  late GameMode _mode;
  late GameVariant _variant;
  BoardSize _size = BoardSize.three;
  Difficulty _difficulty = Difficulty.hard;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _variant = widget.initialVariant;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        32,
        24,
        32 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: AppColors.neonPurple, width: 2)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'GAME OPTIONS',
              style: AppTextStyles.displaySmall.copyWith(
                color: AppColors.neonPurple,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _OptionLabel('GAME MODE'),
            const SizedBox(height: 12),
            GameModeSelector(
              selected: _mode,
              onChanged: (m) => setState(() => _mode = m),
            ),
            const SizedBox(height: 24),
            _OptionLabel('BOARD SIZE'),
            const SizedBox(height: 12),
            BoardSizeSelector(
              selected: _size,
              onChanged: (s) => setState(() => _size = s),
            ),
            const SizedBox(height: 24),
            if (_mode == GameMode.pvAI) ...[
              _OptionLabel('DIFFICULTY'),
              const SizedBox(height: 12),
              DifficultySelector(
                selected: _difficulty,
                onChanged: (d) => setState(() => _difficulty = d),
              ),
              const SizedBox(height: 32),
            ],
            ElevatedButton(
              onPressed: () => widget.onStart(
                GameConfig(
                  mode: _mode,
                  variant: _variant,
                  difficulty: _difficulty,
                  boardSize: _size,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonPurple.withValues(alpha: 0.2),
                foregroundColor: AppColors.neonPurple,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.neonPurple, width: 2),
                ),
                elevation: 0,
              ),
              child: Text(
                'START GAME',
                style: AppTextStyles.headlineLarge.copyWith(letterSpacing: 2),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _OptionLabel extends StatelessWidget {
  final String text;
  const _OptionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.labelLarge.copyWith(
        color: AppColors.textMuted,
        letterSpacing: 4,
        fontSize: 10,
      ),
    );
  }
}

class _LogoWidget extends StatelessWidget {
  const _LogoWidget();

  @override
  Widget build(BuildContext context) {
    final double size = (MediaQuery.of(context).size.width * 0.3).clamp(100, 160);
    return Column(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: 9,
            itemBuilder: (context, i) {
              const pattern = ['X', 'O', '', '', 'X', 'O', '', '', 'X'];
              final symbol = pattern[i];
              final color = symbol == 'X'
                  ? AppColors.playerX
                  : symbol == 'O'
                  ? AppColors.playerO
                  : AppColors.borderDefault;
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: symbol.isNotEmpty
                        ? color.withValues(alpha: 0.5)
                        : AppColors.borderDefault,
                    width: 1.5,
                  ),
                  boxShadow: symbol.isNotEmpty
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: symbol.isNotEmpty
                      ? Text(
                          symbol,
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: color,
                            shadows: [
                              Shadow(
                                color: color.withValues(alpha: 0.8),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        )
                      : null,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'NEON MIND ARENA',
          style: AppTextStyles.displayMedium.copyWith(
            fontSize: 20,
            letterSpacing: 2,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ModeButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ModeButton> createState() => _ModeButtonState();
}

class _ModeButtonState extends State<_ModeButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap?.call();
            }
          : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          decoration: BoxDecoration(
            color: enabled
                ? widget.color.withValues(alpha: _pressed ? 0.18 : 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: enabled
                  ? widget.color.withValues(alpha: _pressed ? 0.8 : 0.4)
                  : AppColors.borderDefault,
              width: 1.5,
            ),
            boxShadow: enabled && !_pressed
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 26,
                color: enabled ? widget.color : AppColors.textMuted,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: AppTextStyles.headlineLarge.copyWith(
                        color: enabled ? widget.color : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: enabled
                            ? AppColors.textSecondary
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (enabled)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: widget.color.withValues(alpha: 0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── _VariantButton ─────────────────────────────────────────────────────────────

class _VariantButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _VariantButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_VariantButton> createState() => _VariantButtonState();
}

class _VariantButtonState extends State<_VariantButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: _pressed ? 0.2 : 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.color.withValues(alpha: _pressed ? 0.9 : 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: widget.color, size: 24),
              const SizedBox(height: 6),
              Text(
                widget.label,
                style: AppTextStyles.labelLarge.copyWith(
                  color: widget.color,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
