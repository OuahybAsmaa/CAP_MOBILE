import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/pages/welcome_page.dart';

void main() {
  runApp(
    const ProviderScope(
      child: CapMobileApp(),
    ),
  );
}

class CapMobileApp extends StatelessWidget {
  const CapMobileApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CapMobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3:    true,
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const WelcomePage(),//pour tesst chauque page je veux le mettre dans racine
      },
    );
  }
}