/// **************************************************************************************
///
/// WIDGETS UI : INDICATEURS DE CHARGEMENT
///
/// OBJECTIF :
/// Ce fichier fournit une collection de widgets réutilisables et spécialisés pour
/// afficher des indicateurs de chargement (loading indicators) dans différents
/// contextes de l'application.
///
/// STRUCTURE DES WIDGETS :
/// - LoadingIndicator : Un indicateur de chargement générique avec un message,
/// idéal pour un chargement de page ou de contenu principal.
///
/// - PullToRefreshIndicator : Un indicateur conçu spécifiquement pour être utilisé
/// avec le widget `RefreshIndicator`. Il supporte l'affichage d'une progression
/// partielle, ce qui permet à l'indicateur de se "remplir" au fur et à mesure
/// que l'utilisateur tire l'écran vers le bas.
///
/// - LoadMoreIndicator : Un indicateur compact destiné à être placé en bas d'une
/// liste pour signaler le chargement d'éléments supplémentaires dans un contexte
/// de défilement infini ("infinite scroll").
///
///***************************************************************************************
library;
import 'package:flutter/material.dart';

/// Un widget d'indicateur de chargement générique, affichant une roue et un message.
class LoadingIndicator extends StatelessWidget {
  /// Le message à afficher sous l'indicateur.
  final String message;
  /// La taille (diamètre) de l'indicateur circulaire.
  final double size;
  /// La couleur de l'indicateur.
  final Color color;
  /// L'épaisseur du trait de l'indicateur.
  final double strokeWidth;

  const LoadingIndicator({
    super.key,
    this.message = 'Chargement...',
    this.size = 40.0,
    this.color = const Color(0xFFAB47BC), // Violet par défaut
    this.strokeWidth = 3.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            color: color,
            strokeWidth: strokeWidth,
          ),
        ),
        // Le message n'est affiché que s'il n'est pas vide.
        if (message.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ],
    );
  }
}

/// Un indicateur de chargement spécifiquement conçu pour l'action "tirer pour rafraîchir".
class PullToRefreshIndicator extends StatelessWidget {
  /// La valeur de progression (de 0.0 à 1.0), généralement fournie par `RefreshIndicator`.
  /// Permet à l'indicateur de se "remplir" lors du geste de l'utilisateur.
  final double value;
  /// La couleur de l'indicateur.
  final Color color;

  const PullToRefreshIndicator({
    super.key,
    required this.value,
    this.color = const Color(0xFFAB47BC), // Violet par défaut
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 40,
        height: 40,
        child: CircularProgressIndicator(
          value: value,
          color: color,
          strokeWidth: 3,
        ),
      ),
    );
  }
}

/// Un indicateur de chargement compact, idéal pour être affiché en bas d'une liste
/// lors du chargement d'éléments supplémentaires (infinite scroll).
class LoadMoreIndicator extends StatelessWidget {
  /// La couleur de l'indicateur.
  final Color color;
  /// Le message optionnel à afficher sous l'indicateur.
  final String? message;

  const LoadMoreIndicator({
    super.key,
    this.color = const Color(0xFFAB47BC), // Violet par défaut
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: color,
              strokeWidth: 2,
            ),
          ),
          // Le message n'est affiché que s'il est fourni.
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message!,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}






// import 'package:flutter/material.dart';
//
// class LoadingIndicator extends StatelessWidget {
//   final String message;
//   final double size;
//   final Color color;
//   final double strokeWidth;
//
//   const LoadingIndicator({
//     super.key,
//     this.message = 'Chargement...',
//     this.size = 40.0,
//     this.color = const Color(0xFFAB47BC), // Purple
//     this.strokeWidth = 3.0,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         SizedBox(
//           width: size,
//           height: size,
//           child: CircularProgressIndicator(
//             color: color,
//             strokeWidth: strokeWidth,
//           ),
//         ),
//         if (message.isNotEmpty) ...[
//           const SizedBox(height: 16),
//           Text(
//             message,
//             style: TextStyle(
//               color: Colors.grey.shade600,
//               fontSize: 16,
//             ),
//           ),
//         ],
//       ],
//     );
//   }
// }
//
// // Variante qui montre une animation plus fluide pour le "pull to refresh"
// class PullToRefreshIndicator extends StatelessWidget {
//   final double value;
//   final Color color;
//
//   const PullToRefreshIndicator({
//     super.key,
//     required this.value,
//     this.color = const Color(0xFFAB47BC),
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: SizedBox(
//         width: 40,
//         height: 40,
//         child: CircularProgressIndicator(
//           value: value,
//           color: color,
//           strokeWidth: 3,
//         ),
//       ),
//     );
//   }
// }
//
// // Variante pour indiquer le chargement de plus d'éléments en bas de la liste
// class LoadMoreIndicator extends StatelessWidget {
//   final Color color;
//   final String? message;
//
//   const LoadMoreIndicator({
//     super.key,
//     this.color = const Color(0xFFAB47BC),
//     this.message,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 16.0),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           SizedBox(
//             width: 24,
//             height: 24,
//             child: CircularProgressIndicator(
//               color: color,
//               strokeWidth: 2,
//             ),
//           ),
//           if (message != null) ...[
//             const SizedBox(height: 8),
//             Text(
//               message!,
//               style: TextStyle(
//                 color: Colors.grey.shade600,
//                 fontSize: 14,
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
// }