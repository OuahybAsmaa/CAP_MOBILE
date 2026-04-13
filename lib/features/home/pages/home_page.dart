import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/pages/profile_page.dart';
import '../../rfid/pages/rfid_page.dart';

// ──────────────────────────────────────────────────────────────
//  DESIGN TOKENS — cohérents avec WelcomePage
// ──────────────────────────────────────────────────────────────
class _C {
  static const bg          = Color(0xFFDCF4F8);
  static const surface     = Color(0xFFFFFFFF);
  static const primary     = Color(0xFF0070F3);
  static const primaryDark = Color(0xFF1E40AF);
  static const primarySoft = Color(0xFFEBF5FF);
  static const success     = Color(0xFF10B981);
  static const warning     = Color(0xFFF59E0B);
  static const error       = Color(0xFFEF4444);
  static const textPrimary   = Color(0xFF111827);
  static const textSecondary = Color(0xFF4B5563);
  static const textMuted     = Color(0xFF9CA3AF);
  static const border        = Color(0xFFD1D5DB);
}

// ──────────────────────────────────────────────────────────────
//  MODÈLE DE MODULE
// ──────────────────────────────────────────────────────────────
class _Module {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final bool available;
  final VoidCallback? onTap;

  const _Module({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bgColor,
    this.available = true,
    this.onTap,
  });
}

// ──────────────────────────────────────────────────────────────
//  HOME PAGE
// ──────────────────────────────────────────────────────────────
class HomePage extends ConsumerStatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin {

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final AnimationController _entranceCtrl;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState    = ref.watch(authProvider);
    if (authState.collaborateur == null) return const SizedBox.shrink();
    final collab       = authState.collaborateur!;
    final authNotifier = ref.read(authProvider.notifier);
    final photoUrl     = authNotifier.getPhotoUrl(collab.codeCollab);

    final modules = <_Module>[
      _Module(
        title: 'Lecteur RFID',
        subtitle: 'Encoder & lire les puces',
        icon: Icons.nfc_rounded,
        color: _C.primary,
        bgColor: _C.primarySoft,
        onTap: () => Navigator.push(
          context,
          _fadeRoute(const RfidPage()),
        ),
      ),
      _Module(
        title: 'Inventaire',
        subtitle: 'Stock & localisation RSSI',
        icon: Icons.inventory_2_rounded,
        color: const Color(0xFF059669),
        bgColor: const Color(0xFFECFDF5),
        available: false,
      ),
      _Module(
        title: 'Commandes',
        subtitle: 'Suivi & traitement',
        icon: Icons.receipt_long_rounded,
        color: const Color(0xFF7C3AED),
        bgColor: const Color(0xFFF5F3FF),
        available: false,
      ),
      _Module(
        title: 'Paiement',
        subtitle: 'Transactions en caisse',
        icon: Icons.payment_rounded,
        color: const Color(0xFFD97706),
        bgColor: const Color(0xFFFFFBEB),
        available: false,
      ),
      _Module(
        title: 'Rapports',
        subtitle: 'Analyses & statistiques',
        icon: Icons.bar_chart_rounded,
        color: const Color(0xFFDC2626),
        bgColor: const Color(0xFFFEF2F2),
        available: false,
      ),
      _Module(
        title: 'Paramètres',
        subtitle: 'Configuration terminal',
        icon: Icons.settings_rounded,
        color: _C.textSecondary,
        bgColor: const Color(0xFFF1F5F9),
        available: false,
      ),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: _C.bg,
        // ── Drawer latéral (profil + menu) ──
        drawer: _buildDrawer(context, ref, collab, photoUrl),
        body: Column(
          children: [
            // ── Top Bar fixe ──
            _buildTopBar(context, collab, photoUrl),
            // ── Contenu scrollable ──
            Expanded(
              child: _buildBody(context, collab, modules),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  //  TOP BAR
  // ────────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context, collab, String photoUrl) {
    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        boxShadow: [
          BoxShadow(
            color: _C.primary.withOpacity(.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              // ── Avatar cliquable → ouvre le drawer ──
              GestureDetector(
                onTap: () => _scaffoldKey.currentState?.openDrawer(),
                child: Stack(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _C.primary.withOpacity(.3), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: _C.primary.withOpacity(.15),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: _C.primarySoft,
                        backgroundImage: photoUrl.isNotEmpty
                            ? NetworkImage(photoUrl)
                            : null,
                        onBackgroundImageError:
                        photoUrl.isNotEmpty ? (_, __) {} : null,
                        child: photoUrl.isEmpty
                            ? Text(
                          _initiales(collab.prenom, collab.nom),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _C.primary,
                          ),
                        )
                            : null,
                      ),
                    ),
                    // Indicateur vert "connecté"
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: _C.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: _C.surface, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 14),

              // ── Titre centré ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CAP MOBILE',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _C.primaryDark,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      collab.magasinNom,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _C.textMuted,
                        letterSpacing: .5,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Icône notifications ──
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _C.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: _C.primary,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  //  DRAWER
  // ────────────────────────────────────────────────────────────
  Widget _buildDrawer(BuildContext context, WidgetRef ref, collab, String photoUrl) {
    return Drawer(
      backgroundColor: _C.surface,
      child: SafeArea(
        child: Column(
          children: [
            // ── Header profil ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_C.primaryDark, _C.primary],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(.4), width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.2),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 36,
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
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    collab.fullName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      collab.typeCollabLibelle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Menu items ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _drawerItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Mon Profil',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, _fadeRoute(const ProfilePage()));
                    },
                  ),
                  _drawerItem(
                    icon: Icons.store_outlined,
                    label: 'Mon Magasin',
                    badge: collab.magasinNom,
                  ),
                  _drawerItem(
                    icon: Icons.admin_panel_settings_outlined,
                    label: 'Administration',
                    visible: collab.estAdministrateur,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Divider(height: 1),
                  ),
                  _drawerItem(
                    icon: Icons.settings_outlined,
                    label: 'Paramètres',
                  ),
                  _drawerItem(
                    icon: Icons.help_outline_rounded,
                    label: 'Aide & Support',
                  ),
                ],
              ),
            ),

            // ── Déconnexion ──
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _C.error,
                    side: BorderSide(color: _C.error.withOpacity(.3)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text(
                    'Déconnexion',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/');
                    ref.read(authProvider.notifier).logout();
                  },
                ),
              ),
            ),

            // Version
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'CapMobile v1.0 · Zebra TC52',
                style: const TextStyle(fontSize: 11, color: _C.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    String? badge,
    bool visible = true,
    VoidCallback? onTap,
  }) {
    if (!visible) return const SizedBox.shrink();
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _C.primarySoft,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: _C.primary, size: 18),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _C.textPrimary,
        ),
      ),
      trailing: badge != null
          ? Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: _C.primarySoft,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          badge,
          style: const TextStyle(
            fontSize: 10,
            color: _C.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      )
          : const Icon(Icons.chevron_right_rounded, color: _C.textMuted, size: 18),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  // ────────────────────────────────────────────────────────────
  //  BODY
  // ────────────────────────────────────────────────────────────
  Widget _buildBody(BuildContext context, collab, List<_Module> modules) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Salutation ──
          _buildGreetingBanner(collab),
          const SizedBox(height: 28),

          // ── Section titre ──
          Row(
            children: [
              Container(width: 4, height: 20,
                decoration: BoxDecoration(
                  color: _C.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Modules disponibles',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _C.textPrimary,
                  letterSpacing: .3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Grille de modules ──
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.05,
            ),
            itemCount: modules.length,
            itemBuilder: (context, i) {
              final delay = i * 80;
              return AnimatedBuilder(
                animation: _entranceCtrl,
                builder: (_, child) {
                  final t = CurvedAnimation(
                    parent: _entranceCtrl,
                    curve: Interval(
                      (delay / 900).clamp(0, 1),
                      ((delay + 400) / 900).clamp(0, 1),
                      curve: Curves.easeOutCubic,
                    ),
                  );
                  return FadeTransition(
                    opacity: t,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, .15),
                        end: Offset.zero,
                      ).animate(t),
                      child: child,
                    ),
                  );
                },
                child: _buildModuleCard(modules[i]),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Bannière salutation ──
  Widget _buildGreetingBanner(collab) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Bonjour' : hour < 18 ? 'Bon après-midi' : 'Bonsoir';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_C.primaryDark, _C.primary],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _C.primary.withOpacity(.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting,',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  collab.prenom,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: .5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.store_rounded,
                          size: 12, color: Colors.white),
                      const SizedBox(width: 5),
                      Text(
                        collab.magasinNom,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Icône décorative
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  // ── Carte module ──
  Widget _buildModuleCard(_Module m) {
    return GestureDetector(
      onTap: m.available ? m.onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: m.available
                ? m.color.withOpacity(.15)
                : _C.border.withOpacity(.5),
          ),
          boxShadow: [
            BoxShadow(
              color: m.available
                  ? m.color.withOpacity(.10)
                  : Colors.black.withOpacity(.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: m.available ? m.bgColor : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    m.icon,
                    color: m.available ? m.color : _C.textMuted,
                    size: 24,
                  ),
                ),
                if (!m.available)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Bientôt',
                      style: TextStyle(
                        fontSize: 9,
                        color: _C.textMuted,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .5,
                      ),
                    ),
                  ),
                if (m.available)
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: m.bgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: m.color,
                      size: 14,
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              m.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: m.available ? _C.textPrimary : _C.textMuted,
                letterSpacing: .2,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              m.subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: _C.textMuted,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──
  String _initiales(String prenom, String nom) {
    final p = prenom.isNotEmpty ? prenom[0].toUpperCase() : '';
    final n = nom.isNotEmpty ? nom[0].toUpperCase() : '';
    return '$p$n';
  }

  Route _fadeRoute(Widget page) => PageRouteBuilder(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, anim, __, child) =>
        FadeTransition(opacity: anim, child: child),
    transitionDuration: const Duration(milliseconds: 300),
  );
}