/// *****************************************************************************
///
/// SERVICE D'AUTHENTIFICATION
///
/// Ce fichier définit la classe `AuthService` qui gère l'authentification des
/// utilisateurs via des services externes, ici spécifiquement avec Google.
///
/// Le processus est le suivant :
/// 1. Tente de connecter l'utilisateur avec son compte Google.
/// 2. Utilise les identifiants Google pour authentifier l'utilisateur auprès de
/// Firebase Auth.
/// 3. Une fois authentifié sur Firebase, il vérifie dans une base de données
/// externe (PostgreSQL) si un profil utilisateur associé existe déjà.
/// 4. En fonction de l'existence du profil, il redirige l'utilisateur soit vers
/// la page d'accueil (`HomePage`), soit vers la page de création de profil
/// (`ProfileCreationPage`).
///
///*****************************************************************************
library;

// Importation des bibliothèques nécessaires
import 'dart:convert'; // Pour encoder et décoder le format JSON

import 'package:firebase_auth/firebase_auth.dart'; // Pour l'authentification Firebase
import 'package:google_sign_in/google_sign_in.dart'; // Pour la connexion avec Google
import 'package:flutter/material.dart'; // Pour les widgets et outils de l'interface utilisateur Flutter
import 'package:hairbnb/pages/home_page.dart'; // Page d'accueil de l'application

import '../../pages/profil/profil_creation_page.dart'; // Page de création de profil

/// Classe statique fournissant des méthodes pour l'authentification.
class AuthService {
  // Fournit une instance pour effectuer des requêtes HTTP.
  // NOTE : Actuellement initialisé à null, nécessite une implémentation (ex: package http).
  static get http => null;

  /// Gère le processus de connexion avec un compte Google.
  ///
  /// [context] est le BuildContext de l'interface pour pouvoir gérer la navigation
  /// et afficher des messages (SnackBar).
  static Future<void> signInWithGoogle(BuildContext context) async {
    try {
      // Ouvre la fenêtre de sélection de compte Google.
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Si `googleUser` est null, cela signifie que l'utilisateur a fermé la fenêtre
      // sans se connecter. On arrête donc le processus.
      if (googleUser == null) {
        return;
      }

      // Récupère les jetons d'authentification (accessToken, idToken) du compte Google.
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      // Crée un objet "credential" spécifique à Firebase à partir des jetons Google.
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Utilise le "credential" pour connecter l'utilisateur à Firebase.
      final userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      // Vérifie si la connexion à Firebase a bien retourné un utilisateur.
      if (userCredential.user != null) {
        // Récupère l'objet utilisateur de Firebase.
        final user = userCredential.user!;
        // Extrait l'identifiant unique (UID) fourni par Firebase.
        final userUuid = user.uid;
        // Extrait l'email de l'utilisateur (avec une valeur par défaut si non disponible).
        final email = user.email ?? "";

        // Appelle la méthode pour vérifier si un profil est déjà enregistré dans notre base de données.
        final bool hasProfile = await _checkUserProfile(userUuid);

        // Si le profil existe, redirige vers la page principale.
        if (hasProfile) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else {
          // Sinon, redirige vers la page de création de profil en passant l'UID et l'email.
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileCreationPage(
                userUuid: userUuid,
                email: email,
              ),
            ),
          );
        }
      }
    } catch (e) {
      // En cas d'erreur durant le processus, l'affiche dans la console de débogage.
      debugPrint("Erreur lors de la connexion Google : $e");
      // Affiche un message d'erreur à l'utilisateur via une SnackBar.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de la connexion Google")),
      );
    }
  }

  /// Vérifie si un profil utilisateur existe dans la base de données PostgreSQL
  /// en interrogeant une API backend.
  ///
  /// [userUuid] est l'identifiant unique de l'utilisateur Firebase.
  /// Retourne `true` si le profil existe, sinon `false`.
  static Future<bool> _checkUserProfile(String userUuid) async {
    // Définit l'URL de l'API backend à appeler.
    final url = Uri.parse("https://www.hairbnb.site/api/check-user-profile/");
    try {
      // Effectue une requête HTTP POST vers l'API.
      final response = await http.post(
        url,
        // Spécifie que le corps de la requête est au format JSON.
        headers: {"Content-Type": "application/json"},
        // Encode l'UID de l'utilisateur en JSON pour l'envoyer dans le corps de la requête.
        body: jsonEncode({"userUuid": userUuid}),
      );

      // Si la requête a réussi (code de statut HTTP 200).
      if (response.statusCode == 200) {
        // Décode la réponse JSON reçue du serveur.
        final data = json.decode(response.body);
        // Retourne vrai si la réponse indique que le profil existe.
        return data['status'] == 'exists';
      }
    } catch (e) {
      // En cas d'erreur lors de l'appel à l'API, l'affiche dans la console.
      debugPrint("Erreur lors de la vérification du profil : $e");
    }
    // Par défaut, ou en cas d'erreur, on considère que le profil n'existe pas.
    return false;
  }
}




// import 'dart:convert';
//
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:flutter/material.dart';
// import 'package:hairbnb/pages/home_page.dart';
//
// import '../../pages/profil/profil_creation_page.dart';
//
// class AuthService {
//   static get http => null;
//
//   static Future<void> signInWithGoogle(BuildContext context) async {
//     try {
//       final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
//       if (googleUser == null) {
//         // L'utilisateur a annulé la connexion
//         return;
//       }
//
//       final GoogleSignInAuthentication googleAuth =
//       await googleUser.authentication;
//
//       final OAuthCredential credential = GoogleAuthProvider.credential(
//         accessToken: googleAuth.accessToken,
//         idToken: googleAuth.idToken,
//       );
//
//       // Authentifiez-vous avec Firebase
//       final userCredential =
//       await FirebaseAuth.instance.signInWithCredential(credential);
//
//       if (userCredential.user != null) {
//         final user = userCredential.user!;
//         final userUuid = user.uid; // Firebase UID
//         final email = user.email ?? "";
//
//         // Vérifie si le profil existe dans PostgreSQL
//         final bool hasProfile = await _checkUserProfile(userUuid);
//
//         if (hasProfile) {
//           // Rediriger vers la page d'accueil si le profil existe
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (context) => const HomePage()),
//           );
//         } else {
//           // Rediriger vers la page de création de profil
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//               builder: (context) => ProfileCreationPage(
//                 userUuid: userUuid,
//                 email: email,
//               ),
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       debugPrint("Erreur lors de la connexion Google : $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Erreur lors de la connexion Google")),
//       );
//     }
//   }
//
//   // Méthode pour vérifier si le profil existe dans la base PostgreSQL
//   static Future<bool> _checkUserProfile(String userUuid) async {
//     final url = Uri.parse("https://www.hairbnb.site/api/check-user-profile/");
//     try {
//       final response = await http.post(
//         url,
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode({"userUuid": userUuid}),
//       );
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         return data['status'] == 'exists'; // Retourne 'true' si le profil existe
//       }
//     } catch (e) {
//       debugPrint("Erreur lors de la vérification du profil : $e");
//     }
//     return false; // Par défaut, retourne 'false'
//   }
// }