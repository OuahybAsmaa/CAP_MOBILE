// Donnees de test de la couche API Swapp.

import 'package:cap_mobile/swapp/models/info_tarif_article_item.dart';

/// Données démo — reproduction capture liste articles Info Tarif.
abstract final class InfoTarifArticleDemoData {
  static List<InfoTarifArticleItem> articlesForOperations(
    Iterable<String> operationCodes,
  ) {
    final codes = operationCodes
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty);
    final codeSet = codes.isEmpty ? null : codes.toSet();
    final all = _allArticles();
    if (codeSet == null) return all;
    return all
        .where(
          (a) =>
              a.operationCodes.isEmpty ||
              a.operationCodes.any(codeSet.contains),
        )
        .toList(growable: false);
  }

  static List<InfoTarifArticleItem> _allArticles() => const [
    InfoTarifArticleItem(
      codeArticle: '52330008',
      prixInitial: 27.99,
      prixPromo: 14,
      stock: 0,
      isNouveaute: true,
      operationCodes: {'3133', '3605', '3717'},
    ),
    InfoTarifArticleItem(
      codeArticle: '53522024',
      prixInitial: 29.99,
      prixPromo: 15,
      stock: 0,
      isNouveaute: true,
      operationCodes: {'3133', '3725'},
    ),
    InfoTarifArticleItem(
      codeArticle: '53522025',
      prixInitial: 29.99,
      prixPromo: 15,
      stock: 0,
      isNouveaute: true,
      operationCodes: {'3133', '3725'},
    ),
    InfoTarifArticleItem(
      codeArticle: '53522026',
      prixInitial: 29.99,
      prixPromo: 15,
      stock: 0,
      isNouveaute: true,
      operationCodes: {'3133', '3727'},
    ),
    InfoTarifArticleItem(
      codeArticle: '53522027',
      prixInitial: 29.99,
      prixPromo: 15,
      stock: 0,
      isNouveaute: true,
      operationCodes: {'3133', '8026'},
    ),
    InfoTarifArticleItem(
      codeArticle: '53522028',
      prixInitial: 27.99,
      prixPromo: 6,
      stock: 1,
      isNouveaute: true,
      operationCodes: {'3133', '3605', '3717', '3725', '3727', '8026'},
    ),
  ];
}
