// =============================================================================
// CapMobile — Module Swapp — Dialogue sélection magasin
// -----------------------------------------------------------------------------
// Fonctionnalité : Liste scrollable des magasins ; retourne codeMag sélectionné ou null.
// Design         : Dialog arrondi ; en-tête dégradé bleu ; ListTile avec check si actif.
// UI             : Modal centré max 340×460 — liste magasins scrollable ;
//                  item sélectionné = check_circle ; bouton Annuler en bas.
// Spécifications : [showStorePickerDialog] ; réexporte resolveMagasins / testMagasins ;
//                  i18n selectStoreTitle, storeCodeLabel, cancel.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/core/apiswap/models/nearby_stock_item.dart';
import 'package:cap_mobile/core/l10n/app_localizations_scope.dart';
import 'package:cap_mobile/core/theme/app_colors.dart';
import 'package:cap_mobile/features/auth/models/collaborateur_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

export 'package:cap_mobile/swapp/data/test_magasins.dart'
    show resolveMagasins, storeLabelFor, testMagasins;

/// Affiche le dialogue de choix de magasin ; retourne le [codeMag] ou null si annulé.
Future<int?> showStorePickerDialog({
  required BuildContext context,
  required List<MagasinModel> stores,
  required int selectedCodeMag,
  Set<int>? storesWithStock,
}) {
  return showDialog<int>(
    context: context,
    builder: (dialogContext) {
      final l10n = dialogContext.l10n;
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340, maxHeight: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.store_rounded, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.selectStoreTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: stores.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final store = stores[index];
                    final selected = store.codeMag == selectedCodeMag;
                    final hasStock = storesWithStock?.contains(store.codeMag) ?? false;
                    final nameColor = hasStock
                        ? AppColors.success
                        : AppColors.primaryDark;
                    return ListTile(
                      leading: Icon(
                        Icons.storefront_outlined,
                        color: hasStock
                            ? AppColors.success
                            : selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                      ),
                      title: Text(
                        store.nomMag,
                        style: TextStyle(
                          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                          color: nameColor,
                        ),
                      ),
                      subtitle: hasStock
                          ? Text(
                              l10n.storeHasStockLabel,
                              style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            )
                          : null,
                      trailing: selected
                          ? const Icon(Icons.check_circle, color: AppColors.primary)
                          : null,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.of(dialogContext).pop(store.codeMag);
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(l10n.cancel),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Affiche le dialogue de choix magasin alentour (liste API nearby + rang proximité).
Future<int?> showNearbyStorePickerDialog({
  required BuildContext context,
  required List<NearbyStoreStock> stores,
  required int selectedCodeMag,
}) {
  return showDialog<int>(
    context: context,
    builder: (dialogContext) {
      final l10n = dialogContext.l10n;
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340, maxHeight: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.map_rounded, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.selectStoreTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: stores.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final store = stores[index];
                    final selected = store.codeMag == selectedCodeMag;
                    final hasStock = store.hasStock;
                    final nameColor =
                        hasStock ? AppColors.success : AppColors.primaryDark;
                    return ListTile(
                      leading: Icon(
                        Icons.storefront_outlined,
                        color: hasStock
                            ? AppColors.success
                            : selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                      ),
                      title: Text(
                        store.nomMag,
                        style: TextStyle(
                          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                          color: nameColor,
                        ),
                      ),
                      subtitle: hasStock
                          ? Text(
                              l10n.storeStockTotal(store.totalStock),
                              style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            )
                          : Text(
                              l10n.nearbyRank(store.rank),
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                      trailing: selected
                          ? const Icon(Icons.check_circle, color: AppColors.primary)
                          : null,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.of(dialogContext).pop(store.codeMag);
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(l10n.cancel),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
