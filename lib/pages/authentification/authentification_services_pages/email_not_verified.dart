////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                PAGE D'ATTENTE DE VÉRIFICATION D'EMAIL                      //
//                                                                            //
//  Ce fichier définit l'interface `EmailNotVerifiedPage`, qui est affichée   //
//  aux utilisateurs qui viennent de s'inscrire mais n'ont pas encore cliqué   //
//  sur le lien de vérification envoyé à leur adresse e-mail.                  //
//                                                                            //
//  Cette page a plusieurs objectifs :                                        //
//  - Informer l'utilisateur de l'état de son compte.                         //
//  - Lui permettre de renvoyer l'e-mail de vérification.                     //
//  - Lui permettre de confirmer manuellement après avoir vérifié son e-mail. //
//  - Offrir une porte de sortie pour retourner à la page de connexion.        //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../profil/profil_creation_page.dart';
import '../login_page.dart';

/// Un widget qui représente l'écran affiché lorsqu'un utilisateur
/// doit vérifier son adresse e-mail après son inscription.
class EmailNotVerifiedPage extends StatelessWidget {
  /// L'adresse e-mail de l'utilisateur, affichée dans le message d'information.
  final String email;

  /// Constructeur de la page, nécessitant l'e-mail de l'utilisateur.
  const EmailNotVerifiedPage({super.key, required this.email});

  /// Déclenche l'envoi d'un nouvel e-mail de vérification à l'utilisateur.
  /// Affiche une confirmation ou une erreur via un `SnackBar`.
  Future<void> _resendVerificationEmail(BuildContext context) async {
    // Récupère l'utilisateur Firebase actuellement connecté.
    final user = FirebaseAuth.instance.currentUser;
    try {
      // Appelle la méthode Firebase pour envoyer l'e-mail.
      await user?.sendEmailVerification();
      // Affiche un message de succès.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email de vérification renvoyé.")),
      );
    } catch (e) {
      // Affiche un message en cas d'erreur (ex: trop de demandes).
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: ${e.toString()}")),
      );
    }
  }

  /// Vérifie auprès de Firebase si l'utilisateur a bien vérifié son e-mail.
  Future<void> _checkVerificationStatus(BuildContext context) async {
    // `reload()` est crucial pour rafraîchir l'état de l'utilisateur depuis les serveurs Firebase.
    await FirebaseAuth.instance.currentUser?.reload();
    final user = FirebaseAuth.instance.currentUser;

    // Si l'utilisateur existe et que la propriété `emailVerified` est maintenant `true`.
    if (user != null && user.emailVerified) {
      // Redirige l'utilisateur vers la page de création de profil pour finaliser l'inscription.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileCreationPage(
            email: user.email ?? '',
            userUuid: user.uid,
          ),
        ),
      );
    } else {
      // Si l'e-mail n'est toujours pas vérifié, en informe l'utilisateur.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email toujours non vérifié.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Arrière-plan utilisant la couleur primaire du thème.
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- Section d'information visuelle ---
              const Icon(Icons.mail_lock_outlined, color: Colors.white, size: 80),
              const SizedBox(height: 20),
              Text(
                "Votre email $email n'a pas encore été vérifié.",
                style: const TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // --- Bouton pour renvoyer l'e-mail ---
              ElevatedButton.icon(
                onPressed: () => _resendVerificationEmail(context),
                icon: const Icon(Icons.refresh),
                label: const Text("Renvoyer l'email de vérification"),
              ),
              const SizedBox(height: 15),

              // --- Bouton pour confirmer la vérification ---
              ElevatedButton.icon(
                onPressed: () => _checkVerificationStatus(context),
                icon: const Icon(Icons.verified_user),
                label: const Text("J'ai confirmé mon email"),
                // Style distinct pour l'action principale.
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 15),

              // --- Lien pour retourner à la page de connexion ---
              TextButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                ),
                child: const Text("Retour à la connexion", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}






// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import '../../profil/profil_creation_page.dart';
// import '../login_page.dart';
//
// class EmailNotVerifiedPage extends StatelessWidget {
//   final String email;
//
//   const EmailNotVerifiedPage({super.key, required this.email});
//
//   Future<void> _resendVerificationEmail(BuildContext context) async {
//     final user = FirebaseAuth.instance.currentUser;
//     try {
//       await user?.sendEmailVerification();
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Email de vérification renvoyé.")),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Erreur: ${e.toString()}")),
//       );
//     }
//   }
//
//   Future<void> _checkVerificationStatus(BuildContext context) async {
//     await FirebaseAuth.instance.currentUser?.reload();
//     final user = FirebaseAuth.instance.currentUser;
//
//     if (user != null && user.emailVerified) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (_) => ProfileCreationPage(
//             email: user.email ?? '',
//             userUuid: user.uid,
//           ),
//         ),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Email toujours non vérifié.")),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Theme.of(context).primaryColor,
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(32.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(Icons.mail_lock_outlined, color: Colors.white, size: 80),
//               const SizedBox(height: 20),
//               Text(
//                 "Votre email $email n'a pas encore été vérifié.",
//                 style: const TextStyle(color: Colors.white, fontSize: 18),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 30),
//               ElevatedButton.icon(
//                 onPressed: () => _resendVerificationEmail(context),
//                 icon: const Icon(Icons.refresh),
//                 label: const Text("Renvoyer l'email de vérification"),
//               ),
//               const SizedBox(height: 15),
//               ElevatedButton.icon(
//                 onPressed: () => _checkVerificationStatus(context),
//                 icon: const Icon(Icons.verified_user),
//                 label: const Text("J'ai confirmé mon email"),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.white,
//                   foregroundColor: Theme.of(context).primaryColor,
//                 ),
//               ),
//               const SizedBox(height: 15),
//               TextButton(
//                 onPressed: () => Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(builder: (context) => const LoginPage()),
//                 ),
//                 child: const Text("Retour à la connexion", style: TextStyle(color: Colors.white)),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }