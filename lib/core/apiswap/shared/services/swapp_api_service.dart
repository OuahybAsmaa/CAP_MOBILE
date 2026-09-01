// =============================================================================
// CapMobile — API Swapp — Service HTTP store-api
// -----------------------------------------------------------------------------

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:cap_mobile/core/apiswap/models/modele_global_model.dart';
import 'package:cap_mobile/core/apiswap/models/nearby_stock_item.dart';
import 'package:cap_mobile/core/apiswap/models/product_review_item.dart';
import 'package:cap_mobile/core/apiswap/models/stock_web_item.dart';
import 'package:cap_mobile/core/apiswap/shared/config/swapp_api_constants.dart';

/// Client HTTP pour les endpoints Swapp (modèle global, stock web).
class SwappApiService {
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'CapMobile/1.0',
    'Authorization': 'Bearer ${SwappApiConstants.bearerToken}',
  };

  /// Charge fiche produit + listePrix (stock par taille) pour un magasin.
  Future<ModeleGlobalModel> fetchModeleGlobal({
    required String codeModele,
    int codeMag = SwappApiConstants.defaultCodeMag,
  }) async {
    final uri = Uri.parse(
      SwappApiConstants.modeleGlobalUrl(codeModele.trim(), codeMag),
    );

    try {
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));

      switch (response.statusCode) {
        case 200:
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          return ModeleGlobalModel.fromJson(json);
        case 401:
          throw Exception('Token API invalide ou expiré');
        case 404:
          throw Exception('Modèle introuvable ($codeModele)');
        default:
          throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Pas de connexion réseau — vérifiez le Wi-Fi');
    } catch (e) {
      rethrow;
    }
  }

  /// Charge stock web SFS (disponibilité entrepôt) par taille.
  Future<List<StockWebItem>> fetchStockWeb({required String codeModele}) async {
    final uri = Uri.parse(SwappApiConstants.stockWebUrl(codeModele.trim()));

    try {
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));

      switch (response.statusCode) {
        case 200:
          final json = jsonDecode(response.body);
          if (json is! List) {
            throw Exception('Réponse stock web invalide');
          }
          return json
              .whereType<Map<String, dynamic>>()
              .map(StockWebItem.fromJson)
              .toList();
        case 401:
          throw Exception('Token API invalide ou expiré');
        case 404:
          throw Exception('Stock web introuvable ($codeModele)');
        default:
          throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Pas de connexion réseau — vérifiez le Wi-Fi');
    } catch (e) {
      rethrow;
    }
  }

  /// Charge les magasins proches et leur stock par taille pour un article (gencode).
  Future<List<NearbyStoreStock>> fetchNearbyStock({
    required String codeArticle,
    required int codeMag,
  }) async {
    final article = codeArticle.trim();
    final mag = SwappApiConstants.resolveCodeMag(codeMag);
    final uri = Uri.parse(SwappApiConstants.nearbyStockUrl(article, mag));

    try {
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));

      switch (response.statusCode) {
        case 200:
          final json = jsonDecode(response.body);
          if (json is! List) {
            throw Exception('Réponse stock alentours invalide');
          }
          return json
              .whereType<Map<String, dynamic>>()
              .toList()
              .asMap()
              .entries
              .map(
                (entry) =>
                    NearbyStoreStock.fromJson(entry.value, rank: entry.key + 1),
              )
              .toList();
        case 401:
          throw Exception('Token API invalide ou expiré');
        case 404:
          throw Exception(
            _readApiMessage(response.body) ?? 'Article introuvable ($article)',
          );
        default:
          throw Exception(
            _readApiMessage(response.body) ??
                'Erreur serveur: ${response.statusCode}',
          );
      }
    } on SocketException {
      throw Exception('Pas de connexion réseau — vérifiez le Wi-Fi');
    }
  }

  /// Charge les avis d'un article pour un collaborateur donné.
  Future<List<ProductReviewItem>> fetchProductReviews({
    required String codeArticle,
    required int codeCollab,
  }) async {
    final article = codeArticle.trim();
    final uri = Uri.parse(
      SwappApiConstants.modeleReviewUrl(article, codeCollab),
    );

    try {
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));

      switch (response.statusCode) {
        case 200:
          final json = jsonDecode(response.body);
          if (json is! List) {
            throw Exception('Réponse avis invalide');
          }
          return json
              .whereType<Map>()
              .map(
                (entry) => ProductReviewItem.fromJson(
                  Map<String, dynamic>.from(entry),
                ),
              )
              .toList();
        case 401:
          throw Exception('Token API invalide ou expiré');
        case 404:
          return const [];
        default:
          throw Exception(
            _readApiMessage(response.body) ??
                'Erreur serveur: ${response.statusCode}',
          );
      }
    } on SocketException {
      throw Exception('Pas de connexion réseau — vérifiez le Wi-Fi');
    }
  }

  String? _readApiMessage(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return null;
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map && decoded['message'] != null) {
        return decoded['message'].toString();
      }
    } catch (_) {}
    return null;
  }
}
