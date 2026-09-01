// =============================================================================
// CapMobile — Module Swapp — Handler scan produit
// -----------------------------------------------------------------------------
// Fonctionnalité : Chaîne API après scan (article → modèle → stock web + alentours).
// Design         : Couche métier sans widget direct.
// UI             : Résultat visible dans _ProductHeroCard + _StockTable après scan ;
//                  erreurs remontées via processSwappProductScanUi → SnackBar.
// Spécifications : Résout codeMod/gencode depuis scan ; met à jour nearby.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/core/apiswap/produit/nearby_stock/providers/nearby_stock_provider.dart';
import 'package:cap_mobile/core/apiswap/produit/stock_web/providers/stock_web_provider.dart';
import 'package:cap_mobile/core/apiswap/shared/config/swapp_api_constants.dart';
import 'package:cap_mobile/core/apiswap/produit/providers/swapp_product_provider.dart';
import 'package:cap_mobile/features/article/providers/article_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

bool swappLooksLikeGencode(String code) {
  final trimmed = code.trim();
  return trimmed.length >= 13 && RegExp(r'^\d+$').hasMatch(trimmed);
}

/// Résout un code scanné (gencode / QR) et charge le produit Swapp + stock web.
Future<String?> handleSwappProductScan(
  WidgetRef ref,
  String rawCode, {
  int? codeMag,
}) async {
  final data = rawCode.trim();
  if (data.isEmpty) return null;

  await ref.read(articleProvider.notifier).fetchArticle(data);

  final article = ref.read(articleProvider).article;
  final mag = codeMag ?? SwappApiConstants.defaultCodeMag;
  final resolvedMag = SwappApiConstants.resolveCodeMag(mag);

  final scannedGencode = swappLooksLikeGencode(data)
      ? data
      : (article?.gencode.trim().isNotEmpty == true
            ? article!.gencode.trim()
            : '');

  var codeModele = article?.codeMod.trim();
  if (codeModele == null || codeModele.isEmpty) {
    codeModele = data;
  }

  await ref
      .read(swappProductProvider.notifier)
      .fetchModele(
        codeModele: codeModele,
        codeMag: resolvedMag,
        scannedGencode: scannedGencode.isNotEmpty ? scannedGencode : data,
      );

  final product = ref.read(swappProductProvider).product;
  final stockCode = product?.reference ?? codeModele;
  ref.read(stockWebProvider.notifier).fetchStockWeb(stockCode);

  ref.read(nearbyStockProvider.notifier).clear();

  return scannedGencode.isNotEmpty ? scannedGencode : product?.gencode;
}
