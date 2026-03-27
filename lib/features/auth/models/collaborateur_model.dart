class CollaborateurModel {
  final int codeCollab;
  final String nom;
  final String prenom;
  final String email;
  final String? tel;
  final String typeCollabLibelle;
  final bool estAdministrateur;
  final int codeMag;
  final String pictureLink;
  final List<MagasinModel> mags;

  CollaborateurModel({
    required this.codeCollab,
    required this.nom,
    required this.prenom,
    required this.email,
    this.tel,
    required this.typeCollabLibelle,
    required this.estAdministrateur,
    required this.codeMag,
    required this.pictureLink,
    required this.mags,
  });

  factory CollaborateurModel.fromJson(Map<String, dynamic> json) {
    return CollaborateurModel(
      codeCollab:        json['codeCollab'] as int,
      nom:               json['nom'] as String? ?? '',
      prenom:            json['prenom'] as String? ?? '',
      email:             json['emailCollab'] as String? ?? '',
      tel:               json['tel'] as String?,
      typeCollabLibelle: json['typeCollabLibelle'] as String? ?? '',
      estAdministrateur: json['estAdministrateur'] as bool? ?? false,
      codeMag:           json['codeMag'] as int? ?? 0,
      pictureLink:       json['pictureLink'] as String? ?? '',
      mags: (json['mags'] as List<dynamic>? ?? [])
          .map((e) => MagasinModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Prénom + Nom affiché
  String get fullName => '$prenom $nom';

  /// Nom du magasin principal
  String get magasinNom =>
      mags.isNotEmpty ? mags.first.nomMag : 'Magasin $codeMag';
}

class MagasinModel {
  final int codeMag;
  final String nomMag;

  MagasinModel({required this.codeMag, required this.nomMag});

  factory MagasinModel.fromJson(Map<String, dynamic> json) {
    return MagasinModel(
      codeMag: json['codeMag'] as int,
      nomMag: json['nomMag'] as String? ?? '',
    );
  }
}