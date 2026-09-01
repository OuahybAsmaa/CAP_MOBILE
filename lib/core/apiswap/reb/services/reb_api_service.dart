import 'dart:convert';
import 'dart:io';

import 'package:cap_mobile/swapp/models/reb/reb.dart';
import 'package:http/http.dart' as http;

import '../data/reb_test_data.dart';
import '../mappers/reb_mapper.dart';

/// Point d'acces aux donnees REB. Remplacer uniquement les corps des methodes
/// par les appels HTTP quand le backend sera disponible.
class RebApiService {
  static const _baseUrl = 'https://vstoreapi.chaussea.net/api';

  Future<List<RebItem>> fetchRebs({
    required int codeMag,
    DateTime? du,
    DateTime? au,
    bool enAttente = true,
  }) async {
    final end = au ?? DateTime.now();
    final start = du ?? end.subtract(const Duration(days: 8));
    final uri = Uri.parse('$_baseUrl/magasins/$codeMag/rebs').replace(
      queryParameters: {
        'enAttente': '$enAttente',
        'du': _apiDate(start),
        'au': _apiDate(end),
      },
    );

    try {
      final response = await http
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw Exception(
          _apiMessage(response.body) ??
              'Erreur serveur REB (${response.statusCode})',
        );
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final values = _extractList(decoded);
      return values
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map(RebMapper.itemFromJson)
          .toList(growable: false);
    } on SocketException {
      throw Exception('Impossible de joindre le serveur des remises en banque');
    } on FormatException {
      throw Exception('Réponse REB invalide');
    }
  }

  static String _apiDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}'
      '${date.month.toString().padLeft(2, '0')}'
      '${date.day.toString().padLeft(2, '0')}';

  static List<dynamic> _extractList(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map) {
      for (final key in const ['rebs', 'items', 'data', 'result']) {
        final value = decoded[key];
        if (value is List) return value;
      }
    }
    throw const FormatException('Liste REB absente');
  }

  static String? _apiMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        return decoded['message']?.toString();
      }
    } catch (_) {}
    return null;
  }

  Future<List<RebEncaissementItem>> fetchEncaissements({
    required int codeMag,
    required DateTime date,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return RebMapper.encaissementsFromJson(
      RebTestData.encaissements(),
    ).where((item) => !item.dejaRemis).toList(growable: false);
  }

  Future<RebItem> createReb(RebCreateRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return RebMapper.createdItemFromRequest(request);
  }
}
