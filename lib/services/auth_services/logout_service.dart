/// *************************************************************************************************
/// *
/// BANNIÈRE : SERVICE DE GESTION DE LA DÉCONNEXION UTILISATEUR                                     *
/// -------------------------------------------------------------                                   *
/// *
/// OBJECTIF :                                                                                      *
/// Ce fichier définit la classe `LogoutService`, qui encapsule toute la logique nécessaire         *
/// pour déconnecter un utilisateur de l'application de manière sécurisée et propre.                *
/// *
/// FONCTIONNALITÉS PRINCIPALES :                                                                   *
/// 1. CONFIRMATION UTILISATEUR : Fournit une méthode `confirmLogout` qui affiche une boîte de      *
/// dialogue modale pour demander à l'utilisateur de confirmer son intention de se déconnecter,    *
/// évitant ainsi les déconnexions accidentelles.                                                 *
/// 2. DÉCONNEXION DE FIREBASE : Gère la déconnexion effective de la session utilisateur auprès     *
/// de Firebase Authentication.                                                                   *
/// 3. NETTOYAGE DE L'ÉTAT LOCAL : Réinitialise l'état de l'utilisateur dans l'application en       *
/// vidant les données du `CurrentUserProvider`. C'est une étape cruciale pour s'assurer        *
/// qu'aucune donnée de l'ancien utilisateur ne persiste après la déconnexion.                   *
/// 4. REDIRECTION : Redirige l'utilisateur vers la page de connexion (`LoginPage`) et efface      *
/// l'historique de navigation pour empêcher tout retour en arrière vers des pages protégées.      *
/// 5. GESTION D'ERREURS : Inclut une gestion des erreurs pour les cas où le processus de           *
/// déconnexion échouerait, informant l'utilisateur via une `SnackBar`.                            *
/// *
///*************************************************************************************************
library;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../pages/authentification/login_page.dart';
import '../providers/current_user_provider.dart';

/// Classe statique fournissant des méthodes pour gérer la déconnexion de l'utilisateur.
class LogoutService {
  // Verrou statique pour s'assurer qu'un seul processus de déconnexion est en cours à la fois.
  static bool isProcessing = false;

  /// Affiche une boîte de dialogue pour que l'utilisateur confirme sa volonté de se déconnecter.
  static Future<void> confirmLogout(BuildContext context) async {
    // Empêche le lancement de plusieurs dialogues de déconnexion si l'un est déjà actif.
    if (isProcessing) return;
    isProcessing = true;

    // Affiche une boîte de dialogue et attend la réponse de l'utilisateur (true/false).
    final bool shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Déconnexion'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: [
            // Bouton pour annuler la déconnexion.
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            // Bouton pour confirmer la déconnexion.
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Déconnexion'),
            ),
          ],
        );
      },
      // Si l'utilisateur ferme la boîte de dialogue sans choisir, la valeur par défaut est `false`.
    ) ?? false;

    // Si l'utilisateur a confirmé, on procède à la déconnexion.
    if (shouldLogout) {
      await logout(context);
    }

    // Libère le verrou une fois le processus terminé.
    isProcessing = false;
  }

  /// Exécute le processus complet de déconnexion.
  static Future<void> logout(BuildContext context) async {
    try {
      // Étape 1 : Déconnecte l'utilisateur de Firebase Authentication.
      await FirebaseAuth.instance.signOut();

      // Étape 2 : Réinitialise les données de l'utilisateur dans le `CurrentUserProvider`.
      // `listen: false` est utilisé car nous sommes dans un événement et n'avons pas besoin de reconstruire ce widget.
      Provider.of<CurrentUserProvider>(context, listen: false).clearUser();

      // Étape 3 : Redirige vers la page de connexion et supprime toutes les routes précédentes.
      // Ceci empêche l'utilisateur de revenir aux écrans précédents avec le bouton "retour".
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
      );
    } catch (e) {
      // En cas d'erreur, affiche un message dans la console et une SnackBar à l'utilisateur.
      debugPrint("Erreur lors de la déconnexion : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de la déconnexion.")),
      );
    }
  }
}





// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:provider/provider.dart';
// import '../../pages/authentification/login_page.dart';
// import '../providers/current_user_provider.dart';
//
// class LogoutService {
//   static bool isProcessing = false;
//
//   /// Affiche une boîte de dialogue pour confirmer la déconnexion
//   static Future<void> confirmLogout(BuildContext context) async {
//     if (isProcessing) return; // Empêche les appels multiples
//     isProcessing = true;
//
//     final bool shouldLogout = await showDialog<bool>(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Déconnexion'),
//           content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(false),
//               child: const Text('Annuler'),
//             ),
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(true),
//               child: const Text('Déconnexion'),
//             ),
//           ],
//         );
//       },
//     ) ?? false;
//
//     if (shouldLogout) {
//       await logout(context);
//     }
//
//     isProcessing = false;
//   }
//
//   /// 🔄 Déconnexion Firebase et réinitialisation du `UserProvider`
//   static Future<void> logout(BuildContext context) async {
//     try {
//       await FirebaseAuth.instance.signOut();
//
//       // 🔥 Réinitialiser `UserProvider`
//       Provider.of<CurrentUserProvider>(context, listen: false).clearUser();
//
//       // 🔄 Redirection vers `LoginPage`
//       Navigator.pushAndRemoveUntil(
//         context,
//         MaterialPageRoute(builder: (context) => const LoginPage()),
//             (route) => false,
//       );
//     } catch (e) {
//       debugPrint("Erreur lors de la déconnexion : $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Erreur lors de la déconnexion.")),
//       );
//     }
//   }
// }