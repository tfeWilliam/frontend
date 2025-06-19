import 'package:flutter/material.dart';

import '../../pages/payment/paiement_sucess_page.dart';

class RouteService {
  // Singleton pattern
  static final RouteService _instance = RouteService._internal();
  factory RouteService() => _instance;
  RouteService._internal();

  // Méthode pour générer les routes à la demande
  Route<dynamic>? generateRoute(RouteSettings settings) {
    // Extrait le nom de la route et les arguments
    final name = settings.name;
    final arguments = settings.arguments;

    // Gère chaque route spécifique
    switch (name) {
      case '/paiement_success':
      // Crée la route uniquement lorsqu'elle est demandée
        return MaterialPageRoute(
          builder: (context) => PaiementSuccessScreen(
            sessionId: arguments is Map<String, dynamic> ? arguments['sessionId'] : null,
          ),
          settings: settings,
        );

      default:
      // Retourne null pour les routes inconnues (laissez le navigateur principal les gérer)
        return null;
    }
  }

  // Méthode pour naviguer vers l'écran de succès de paiement
  void navigateToPaiementSuccess(BuildContext context, String? sessionId) {
    Navigator.of(context).pushNamed(
      '/paiement_success',
      arguments: {'sessionId': sessionId},
    );
  }
}
