// =============================================================================
// CapMobile — API Swapp — Modèle JSON modèle global (store-api)
// -----------------------------------------------------------------------------
// Fonctionnalité : DTO réponse GET /api/modele/{code}/mag/{codeMag}/global.
// Design         : ModeleGlobalModel + ModelePrixItem (stock par taille).
// UI             : JSON API → ProductStockMapper → ProductStockView → widgets écran.
// Spécifications : fromJson tolérant ; helpers _asInt / _asDouble.
// Auteur         : H.AMIZIANI
// =============================================================================

/// Ligne stock/prix pour une taille dans listePrix.
class ModelePrixItem {
  final int artIdentifiant;
  final String gencode;
  final int codeMag;
  final String taille;
  final double pv;
  final int stockDepot;
  final int stockTransit;
  final int stockPicking;
  final int stockMag;
  final int stockResa;
  final int stockPreResa;
  final int stockVol;
  final int stockEcartWeb;
  final int stockNonVendable;

  const ModelePrixItem({
    required this.artIdentifiant,
    required this.gencode,
    required this.codeMag,
    required this.taille,
    required this.pv,
    required this.stockDepot,
    required this.stockTransit,
    required this.stockPicking,
    required this.stockMag,
    required this.stockResa,
    required this.stockPreResa,
    required this.stockVol,
    required this.stockEcartWeb,
    required this.stockNonVendable,
  });

  factory ModelePrixItem.fromJson(Map<String, dynamic> json) {
    return ModelePrixItem(
      artIdentifiant: _asInt(json['artIdentifiant']),
      gencode: json['gencode']?.toString() ?? '',
      codeMag: _asInt(json['codeMag']),
      taille: json['taille']?.toString() ?? '',
      pv: _asDouble(json['pv']),
      stockDepot: _asInt(json['stockDepot']),
      stockTransit: _asInt(json['stockTransit']),
      stockPicking: _asInt(json['stockPicking']),
      stockMag: _asInt(json['stockMag']),
      stockResa: _asInt(json['stockResa']),
      stockPreResa: _asInt(json['stockPreResa']),
      stockVol: _asInt(json['stockVol']),
      stockEcartWeb: _asInt(json['stockEcartWeb']),
      stockNonVendable: _asInt(json['stockNonVendable']),
    );
  }
}

/// Fiche produit complète retournée par l'API modèle global.
class ModeleGlobalModel {
  final String libProduit;
  final String libTaille;
  final String libRayon;
  final String? libPlusProduit;
  final String libSaison;
  final String libFamille;
  final String libSousFamille;
  final String libTheme;
  final double prixVente;
  final String codeModele;
  final bool antivol;
  final String description;
  final bool resteALiver;
  final bool prixVenteUnique;
  final String forme;
  final String marque;
  final List<ModelePrixItem> listePrix;

  const ModeleGlobalModel({
    required this.libProduit,
    required this.libTaille,
    required this.libRayon,
    this.libPlusProduit,
    required this.libSaison,
    required this.libFamille,
    required this.libSousFamille,
    required this.libTheme,
    required this.prixVente,
    required this.codeModele,
    required this.antivol,
    required this.description,
    required this.resteALiver,
    required this.prixVenteUnique,
    required this.forme,
    required this.marque,
    required this.listePrix,
  });

  factory ModeleGlobalModel.fromJson(Map<String, dynamic> json) {
    final rawList = json['listePrix'];
    final items = rawList is List
        ? rawList
            .whereType<Map<String, dynamic>>()
            .map(ModelePrixItem.fromJson)
            .toList()
        : <ModelePrixItem>[];

    return ModeleGlobalModel(
      libProduit: json['libProduit']?.toString() ?? '',
      libTaille: json['libTaille']?.toString() ?? '',
      libRayon: json['libRayon']?.toString() ?? '',
      libPlusProduit: json['libPlusProduit']?.toString(),
      libSaison: json['libSaison']?.toString() ?? '',
      libFamille: json['libFamille']?.toString() ?? '',
      libSousFamille: json['libSousFamille']?.toString() ?? '',
      libTheme: json['libTheme']?.toString() ?? '',
      prixVente: _asDouble(json['prixVente']),
      codeModele: json['codeModele']?.toString() ?? '',
      antivol: json['antivol'] == true,
      description: json['description']?.toString() ?? '',
      resteALiver: json['resteALiver'] == true,
      prixVenteUnique: json['prixVenteUnique'] == true,
      forme: json['forme']?.toString() ?? '',
      marque: json['marque']?.toString() ?? '',
      listePrix: items,
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
