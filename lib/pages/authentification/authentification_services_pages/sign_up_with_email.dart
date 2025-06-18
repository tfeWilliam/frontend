////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//          FONCTIONNALITÉ D'INSCRIPTION UTILISATEUR PAR E-MAIL                 //
//                                                                            //
//  Ce fichier contient la logique métier pour l'inscription d'un nouvel      //
//  utilisateur via e-mail et mot de passe en utilisant Firebase              //
//  Authentication. Il gère la création de l'utilisateur, l'envoi de l'e-mail //
//  de vérification, et l'affichage des retours à l'utilisateur (dialogues    //
//  de confirmation ou messages d'erreur).                                    //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../login_page.dart';

/// Gère le processus complet d'inscription d'un utilisateur avec e-mail et mot de passe.
///
/// Cette fonction asynchrone effectue les étapes suivantes :
/// 1. Crée un nouvel utilisateur dans Firebase Authentication.
/// 2. Envoie un e-mail de vérification à l'adresse fournie.
/// 3. Affiche une boîte de dialogue informant l'utilisateur de vérifier sa boîte de réception.
/// 4. Redirige l'utilisateur vers la page de connexion après confirmation.
/// 5. Gère les erreurs spécifiques à Firebase et les autres exceptions en affichant un `SnackBar`.
///
/// [context] : Le `BuildContext` pour afficher les dialogues et les SnackBars.
/// [email] : L'adresse e-mail pour le nouveau compte.
/// [password] : Le mot de passe pour le nouveau compte.
///
/// Retourne `true` si l'utilisateur a été créé avec succès, `false` sinon.
Future<bool> signUpWithEmail(
    BuildContext context,
    String email,
    String password,
    ) async {
  try {
    // Étape 1 : Tente de créer un nouvel utilisateur avec les informations fournies.
    final UserCredential userCredential =
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Récupère l'objet User nouvellement créé.
    final user = userCredential.user;

    // Étape 2 : Si l'utilisateur est créé et que son e-mail n'est pas encore vérifié.
    if (user != null && !user.emailVerified) {
      // Envoie l'e-mail de vérification.
      await user.sendEmailVerification();

      // Vérification de sécurité : s'assure que le widget est toujours "monté" (visible)
      // avant d'interagir avec le BuildContext, pour éviter les erreurs si l'utilisateur
      // a quitté la page pendant l'opération asynchrone.
      if (!context.mounted) return false;

      // Étape 3 : Affiche une boîte de dialogue pour informer l'utilisateur.
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Confirme ton adresse e-mail"),
          content: const Text(
              "Un lien de vérification a été envoyé. Clique dessus depuis ta boîte mail."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Ferme la popup.
                // Étape 4 : Redirige l'utilisateur vers la page de connexion.
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
              child: const Text("OK"),
            )
          ],
        ),
      );
    }

    // Retourne `true` pour indiquer que le processus s'est bien déroulé.
    return true;

  } on FirebaseAuthException catch (e) {
    // Capture les erreurs spécifiques à Firebase (ex: e-mail déjà utilisé, mot de passe faible).
    String message = e.message ?? "Une erreur s'est produite";
    debugPrint(message); // Affiche l'erreur dans la console de débogage.

    if (!context.mounted) return false;
    // Affiche l'erreur à l'utilisateur dans un SnackBar.
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    return false; // Indique l'échec.

  } catch (e) {
    // Capture toutes les autres erreurs potentielles (ex: problème réseau).
    debugPrint("Erreur inconnue : $e");

    if (!context.mounted) return false;
    // Affiche un message d'erreur générique.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Une erreur inattendue est survenue.")),
    );
    return false; // Indique l'échec.
  }
}








// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
//
// import '../login_page.dart';
//
// Future<bool> signUpWithEmail(
//     BuildContext context,
//     String email,
//     String password,
//     ) async {
//   try {
//     final UserCredential userCredential =
//     await FirebaseAuth.instance.createUserWithEmailAndPassword(
//       email: email,
//       password: password,
//     );
//
//     final user = userCredential.user;
//
//     if (user != null && !user.emailVerified) {
//       await user.sendEmailVerification();
//
//       if (!context.mounted) return false;
//
//       await showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: const Text("Confirme ton adresse e-mail"),
//           content: const Text(
//               "Un lien de vérification a été envoyé. Clique dessus depuis ta boîte mail."),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop(); // ferme la popup
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(builder: (_) => const LoginPage()),
//                 ); // redirige vers Login
//               },
//               child: const Text("OK"),
//             )
//           ],
//         ),
//       );
//     }
//
//     return true;
//   } on FirebaseAuthException catch (e) {
//     String message = e.message ?? "Une erreur s'est produite";
//     debugPrint(message);
//     if (!context.mounted) return false;
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
//     return false;
//   } catch (e) {
//     debugPrint("Erreur inconnue : $e");
//     if (!context.mounted) return false;
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Une erreur inattendue est survenue.")),
//     );
//     return false;
//   }
// }
