import 'dart:convert';
import 'dart:io';

import 'package:cap_mobile/core/api/api_constants.dart';
import 'package:cap_mobile/swapp/models/info_tarif_article_item.dart';
import 'package:cap_mobile/swapp/models/info_tarif_item.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../mappers/tarif_mapper.dart';

class TarifApiService {
  static const _jsonHeaders = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  Future<List<InfoTarifItem>> fetchOperations({int? codeMag}) async {
    final magasin = codeMag != null && codeMag > 0 ? codeMag : 26;
    final uri = Uri.parse(
      ApiConstants.apiUrl(
        '/api/magasins/$magasin/operations-commerciales/fds',
      ),
    );
    try {
      final response = await http
          .get(uri, headers: _jsonHeaders)
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw Exception(
          _message(response.body) ??
              'Erreur Info Tarif (${response.statusCode})',
        );
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final rawOperations = decoded is Map ? decoded['operations'] : null;
      if (rawOperations is! List) {
        throw const FormatException('Liste operations absente');
      }
      return rawOperations
          .whereType<Map>()
          .map((json) => Map<String, dynamic>.from(json))
          .map(TarifMapper.operation)
          .where((operation) => operation.code.isNotEmpty)
          .toList(growable: false)
        ..sort((a, b) => b.dateDebut.compareTo(a.dateDebut));
    } on SocketException {
      throw Exception('Impossible de joindre le serveur Info Tarif');
    } on FormatException {
      throw Exception('Réponse Info Tarif invalide');
    }
  }

  Future<void> updateFds({int? codeMag, required int codeCollab}) async {
    final magasin = codeMag != null && codeMag > 0 ? codeMag : 26;
    if (codeCollab <= 0) {
      throw Exception('Code utilisateur connecté invalide');
    }
    final uri = Uri.parse(
      ApiConstants.apiUrl(
        '/api/magasins/$magasin/operations-commerciales/fds/maj',
      ),
    );
    final requestBody = {'codeCollab': codeCollab, 'force': true};
    try {
      debugPrint(
        '[INFO_TARIF][FDS][POST] url=$uri body=${jsonEncode(requestBody)}',
      );
      final response = await http
          .post(
            uri,
            headers: _jsonHeaders,
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));
      debugPrint(
        '[INFO_TARIF][FDS][RESPONSE] status=${response.statusCode} '
        'body=${_traceBody(response.body)}',
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          _message(response.body) ??
              'Erreur mise à jour FDS (${response.statusCode})',
        );
      }
    } on SocketException {
      debugPrint('[INFO_TARIF][FDS][ERROR] serveur inaccessible: $uri');
      throw Exception('Impossible de joindre le serveur Info Tarif');
    } catch (error) {
      debugPrint('[INFO_TARIF][FDS][ERROR] $error');
      rethrow;
    }
  }

  static String _traceBody(String body) {
    final normalized = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 500) return normalized;
    return '${normalized.substring(0, 500)}…';
  }

  static String? _message(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) return decoded['message']?.toString();
    } catch (_) {}
    return null;
  }

  Future<List<InfoTarifArticleItem>> fetchArticles({
    required int codeMag,
    required List<InfoTarifItem> operations,
  }) async {
    final responses = await Future.wait(
      operations.map((operation) async {
        final uri = Uri.parse(
          ApiConstants.apiUrl(
            '/api/magasins/$codeMag/operations-commerciales/'
            '${Uri.encodeComponent(operation.codePromo)}/modeles',
          ),
        );
        debugPrint(
          '[INFO_TARIF][MODELES][GET] codeMag=$codeMag '
          'codePromo=${operation.codePromo} url=$uri',
        );
        final response = await http
            .get(uri, headers: _jsonHeaders)
            .timeout(const Duration(seconds: 20));
        debugPrint(
          '[INFO_TARIF][MODELES][RESPONSE] '
          'codePromo=${operation.codePromo} status=${response.statusCode} '
          'body=${_traceBody(response.body)}',
        );
        if (response.statusCode != 200) {
          throw Exception(
            _message(response.body) ??
                'Erreur modèles opération ${operation.codePromo} '
                    '(${response.statusCode})',
          );
        }
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final values = _extractModels(decoded);
        return values
            .whereType<Map>()
            .map((json) => Map<String, dynamic>.from(json))
            .map(TarifMapper.article)
            .where((article) => article.codeArticle.isNotEmpty)
            .toList(growable: false);
      }),
    );
    final unique = <String, InfoTarifArticleItem>{};
    for (final articles in responses) {
      for (final article in articles) {
        unique[article.codeArticle] = article;
      }
    }
    return unique.values.toList(growable: false);
  }

  static List<dynamic> _extractModels(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map) {
      for (final key in const ['modeles', 'models', 'items', 'data', 'result']) {
        final value = decoded[key];
        if (value is List) return value;
      }
    }
    throw const FormatException('Liste modeles absente');
  }
}
