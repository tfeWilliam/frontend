////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                ÉCRAN DE CONFIRMATION DE PAIEMENT RÉUSSI                      //
//                                                                            //
//  Ce fichier définit l'écran `PaiementSuccessScreen`, une page statique     //
//  qui est affichée à l'utilisateur pour confirmer que sa transaction de     //
//  paiement a été traitée avec succès.                                       //
//                                                                            //
//  Son rôle est de fournir un retour visuel clair et positif, d'afficher     //
//  optionnellement une référence de transaction, et de fournir une action    //
//  pour retourner à l'accueil de l'application, en nettoyant la pile de      //
//  navigation pour empêcher l'utilisateur de revenir en arrière dans le      //
//  tunnel de paiement.                                                       //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;

import 'package:flutter/material.dart';

/// Un `StatelessWidget` qui affiche un écran de succès après un paiement.
class PaiementSuccessScreen extends StatelessWidget {
  /// L'identifiant de la session de paiement Stripe, peut être nul.
  final String? sessionId;

  /// Constructeur de la page de succès.
  /// Le `sessionId` peut être passé directement ou via les arguments de la route.
  const PaiementSuccessScreen({super.key, this.sessionId});

  @override
  Widget build(BuildContext context) {
    // Tente de récupérer le sessionId depuis les arguments de la route
    // si celui-ci n'a pas été fourni directement via le constructeur.
    // Cela rend le widget plus flexible.
    String? routeSessionId = sessionId;
    if (routeSessionId == null) {
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments != null && arguments is Map<String, dynamic>) {
        routeSessionId = arguments['sessionId'] as String?;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement Confirmé'),
        backgroundColor: Colors.green,
        // Empêche l'affichage automatique du bouton "retour" dans l'AppBar.
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Section d'information visuelle ---
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 100,
              ),
              const SizedBox(height: 24),
              const Text(
                'Paiement réussi !',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Votre réservation a été confirmée avec succès.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),

              // --- Affiche l'ID de session s'il est disponible ---
              if (routeSessionId != null) ...[
                const SizedBox(height: 12),
                Text(
                  'ID de session: $routeSessionId',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
              const SizedBox(height: 32),

              // --- Bouton d'action principal ---
              ElevatedButton(
                onPressed: () {
                  // Navigue vers la page d'accueil et supprime toutes les routes
                  // précédentes de la pile de navigation.
                  // Le prédicat `(route) => false` assure que l'utilisateur
                  // ne pourra pas revenir à l'écran de paiement.
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/home', // Assurez-vous que cette route est définie dans votre application.
                        (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text(
                  'Retour à l\'accueil',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}






// import 'package:flutter/material.dart';
//
// class PaiementSuccessScreen extends StatelessWidget {
//   final String? sessionId;
//
//   const PaiementSuccessScreen({super.key, this.sessionId});
//
//   @override
//   Widget build(BuildContext context) {
//     // Récupérer le sessionId depuis les arguments de route si pas fourni directement
//     String? routeSessionId = sessionId;
//
//     if (routeSessionId == null) {
//       final arguments = ModalRoute.of(context)?.settings.arguments;
//       if (arguments != null && arguments is Map<String, dynamic>) {
//         routeSessionId = arguments['sessionId'] as String?;
//       }
//     }
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Paiement Confirmé'),
//         backgroundColor: Colors.green,
//       ),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(
//                 Icons.check_circle_outline,
//                 color: Colors.green,
//                 size: 100,
//               ),
//               const SizedBox(height: 24),
//               const Text(
//                 'Paiement réussi !',
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 16),
//               const Text(
//                 'Votre réservation a été confirmée avec succès.',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 16),
//               ),
//               if (routeSessionId != null) ...[
//                 const SizedBox(height: 12),
//                 Text(
//                   'ID de session: $routeSessionId',
//                   style: const TextStyle(fontSize: 14, color: Colors.grey),
//                 ),
//               ],
//               const SizedBox(height: 32),
//               ElevatedButton(
//                 onPressed: () {
//                   // Retour à l'écran d'accueil ou navigation vers les détails de réservation
//                   Navigator.of(context).pushNamedAndRemoveUntil(
//                     '/home', // Remplacez par votre route d'accueil
//                         (route) => false, // Supprime toutes les routes de la pile
//                   );
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.green,
//                   padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
//                 ),
//                 child: const Text(
//                   'Retour à l\'accueil',
//                   style: TextStyle(fontSize: 16),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }