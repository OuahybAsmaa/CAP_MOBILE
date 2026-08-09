// =============================================================================
// CapMobile — Service recherche client store-api
// -----------------------------------------------------------------------------

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../apiswap/swapp_api_constants.dart';
import 'client_api_constants.dart';
import 'models/client_item.dart';

class ClientSearchQuery {
  final String gsm;
  final String nom;
  final String prenom;
  final String email;
  final int limit;
  final int? codeMag;

  const ClientSearchQuery({
    this.gsm = '',
    this.nom = '',
    this.prenom = '',
    this.email = '',
    this.limit = 10,
    this.codeMag,
  });

  bool get isEmpty =>
      gsm.trim().isEmpty &&
      nom.trim().isEmpty &&
      prenom.trim().isEmpty &&
      email.trim().isEmpty;
}

class ClientService {
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'CapMobile/1.0',
        'Authorization': 'Bearer ${SwappApiConstants.bearerToken}',
      };

  Future<List<ClientItem>> searchClients(ClientSearchQuery query) async {
    if (query.isEmpty) {
      throw Exception('Saisissez au moins un critère de recherche');
    }

    try {
      final uri = ClientApiConstants.searchUrl(
        gsm: query.gsm,
        nom: query.nom,
        prenom: query.prenom,
        email: query.email,
        limit: query.limit,
        codeMag: query.codeMag,
      );

      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return _parseList(response.body).take(query.limit).toList();
      }

      if (response.statusCode == 404) {
        return _filterMock(query);
      }

      throw Exception(
        _readMessage(response.body) ??
            'Erreur serveur (${response.statusCode})',
      );
    } on SocketException {
      return _filterMock(query);
    } catch (e) {
      if (e is Exception && e.toString().contains('Saisissez')) rethrow;
      return _filterMock(query);
    }
  }

  List<ClientItem> _parseList(String body) {
    final decoded = jsonDecode(body);
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((e) => ClientItem.fromJson(Map<String, dynamic>.from(e)))
          .where((c) => c.lastName.isNotEmpty || c.firstName.isNotEmpty)
          .toList();
    }
    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      for (final key in ['clients', 'resultat', 'data', 'items']) {
        final nested = map[key];
        if (nested is List) {
          return nested
              .whereType<Map>()
              .map((e) => ClientItem.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      }
    }
    throw Exception('Réponse client invalide');
  }

  String? _readMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['message'] != null) {
        return decoded['message'].toString();
      }
    } catch (_) {}
    return null;
  }

  List<ClientItem> _filterMock(ClientSearchQuery query) {
    Iterable<ClientItem> results = _mockClients;

    final gsm = query.gsm.trim();
    final nom = query.nom.trim().toLowerCase();
    final prenom = query.prenom.trim().toLowerCase();
    final email = query.email.trim().toLowerCase();

    if (gsm.isNotEmpty) {
      results = results.where(
        (c) => c.phone.replaceAll(' ', '').contains(gsm.replaceAll(' ', '')),
      );
    }
    if (nom.isNotEmpty) {
      results = results.where(
        (c) => c.lastName.toLowerCase().contains(nom),
      );
    }
    if (prenom.isNotEmpty) {
      results = results.where(
        (c) => c.firstName.toLowerCase().contains(prenom),
      );
    }
    if (email.isNotEmpty) {
      results = results.where(
        (c) => c.email.toLowerCase().contains(email),
      );
    }

    return results.take(query.limit).toList();
  }

  static const List<ClientItem> _mockClients = [
    ClientItem(
      id: '1',
      civility: 'Mm',
      lastName: 'STEPHANE',
      firstName: 'ELISABETH',
      email: 'elizabeth.stephane@gmail.com',
      phone: '06 12 34 56 78',
      birthDate: '12/06/1982',
      birthCity: 'BAR LE DUC',
      address: '12 rue des Lilas — BAR LE DUC',
      storeLabel: 'Chaussea Mulhouse',
      loyaltyPercent: 100,
      avatarKind: ClientAvatarKind.leaves,
    ),
    ClientItem(
      id: '2',
      civility: 'M.',
      lastName: 'MARTIN',
      firstName: 'PAUL',
      email: 'paul.martin@outlook.fr',
      phone: '07 98 76 54 32',
      birthDate: '03/11/1975',
      birthCity: 'MULHOUSE',
      address: '8 avenue de la Gare — MULHOUSE',
      storeLabel: 'Chaussea Mulhouse',
      loyaltyPercent: 85,
      avatarKind: ClientAvatarKind.branch,
    ),
    ClientItem(
      id: '3',
      civility: 'Mm',
      lastName: 'MARTIN',
      firstName: 'SOPHIE',
      email: 'sophie.dubois@yahoo.fr',
      phone: '06 55 44 33 22',
      birthDate: '21/02/1990',
      birthCity: 'COLMAR',
      address: '5 place Rapp — COLMAR',
      storeLabel: 'Chaussea Colmar',
      loyaltyPercent: 100,
      avatarKind: ClientAvatarKind.rose,
    ),
    ClientItem(
      id: '4',
      civility: 'M.',
      lastName: 'MARTIN',
      firstName: 'LUC',
      email: 'l.bernard@gmail.com',
      phone: '06 11 22 33 44',
      birthDate: '15/08/1988',
      birthCity: 'STRASBOURG',
      address: '22 rue du Vieux Marché — STRASBOURG',
      storeLabel: 'Chaussea Strasbourg',
      loyaltyPercent: 72,
      avatarKind: ClientAvatarKind.leaves,
    ),
    ClientItem(
      id: '5',
      civility: 'Mm',
      lastName: 'PETIT',
      firstName: 'MARIE',
      email: 'marie.petit@free.fr',
      phone: '06 77 88 99 00',
      birthDate: '09/04/1995',
      birthCity: 'BELFORT',
      address: '3 allée des Roses — BELFORT',
      storeLabel: 'Chaussea Belfort',
      loyaltyPercent: 100,
      avatarKind: ClientAvatarKind.rose,
    ),
  ];
}
