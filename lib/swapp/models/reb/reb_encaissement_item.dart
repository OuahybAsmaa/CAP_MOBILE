// =============================================================================
// CapMobile — Swapp — Encaissement disponible pour une remise
// -----------------------------------------------------------------------------
// Une ligne correspond à un encaissement caisse que l'utilisateur peut inclure
// dans une nouvelle remise. `dejaRemis` empêche une double affectation.
// =============================================================================

class RebEncaissementItem {
  final String id;
  final DateTime date;
  final double montant;
  final String collaborateur;
  final String? photoUrl;
  final bool dejaRemis;

  const RebEncaissementItem({
    required this.id,
    required this.date,
    required this.montant,
    required this.collaborateur,
    this.photoUrl,
    this.dejaRemis = false,
  });

  /// Mapping du futur endpoint des encaissements non encore remis.
  factory RebEncaissementItem.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['montant'] ?? json['amount'];
    return RebEncaissementItem(
      id: '${json['id'] ?? json['numEncaissement'] ?? ''}'.trim(),
      date: DateTime.tryParse('${json['date'] ?? ''}') ?? DateTime.now(),
      montant: rawAmount is num
          ? rawAmount.toDouble()
          : double.tryParse('$rawAmount'.replaceAll(',', '.')) ?? 0,
      collaborateur: '${json['collaborateur'] ?? json['nom'] ?? ''}'.trim(),
      photoUrl: _nullableString(json['photoUrl']),
      dejaRemis: json['dejaRemis'] == true,
    );
  }

  static String? _nullableString(Object? raw) {
    final value = '${raw ?? ''}'.trim();
    return value.isEmpty ? null : value;
  }
}
