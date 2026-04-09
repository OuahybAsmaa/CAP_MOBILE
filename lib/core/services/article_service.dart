import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../features/article/models/article_model.dart';
import '../api/api_constants.dart';

class ArticleService {
  static const String _baseUrl = ApiConstants.baseUrl;

  String _extractGencode(String scannedValue) {
    try {
      final uri = Uri.parse(scannedValue);
      if (uri.hasScheme) {
        final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
        return segments.last;
      }
    } catch (_) {}
    return scannedValue;
  }

  Future<ArticleModel> getArticle(String gencode) async {
    final cleanedGencode = _extractGencode(gencode);
    final uri = Uri.parse('$_baseUrl/api/articles/$cleanedGencode/');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept':       'application/json',
          'User-Agent':   'CapMobile/1.0',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ArticleModel.fromJson(json);
      } else if (response.statusCode == 404) {
        throw Exception('Article introuvable (gencode: $cleanedGencode)');
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Pas de connexion réseau — vérifiez le Wi-Fi');
    } catch (e) {
      rethrow;
    }
  }

  String getPhotoUrl(String codeMod) {
    return '$_baseUrl/api/image/produit/$codeMod.jpg';
  }
}