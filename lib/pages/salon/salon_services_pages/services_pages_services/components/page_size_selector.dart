/// *************************************************************************************************
///
/// BANNER : EXPLICATION GÉNÉRALE DU WIDGET
///
/// Ce fichier définit `PageSizeSelector`, un widget Flutter stateless.
///
/// Objectif :
/// Ce widget fournit une interface utilisateur simple et réutilisable pour permettre à
/// l'utilisateur de choisir le nombre d'éléments à afficher par page dans une liste ou
/// une grille paginée.
///
/// Fonctionnement :
/// 1.  Le widget se présente sous la forme d'un `IconButton`.
/// 2.  Lorsque l'utilisateur appuie sur l'icône, une feuille modale (`ModalBottomSheet`)
/// apparaît depuis le bas de l'écran.
/// 3.  Cette feuille modale contient des boutons pour chaque option de taille de page
/// disponible (par exemple, 5, 10, 20).
/// 4.  Le bouton correspondant à la taille de page actuellement sélectionnée est
/// visuellement mis en évidence.
/// 5.  Lorsque l'utilisateur sélectionne une nouvelle taille, la feuille se ferme et
/// la fonction de rappel `onChanged` est exécutée avec la nouvelle valeur,
/// permettant au widget parent de se mettre à jour.
///
///*************************************************************************************************
library;

import 'package:flutter/material.dart';

/// Un widget qui affiche un bouton pour sélectionner le nombre d'éléments par page.
class PageSizeSelector extends StatelessWidget {
  /// La taille de page actuellement sélectionnée.
  final int currentSize;
  /// La liste des options de taille de page disponibles.
  final List<int> options;
  /// La fonction de rappel exécutée lorsqu'une nouvelle taille est sélectionnée.
  final void Function(int) onChanged;
  /// La couleur utilisée pour mettre en évidence la sélection active.
  final Color color;

  /// Constructeur pour le widget `PageSizeSelector`.
  const PageSizeSelector({
    super.key,
    required this.currentSize,
    required this.onChanged,
    this.options = const [5, 10, 20], // Options par défaut si non fournies.
    this.color = const Color(0xFF7B61FF), // Couleur par défaut si non fournie.
  });

  @override
  Widget build(BuildContext context) {
    // Le widget est un simple bouton avec une icône.
    return IconButton(
      icon: const Icon(Icons.format_list_numbered),
      tooltip: "Nombre d'éléments par page",
      // Lorsque le bouton est pressé, on affiche la feuille modale.
      onPressed: () {
        showModalBottomSheet(
          context: context,
          // Le constructeur de la feuille modale.
          builder: (context) {
            return Container(
              padding: const EdgeInsets.all(16),
              // Utilise MainAxisSize.min pour que la feuille ne prenne que la hauteur nécessaire.
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Éléments par page",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  // Une rangée pour afficher les boutons d'options.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    // Crée un bouton pour chaque option de taille disponible.
                    children: options.map((size) {
                      // Détermine si cette option est celle actuellement sélectionnée.
                      final isSelected = size == currentSize;
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          // La couleur du bouton dépend de s'il est sélectionné ou non.
                          backgroundColor: isSelected ? color : Colors.grey[200],
                          foregroundColor: isSelected ? Colors.white : Colors.black87,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onPressed: () {
                          // Ferme la feuille modale.
                          Navigator.pop(context);
                          // Si l'utilisateur a cliqué sur une taille différente,
                          // on appelle le callback pour mettre à jour l'état parent.
                          if (size != currentSize) onChanged(size);
                        },
                        child: Text(
                          "$size",
                          style: TextStyle(
                            // Met le texte en gras pour l'option sélectionnée.
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(), // Convertit l'itérable généré par .map en une liste de widgets.
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}







// import 'package:flutter/material.dart';
//
// class PageSizeSelector extends StatelessWidget {
//   final int currentSize;
//   final List<int> options;
//   final void Function(int) onChanged;
//   final Color color;
//
//   const PageSizeSelector({
//     super.key,
//     required this.currentSize,
//     required this.onChanged,
//     this.options = const [5, 10, 20],
//     this.color = const Color(0xFF7B61FF),
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return IconButton(
//       icon: const Icon(Icons.format_list_numbered),
//       tooltip: "Nombre de services par page",
//       onPressed: () {
//         showModalBottomSheet(
//           context: context,
//           builder: (context) {
//             return Container(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     "Services par page",
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 16),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: options.map((size) {
//                       final isSelected = size == currentSize;
//                       return ElevatedButton(
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: isSelected ? color : Colors.grey[200],
//                           foregroundColor: isSelected ? Colors.white : Colors.black87,
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                         ),
//                         onPressed: () {
//                           Navigator.pop(context);
//                           if (size != currentSize) onChanged(size);
//                         },
//                         child: Text(
//                           "$size",
//                           style: TextStyle(
//                             fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//                           ),
//                         ),
//                       );
//                     }).toList(),
//                   ),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
// }
