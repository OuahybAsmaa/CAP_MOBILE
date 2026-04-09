import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

// ──────────────────────────────────────────────────────────────
//  DESIGN TOKENS
// ──────────────────────────────────────────────────────────────
class _C {
  static const bg          = Color(0xFFDCF4F8);
  static const surface     = Color(0xFFFFFFFF);
  static const primary     = Color(0xFF0070F3);
  static const primaryDark = Color(0xFF1E40AF);
  static const primarySoft = Color(0xFFEBF5FF);
  static const success     = Color(0xFF10B981);
  static const error       = Color(0xFFEF4444);
  static const textPrimary   = Color(0xFF111827);
  static const textSecondary = Color(0xFF4B5563);
  static const textMuted     = Color(0xFF9CA3AF);
  static const border        = Color(0xFFD1D5DB);
}

// ──────────────────────────────────────────────────────────────
//  PROFILE PAGE
// ──────────────────────────────────────────────────────────────
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage>
    with SingleTickerProviderStateMixin {

  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, .08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState    = ref.watch(authProvider);
    final collab       = authState.collaborateur!;
    final authNotifier = ref.read(authProvider.notifier);
    final photoUrl     = authNotifier.getPhotoUrl(collab.codeCollab);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: CustomScrollView(
          slivers: [
            // ── AppBar personnalisée ──
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              backgroundColor: _C.primaryDark,
              elevation: 0,
              leading: IconButton(
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: _buildHeader(collab, photoUrl),
              ),
            ),

            // ── Contenu ──
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Infos personnelles ──
                        _sectionTitle('Informations personnelles'),
                        const SizedBox(height: 12),
                        _buildInfoCard([
                          _InfoRow(
                            icon: Icons.badge_outlined,
                            label: 'Code collaborateur',
                            value: collab.codeCollab.toString(),
                            color: _C.primary,
                          ),
                          _InfoRow(
                            icon: Icons.person_outline_rounded,
                            label: 'Nom complet',
                            value: collab.fullName,
                            color: _C.primary,
                          ),
                          _InfoRow(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: collab.email.isNotEmpty
                                ? collab.email
                                : 'Non renseigné',
                            color: _C.primary,
                          ),
                          _InfoRow(
                            icon: Icons.phone_outlined,
                            label: 'Téléphone',
                            value: collab.tel != null && collab.tel!.isNotEmpty
                                ? collab.tel!
                                : 'Non renseigné',
                            color: _C.primary,
                          ),
                        ]),

                        const SizedBox(height: 24),

                        // ── Informations magasin ──
                        _sectionTitle('Magasin & rôle'),
                        const SizedBox(height: 12),
                        _buildInfoCard([
                          _InfoRow(
                            icon: Icons.store_outlined,
                            label: 'Magasin',
                            value: collab.magasinNom,
                            color: const Color(0xFF059669),
                          ),
                          _InfoRow(
                            icon: Icons.work_outline_rounded,
                            label: 'Type collaborateur',
                            value: collab.typeCollabLibelle,
                            color: const Color(0xFF059669),
                          ),
                          if (collab.estAdministrateur)
                            _InfoRow(
                              icon: Icons.admin_panel_settings_outlined,
                              label: 'Droits',
                              value: 'Administrateur',
                              color: const Color(0xFFD97706),
                              chip: true,
                            ),
                        ]),

                        const SizedBox(height: 32),

                        // ── Bouton déconnexion ──
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _C.error,
                              side: BorderSide(color: _C.error.withOpacity(.3)),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.logout_rounded, size: 18),
                            label: const Text(
                              'Se déconnecter',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            onPressed: () {
                              ref.read(authProvider.notifier).logout();
                              Navigator.of(context).pushReplacementNamed('/');
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header avec avatar ──
  Widget _buildHeader(collab, String photoUrl) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_C.primaryDark, _C.primary],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Avatar avec ring
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 98,
                  height: 98,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(.3),
                      width: 3,
                    ),
                  ),
                ),
                CircleAvatar(
                  radius: 44,
                  backgroundColor: Colors.white.withOpacity(.2),
                  backgroundImage: photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl)
                      : null,
                  onBackgroundImageError:
                  photoUrl.isNotEmpty ? (_, __) {} : null,
                  child: photoUrl.isEmpty
                      ? Text(
                    _initiales(collab.prenom, collab.nom),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  )
                      : null,
                ),
                // Badge statut
                Positioned(
                  right: 0,
                  bottom: 2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _C.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              collab.fullName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: .3,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                collab.typeCollabLibelle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Section titre ──
  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: _C.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: _C.textPrimary,
            letterSpacing: .2,
          ),
        ),
      ],
    );
  }

  // ── Carte d'infos ──
  Widget _buildInfoCard(List<_InfoRow> rows) {
    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _C.primary.withOpacity(.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final isLast = e.key == rows.length - 1;
          return Column(
            children: [
              _buildInfoTile(e.value),
              if (!isLast)
                const Divider(height: 1, indent: 58, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoTile(_InfoRow row) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: row.color.withOpacity(.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(row.icon, color: row.color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _C.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                row.chip
                    ? Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: row.color.withOpacity(.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    row.value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: row.color,
                    ),
                  ),
                )
                    : Text(
                  row.value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _C.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initiales(String prenom, String nom) {
    final p = prenom.isNotEmpty ? prenom[0].toUpperCase() : '';
    final n = nom.isNotEmpty ? nom[0].toUpperCase() : '';
    return '$p$n';
  }
}

// Modèle interne
class _InfoRow {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool chip;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.chip = false,
  });
}