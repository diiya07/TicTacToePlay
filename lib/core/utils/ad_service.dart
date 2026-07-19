import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:tictactoe/core/utils/progression_service.dart';
import 'package:tictactoe/core/utils/score_service.dart';

// ── Test Ad Unit IDs (replace with real IDs before release) ──────────────────

class _AdIds {
  _AdIds._();

  static String get banner {
    if (kIsWeb) return '';
    return defaultTargetPlatform == TargetPlatform.iOS
        ? 'ca-app-pub-3940256099942544/2934735716'
        : 'ca-app-pub-3940256099942544/6300978111';
  }

  static String get interstitial {
    if (kIsWeb) return '';
    return defaultTargetPlatform == TargetPlatform.iOS
        ? 'ca-app-pub-3940256099942544/4411468910'
        : 'ca-app-pub-3940256099942544/1033173712';
  }

  static String get rewarded {
    if (kIsWeb) return '';
    return defaultTargetPlatform == TargetPlatform.iOS
        ? 'ca-app-pub-3940256099942544/1712485313'
        : 'ca-app-pub-3940256099942544/5224354917';
  }
}

// ── AdService ─────────────────────────────────────────────────────────────────

/// Manages all AdMob ads — banner, interstitial, rewarded.
///
/// Usage:
///   final adService = AdService();
///   await adService.initialize();
///   adService.loadInterstitial();
///   adService.loadRewarded();
///   adService.onGameCompleted(); // call after each game finishes
///
/// Never crashes on ad failure — all errors are swallowed safely.
class AdService extends ChangeNotifier {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();
  static const int _interstitialTriggerCount = 3;

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  bool _bannerReady = false;
  bool _interstitialReady = false;
  bool _rewardedReady = false;
  int _gamesCompleted = 0;

  bool get bannerReady => _bannerReady && !kIsWeb && !_isPremium;
  BannerAd? get bannerAd => _bannerAd;

  bool _isPremium = false;

  Future<void> loadPremiumState() async {
    _isPremium = await ScoreService().isPremiumUnlocked();
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Call once in main() before runApp().
  static Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      await MobileAds.instance.initialize();
    } catch (e) {
      debugPrint('[AdService] initialize error: $e');
    }
  }

  void loadAll(double bannerWidth) {
    _loadBanner(bannerWidth);
    _loadInterstitial();
    _loadRewarded();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }

  // ── Game lifecycle hook ───────────────────────────────────────────────────

  /// Call once per completed game. Shows interstitial every N games.
  void onGameCompleted() {
    if (kIsWeb || _isPremium) return;
    _gamesCompleted++;
    if (_gamesCompleted % _interstitialTriggerCount == 0) {
      _showInterstitial();
    }
  }

  // ── Banner ────────────────────────────────────────────────────────────────
  Future<void> _loadBanner(double bannerWidth) async {
    if (kIsWeb) return;
    final String id = _AdIds.banner;
    if (id.isEmpty) return;

    _bannerAd?.dispose();
    _bannerReady = false;

    // Adaptive size — falls back to standard banner if null
    final AnchoredAdaptiveBannerAdSize? adaptiveSize =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
          bannerWidth.truncate(),
        );

    final AdSize size = adaptiveSize ?? AdSize.banner;

    _bannerAd = BannerAd(
      adUnitId: id,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          _bannerReady = true;
          notifyListeners();
        },
        onAdFailedToLoad: (_, error) {
          debugPrint('[AdService] Banner failed: $error');
          _bannerReady = false;
          _bannerAd?.dispose();
          _bannerAd = null;
          notifyListeners();
        },
      ),
    )..load();
  }

  // ── Interstitial ──────────────────────────────────────────────────────────

  void loadInterstitial() => _loadInterstitial();

  void _loadInterstitial() {
    if (kIsWeb) return;
    final String id = _AdIds.interstitial;
    if (id.isEmpty) return;

    InterstitialAd.load(
      adUnitId: id,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialReady = true;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (_) {
              _interstitialReady = false;
              _interstitialAd = null;
              _loadInterstitial(); // pre-load for next time
            },
            onAdFailedToShowFullScreenContent: (_, error) {
              debugPrint('[AdService] Interstitial show failed: $error');
              _interstitialReady = false;
              _interstitialAd = null;
              _loadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdService] Interstitial load failed: $error');
          _interstitialReady = false;
        },
      ),
    );
  }

  void _showInterstitial() {
    if (!_interstitialReady || _interstitialAd == null) return;
    try {
      _interstitialAd!.show();
    } catch (e) {
      debugPrint('[AdService] Interstitial show exception: $e');
    }
  }

  // ── Rewarded ──────────────────────────────────────────────────────────────

  void loadRewarded() => _loadRewarded();

  void _loadRewarded() {
    if (kIsWeb) return;
    final String id = _AdIds.rewarded;
    if (id.isEmpty) return;

    RewardedAd.load(
      adUnitId: id,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _rewardedReady = true;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (_) {
              _rewardedReady = false;
              _rewardedAd = null;
              _loadRewarded(); // pre-load
            },
            onAdFailedToShowFullScreenContent: (_, error) {
              debugPrint('[AdService] Rewarded show failed: $error');
              _rewardedReady = false;
              _rewardedAd = null;
              _loadRewarded();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdService] Rewarded load failed: $error');
          _rewardedReady = false;
        },
      ),
    );
  }

  /// Shows the rewarded ad. Calls [onRewarded] only if the user earns a reward.
  /// Calls [onNotAvailable] if no ad is loaded.
  /// Always grants 25 coins when the user earns a reward.
  void showRewarded({
    required VoidCallback onRewarded,
    required VoidCallback onNotAvailable,
  }) {
    if (kIsWeb || !_rewardedReady || _rewardedAd == null) {
      onNotAvailable();
      return;
    }
    try {
      _rewardedAd!.show(onUserEarnedReward: (ad, reward) {
        ProgressionService().addCoins(25);
        onRewarded();
      });
    } catch (e) {
      debugPrint('[AdService] Rewarded show exception: $e');
      onNotAvailable();
    }
  }
}

// ── BannerAdWidget ────────────────────────────────────────────────────────────

/// Drop-in widget that renders the banner ad when ready.
/// Zero-height when ad isn't loaded — never breaks layout.
class BannerAdWidget extends StatelessWidget {
  final AdService adService;

  const BannerAdWidget({super.key, required this.adService});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !adService.bannerReady || adService.bannerAd == null) {
      return const SizedBox.shrink();
    }
    final BannerAd ad = adService.bannerAd!;
    return SafeArea(
      top: false,
      child: SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
