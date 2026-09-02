// =============================================================================
// CapMobile — Constantes API recherche client
// -----------------------------------------------------------------------------

import '../api/api_constants.dart';

class ClientApiConstants {
  ClientApiConstants._();

  /// GET recherche clients (GSM, nom, prénom, email, limite).
  static Uri searchUrl({
    String gsm = '',
    String nom = '',
    String prenom = '',
    String email = '',
    int limit = 10,
    int? codeMag,
  }) {
    final params = <String, String>{
      if (gsm.trim().isNotEmpty) 'gsm': gsm.trim(),
      if (nom.trim().isNotEmpty) 'nom': nom.trim(),
      if (prenom.trim().isNotEmpty) 'prenom': prenom.trim(),
      if (email.trim().isNotEmpty) 'email': email.trim(),
      'limit': '$limit',
      if (codeMag != null && codeMag > 0) 'codeMag': '$codeMag',
    };

    return Uri.parse('${ApiConstants.digitalStoreBaseUrl}/api/client/search')
        .replace(queryParameters: params.isEmpty ? null : params);
  }
}
