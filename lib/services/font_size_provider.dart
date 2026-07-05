import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontSizeProvider extends ChangeNotifier {
  static const String _prefKey = 'user_font_scale';
  static const double _defaultScale = 1.0;
  static const double _minScale = 0.8;
  static const double _maxScale = 1.1;

  double _fontScale = _defaultScale;

  double get fontScale => _fontScale;
  double get minScale => _minScale;
  double get maxScale => _maxScale;

  FontSizeProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _fontScale = prefs.getDouble(_prefKey) ?? _defaultScale;
    notifyListeners();
  }

  Future<void> setFontScale(double scale) async {
    final clamped = scale.clamp(_minScale, _maxScale);
    if (_fontScale == clamped) return;
    _fontScale = clamped;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefKey, _fontScale);
  }

  Future<void> reset() async {
    await setFontScale(_defaultScale);
  }
}
