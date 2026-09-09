import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../api/api_constants.dart';
import '../../features/pva_control/models/pva_model.dart';

// ─────────────────────────────────────────────────────────────
//  SERVICE — Contrôle Support (PVA)
// ─────────────────────────────────────────────────────────────

class PvaService {
  static const String _baseUrl = ApiConstants.digitalStoreBaseUrl;

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept':       'application/json',
    'User-Agent':   'CapMobile/1.0',
  };

  Future<PvaReceptionModel> getReception(String codeSupport) async {
    final uri = Uri.parse(
      '$_baseUrl/api/rfid/receptions/${codeSupport.trim()}',
    );

    try {
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));

      switch (response.statusCode) {
        case 200:
          final List<dynamic> json =
          jsonDecode(response.body) as List<dynamic>;

          final lignes = json
              .map((e) => PvaLigne.fromJson(e as Map<String, dynamic>))
              .toList();

          if (lignes.isEmpty) {
            throw Exception('Aucun article trouvé pour ce code');
          }

          return PvaReceptionModel(
            codeSupport: codeSupport,
            lignes:      lignes,
          );

        case 404:
          throw Exception('Support introuvable (code: $codeSupport)');

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

  Future<String> getCodeModFromEan(String ean) async {
    final uri = Uri.parse('$_baseUrl/api/articles/${ean.trim()}/');
    try {
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json['codeMod']?.toString() ?? '';
      }
      return '';
    } catch (_) {
      return '';
    }
  }
}