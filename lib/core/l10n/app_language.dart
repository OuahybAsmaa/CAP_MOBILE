import 'package:flutter/material.dart';

enum AppLanguage {
  fr,
  en,
  nl;

  Locale get locale => Locale(name);

  String get label => switch (this) {
        AppLanguage.fr => 'Français',
        AppLanguage.en => 'English',
        AppLanguage.nl => 'Nederlands',
      };

  static const supportedLocales = [
    Locale('fr'),
    Locale('en'),
    Locale('nl'),
  ];

  static AppLanguage fromCode(String? code) {
    return AppLanguage.values.firstWhere(
      (l) => l.name == code,
      orElse: () => AppLanguage.fr,
    );
  }
}
