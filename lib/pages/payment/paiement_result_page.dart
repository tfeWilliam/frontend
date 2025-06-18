////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//             PAGE D'AFFICHAGE DU RÉSULTAT D'UN PAIEMENT                     //
//                                                                            //
//  Ce fichier définit l'écran `PaiementResultPage`, qui est une page de      //
//  feedback affichée à l'utilisateur immédiatement après une tentative de    //
//  paiement.                                                                 //
//                                                                            //
//  Ce widget est conçu pour être générique et peut afficher soit un message  //
//  de succès, soit un message d'échec, en adaptant dynamiquement son contenu //
//  (textes, icônes, couleurs, actions des boutons) en fonction du booléen     //
//  `success` qui lui est passé en paramètre.                                 //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;

import 'package:flutter/material.dart';

/// Un `StatelessWidget` qui affiche un écran de résultat (succès ou échec)
/// après une transaction de paiement.
class PaiementResultPage extends StatelessWidget {
  /// Un booléen indiquant si le paiement a réussi (`true`) ou échoué (`false`).
  final bool success;
  /// L'identifiant du rendez-vous associé, affiché en cas de succès.
  final int rendezVousId;
  /// La fonction de callback à exécuter lorsque l'utilisateur appuie sur le bouton principal.
  final Function() onContinue;

  /// Constructeur de la page de résultat de paiement.
  const PaiementResultPage({
    required this.success,
    required this.rendezVousId,
    required this.onContinue,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Le titre de la page change en fonction du succès ou de l'échec.
        title: Text(success ? "Paiement réussi" : "Paiement échoué"),
        centerTitle: true,
        // Désactive la flèche de retour automatique pour forcer l'utilisateur
        // à utiliser les boutons d'action définis sur la page.
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Affiche une icône de succès ou d'erreur en fonction du résultat.
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: success ? Colors.green : Colors.red,
                size: 80,
              ),

              const SizedBox(height: 24),

              // Affiche un titre de statut clair et coloré.
              Text(
                success
                    ? "Paiement confirmé !"
                    : "Échec du paiement",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: success ? Colors.green : Colors.red,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Affiche un message détaillé expliquant la situation à l'utilisateur.
              Text(
                success
                    ? "Votre réservation a été confirmée avec succès. Merci de faire confiance à Hairbnb!"
                    : "Une erreur est survenue lors du traitement de votre paiement. Veuillez réessayer ou contacter le support.",
                style: const TextStyle(
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Affiche le numéro de référence du rendez-vous uniquement en cas de succès.
              if (success)
                Text(
                  "Référence: RDV-$rendezVousId",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: 32),

              // Bouton d'action principal. Le texte et l'action changent en fonction du résultat.
              ElevatedButton(
                // Exécute la fonction de callback fournie lors du clic.
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: success ? Colors.green : Colors.blue,
                ),
                child: Text(
                  success
                      ? "Voir mes rendez-vous"
                      : "Réessayer",
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Bouton d'action secondaire pour fermer la page ou retourner à l'accueil.
              TextButton(
                onPressed: () {
                  // Ferme la page de résultat actuelle et retourne à la page précédente.
                  Navigator.of(context).pop();
                },
                child: Text(
                  success
                      ? "Retour à l'accueil"
                      : "Annuler",
                  style: TextStyle(
                    fontSize: 16,
                    color: success ? Colors.black54 : Colors.red,
                  ),
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
// class PaiementResultPage extends StatelessWidget {
//   final bool success;
//   final int rendezVousId;
//   final Function() onContinue;
//
//   const PaiementResultPage({
//     required this.success,
//     required this.rendezVousId,
//     required this.onContinue,
//     super.key,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(success ? "Paiement réussi" : "Paiement échoué"),
//         centerTitle: true,
//         automaticallyImplyLeading: false, // Désactive le bouton retour
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               // Icône de statut
//               Icon(
//                 success ? Icons.check_circle : Icons.error,
//                 color: success ? Colors.green : Colors.red,
//                 size: 80,
//               ),
//
//               const SizedBox(height: 24),
//
//               // Titre du statut
//               Text(
//                 success
//                     ? "Paiement confirmé !"
//                     : "Échec du paiement",
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: success ? Colors.green : Colors.red,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//
//               const SizedBox(height: 16),
//
//               // Message détaillé
//               Text(
//                 success
//                     ? "Votre réservation a été confirmée avec succès. Merci de faire confiance à Hairbnb!"
//                     : "Une erreur est survenue lors du traitement de votre paiement. Veuillez réessayer ou contacter le support.",
//                 style: const TextStyle(
//                   fontSize: 16,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//
//               const SizedBox(height: 16),
//
//               // Numéro de référence
//               if (success)
//                 Text(
//                   "Référence: RDV-$rendezVousId",
//                   style: const TextStyle(
//                     fontWeight: FontWeight.bold,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//
//               const SizedBox(height: 32),
//
//               // Bouton de continuation
//               ElevatedButton(
//                 onPressed: onContinue,
//                 style: ElevatedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   backgroundColor: success ? Colors.green : Colors.blue,
//                 ),
//                 child: Text(
//                   success
//                       ? "Voir mes rendez-vous"
//                       : "Réessayer",
//                   style: const TextStyle(
//                     fontSize: 18,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//
//               const SizedBox(height: 16),
//
//               // Bouton secondaire
//               TextButton(
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                 },
//                 child: Text(
//                   success
//                       ? "Retour à l'accueil"
//                       : "Annuler",
//                   style: TextStyle(
//                     fontSize: 16,
//                     color: success ? Colors.black54 : Colors.red,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }