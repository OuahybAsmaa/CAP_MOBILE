import 'dart:async';
import '../../features/auth/models/collaborateur_model.dart';

class AuthServiceMock {
  // faire une simualtion avec des donnes mocker
  static const Duration _delay = Duration(milliseconds: 800);

  static final Map<String, CollaborateurModel> _mockCollaborateurs = {
    '154': CollaborateurModel(
      codeCollab: 154,
      nom: 'DUPONT',
      prenom: 'Jean',
      email: 'jean.dupont@chaussea.net',
      tel: '0612345678',
      typeCollabLibelle: 'Responsable Magasin',
      estAdministrateur: true,
      codeMag: 1,
      pictureLink: '',
      mags: [
        MagasinModel(codeMag: 1, nomMag: 'Magasin Central'),
        MagasinModel(codeMag: 2, nomMag: 'Magasin Nord'),
      ],
    ),
    '123': CollaborateurModel(
      codeCollab: 123,
      nom: 'MARTIN',
      prenom: 'Sophie',
      email: 'sophie.martin@chaussea.net',
      tel: '0687654321',
      typeCollabLibelle: 'Vendeur',
      estAdministrateur: false,
      codeMag: 1,
      pictureLink: '',
      mags: [
        MagasinModel(codeMag: 1, nomMag: 'Magasin Central'),
      ],
    ),
    '456': CollaborateurModel(
      codeCollab: 456,
      nom: 'BERNARD',
      prenom: 'Pierre',
      email: 'pierre.bernard@chaussea.net',
      tel: null,
      typeCollabLibelle: 'Stagiaire',
      estAdministrateur: false,
      codeMag: 2,
      pictureLink: '',
      mags: [
        MagasinModel(codeMag: 2, nomMag: 'Magasin Nord'),
      ],
    ),
  };

  Future<CollaborateurModel> getCollaborateur(String codeCollab) async {
    // Simuler un délai réseau
    await Future.delayed(_delay);

    final trimmedCode = codeCollab.trim();
    final collaborateur = _mockCollaborateurs[trimmedCode];

    if (collaborateur != null) {
      print('[MOCK] Collaborateur trouvé: ${collaborateur.prenom} ${collaborateur.nom}');
      return collaborateur;
    } else {
      print('[MOCK] Collaborateur introuvable: $trimmedCode');
      throw Exception('Collaborateur introuvable (code: $trimmedCode)');
    }
  }

  String getPhotoUrl(int codeCollab) {
    return 'https://ui-avatars.com/api/?name=${codeCollab}&background=random&size=100';
  }

  void addMockCollaborateur(CollaborateurModel collaborateur) {
    _mockCollaborateurs[collaborateur.codeCollab.toString()] = collaborateur;
  }
}