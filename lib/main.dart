

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:tictactoe/core/navigation/app_router.dart';
import 'package:tictactoe/core/utils/ad_service.dart';
import 'package:tictactoe/core/utils/score_service.dart';
import 'package:tictactoe/firebase_options.dart';
import 'package:tictactoe/shared/theme/app_theme.dart';

void main() async {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  await _requestTrackingPermission();
  await Future.wait([
    Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ), // required for online mode
    ScoreService().init(),
    AdService.initialize(),
  ]);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const NeonTicTacToeApp());
}

class NeonTicTacToeApp extends StatelessWidget {
  const NeonTicTacToeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Neon Mind Arena',
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}

Future<void> _requestTrackingPermission() async {
  try {
    final TrackingStatus status =
        await AppTrackingTransparency.trackingAuthorizationStatus;

    // Only request if not yet determined
    if (status == TrackingStatus.notDetermined) {
      // Small delay recommended by Apple — lets the app UI settle first
      await Future.delayed(const Duration(milliseconds: 200));
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
  } catch (e) {
    // Non-iOS platforms throw — safe to ignore
    debugPrint('[ATT] Tracking request skipped: $e');
  }
}
