import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Manages the rewarded ad lifecycle.
///
/// Call [preload] once at app startup and after every shown ad.
/// Call [showRewardedAd] when the user initiates the "Watch a video" action.
///
/// Ad unit IDs are Google's official test IDs during development.
/// Replace with real unit IDs (from the AdMob console) before production.
class AdService {
  static final instance = AdService._();
  AdService._();

  RewardedAd? _rewardedAd;
  bool _isLoading = false;

  // Official Google test ad unit IDs — swap before production.
  static const _androidAdUnitId = 'ca-app-pub-6815089400235059/1626702859';
  static const _iosAdUnitId = 'ca-app-pub-6815089400235059/5804086160';

  String get _adUnitId =>
      Platform.isAndroid ? _androidAdUnitId : _iosAdUnitId;

  /// True when an ad is loaded and ready to display.
  bool get isReady => _rewardedAd != null;

  /// Loads the next rewarded ad in the background.
  /// Safe to call multiple times — ignored if already loading or loaded.
  Future<void> preload() async {
    if (_isLoading || _rewardedAd != null) return;
    _isLoading = true;
    try {
      await RewardedAd.load(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _isLoading = false;
          },
          onAdFailedToLoad: (error) {
            debugPrint('AdService: failed to load — $error');
            _isLoading = false;
          },
        ),
      );
    } catch (e) {
      debugPrint('AdService: preload error — $e');
      _isLoading = false;
    }
  }

  /// Shows the rewarded ad.
  ///
  /// [onRewarded] is called **after** the ad closes if the user earned the
  /// reward — safe to update UI and Firestore from this callback.
  ///
  /// [onFailed] is called if the ad could not be shown.
  void showRewardedAd({
    required VoidCallback onRewarded,
    VoidCallback? onFailed,
  }) {
    if (_rewardedAd == null) {
      onFailed?.call();
      return;
    }

    bool rewarded = false;
    final ad = _rewardedAd!;
    _rewardedAd = null; // clear immediately so isReady returns false

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (rewarded) onRewarded();
        preload(); // load the next ad in background
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('AdService: failed to show — $error');
        ad.dispose();
        onFailed?.call();
        preload();
      },
    );

    ad.show(onUserEarnedReward: (_, __) => rewarded = true);
  }

  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
