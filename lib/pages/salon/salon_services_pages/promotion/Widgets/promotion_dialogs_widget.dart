/// *************************************************************************************************
///
/// BANNER : EXPLICATION GÉNÉRALE DU FICHIER
///
/// Ce fichier contient des fonctions utilitaires pour afficher des boîtes de dialogue
/// (`AlertDialog`) standards liées à la gestion des promotions.
///
/// Objectif :
/// Centraliser la logique d'affichage des dialogues pour des actions comme la suppression,
/// afin de rendre le code plus propre, réutilisable et facile à maintenir.
///
/// Fonction(s) définie(s) :
/// - `showDeletePromotionDialog`: Affiche une boîte de dialogue demandant à l'utilisateur
/// de confirmer la suppression d'une promotion avant de procéder.
///
///*************************************************************************************************
library;

import 'package:flutter/material.dart';
import '../../../../../models/promotion_full.dart';
import '../services/promotion_service.dart';

/// Affiche une boîte de dialogue de confirmation pour supprimer une promotion.
///
/// [context] : Le `BuildContext` nécessaire pour afficher le dialogue et la SnackBar.
/// [promotionFull] : L'objet promotion contenant l'ID nécessaire pour la suppression.
/// [onSuccess] : Une fonction de rappel (`callback`) qui est exécutée uniquement si
/// la suppression réussit. Utile pour rafraîchir l'interface utilisateur.
Future<void> showDeletePromotionDialog({
  required BuildContext context,
  required PromotionFull promotionFull,
  required VoidCallback onSuccess,
}) async {
  // `showDialog` est la fonction Flutter standard pour afficher une fenêtre modale.
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Supprimer la promotion'),
      content: const Text('Êtes-vous sûr de vouloir supprimer cette promotion ? Cette action est irréversible.'),
      actions: [
        // Bouton pour annuler l'opération.
        TextButton(
          // `Navigator.pop(context)` ferme simplement la boîte de dialogue actuelle.
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        // Bouton pour confirmer la suppression.
        TextButton(
          onPressed: () async {
            // BONNE PRATIQUE : On capture le ScaffoldMessenger AVANT de fermer le dialogue.
            // Si on le fait après, le 'context' pourrait ne plus être valide, ce qui causerait une erreur.
            final messenger = ScaffoldMessenger.of(context);

            // On ferme la boîte de dialogue de confirmation immédiatement pour une meilleure expérience utilisateur.
            Navigator.pop(context);

            // Appel asynchrone au service pour effectuer la suppression.
            final result = await PromotionService.deletePromotion(promotionFull.id);

            // Vérifie si l'opération a réussi en se basant sur la réponse du service.
            if (result['success'] == true) {
              // Affiche une SnackBar de succès.
              messenger.showSnackBar(
                SnackBar(
                  content: Text(result['message']),
                  backgroundColor: Colors.green,
                ),
              );
              // Exécute le callback `onSuccess` pour permettre à la page appelante de se mettre à jour.
              onSuccess();
            } else {
              // En cas d'échec, affiche une SnackBar d'erreur.
              messenger.showSnackBar(
                SnackBar(
                  content: Text(result['error'] ?? "Une erreur inconnue est survenue."),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          // Style le bouton en rouge pour indiquer une action destructive.
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Supprimer'),
        ),
      ],
    ),
  );
}








// // lib/ui/widgets/promotion_dialogs.dart
// import 'package:flutter/material.dart';
// import '../../../../../models/promotion_full.dart';
// import '../services/promotion_service.dart';
//
//
// Future<void> showDeletePromotionDialog({
//   required BuildContext context,
//   required PromotionFull promotionFull,
//   required VoidCallback onSuccess,
// }) async {
//   showDialog(
//     context: context,
//     builder: (context) => AlertDialog(
//       title: const Text('Supprimer la promotion'),
//       content: const Text('Êtes-vous sûr de vouloir supprimer cette promotion ?'),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: const Text('Annuler'),
//         ),
//         TextButton(
//           onPressed: () async {
//             final messenger = ScaffoldMessenger.of(context); // ✅ capturé avant pop
//             Navigator.pop(context);
//
//             final result = await PromotionService.deletePromotion(promotionFull.id);
//
//             if (result['success'] == true) {
//               messenger.showSnackBar(
//                 SnackBar(
//                   content: Text(result['message']),
//                   backgroundColor: Colors.green,
//                 ),
//               );
//               onSuccess();
//             } else {
//               messenger.showSnackBar(
//                 SnackBar(
//                   content: Text(result['error'] ?? "Erreur inconnue"),
//                   backgroundColor: Colors.red,
//                 ),
//               );
//             }
//           },
//           style: TextButton.styleFrom(foregroundColor: Colors.red),
//           child: const Text('Supprimer'),
//         ),
//       ],
//     ),
//   );
// }
//
