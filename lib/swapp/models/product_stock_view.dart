// =============================================================================
// CapMobile — Module Swapp — Modèle vue produit
// -----------------------------------------------------------------------------
// Fonctionnalité : Représentation UI du produit + stock par taille (magasin).
// Design         : Objet immuable passé aux widgets (carte produit, tableaux).
// UI             : Chaque champ alimente un libellé ou widget de l'écran produit :
//                  reference/colorway/size → ligne 1 hero ; sizeRange/category → L2 ;
//                  segment → L3 ; model/price → Pills ; reassortOk → ReassortChip ;
//                  photoUrl → ProductPhotoCircle ; stockBySize → _StockTable.
// Spécifications : Mapping depuis ArticleModel ou ModeleGlobalModel ;
//                  totaux stock via [stockTotals], colonnes via [visibleStockColumns].
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/core/apiswap/swapp_api_constants.dart';
import 'package:cap_mobile/features/article/models/article_model.dart';

import 'stock_column.dart';

/// Vue produit consolidée — source de données pour toute la carte hero et le tableau.
class ProductStockView {
  /// UI : Texte monospace ligne 1 hero (ex. « 35620066 BLANC/NOIR 40 »).
  final String reference;

  /// API alentours : gencode article pour GET /api/stock/{gencode}/{codeMag}/nearby.
  final String gencode;

  /// UI : Traduit via l10n.displayColorway — ligne 1 hero.
  final String colorway;

  /// UI : Traduit via l10n.displaySizeLabel — ligne 1 hero.
  final String size;

  /// UI : Traduit via l10n.displaySizeOrRange — ligne 2 hero (orange).
  final String sizeRange;

  /// UI : Traduit via l10n.displayCategory — ligne 2 hero (orange).
  final String category;

  /// UI : Pill modèle outline — ligne 3 hero (ex. DURAMO RC2).
  final String model;

  /// UI : Traduit via l10n.displaySegment — ligne 3 hero (bleu).
  final String segment;

  /// UI : Pill prix filled — ligne 3 hero (ex. « 50€ »).
  final double price;

  /// UI : ReassortChip vert (true) ou rouge (false) — ligne 1 hero gauche.
  final bool reassortOk;

  /// UI : Image réseau ProductPhotoCircle — colonne droite hero.
  final String? photoUrl;

  /// UI : réservé header panier (v2) — quantité panier.
  final int cartQty;

  /// UI : réservé header commande (v2) — quantité pré-résa.
  final int orderedQty;

  /// UI : _StockTable — Map[taille][rubrique] → _ValueCircle par cellule.
  final Map<String, Map<String, int>> stockBySize;

  /// UI : _PlusProduitPanel — libellé « PlusP » depuis API modèle (libPlusProduit).
  final String? libPlusProduit;

  const ProductStockView({
    required this.reference,
    this.gencode = '',
    required this.colorway,
    required this.size,
    required this.sizeRange,
    required this.category,
    required this.model,
    required this.segment,
    required this.price,
    required this.reassortOk,
    this.photoUrl,
    this.cartQty = 0,
    this.orderedQty = 0,
    this.stockBySize = const {},
    this.libPlusProduit,
  });

  ProductStockView copyWith({
    String? reference,
    String? gencode,
    String? colorway,
    String? size,
    String? sizeRange,
    String? category,
    String? model,
    String? segment,
    double? price,
    bool? reassortOk,
    String? photoUrl,
    int? cartQty,
    int? orderedQty,
    Map<String, Map<String, int>>? stockBySize,
    String? libPlusProduit,
  }) {
    return ProductStockView(
      reference: reference ?? this.reference,
      gencode: gencode ?? this.gencode,
      colorway: colorway ?? this.colorway,
      size: size ?? this.size,
      sizeRange: sizeRange ?? this.sizeRange,
      category: category ?? this.category,
      model: model ?? this.model,
      segment: segment ?? this.segment,
      price: price ?? this.price,
      reassortOk: reassortOk ?? this.reassortOk,
      photoUrl: photoUrl ?? this.photoUrl,
      cartQty: cartQty ?? this.cartQty,
      orderedQty: orderedQty ?? this.orderedQty,
      stockBySize: stockBySize ?? this.stockBySize,
      libPlusProduit: libPlusProduit ?? this.libPlusProduit,
    );
  }

  /// UI : Ligne totaux en-tête _StockTable (somme par colonne visible).
  Map<String, int> get stockTotals {
    final totals = {
      for (final column in StockColumns.metrics) column.key: 0,
    };
    for (final line in stockBySize.values) {
      for (final entry in line.entries) {
        totals[entry.key] = (totals[entry.key] ?? 0) + entry.value;
      }
    }
    return totals;
  }

  /// UI : Colonnes affichées dans _StockTable (en-tête + lignes taille).
  List<StockColumnDef> get visibleStockColumns =>
      StockColumns.visibleFor(stockTotals);

  /// Construction depuis l'API article (scan gencode).
  factory ProductStockView.fromArticle(ArticleModel article, String photoUrl) {
    final category = article.libTheme.isNotEmpty
        ? article.libTheme
        : article.libFamille;

    return ProductStockView(
      reference: article.codeMod.isNotEmpty ? article.codeMod : article.gencode,
      gencode: article.gencode,
      colorway: article.libColoris.toUpperCase(),
      size: article.libTaille,
      sizeRange: article.libFamille.isNotEmpty
          ? article.libFamille
          : article.libRayon,
      category: category,
      model: article.libArticle,
      segment: [
        if (article.libRayon.isNotEmpty) article.libRayon.toUpperCase(),
        if (article.libSaison.isNotEmpty) article.libSaison,
      ].join(' / '),
      price: article.prixVente,
      reassortOk: true,
      photoUrl: photoUrl,
      libPlusProduit: article.libPlusProduit,
    );
  }
}

/// UI : Données affichées avant chargement API (placeholder écran produit).
ProductStockView demoProductStockView() {
  final defaultCode = SwappApiConstants.defaultCodeModele;
  final isGencode = defaultCode.length >= 13 && RegExp(r'^\d+$').hasMatch(defaultCode);

  return ProductStockView(
    reference: defaultCode,
    gencode: isGencode ? defaultCode : '',
    colorway: 'BLANC/NOIR',
    size: '40',
    sizeRange: 'Du 40 au 46',
    category: 'Running',
    model: 'DURAMO RC2',
    segment: 'HOMME / A26',
    price: 49.99,
    reassortOk: true,
    photoUrl: SwappApiConstants.productPhotoUrl(
      isGencode && defaultCode.length >= 8
          ? defaultCode.substring(0, 8)
          : defaultCode,
    ),
    stockBySize: const {
      '40': {
        'dispo': 0,
        'transit': 0,
        'picking': 0,
        'vols': 0,
        'nv': 0,
        'ew': 0,
        'resas': 0,
        'resaPlus': 0,
        'depot': 0,
      },
      '41': {
        'dispo': 0,
        'transit': 0,
        'picking': 0,
        'vols': 0,
        'nv': 0,
        'ew': 0,
        'resas': 0,
        'resaPlus': 0,
        'depot': 0,
      },
      '42': {
        'dispo': 0,
        'transit': 0,
        'picking': 0,
        'vols': 0,
        'nv': 0,
        'ew': 0,
        'resas': 0,
        'resaPlus': 0,
        'depot': 0,
      },
      '43': {
        'dispo': 0,
        'transit': 0,
        'picking': 0,
        'vols': 0,
        'nv': 0,
        'ew': 0,
        'resas': 0,
        'resaPlus': 0,
        'depot': 0,
      },
      '44': {
        'dispo': 0,
        'transit': 0,
        'picking': 0,
        'vols': 0,
        'nv': 0,
        'ew': 0,
        'resas': 0,
        'resaPlus': 0,
        'depot': 0,
      },
      '45': {
        'dispo': 0,
        'transit': 0,
        'picking': 0,
        'vols': 0,
        'nv': 0,
        'ew': 0,
        'resas': 0,
        'resaPlus': 0,
        'depot': 0,
      },
      '46': {
        'dispo': 0,
        'transit': 0,
        'picking': 0,
        'vols': 0,
        'nv': 0,
        'ew': 0,
        'resas': 0,
        'resaPlus': 0,
        'depot': 0,
      },
    },
  );
}
