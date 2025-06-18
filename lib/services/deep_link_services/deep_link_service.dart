/// *****************************************************************************
///
/// SERVICE DE ROUTAGE (RouteService)
///
/// Ce fichier définit la classe `RouteService`, conçue pour gérer de manière
/// centralisée la génération de routes dynamiques dans l'application Flutter.
///
/// PRINCIPALES RESPONSABILITÉS :
/// 1. Utilise le design pattern Singleton pour garantir une instance unique
/// du service dans toute l'application.
/// 2. Fournit une méthode `generateRoute` destinée à être utilisée avec
/// `onGenerateRoute` de `MaterialApp`.
/// 3. Gère la navigation vers des routes spécifiques, comme l'écran de succès
/// de paiement (`/paiement_success`).
/// 4. Est capable d'extraire des paramètres depuis l'URL (query parameters, pour
/// les deep links/redirections web) ou depuis les arguments passés lors d'une
/// navigation programmatique interne.
/// 5. Offre des méthodes d'aide (ex: `MapsToPaiementSuccess`) pour
/// faciliter la navigation depuis d'autres parties du code.
///
///*****************************************************************************
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../pages/payment/paiement_sucess_page.dart';

/// Un service pour gérer la génération et la logique de navigation des routes.
/// Implémente le pattern Singleton pour n'avoir qu'une seule instance.
class RouteService {
  // Instance unique et statique du service.
  static final RouteService _instance = RouteService._internal();

  // Constructeur factory qui retourne toujours la même instance `_instance`.
  factory RouteService() => _instance;

  // Constructeur privé pour empêcher la création d'autres instances.
  RouteService._internal();

  /// Méthode d'aide pour naviguer vers l'écran de succès de paiement.
  ///
  /// Utilise la navigation nommée et passe le [sessionId] via les `arguments`.
  /// [context] : Le contexte de build actuel pour accéder au Navigator.
  /// [sessionId] : L'identifiant de session de paiement à transmettre à l'écran suivant.
  void navigateToPaiementSuccess(BuildContext context, String? sessionId) {
    Navigator.of(context).pushNamed(
      '/paiement_success', // Le nom de la route à appeler.
      arguments: {'sessionId': sessionId}, // Passe le sessionId dans un Map.
    );
  }

  /// Génère une route dynamiquement en fonction des [settings] fournis.
  ///
  /// Cette méthode est conçue pour être branchée sur `onGenerateRoute` dans `MaterialApp`.
  /// Elle analyse le nom de la route et ses arguments pour construire la page appropriée.
  Route<dynamic>? generateRoute(RouteSettings settings) {
    // Affiche dans la console la route en cours de traitement pour le débogage.
    if (kDebugMode) {
      print('Génération de route pour: ${settings.name}');
    }

    // Récupère le nom de la route depuis les settings. Peut être null.
    final String routeName = settings.name ?? '';

    // Transforme le nom de la route en objet Uri pour pouvoir facilement
    // analyser le chemin et les paramètres de requête (ex: ?session_id=...).
    final Uri uri = Uri.parse(routeName);

    // Extrait le chemin de base de l'URI, sans les paramètres.
    String path = uri.path;
    // Nettoie le chemin en retirant le premier '/' s'il existe.
    if (path.startsWith('/')) {
      path = path.substring(1);
    }

    // Utilise une structure switch pour gérer les différentes routes connues.
    switch (path) {
      case 'paiement_success':
        String? sessionId;

        // Tente de récupérer le 'session_id' de deux manières, avec une priorité.

        // Priorité 1: Vérifier les paramètres de requête de l'URL.
        // C'est utile pour les redirections depuis un site web (ex: après un paiement Stripe).
        if (uri.queryParameters.containsKey('session_id')) {
          sessionId = uri.queryParameters['session_id'];
          if (kDebugMode) {
            print('Session ID trouvé dans les query parameters: $sessionId');
          }
        }
        // Priorité 2: Si non trouvé, vérifier les arguments passés à `pushNamed`.
        // C'est le cas pour la navigation interne à l'application.
        else if (settings.arguments is Map<String, dynamic>) {
          sessionId = (settings.arguments as Map<String, dynamic>)['sessionId'];
          if (kDebugMode) {
            print('Session ID trouvé dans les arguments: $sessionId');
          }
        }

        // Retourne une MaterialPageRoute qui construit l'écran `PaiementSuccessScreen`.
        return MaterialPageRoute(
          builder: (context) => PaiementSuccessScreen(sessionId: sessionId),
          settings: settings, // Transmet les settings originaux à la nouvelle route.
        );

    // Ajoutez ici d'autres 'case' pour d'autres routes dynamiques.

      default:
      // Si la route n'est pas reconnue par ce service, on l'affiche en console.
        if (kDebugMode) {
          print('Route inconnue: $path');
        }
        // Retourne null pour indiquer à Flutter qu'il doit utiliser un autre mécanisme
        // pour gérer la route (par exemple, la table de routes statiques `routes`).
        return null;
    }
  }
}







// import 'package:flutter/material.dart';
// import '../../pages/payment/paiement_sucess_page.dart'; // Votre chemin ajusté
//
// class RouteService {
//   // Singleton pattern
//   static final RouteService _instance = RouteService._internal();
//   factory RouteService() => _instance;
//   RouteService._internal();
//
//   // Ajout de la méthode navigateToPaiementSuccess
//   void navigateToPaiementSuccess(BuildContext context, String? sessionId) {
//     Navigator.of(context).pushNamed(
//       '/paiement_success',
//       arguments: {'sessionId': sessionId},
//     );
//   }
//
//   // Méthode de génération de route appelée par onGenerateRoute
//   Route<dynamic>? generateRoute(RouteSettings settings) {
//     print('Génération de route pour: ${settings.name}');
//
//     // Récupérer le nom de la route et les arguments
//     final String routeName = settings.name ?? '';
//
//     // Si routeName contient des paramètres de requête
//     final Uri uri = Uri.parse(routeName);
//
//     // Extraire le chemin principal (sans query parameters)
//     String path = uri.path;
//     if (path.startsWith('/')) {
//       path = path.substring(1); // Enlever le slash initial si présent
//     }
//
//     // Vérifier la route
//     switch (path) {
//       case 'paiement_success':
//       // Récupérer session_id des query parameters ou des arguments
//         String? sessionId;
//
//         // D'abord essayer depuis les query parameters
//         if (uri.queryParameters.containsKey('session_id')) {
//           sessionId = uri.queryParameters['session_id'];
//           print('Session ID trouvé dans les query parameters: $sessionId');
//         }
//         // Ensuite essayer depuis les arguments (pour navigation programmatique)
//         else if (settings.arguments is Map<String, dynamic>) {
//           sessionId = (settings.arguments as Map<String, dynamic>)['sessionId'];
//           print('Session ID trouvé dans les arguments: $sessionId');
//         }
//
//         return MaterialPageRoute(
//           builder: (context) => PaiementSuccessScreen(sessionId: sessionId),
//           settings: settings,
//         );
//
//     // Vous pouvez ajouter d'autres routes spéciales ici
//
//       default:
//         print('Route inconnue: $path');
//         return null; // Laisser le système de routes par défaut gérer le reste
//     }
//   }
// }
//
