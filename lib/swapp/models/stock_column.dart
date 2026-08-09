// =============================================================================
// CapMobile — Module Swapp — Colonnes stock
// -----------------------------------------------------------------------------
// Fonctionnalité : Définition des rubriques stock (Dispo, Transit, Picking…).
// Design         : Icône + couleur thème par colonne ; affichage conditionnel.
// UI             : Chaque StockColumnDef → colonne _StockTable : label en-tête,
//                  icône+couleur dans _ValueCircle ; taille = 1re colonne fixe.
// Spécifications : Mag = colonnes dynamiques ; Web = Taille + Dispo uniquement.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Métadonnées UI d'une colonne tableau stock (clé API → rendu visuel).
class StockColumnDef {
  /// Clé dans stockBySize (ex. 'dispo', 'transit').
  final String key;

  /// UI : Libellé court en-tête colonne _StockTable.
  final String label;

  /// UI : Icône optionnelle en-tête (non affichée en v1, utilisée en v2).
  final IconData icon;

  /// UI : Couleur fond/texte _ValueCircle pour cette métrique.
  final Color color;

  const StockColumnDef({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
  });
}

/// Catalogue colonnes — mapping direct vers le tableau stock UI.
abstract class StockColumns {
  /// UI : Colonne 1 — libellé taille (40, 41…) dans _StockTableRow.
  static const taille = StockColumnDef(
    key: 'taille',
    label: 'Taille',
    icon: Icons.straighten,
    color: AppColors.info,
  );

  /// UI : Cercle vert — stock disponible magasin.
  static const dispo = StockColumnDef(
    key: 'dispo',
    label: 'Dispo',
    icon: Icons.storefront_outlined,
    color: AppColors.success,
  );

  /// UI : Cercle orange — stock en transit.
  static const transit = StockColumnDef(
    key: 'transit',
    label: 'Transit',
    icon: Icons.local_shipping_outlined,
    color: AppColors.warning,
  );

  /// UI : Cercle rouge — stock en picking.
  static const picking = StockColumnDef(
    key: 'picking',
    label: 'Picking',
    icon: Icons.front_hand_outlined,
    color: AppColors.error,
  );

  /// UI : Cercle bleu foncé — vols (colonne masquée si total=0).
  static const vols = StockColumnDef(
    key: 'vols',
    label: 'Vols',
    icon: Icons.gpp_bad_outlined,
    color: AppColors.primaryDark,
  );

  /// UI : Cercle gris — non vendable (colonne masquée si total=0).
  static const nonVendable = StockColumnDef(
    key: 'nv',
    label: 'N.V.',
    icon: Icons.block_outlined,
    color: AppColors.textSecondary,
  );

  /// UI : Cercle orange — écart web (colonne masquée si total=0).
  static const ecartWeb = StockColumnDef(
    key: 'ew',
    label: 'E.W.',
    icon: Icons.public_off_outlined,
    color: AppColors.orange,
  );

  /// UI : Cercle violet — réservations (colonne masquée si total=0).
  static const resas = StockColumnDef(
    key: 'resas',
    label: 'Résas',
    icon: Icons.lock_outline,
    color: AppColors.tertiary,
  );

  /// UI : Cercle secondaire — pré-réservations (colonne masquée si total=0).
  static const resaPlus = StockColumnDef(
    key: 'resaPlus',
    label: 'Résa+',
    icon: Icons.inventory_2_outlined,
    color: AppColors.secondary,
  );

  /// UI : Cercle secondaire — stock dépôt (toujours visible en mag).
  static const depot = StockColumnDef(
    key: 'depot',
    label: 'Dépôt',
    icon: Icons.warehouse_outlined,
    color: AppColors.secondary,
  );

  static const coreMetrics = [dispo, transit, picking, depot];

  static const optionalMetrics = [
    vols,
    nonVendable,
    ecartWeb,
    resas,
    resaPlus,
  ];

  static const metrics = [
    dispo,
    transit,
    picking,
    vols,
    nonVendable,
    ecartWeb,
    resas,
    resaPlus,
    depot,
  ];

  static const all = [taille, ...metrics];

  /// UI : Colonnes rendues dans _StockTable onglet Stock Mag.
  static List<StockColumnDef> visibleFor(Map<String, int> totals) {
    return [
      taille,
      dispo,
      transit,
      picking,
      ...optionalMetrics.where((column) => (totals[column.key] ?? 0) > 0),
      depot,
    ];
  }

  /// UI : Colonnes rendues dans _StockTable onglet Stock Web (2 colonnes).
  static const web = [taille, dispo];
}
