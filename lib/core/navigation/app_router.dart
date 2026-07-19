import 'package:go_router/go_router.dart';
import 'package:tictactoe/features/home/screens/home_screen.dart';
import 'package:tictactoe/features/game/screens/game_screen.dart';
import 'package:tictactoe/features/daily_challenge/screens/daily_challenge_screen.dart';
import 'package:tictactoe/features/leaderboard/screens/leaderboard_screen.dart';
import 'package:tictactoe/features/profile/screens/profile_screen.dart';
import 'package:tictactoe/features/shop/screens/shop_screen.dart';
import 'package:tictactoe/features/replay/screens/replay_screen.dart';
import 'package:tictactoe/features/home/screens/online_lobby_screen.dart';
import 'package:tictactoe/features/home/screens/online_game_screen.dart';
import 'package:tictactoe/features/game/controllers/online_game_controller.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/game',
      builder: (context, state) {
        return GameScreen(arguments: state.extra);
      },
    ),
    GoRoute(
      path: '/online-lobby',
      builder: (context, state) => const OnlineLobbyScreen(),
    ),
    GoRoute(
      path: '/online-game',
      builder: (context, state) {
        final controller = state.extra as OnlineGameController;
        return OnlineGameScreen(controller: controller);
      },
    ),
    GoRoute(
      path: '/daily-challenge',
      builder: (context, state) => const DailyChallengeScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/shop',
      builder: (context, state) => const ShopScreen(),
    ),
    GoRoute(
      path: '/leaderboard',
      builder: (context, state) => const LeaderboardScreen(),
    ),
    GoRoute(
      path: '/replay',
      builder: (context, state) => const ReplayScreen(),
    ),
  ],
);
