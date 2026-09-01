// =============================================================================
// CapMobile — Module Swapp — Menu principal (maquette indigo)
// -----------------------------------------------------------------------------
// Fonctionnalité : Hub SWApp — sections Stock, Ventes, Équipe.
// Design         : SwappMenuShell + SwappMenuKit (tuiles taille fixe 3 colonnes).
// UI             : Tuile « Infos produit » → SwappInfosProduitMenuPage ;
//                  Tuile « Transferts » → InfoTransfertMenuPage ;
//                  Tuile « Mes REBs » → MesRebsPage ;
//                  Tuile « Réceptions » → ReceptionsMenuPage ;
//                  Tuile « Mes clients » → ClientSearchPage (module client) ;
//                  Tuile « My Goodays » → MyGoodaysPage (satisfaction client).
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/swapp/pages/client/client_search_page.dart';
import 'package:cap_mobile/swapp/pages/goodays/my_goodays_page.dart';
import 'package:cap_mobile/swapp/pages/nvs/mes_nvs_page.dart';
import 'package:cap_mobile/swapp/pages/produit/swapp_infos_produit_menu_page.dart';
import 'package:cap_mobile/swapp/pages/reb/mes_rebs_page.dart';
import 'package:cap_mobile/swapp/pages/reception/receptions_menu_page.dart';
import 'package:cap_mobile/swapp/pages/transfert/info_transfert_menu_page.dart';
import 'package:cap_mobile/swapp/widgets/swapp_menu_kit.dart';
import 'package:cap_mobile/features/tickets/pages/tickets_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hub SWApp — point d'entrée depuis l'accueil Cap Mobile.
class SwappMenuPage extends ConsumerWidget {
  const SwappMenuPage({super.key});

  /// Route fade-in vers le menu principal SWApp.
  static Route<void> fadeRoute() => swappMenuFadeRoute(const SwappMenuPage());

  /// Sections Stock & inventaire, Ventes & clients, Équipe & outils.
  List<SwappMenuSectionData> _sections(BuildContext context) {
    void soon(String label) => swappMenuSoonSnackBar(context, label);

    return [
      SwappMenuSectionData(
        title: 'Stock & inventaire',
        count: '06',
        tiles: [
          SwappMenuTileData(
            title: 'Infos produit',
            subtitle: 'Fiche produit',
            icon: Icons.show_chart_rounded,
            iconColor: SwappMenuColors.p1,
            iconBg: SwappMenuColors.p1Bg,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(context, SwappInfosProduitMenuPage.fadeRoute());
            },
          ),
          SwappMenuTileData(
            title: 'Mvts. Stock',
            subtitle: 'Historique',
            icon: Icons.timeline_rounded,
            iconColor: SwappMenuColors.p2,
            iconBg: SwappMenuColors.p2Bg,
            onTap: () => soon('Mvts. Stock'),
          ),
          SwappMenuTileData(
            title: 'Mes REBs',
            subtitle: 'Remises banque',
            icon: Icons.account_balance_rounded,
            iconColor: SwappMenuColors.p3,
            iconBg: SwappMenuColors.p3Bg,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(context, MesRebsPage.fadeRoute());
            },
          ),
          SwappMenuTileData(
            title: 'Inventaire',
            subtitle: 'Comptage',
            icon: Icons.inventory_2_outlined,
            iconColor: SwappMenuColors.p4,
            iconBg: SwappMenuColors.p4Bg,
            onTap: () => soon('Inventaire'),
          ),
          SwappMenuTileData(
            title: 'Réceptions',
            subtitle: 'Livraisons',
            icon: Icons.move_to_inbox_rounded,
            iconColor: SwappMenuColors.p5,
            iconBg: SwappMenuColors.p5Bg,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(context, ReceptionsMenuPage.fadeRoute());
            },
          ),
          SwappMenuTileData(
            title: 'Transferts',
            subtitle: 'Transfert',
            icon: Icons.swap_horiz_rounded,
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
        title: 'Ventes & clients',
        count: '05',
        tiles: [
          SwappMenuTileData(
            title: 'Mon stock',
            subtitle: 'Disponibilités',
            icon: Icons.grid_view_rounded,
            iconColor: SwappMenuColors.p1,
            iconBg: SwappMenuColors.p1Bg,
            onTap: () => soon('Mon stock'),
          ),
          SwappMenuTileData(
            title: 'Mes clients',
            subtitle: 'Fiches client',
            icon: Icons.people_outline_rounded,
            iconColor: SwappMenuColors.p2,
            iconBg: SwappMenuColors.p2Bg,
            onTap: () {
              Navigator.push(context, ClientSearchPage.fadeRoute());
            },
          ),
          SwappMenuTileData(
            title: 'Catalogue',
            subtitle: 'Références',
            icon: Icons.category_outlined,
            iconColor: SwappMenuColors.p3,
            iconBg: SwappMenuColors.p3Bg,
            onTap: () => soon('Catalogue'),
          ),
          SwappMenuTileData(
            title: 'My Goodays',
            subtitle: 'Fidélité',
            icon: Icons.sentiment_satisfied_alt_outlined,
            iconColor: SwappMenuColors.p6,
            iconBg: SwappMenuColors.p6Bg,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(context, MyGoodaysPage.fadeRoute());
            },
          ),
          SwappMenuTileData(
            title: 'Commandes',
            subtitle: 'Suivi',
            icon: Icons.calendar_today_outlined,
            iconColor: SwappMenuColors.p4,
            iconBg: SwappMenuColors.p4Bg,
            onTap: () => soon('Commandes'),
          ),
        ],
      ),
      SwappMenuSectionData(
        title: 'Équipe & outils',
        count: '05',
        tiles: [
          SwappMenuTileData(
            title: 'e-Resas',
            subtitle: 'Réservations',
            icon: Icons.chat_bubble_outline_rounded,
            iconColor: SwappMenuColors.p3,
            iconBg: SwappMenuColors.p3Bg,
            onTap: () => soon('e-Resas'),
          ),
          SwappMenuTileData(
            title: 'My Team',
            subtitle: 'Plannings',
            icon: Icons.groups_outlined,
            iconColor: SwappMenuColors.p2,
            iconBg: SwappMenuColors.p2Bg,
            onTap: () => soon('My Team'),
          ),
          SwappMenuTileData(
            title: 'Calculette',
            subtitle: 'Calcul rapide',
            icon: Icons.calculate_outlined,
            iconColor: SwappMenuColors.p1,
            iconBg: SwappMenuColors.p1Bg,
            onTap: () => soon('Calculette'),
          ),
          SwappMenuTileData(
            title: 'Mes NVS',
            subtitle: 'Non-ventes',
            icon: Icons.troubleshoot_rounded,
            iconColor: SwappMenuColors.p3,
            iconBg: SwappMenuColors.p3Bg,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(context, MesNvsPage.fadeRoute());
            },
          ),
          SwappMenuTileData(
            title: 'Gestion tickets',
            subtitle: 'Suivi & support',
            icon: Icons.confirmation_number_outlined,
            iconColor: SwappMenuColors.p5,
            iconBg: SwappMenuColors.p5Bg,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(context, TicketsPage.route());
            },
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
