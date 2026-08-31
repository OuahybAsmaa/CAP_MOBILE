import 'package:cap_mobile/core/l10n/app_language.dart';
import 'package:cap_mobile/core/l10n/app_localizations.dart';
import 'package:cap_mobile/core/l10n/app_localizations_scope.dart';
import 'package:cap_mobile/core/l10n/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/pages/welcome_page.dart';

void main() {
  runApp(const ProviderScope(child: CapMobileApp()));
}

class CapMobileApp extends ConsumerWidget {
  const CapMobileApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(localeProvider);

    return AppLocalizationsScope(
      l10n: AppLocalizations(language),
      child: MaterialApp(
        title: 'CapMobile',
        debugShowCheckedModeBanner: false,
        locale: language.locale,
        supportedLocales: AppLanguage.supportedLocales,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
        initialRoute: '/',
        routes: {'/': (_) => const WelcomePage()},
      ),
    );
  }
}