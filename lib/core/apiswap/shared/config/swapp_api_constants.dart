// =============================================================================
// CapMobile — API Swapp — Constantes endpoints et valeurs par défaut
// -----------------------------------------------------------------------------
// Fonctionnalité : URLs store-api, token Bearer, codeMag/codeModèle par défaut.
// Design         : N/A (configuration statique).
// UI             : defaultCodeMag → magasin initial ; productPhotoUrl → ProductPhotoCircle ;
//                  modeleGlobalUrl/stockWebUrl → données hero + _StockTable.
// Spécifications : Base URL depuis ApiConstants ; photo JPG via codeModele ;
//                  stock web endpoint /api/stock/{code}/sfs.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/core/api/api_constants.dart';
import 'package:cap_mobile/features/auth/models/collaborateur_model.dart';

/// Constantes réseau et valeurs par défaut du module Swapp / store-api.
class SwappApiConstants {
  SwappApiConstants._();

  /// Magasin par défaut (Chaussea Mulhouse en test).
  static const int defaultCodeMag = 26;

  /// Code magasin effectif — ignore 0/null (auth incomplet).
  static int resolveCodeMag(int? codeMag, {int fallback = defaultCodeMag}) {
    if (codeMag != null && codeMag > 0) return codeMag;
    return fallback;
  }

  /// Magasin depuis le profil collaborateur (codeMag ou premier magasin auth).
  static int resolveCodeMagFromCollab(
    CollaborateurModel? collab, {
    int fallback = defaultCodeMag,
  }) {
    if (collab == null) return fallback;
    if (collab.codeMag > 0) return collab.codeMag;
    for (final store in collab.mags) {
      if (store.codeMag > 0) return store.codeMag;
    }
    return fallback;
  }

  /// Code modèle de démonstration si aucun produit chargé.
  static const String defaultCodeModele = '36330033010240';

  /// Token JWT store-api (header Authorization: Bearer).
  static const String bearerToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJjb2RlQ29sbGFiIjoxNTQsInRva2VuIjoiYzA1MDQ0ZDUtNDA1OS00ODlmLWEyZjMtZWUzOGIzNGI3NzkxIiwiaWF0IjoxNzg3NDQ1MjI1LCJleHAiOjE3ODc0NDg4MjV9.bFeLsy-YKwsrXy1qrjF8SqLNk798MMxvlEAWyzyR1g4';

  /// GET modèle global + stock magasin pour un codeMag donné.
  static String modeleGlobalUrl(String codeModele, int codeMag) =>
      '${ApiConstants.digitalStoreBaseUrl}/api/modele/$codeModele/mag/$codeMag/global';

  /// URL image produit (JPEG) sur le serveur.
  static String productPhotoUrl(String codeModele) =>
      '${ApiConstants.digitalStoreBaseUrl}/api/image/produit/$codeModele.jpg';

  /// GET stock web SFS (Ship From Store) par taille.
  static String stockWebUrl(String codeModele) =>
      '${ApiConstants.digitalStoreBaseUrl}/api/stock/$codeModele/sfs';

  /// GET stock magasins alentours (gencode + magasin de référence utilisateur).
  static String nearbyStockUrl(String codeArticle, int codeMag) =>
      '${ApiConstants.digitalStoreBaseUrl}/api/stock/$codeArticle/$codeMag/nearby';

  /// GET avis produit par code article (gencode) et code collaborateur.
  static String modeleReviewUrl(String codeArticle, int codeCollab) =>
      '${ApiConstants.digitalStoreBaseUrl}/api/modele/$codeArticle/review/$codeCollab';

  // -------------------------------------------------------------------------
  // Remises en banque
  // Les routes sont centralisées ici : si le contrat backend change, aucune
  // page Flutter ni aucun modèle métier ne devra être modifié.
  // -------------------------------------------------------------------------
  static String rebsUrl(int codeMag) =>
      '${ApiConstants.digitalStoreBaseUrl}/api/rebs/$codeMag';

  static String rebEncaissementsUrl(int codeMag, DateTime date) {
    final day = date.toIso8601String().split('T').first;
    return '${ApiConstants.digitalStoreBaseUrl}/api/rebs/$codeMag/encaissements?date=$day';
  }
}
