import 'package:cap_mobile/core/l10n/app_language.dart';

class AppLocalizations {
  AppLocalizations(this.appLanguage);

  final AppLanguage appLanguage;

  String _t(String fr, String en, String nl) => switch (appLanguage) {
        AppLanguage.fr => fr,
        AppLanguage.en => en,
        AppLanguage.nl => nl,
      };

  // ── Général ──
  String get productTitle => _t('PRODUIT', 'PRODUCT', 'PRODUCT');
  String get productPageTitle => _t('Produit', 'Product', 'Product');
  String get cart => _t('Panier', 'Cart', 'Winkelwagen');
  String get order => _t('Cmd', 'Order', 'Best.');
  String get cancel => _t('Annuler', 'Cancel', 'Annuleren');
  String get validate => _t('Valider', 'Confirm', 'Bevestigen');
  String get you => _t('Vous', 'You', 'Jij');
  String get comingSoon => _t('Section à venir', 'Coming soon', 'Binnenkort beschikbaar');

  // ── Réassort ──
  String get reorderOk => _t('Réassort OK', 'Reorder OK', 'Herbevoorrading OK');
  String get reorderPending =>
      _t('Réassort en attente', 'Reorder pending', 'Herbevoorrading in afwachting');

  // ── Dialogue code article ──
  String get articleCodeTitle => _t('Code art.', 'Art. code', 'Art.code');
  String get articleCodeSubtitle => _t(
        'Code modèle à charger',
        'Model code to load',
        'Modelcode laden',
      );
  String get articleCodeHint => _t('Ex: 56620084', 'Ex: 56620084', 'Bv: 56620084');
  String get articleCodeRequired => _t(
        'Saisissez un code article',
        'Enter an article code',
        'Voer een artikelcode in',
      );
  String get codeRequired =>
      _t('Code requis', 'Code required', 'Code verplicht');

  // ── Navigation bas ──
  String get navStockMag => _t('Stock Mag', 'Store stock', 'Winkelvoorraad');
  String get navStockWeb => _t('Stock Web', 'Web stock', 'Webvoorraad');
  String get navNearby => _t('Alentours', 'Nearby', 'In de buurt');
  String get navReviews => _t('Avis', 'Reviews', 'Beoordelingen');
  String get navReserve => _t('Reserve', 'Reserve', 'Reserveren');

  // ── Stock colonnes ──
  String stockColumnLabel(String key) => switch (key) {
        'taille' => _t('Taille', 'Size', 'Maat'),
        'dispo' => _t('Dispo', 'Avail.', 'Besch.'),
        'transit' => _t('Transit', 'Transit', 'Transit'),
        'picking' => _t('Picking', 'Picking', 'Picking'),
        'vols' => _t('Vols', 'Theft', 'Diefstal'),
        'nv' => _t('N.V.', 'N.S.', 'N.V.'),
        'ew' => _t('E.W.', 'W.G.', 'W.V.'),
        'resas' => _t('Résas', 'Res.', 'Res.'),
        'resaPlus' => _t('Résa+', 'Res.+', 'Res.+'),
        'depot' => _t('Dépôt', 'Warehouse', 'Depot'),
        _ => key,
      };

  String get dispoWeb => _t('Dispo Web', 'Web avail.', 'Web besch.');
  String get pickingShort => _t('Pick.', 'Pick.', 'Pick.');
  String totalCount(int value) =>
      _t('Total $value', 'Total $value', 'Totaal $value');

  /// Plages de tailles API (ex. « Du 40 au 46 »).
  String displaySizeRange(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return raw;

    final duAu = RegExp(
      r'^du\s+(.+?)\s+au\s+(.+?)$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (duAu != null) {
      final from = duAu.group(1)!;
      final to = duAu.group(2)!;
      return _t('Du $from au $to', 'From $from to $to', '$from tot $to');
    }

    final auOnly = RegExp(
      r'^(.+?)\s+au\s+(.+?)$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (auOnly != null) {
      final from = auOnly.group(1)!;
      final to = auOnly.group(2)!;
      return _t('$from au $to', '$from to $to', '$from tot $to');
    }

    return raw;
  }

  /// Coloris (ex. « NOIR/BLEU »).
  String displayColorway(String raw) {
    if (raw.isEmpty) return raw;

    String translateToken(String token) {
      final t = token.trim();
      if (t.isEmpty) return token;
      final upper = t.toUpperCase();
      return switch (upper) {
        'NOIR' => _t('NOIR', 'BLACK', 'ZWART'),
        'BLANC' => _t('BLANC', 'WHITE', 'WIT'),
        'BLEU' => _t('BLEU', 'BLUE', 'BLAUW'),
        'ROUGE' => _t('ROUGE', 'RED', 'ROOD'),
        'VERT' => _t('VERT', 'GREEN', 'GROEN'),
        'GRIS' => _t('GRIS', 'GREY', 'GRIJS'),
        'GRAY' => _t('GRIS', 'GREY', 'GRIJS'),
        'JAUNE' => _t('JAUNE', 'YELLOW', 'GEEL'),
        'ORANGE' => _t('ORANGE', 'ORANGE', 'ORANJE'),
        'ROSE' => _t('ROSE', 'PINK', 'ROZE'),
        'VIOLET' => _t('VIOLET', 'PURPLE', 'PAARS'),
        'MARRON' => _t('MARRON', 'BROWN', 'BRUIN'),
        'BEIGE' => _t('BEIGE', 'BEIGE', 'BEIGE'),
        'MARINE' => _t('MARINE', 'NAVY', 'MARINE'),
        'KAKI' => _t('KAKI', 'KHAKI', 'KHAKI'),
        _ => t,
      };
    }

    return raw
        .split('/')
        .map(translateToken)
        .where((part) => part.isNotEmpty)
        .join('/');
  }

  /// Libellé taille article (ex. « TAILLE UNIQUE », « TU »).
  String displaySizeLabel(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return raw;

    final normalized = trimmed.toUpperCase();
    if (normalized == 'TU' ||
        normalized == 'TAILLE UNIQUE' ||
        normalized == 'ONE SIZE') {
      return _t('Taille unique', 'One size', 'One size');
    }

    return raw;
  }

  /// Type / catégorie produit (ex. « CHAUSSURES », « RUNNING »).
  String displayCategory(String raw) {
    if (raw.isEmpty) return raw;

    var result = raw;
    final replacements = <String, String Function()>{
      r'\bCHAUSSURES?\b': () => _t('Chaussures', 'Footwear', 'Schoenen'),
      r'\bRUNNING\b': () => _t('Running', 'Running', 'Hardlopen'),
      r'\bTRAIL\b': () => _t('Trail', 'Trail', 'Trail'),
      r'\bFOOTBALL\b': () => _t('Football', 'Football', 'Voetbal'),
      r'\bBASKET\b': () => _t('Basket', 'Basketball', 'Basketbal'),
      r'\bTENNIS\b': () => _t('Tennis', 'Tennis', 'Tennis'),
      r'\bTEXTILE\b': () => _t('Textile', 'Apparel', 'Textiel'),
      r'\bVETEMENTS?\b': () => _t('Vêtements', 'Clothing', 'Kleding'),
      r'\bACCESSOIRES?\b': () => _t('Accessoires', 'Accessories', 'Accessoires'),
      r'\bSPORT\b': () => _t('Sport', 'Sport', 'Sport'),
      r'\bFITNESS\b': () => _t('Fitness', 'Fitness', 'Fitness'),
      r'\bNATATION\b': () => _t('Natation', 'Swimming', 'Zwemmen'),
      r'\bOUTDOOR\b': () => _t('Outdoor', 'Outdoor', 'Outdoor'),
    };

    for (final entry in replacements.entries) {
      result = result.replaceAllMapped(
        RegExp(entry.key, caseSensitive: false),
        (_) => entry.value(),
      );
    }

    return result;
  }

  /// Plage ou famille affichée sous le code produit.
  String displaySizeOrRange(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return raw;

    final range = displaySizeRange(trimmed);
    if (range != trimmed) return range;
    return displayCategory(trimmed);
  }

  /// Segments courants (ex. « HOMME / A26 »).
  String displaySegment(String raw) {
    if (raw.isEmpty) return raw;
    return raw
        .replaceAllMapped(
          RegExp(r'\bHOMME\b', caseSensitive: false),
          (_) => _t('HOMME', 'MEN', 'HEREN'),
        )
        .replaceAllMapped(
          RegExp(r'\bFEMME\b', caseSensitive: false),
          (_) => _t('FEMME', 'WOMEN', 'DAMES'),
        )
        .replaceAllMapped(
          RegExp(r'\bENFANT\b', caseSensitive: false),
          (_) => _t('ENFANT', 'KIDS', 'KINDEREN'),
        )
        .replaceAllMapped(
          RegExp(r'\bUNISEXE\b', caseSensitive: false),
          (_) => _t('UNISEXE', 'UNISEX', 'UNISEX'),
        )
        .replaceAllMapped(
          RegExp(r'\bGARÇON\b', caseSensitive: false),
          (_) => _t('GARÇON', 'BOYS', 'JONGEN'),
        )
        .replaceAllMapped(
          RegExp(r'\bGARCON\b', caseSensitive: false),
          (_) => _t('GARÇON', 'BOYS', 'JONGEN'),
        )
        .replaceAllMapped(
          RegExp(r'\bFILLE\b', caseSensitive: false),
          (_) => _t('FILLE', 'GIRLS', 'MEISJE'),
        );
  }

  // ── Avis : onglets ──
  String get giveReview => _t('Donner un avis', 'Give a review', 'Review geven');
  String get manageReviews => _t('Gérer les avis', 'Manage reviews', 'Beoordelingen beheren');

  // ── Avis : formulaire ──
  String get yourRating => _t('Votre note', 'Your rating', 'Uw beoordeling');
  String get reportDefect => _t('Signaler un défaut', 'Report a defect', 'Defect melden');
  String get reportDefectHint => _t(
        'Activez si l\'article présente un problème',
        'Enable if the item has an issue',
        'Activeer als het artikel een probleem heeft',
      );
  String get comment => _t('Commentaire', 'Comment', 'Opmerking');
  String get commentHint => _t(
        'Décrivez votre expérience avec cet article',
        'Describe your experience with this item',
        'Beschrijf uw ervaring met dit artikel',
      );
  String get photo => _t('Photo', 'Photo', 'Foto');
  String get retakePhoto => _t('Reprendre', 'Retake', 'Opnieuw');
  String get openingCamera => _t('Ouverture caméra…', 'Opening camera…', 'Camera openen…');
  String get takePhoto => _t('Prendre une photo', 'Take a photo', 'Foto maken');
  String get takePhotoHint => _t(
        'Utilise la caméra de l\'appareil',
        'Uses the device camera',
        'Gebruikt de camer van het apparaat',
      );
  String get sendReview => _t('Envoyer l\'avis', 'Submit review', 'Review verzenden');
  String get cameraPermissionDenied => _t(
        'Autorisez la caméra pour ajouter une photo.',
        'Allow camera access to add a photo.',
        'Sta cameratoegang toe om een foto toe te voegen.',
      );
  String get cameraOpenFailed => _t(
        'Impossible d\'ouvrir la caméra.',
        'Unable to open the camera.',
        'Kan de camera niet openen.',
      );

  // ── Avis : gestion ──
  String reviewsCount(int count) => _t('$count avis', '$count reviews', '$count beoordelingen');
  String get averageRating => _t('Note moy.', 'Avg. rating', 'Gem. score');
  String get noReviewsForFilter => _t(
        'Aucun avis pour ce filtre',
        'No reviews for this filter',
        'Geen beoordelingen voor dit filter',
      );
  String get defectiveReported => _t(
        'Article signalé défectueux',
        'Item reported as defective',
        'Artikel gemeld als defect',
      );
  String get filterAll => _t('Tous', 'All', 'Alle');
  String get filterPublished => _t('Publiés', 'Published', 'Gepubliceerd');
  String get filterPending => _t('En attente', 'Pending', 'In afwachting');
  String get language => _t('Langue', 'Language', 'Taal');

  // ── Scanner QR caméra ──
  String get scanQrTitle => _t('QR', 'QR', 'QR');
  String get scanQrHint => _t(
        'Cadrez le code',
        'Frame the code',
        'Code in kader',
      );
  String get scanTorch => _t('Flash', 'Flash', 'Flits');
  String get scanDataWedgeHint => _t(
        'Scannez avec le bouton Zebra',
        'Scan with the Zebra trigger',
        'Scan met de Zebra-knop',
      );
  String get scanLoading => _t('Chargement…', 'Loading…', 'Laden…');

  // ── Sélection magasin ──
  String get selectStoreTitle =>
      _t('Choisir un magasin', 'Select a store', 'Winkel kiezen');
  String get storeCodeLabel => _t('Code', 'Code', 'Code');
  String get storeHasStockLabel =>
      _t('Stock disponible', 'Stock available', 'Voorraad beschikbaar');
  String storeStockTotal(int total) =>
      _t('$total en stock', '$total in stock', '$total op voorraad');
  String nearbyRank(int rank) => _t('Rang $rank', 'Rank $rank', 'Rang $rank');
}
