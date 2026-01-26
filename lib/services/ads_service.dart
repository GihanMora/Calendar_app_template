import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/app_config.dart';

class AdsService {
  static InterstitialAd? _interstitial;
  static bool _isLoading = false;
  static RewardedAd? _rewarded;

  // Ad Unit IDs are read from config/country_x.json (single source of truth)
  static String get interstitialUnitId => AppConfig.interstitialAdUnitId;

  static Future<void> ensureLoaded() async {
    if (kIsWeb) return; // web unsupported
    if (_interstitial != null || _isLoading) return;
    _isLoading = true;
    await InterstitialAd.load(
      adUnitId: interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (error) {
          _interstitial = null;
          _isLoading = false;
        },
      ),
    );
  }

  static Future<void> showIfAvailable({VoidCallback? onClosed}) async {
    if (kIsWeb) {
      onClosed?.call();
      return;
    }
    if (_interstitial == null) {
      await ensureLoaded();
    }
    final ad = _interstitial;
    if (ad == null) {
      onClosed?.call();
      return;
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitial = null;
        ensureLoaded();
        onClosed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitial = null;
        ensureLoaded();
        onClosed?.call();
      },
    );
    await ad.show();
    _interstitial = null;
  }

  // Rewarded Ad for enabling dark theme
  // Ad Unit ID is read from config/country_x.json (single source of truth)
  static String get rewardedUnitId => AppConfig.rewardedAdUnitId;

  static Future<void> loadRewarded() async {
    if (kIsWeb || _rewarded != null) return;
    await RewardedAd.load(
      adUnitId: rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewarded = ad,
        onAdFailedToLoad: (error) => _rewarded = null,
      ),
    );
  }

  static Future<bool> showRewarded() async {
    if (kIsWeb) return true; // allow on web
    if (_rewarded == null) await loadRewarded();
    final ad = _rewarded;
    if (ad == null) return false;
    bool rewarded = false;
    final completer = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewarded = null;
        loadRewarded();
        if (!completer.isCompleted) completer.complete(rewarded);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewarded = null;
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    ad.show(onUserEarnedReward: (_, __) {
      rewarded = true;
    });
    return completer.future;
  }
}


