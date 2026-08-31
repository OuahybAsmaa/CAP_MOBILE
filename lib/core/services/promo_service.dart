import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../features/promo/models/promo_model.dart';
import '../api/api_constants.dart';

class PromoService {
  static const String _baseUrl = ApiConstants.baseUrl;

  Future<List<OperationCommerciale>> getOperations(int codeMag) async {
    final uri = Uri.parse(
      '$_baseUrl/api/magasins/$codeMag/operations-commerciales/toutes',
    );
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Erreur chargement opérations');
    }
    final data = jsonDecode(response.body);
    final list = data['operations'] as List;
    return list.map((e) => OperationCommerciale.fromJson(e)).toList();
  }

  Future<List<PromoResult>> verifierPromo({
    required int gencode,
    int codeMag=433,
    required List<int> listOp,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/api/modele/$gencode/mag/$codeMag/',
    ).replace(queryParameters: {
      'listOp': listOp.join(','),
    });

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Erreur vérification promo (${response.statusCode})');
    }

    final raw = jsonDecode(response.body);

    // Cas 1 : réponse déjà une liste JSON
    if (raw is List) {
      return raw
          .map((e) => PromoResult.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Cas 2 : objet indexé
    if (raw is Map) {
      final entries = (raw as Map<String, dynamic>).entries.toList()
        ..sort((a, b) => int.parse(a.key).compareTo(int.parse(b.key)));
      return entries
          .map((e) => PromoResult.fromJson(e.value as Map<String, dynamic>))
          .toList();
    }

    throw Exception('Format de réponse inattendu : ${raw.runtimeType}');
  }

  Future<List<ModeleProduit>> getModelesOperation({
    required int codeMag,
    required int codePromo,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/api/magasins/$codeMag/operations-commerciales/$codePromo/modeles',
    );
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Erreur chargement produits (${response.statusCode})');
    }

    final raw = jsonDecode(response.body);
    if (raw is List) {
      return raw.map((e) => ModeleProduit.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Format de réponse inattendu : ${raw.runtimeType}');
  }

  Future<String> majFds({required int codeMag, required int codeCollab}) async {
    final uri = Uri.parse('$_baseUrl/api/magasins/$codeMag/operations-commerciales/fds/maj');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'codeCollab': codeCollab}),
    );

    if (response.statusCode != 200 && response.statusCode != 422) {
      throw Exception('Erreur mise à jour FDS (${response.statusCode})');
    }

    final data = jsonDecode(response.body);
    return data['message'] ?? 'FDS mises à jour avec succès';
  }

}