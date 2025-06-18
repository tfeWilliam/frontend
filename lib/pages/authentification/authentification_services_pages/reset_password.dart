////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//          FONCTIONNALITÉ DE RÉINITIALISATION DE MOT DE PASSE                  //
//                                                                            //
//  Ce fichier contient les fonctions nécessaires pour gérer le processus de  //
//  réinitialisation de mot de passe via Firebase Authentication. Il expose   //
//  une fonction publique `showResetPasswordDialog` qui affiche une boîte de  //
//  dialogue à l'utilisateur, et utilise une fonction privée `_sendResetEmail`//
//  pour communiquer avec Firebase.                                           //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Affiche une boîte de dialogue modale pour permettre à l'utilisateur de
/// saisir son adresse e-mail afin de réinitialiser son mot de passe.
///
/// [context] : Le `BuildContext` actuel, nécessaire pour afficher la boîte de dialogue.
Future<void> showResetPasswordDialog(BuildContext context) async {
  // Contrôleur pour récupérer le texte saisi par l'utilisateur dans le champ email.
  final TextEditingController resetEmailCtrl = TextEditingController();

  return showDialog(
    context: context,
    builder: (context) {
      // Construit et retourne l'AlertDialog.
      return AlertDialog(
        // Le titre de la boîte de dialogue.
        title: const Text("Réinitialiser le mot de passe"),
        // Le contenu principal : un champ de saisie pour l'e-mail.
        content: TextField(
          controller: resetEmailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: "Entrez votre email"),
        ),
        // Les boutons d'action en bas de la boîte de dialogue.
        actions: [
          // Bouton pour annuler et fermer la boîte de dialogue.
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Annuler"),
          ),
          // Bouton pour soumettre la demande de réinitialisation.
          ElevatedButton(
            onPressed: () async {
              // Récupère l'e-mail et supprime les espaces superflus.
              final email = resetEmailCtrl.text.trim();
              // Ferme la boîte de dialogue avant d'effectuer l'action asynchrone.
              Navigator.of(context).pop();
              // Appelle la fonction privée pour envoyer l'e-mail.
              await _sendResetEmail(context, email);
            },
            child: const Text("Envoyer"),
          ),
        ],
      );
    },
  );
}

/// Fonction privée qui communique avec Firebase pour envoyer l'e-mail de
/// réinitialisation de mot de passe.
///
/// [context] : Le `BuildContext` pour afficher les `SnackBar` de feedback.
/// [email] : L'adresse e-mail à qui envoyer le lien de réinitialisation.
Future<void> _sendResetEmail(BuildContext context, String email) async {
  try {
    // Appelle la méthode de Firebase Authentication pour envoyer l'e-mail.
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    // Si l'envoi réussit, affiche un message de confirmation.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("📧 Email de réinitialisation envoyé !")),
    );
  } catch (e) {
    // Si une erreur se produit (ex: e-mail non trouvé), affiche un message d'erreur.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Erreur : ${e.toString()}")),
    );
  }
}





// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
//
// Future<void> showResetPasswordDialog(BuildContext context) async {
//   final TextEditingController resetEmailCtrl = TextEditingController();
//
//   return showDialog(
//     context: context,
//     builder: (context) {
//       return AlertDialog(
//         title: const Text("Réinitialiser le mot de passe"),
//         content: TextField(
//           controller: resetEmailCtrl,
//           keyboardType: TextInputType.emailAddress,
//           decoration: const InputDecoration(labelText: "Entrez votre email"),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text("Annuler"),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               final email = resetEmailCtrl.text.trim();
//               Navigator.of(context).pop();
//               await _sendResetEmail(context, email);
//             },
//             child: const Text("Envoyer"),
//           ),
//         ],
//       );
//     },
//   );
// }
//
// Future<void> _sendResetEmail(BuildContext context, String email) async {
//   try {
//     await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("📧 Email de réinitialisation envoyé !")),
//     );
//   } catch (e) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("Erreur : ${e.toString()}")),
//     );
//   }
// }
