import 'package:cap_mobile/core/l10n/app_language.dart';

class AppLocalizationsFeatures {
  AppLocalizationsFeatures(this.appLanguage);

  final AppLanguage appLanguage;

  String _t(String fr, String en, String nl) => switch (appLanguage) {
    AppLanguage.fr => fr,
    AppLanguage.en => en,
    AppLanguage.nl => nl,
  };

  // ── App général ──
  String get appTitle => _t('CAP MOBILE', 'CAP MOBILE', 'CAP MOBILE');

  // ── Modules home ──
  String get moduleRfidTitle => _t('Encodage (RFID)', 'Encoding (RFID)', 'Codering (RFID)');
  String get moduleRfidSubtitle => _t('Encoder & lire les puces', 'Encode & read chips', 'Chips coderen & lezen');
  String get moduleQcTitle => _t('QC RFID', 'QC RFID', 'QC RFID');
  String get moduleQcSubtitle => _t('Contrôle qualité colis', 'Parcel quality control', 'Kwaliteitscontrole pakket');
  String get moduleExpTitle => _t('Contrôle EXP', 'EXP Control', 'EXP Controle');
  String get moduleExpSubtitle => _t('Vérification des réceptions', 'Reception verification', 'Ontvangst verificatie');
  String get modulePromoTitle => _t('Opérations Commerciales', 'Commercial Operations', 'Commerciële Operaties');
  String get modulePromoSubtitle => _t('Vérification des promotions', 'Promotions verification', 'Promoties verificatie');
  String get language => _t('Langue', 'Language', 'Taal');

  // ── Salutations ──
  String get greetingMorning => _t('Bonjour', 'Good morning', 'Goedemorgen');
  String get greetingAfternoon => _t('Bon après-midi', 'Good afternoon', 'Goedemiddag');
  String get greetingEvening => _t('Bonsoir', 'Good evening', 'Goedenavond');

  // ── Drawer ──
  String get drawerMyProfile => _t('Mon Profil', 'My Profile', 'Mijn Profiel');
  String get drawerMyStore => _t('Mon Magasin', 'My Store', 'Mijn Winkel');
  String get drawerAdministration => _t('Administration', 'Administration', 'Administratie');
  String get drawerSettings => _t('Paramètres', 'Settings', 'Instellingen');
  String get drawerHelp => _t('Aide & Support', 'Help & Support', 'Hulp & Support');
  String get drawerLogout => _t('Déconnexion', 'Logout', 'Uitloggen');
  String get modulesAvailableSection => _t('Modules disponibles', 'Available modules', 'Beschikbare modules');
  String get comingSoonBadge => _t('Bientôt', 'Coming soon', 'Binnenkort');

  // ── Welcome page ──
  String get welcomeSubtitle => _t('GESTION RFID & ÉTIQUETAGE', 'RFID & LABELING MANAGEMENT', 'RFID & ETIKETBEHEER');
  String get welcomeScanTitle => _t('Scannez votre badge', 'Scan your badge', 'Scan uw badge');
  String get welcomeScanSubtitle => _t('Pointez le scanner Zebra vers votre code-barres', 'Point the Zebra scanner at your barcode', 'Richt de Zebra-scanner op uw barcode');
  String get welcomeLoadingTitle => _t('Authentification en cours', 'Authenticating', 'Authenticeren');
  String get welcomeLoadingSubtitle => _t('Vérification des accréditations', 'Checking credentials', 'Inloggegevens controleren');
  String get welcomeErrorTitle => _t('Badge non reconnu', 'Badge not recognized', 'Badge niet herkend');
  String get welcomeErrorRetry => _t('Relance du scan dans 2 secondes...', 'Restarting scan in 2 seconds...', 'Scan herstart in 2 seconden...');
  String get welcomeZebraConnected => _t('Système Zebra connecté', 'Zebra system connected', 'Zebra systeem verbonden');
  String get welcomeZebraConnecting => _t('Connexion Zebra...', 'Connecting Zebra...', 'Zebra verbinden...');

  // ── Profile page ──
  String get profileSectionPersonal => _t('Informations personnelles', 'Personal information', 'Persoonlijke informatie');
  String get profileSectionStore => _t('Magasin & rôle', 'Store & role', 'Winkel & rol');
  String get profileLabelCode => _t('Code collaborateur', 'Employee code', 'Medewerkerscode');
  String get profileLabelFullName => _t('Nom complet', 'Full name', 'Volledige naam');
  String get profileLabelEmail => _t('Email', 'Email', 'E-mail');
  String get profileLabelPhone => _t('Téléphone', 'Phone', 'Telefoon');
  String get profileLabelStore => _t('Magasin', 'Store', 'Winkel');
  String get profileLabelType => _t('Type collaborateur', 'Employee type', 'Medewerkertype');
  String get profileLabelRights => _t('Droits', 'Rights', 'Rechten');
  String get profileLabelAdmin => _t('Administrateur', 'Administrator', 'Beheerder');
  String get profileLabelEmailEmpty => _t('Non renseigné', 'Not provided', 'Niet opgegeven');
  String get profileLabelPhoneEmpty => _t('Non renseigné', 'Not provided', 'Niet opgegeven');
  String get profileLogout => _t('Se déconnecter', 'Log out', 'Uitloggen');
}