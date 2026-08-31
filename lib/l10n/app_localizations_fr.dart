// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'CAP MOBILE';

  @override
  String get moduleRfidTitle => 'Encodage (RFID)';

  @override
  String get moduleRfidSubtitle => 'Encoder & lire les puces';

  @override
  String get moduleQcTitle => 'QC RFID';

  @override
  String get moduleQcSubtitle => 'Parcel quality control';

  @override
  String get moduleExpTitle => 'Contrôle EXP';

  @override
  String get moduleExpSubtitle => 'Vérification des réceptions';

  @override
  String get modulePromoTitle => 'Opérations Commerciales';

  @override
  String get modulePromoSubtitle => 'Vérification des promotions';

  @override
  String get greetingMorning => 'Bonjour,';

  @override
  String get greetingAfternoon => 'Bon après-midi,';

  @override
  String get greetingEvening => 'Bonsoir,';

  @override
  String get drawerMyProfile => 'Mon Profil';

  @override
  String get drawerMyStore => 'Mon Magasin';

  @override
  String get drawerAdministration => 'Administration';

  @override
  String get drawerSettings => 'Paramètres';

  @override
  String get drawerHelp => 'Aide & Support';

  @override
  String get drawerLogout => 'Déconnexion';

  @override
  String get drawerVersion => 'CapMobile v1.0 · Zebra TC52';

  @override
  String get modulesAvailableSection => 'Modules disponibles';

  @override
  String get comingSoonBadge => 'Bientôt';

  @override
  String get welcomeSubtitle => 'GESTION RFID & ÉTIQUETAGE';

  @override
  String get welcomeScanTitle => 'Scannez votre badge';

  @override
  String get welcomeScanSubtitle =>
      'Pointez le scanner Zebra vers votre code-barres';

  @override
  String get welcomeLoadingTitle => 'Authentification en cours';

  @override
  String get welcomeLoadingSubtitle => 'Vérification des accréditations';

  @override
  String get welcomeErrorTitle => 'Badge non reconnu';

  @override
  String get welcomeErrorRetry => 'Relance du scan dans 2 secondes...';

  @override
  String get welcomeZebraConnected => 'Système Zebra connecté';

  @override
  String get welcomeZebraConnecting => 'Connexion Zebra...';

  @override
  String get profileSectionPersonal => 'Informations personnelles';

  @override
  String get profileSectionStore => 'Magasin & rôle';

  @override
  String get profileLabelCode => 'Code collaborateur';

  @override
  String get profileLabelFullName => 'Nom complet';

  @override
  String get profileLabelEmail => 'Email';

  @override
  String get profileLabelPhone => 'Téléphone';

  @override
  String get profileLabelStore => 'Magasin';

  @override
  String get profileLabelType => 'Type collaborateur';

  @override
  String get profileLabelRights => 'Droits';

  @override
  String get profileLabelAdmin => 'Administrateur';

  @override
  String get profileLabelEmailEmpty => 'Non renseigné';

  @override
  String get profileLabelPhoneEmpty => 'Non renseigné';

  @override
  String get profileLogout => 'Se déconnecter';
}
