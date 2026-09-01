// =============================================================================
// CapMobile — Module Swapp — Menu Infos produit
// -----------------------------------------------------------------------------
// Fonctionnalité : Sous-menu accessible depuis « Infos produit » (hub SWApp).
// Design         : Même kit indigo que SwappMenuPage (SwappMenuShell).
// UI             : 3 sections — Consultation, Étiquettes & offline, RFID & outils ;
//                  tuiles taille fixe (SwappMenuLayout.tileHeight).
// Navigation     : Infos Stocks → DetailProduitPage ; Infos Tarifs → InfoTarifPage (legacy) ;
//                  Info Tarif 2 → InfoTarifPage2 ; Infos OTs → InfoOtPage ;
//                  Infos Transferts → InfoTransfertMenuPage.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/swapp/pages/produit/produit_scan_page.dart';
import 'package:cap_mobile/swapp/pages/produit/info_ot_page.dart';
import 'package:cap_mobile/swapp/pages/tarif/info_tarif_page.dart';
import 'package:cap_mobile/swapp/pages/tarif/info_tarif_page2.dart';
import 'package:cap_mobile/swapp/pages/transfert/info_transfert_menu_page.dart';
import 'package:cap_mobile/swapp/widgets/swapp_menu_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sous-menu Infos produit — grille indigo identique au menu principal.
class SwappInfosProduitMenuPage extends ConsumerWidget {
  const SwappInfosProduitMenuPage({super.key});

  /// Route fade-in vers ce sous-menu.
  static Route<void> fadeRoute() =>
      swappMenuFadeRoute(const SwappInfosProduitMenuPage());

  /// Construit les 3 sections et leurs tuiles d'action.
  List<SwappMenuSectionData> _sections(BuildContext context) {
    void soon(String label) => swappMenuSoonSnackBar(context, label);

    return [
      SwappMenuSectionData(
        title: 'Consultation',
        count: '05',
        tiles: [
          SwappMenuTileData(
            title: 'Infos Stocks',
            subtitle: 'Fiche stock',
            icon: Icons.inventory_2_outlined,
            iconColor: SwappMenuColors.p1,
            iconBg: SwappMenuColors.p1Bg,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(context, ProduitScanPage.fadeRoute());
            },
          ),
          SwappMenuTileData(
            title: 'Infos Tarifs',
            subtitle: 'Prix & promos',
            icon: Icons.local_offer_outlined,
            iconColor: SwappMenuColors.p5,
            iconBg: SwappMenuColors.p5Bg,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(context, InfoTarifPage.fadeRoute());
            },
          ),
          SwappMenuTileData(
            title: 'Info Tarif 2',
            subtitle: 'Design moderne',
            icon: Icons.auto_awesome_outlined,
            iconColor: SwappMenuColors.p4,
            iconBg: SwappMenuColors.p4Bg,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(context, InfoTarifPage2.fadeRoute());
            },
          ),
          SwappMenuTileData(
            title: 'Infos OTs',
            subtitle: 'Ordres transfert',
            icon: Icons.sync_alt_rounded,
            iconColor: SwappMenuColors.p3,
            iconBg: SwappMenuColors.p3Bg,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(context, InfoOtPage.fadeRoute());
            },
          ),
          SwappMenuTileData(
            title: 'Infos Transferts',
            subtitle: 'Livraisons',
            icon: Icons.local_shipping_outlined,
            iconColor: SwappMenuColors.p6,
            iconBg: SwappMenuColors.p6Bg,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(context, InfoTransfertMenuPage.fadeRoute());
            },
          ),
        ],
      ),
      SwappMenuSectionData(
        title: 'Étiquettes & offline',
        count: '02',
        tiles: [
          SwappMenuTileData(
            title: 'Mes Étiquettes',
            subtitle: 'Impression',
            icon: Icons.qr_code_2_rounded,
            iconColor: SwappMenuColors.p4,
            iconBg: SwappMenuColors.p4Bg,
            onTap: () => soon('Mes Étiquettes'),
          ),
          SwappMenuTileData(
            title: 'Infos Tarifs',
            subtitle: 'Hors ligne',
            icon: Icons.wifi_off_rounded,
            iconColor: SwappMenuColors.p2,
            iconBg: SwappMenuColors.p2Bg,
            onTap: () => soon('Infos Tarifs hors ligne'),
          ),
        ],
      ),
      SwappMenuSectionData(
        title: 'RFID & outils',
        count: '01',
        tiles: [
          SwappMenuTileData(
            title: 'Connecter RFID',
            subtitle: 'Lecteur',
            icon: Icons.bluetooth_searching_rounded,
            iconColor: SwappMenuColors.p1,
            iconBg: SwappMenuColors.p1Bg,
            onTap: () => soon('Connecter RFID'),
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SwappMenuShell(sections: _sections(context));
  }
}
