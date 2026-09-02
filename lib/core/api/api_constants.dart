class ApiConstants {
  static const String digitalStoreBaseUrl =
      'https://digitalapi.monchaussea.com/store-api';

  /// Base de l'API VStore. Elle peut être remplacée au lancement/build avec :
  /// `--dart-define=VSTORE_API_BASE_URL=https://serveur.exemple.net`
  static const String baseUrl = String.fromEnvironment(
    'VSTORE_API_BASE_URL',
    defaultValue: 'https://digitalapi.monchaussea.com/store-api',
  );

  static String apiUrl(String path) {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$base$normalizedPath';
  }
}
