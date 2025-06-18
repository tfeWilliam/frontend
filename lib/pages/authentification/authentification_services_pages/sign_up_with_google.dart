////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//             FONCTIONNALITÉ D'INSCRIPTION VIA UN COMPTE GOOGLE                //
//                                                                            //
//  Ce fichier contient la logique métier pour l'inscription ou la connexion  //
//  d'un utilisateur via son compte Google. Il orchestre l'interaction entre  //
//  le package `google_sign_in` pour l'authentification auprès de Google, et  //
//  `firebase_auth` pour créer une session utilisateur dans l'écosystème      //
//  Firebase de l'application.                                                //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hairbnb/pages/profil/profil_creation_page.dart';

/// Gère le processus complet d'inscription ou de connexion d'un utilisateur via son compte Google.
///
/// Cette fonction asynchrone effectue les étapes suivantes :
/// 1. Déconnecte toute session Google précédente pour forcer la sélection d'un compte.
/// 2. Ouvre la fenêtre de connexion Google native pour que l'utilisateur choisisse un compte.
/// 3. Récupère les jetons d'authentification (`accessToken`, `idToken`) de Google.
/// 4. Crée une `AuthCredential` Firebase à partir de ces jetons.
/// 5. Utilise cette "credential" pour se connecter ou créer un compte dans Firebase Authentication.
/// 6. En cas de succès, redirige l'utilisateur vers la page de création de profil.
/// 7. Gère les erreurs et l'annulation par l'utilisateur.
///
/// [context] : Le `BuildContext` pour afficher les `SnackBar` et gérer la navigation.
///
/// Retourne l'objet `User` de Firebase en cas de succès, ou `null` en cas d'échec ou d'annulation.
Future<User?> signUpWithGoogle(BuildContext context) async {
  try {
    // Étape 1 : Initialisation du service de connexion Google.
    final GoogleSignIn googleSignIn = GoogleSignIn(
      // Le `clientId` est spécifique à votre application (pour les plateformes web/desktop).
      clientId: "523426514457-f6gveh52ou52p0glo5g0tjqs3hvegat2.apps.googleusercontent.com",
    );

    // Déconnecte l'utilisateur d'une éventuelle session Google précédente.
    // C'est une bonne pratique pour s'assurer que l'utilisateur peut choisir un compte.
    await googleSignIn.signOut();

    // Étape 2 : Déclenche la fenêtre de connexion Google.
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    // Si `googleUser` est nul, cela signifie que l'utilisateur a fermé la fenêtre sans se connecter.
    if (googleUser == null) {
      debugPrint("Création de compte annulée par l'utilisateur.");
      return null;
    }

    // Étape 3 : Récupération des jetons d'authentification depuis le compte Google.
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // Étape 4 : Création d'une "credential" Firebase spécifique à Google.
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Étape 5 : Utilisation de la "credential" pour se connecter à Firebase.
    // Firebase créera un nouvel utilisateur s'il n'existe pas, ou le connectera s'il existe.
    final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    final User? user = userCredential.user;

    // Étape 6 : Si la connexion à Firebase a réussi.
    if (user != null) {
      // Redirige l'utilisateur vers la page de création de profil.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileCreationPage(
            email: user.email ?? '',
            userUuid: user.uid,
          ),
        ),
      );
      // Retourne l'objet User pour indiquer le succès.
      return user;
    }

    // Retourne null si, pour une raison quelconque, l'objet user n'a pas été créé.
    return null;
  } catch (e) {
    // Étape 7 : Gestion des erreurs potentielles durant le processus.
    debugPrint("Erreur inattendue lors de la création de compte Google : $e");
    // Affiche un message d'erreur générique à l'utilisateur.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Erreur lors de la création de compte Google.")),
    );
    // Retourne null pour indiquer l'échec.
    return null;
  }
}







// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:hairbnb/pages/profil/profil_creation_page.dart';
//
// Future<User?> signUpWithGoogle(BuildContext context) async {
//   try {
//     final GoogleSignIn googleSignIn = GoogleSignIn(
//       clientId: "523426514457-f6gveh52ou52p0glo5g0tjqs3hvegat2.apps.googleusercontent.com",
//     );
//     await googleSignIn.signOut();
//
//     final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
//
//     if (googleUser == null) {
//       debugPrint("Création de compte annulée par l'utilisateur.");
//       return null;
//     }
//
//     final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
//
//     final AuthCredential credential = GoogleAuthProvider.credential(
//       accessToken: googleAuth.accessToken,
//       idToken: googleAuth.idToken,
//     );
//
//     final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
//     final User? user = userCredential.user;
//
//     if (user != null) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (context) => ProfileCreationPage(
//             email: user.email ?? '',
//             userUuid: user.uid,
//           ),
//         ),
//       );
//       return user;
//     }
//
//     return null;
//   } catch (e) {
//     debugPrint("Erreur inattendue lors de la création de compte Google : $e");
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Erreur lors de la création de compte Google.")),
//     );
//     return null;
//   }
// }
