import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState    = ref.watch(authProvider);
    final collab       = authState.collaborateur!;
    final authNotifier = ref.read(authProvider.notifier);
    final photoUrl     = authNotifier.getPhotoUrl(collab.codeCollab);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Mon Profil'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [

            // ─── En-tête bleu avec photo ────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36),
              decoration: BoxDecoration(
                color: Colors.blue[700],
                borderRadius: const BorderRadius.only(
                  bottomLeft:  Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue[300],
                    backgroundImage: photoUrl.isNotEmpty
                        ? NetworkImage(photoUrl)
                        : null,
                    onBackgroundImageError: photoUrl.isNotEmpty
                        ? (_, __) {}
                        : null,
                    child: photoUrl.isEmpty
                        ? Text(
                      _initiales(collab.prenom, collab.nom),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                        : null,
                  ),
                  const SizedBox(height: 14),

                  // Nom complet
                  Text(
                    collab.fullName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Badge rôle
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      collab.typeCollabLibelle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ─── Infos ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    children: [
                      _buildInfoTile(
                        icon:  Icons.badge_outlined,
                        label: 'Code collaborateur',
                        value: collab.codeCollab.toString(),
                      ),
                      _divider(),
                      _buildInfoTile(
                        icon:  Icons.email_outlined,
                        label: 'Email',
                        value: collab.email.isNotEmpty
                            ? collab.email
                            : 'Non renseigné',
                      ),
                      _divider(),
                      _buildInfoTile(
                        icon:  Icons.phone_outlined,
                        label: 'Téléphone',
                        value: collab.tel != null && collab.tel!.isNotEmpty
                            ? collab.tel!
                            : 'Non renseigné',
                      ),
                      _divider(),
                      _buildInfoTile(
                        icon:  Icons.store_outlined,
                        label: 'Magasin',
                        value: collab.magasinNom,
                      ),
                      if (collab.estAdministrateur) ...[
                        _divider(),
                        _buildInfoTile(
                          icon:  Icons.admin_panel_settings_outlined,
                          label: 'Rôle',
                          value: 'Administrateur',
                          valueColor: Colors.orange[700],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue[600]),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[500],
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: valueColor ?? Colors.black87,
        ),
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, indent: 56);

  String _initiales(String prenom, String nom) {
    final p = prenom.isNotEmpty ? prenom[0].toUpperCase() : '';
    final n = nom.isNotEmpty   ? nom[0].toUpperCase()    : '';
    return '$p$n';
  }
}