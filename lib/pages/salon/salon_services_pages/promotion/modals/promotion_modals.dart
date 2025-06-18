/// *************************************************************************************************
///
/// BANNER : EXPLICATION GÉNÉRALE DU WIDGET
///
/// Ce fichier définit `PromotionStatusBadge`, un widget Flutter stateless.
///
/// Objectif :
/// Ce widget est une petite capsule visuelle (un "badge") réutilisable, conçue pour
/// afficher l'état actuel d'une promotion. Il détermine si une promotion est
/// "Active", "À venir" ou "Terminée" en se basant sur ses dates et change de
/// couleur et de texte en conséquence.
///
/// Fonctionnement :
/// 1.  Il reçoit un objet `PromotionFull` contenant les détails de la promotion.
/// 2.  Il utilise une classe de service, `PromotionService`, pour évaluer l'état de
/// la promotion (active, future, ou passée).
/// 3.  Il affiche un `Container` stylisé avec une couleur et un texte correspondant
/// à l'état :
/// - Vert pour "Active".
/// - Orange pour "À venir".
/// - Gris pour "Terminée".
///
/// Dépendances :
/// - `models/promotion_full.dart` : Pour le modèle de données de la promotion.
/// - `services/promotion_service.dart` : Pour la logique métier de détermination du statut.
///
///*************************************************************************************************
library;

import 'package:flutter/material.dart';
import '../../../../../models/promotion_full.dart';
import '../services/promotion_service.dart';

/// Un widget qui affiche un badge de couleur indiquant le statut
/// d'une promotion (Active, À venir, Terminée).
class PromotionStatusBadge extends StatelessWidget {
  /// Les données complètes de la promotion à afficher.
  final PromotionFull promotionFull;

  /// Constructeur pour le widget `PromotionStatusBadge`.
  const PromotionStatusBadge({super.key, required this.promotionFull});

  @override
  Widget build(BuildContext context) {
    // Fait appel au service pour déterminer si la promotion est actuellement active.
    final bool isActive = PromotionService.isPromotionActive(promotionFull);
    // Fait appel au service pour déterminer si la promotion est programmée pour le futur.
    final bool isFuture = PromotionService.isPromotionFuture(promotionFull);

    // Initialise les valeurs par défaut pour une promotion terminée.
    Color statusColor = Colors.grey;
    String statusText = "Terminée";

    // Met à jour la couleur et le texte si la promotion est active.
    if (isActive) {
      statusColor = Colors.green;
      statusText = "Active";
    }
    // Sinon, met à jour si la promotion est à venir.
    else if (isFuture) {
      statusColor = Colors.orange;
      statusText = "À venir";
    }

    // Retourne un conteneur stylisé pour former le badge.
    return Container(
      // Marge intérieure pour le texte.
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      // Décoration pour la couleur de fond et les coins arrondis.
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(4),
      ),
      // Le texte du statut.
      child: Text(
        statusText,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}







// // lib/ui/widgets/promotion_status_badge.dart
// import 'package:flutter/material.dart';
// import '../../../../../models/promotion_full.dart';
// import '../services/promotion_service.dart';
//
// class PromotionStatusBadge extends StatelessWidget {
//   final PromotionFull promotionFull;
//
//   const PromotionStatusBadge({super.key, required this.promotionFull});
//
//   @override
//   Widget build(BuildContext context) {
//     final bool isActive = PromotionService.isPromotionActive(promotionFull);
//     final bool isFuture = PromotionService.isPromotionFuture(promotionFull);
//
//     Color statusColor = Colors.grey;
//     String statusText = "Terminée";
//
//     if (isActive) {
//       statusColor = Colors.green;
//       statusText = "Active";
//     } else if (isFuture) {
//       statusColor = Colors.orange;
//       statusText = "À venir";
//     }
//
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//       decoration: BoxDecoration(
//         color: statusColor,
//         borderRadius: BorderRadius.circular(4),
//       ),
//       child: Text(
//         statusText,
//         style: const TextStyle(color: Colors.white, fontSize: 12),
//       ),
//     );
//   }
// }
