/// *************************************************************************************************
///
/// BANNER : EXPLICATION GÉNÉRALE DU WIDGET
///
/// Ce fichier définit `ServicePriceWidget`, un widget Flutter stateless et réutilisable.
///
/// Objectif :
/// Ce widget est conçu pour afficher le prix et la durée d'un service de manière
/// claire et visuellement attrayante. Il gère intelligemment l'affichage lorsqu'une
/// promotion est active.
///
/// Fonctionnalités :
/// - Affiche le prix et la durée sous forme de "tags" (étiquettes) colorés.
/// - Si une promotion est active, il calcule le prix final, affiche le prix original
/// barré et met en évidence le nouveau prix avec une petite animation.
/// - Il est entièrement autonome et se reconstruit en fonction des données du
/// `ServiceSalonDetails` qui lui sont passées.
///
///*************************************************************************************************
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/public_salon_details.dart';

/// Un widget qui affiche le prix et la durée d'un service,
/// en gérant l'affichage des promotions actives.
class ServicePriceWidget extends StatelessWidget {
  /// Les détails du service à afficher, incluant le prix, la durée et les promotions.
  final ServiceSalonDetails serviceSalonDetails;

  /// Constructeur pour le widget `ServicePriceWidget`.
  const ServicePriceWidget({super.key, required this.serviceSalonDetails});

  @override
  Widget build(BuildContext context) {
    // Détermine si une promotion est actuellement active pour ce service.
    final hasPromo = serviceSalonDetails.promotionActive != null;
    // Récupère le prix de base du service.
    final prixOriginal = serviceSalonDetails.prix ?? 0.0;

    // Calcule le prix final. Si une promotion est active, applique le pourcentage de réduction.
    double prixFinal = prixOriginal;
    if (hasPromo) {
      final percentage = double.tryParse(serviceSalonDetails.promotionActive!.discountPercentage) ?? 0;
      prixFinal = prixOriginal * (1 - (percentage / 100));
    }

    // Organise les "tags" de prix et de durée dans une rangée.
    return Row(
      children: [
        // Si une promotion est active...
        if (hasPromo) ...[
          // Affiche le prix original barré.
          _tag('${prixOriginal.toStringAsFixed(2)} €', Colors.grey, isStrikethrough: true),
          const SizedBox(width: 8),
          // Affiche le nouveau prix avec une animation.
          _animatedTag('${prixFinal.toStringAsFixed(2)} €', Colors.red),
        ] else
        // Sinon, affiche simplement le prix normal.
          _tag('${prixOriginal.toStringAsFixed(2)} €', Colors.green),
        const SizedBox(width: 8),
        // Affiche toujours la durée.
        _tag('${serviceSalonDetails.duree ?? 0} min', Colors.blue),
      ],
    );
  }

  /// Méthode privée pour construire un "tag" (étiquette) stylisé.
  /// C'est un composant d'UI réutilisable pour ce widget.
  Widget _tag(String label, Color color, {bool isStrikethrough = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1), // Fond semi-transparent.
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          color: color,
          fontSize: 12,
          // Applique un style barré si nécessaire.
          decoration: isStrikethrough ? TextDecoration.lineThrough : null,
        ),
      ),
    );
  }

  /// Méthode privée qui enveloppe un "tag" dans une animation.
  /// Utilise `TweenAnimationBuilder` pour une animation simple sans `AnimationController`.
  Widget _animatedTag(String label, Color color) {
    return TweenAnimationBuilder<double>(
      // L'animation va de 0.0 à 1.0.
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      // Le `builder` est appelé à chaque "tick" de l'animation.
      builder: (context, value, child) {
        // `value` est la valeur actuelle de l'animation (entre 0.0 et 1.0).
        // On l'utilise pour animer l'opacité et la position.
        return Opacity(
          opacity: value, // Fait apparaître le tag en fondu.
          child: Transform.translate(
            // Fait glisser le tag depuis la gauche.
            offset: Offset(10 * (1 - value), 0),
            child: child, // `child` est le widget passé ci-dessous, qui n'est pas reconstruit.
          ),
        );
      },
      // Le widget `_tag` est passé ici comme `child` pour optimiser les performances.
      // Il n'est construit qu'une seule fois.
      child: _tag(label, color),
    );
  }
}







// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../../../models/public_salon_details.dart';
//
// class ServicePriceWidget extends StatelessWidget {
//   final ServiceSalonDetails serviceSalonDetails;
//
//   const ServicePriceWidget({super.key, required this.serviceSalonDetails});
//
//   @override
//   Widget build(BuildContext context) {
//     final hasPromo = serviceSalonDetails.promotionActive != null;
//     final prixOriginal = serviceSalonDetails.prix ?? 0.0;
//
//     double prixFinal = prixOriginal;
//     if (hasPromo) {
//       final percentage = double.tryParse(serviceSalonDetails.promotionActive!.discountPercentage) ?? 0;
//       prixFinal = prixOriginal * (1 - (percentage / 100));
//     }
//
//     return Row(
//       children: [
//         if (hasPromo) ...[
//           _tag('${prixOriginal.toStringAsFixed(2)} €', Colors.grey, isStrikethrough: true),
//           const SizedBox(width: 8),
//           _animatedTag('${prixFinal.toStringAsFixed(2)} €', Colors.red),
//         ] else
//           _tag('${prixOriginal.toStringAsFixed(2)} €', Colors.green),
//         const SizedBox(width: 8),
//         _tag('${serviceSalonDetails.duree ?? 0} min', Colors.blue),
//       ],
//     );
//   }
//
//   Widget _tag(String label, Color color, {bool isStrikethrough = false}) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Text(
//         label,
//         style: GoogleFonts.poppins(
//           fontWeight: FontWeight.w500,
//           color: color,
//           fontSize: 12,
//           decoration: isStrikethrough ? TextDecoration.lineThrough : null,
//         ),
//       ),
//     );
//   }
//
//   Widget _animatedTag(String label, Color color) {
//     return TweenAnimationBuilder<double>(
//       tween: Tween(begin: 0, end: 1),
//       duration: const Duration(milliseconds: 400),
//       builder: (context, value, child) {
//         return Opacity(
//           opacity: value,
//           child: Transform.translate(
//             offset: Offset(10 * (1 - value), 0),
//             child: child,
//           ),
//         );
//       },
//       child: _tag(label, color),
//     );
//   }
// }
