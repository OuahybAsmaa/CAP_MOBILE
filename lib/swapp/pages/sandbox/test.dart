import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: Test()));
}

class Test extends StatelessWidget {
  const Test({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ma page Test')),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Texte 1
            const Text(
              'Connexion',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            // Champ de saisie 1
            const TextField(
              decoration: InputDecoration(
                labelText: 'Nom utilisateur',
                hintText: 'Entrez votre nom',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // Champ de saisie 2
            const TextField(
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                hintText: 'Entrez votre mot de passe',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),

            const SizedBox(height: 20),

            // Texte 2
            const Text('Veuillez saisir vos informations'),

            const SizedBox(height: 30),

            // Bouton
            ElevatedButton(
              onPressed: () {
                print('Bouton cliqué');
              },
              child: const Text('Se connecter'),
            ),
          ],
        ),
      ),
    );
  }
}
