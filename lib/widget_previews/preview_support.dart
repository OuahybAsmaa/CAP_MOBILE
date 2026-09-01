// =============================================================================
// CapMobile — Widget Previews — Support commun (debug / IDE)
// -----------------------------------------------------------------------------
// Fonctionnalité : Wrappers thème, l10n, Riverpod pour @Preview.
// Usage          : flutter widget-preview start  ·  onglet IDE « Widget Preview »
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/core/l10n/app_language.dart';
import 'package:cap_mobile/core/l10n/app_localizations.dart';
import 'package:cap_mobile/core/l10n/app_localizations_scope.dart';
import 'package:cap_mobile/core/services/auth_service.dart';
import 'package:cap_mobile/features/auth/models/collaborateur_model.dart';
import 'package:cap_mobile/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Collaborateur injecté dans les previews Swapp.
CollaborateurModel get previewCollaborateur => CollaborateurModel(
      codeCollab: 154,
      nom: 'AMIZIANI',
      prenom: 'Aziz',
      email: 'aziz.amiziani@chaussea.net',
      tel: '0612345678',
      typeCollabLibelle: 'Vendeur',
      estAdministrateur: false,
      codeMag: 26,
      pictureLink: '',
      mags: [
        MagasinModel(codeMag: 26, nomMag: 'Magasin 26'),
      ],
    );

/// AuthService minimal pour le previewer (sans appel réseau).
class PreviewAuthService extends AuthService {
  @override
  Future<CollaborateurModel> getCollaborateur(String codeCollab) async {
    return previewCollaborateur;
  }

  @override
  String getPhotoUrl(int codeCollab) {
    return 'https://ui-avatars.com/api/?name=Aziz&background=4640D6&color=fff&size=100';
  }
}

/// AuthNotifier mock — injecte un collaborateur fixe sans appel réseau (previews IDE).
class _PreviewAuthNotifier extends AuthNotifier {
  _PreviewAuthNotifier(Ref ref) : super(PreviewAuthService(), ref) {
    state = AuthState(collaborateur: previewCollaborateur);
  }
}

/// Thème clair Cap Mobile pour le previewer web.
PreviewThemeData capMobilePreviewTheme() => PreviewThemeData(
      materialLight: ThemeData(
        colorSchemeSeed: const Color(0xFF3949AB),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFEEF0FA),
      ),
      materialDark: ThemeData.dark(useMaterial3: true),
    );

/// Localisations FR par défaut dans le previewer.
PreviewLocalizationsData capMobilePreviewLocalizations() =>
    const PreviewLocalizationsData(
      locale: Locale('fr'),
      supportedLocales: AppLanguage.supportedLocales,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );

/// MaterialApp + l10n + Riverpod (auth mock) pour les écrans Swapp.
Widget capMobilePreviewWrapper(Widget child) {
  final l10n = AppLocalizations(AppLanguage.fr);

  return ProviderScope(
    overrides: [
      authProvider.overrideWith(_PreviewAuthNotifier.new),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: l10n.appLanguage.locale,
      supportedLocales: AppLanguage.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: AppLocalizationsScope(
        l10n: l10n,
        child: child,
      ),
    ),
  );
}

/// Wrapper léger — Material + l10n sans Riverpod.
Widget capMobileLightPreviewWrapper(Widget child) {
  final l10n = AppLocalizations(AppLanguage.fr);

  return MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: l10n.appLanguage.locale,
    supportedLocales: AppLanguage.supportedLocales,
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: AppLocalizationsScope(
      l10n: l10n,
      child: Scaffold(body: Center(child: child)),
    ),
  );
}

/// Fonctions dp/sp identité — pas de mise à l'échelle dans le previewer web.
double previewDp(double value) => value;
double previewSp(double value) => value;
