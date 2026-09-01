// Donnees de test du module produit.

import 'package:cap_mobile/core/apiswap/shared/config/swapp_api_constants.dart';
import 'package:cap_mobile/swapp/models/product_stock_view.dart';

/// Jeu de test — affiché si l'API ne renvoie pas colisDepot / colisDepotResa.
List<ColisDepotChip> demoColisDepotChips() => const [
  ColisDepotChip(
    id: 'demo_resa_0',
    label: '40-46 Je débloque 1 colis de 12 paires.Assortiment running test.',
    isDepotResa: true,
  ),
  ColisDepotChip(
    id: 'demo_depot_0',
    label: '40-46 Je pari sur 1 colis de 12 paires.Assortiment running test.',
    isDepotResa: false,
  ),
];

/// UI : Données affichées avant chargement API (placeholder écran produit).
ProductStockView demoProductStockView() {
  final defaultCode = SwappApiConstants.defaultCodeModele;
  final isGencode =
      defaultCode.length >= 13 && RegExp(r'^\d+$').hasMatch(defaultCode);

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
    colisDepotChips: demoColisDepotChips(),
  );
}
