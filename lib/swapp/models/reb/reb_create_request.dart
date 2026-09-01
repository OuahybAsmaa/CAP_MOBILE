// =============================================================================
// CapMobile — Swapp — Requête de création d'une remise
// -----------------------------------------------------------------------------
// DTO séparé de RebItem : il décrit exactement les données envoyées au futur
// POST API. Le chemin photo local sera uploadé avant ou pendant cette requête.
// =============================================================================

class RebCreateRequest {
  final DateTime date;
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

  const RebCreateRequest({
    required this.date,
    required this.codeMag,
    required this.codeCollab,
    required this.prenom,
    required this.nom,
    required this.encaissementIds,
    required this.totalEncaissements,
    required this.montantDeclare,
    this.photoCollaborateurUrl,
    this.observations,
    this.bordereauLocalPath,
  });

  /// Corps JSON prévu pour le futur POST `/api/rebs`.
  ///
  /// Le fichier du bordereau n'est pas encodé ici : il devra être envoyé en
  /// multipart, puis son URL distante ajoutée au payload selon le contrat API.
  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'codeMag': codeMag,
    'codeCollab': codeCollab,
    'encaissementIds': encaissementIds,
    'totalEncaissements': totalEncaissements,
    'montantDeclare': montantDeclare,
    if (observations?.trim().isNotEmpty == true)
      'observations': observations!.trim(),
  };
}
