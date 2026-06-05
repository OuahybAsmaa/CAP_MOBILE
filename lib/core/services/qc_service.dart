import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../core/api/api_constants.dart';
import '../../features/QC/models/qc_model.dart';
import '../../features/article/models/article_model.dart';
class QcService {
  static const String _baseUrl = ApiConstants.baseUrl;
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept':       'application/json',
    'User-Agent':   'CapMobile/1.0',
  };
  // ── Étape 1a : gencode → article (codeMod) ─────────────────
  // Même endpoint qu'ArticleService
  Future<String> getCodeModFromGencode(String gencode) async {
    final uri = Uri.parse('$_baseUrl/api/articles/${gencode.trim()}/');
    try {
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final codeMod = json['codeMod'] as String? ?? '';
        if (codeMod.isEmpty) throw Exception('codeMod introuvable');
        return codeMod;
      } else if (response.statusCode == 404) {
        throw Exception('Article introuvable (gencode: $gencode)');
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Pas de connexion réseau');
    } catch (e) { rethrow; }
  }
  // ── Étape 1b : codeMod → liste des colis ───────────────────
  Future<QcProductionModel> getColisByCodeMod(String codeMod) async {
    final uri = Uri.parse(
        '$_baseUrl/api/quality-check/production/${codeMod.trim()}');
    try {
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return QcProductionModel.fromJson(json);
      } else if (response.statusCode == 404) {
        throw Exception('Aucun colis trouvé pour ce code modèle');
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Pas de connexion réseau');
    } catch (e) { rethrow; }
  }
  // ── Étape inventaire : GTIN → article (codeMod + libTaille) ─
  // On réutilise le même endpoint article mais on passe par le GTIN
  // L'API retourne codeMod et libTaille qu'on utilise pour le QC
  Future<ArticleModel?> getArticleByGtin(String gtin) async {
    // Le GTIN est utilisé comme identifiant de recherche
    // L'endpoint /api/articles/{gtin}/ retourne l'article complet
    final uri = Uri.parse('$_baseUrl/api/articles/$gtin/');
    try {
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ArticleModel.fromJson(json);
      }
      // 404 = GTIN inconnu → pas bloquant
      return null;
    } catch (_) {
      return null;
    }
  }
}