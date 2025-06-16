

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'chart_page.dart';
import 'splash_page.dart';
import 'locale.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize(); // Google Ads SDK başlatılıyor
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;
  String _currentLang = 'en';

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;
  bool _adShown = false;

  @override
  void initState() {
    super.initState();
    _loadInterstitialAd();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-3997673870000021/5627050947',
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;

          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
                onAdDismissedFullScreenContent: (ad) => ad.dispose(),
                onAdFailedToShowFullScreenContent: (ad, error) => ad.dispose(),
              );

          if (!_adShown) {
            _interstitialAd!.show();
            _adShown = true;
          }
        },
        onAdFailedToLoad: (error) {
          print('InterstitialAd failed to load: $error');
        },
      ),
    );
  }

  void _changeTheme(ThemeMode newMode) {
    setState(() => _themeMode = newMode);
  }

  void _changeLanguage(String langCode) {
    setState(() => _currentLang = langCode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TallyUp',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF1F8F6),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF394867),
          foregroundColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2C3E50),
          foregroundColor: Colors.white,
        ),
        colorScheme: const ColorScheme.dark(primary: Colors.tealAccent),
      ),
      home: SplashPage(
        themeMode: _themeMode,
        onThemeChanged: _changeTheme,
        currentLang: _currentLang,
        onLangChanged: _changeLanguage,
      ),
    );
  }
}
