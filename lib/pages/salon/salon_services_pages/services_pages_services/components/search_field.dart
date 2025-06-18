/// *************************************************************************************************
///
/// BANNER : EXPLICATION GÉNÉRALE DU WIDGET
///
/// Ce fichier définit `SearchField`, un widget Flutter stateless et réutilisable.
///
/// Objectif :
/// Fournir un champ de saisie de texte standardisé et stylisé pour les fonctionnalités
/// de recherche à travers l'application. En le créant comme un widget séparé, on
/// assure une apparence et un comportement cohérents partout où une barre de
/// recherche est nécessaire.
///
/// Fonctionnement :
/// - Il est encapsulé dans un widget `Expanded`, ce qui signifie qu'il est conçu pour
/// s'étirer et occuper l'espace disponible dans une `Row` ou un `Flex`.
/// - Il utilise un `TextEditingController` passé en paramètre pour permettre au widget
/// parent de contrôler et d'écouter le contenu du champ de recherche.
/// - Il affiche une icône de recherche et un texte d'aide (`hintText`) personnalisable.
///
///*************************************************************************************************
library;

import 'package:flutter/material.dart';

/// Un widget réutilisable qui affiche un champ de recherche stylisé.
class SearchField extends StatelessWidget {
  /// Le contrôleur pour gérer le texte du champ de recherche.
  final TextEditingController controller;
  /// Le texte indicatif affiché lorsque le champ est vide.
  final String hintText;

  /// Constructeur pour le widget `SearchField`.
  const SearchField({
    super.key,
    required this.controller,
    this.hintText = "Rechercher...", // Valeur par défaut pour le texte d'aide.
  });

  @override
  Widget build(BuildContext context) {
    // Le widget Expanded permet au champ de recherche de prendre toute la place
    // disponible dans une Row, ce qui est un cas d'usage courant.
    return Expanded(
      child: TextField(
        // Associe le contrôleur externe au champ de texte.
        controller: controller,
        // Définit le style et l'apparence du champ de texte.
        decoration: InputDecoration(
          hintText: hintText, // Affiche le texte d'aide.
          // Ajoute une icône de loupe au début du champ.
          prefixIcon: const Icon(Icons.search),
          // Définit une bordure avec des coins arrondis.
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          // Réduit le remplissage vertical pour un champ plus compact.
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }
}







// import 'package:flutter/material.dart';
//
// class SearchField extends StatelessWidget {
//   final TextEditingController controller;
//   final String hintText;
//
//   const SearchField({
//     super.key,
//     required this.controller,
//     this.hintText = "Rechercher...",
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Expanded(
//       child: TextField(
//         controller: controller,
//         decoration: InputDecoration(
//           hintText: hintText,
//           prefixIcon: const Icon(Icons.search),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           contentPadding: const EdgeInsets.symmetric(vertical: 0),
//         ),
//       ),
//     );
//   }
// }
