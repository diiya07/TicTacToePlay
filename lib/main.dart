import 'package:flutter/material.dart';

void main() {
  runApp(TicTacToe());
}

class TicTacToe extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Tic Tac Toe', style: TextStyle(fontFamily: 'Neon')),
          backgroundColor: Colors.black,
        ),
        body: GameScreen(),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  List<String> _board = [];
  bool _xTurn = true;
  String _winner = "";

  @override
  void initState() {
    super.initState();
    _board = List<String>.filled(9, '');
    _xTurn = true;
    _winner = '';
  }

  void _resetGame() {
    setState(() {
      _board = List<String>.filled(9, '');
      _xTurn = true;
      _winner = '';
    });
  }

  void _playMove(int index) {
    if (_board[index] == '' && _winner == '') {
      setState(() {
        _board[index] = _xTurn ? 'X' : 'O';
        _xTurn = !_xTurn;
        _winner = _checkWinner();
      });
    }
  }

  String _checkWinner() {
    List<List<int>> winningCombinations = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];

    for (var combo in winningCombinations) {
      if (_board[combo[0]] == _board[combo[1]] &&
          _board[combo[1]] == _board[combo[2]] &&
          _board[combo[0]] != '') {
        return _board[combo[0]];
      }
    }

    if (_board.every((element) => element != '')) {
      return 'Draw';
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      color: Colors.black,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.0,
              ),
              itemCount: 9,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _playMove(index),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    margin: EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16.0),
                      boxShadow: [
                        BoxShadow(
                          color: _board[index] == ''
                              ? Colors.white.withOpacity(0.1)
                              : (_board[index] == 'X'
                                  ? Colors.pinkAccent
                                  : Colors.cyanAccent),
                          blurRadius: 20.0,
                          spreadRadius: 4.0,
                        ),
                      ],
                      border: Border.all(
                        color: _board[index] == ''
                            ? Colors.white.withOpacity(0.2)
                            : (_board[index] == 'X'
                                ? Colors.pinkAccent
                                : Colors.cyanAccent),
                        width: 4.0,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _board[index],
                        style: TextStyle(
                          fontSize: 64.0,
                          color: _board[index] == 'X'
                              ? Colors.pinkAccent
                              : Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Neon',
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Text(
            _winner.isEmpty
                ? "Turn: ${_xTurn ? 'X' : 'O'}"
                : _winner == 'Draw'
                    ? "Game Draw!"
                    : "Winner: $_winner",
            style: TextStyle(
              fontSize: 32.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Neon',
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _resetGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purpleAccent,
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            child: Text(
              "Reset Game",
              style: TextStyle(
                fontSize: 24.0,
                color: Colors.white,
                fontFamily: 'Neon',
              ),
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
