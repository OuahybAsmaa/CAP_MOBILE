import 'package:cap_mobile/core/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:cap_mobile/core/l10n/app_localizations_features.dart';

class AppLocalizationsScope extends InheritedWidget {
  final AppLocalizations l10n;

  const AppLocalizationsScope({
    super.key,
    required this.l10n,
    required super.child,
  });

  static AppLocalizations of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppLocalizationsScope>();
    assert(scope != null, 'AppLocalizationsScope not found');
    return scope!.l10n;
  }

  @override
  bool updateShouldNotify(AppLocalizationsScope oldWidget) =>
      l10n.appLanguage != oldWidget.l10n.appLanguage;
}

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizationsScope.of(this);
}
extension AppLocalizationsFeaturesContext on BuildContext {
  AppLocalizationsFeatures get f => AppLocalizationsFeatures(
    AppLocalizationsScope.of(this).appLanguage,
  );
}