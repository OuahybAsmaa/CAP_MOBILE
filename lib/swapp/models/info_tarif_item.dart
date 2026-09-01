// =============================================================================
// CapMobile — Module Swapp — Modèle Info Tarif
// -----------------------------------------------------------------------------
// Fonctionnalité : Opération tarifaire / promo magasin (liste Info Tarif).
// Design         : Objet immuable — mapping futur depuis JSON API store.
// UI             : Alimente InfoTarifPage (carte opération + dates + statut).
// Spécifications : Données démo dans [InfoTarifDemoData] en attendant l'API.
// Auteur         : H.AMIZIANI
// =============================================================================

/// Opération tarifaire — une ligne de la liste « Info Tarif ».
class InfoTarifItem {
  /// Code opération (ex. « 3133 »).
  final String code;

  /// Libellé affiché (ex. « OP DEFAUTS »).
  final String label;

  /// Date de début de validité.
  final DateTime dateDebut;

  /// Date de fin de validité.
  final DateTime dateFin;

  /// Statut affiché en fin de ligne (ex. « N » = Nouveau).
  final String statut;

  const InfoTarifItem({
    required this.code,
    required this.label,
    required this.dateDebut,
    required this.dateFin,
    this.statut = 'N',
  });

  /// Identifiant unique pour sélection UI.
  String get id => code;

  /// Titre complet — « 3133 OP DEFAUTS ».
  String get displayTitle => '$code $label';

  /// Opération active à la date [day] (inclusif début/fin).
  bool isActiveOn(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final start = DateTime(dateDebut.year, dateDebut.month, dateDebut.day);
    final end = DateTime(dateFin.year, dateFin.month, dateFin.day);
    return !d.isBefore(start) && !d.isAfter(end);
  }

  /// Parsing JSON API — à brancher quand l'endpoint sera disponible.
  ///
  /// Exemple attendu :
  /// `{ "code": "3133", "libelle": "OP DEFAUTS", "dateDebut": "2023-03-07",
  ///    "dateFin": "2026-09-07", "statut": "N" }`
  factory InfoTarifItem.fromJson(Map<String, dynamic> json) {
    return InfoTarifItem(
      code: '${json['code'] ?? json['codeOp'] ?? ''}'.trim(),
      label: '${json['libelle'] ?? json['label'] ?? ''}'.trim(),
      dateDebut: _parseDate(json['dateDebut']),
      dateFin: _parseDate(json['dateFin']),
      statut: '${json['statut'] ?? 'N'}'.trim(),
    );
  }

  static DateTime _parseDate(Object? raw) {
    if (raw is String && raw.isNotEmpty) {
      final iso = DateTime.tryParse(raw);
      if (iso != null) return iso;
      final parts = raw.split('/');
      if (parts.length == 3) {
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[2]);
        if (d != null && m != null && y != null) {
          return DateTime(y, m, d);
        }
      }
    }
    return DateTime.now();
  }
}
