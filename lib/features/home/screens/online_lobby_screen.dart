

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tictactoe/core/constants/app_colors.dart';
import 'package:tictactoe/core/constants/app_text_styles.dart';
import 'package:tictactoe/core/models/game_models.dart';
import 'package:tictactoe/core/utils/responsive_layout.dart';
import 'package:tictactoe/core/utils/score_service.dart';
import 'package:tictactoe/features/game/controllers/online_game_controller.dart';
import 'package:tictactoe/shared/widgets/neon_grid_background.dart';
import 'package:tictactoe/shared/widgets/neon_back_button.dart';

/// Create or join an online room.
class OnlineLobbyScreen extends StatefulWidget {
  const OnlineLobbyScreen({super.key});

  @override
  State<OnlineLobbyScreen> createState() => _OnlineLobbyScreenState();
}

class _OnlineLobbyScreenState extends State<OnlineLobbyScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _nameCtrl = TextEditingController(text: 'PLAYER');
  final _codeCtrl = TextEditingController();
  BoardSize _boardSize = BoardSize.three;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadSavedName();
  }

  Future<void> _loadSavedName() async {
    // Load saved name from Player 1's slot if available
    final savedName = await ScoreService().getPlayerName(true);
    if (mounted && savedName != 'PLAYER 1') {
      _nameCtrl.text = savedName;
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    if (_loading) return;
    final name = _nameCtrl.text.trim().isEmpty ? 'PLAYER' : _nameCtrl.text.trim();
    setState(() => _loading = true);
    
    final ctrl = OnlineGameController();
    // In a real app, we'd check user settings for the theme color.
    // For now, we'll default to the standard neonPurple.
    ctrl.setThemeColor(AppColors.neonPurple);
    
    await ctrl.createRoom(playerName: name, boardSize: _boardSize);
    
    if (!mounted) return;
    setState(() => _loading = false);
    
    if (ctrl.status == OnlineStatus.error) {
      _showError(ctrl.errorMessage);
      ctrl.dispose();
      return;
    }
    
    // Save name for next time
    await ScoreService().setPlayerName(true, name);
    
    if (!mounted) return;
    context.go('/online-game', extra: ctrl);
  }

  Future<void> _joinRoom() async {
    if (_loading) return;
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 6) {
      _showError('Enter a valid 6-character room code.');
      return;
    }
    final name = _nameCtrl.text.trim().isEmpty ? 'PLAYER' : _nameCtrl.text.trim();
    setState(() => _loading = true);
    
    final ctrl = OnlineGameController();
    ctrl.setThemeColor(AppColors.neonPurple);
    
    await ctrl.joinRoom(code: code, playerName: name);
    
    if (!mounted) return;
    setState(() => _loading = false);
    
    if (ctrl.status == OnlineStatus.error) {
      _showError(ctrl.errorMessage);
      ctrl.dispose();
      return;
    }
    
    // Save name for next time
    await ScoreService().setPlayerName(true, name);
    
    if (!mounted) return;
    context.go('/online-game', extra: ctrl);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: AppColors.neonPink.withValues(alpha: 0.9),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Text(msg, style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final hPad = ResponsiveLayout.horizontalPadding(context);
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWide = screenWidth >= 750;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: NeonGridBackground()),
          Scaffold(
            backgroundColor: Colors.transparent,
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
              title: Text('ONLINE',
                  style: AppTextStyles.headlineLarge
                      .copyWith(color: AppColors.neonPurple, letterSpacing: 4)),
              centerTitle: true,
              bottom: isWide
                  ? null
                  : TabBar(
                      controller: _tabs,
                      indicatorColor: AppColors.neonPurple,
                      indicatorWeight: 3,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelStyle: AppTextStyles.labelLarge.copyWith(letterSpacing: 2),
                      unselectedLabelStyle: AppTextStyles.labelLarge
                          .copyWith(color: AppColors.textMuted, letterSpacing: 2),
                      tabs: const [
                        Tab(text: 'CREATE'),
                        Tab(text: 'JOIN'),
                      ],
                    ),
            ),
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isWide ? 900 : 440,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: hPad,
                      vertical: 24,
                    ),
                    child: isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left Column: CREATE
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: AppColors.borderDefault,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        'CREATE ROOM',
                                        style: AppTextStyles.displaySmall
                                            .copyWith(color: AppColors.neonPurple),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 12),
                                      _CreateTab(
                                        nameCtrl: _nameCtrl,
                                        boardSize: _boardSize,
                                        onBoardSize: (s) => setState(() => _boardSize = s),
                                        loading: _loading,
                                        onCreate: _createRoom,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 32),
                              // Right Column: JOIN
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: AppColors.borderDefault,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        'JOIN ROOM',
                                        style: AppTextStyles.displaySmall
                                            .copyWith(color: AppColors.neonCyan),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 12),
                                      _JoinTab(
                                        nameCtrl: _nameCtrl,
                                        codeCtrl: _codeCtrl,
                                        loading: _loading,
                                        onJoin: _joinRoom,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : TabBarView(
                            controller: _tabs,
                            children: [
                              _CreateTab(
                                nameCtrl: _nameCtrl,
                                boardSize: _boardSize,
                                onBoardSize: (s) => setState(() => _boardSize = s),
                                loading: _loading,
                                onCreate: _createRoom,
                              ),
                              _JoinTab(
                                nameCtrl: _nameCtrl,
                                codeCtrl: _codeCtrl,
                                loading: _loading,
                                onJoin: _joinRoom,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Create tab ────────────────────────────────────────────────────────────────

class _CreateTab extends StatelessWidget {
  final TextEditingController nameCtrl;
  final BoardSize boardSize;
  final ValueChanged<BoardSize> onBoardSize;
  final bool loading;
  final VoidCallback onCreate;

  const _CreateTab({
    required this.nameCtrl, required this.boardSize,
    required this.onBoardSize, required this.loading,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          _InputField(ctrl: nameCtrl, label: 'YOUR NAME', hint: 'Enter name', icon: Icons.person_rounded),
          const SizedBox(height: 32),
          _FieldLabel('BOARD SIZE'),
          const SizedBox(height: 16),
          Row(
            children: [
              _SizeOption(
                size: BoardSize.three,
                current: boardSize,
                onTap: () => onBoardSize(BoardSize.three),
              ),
              const SizedBox(width: 12),
              _SizeOption(
                size: BoardSize.five,
                current: boardSize,
                onTap: () => onBoardSize(BoardSize.five),
              ),
            ],
          ),
          const SizedBox(height: 48), 
          _LobbyButton(
            label: loading ? 'CREATING...' : 'CREATE ROOM',
            color: AppColors.neonPurple,
            onPressed: loading ? null : onCreate,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Join tab ──────────────────────────────────────────────────────────────────

class _JoinTab extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController codeCtrl;
  final bool loading;
  final VoidCallback onJoin;

  const _JoinTab({
    required this.nameCtrl, required this.codeCtrl,
    required this.loading, required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          _InputField(ctrl: nameCtrl, label: 'YOUR NAME', hint: 'Enter name', icon: Icons.person_rounded),
          const SizedBox(height: 24),
          _InputField(
            ctrl: codeCtrl,
            label: 'ROOM CODE',
            hint: '6-CHAR CODE',
            caps: true,
            maxLen: 6,
            icon: Icons.vpn_key_rounded,
          ),
          const SizedBox(height: 48), 
          _LobbyButton(
            label: loading ? 'JOINING...' : 'JOIN ROOM',
            color: AppColors.neonCyan,
            onPressed: loading ? null : onJoin,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: AppTextStyles.labelLarge
          .copyWith(color: AppColors.textMuted, letterSpacing: 4, fontSize: 10));
}

class _InputField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  final bool caps;
  final int? maxLen;
  final IconData icon;
  
  const _InputField({
    required this.ctrl, required this.label, required this.hint,
    required this.icon,
    this.caps = false, this.maxLen,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        const SizedBox(height: 12),
        TextField(
          controller: ctrl,
          maxLength: maxLen ?? 16,
          textCapitalization: caps
              ? TextCapitalization.characters
              : TextCapitalization.words,
          style: AppTextStyles.headlineLarge
              .copyWith(color: AppColors.textPrimary, letterSpacing: caps ? 4 : 1),
          cursorColor: AppColors.neonPurple,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
            counterText: '',
            hintText: hint,
            hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.borderDefault, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.borderDefault, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.neonPurple, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _LobbyButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  const _LobbyButton({required this.label, required this.color, this.onPressed});

  @override
  State<_LobbyButton> createState() => _LobbyButtonState();
}

class _LobbyButtonState extends State<_LobbyButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onPressed!();
            }
          : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: widget.color
                .withValues(alpha: enabled ? (_pressed ? 0.25 : 0.15) : 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: widget.color.withValues(
                    alpha: enabled ? (_pressed ? 1.0 : 0.7) : 0.2),
                width: 2),
            boxShadow: enabled && !_pressed
                ? [
                    BoxShadow(
                        color: widget.color.withValues(alpha: 0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 4))
                  ]
                : null,
          ),
          child: Center(
            child: widget.onPressed == null && widget.label.contains('...')
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: widget.color))
                : Text(widget.label,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headlineLarge.copyWith(
                        letterSpacing: 2,
                        color: widget.color
                            .withValues(alpha: enabled ? 1.0 : 0.3))),
          ),
        ),
      ),
    );
  }
}


class _SizeOption extends StatelessWidget {
  final BoardSize size;
  final BoardSize current;
  final VoidCallback onTap;

  const _SizeOption({
    required this.size,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool active = size == current;
    final Color col =
        size == BoardSize.three ? AppColors.neonCyan : AppColors.neonPink;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: active ? col.withValues(alpha: 0.12) : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active ? col : AppColors.borderDefault,
              width: active ? 2 : 1.5,
            ),
            boxShadow: active
                ? [BoxShadow(color: col.withValues(alpha: 0.2), blurRadius: 12)]
                : null,
          ),
          child: Column(
            children: [
              Text(
                size.label,
                style: AppTextStyles.headlineLarge.copyWith(
                  color: active ? col : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                size == BoardSize.three ? '3 x 3' : '5 x 5',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: active ? col.withValues(alpha: 0.7) : AppColors.textMuted,
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

