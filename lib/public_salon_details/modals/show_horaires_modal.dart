/// *************************************************************************************************
///
/// BANNER : EXPLICATION GÉNÉRALE DU FICHIER
///
/// Ce fichier définit une unique fonction d'assistance, `showHorairesModal`.
///
/// Objectif :
/// Afficher une boîte de dialogue (`Dialog`) stylisée et centrée qui présente les
/// horaires d'ouverture d'un salon. La fonction prend en entrée une chaîne de
/// caractères formatée et la parse pour l'afficher de manière lisible pour l'utilisateur.
///
/// Fonctionnement :
/// 1.  La fonction reçoit une chaîne `horaires` (ex: "09:00-18:00/Mon, 09:00-18:00/Tue,...").
/// 2.  Elle utilise une Map pour traduire les abréviations des jours en anglais
/// (ex: "Mon") en leurs noms complets en français ("Lundi").
/// 3.  Elle divise la chaîne pour traiter chaque jour individuellement.
/// 4.  Elle utilise `showDialog` pour afficher une `Dialog` qui contient la liste
/// formatée des jours et des heures, ainsi qu'un bouton pour la fermer.
///
///*************************************************************************************************
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Affiche une boîte de dialogue centrée présentant les horaires d'ouverture.
///
/// [context] : Le BuildContext nécessaire pour afficher le dialogue.
/// [horaires] : Une chaîne de caractères représentant les horaires, où chaque
/// entrée est séparée par une virgule (ex: "09:00-18:00/Mon, ...").
void showHorairesModal(BuildContext context, String horaires) {
  // Map pour faire la correspondance entre les abréviations des jours et leurs noms complets en français.
  final jours = {
    'Mon': 'Lundi',
    'Tue': 'Mardi',
    'Wed': 'Mercredi',
    'Thu': 'Jeudi',
    'Fri': 'Vendredi',
    'Sat': 'Samedi',
    'Sun': 'Dimanche',
  };

  // Divise la chaîne d'horaires en une liste, en supprimant les espaces superflus.
  final horairesList = horaires.split(',').map((e) => e.trim()).toList();

  // Utilise `showDialog` pour afficher une boîte de dialogue modale centrée.
  showDialog(
    context: context,
    builder: (context) {
      // Le widget `Dialog` est la base pour une fenêtre modale centrée.
      return Dialog(
        // Le fond du `Dialog` lui-même est rendu transparent.
        backgroundColor: Colors.transparent,
        // `insetPadding` contrôle l'espace autour du contenu du dialogue,
        // ce qui permet de le positionner et de le dimensionner.
        insetPadding: const EdgeInsets.fromLTRB(20, 50, 20, 100),
        // Le contenu visuel du dialogue est défini par ce `Container`.
        child: Container(
          // La décoration du `Container` définit l'apparence réelle du modal.
          decoration: BoxDecoration(
            color: Colors.white, // Fond blanc.
            borderRadius: BorderRadius.circular(20), // Bords arrondis.
          ),
          padding: const EdgeInsets.all(20), // Marge intérieure.

          // Le contenu est organisé dans une `Column`.
          child: Column(
            mainAxisSize: MainAxisSize.min, // La colonne s'adapte à la taille de son contenu.
            children: [
              // Titre du dialogue.
              Text(
                'Horaires d\'ouverture',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // Itère sur chaque entrée de la liste d'horaires pour créer une ligne de texte.
              ...horairesList.map((part) {
                // Sépare l'horaire (ex: "09:00-18:00") du code du jour (ex: "Mon").
                final split = part.split('/');
                if (split.length == 2) {
                  final horaire = split[0];
                  final jourCode = split[1];
                  // Traduit le code du jour en son nom complet.
                  final jour = jours[jourCode] ?? jourCode;
                  // Affiche une ligne stylisée pour chaque jour.
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, size: 16, color: Colors.deepPurple),
                        const SizedBox(width: 10),
                        Text(
                          '$jour : $horaire',
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }
                // Si le format est incorrect, retourne un widget vide.
                return const SizedBox.shrink();
              }),
              const SizedBox(height: 20), // Espace avant le bouton.
              // Bouton pour fermer la boîte de dialogue.
              Align(
                alignment: Alignment.center,
                child: ElevatedButton(
                  onPressed: () {
                    // Ferme le dialogue lorsque le bouton est pressé.
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text('Fermer'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}







// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
//
// void showHorairesModal(BuildContext context, String horaires) {
//   final jours = {
//     'Mon': 'Lundi',
//     'Tue': 'Mardi',
//     'Wed': 'Mercredi',
//     'Thu': 'Jeudi',
//     'Fri': 'Vendredi',
//     'Sat': 'Samedi',
//     'Sun': 'Dimanche',
//   };
//
//   final horairesList = horaires.split(',').map((e) => e.trim()).toList();
//
//   // REMPLACE showModalBottomSheet PAR showDialog
//   showDialog(
//     context: context,
//     builder: (context) {
//       return Dialog( // ENVELOPPE LE CONTENU DANS UN WIDGET Dialog
//         backgroundColor: Colors.transparent, // Rend le fond du Dialog transparent
//         // Ajuste le padding pour pousser le modal vers le haut si nécessaire.
//         // Par exemple, 50px en haut et 100px en bas pour le remonter un peu.
//         insetPadding: EdgeInsets.fromLTRB(20, 50, 20, 100), // Ajusté pour le positionnement
//         child: Container( // Le Container qui contient le contenu du modal
//           // Tu peux retirer le `shape` et `backgroundColor` du `showModalBottomSheet` précédent
//           // car maintenant le Container gère sa propre décoration.
//           decoration: BoxDecoration(
//             color: Colors.white, // Couleur de fond du modal
//             borderRadius: BorderRadius.circular(20), // Bords arrondis pour le modal centré
//           ),
//           padding: const EdgeInsets.all(20), // Padding interne pour le contenu
//
//           // Le contenu de ton modal d'horaires
//           child: Column(
//             mainAxisSize: MainAxisSize.min, // La colonne prendra la taille minimale de ses enfants
//             children: [
//               Text(
//                 'Horaires d\'ouverture',
//                 style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 16),
//               ...horairesList.map((part) {
//                 final split = part.split('/');
//                 if (split.length == 2) {
//                   final horaire = split[0];
//                   final jourCode = split[1];
//                   final jour = jours[jourCode] ?? jourCode;
//                   return Padding(
//                     padding: const EdgeInsets.symmetric(vertical: 4),
//                     child: Row(
//                       children: [
//                         const Icon(Icons.access_time, size: 16, color: Colors.deepPurple),
//                         const SizedBox(width: 10),
//                         Text(
//                           '$jour : $horaire',
//                           style: GoogleFonts.poppins(fontSize: 14),
//                         ),
//                       ],
//                     ),
//                   );
//                 }
//                 return const SizedBox.shrink();
//               }),
//               const SizedBox(height: 20), // Ajoute un peu d'espace avant le bouton
//               Align( // Ajoute un bouton de fermeture
//                 alignment: Alignment.center,
//                 child: ElevatedButton(
//                   onPressed: () {
//                     Navigator.of(context).pop();
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.deepPurple, // Exemple de couleur
//                     foregroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                   ),
//                   child: Text('Fermer'),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     },
//   );
// }