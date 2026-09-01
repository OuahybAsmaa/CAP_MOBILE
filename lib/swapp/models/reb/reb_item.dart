// =============================================================================
// CapMobile — Swapp — Entité métier Remise En Banque
// -----------------------------------------------------------------------------
// Une entité immutable représentant une remise affichée dans « Mes remises ».
// Le mapping JSON est volontairement isolé ici : l'UI ne dépend donc pas de la
// forme exacte de la future réponse HTTP.
// =============================================================================

/// Étape de traitement d'une remise en banque.
enum RebStatut { enAttente, traitee }

/// Remise en banque réalisée par un collaborateur pour une journée.
class RebItem {
  /// Identifiant fonctionnel retourné par l'API.
  final String numReb;
  final DateTime date;

  /// Identité du collaborateur responsable de la remise.
  final int? codeCollab;
  final String prenom;
  final String nom;
  final String? photoUrl;

  /// Total des encaissements rattachés et montant déclaré à la banque.
  final double encaissement;
  final double declareReb;

  /// URL distante après upload, ou chemin local durant le mode démo.
  final String? bordereauUrl;
  final String? observations;
  final RebStatut statut;

  const RebItem({
    required this.numReb,
    required this.date,
    required this.prenom,
    required this.nom,
    required this.encaissement,
    required this.declareReb,
    required this.statut,
    this.codeCollab,
    this.photoUrl,
    this.bordereauUrl,
    this.observations,
  });

  String get id => numReb;
  double get ecart => declareReb - encaissement;
  bool get conforme => ecart.abs() < 0.005;
  bool get bordereauManquant =>
      bordereauUrl == null || bordereauUrl!.trim().isEmpty;

  String get initiales {
    final p = prenom.trim();
    final n = nom.trim();
    return '${p.isEmpty ? '' : p[0]}${n.isEmpty ? '' : n[0]}'.toUpperCase();
  }

  RebItem copyWith({
    RebStatut? statut,
    String? bordereauUrl,
    String? observations,
  }) {
    return RebItem(
      numReb: numReb,
      date: date,
      codeCollab: codeCollab,
      prenom: prenom,
      nom: nom,
      photoUrl: photoUrl,
      encaissement: encaissement,
      declareReb: declareReb,
      bordereauUrl: bordereauUrl ?? this.bordereauUrl,
      observations: observations ?? this.observations,
      statut: statut ?? this.statut,
    );
  }

  static int compareRecent(RebItem a, RebItem b) {
    final byDate = b.date.compareTo(a.date);
    return byDate != 0 ? byDate : b.numReb.compareTo(a.numReb);
  }

  /// Convertit la réponse du futur endpoint GET `/api/rebs`.
  factory RebItem.fromJson(Map<String, dynamic> json) {
    final collabRaw = json['collaborateur'] ?? json['collab'];
    final collab = collabRaw is Map
        ? Map<String, dynamic>.from(collabRaw)
        : const <String, dynamic>{};
    return RebItem(
      numReb: '${json['numReb'] ?? json['numeroReb'] ?? json['id'] ?? ''}'
          .trim(),
      date: _parseDate(
        json['date'] ?? json['dateReb'] ?? json['dateRemise'],
      ),
      codeCollab: _parseInt(
        json['codeCollab'] ?? collab['codeCollab'] ?? collab['id'],
      ),
      prenom: '${json['prenom'] ?? collab['prenom'] ?? ''}'.trim(),
      nom: '${json['nom'] ?? collab['nom'] ?? ''}'.trim(),
      photoUrl: _nullableString(
        json['photoUrl'] ?? collab['pictureLink'] ?? collab['photoUrl'],
      ),
      encaissement: _parseAmount(
        json['encaissement'] ??
            json['montantEncaissement'] ??
            json['montantCaisse'] ??
            json['montant'],
      ),
      declareReb: _parseAmount(
        json['declareReb'] ??
            json['declare'] ??
            json['montantDeclare'] ??
            json['montantReb'] ??
            json['montant'],
      ),
      bordereauUrl: _nullableString(
        json['bordereauUrl'] ?? json['urlBordereau'] ?? json['bordereau'],
      ),
      observations: _nullableString(
        json['observations'] ?? json['observation'] ?? json['commentaire'],
      ),
      statut: '${json['statut'] ?? json['libStatut'] ?? ''}'
                  .trim()
                  .toLowerCase() ==
              'traitee'
          ? RebStatut.traitee
          : RebStatut.enAttente,
    );
  }

  static DateTime _parseDate(Object? raw) {
    if (raw is DateTime) return raw;
    final value = '${raw ?? ''}'.trim();
    if (RegExp(r'^\d{8}$').hasMatch(value)) {
      return DateTime(
        int.parse(value.substring(0, 4)),
        int.parse(value.substring(4, 6)),
        int.parse(value.substring(6, 8)),
      );
    }
    return DateTime.tryParse(value) ?? DateTime.now();
  }

  static double _parseAmount(Object? raw) => raw is num
      ? raw.toDouble()
      : double.tryParse('${raw ?? ''}'.replaceAll(',', '.')) ?? 0;

  static int? _parseInt(Object? raw) =>
      raw is int ? raw : int.tryParse('${raw ?? ''}');

  static String? _nullableString(Object? raw) {
    final value = '${raw ?? ''}'.trim();
    return value.isEmpty ? null : value;
  }
}
