import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AdMobService {
  // Ad Unit IDs
  static String get _bannerAdUnitId => dotenv.env['BANNER_AD_UNIT_ID']!;
  static String get _interstitialAdUnitId => dotenv.env['INTERSTITIAL_AD_UNIT_ID']!;

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
    } // else {
      // print('AdMob initialized in RELEASE mode - using production ad unit IDs');
    // }
  }

  // Get Banner Ad Unit ID (uses test ads in debug mode)
  static String get bannerAdUnitId {
    if (kDebugMode) {
      return _testBannerAdUnitId;
    }
    if (Platform.isIOS) {
      return _bannerAdUnitId;
    }
    return _bannerAdUnitId; // Same for both platforms in this case
  }

  // Get Interstitial Ad Unit ID (uses test ads in debug mode)
  static String get interstitialAdUnitId {
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
          // print('Banner ad loaded');
        },
        onAdFailedToLoad: (ad, error) {
          if (kDebugMode) {
            print('Banner ad failed to load: $error');
          }
          ad.dispose();
        },
        onAdOpened: (ad) {
          // print('Banner ad opened');
        },
        onAdClosed: (ad) {
          // print('Banner ad closed');
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
          if (kDebugMode) {
            print('Interstitial ad loaded');
          }

          _interstitialAd!.setImmersiveMode(true);
        },
        onAdFailedToLoad: (error) {
          if (kDebugMode) {
            print('Interstitial ad failed to load: $error');
          }
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
          // print('Interstitial ad showed full screen content');
        },
        onAdDismissedFullScreenContent: (ad) {
          // print('Interstitial ad dismissed');
          ad.dispose();
          _isInterstitialAdReady = false;
          _interstitialAd = null;
          
          // Load next ad
          loadInterstitialAd();
          
          // Call callback if provided
          onAdClosed?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          if (kDebugMode) {
            print('Interstitial ad failed to show: $error');
          }
          ad.dispose();
          _isInterstitialAdReady = false;
          _interstitialAd = null;
          
          // Load next ad
          loadInterstitialAd();
        },
      );

      _interstitialAd!.show();
    } else {
      if (kDebugMode) {
        print('Interstitial ad not ready');
      }
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
