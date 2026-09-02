import 'package:cap_mobile/core/api/api_constants.dart';

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

  /// Informations détaillées retournées par vstoreapi.
  final DateTime? dateVente;
  final DateTime? dateReb;
  final String codeCaissiereEnc;
  final String prenomCaissiereEnc;
  final String? photoCaissiereEnc;
  final String codeCaissiereReb;
  final String prenomCaissiereReb;
  final String? photoCaissiereReb;
  final String? codeBanque;
  final String? codeMediaBnq;
  final String? codeMediaSig;
  final String? signatureUrl;

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
    this.dateVente,
    this.dateReb,
    this.codeCaissiereEnc = '',
    this.prenomCaissiereEnc = '',
    this.photoCaissiereEnc,
    this.codeCaissiereReb = '',
    this.prenomCaissiereReb = '',
    this.photoCaissiereReb,
    this.codeBanque,
    this.codeMediaBnq,
    this.codeMediaSig,
    this.signatureUrl,
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
      dateVente: dateVente,
      dateReb: dateReb,
      codeCaissiereEnc: codeCaissiereEnc,
      prenomCaissiereEnc: prenomCaissiereEnc,
      photoCaissiereEnc: photoCaissiereEnc,
      codeCaissiereReb: codeCaissiereReb,
      prenomCaissiereReb: prenomCaissiereReb,
      photoCaissiereReb: photoCaissiereReb,
      codeBanque: codeBanque,
      codeMediaBnq: codeMediaBnq,
      codeMediaSig: codeMediaSig,
      signatureUrl: signatureUrl,
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
    final dateVente = _parseNullableDate(json['dateVente'] ?? json['date']);
    final dateReb = _parseNullableDate(json['dateReb'] ?? json['dateRemise']);
    final codeEnc = '${json['codeCaissiereEnc'] ?? ''}'.trim();
    final prenomEnc = '${json['prenomCaissiereEnc'] ?? ''}'.trim();
    final codeReb = '${json['codeCaissiereReb'] ?? ''}'.trim();
    final prenomReb = '${json['prenomCaissiereReb'] ?? ''}'.trim();
    final resolvedDate = dateReb ?? dateVente ?? DateTime.now();
    final rawNumReb = '${json['numReb'] ?? json['numeroReb'] ?? json['id'] ?? ''}'
        .trim();
    final resolvedNumReb = rawNumReb.isNotEmpty
        ? rawNumReb
        : 'ATT-${resolvedDate.millisecondsSinceEpoch}-$codeEnc';
    final photoEnc = _resolveVstoreUrl(json['photoCaissiereEnc']);
    final photoReb = _resolveVstoreUrl(json['photoCaissiereReb']);
    final traite = dateReb != null || rawNumReb.isNotEmpty;

    return RebItem(
      numReb: resolvedNumReb,
      date: resolvedDate,
      codeCollab: _parseInt(
        json['codeCollab'] ??
            (codeReb.isNotEmpty
                ? codeReb
                : codeEnc.isNotEmpty
                ? codeEnc
                : null) ??
            collab['codeCollab'] ??
            collab['id'],
      ),
      prenom:
          '${json['prenom'] ?? (prenomReb.isNotEmpty ? prenomReb : prenomEnc.isNotEmpty ? prenomEnc : null) ?? collab['prenom'] ?? ''}'
              .trim(),
      nom: '${json['nom'] ?? collab['nom'] ?? ''}'.trim(),
      photoUrl: _nullableString(
        json['photoUrl'] ??
            (photoReb?.isNotEmpty == true
                ? photoReb
                : photoEnc?.isNotEmpty == true
                ? photoEnc
                : null) ??
            collab['pictureLink'] ??
            collab['photoUrl'],
      ),
      encaissement: _parseAmount(
        json['montantEncaisse'] ??
            json['montantEncaisseReb'] ??
            json['encaissement'] ??
            json['montantEncaissement'] ??
            json['montantCaisse'] ??
            json['montantEncaisse'],
      ),
      declareReb: _parseAmount(
        json['declareReb'] ??
            json['declare'] ??
            json['montantDeclare'] ??
            json['montantReb'] ??
            json['montantEncaisseReb'] ??
            json['montantEncaisse'] ??
            json['montant'],
      ),
      bordereauUrl: _resolveVstoreUrl(
        json['justificatif'] ??
            json['bordereauUrl'] ??
            json['urlBordereau'] ??
            json['bordereau'],
      ),
      observations: _nullableString(
        json['description'] ??
            json['observations'] ??
            json['observation'] ??
            json['commentaire'],
      ),
      statut: traite ||
              '${json['statut'] ?? json['libStatut'] ?? ''}'
                      .trim()
                      .toLowerCase() ==
                  'traitee'
          ? RebStatut.traitee
          : RebStatut.enAttente,
      dateVente: dateVente,
      dateReb: dateReb,
      codeCaissiereEnc: codeEnc,
      prenomCaissiereEnc: prenomEnc,
      photoCaissiereEnc: photoEnc,
      codeCaissiereReb: codeReb,
      prenomCaissiereReb: prenomReb,
      photoCaissiereReb: photoReb,
      codeBanque: _nullableString(json['codeBanque']),
      codeMediaBnq: _nullableString(json['codeMediaBnq']),
      codeMediaSig: _nullableString(json['codeMediaSig']),
      signatureUrl: _resolveVstoreUrl(json['signature']),
    );
  }

  static DateTime _parseDate(Object? raw) {
    if (raw is DateTime) return raw.toLocal();
    final value = '${raw ?? ''}'.trim();
    if (RegExp(r'^\d{8}$').hasMatch(value)) {
      return DateTime(
        int.parse(value.substring(0, 4)),
        int.parse(value.substring(4, 6)),
        int.parse(value.substring(6, 8)),
      );
    }
    return DateTime.tryParse(value)?.toLocal() ?? DateTime.now();
  }

  static DateTime? _parseNullableDate(Object? raw) {
    if (raw == null || '$raw'.trim().isEmpty) return null;
    return _parseDate(raw);
  }

  static String? _resolveVstoreUrl(Object? raw) {
    final value = _nullableString(raw);
    if (value == null) return null;
    if (value.startsWith('data:image/')) return value;
    final compact = value.replaceAll(RegExp(r'\s+'), '');
    if (compact.length > 200 &&
        RegExp(r'^[A-Za-z0-9+/]+={0,2}$').hasMatch(compact)) {
      return 'data:image/jpeg;base64,$compact';
    }
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    return ApiConstants.apiUrl(value);
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
