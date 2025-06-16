import 'dart:async';
import 'package:flutter/material.dart';
import 'chart_page.dart';

class SplashPage extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  final String currentLang;
  final ValueChanged<String> onLangChanged;

  const SplashPage({
    required this.themeMode,
    required this.onThemeChanged,
    required this.currentLang,
    required this.onLangChanged,
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();

    Timer(Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChartPage(
            key: ValueKey(
              widget.currentLang,
            ), // 🔁 Dil değişince yeniden oluşturur
            themeMode: widget.themeMode,
            onThemeChanged: widget.onThemeChanged,
            currentLang: widget.currentLang,
            onLangChanged: widget.onLangChanged,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1C20), // Koyu özel arka plan
      body: Center(
        child: Image.asset('assets/logo.png', width: 200, height: 200),
      ),
    );
  }
}
