// =============================================================================
// CapMobile — Module Swapp — Jeu de test magasins
// -----------------------------------------------------------------------------
// Fonctionnalité : Liste de magasins fictifs pour tester la sélection magasin
//                  et le rechargement stock API (codeMag variable).
// Design         : N/A (données pures).
// UI             : Alimente showStorePickerDialog (ListTile nomMag + codeMag) ;
//                  storeLabelFor → tooltip StoreSelectButton ; codeMag → stock API.
// Spécifications : Fusion avec magasins auth via [resolveMagasins] ; tri par code.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/features/auth/models/collaborateur_model.dart';

/// Magasins de démonstration si l'utilisateur n'a pas de liste auth.
final List<MagasinModel> testMagasins = [
  MagasinModel(codeMag: 24, nomMag: 'Chaussea Mulhouse'),
  MagasinModel(codeMag: 17, nomMag: 'Chaussea Strasbourg'),
  MagasinModel(codeMag: 42, nomMag: 'Chaussea Colmar'),
  MagasinModel(codeMag: 8, nomMag: 'Chaussea Metz'),
  MagasinModel(codeMag: 31, nomMag: 'Chaussea Nancy'),
  MagasinModel(codeMag: 56, nomMag: 'Chaussea Reims'),
  MagasinModel(codeMag: 103, nomMag: 'Chaussea Lyon Part-Dieu'),
  MagasinModel(codeMag: 215, nomMag: 'Chaussea Paris Nation'),
  MagasinModel(codeMag: 400, nomMag: 'Entrepôt RFID Test'),
  MagasinModel(codeMag: 1, nomMag: 'Magasin Central (mock)'),
  MagasinModel(codeMag: 2, nomMag: 'Magasin Nord (mock)'),
];

/// Liste pour le picker : magasins auth + jeu de test (sans doublon de code).
List<MagasinModel> resolveMagasins(List<MagasinModel>? authStores) {
  final byCode = <int, MagasinModel>{};

  for (final store in testMagasins) {
    byCode[store.codeMag] = store;
  }
  if (authStores != null) {
    for (final store in authStores) {
      byCode[store.codeMag] = store;
    }
  }

  final merged = byCode.values.toList()
    ..sort((a, b) => a.codeMag.compareTo(b.codeMag));
  return merged;
}

/// Retourne le libellé magasin pour un code, ou « Mag. XX » par défaut.
String storeLabelFor(int codeMag, List<MagasinModel> stores) {
  for (final store in stores) {
    if (store.codeMag == codeMag) return store.nomMag;
  }
  return 'Mag. $codeMag';
}
