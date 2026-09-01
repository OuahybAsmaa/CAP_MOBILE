// =============================================================================
// CapMobile — API Swapp — Modèle avis produit (GET review)
// -----------------------------------------------------------------------------

String _string(dynamic value) {
  if (value == null) return '';
  return value.toString();
}

class ProductReviewCollab {
  final int codeCollab;
  final String nom;
  final String prenom;
  final String pictureLink;

  const ProductReviewCollab({
    required this.codeCollab,
    required this.nom,
    required this.prenom,
    this.pictureLink = '',
  });

  factory ProductReviewCollab.fromJson(Map<String, dynamic> json) {
    return ProductReviewCollab(
      codeCollab: json['codeCollab'] is int
          ? json['codeCollab'] as int
          : int.tryParse(_string(json['codeCollab'])) ?? 0,
      nom: _string(json['nom']),
      prenom: _string(json['prenom']),
      pictureLink: _string(
        json['pictureLink'] ?? json['photoUrl'] ?? json['picture'],
      ),
    );
  }

  String get displayName {
    final p = prenom.trim();
    final n = nom.trim();
    if (p.isNotEmpty && n.isNotEmpty) return '$p $n';
    if (n.isNotEmpty) return n;
    if (p.isNotEmpty) return p;
    return 'Collab $codeCollab';
  }
}

class ProductReviewItem {
  final int codeReview;
  final int codeCollab;
  final String codeMod;
  final DateTime? dateReview;
  final int resultat;
  final String review;
  final int defaut;
  final ProductReviewCollab? collab;
  final List<Map<String, dynamic>> medias;

  const ProductReviewItem({
    required this.codeReview,
    required this.codeCollab,
    required this.codeMod,
    this.dateReview,
    required this.resultat,
    this.review = '',
    required this.defaut,
    this.collab,
    this.medias = const [],
  });

  factory ProductReviewItem.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    final rawDate = _string(json['dateReview']);
    if (rawDate.isNotEmpty) {
      parsedDate = DateTime.tryParse(rawDate);
    }

    ProductReviewCollab? collab;
    final collabJson = json['collab'];
    if (collabJson is Map) {
      collab = ProductReviewCollab.fromJson(
        Map<String, dynamic>.from(collabJson),
      );
    }

    final mediasJson = json['medias'];
    final medias = mediasJson is List
        ? mediasJson
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
        : <Map<String, dynamic>>[];

    return ProductReviewItem(
      codeReview: json['codeReview'] is int
          ? json['codeReview'] as int
          : int.tryParse(_string(json['codeReview'])) ?? 0,
      codeCollab: json['codeCollab'] is int
          ? json['codeCollab'] as int
          : int.tryParse(_string(json['codeCollab'])) ?? 0,
      codeMod: _string(json['codeMod']),
      dateReview: parsedDate,
      resultat: json['resultat'] is int
          ? json['resultat'] as int
          : int.tryParse(_string(json['resultat'])) ?? 0,
      review: _string(json['review']),
      defaut: json['defaut'] is int
          ? json['defaut'] as int
          : int.tryParse(_string(json['defaut'])) ?? 0,
      collab: collab,
      medias: medias,
    );
  }

  String get authorLabel {
    final c = collab;
    if (c == null) return 'Collab $codeCollab';
    return c.displayName;
  }

  bool get isDefective => defaut != 0;

  String get comment => review.trim();

  int get rating => resultat.clamp(0, 5);
}
