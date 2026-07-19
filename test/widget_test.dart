import 'package:flutter_test/flutter_test.dart';
import 'package:tictactoe/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NeonTicTacToeApp());

    // Verify the app title exists on the home screen
    expect(find.text('TIC TAC TOE'), findsOneWidget);
    
    // Verify common menu items
    expect(find.text('PLAY VS AI'), findsOneWidget);
    expect(find.text('1 VS 1'), findsOneWidget);
    expect(find.text('ONLINE'), findsOneWidget);
  });
}
