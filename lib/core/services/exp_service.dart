import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../core/api/api_constants.dart';
import '../../../features/exp_control/models/exp_model.dart';
import '../../../features/article/models/article_model.dart';

// ─────────────────────────────────────────────────────────────
//  SERVICE — Contrôle EXP
// ─────────────────────────────────────────────────────────────

class ExpService {
  static const String _baseUrl = ApiConstants.baseUrl;

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept':       'application/json',
    'User-Agent':   'CapMobile/1.0',
  };

  Future<ExpReceptionModel> getReceptionDetails(
      String codeRecep, String codeMag) async {
    final uri = Uri.parse(
      '$_baseUrl/api/rfid/receptions/${codeRecep.trim()}/${codeMag.trim()}/details',
    );

    try {
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));

      switch (response.statusCode) {
        case 200:
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          final model = ExpReceptionModel.fromJson(json);
          if (model.lignes.isEmpty) {
            throw Exception('Aucun article trouvé pour cette réception');
          }
          return model;

        case 404:
          throw Exception('Réception introuvable (code: $codeRecep)');

        default:
          throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Pas de connexion réseau');
    } on TimeoutException {
      throw Exception('Délai dépassé, réessayez');
    } catch (e) {
      rethrow;
    }
  }


  Future<ArticleModel?> getArticleByGtin(String gtin) async {
    final uri = Uri.parse('$_baseUrl/api/articles/$gtin/');

    try {
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ArticleModel.fromJson(json);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}