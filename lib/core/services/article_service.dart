import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../features/article/models/article_model.dart';

class ArticleService {
  static const String _baseUrl = 'https://digitalapi.monchaussea.com/store-api';

  Future<ArticleModel> getArticle(String gencode) async {
    final uri = Uri.parse('$_baseUrl/api/articles/$gencode/');

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
        throw Exception('Article introuvable (gencode: $gencode)');
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Pas de connexion réseau — vérifiez le Wi-Fi');
    } catch (e) {
      rethrow;
    }
  }

  String getPhotoUrl(String gencode) {
    return '$_baseUrl/image/produit/$gencode.jpg';
  }
}