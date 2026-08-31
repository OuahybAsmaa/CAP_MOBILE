import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('fr')];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'CAP MOBILE'**
  String get appTitle;

  /// No description provided for @moduleRfidTitle.
  ///
  /// In fr, this message translates to:
  /// **'Encodage (RFID)'**
  String get moduleRfidTitle;

  /// No description provided for @moduleRfidSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Encoder & lire les puces'**
  String get moduleRfidSubtitle;

  /// No description provided for @moduleQcTitle.
  ///
  /// In fr, this message translates to:
  /// **'QC RFID'**
  String get moduleQcTitle;

  /// No description provided for @moduleQcSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Parcel quality control'**
  String get moduleQcSubtitle;

  /// No description provided for @moduleExpTitle.
  ///
  /// In fr, this message translates to:
  /// **'Contrôle EXP'**
  String get moduleExpTitle;

  /// No description provided for @moduleExpSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Vérification des réceptions'**
  String get moduleExpSubtitle;

  /// No description provided for @modulePromoTitle.
  ///
  /// In fr, this message translates to:
  /// **'Opérations Commerciales'**
  String get modulePromoTitle;

  /// No description provided for @modulePromoSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Vérification des promotions'**
  String get modulePromoSubtitle;

  /// No description provided for @greetingMorning.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour,'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In fr, this message translates to:
  /// **'Bon après-midi,'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In fr, this message translates to:
  /// **'Bonsoir,'**
  String get greetingEvening;

  /// No description provided for @drawerMyProfile.
  ///
  /// In fr, this message translates to:
  /// **'Mon Profil'**
  String get drawerMyProfile;

  /// No description provided for @drawerMyStore.
  ///
  /// In fr, this message translates to:
  /// **'Mon Magasin'**
  String get drawerMyStore;

  /// No description provided for @drawerAdministration.
  ///
  /// In fr, this message translates to:
  /// **'Administration'**
  String get drawerAdministration;

  /// No description provided for @drawerSettings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get drawerSettings;

  /// No description provided for @drawerHelp.
  ///
  /// In fr, this message translates to:
  /// **'Aide & Support'**
  String get drawerHelp;

  /// No description provided for @drawerLogout.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get drawerLogout;

  /// No description provided for @drawerVersion.
  ///
  /// In fr, this message translates to:
  /// **'CapMobile v1.0 · Zebra TC52'**
  String get drawerVersion;

  /// No description provided for @modulesAvailableSection.
  ///
  /// In fr, this message translates to:
  /// **'Modules disponibles'**
  String get modulesAvailableSection;

  /// No description provided for @comingSoonBadge.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt'**
  String get comingSoonBadge;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'GESTION RFID & ÉTIQUETAGE'**
  String get welcomeSubtitle;

  /// No description provided for @welcomeScanTitle.
  ///
  /// In fr, this message translates to:
  /// **'Scannez votre badge'**
  String get welcomeScanTitle;

  /// No description provided for @welcomeScanSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Pointez le scanner Zebra vers votre code-barres'**
  String get welcomeScanSubtitle;

  /// No description provided for @welcomeLoadingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Authentification en cours'**
  String get welcomeLoadingTitle;

  /// No description provided for @welcomeLoadingSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Vérification des accréditations'**
  String get welcomeLoadingSubtitle;

  /// No description provided for @welcomeErrorTitle.
  ///
  /// In fr, this message translates to:
  /// **'Badge non reconnu'**
  String get welcomeErrorTitle;

  /// No description provided for @welcomeErrorRetry.
  ///
  /// In fr, this message translates to:
  /// **'Relance du scan dans 2 secondes...'**
  String get welcomeErrorRetry;

  /// No description provided for @welcomeZebraConnected.
  ///
  /// In fr, this message translates to:
  /// **'Système Zebra connecté'**
  String get welcomeZebraConnected;

  /// No description provided for @welcomeZebraConnecting.
  ///
  /// In fr, this message translates to:
  /// **'Connexion Zebra...'**
  String get welcomeZebraConnecting;

  /// No description provided for @profileSectionPersonal.
  ///
  /// In fr, this message translates to:
  /// **'Informations personnelles'**
  String get profileSectionPersonal;

  /// No description provided for @profileSectionStore.
  ///
  /// In fr, this message translates to:
  /// **'Magasin & rôle'**
  String get profileSectionStore;

  /// No description provided for @profileLabelCode.
  ///
  /// In fr, this message translates to:
  /// **'Code collaborateur'**
  String get profileLabelCode;

  /// No description provided for @profileLabelFullName.
  ///
  /// In fr, this message translates to:
  /// **'Nom complet'**
  String get profileLabelFullName;

  /// No description provided for @profileLabelEmail.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get profileLabelEmail;

  /// No description provided for @profileLabelPhone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get profileLabelPhone;

  /// No description provided for @profileLabelStore.
  ///
  /// In fr, this message translates to:
  /// **'Magasin'**
  String get profileLabelStore;

  /// No description provided for @profileLabelType.
  ///
  /// In fr, this message translates to:
  /// **'Type collaborateur'**
  String get profileLabelType;

  /// No description provided for @profileLabelRights.
  ///
  /// In fr, this message translates to:
  /// **'Droits'**
  String get profileLabelRights;

  /// No description provided for @profileLabelAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Administrateur'**
  String get profileLabelAdmin;

  /// No description provided for @profileLabelEmailEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Non renseigné'**
  String get profileLabelEmailEmpty;

  /// No description provided for @profileLabelPhoneEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Non renseigné'**
  String get profileLabelPhoneEmpty;

  /// No description provided for @profileLogout.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get profileLogout;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
