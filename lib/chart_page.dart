

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'locale.dart'; // 🌐 Dil dosyası

class ChartPage extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  late String currentLang;
  final ValueChanged<String> onLangChanged;

  ChartPage({
    Key? key,
    required this.themeMode,
    required this.onThemeChanged,
    required this.currentLang,
    required this.onLangChanged,
  }) : super(key: key); // 🔧 Burayı ekle

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  late String currentLang;
  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;
  List<List<TextEditingController>> controllers = [];
  List<List<TextEditingController>> previousControllers = [];
  int rows = 4;
  int columns = 2;
  final int maxColumns = 4;

  static const lightBg = Color(0xFFF1F8F6);
  static const lightPanel = Color(0xFF394867);
  static const lightCard = Color(0xFFE7F6F2);
  static const lightNameBox = Color(0xFF9EC8B9);
  static const lightText = Color(0xFF2C3333);

  static const darkBg = Color(0xFF1A1A1A);
  static const darkPanel = Color(0xFF2C3E50);
  static const darkCard = Color(0xFF263238);
  static const darkNameBox = Color(0xFF344955);
  static const darkText = Color(0xFFECEFF1);
  static const darkHint = Color(0xFF90A4AE);
  static const darkAccent = Color(0xFF4DD0E1);

  @override
  void initState() {
    super.initState();
    currentLang = widget.currentLang;
    _initControllers();
    _loadData();

    @override
    void didUpdateWidget(ChartPage oldWidget) {
      super.didUpdateWidget(oldWidget);
      if (widget.currentLang != oldWidget.currentLang) {
        // sadece boş olan name hücrelerini güncelle
        for (int i = 0; i < controllers[0].length; i++) {
          if (controllers[0][i].text.trim().isEmpty) {
            controllers[0][i].text =
                localizedStrings[widget.currentLang]!['name']!;
          }
        }
        setState(() {});
      }
    }

    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3997673870000021/2518721628',
      request: AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          print('Ad failed to load: $error');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }

  void _initControllers() {
    controllers = List.generate(
      rows,
      (_) => List.generate(columns, (_) => TextEditingController()),
    );
  }

  Future<void> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<List<String>> data = controllers
        .map((row) => row.map((cell) => cell.text).toList())
        .toList();
    String jsonData = jsonEncode(data);
    await prefs.setString('chartData', jsonData);
  }

  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jsonData = prefs.getString('chartData');
    if (jsonData != null) {
      List decoded = jsonDecode(jsonData);
      setState(() {
        controllers = decoded
            .map<List<TextEditingController>>(
              (row) => row
                  .map<TextEditingController>(
                    (text) => TextEditingController(text: text),
                  )
                  .toList(),
            )
            .toList();
        rows = controllers.length;
        columns = controllers.isNotEmpty ? controllers[0].length : 0;
      });
    }
  }

  void _saveState() {
    previousControllers = controllers
        .map(
          (row) => row
              .map((cell) => TextEditingController(text: cell.text))
              .toList(),
        )
        .toList();
  }

  void _undo() {
    if (previousControllers.isNotEmpty) {
      setState(() {
        controllers = previousControllers
            .map(
              (row) => row
                  .map((cell) => TextEditingController(text: cell.text))
                  .toList(),
            )
            .toList();
        rows = controllers.length;
        columns = controllers[0].length;
      });
      _saveData();
    }
  }

  bool _isLastRowFilled() {
    if (rows < 2) return false;
    return controllers[rows - 1].any(
      (controller) => controller.text.trim().isNotEmpty,
    );
  }

  void _checkAndAddRow() {
    if (_isLastRowFilled()) {
      _saveState();
      setState(() {
        controllers.add(List.generate(columns, (_) => TextEditingController()));
        rows++;
      });
      _saveData();
    }
  }

  void _removeColumn(int colIndex) {
    if (columns <= 1) return;
    _saveState();
    setState(() {
      for (var row in controllers) {
        row.removeAt(colIndex);
      }
      columns--;
    });
    _saveData();
  }

  int _getColumnTotal(int colIndex) {
    int sum = 0;
    for (int i = 1; i < rows; i++) {
      int value = int.tryParse(controllers[i][colIndex].text) ?? 0;
      sum += value;
    }
    return sum;
  }

  List<int> _getRelativeDifferences() {
    List<int> totals = List.generate(columns, (col) => _getColumnTotal(col));
    int minTotal = totals.reduce((a, b) => a < b ? a : b);
    return totals.map((total) => total - minTotal).toList();
  }

  void _resetChart() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(localizedStrings[widget.currentLang]!['reset']!),
        content: Text(localizedStrings[widget.currentLang]!['confirmReset']!),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(localizedStrings[widget.currentLang]!['cancel']!),
          ),
          TextButton(
            onPressed: () {
              _saveState();
              setState(() {
                rows = 4;
                columns = 2;
                _initControllers();
              });
              _saveData();
              Navigator.of(context).pop();
            },
            child: Text(localizedStrings[widget.currentLang]!['confirm']!),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - 40;
    final cellWidth = availableWidth / (columns + 1.8);
    final fontSize = (cellWidth / 5).clamp(12.0, 18.0);
    final cellHeight = fontSize * 2.2;
    final topBarHeight = MediaQuery.of(context).size.height * 0.10;
    final bottomBarHeight = MediaQuery.of(context).size.height * 0.08;

    return Scaffold(
      backgroundColor: isDark ? darkBg : lightBg,
      body: Column(
        children: [
          Container(
            height: topBarHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? darkPanel : lightPanel,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tally Up',
                    style: TextStyle(
                      color: Color.fromARGB(255, 246, 169, 3), // Altın sarısı
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.undo, color: Colors.white),
                        onPressed: _undo,
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: _resetChart,
                      ),
                      PopupMenuButton<ThemeMode>(
                        icon: const Icon(Icons.color_lens, color: Colors.white),
                        onSelected: widget.onThemeChanged,
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: ThemeMode.light,
                            child: Text("Light"),
                          ),
                          PopupMenuItem(
                            value: ThemeMode.dark,
                            child: Text("Dark"),
                          ),
                          PopupMenuItem(
                            value: ThemeMode.system,
                            child: Text("System"),
                          ),
                        ],
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.language, color: Colors.white),
                        onSelected: (lang) {
                          if (widget.currentLang != lang) {
                            widget.onLangChanged(
                              lang,
                            ); // Dil state’ini güncelle
                            Navigator.pushReplacement(
                              // Sayfayı yeniden yükle
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChartPage(
                                  themeMode: widget.themeMode,
                                  onThemeChanged: widget.onThemeChanged,
                                  currentLang: lang,
                                  onLangChanged: widget.onLangChanged,
                                ),
                              ),
                            );
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          const PopupMenuItem(
                            value: 'en',
                            child: Text('🇬🇧 English'),
                          ),
                          PopupMenuItem(
                            value: 'ku',
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/icons/kurdistan_flag.png',
                                  width: 18,
                                  height: 18,
                                ),
                                SizedBox(width: 8),
                                Text('کوردی'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'ar',
                            child: Text('🇸🇦 العربية'),
                          ),
                          const PopupMenuItem(
                            value: 'tr',
                            child: Text('🇹🇷 Türkçe'),
                          ),
                          const PopupMenuItem(
                            value: 'fa',
                            child: Text('🇮🇷 فارسی'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: bottomBarHeight + 16),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? darkCard : lightCard,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: _buildChart(
                    cellHeight,
                    fontSize,
                    isDark,
                    lightNameBox: lightNameBox,
                    darkNameBox: darkNameBox,
                    lightText: lightText,
                    darkText: darkText,
                    darkAccent: darkAccent,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: bottomBarHeight,
        decoration: BoxDecoration(
          color: isDark ? darkPanel : lightPanel,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: _isBannerAdReady
            ? AdWidget(ad: _bannerAd)
            : Center(
                child: Text(
                  localizedStrings[widget.currentLang]!['loadingAd']!,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildChart(
    double cellHeight,
    double fontSize,
    bool isDark, {
    required Color lightNameBox,
    required Color darkNameBox,
    required Color lightText,
    required Color darkText,
    required Color darkAccent,
  }) {
    List<int> totals = List.generate(columns, (col) => _getColumnTotal(col));
    bool hasValues = totals.any((total) => total > 0);

    // Benzersiz ve artan sıralı toplamlar
    List<int> uniqueSortedTotals = totals.toSet().toList()..sort();

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              List.generate(columns, (col) {
                int total = totals[col];
                int rankIndex = uniqueSortedTotals.indexOf(total);
                String displayText = '';
                Color diffColor = Colors.grey;

                if (hasValues) {
                  if (rankIndex == 0) {
                    displayText = '$total 🏆';
                    diffColor = Colors.amber;
                  } else if (rankIndex == 1) {
                    int diff = total - uniqueSortedTotals[0];
                    displayText = '+$diff ⬆️';
                    diffColor = Colors.green;
                  } else if (rankIndex == 2 && uniqueSortedTotals.length > 3) {
                    int diff = total - uniqueSortedTotals[0];
                    displayText = '+$diff ⬆️';
                    diffColor = Colors.blue;
                  } else {
                    int diff = total - uniqueSortedTotals[0];
                    displayText = '+$diff ⬇️';
                    diffColor = Colors.red;
                  }
                }

                return Expanded(
                  child: Column(
                    children:
                        List.generate(rows, (row) {
                            return Container(
                              height: cellHeight,
                              margin: const EdgeInsets.all(4),
                              child: row == 0
                                  ? _nameHeader(
                                      col,
                                      fontSize,
                                      isDark,
                                      lightNameBox,
                                      darkNameBox,
                                      lightText,
                                      darkText,
                                    )
                                  : _valueCell(
                                      col,
                                      row,
                                      fontSize,
                                      isDark,
                                      darkAccent,
                                    ),
                            );
                          })
                          ..add(
                            Text(
                              '$total',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: fontSize,
                                color: isDark ? darkAccent : Colors.teal,
                              ),
                            ),
                          )
                          ..add(
                            hasValues
                                ? Text(
                                    displayText,
                                    style: TextStyle(
                                      fontSize: fontSize * 0.8,
                                      color: diffColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                  ),
                );
              })..addAll(
                columns < maxColumns
                    ? [
                        _addColumnButton(
                          cellHeight,
                          fontSize,
                          isDark,
                          lightNameBox,
                          darkNameBox,
                        ),
                      ]
                    : [],
              ),
        ),
      ],
    );
  }

  Widget _nameHeader(
    int col,
    double fontSize,
    bool isDark,
    Color lightBox,
    Color darkBox,
    Color lightText,
    Color darkText,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? darkBox : lightBox,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Text("👤", style: TextStyle(fontSize: fontSize * 0.8)),
              if (columns > 1)
                Positioned(
                  top: -6,
                  right: -6,
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: GestureDetector(
                      onTap: () => _removeColumn(col),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: controllers[0][col],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSize,
                color: isDark ? darkText : lightText,
              ),
              decoration: InputDecoration(
                hintText: localizedStrings[widget.currentLang]!['name']!,
                hintStyle: TextStyle(
                  color: isDark ? darkHint : lightText.withOpacity(0.5),
                ),
                border: InputBorder.none,
                isCollapsed: true,
              ),
              onChanged: (_) {
                _checkAndAddRow();
                _saveData();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _valueCell(
    int col,
    int row,
    double fontSize,
    bool isDark,
    Color darkAccent,
  ) {
    return TextField(
      controller: controllers[row][col],
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: fontSize),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        hintText: '0',
        border: const UnderlineInputBorder(),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: isDark ? darkAccent : Colors.teal,
            width: 2,
          ),
        ),
      ),
      onChanged: (_) {
        _checkAndAddRow();
        Future.delayed(const Duration(milliseconds: 10), () {
          setState(() {});
        });
        _saveData();
      },
    );
  }

  Widget _addColumnButton(
    double height,
    double fontSize,
    bool isDark,
    Color lightBox,
    Color darkBox,
  ) {
    return Column(
      children: [
        Container(
          height: height,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? darkBox : lightBox,
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.add),
            iconSize: fontSize,
            onPressed: () {
              if (columns >= maxColumns) return;
              _saveState();
              setState(() {
                for (var row in controllers) {
                  row.add(TextEditingController());
                }
                columns++;
              });
              _saveData();
            },
          ),
        ),
      ],
    );
  }
}
