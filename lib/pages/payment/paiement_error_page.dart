/// **************************************************************************************
///
/// PAGE UI : ERREUR DE PAIEMENT
///
/// OBJECTIF :
/// Ce fichier définit un écran simple et statique, `PaiementErrorPage`, qui est
/// affiché à l'utilisateur lorsqu'une transaction de paiement a échoué ou a été
/// explicitement annulée.
///
/// FONCTIONNALITÉS CLÉS :
/// - C'est un `StatelessWidget` léger, car son contenu est fixe.
/// - Il informe clairement l'utilisateur de l'échec de l'opération.
/// - Il propose deux actions de navigation claires :
/// 1. "Réessayer" : Fait revenir l'utilisateur à l'écran précédent pour qu'il
/// puisse tenter à nouveau le paiement.
/// 2. "Retour à l’accueil" : Ferme toutes les pages du flux de paiement et
/// ramène l'utilisateur à la page principale de l'application.
///
///***************************************************************************************
library;
import 'package:flutter/material.dart';

/// Un écran simple affiché lorsque le processus de paiement a échoué ou a été annulé.
class PaiementErrorPage extends StatelessWidget {
  const PaiementErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Paiement échoué"),
        // Empêche l'affichage automatique d'un bouton de retour, car la navigation est gérée explicitement ci-dessous.
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: SafeArea(
          child: Center(
          child: Padding(
          padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cancel, color: Colors.red, size: 80),
          const SizedBox(height: 24),
          const Text(
            "Oups ! Le paiement a échoué ou a été annulé.",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Bouton pour revenir à l'écran précédent et tenter à nouveau le paiement.
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("Réessayer"),
          ),
          const SizedBox(height: 12),

          // Bouton pour fermer toutes les pages du flux de paiement et revenir à l'écran d'accueil.
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text("Retour à l’accueil"),
          ),
        ],
      ),
    ),
    ),
      ),
    );
  }
}






// import 'package:flutter/material.dart';
//
// class PaiementErrorPage extends StatelessWidget {
//   const PaiementErrorPage({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Paiement échoué"),
//         automaticallyImplyLeading: false,
//         centerTitle: true,
//       ),
//       body: SafeArea(
//         child: Center(
//           child: Padding(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Icon(Icons.cancel, color: Colors.red, size: 80),
//                 const SizedBox(height: 24),
//                 const Text(
//                   "Oups ! Le paiement a échoué ou a été annulé.",
//                   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 32),
//                 ElevatedButton(
//                   onPressed: () {
//                     Navigator.of(context).pop();
//                   },
//                   child: const Text("Réessayer"),
//                 ),
//                 const SizedBox(height: 12),
//                 TextButton(
//                   onPressed: () {
//                     Navigator.of(context).popUntil((route) => route.isFirst);
//                   },
//                   child: const Text("Retour à l’accueil"),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
