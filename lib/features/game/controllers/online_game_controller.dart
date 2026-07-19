import 'dart:async';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tictactoe/core/models/game_models.dart';
import 'package:tictactoe/core/utils/game_logic.dart';

enum OnlineStatus {
  idle,
  creating,
  waiting,
  joining,
  playing,
  won,
  lost,
  draw,
  error,
  opponentLeft,
}

/// Manages a real-time online game via Firebase Realtime Database.
///
/// Room schema:
///   games/{code}/
///     board       : List of int (0=none, 1=X, 2=O)
///     currentTurn : String     ('X' | 'O')
///     status      : String     ('waiting' | 'playing' | 'done')
///     xName       : String
///     oName       : String
///     boardSize   : int        (3 | 5)
///     winner      : String     ('X' | 'O' | 'Draw' | '')
///     winLine     : List of int
class OnlineGameController extends ChangeNotifier {
  final DatabaseReference _db = FirebaseDatabase.instance.ref('games');

  String? _roomCode;
  Player _myPlayer = Player.none;
  List<Player> _board = List.filled(9, Player.none);
  Player _currentTurn = Player.x;
  OnlineStatus _status = OnlineStatus.idle;
  GameResult _result = const GameResult(status: GameStatus.playing);
  String _xName = 'PLAYER 1';
  String _oName = 'PLAYER 2';
  int _gridSize = 3;
  int _winLength = 3; // derived from boardSize — avoids hardcoded formula
  String _errorMessage = '';

  bool _rematchRequested = false;
  bool _opponentRematchRequested = false;
  Color? _themeColor;

  StreamSubscription<DatabaseEvent>? _subscription;

  // ── Getters ────────────────────────────────────────────────────────────────
  String? get roomCode => _roomCode;
  Player get myPlayer => _myPlayer;
  List<Player> get board => List.unmodifiable(_board);
  Player get currentTurn => _currentTurn;
  OnlineStatus get status => _status;
  GameResult get result => _result;
  String get xName => _xName;
  String get oName => _oName;
  int get gridSize => _gridSize;
  String get errorMessage => _errorMessage;
  bool get rematchRequested => _rematchRequested;
  bool get opponentRematchRequested => _opponentRematchRequested;
  Color? get themeColor => _themeColor;

  bool get isMyTurn =>
      _status == OnlineStatus.playing && _currentTurn == _myPlayer;
  bool get gameOver => _result.isOver || _status == OnlineStatus.opponentLeft;

  void setThemeColor(Color color) {
    _themeColor = color;
    notifyListeners();
  }

  // ── Room management ────────────────────────────────────────────────────────

  Future<void> createRoom({
    required String playerName,
    required BoardSize boardSize,
  }) async {
    _status = OnlineStatus.creating;
    notifyListeners();

    try {
      final String code = _generateCode();
      _roomCode = code;
      _myPlayer = Player.x;
      _gridSize = boardSize.gridSize;
      _winLength = boardSize.winLength; // use BoardSize model — no hardcoding
      _xName = playerName.toUpperCase();
      _board = List.filled(boardSize.cellCount, Player.none);

      await _db.child(code).set({
        'board': List.filled(boardSize.cellCount, 0),
        'currentTurn': 'X',
        'status': 'waiting',
        'xName': _xName,
        'oName': '',
        'boardSize': boardSize.gridSize,
        'winner': '',
        'winLine': <int>[],
        'rematchX': false,
        'rematchO': false,
      });

      _status = OnlineStatus.waiting;
      notifyListeners();
      _listenToRoom(code);
    } catch (e) {
      _setError('Failed to create room: $e');
    }
  }

  Future<void> joinRoom({
    required String code,
    required String playerName,
  }) async {
    _status = OnlineStatus.joining;
    notifyListeners();

    try {
      final snapshot = await _db.child(code).get();
      if (!snapshot.exists) {
        _setError('Room "$code" not found.');
        return;
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      if (data['status'] != 'waiting') {
        _setError('Room is no longer open.');
        return;
      }

      _roomCode = code;
      _myPlayer = Player.o;
      _gridSize = (data['boardSize'] as int?) ?? 3;
      _winLength = _gridSize >= 5 ? 5 : 3; // mirror BoardSizeExt.winLength
      _xName = (data['xName'] as String?) ?? 'PLAYER 1';
      _oName = playerName.toUpperCase();

      final int cellCount = _gridSize * _gridSize;
      _board = List.filled(cellCount, Player.none);

      await _db.child(code).update({'oName': _oName, 'status': 'playing'});

      _status = OnlineStatus.playing;
      notifyListeners();
      _listenToRoom(code);
    } catch (e) {
      _setError('Failed to join room: $e');
    }
  }

  // ── Gameplay ───────────────────────────────────────────────────────────────

  Future<void> makeMove(int index) async {
    if (!isMyTurn) return;
    if (index < 0 || index >= _board.length) return;
    if (_board[index] != Player.none) return;
    if (_result.isOver) return;

    HapticFeedback.lightImpact();

    final List<Player> newBoard = List<Player>.from(_board)
      ..[index] = _myPlayer;
    final GameResult newResult = GameLogic.checkWinner(
      newBoard,
      _gridSize,
      _winLength,
    );

    final List<int> boardInts = newBoard
        .map(
          (p) => p == Player.x
              ? 1
              : p == Player.o
              ? 2
              : 0,
        )
        .toList();

    String winner = '';
    if (newResult.status == GameStatus.xWon) winner = 'X';
    if (newResult.status == GameStatus.oWon) winner = 'O';
    if (newResult.status == GameStatus.draw) winner = 'Draw';

    try {
      await _db.child(_roomCode!).update({
        'board': boardInts,
        'currentTurn': _myPlayer == Player.x ? 'O' : 'X',
        'status': newResult.isOver ? 'done' : 'playing',
        'winner': winner,
        'winLine': newResult.winningLine,
      });
    } catch (e) {
      debugPrint('[OnlineGameController] move error: $e');
    }
  }

  Future<void> requestRematch() async {
    if (_roomCode == null || !gameOver) return;

    final String field = _myPlayer == Player.x ? 'rematchX' : 'rematchO';
    _rematchRequested = true;
    notifyListeners();

    try {
      await _db.child(_roomCode!).update({field: true});
    } catch (e) {
      debugPrint('[OnlineGameController] rematch error: $e');
    }
  }

  Future<void> _resetBoardRemotely() async {
    if (_roomCode == null) return;
    try {
      await _db.child(_roomCode!).update({
        'board': List.filled(_gridSize * _gridSize, 0),
        'currentTurn': 'X',
        'status': 'playing',
        'winner': '',
        'winLine': <int>[],
        'rematchX': false,
        'rematchO': false,
      });
    } catch (e) {
      debugPrint('[OnlineGameController] reset error: $e');
    }
  }

  // ── Firebase listener ──────────────────────────────────────────────────────

  void _listenToRoom(String code) {
    _subscription = _db
        .child(code)
        .onValue
        .listen(
          (event) {
            if (_isDisposed) return;
            if (!event.snapshot.exists) {
              _setError('Room was deleted.');
              return;
            }

            try {
              final data = Map<String, dynamic>.from(
                event.snapshot.value as Map,
              );
              _applyRemoteState(data);
            } catch (e) {
              debugPrint('[OnlineGameController] parse error: $e');
            }
          },
          onError: (e) {
            _setError('Connection lost: $e');
          },
        );
  }

  void _applyRemoteState(Map<String, dynamic> data) {
    // Board
    final List<dynamic> rawBoard = (data['board'] as List?) ?? [];
    _board = rawBoard.map((v) {
      final int n = (v as num?)?.toInt() ?? 0;
      return n == 1
          ? Player.x
          : n == 2
          ? Player.o
          : Player.none;
    }).toList();

    // Turn
    _currentTurn = (data['currentTurn'] as String?) == 'X'
        ? Player.x
        : Player.o;

    // Names
    _xName = (data['xName'] as String?) ?? _xName;
    _oName = (data['oName'] as String?) ?? _oName;

    // Status
    final String roomStatus = (data['status'] as String?) ?? 'waiting';

    // Rematch sync
    final bool remX = (data['rematchX'] as bool?) ?? false;
    final bool remO = (data['rematchO'] as bool?) ?? false;
    _rematchRequested = _myPlayer == Player.x ? remX : remO;
    _opponentRematchRequested = _myPlayer == Player.x ? remO : remX;

    if (roomStatus == 'waiting' && _myPlayer == Player.x) {
      _status = OnlineStatus.waiting;
    } else if (roomStatus == 'playing') {
      // If we were in a "done" or "rematch" state and it's now "playing", reset local game state
      if (_status != OnlineStatus.playing && _status != OnlineStatus.joining) {
        _result = const GameResult(status: GameStatus.playing);
      }
      _status = OnlineStatus.playing;
    } else if (roomStatus == 'done') {
      final String winner = (data['winner'] as String?) ?? '';
      final List<int> winLine = ((data['winLine'] as List?) ?? [])
          .map((e) => (e as num).toInt())
          .toList();

      if (winner == 'Draw') {
        _result = const GameResult(status: GameStatus.draw);
        _status = OnlineStatus.draw;
      } else if (winner == 'X') {
        _result = GameResult(status: GameStatus.xWon, winningLine: winLine);
        _status = _myPlayer == Player.x ? OnlineStatus.won : OnlineStatus.lost;
      } else if (winner == 'O') {
        _result = GameResult(status: GameStatus.oWon, winningLine: winLine);
        _status = _myPlayer == Player.o ? OnlineStatus.won : OnlineStatus.lost;
      }

      // Auto-reset if both requested rematch (only X triggers the DB update to avoid race)
      if (remX && remO && _myPlayer == Player.x) {
        _resetBoardRemotely();
      }

      HapticFeedback.heavyImpact();
    } else if (roomStatus == 'abandoned') {
      _status = OnlineStatus.opponentLeft;
    }

    if (!_isDisposed) notifyListeners();
  }

  // ── Cleanup ────────────────────────────────────────────────────────────────

  Future<void> leaveRoom() async {
    if (_roomCode == null) return;
    try {
      await _db.child(_roomCode!).update({'status': 'abandoned'});
      // Schedule deletion after a delay or use Firebase TTL rules
    } catch (_) {}
    _cleanup();
  }

  void _cleanup() {
    _subscription?.cancel();
    _subscription = null;
    _roomCode = null;
    _myPlayer = Player.none;
    _status = OnlineStatus.idle;
    _result = const GameResult(status: GameStatus.playing);
  }

  void _setError(String msg) {
    _errorMessage = msg;
    _status = OnlineStatus.error;
    if (!_isDisposed) notifyListeners();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  bool _isDisposed = false;
  @override
  void dispose() {
    _isDisposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
