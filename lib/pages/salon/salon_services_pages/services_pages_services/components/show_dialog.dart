////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//          FONCTIONS UTILITAIRES POUR L'AFFICHAGE DE DIALOGUES                 //
//                                                                            //
//  Ce fichier contient un ensemble de fonctions utilitaires réutilisables    //
//  pour afficher des boîtes de dialogue modales standardisées (succès et     //
//  erreur) à travers l'application.                                          //
//                                                                            //
//  L'objectif de centraliser ces fonctions est d'assurer une expérience      //
//  utilisateur cohérente pour les notifications et de simplifier leur appel  //
//  depuis n'importe quelle partie du code.                                   //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;

import 'package:flutter/material.dart';

/// Affiche une boîte de dialogue modale stylisée pour notifier l'utilisateur d'un succès.
///
/// Cette boîte de dialogue est non-bloquante et se ferme automatiquement après 1.5 secondes
/// pour une expérience utilisateur fluide.
///
/// [context] : Le `BuildContext` nécessaire pour afficher le dialogue.
/// [message] : Le message de succès personnalisé à afficher.
void showSuccessDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    // Empêche la fermeture du dialogue en cliquant à l'extérieur.
    barrierDismissible: false,
    builder: (BuildContext context) {
      // Déclenche la fermeture automatique du dialogue après un court délai.
      Future.delayed(const Duration(milliseconds: 1500), () {
        // Vérifie si le dialogue peut être fermé avant d'appeler pop.
        // Évite une erreur si l'utilisateur a navigué ailleurs entre-temps.
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
      });

      return Dialog(
        // Le fond du `Dialog` est transparent pour permettre des coins arrondis
        // et une ombre personnalisée sur le `Container` enfant.
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Le dialogue s'adapte à son contenu.
            children: [
              // Icône de succès stylisée.
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),

              // Titre du message de succès.
              const Text(
                "Succès !",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),

              // Message de succès détaillé et dynamique.
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 16),

              // Indicateur visuel de la fermeture automatique.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Fermeture automatique...",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Affiche une boîte de dialogue modale stylisée pour notifier l'utilisateur d'une erreur.
///
/// Contrairement au dialogue de succès, celui-ci nécessite une action de l'utilisateur
/// (cliquer sur "OK") pour être fermé.
///
/// [context] : Le `BuildContext` nécessaire pour afficher le dialogue.
/// [message] : Le message d'erreur personnalisé à afficher.
void showErrorDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icône d'erreur stylisée.
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error,
                  color: Colors.red,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),

              // Titre du message d'erreur.
              const Text(
                "Erreur",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),

              // Message d'erreur détaillé et dynamique.
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 20),

              // Bouton d'action pour fermer la boîte de dialogue.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "OK",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}





// // ✅ NOUVEAU : Fonction pour afficher le dialog de succès
// import 'package:flutter/material.dart';
//
// void showSuccessDialog(BuildContext context, String message) {
//   showDialog(
//     context: context,
//     barrierDismissible: false,
//     builder: (BuildContext context) {
//       // ✅ Auto-fermeture après 1.5 secondes
//       Future.delayed(const Duration(milliseconds: 1500), () {
//         if (Navigator.canPop(context)) {
//           Navigator.of(context).pop();
//         }
//       });
//
//       return Dialog(
//         backgroundColor: Colors.transparent,
//         child: Container(
//           padding: const EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(16),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.1),
//                 blurRadius: 10,
//                 offset: const Offset(0, 4),
//               ),
//             ],
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // ✅ Icône de succès
//               Container(
//                 width: 60,
//                 height: 60,
//                 decoration: BoxDecoration(
//                   color: Colors.green.withOpacity(0.1),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(
//                   Icons.check_circle,
//                   color: Colors.green,
//                   size: 40,
//                 ),
//               ),
//               const SizedBox(height: 16),
//
//               // ✅ Message de succès
//               Text(
//                 "Succès !",
//                 style: const TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.green,
//                 ),
//               ),
//               const SizedBox(height: 8),
//
//               Text(
//                 message,
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: Colors.grey[700],
//                 ),
//               ),
//               const SizedBox(height: 16),
//
//               // ✅ Indicateur de fermeture automatique
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const SizedBox(
//                     width: 16,
//                     height: 16,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                       valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   Text(
//                     "Fermeture automatique...",
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: Colors.grey[500],
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       );
//     },
//   );
// }
//
// // ✅ NOUVEAU : Fonction pour afficher le dialog d'erreur
// void showErrorDialog(BuildContext context, String message) {
//   showDialog(
//     context: context,
//     builder: (BuildContext context) {
//       return Dialog(
//         backgroundColor: Colors.transparent,
//         child: Container(
//           padding: const EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(16),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.1),
//                 blurRadius: 10,
//                 offset: const Offset(0, 4),
//               ),
//             ],
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // ✅ Icône d'erreur
//               Container(
//                 width: 60,
//                 height: 60,
//                 decoration: BoxDecoration(
//                   color: Colors.red.withOpacity(0.1),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(
//                   Icons.error,
//                   color: Colors.red,
//                   size: 40,
//                 ),
//               ),
//               const SizedBox(height: 16),
//
//               // ✅ Message d'erreur
//               Text(
//                 "Erreur",
//                 style: const TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.red,
//                 ),
//               ),
//               const SizedBox(height: 8),
//
//               Text(
//                 message,
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: Colors.grey[700],
//                 ),
//               ),
//               const SizedBox(height: 20),
//
//               // ✅ Bouton OK
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: () => Navigator.of(context).pop(),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.red,
//                     padding: const EdgeInsets.symmetric(vertical: 12),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   child: const Text(
//                     "OK",
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     },
//   );
// }