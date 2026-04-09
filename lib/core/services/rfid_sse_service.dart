import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../features/SSE/models/rfid_sse_model.dart';
import '../api/api_constants.dart';

// ──────────────────────────────────────────────────────────────
//  SERVICE
// ──────────────────────────────────────────────────────────────
class RfidSseService {
  static const String _baseUrl = ApiConstants.baseUrl;

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept':       'application/json',
    'User-Agent':   'CapMobile/1.0',
  };

  // ── POST — Ajouter un scan RFID SSE ────────────────────────
  Future<bool> addRfidSse({
    required String gencodeRfid,
    required String gencodeCh,
    required String epc,
    required int    codeCollab,
    int    codeMag   = 400,
    String codeMotif = '8',
  }) async {
    final uri  = Uri.parse('$_baseUrl/api/rfid/sse');
    final body = jsonEncode({
      'gencodeRfid': gencodeRfid,
      'gencodeCh':   gencodeCh,
      'epc':         epc,
      'codeMag':     codeMag,
      'codeCollab':  codeCollab,
      'codeMotif':   codeMotif,
    });

    try {
      final response = await http
          .post(uri, headers: _headers, body: body)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json['success'] == true;
      }
      throw Exception('Erreur serveur POST SSE: ${response.statusCode}');
    } on SocketException {
      throw Exception('Pas de connexion réseau');
    } catch (e) {
      rethrow;
    }
  }

  // ── GET — Récupérer la liste des RFID SSE ──────────────────
  Future<List<RfidSseEntry>> getRfidSseList({
    required int codeMag,
    required int codeCollab,
    int nbLig = 500,
  }) async {
    final uri = Uri.parse(
        '$_baseUrl/api/rfid/sse/$codeMag/$codeCollab/$nbLig/');

    try {
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        return list
            .map((e) => RfidSseEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Erreur serveur GET SSE: ${response.statusCode}');
    } on SocketException {
      throw Exception('Pas de connexion réseau');
    } catch (e) {
      rethrow;
    }
  }
}