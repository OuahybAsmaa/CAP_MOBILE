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
  String get moduleControleRfidTitle => _t('Contrôle RFID', 'RFID Control', 'RFID Controle');
  String get moduleControleRfidSubtitle => _t('Qualité & Export', 'Quality & Export', 'Kwaliteit & Export');

// ── Swapp ──
  String get moduleSwappTitle => _t('Swapp', 'Swapp', 'Swapp');
  String get moduleSwappSubtitle => _t('Stock & ventes magasin', 'Store stock & sales', 'Winkelvoorraad & verkoop');

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
  String get manualEntry => _t('Saisir manuellement', 'Enter manually', 'Handmatig invoeren');
  String get manualEntryTitle => _t('Saisie manuelle', 'Manual entry', 'Handmatige invoer');
  String get manualEntryHint => _t('Ex: 12345', 'Ex: 12345', 'Bv: 12345');
  String get manualEntryValidate => _t('Valider', 'Confirm', 'Bevestigen');
  String get manualEntryCancel => _t('Annuler', 'Cancel', 'Annuleren');

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

  // ── EXP Inventory ──
  String get expInventoryTitle => _t('Contrôle EXP', 'EXP Control', 'EXP Controle');
  String get expInventoryRunning => _t('Lecture...', 'Reading...', 'Lezen...');
  String get expInventoryWaiting => _t('En attente', 'Waiting', 'Wachten');
  String get expInventoryNoReader => _t('Aucun lecteur connecté', 'No reader connected', 'Geen lezer verbonden');
  String get expInventoryReaderPrefix => _t('Lecteur : ', 'Reader: ', 'Lezer: ');
  String get expInventoryArticles => _t('articles', 'items', 'artikelen');
  String get expTableSize => _t('Taille', 'Size', 'Maat');
  String get expTableExpected => _t('Attendu', 'Expected', 'Verwacht');
  String get expTableRead => _t('Lu', 'Read', 'Gelezen');
  String get expTableStatus => _t('Statut', 'Status', 'Status');
  String get expTableTotal => _t('TOTAL', 'TOTAL', 'TOTAAL');
  String get expTableWaiting => _t('— En attente du lancement —', '— Waiting to start —', '— Wachten op start —');
  String get expTableConform => _t('Conforme', 'Conform', 'Conform');
  String get expTableGap => _t('Écart', 'Gap', 'Verschil');
  String get expNoRfidWarning => _t('Connectez un lecteur RFID avant de commencer.', 'Connect an RFID reader before starting.', 'Verbind een RFID-lezer voor het starten.');
  String get expBtnStart => _t('Démarrer le contrôle', 'Start control', 'Controle starten');
  String get expBtnStop => _t('Arrêter la lecture', 'Stop reading', 'Lezen stoppen');
  String get expBtnRedo => _t('Refaire', 'Redo', 'Opnieuw');
  String get expBtnFinish => _t('Terminer', 'Finish', 'Voltooien');

// ── EXP Control ──
  String get expControlTitle => _t('CONTRÔLE EXP', 'EXP CONTROL', 'EXP CONTROLE');
  String get expControlSubtitle => _t('Réception · Expédition', 'Reception · Shipment', 'Ontvangst · Verzending');
  String get expReaderConnected => _t('Connected', 'Connected', 'Verbonden');
  String get expReaderDisconnected => _t('Disconnected', 'Disconnected', 'Verbroken');
  String get expRfidReaderTitle => _t('RFID Reader', 'RFID Reader', 'RFID Lezer');
  String get expNoReaderAvailable => _t('No reader available', 'No reader available', 'Geen lezer beschikbaar');
  String get expScanTitle => _t('Scanner le code d\'export', 'Scan the export code', 'Exportcode scannen');
  String get expScanSubtitleReady => _t('Pointez le scanner DataWedge\nvers le code-barres de réception', 'Point the DataWedge scanner\nat the reception barcode', 'Richt de DataWedge-scanner\nop de ontvangstbarcode');
  String get expScanSubtitleNotReady => _t('Entrez d\'abord le code magasin', 'Enter the store code first', 'Voer eerst de winkelcode in');
  String get expScanInfo => _t('Le scan du code réception affiche automatiquement les articles attendus dans ce colis.', 'Scanning the reception code automatically displays the expected items in this parcel.', 'Het scannen van de ontvangstcode toont automatisch de verwachte artikelen.');
  String get expMagLabel => _t('Code magasin', 'Store code', 'Winkelcode');
  String get expLoadingTitle => _t('Chargement de la réception...', 'Loading reception...', 'Ontvangst laden...');
  String get expErrorTitle => _t('Une erreur est survenue', 'An error occurred', 'Er is een fout opgetreden');
  String get expBtnScanAgain => _t('Scanner à nouveau', 'Scan again', 'Opnieuw scannen');
  String get expBtnLaunchRfid => _t('Lancer le contrôle RFID', 'Launch RFID control', 'RFID-controle starten');
  String get expReceptionFrom => _t('De', 'From', 'Van');
  String get expReceptionTo => _t('Vers', 'To', 'Naar');
  String get expReceptionDate => _t('Expédié le', 'Shipped on', 'Verzonden op');
  String get expReceptionArticle => _t('article', 'item', 'artikel');
  String get expReceptionArticles => _t('articles', 'items', 'artikelen');

  // ── Promo Operations ──
  String get promoTitle => _t('Opérations Commerciales', 'Commercial Operations', 'Commerciële Operaties');
  String get promoRetry => _t('Réessayer', 'Retry', 'Opnieuw proberen');
  String get promoNoOps => _t('Aucune opération commerciale disponible', 'No commercial operations available', 'Geen commerciële operaties beschikbaar');
  String get promoNoOpsFiltered => _t('Aucune opération sur cette période', 'No operations for this period', 'Geen operaties voor deze periode');
  String get promoResetFilter => _t('Réinitialiser le filtre', 'Reset filter', 'Filter resetten');
  String get promoSelectHint => _t('Sélectionnez une ou plusieurs opérations à vérifier', 'Select one or more operations to verify', 'Selecteer een of meer te verifiëren operaties');
  String get promoActive => _t('Active', 'Active', 'Actief');
  String get promoInactive => _t('Inactive', 'Inactive', 'Inactief');
  String get promoAppEnseigne => _t('Application Enseigne', 'Brand Application', 'Merktoepassing');
  String get promoAppProduit => _t('Application Produit', 'Product Application', 'Producttoepassing');
  String get promoUpdateFds => _t('Mettre à jour mes FDS :)', 'Update my FDS :)', 'Mijn FDS bijwerken :)');

// ── Operation Products ──
  String get operationNouveaute => _t('NOUVEAUTÉ', 'NEW', 'NIEUW');
  String get operationFilterNouveautes => _t('les nouveautés', 'New items', 'Nieuwigheden');
  String get operationColArticle => _t('Article', 'Item', 'Artikel');
  String get operationColPvIni => _t('PV Ini', 'Ini. Price', 'Init. Prijs');
  String get operationColPromo => _t('Promo', 'Promo', 'Promo');
  String get operationColStock => _t('Stock', 'Stock', 'Voorraad');
  String get operationNoNouveaute => _t('Aucune nouveauté dans cette opération', 'No new items in this operation', 'Geen nieuwigheden in deze operatie');
  String get operationNoArticle => _t('Aucun article dans cette opération', 'No items in this operation', 'Geen artikelen in deze operatie');

// ── Promo Scan ──
  String get promoScanTitle => _t('Consulter Tarif', 'Check Price', 'Prijs bekijken');
  String get promoScanSubtitle => _t('Scanner un article', 'Scan an item', 'Artikel scannen');
  String get promoScanDialogTitle => _t('Saisir le gencode', 'Enter barcode', 'Streepjescode invoeren');
  String get promoScanHint => _t('Ex: 34544068037110', 'Ex: 34544068037110', 'Bv: 34544068037110');
  String get promoScanCancel => _t('Annuler', 'Cancel', 'Annuleren');
  String get promoScanVerify => _t('Vérifier', 'Verify', 'Verifiëren');
  String get promoScanNoReader => _t('No reader available', 'No reader available', 'Geen lezer beschikbaar');
  String get promoScanLoading => _t('Vérification en cours...', 'Verifying...', 'Verifiëren...');
  String get promoScanWaiting => _t('Scanner un article', 'Scan an item', 'Artikel scannen');
  String get promoScanWaitingSubtitle => _t('Pointez le scanner vers le code-barres\nde l\'article à vérifier', 'Point the scanner at the barcode\nof the item to verify', 'Richt de scanner op de streepjescode\nvan het te verifiëren artikel');
  String get promoScanAgain => _t('Scanner un autre article', 'Scan another item', 'Nog een artikel scannen');
  String get promoReaderConnected => _t('Connected', 'Connected', 'Verbonden');
  String get promoReaderDisconnected => _t('Disconnected', 'Disconnected', 'Verbroken');
  String get promoRfidReaderTitle => _t('RFID Reader', 'RFID Reader', 'RFID Lezer');
  String get promoNoReaderAvailable => _t('No reader available', 'No reader available', 'Geen lezer beschikbaar');

  // ── PVA Control ──
  String get pvaControlTitle => _t('Contrôle PAV', 'PAV Control', 'PAV Controle');
  String get pvaControlSubtitle => _t('Vérification des articles PAV', 'PAV items verification', 'PAV-artikelen verificatie');
  String get pvaReaderConnected => _t('Connecté', 'Connected', 'Verbonden');
  String get pvaReaderDisconnected => _t('Non connecté', 'Not connected', 'Niet verbonden');
  String get pvaReaderDialogTitle => _t('Lecteur RFID', 'RFID Reader', 'RFID Lezer');
  String get pvaNoReaderAvailable => _t('Aucun lecteur disponible', 'No reader available', 'Geen lezer beschikbaar');
  String get pvaScanTitle => _t('Scanner un code PAV', 'Scan a PAV code', 'Scan een PAV-code');
  String get pvaScanSubtitleReady => _t(
      'Scannez le code-barres du support PAV\npour charger les articles à contrôler.',
      'Scan the PAV support barcode\nto load the items to control.',
      'Scan de streepjescode van de PAV-drager\nom de te controleren artikelen te laden.');
  String get pvaScanSubtitleNotReady => _t(
      'Connectez un lecteur RFID\npour activer le scan.',
      'Connect an RFID reader\nto enable scanning.',
      'Verbind een RFID-lezer\nom scannen te activeren.');
  String get pvaNoReaderWarning => _t(
      'Aucun lecteur RFID connecté. Appuyez sur le badge en haut à droite pour en sélectionner un.',
      'No RFID reader connected. Tap the badge at the top right to select one.',
      'Geen RFID-lezer verbonden. Tik op het label rechtsboven om er een te selecteren.');
  String get pvaScanInfo => _t(
      'Pointez le scanner vers le code-barres du support PAV pour démarrer le contrôle.',
      'Point the scanner at the PAV support barcode to start the control.',
      'Richt de scanner op de streepjescode van de PAV-drager om de controle te starten.');
  String get pvaLoadingTitle => _t('Chargement des articles...', 'Loading items...', 'Artikelen laden...');
  String get pvaLoadingCodePrefix => _t('Code : ', 'Code: ', 'Code: ');
  String get pvaErrorTitle => _t('Code PAV introuvable', 'PAV code not found', 'PAV-code niet gevonden');
  String get pvaBtnScanAgain => _t('Scanner à nouveau', 'Scan again', 'Opnieuw scannen');
  String get pvaArticle => _t('article', 'item', 'artikel');
  String get pvaArticles => _t('articles', 'items', 'artikelen');
  String get pvaBtnLaunch => _t('Lancer le contrôle', 'Launch control', 'Controle starten');
  String get pvaNoReaderCannotLaunch => _t(
      'Aucun lecteur RFID connecté. Impossible de lancer le contrôle.',
      'No RFID reader connected. Cannot launch the control.',
      'Geen RFID-lezer verbonden. Kan de controle niet starten.');
  String get pvaTableArticle => _t('Article', 'Item', 'Artikel');
  String get pvaTableSize => _t('Taille', 'Size', 'Maat');
  String get pvaTableQty => _t('Qté', 'Qty', 'Aant.');

  // ── PVA Inventory ──
  String get pvaInventoryTitle => _t('Inventaire PAV', 'PAV Inventory', 'PAV-inventaris');
  String get pvaInventoryRunning => _t('En cours', 'Running', 'Bezig');
  String get pvaInventoryWaiting => _t('En attente', 'Waiting', 'Wachten');
  String get pvaInventoryReaderPrefix => _t('Lecteur : ', 'Reader: ', 'Lezer: ');
  String get pvaInventoryNoReader => _t('Aucun lecteur connecté', 'No reader connected', 'Geen lezer verbonden');
  String get pvaTableExpected => _t('Attendu', 'Expected', 'Verwacht');
  String get pvaTableRead => _t('Lu', 'Read', 'Gelezen');
  String get pvaTableStatus => _t('Statut', 'Status', 'Status');
  String get pvaTableTotal => _t('Total', 'Total', 'Totaal');
  String get pvaTableWaitingScan => _t('En attente du scan...', 'Waiting for scan...', 'Wachten op scan...');
  String get pvaTableConform => _t('Conforme', 'Conform', 'Conform');
  String get pvaTableGap => _t('Écart', 'Gap', 'Verschil');
  String get pvaNoReaderConnectedWarning => _t('Aucun lecteur RFID connecté.', 'No RFID reader connected.', 'Geen RFID-lezer verbonden.');
  String get pvaBtnStart => _t('Démarrer le contrôle', 'Start control', 'Controle starten');
  String get pvaBtnStop => _t('Arrêter le scan', 'Stop scan', 'Scan stoppen');
  String get pvaConformeLabel => _t('conforme', 'conform', 'conform');
  String get pvaGapPrefix => _t('Écart : ', 'Gap: ', 'Verschil: ');
  String get pvaBtnRedo => _t('Refaire', 'Redo', 'Opnieuw');
  String get pvaBtnFinish => _t('Terminer', 'Finish', 'Voltooien');
  // ── Control RFID Menu ──
  String get controlRfidMenuTitle => _t('Contrôle RFID', 'RFID Control', 'RFID Controle');
  String get controlRfidMenuQcTitle => _t('Contrôle Qualité', 'Quality Control', 'Kwaliteitscontrole');
  String get controlRfidMenuQcSubtitle => _t('Vérification qualité des articles', 'Items quality verification', 'Kwaliteitsverificatie van artikelen');
  String get controlRfidMenuExpTitle => _t('Contrôle Export', 'Export Control', 'Export Controle');
  String get controlRfidMenuExpSubtitle => _t('Contrôle des expéditions', 'Shipments control', 'Verzendingscontrole');
  String get controlRfidMenuPvaTitle => _t('Contrôle PAV', 'PAV Control', 'PAV Controle');
  String get controlRfidMenuPvaSubtitle => _t('Vérification des supports PAV', 'PAV supports verification', 'Verificatie van PAV-dragers');
}