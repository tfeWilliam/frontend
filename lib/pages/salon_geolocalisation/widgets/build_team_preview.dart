////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                WIDGET D'APERÇU DE L'ÉQUIPE D'UN SALON                        //
//                                                                            //
//  Ce fichier définit une unique fonction de construction, `buildTeamPreview`,//
//  qui retourne un widget `Stateless` conçu pour afficher un aperçu compact  //
//  de l'équipe d'une coiffeuse.                                              //
//                                                                            //
//  Son rôle est de présenter de manière concise les premiers membres de      //
//  l'équipe (jusqu'à 3) et d'indiquer s'il y en a d'autres, tout en          //
//  mettant en évidence la propriétaire du salon avec un style visuel         //
//  distinct.                                                                 //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;

import 'package:flutter/material.dart';
import 'package:hairbnb/models/salon_details_geo.dart';

/// La couleur primaire utilisée pour le style de ce widget.
final Color primaryColor = Color(0xFF8E44AD);

/// Construit un widget qui affiche un aperçu de l'équipe d'un salon.
///
/// Il affiche les 3 premiers membres de l'équipe sous forme de puces (chips)
/// et indique le nombre de membres supplémentaires s'il y en a. Le style
/// visuel est différent pour la propriétaire du salon afin de la mettre en évidence.
///
/// [coiffeuses] : La liste complète des objets `CoiffeuseDetailsForGeo` de l'équipe.
///
/// Retourne un `Widget` prêt à être inséré dans une arborescence d'widgets.
Widget buildTeamPreview(List<CoiffeuseDetailsForGeo> coiffeuses) {
  return Padding(
    padding: const EdgeInsets.only(top: 16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre de la section.
        Text(
          "L'équipe :",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: primaryColor),
        ),
        const SizedBox(height: 8),

        // Le widget `Wrap` permet aux puces de passer à la ligne suivante si l'espace est insuffisant.
        Wrap(
          spacing: 8, // Espace horizontal entre les puces.
          runSpacing: 8, // Espace vertical entre les lignes de puces.
          // Ne prend que les 3 premiers membres de l'équipe pour l'aperçu.
          children: coiffeuses.take(3).map<Widget>((coiffeuse) {
            // Construit une puce (chip) pour chaque membre de l'équipe.
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                // La couleur de fond change si la coiffeuse est la propriétaire.
                color: coiffeuse.estProprietaire
                    ? primaryColor.withOpacity(0.1)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min, // La puce prend la taille de son contenu.
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: coiffeuse.estProprietaire
                        ? primaryColor.withOpacity(0.2)
                        : Colors.transparent,
                    // MODIFIÉ: Pour le moment, on utilise juste une icône (photo_profil pas dans le nouveau modèle)
                    child: Icon(
                      Icons.person,
                      size: 16,
                      color: coiffeuse.estProprietaire ? primaryColor : Colors.grey[500],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    coiffeuse.prenom,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: coiffeuse.estProprietaire ? primaryColor : Colors.grey[800],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),

        // Affiche un texte indiquant le nombre de membres supplémentaires s'il y en a plus de 3.
        if (coiffeuses.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              "+${coiffeuses.length - 3} autres",
              style: TextStyle(fontSize: 12, color: Colors.grey[500], fontStyle: FontStyle.italic),
            ),
          ),
      ],
    ),
  );
}




// import 'package:flutter/material.dart';
// import 'package:hairbnb/models/salon_details_geo.dart';
//
// final Color primaryColor = Color(0xFF8E44AD);
//
// Widget buildTeamPreview(List<CoiffeuseDetailsForGeo> coiffeuses) {
//   return Padding(
//     padding: const EdgeInsets.only(top: 16.0),
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           "L'équipe :",
//           style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: primaryColor),
//         ),
//         SizedBox(height: 8),
//         Wrap(
//           spacing: 8,
//           runSpacing: 8,
//           children: coiffeuses.take(3).map<Widget>((coiffeuse) {
//             return Container(
//               padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//               decoration: BoxDecoration(
//                 color: coiffeuse.estProprietaire
//                     ? primaryColor.withOpacity(0.1)
//                     : Colors.grey[100],
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   CircleAvatar(
//                     radius: 12,
//                     backgroundColor: coiffeuse.estProprietaire
//                         ? primaryColor.withOpacity(0.2)
//                         : Colors.transparent,
//                     // MODIFIÉ: Pour le moment, on utilise juste une icône (photo_profil pas dans le nouveau modèle)
//                     child: Icon(
//                       Icons.person,
//                       size: 16,
//                       color: coiffeuse.estProprietaire ? primaryColor : Colors.grey[500],
//                     ),
//                   ),
//                   SizedBox(width: 6),
//                   Text(
//                     coiffeuse.prenom,
//                     style: TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.w500,
//                       color: coiffeuse.estProprietaire ? primaryColor : Colors.grey[800],
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           }).toList(),
//         ),
//         if (coiffeuses.length > 3)
//           Padding(
//             padding: EdgeInsets.only(top: 8),
//             child: Text(
//               "+${coiffeuses.length - 3} autres",
//               style: TextStyle(fontSize: 12, color: Colors.grey[500], fontStyle: FontStyle.italic),
//             ),
//           ),
//       ],
//     ),
//   );
// }