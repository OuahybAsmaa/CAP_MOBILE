import 'package:cap_mobile/swapp/models/reb/reb.dart';

/// Convertit les payloads de l'API REB en modeles utilises par Swapp.
abstract final class RebMapper {
  static RebItem itemFromJson(Map<String, dynamic> json) =>
      RebItem.fromJson(json);

  static List<RebItem> itemsFromJson(List<Map<String, dynamic>> json) =>
      json.map(itemFromJson).toList(growable: false);

  static RebEncaissementItem encaissementFromJson(Map<String, dynamic> json) =>
      RebEncaissementItem.fromJson(json);

  static List<RebEncaissementItem> encaissementsFromJson(
    List<Map<String, dynamic>> json,
  ) => json.map(encaissementFromJson).toList(growable: false);

  static RebItem createdItemFromRequest(RebCreateRequest request) => RebItem(
    numReb: 'REB-${request.date.millisecondsSinceEpoch}',
    date: request.date,
    codeCollab: request.codeCollab,
    prenom: request.prenom,
    nom: request.nom,
    photoUrl: request.photoCollaborateurUrl,
    encaissement: request.totalEncaissements,
    declareReb: request.montantDeclare,
    bordereauUrl: request.bordereauLocalPath,
    observations: request.observations,
    statut: RebStatut.enAttente,
  );
}
