// =============================================================================
// CapMobile — Module Swapp — Modèle article Info Tarif
// -----------------------------------------------------------------------------
// Fonctionnalité : Ligne article tarif (PV ini, promo, stock) — écran liste.
// Design         : Objet immuable — mapping futur JSON API tarifs articles.
// UI             : InfoTarifArticlesPage (photo, ref, pastilles prix/stock).
// Spécifications : Données démo [InfoTarifArticleDemoData] en attendant l'API ;
//                  photo produit résolue via SwappApiConstants.productPhotoUrl.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/core/apiswap/shared/config/swapp_api_constants.dart';

/// Article tarifaire — une ligne de la liste « Info Tarif » (refs / articles).
class InfoTarifArticleItem {
  /// Code article / référence (ex. « 52330008 »).
  final String codeArticle;

  /// Prix vente initial (€).
  final double prixInitial;

  /// Prix promo (€).
  final double prixPromo;

  /// Stock magasin.
  final int stock;

  /// URL photo produit (optionnel).
  final String? photoUrl;

  /// Codes opérations auxquelles l'article est rattaché (filtre démo).
  final Set<String> operationCodes;

  /// Nouveauté — affiche le badge « NEW » devant le PV initial.
  final bool isNouveaute;

  const InfoTarifArticleItem({
    required this.codeArticle,
    required this.prixInitial,
    required this.prixPromo,
    required this.stock,
    this.photoUrl,
    this.operationCodes = const {},
    this.isNouveaute = false,
  });

  /// Code modèle photo — 8 premiers caractères du code article.
  String get codeModele {
    final code = codeArticle.trim();
    return code.length >= 8 ? code.substring(0, 8) : code;
  }

  /// URL photo réelle — [photoUrl] si fournie, sinon image produit store-api.
  String get resolvedPhotoUrl {
    final custom = photoUrl?.trim();
    if (custom != null && custom.isNotEmpty) return custom;
    return SwappApiConstants.productPhotoUrl(codeModele);
  }

  /// Affichage prix initial — « 27.99€ ».
  String get prixInitialLabel =>
      '${prixInitial.toStringAsFixed(prixInitial.truncateToDouble() == prixInitial ? 0 : 2)}€';

  /// Affichage prix promo — « 14€ » ou « 14.99€ ».
  String get prixPromoLabel {
    final v = prixPromo;
    if (v.truncateToDouble() == v) return '${v.toInt()}€';
    return '${v.toStringAsFixed(2)}€';
  }

  factory InfoTarifArticleItem.fromJson(Map<String, dynamic> json) {
    return InfoTarifArticleItem(
      codeArticle:
          '${json['codeMod'] ?? json['codeModele'] ?? json['codeArticle'] ?? json['gencode'] ?? ''}'
              .trim(),
      prixInitial: _toDouble(
        json['pvInitial'] ??
            json['prixInitial'] ??
            json['pvIni'] ??
            json['prixVenteInitial'],
      ),
      prixPromo: _toDouble(
        json['prixPromo'] ?? json['pvPromo'] ?? json['prixFds'] ?? json['promo'],
      ),
      stock: _toInt(json['stock'] ?? json['stockMag'] ?? json['qteStock']),
      photoUrl: (json['photoUrl'] ?? json['imageUrl'])?.toString(),
      operationCodes: _parseOpCodes(json['operationCodes']),
      isNouveaute: json['isNouveaute'] == true || json['nouveaute'] == true,
    );
  }

  static double _toDouble(Object? raw) {
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw.replaceAll(',', '.')) ?? 0;
    return 0;
  }

  static int _toInt(Object? raw) {
    if (raw is num) return raw.toInt();
    return int.tryParse('${raw ?? ''}') ?? 0;
  }

  static Set<String> _parseOpCodes(Object? raw) {
    if (raw is List) {
      return raw.map((e) => '$e'.trim()).where((s) => s.isNotEmpty).toSet();
    }
    return const {};
  }
}
