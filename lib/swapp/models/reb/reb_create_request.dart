// =============================================================================
// CapMobile — Swapp — Requête de création d'une remise
// -----------------------------------------------------------------------------
// DTO séparé de RebItem : il décrit exactement les données envoyées au futur
// POST API. Le chemin photo local sera uploadé avant ou pendant cette requête.
// =============================================================================

class RebCreateRequest {
  final DateTime date;
  final DateTime dateEncaissement;
  final int codeMag;
  final int codeCollab;
  final String prenom;
  final String nom;
  final String? photoCollaborateurUrl;
  final List<String> encaissementIds;
  final double totalEncaissements;
  final double montantDeclare;
  final String? observations;
  final String? bordereauLocalPath;
  final String signatureBase64;

  const RebCreateRequest({
    required this.date,
    required this.dateEncaissement,
    required this.codeMag,
    required this.codeCollab,
    required this.prenom,
    required this.nom,
    required this.encaissementIds,
    required this.totalEncaissements,
    required this.montantDeclare,
    required this.signatureBase64,
    this.photoCollaborateurUrl,
    this.observations,
    this.bordereauLocalPath,
  });

  /// Corps attendu par POST `/api/magasins/{codeMag}/rebs`.
  Map<String, dynamic> toApiJson({required String mediaReb}) => {
    'dateReb': date.toIso8601String(),
    // Les lignes en attente n'ont pas encore de numReb côté API. Leur ID
    // local commence alors par ATT- et ne doit pas être envoyé au backend.
    'numReb': encaissementIds.single.startsWith('ATT-')
        ? ''
        : encaissementIds.single,
    'dateEncaissement': dateEncaissement.toIso8601String(),
    'description': observations?.trim() ?? '',
    'codeCollab': codeCollab.toString(),
    'montant': montantDeclare.toStringAsFixed(2),
    'mediaReb': mediaReb,
    'signature': signatureBase64,
  };
}
