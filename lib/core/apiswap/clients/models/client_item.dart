// =============================================================================
// CapMobile — Modèle client (recherche CRM)
// -----------------------------------------------------------------------------

enum ClientAvatarKind { branch, leaves, rose }

class ClientItem {
  final String id;
  final String civility;
  final String lastName;
  final String firstName;
  final String email;
  final String phone;
  final String? birthDate;
  final String? birthCity;
  final String? address;
  final String? storeLabel;
  final int loyaltyPercent;
  final ClientAvatarKind avatarKind;

  const ClientItem({
    required this.id,
    this.civility = '',
    required this.lastName,
    required this.firstName,
    this.email = '',
    this.phone = '',
    this.birthDate,
    this.birthCity,
    this.address,
    this.storeLabel,
    this.loyaltyPercent = 0,
    this.avatarKind = ClientAvatarKind.leaves,
  });

  String get fullName {
    final parts = [
      if (civility.isNotEmpty) civility,
      if (lastName.isNotEmpty) lastName,
      if (firstName.isNotEmpty) firstName,
    ];
    return parts.join(' ').trim();
  }

  String get birthLine {
    final parts = [
      if (birthDate != null && birthDate!.isNotEmpty) birthDate,
      if (birthCity != null && birthCity!.isNotEmpty) birthCity,
    ];
    return parts.join(' ');
  }

  factory ClientItem.fromJson(Map<String, dynamic> json) {
    return ClientItem(
      id: _string(json, ['id', 'codeClient', 'code']),
      civility: _string(json, ['civilite', 'civility', 'titre']),
      lastName: _string(json, ['nom', 'lastName', 'name']),
      firstName: _string(json, ['prenom', 'firstName']),
      email: _string(json, ['email', 'mail']),
      phone: _string(json, ['gsm', 'telephone', 'phone', 'mobile']),
      birthDate: _optional(json, ['dateNaissance', 'birthDate', 'naissance']),
      birthCity: _optional(json, ['villeNaissance', 'birthCity', 'ville']),
      address: _optional(json, ['adresse', 'address', 'adresseComplete']),
      storeLabel: _optional(json, ['magasin', 'store', 'libMag']),
      loyaltyPercent: _int(json, ['fidelite', 'loyalty', 'pourcentage', 'percent']),
      avatarKind: ClientAvatarKind.values[
          _int(json, ['avatar']) % ClientAvatarKind.values.length],
    );
  }

  static String _string(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return '';
  }

  static String? _optional(Map<String, dynamic> json, List<String> keys) {
    final value = _string(json, keys);
    return value.isEmpty ? null : value;
  }

  static int _int(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value.replaceAll('%', '').trim());
        if (parsed != null) return parsed;
      }
    }
    return 0;
  }
}
