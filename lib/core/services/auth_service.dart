import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../features/auth/models/collaborateur_model.dart';
import 'dart:io';
import '../api/api_constants.dart';

class AuthService {
  static const String _baseUrl = ApiConstants.baseUrl;

  Future<CollaborateurModel> getCollaborateur(String codeCollab) async {
    final uri = Uri.parse('$_baseUrl/api/collaborateurs/$codeCollab/');

    try {
      final client = http.Client();

      final response = await client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'CapMobile/1.0',
        },
      ).timeout(const Duration(seconds: 15));

      client.close();

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        print('Authentification réussie: ${json['prenom']}');
        return CollaborateurModel.fromJson(json);
      } else if (response.statusCode == 404) {
        throw Exception('Collaborateur introuvable (code: $codeCollab)');
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}\n${response.body}');
      }
    } on SocketException catch (e) {
      print('SocketException: $e');
      throw Exception('Pas de connexion au serveur\nVérifiez que le TC52 est connecté au réseau entreprise');
    } on http.ClientException catch (e) {
      print('ClientException: $e');
      throw Exception('Erreur de connexion: ${e.message}');
    } catch (e) {
      print('Erreur générale: $e');
      throw Exception('Erreur: $e');
    }
  }

  String getPhotoUrl(int codeCollab) {
    return '$_baseUrl/api/collaborateurs/$codeCollab/photo';
  }
}