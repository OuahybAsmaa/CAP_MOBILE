// =============================================================================
// CapMobile — Module Swapp — Modèle Info OT
// -----------------------------------------------------------------------------
// Fonctionnalité : Ligne ordre de transfert (OT) — article, quantité, magasin.
// Design         : Objet immuable — mapping futur JSON API store.
// UI             : InfoOtPage (table Article · Qté · Magasin).
// Spécifications : Données démo [InfoOtDemoData] en attendant l'API.
// Auteur         : H.AMIZIANI
// =============================================================================

/// Ligne OT — un article dans un ordre de transfert.
class InfoOtItem {
  /// Identifiant OT (ex. « OT-2026-0142 »).
  final String otId;

  /// Code article / gencode.
  final String codeArticle;

  /// Libellé court (optionnel).
  final String? libelle;

  /// Quantité demandée.
  final int quantite;

  /// Code magasin destination ou origine.
  final int codeMagasin;

  /// Libellé magasin affiché.
  final String libelleMagasin;

  const InfoOtItem({
    required this.otId,
    required this.codeArticle,
    this.libelle,
    required this.quantite,
    required this.codeMagasin,
    required this.libelleMagasin,
  });

  String get id => '$otId-$codeArticle';

  /// Parsing JSON API — à brancher quand l'endpoint sera disponible.
  ///
  /// Exemple attendu :
  /// `{ "otId": "OT-2026-0142", "codeArticle": "52330008", "libelle": "...",
  ///    "quantite": 2, "codeMagasin": 42, "libelleMagasin": "CAP 042" }`
  factory InfoOtItem.fromJson(Map<String, dynamic> json) {
    return InfoOtItem(
      otId: '${json['otId'] ?? json['numOt'] ?? ''}'.trim(),
      codeArticle: '${json['codeArticle'] ?? json['gencode'] ?? ''}'.trim(),
      libelle: json['libelle']?.toString(),
      quantite: (json['quantite'] ?? json['qte'] as num?)?.toInt() ?? 0,
      codeMagasin:
          (json['codeMagasin'] ?? json['codeMag'] as num?)?.toInt() ?? 0,
      libelleMagasin: '${json['libelleMagasin'] ?? json['magasin'] ?? ''}'
          .trim(),
    );
  }
}
