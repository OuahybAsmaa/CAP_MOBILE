// =============================================================================
// CapMobile — Module Swapp — Recherche client (ClientSearchPage)
// -----------------------------------------------------------------------------
// Fonctionnalité : Recherche CRM par GSM, nom, prénom, e-mail ; liste résultats ;
//                  navigation vers ajout client ; limite 10/50 résultats.
// Design         : Thème bleu AppColors ; header dégradé ; champs capsule blancs ;
//                  cartes client avec bande latérale primary + badge fidélité.
// UI             : ClientPageScaffold → formulaire (_SearchFormView) ou liste
//                  (_ResultsView) ; PopScope gère retour liste→formulaire→produit ;
//                  icône + header → ClientAddPage ; loupe header + bouton Rechercher.
// Spécifications : Riverpod clientSearchProvider ; validation critères avant API ;
//                  IntrinsicHeight sur cartes pour éviter overflow layout.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/core/clients/client_search_provider.dart';
import 'package:cap_mobile/core/clients/client_service.dart';
import 'package:cap_mobile/core/clients/models/client_item.dart';
import 'package:cap_mobile/core/theme/app_colors.dart';
import 'package:cap_mobile/features/auth/providers/auth_provider.dart';
import 'package:cap_mobile/swapp/pages/client_add_page.dart';
import 'package:cap_mobile/swapp/widgets/client_form_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// UI : Point d'entrée écran « Liste des Clients » — formulaire puis résultats.
/// Auteur : H.AMIZIANI
class ClientSearchPage extends ConsumerStatefulWidget {
  const ClientSearchPage({super.key});

  @override
  ConsumerState<ClientSearchPage> createState() => _ClientSearchPageState();
}

class _ClientSearchPageState extends ConsumerState<ClientSearchPage> {
  final _gsmCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  int _pageSize = 10;

  @override
  void dispose() {
    _gsmCtrl.dispose();
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  bool get _hasCriteria =>
      _gsmCtrl.text.trim().isNotEmpty ||
      _nomCtrl.text.trim().isNotEmpty ||
      _prenomCtrl.text.trim().isNotEmpty ||
      _emailCtrl.text.trim().isNotEmpty;

  /// UI : Lance l'API si au moins un champ rempli ; SnackBar sinon (reste sur formulaire).
  void _runSearch() {
    FocusScope.of(context).unfocus();

    if (!_hasCriteria) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saisissez au moins un critère de recherche'),
        ),
      );
      return;
    }

    HapticFeedback.lightImpact();

    final codeMag = ref.read(authProvider).collaborateur?.codeMag;
    final query = ClientSearchQuery(
      gsm: _gsmCtrl.text,
      nom: _nomCtrl.text,
      prenom: _prenomCtrl.text,
      email: _emailCtrl.text,
      limit: _pageSize,
      codeMag: codeMag != null && codeMag > 0 ? codeMag : null,
    );

    ref.read(clientSearchProvider.notifier).search(query);
  }

  /// UI : Retour liste → masque recherche (conserve les TextEditingController).
  void _backToForm() {
    ref.read(clientSearchProvider.notifier).backToForm();
  }

  /// UI : Retour formulaire → page produit Swapp (Navigator.pop).
  void _handleBack() {
    if (ref.read(clientSearchProvider).hasSearched) {
      _backToForm();
    } else {
      Navigator.pop(context);
    }
  }

  /// UI : Transition fade vers ClientAddPage (bouton + du header).
  void _openAddClient() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const ClientAddPage(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 280),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(clientSearchProvider);
    final showResults = searchState.hasSearched;

    String? subtitle;
    if (showResults && !searchState.isLoading) {
      final n = searchState.results.length;
      subtitle = n == 1 ? '1 client trouvé' : '$n clients trouvés';
    }

    return PopScope(
      canPop: !showResults,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _backToForm();
      },
      child: ClientPageScaffold(
        title: 'Liste des Clients',
        subtitle: subtitle,
        onBack: _handleBack,
        onSearch: _runSearch,
        onAdd: _openAddClient,
        onStats: () {},
        showAddAction: !showResults,
        showStatsAction: !showResults,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          child: showResults
              ? _ResultsView(
                  key: const ValueKey('results'),
                  state: searchState,
                  onRetry: _runSearch,
                )
              : _SearchFormView(
                  key: const ValueKey('form'),
                  gsmCtrl: _gsmCtrl,
                  nomCtrl: _nomCtrl,
                  prenomCtrl: _prenomCtrl,
                  emailCtrl: _emailCtrl,
                  pageSize: _pageSize,
                  onPageSizeChanged: (v) => setState(() => _pageSize = v),
                  onSearch: _runSearch,
                ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Corps formulaire — micro, 4 champs, bouton Rechercher, sélecteur 10/50
// UI     : ScrollView + ClientPageSizeSelector fixé en bas de l'écran.
// Auteur : H.AMIZIANI
// ---------------------------------------------------------------------------
class _SearchFormView extends StatelessWidget {
  final TextEditingController gsmCtrl;
  final TextEditingController nomCtrl;
  final TextEditingController prenomCtrl;
  final TextEditingController emailCtrl;
  final int pageSize;
  final ValueChanged<int> onPageSizeChanged;
  final VoidCallback onSearch;

  const _SearchFormView({
    super.key,
    required this.gsmCtrl,
    required this.nomCtrl,
    required this.prenomCtrl,
    required this.emailCtrl,
    required this.pageSize,
    required this.onPageSizeChanged,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primarySoft, AppColors.bg],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClientMicButton(onTap: () {}),
                    const SizedBox(height: 24),
                    ClientFormField(
                      controller: gsmCtrl,
                      hint: 'Introduire le GSM du client',
                      icon: Icons.smartphone_rounded,
                      iconColor: AppColors.primary,
                      iconBg: AppColors.primarySoft,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    ClientFormField(
                      controller: nomCtrl,
                      hint: 'Nom du client',
                      icon: Icons.badge_outlined,
                      iconColor: AppColors.info,
                      iconBg: const Color(0xFFDBEAFE),
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 12),
                    ClientFormField(
                      controller: prenomCtrl,
                      hint: 'Prénom du client',
                      icon: Icons.person_outline_rounded,
                      iconColor: AppColors.tertiary,
                      iconBg: const Color(0xFFE0F2FE),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 12),
                    ClientFormField(
                      controller: emailCtrl,
                      hint: 'E-mail du client',
                      icon: Icons.mail_outline_rounded,
                      iconColor: AppColors.primaryDark,
                      iconBg: AppColors.primarySoft,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: onSearch,
                      icon: const Icon(Icons.search_rounded),
                      label: const Text(
                        'Rechercher',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ClientPageSizeSelector(value: pageSize, onChanged: onPageSizeChanged),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Corps résultats — loading, erreur, vide ou ListView cartes client
// UI     : AnimatedSwitcher depuis le formulaire ; compteur dans le header scaffold.
// Auteur : H.AMIZIANI
// ---------------------------------------------------------------------------
class _ResultsView extends StatelessWidget {
  final ClientSearchState state;
  final VoidCallback onRetry;

  const _ResultsView({
    super.key,
    required this.state,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.results.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_search_rounded, size: 64, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text(
              'Aucun client trouvé',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      itemCount: state.results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _ClientCard(client: state.results[index]),
    );
  }
}

// ---------------------------------------------------------------------------
// Carte client — bande bleue gauche, rail fidélité, détails contact
// UI     : IntrinsicHeight + Row stretch pour aligner la barre latérale primary.
// Auteur : H.AMIZIANI
// ---------------------------------------------------------------------------
class _ClientCard extends StatelessWidget {
  final ClientItem client;

  const _ClientCard({required this.client});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.07),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 4, color: AppColors.primary),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ClientSideRail(client: client),
                          const SizedBox(width: 12),
                          Expanded(child: _ClientDetails(client: client)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Colonne gauche carte — avatar, badge %, panier +
// UI     : Largeur fixe 54 dp ; gradient primary sur le badge fidélité.
// Auteur : H.AMIZIANI
// ---------------------------------------------------------------------------
class _ClientSideRail extends StatelessWidget {
  final ClientItem client;

  const _ClientSideRail({required this.client});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      child: Column(
        children: [
          _AvatarBadge(kind: client.avatarKind),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              '${client.loyaltyPercent}%',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {},
              child: const Padding(
                padding: EdgeInsets.all(7),
                child: Icon(
                  Icons.add_shopping_cart_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// UI : Icône décorative (branche, feuilles, rose) selon ClientAvatarKind.
/// Auteur : H.AMIZIANI
class _AvatarBadge extends StatelessWidget {
  final ClientAvatarKind kind;

  const _AvatarBadge({required this.kind});

  @override
  Widget build(BuildContext context) {
    final (icon, color, bg) = switch (kind) {
      ClientAvatarKind.branch => (
          Icons.park_outlined,
          AppColors.secondary,
          const Color(0xFFECEFF1),
        ),
      ClientAvatarKind.leaves => (
          Icons.eco_rounded,
          AppColors.success,
          const Color(0xFFD1FAE5),
        ),
      ClientAvatarKind.rose => (
          Icons.local_florist_rounded,
          AppColors.orange,
          const Color(0xFFFFEDD5),
        ),
    };

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Icon(icon, color: color, size: 26),
    );
  }
}

// ---------------------------------------------------------------------------
// Colonne droite carte — nom, e-mail, GSM, naissance, adresse
// UI     : _DetailRow avec pastille icône colorée par type d'information.
// Auteur : H.AMIZIANI
// ---------------------------------------------------------------------------
class _ClientDetails extends StatelessWidget {
  final ClientItem client;

  const _ClientDetails({required this.client});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailRow(
          icon: Icons.storefront_rounded,
          iconColor: AppColors.primary,
          child: Text(
            client.fullName,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w800,
              fontSize: 14.5,
            ),
          ),
        ),
        if (client.email.isNotEmpty) ...[
          const SizedBox(height: 6),
          _DetailRow(
            icon: Icons.email_outlined,
            iconColor: AppColors.info,
            child: Text(client.email, style: const TextStyle(fontSize: 13)),
          ),
        ],
        if (client.phone.isNotEmpty) ...[
          const SizedBox(height: 6),
          _DetailRow(
            icon: Icons.phone_in_talk_rounded,
            iconColor: AppColors.tertiary,
            child: Text(
              client.phone,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
        if (client.birthLine.isNotEmpty) ...[
          const SizedBox(height: 6),
          _DetailRow(
            icon: Icons.cake_outlined,
            iconColor: AppColors.primary,
            child: Text(client.birthLine, style: const TextStyle(fontSize: 13)),
          ),
        ],
        if (client.address != null && client.address!.isNotEmpty) ...[
          const SizedBox(height: 6),
          _DetailRow(
            icon: Icons.location_on_outlined,
            iconColor: AppColors.textMuted,
            child: Text(client.address!, style: const TextStyle(fontSize: 12.5)),
          ),
        ],
      ],
    );
  }
}

/// UI : Ligne icône + texte dans une carte client (_ClientDetails).
/// Auteur : H.AMIZIANI
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _DetailRow({
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 8),
        Expanded(child: Padding(padding: const EdgeInsets.only(top: 3), child: child)),
      ],
    );
  }
}
