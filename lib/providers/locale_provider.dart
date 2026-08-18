import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('mr');

  Locale get locale => _locale;

  LocaleProvider([SharedPreferences? prefs]) {
    if (prefs != null) {
      final languageCode = prefs.getString('language_code') ?? 'mr';
      _locale = Locale(languageCode);
    } else {
      _loadLocale();
    }
  }

  void _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code') ?? 'mr';
    if (_locale.languageCode != languageCode) {
      _locale = Locale(languageCode);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (locale == _locale) return;
    
    _locale = locale;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
  }
}
