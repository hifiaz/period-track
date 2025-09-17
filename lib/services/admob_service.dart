import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  // Ad Unit IDs
  static const String _bannerAdUnitId = 'ca-app-pub-8821032108500398/6117316517';
  static const String _interstitialAdUnitId = 'ca-app-pub-8821032108500398/4532772107';

  // Test Ad Unit IDs for development
  static const String _testBannerAdUnitId = 'ca-app-pub-3940256099942544/2934735716';
  static const String _testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/4411468910';

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;

  // Initialize AdMob
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
    if (kDebugMode) {
      print('AdMob initialized in DEBUG mode - using test ad unit IDs');
    } else {
      print('AdMob initialized in RELEASE mode - using production ad unit IDs');
    }
  }

  // Get Banner Ad Unit ID (uses test ads in debug mode)
  String get bannerAdUnitId {
    if (kDebugMode) {
      return _testBannerAdUnitId;
    }
    if (Platform.isIOS) {
      return _bannerAdUnitId;
    }
    return _bannerAdUnitId; // Same for both platforms in this case
  }

  // Get Interstitial Ad Unit ID (uses test ads in debug mode)
  String get interstitialAdUnitId {
    if (kDebugMode) {
      return _testInterstitialAdUnitId;
    }
    if (Platform.isIOS) {
      return _interstitialAdUnitId;
    }
    return _interstitialAdUnitId; // Same for both platforms in this case
  }

  // Create Banner Ad
  BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('Banner ad loaded');
        },
        onAdFailedToLoad: (ad, error) {
          print('Banner ad failed to load: $error');
          ad.dispose();
        },
        onAdOpened: (ad) {
          print('Banner ad opened');
        },
        onAdClosed: (ad) {
          print('Banner ad closed');
        },
      ),
    );
  }

  // Load Interstitial Ad
  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          print('Interstitial ad loaded');

          _interstitialAd!.setImmersiveMode(true);
        },
        onAdFailedToLoad: (error) {
          print('Interstitial ad failed to load: $error');
          _isInterstitialAdReady = false;
        },
      ),
    );
  }

  // Show Interstitial Ad
  void showInterstitialAd({VoidCallback? onAdClosed}) {
    if (_isInterstitialAdReady && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          print('Interstitial ad showed full screen content');
        },
        onAdDismissedFullScreenContent: (ad) {
          print('Interstitial ad dismissed');
          ad.dispose();
          _isInterstitialAdReady = false;
          _interstitialAd = null;
          
          // Load next ad
          loadInterstitialAd();
          
          // Call callback if provided
          onAdClosed?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('Interstitial ad failed to show: $error');
          ad.dispose();
          _isInterstitialAdReady = false;
          _interstitialAd = null;
          
          // Load next ad
          loadInterstitialAd();
        },
      );

      _interstitialAd!.show();
    } else {
      print('Interstitial ad not ready');
      // Load ad for next time
      loadInterstitialAd();
    }
  }

  // Check if interstitial ad is ready
  bool get isInterstitialAdReady => _isInterstitialAdReady;

  // Dispose resources
  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialAdReady = false;
  }
}