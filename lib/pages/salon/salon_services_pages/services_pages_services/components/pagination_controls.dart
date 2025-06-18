////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//             WIDGET DE CONTRÔLES DE PAGINATION RÉUTILISABLE                   //
//                                                                            //
//  Ce fichier définit `PaginationControls`, un widget `Stateless` qui        //
//  fournit une interface utilisateur standard pour la navigation entre les   //
//  pages d'une liste de données.                                             //
//                                                                            //
//  Il est conçu pour être un composant de présentation "pur" : son état      //
//  visuel (boutons activés/désactivés, numéros de page) est entièrement       //
//  déterminé par les paramètres qui lui sont fournis, et il notifie le       //
//  widget parent des actions de l'utilisateur via des callbacks.             //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;

import 'package:flutter/material.dart';

/// Un widget qui affiche des boutons "Précédent" et "Suivant" ainsi qu'un
/// indicateur de page (ex: "1 / 5").
class PaginationControls extends StatelessWidget {
  /// Le numéro de la page actuellement affichée.
  final int currentPage;
  /// Le nombre total d'éléments dans toutes les pages.
  final int totalItems;
  /// Le nombre d'éléments par page.
  final int pageSize;
  /// L'URL de la page précédente, fournie par l'API. Si `null`, le bouton "Précédent" est désactivé.
  final String? previousPageUrl;
  /// L'URL de la page suivante, fournie par l'API. Si `null`, le bouton "Suivant" est désactivé.
  final String? nextPageUrl;
  /// La fonction de callback à exécuter lorsque le bouton "Précédent" est cliqué.
  final VoidCallback onPrevious;
  /// La fonction de callback à exécuter lorsque le bouton "Suivant" est cliqué.
  final VoidCallback onNext;
  /// La couleur principale utilisée pour les boutons.
  final Color color;

  /// Constructeur pour le widget de contrôles de pagination.
  const PaginationControls({
    super.key,
    required this.currentPage,
    required this.totalItems,
    required this.pageSize,
    required this.previousPageUrl,
    required this.nextPageUrl,
    required this.onPrevious,
    required this.onNext,
    this.color = const Color(0xFF7B61FF),
  });

  @override
  Widget build(BuildContext context) {
    // Optimisation : si le nombre total d'éléments est inférieur ou égal à la taille
    // d'une page, cela signifie qu'il n'y a qu'une seule page.
    // Dans ce cas, on n'affiche aucun contrôle.
    if (totalItems <= pageSize) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // --- Bouton "Précédent" ---
          ElevatedButton.icon(
            // Le bouton est désactivé (`onPressed` est null) si `previousPageUrl` est null.
            onPressed: previousPageUrl != null ? onPrevious : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              disabledForegroundColor: Colors.grey[500],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.arrow_back),
            label: const Text("Précédent"),
          ),

          // --- Indicateur de page (ex: "2 / 10") ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              // Calcule le nombre total de pages en utilisant `ceil()` pour arrondir à l'entier supérieur.
              "$currentPage / ${(totalItems / pageSize).ceil()}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),

          // --- Bouton "Suivant" ---
          ElevatedButton.icon(
            // Le bouton est désactivé (`onPressed` est null) si `nextPageUrl` est null.
            onPressed: nextPageUrl != null ? onNext : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              disabledForegroundColor: Colors.grey[500],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.arrow_forward),
            label: const Text("Suivant"),
          ),
        ],
      ),
    );
  }
}






// import 'package:flutter/material.dart';
//
// class PaginationControls extends StatelessWidget {
//   final int currentPage;
//   final int totalItems;
//   final int pageSize;
//   final String? previousPageUrl;
//   final String? nextPageUrl;
//   final VoidCallback onPrevious;
//   final VoidCallback onNext;
//   final Color color;
//
//   const PaginationControls({
//     super.key,
//     required this.currentPage,
//     required this.totalItems,
//     required this.pageSize,
//     required this.previousPageUrl,
//     required this.nextPageUrl,
//     required this.onPrevious,
//     required this.onNext,
//     this.color = const Color(0xFF7B61FF),
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     if (totalItems <= pageSize) return const SizedBox.shrink();
//
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           // Previous button
//           ElevatedButton.icon(
//             onPressed: previousPageUrl != null ? onPrevious : null,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: color,
//               foregroundColor: Colors.white,
//               disabledBackgroundColor: Colors.grey[300],
//               disabledForegroundColor: Colors.grey[500],
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//             ),
//             icon: const Icon(Icons.arrow_back),
//             label: const Text("Précédent"),
//           ),
//
//           // Page indicator
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: Text(
//               "$currentPage / ${(totalItems / pageSize).ceil()}",
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16,
//               ),
//             ),
//           ),
//
//           // Next button
//           ElevatedButton.icon(
//             onPressed: nextPageUrl != null ? onNext : null,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: color,
//               foregroundColor: Colors.white,
//               disabledBackgroundColor: Colors.grey[300],
//               disabledForegroundColor: Colors.grey[500],
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//             ),
//             icon: const Icon(Icons.arrow_forward),
//             label: const Text("Suivant"),
//           ),
//         ],
//       ),
//     );
//   }
// }
