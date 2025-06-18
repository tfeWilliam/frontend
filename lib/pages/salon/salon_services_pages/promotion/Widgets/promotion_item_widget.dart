/// *************************************************************************************************
///
/// BANNER : EXPLICATION GÉNÉRALE DU WIDGET
///
/// Ce fichier définit `PromotionItem`, un widget Flutter stateless.
///
/// Objectif :
/// Ce widget est conçu pour afficher une seule promotion de manière claire et concise
/// dans une liste. Il présente les informations clés de la promotion, son statut
/// actuel (active, à venir, terminée) avec un code couleur, et fournit des boutons
/// d'action pour la modifier ou la supprimer.
///
/// Fonctionnalités :
/// - Affiche le pourcentage de réduction, les dates de validité et le prix final
/// si la promotion est active.
/// - Utilise `PromotionService` pour déterminer le statut de la promotion et adapte
/// son apparence (couleur de fond, bordure) en conséquence.
/// - Peut être "mis en surbrillance" (via le paramètre `isHighlighted`) pour attirer
/// l'attention, par exemple sur la promotion actuellement active.
/// - Inclut des boutons d'action (Modifier, Supprimer) qui déclenchent des fonctions
/// de rappel (`callback`) passées en paramètre.
///
/// Dépendances :
/// - `models/promotion_full.dart` : Pour les données de la promotion.
/// - `models/service_with_promo.dart` : Pour les données du service associé.
/// - `services/promotion_service.dart` : Pour la logique de statut de la promotion.
/// - `utils/date_formatter.dart` : Pour formater les dates.
///
///*************************************************************************************************
library;

import 'package:flutter/material.dart';
import '../../../../../models/promotion_full.dart';
import '../../../../../models/service_with_promo.dart';
import '../services/promotion_service.dart';
import '../utils/date_formatter.dart';

/// Un widget qui affiche les détails d'une promotion unique dans une liste.
class PromotionItem extends StatelessWidget {
  /// Les données complètes de la promotion à afficher.
  final PromotionFull promotionFull;
  /// Le service associé à cette promotion, utilisé pour calculer le prix final.
  final ServiceWithPromo serviceWithPromo;
  /// Callback exécuté lorsque l'utilisateur appuie sur le bouton de suppression.
  final VoidCallback onDelete;
  /// Callback exécuté lorsque l'utilisateur appuie sur le bouton de modification.
  final VoidCallback onEdit;
  /// Si `true`, applique une bordure plus épaisse pour mettre l'élément en évidence.
  final bool isHighlighted;

  /// Constructeur du widget `PromotionItem`.
  const PromotionItem({
    super.key,
    required this.promotionFull,
    required this.serviceWithPromo,
    required this.onDelete,
    required this.onEdit,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    // Détermine le statut de la promotion en utilisant le service dédié.
    final bool isActive = PromotionService.isPromotionActive(promotionFull);
    final bool isFuture = PromotionService.isPromotionFuture(promotionFull);

    // Définit la couleur de base en fonction du statut (par défaut, 'terminée').
    Color statusColor = Colors.grey;
    if (isActive) {
      statusColor = Colors.green; // Vert pour les promotions actives.
    } else if (isFuture) {
      statusColor = Colors.orange; // Orange pour les promotions à venir.
    }

    // Le conteneur principal de l'élément de promotion.
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // Utilise une version plus claire de la couleur de statut pour le fond.
        color: statusColor.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        // La bordure change d'épaisseur et d'opacité si l'élément est mis en surbrillance.
        border: Border.all(
          color: isHighlighted ? statusColor : statusColor.withAlpha(128),
          width: isHighlighted ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Section de gauche contenant les informations textuelles.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Première ligne avec le pourcentage de réduction et le badge de statut.
                Row(
                  children: [
                    Text(
                      '${promotionFull.pourcentage.toStringAsFixed(0)}% de réduction',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isActive ? statusColor : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Construit le petit badge de statut (Active, À venir, etc.).
                    _buildStatusBadge(promotionFull, statusColor),
                  ],
                ),
                const SizedBox(height: 4),
                // Affiche les dates de début et de fin formatées.
                Text(
                  'Du ${DateFormatter.formatDate(promotionFull.dateDebut)} au ${DateFormatter.formatDate(promotionFull.dateFin)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
                // Si la promotion est active, affiche le prix final calculé.
                if (isActive)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Prix actuel: ${(serviceWithPromo.prix * (1 - promotionFull.pourcentage / 100)).toStringAsFixed(2)} €',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Section de droite contenant les boutons d'action.
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                onPressed: onEdit, // Déclenche le callback de modification.
                constraints: const BoxConstraints(), // Réduit la zone de contact par défaut.
                padding: const EdgeInsets.all(8),
                tooltip: 'Modifier',
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: onDelete, // Déclenche le callback de suppression.
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
                tooltip: 'Supprimer',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Méthode privée pour construire le badge de statut.
  Widget _buildStatusBadge(PromotionFull promo, Color color) {
    String label;

    // Détermine le texte du badge en fonction du statut.
    if (PromotionService.isPromotionActive(promo)) {
      label = "Active";
    } else if (PromotionService.isPromotionFuture(promo)) {
      label = "À venir";
    } else {
      label = "Terminée";
    }

    // Retourne un conteneur stylisé pour le badge.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}








// // 📁 lib/ui/widgets/promotion_item_widget.dart
// import 'package:flutter/material.dart';
// import '../../../../../models/promotion_full.dart';
// import '../../../../../models/service_with_promo.dart';
// import '../services/promotion_service.dart';
// import '../utils/date_formatter.dart';
//
// class PromotionItem extends StatelessWidget {
//   final PromotionFull promotionFull;
//   final ServiceWithPromo serviceWithPromo;
//   final VoidCallback onDelete;
//   final VoidCallback onEdit;
//   final bool isHighlighted;
//
//   const PromotionItem({
//     super.key,
//     required this.promotionFull,
//     required this.serviceWithPromo,
//     required this.onDelete,
//     required this.onEdit,
//     this.isHighlighted = false,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final bool isActive = PromotionService.isPromotionActive(promotionFull);
//     final bool isFuture = PromotionService.isPromotionFuture(promotionFull);
//
//     Color statusColor = Colors.grey;
//
//     if (isActive) {
//       statusColor = Colors.green;
//     } else if (isFuture) {
//       statusColor = Colors.orange;
//     }
//
//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 6),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: statusColor.withAlpha(25),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(
//           color: isHighlighted
//               ? statusColor
//               : statusColor.withAlpha((0.5 * 255).toInt()),
//           width: isHighlighted ? 2 : 1,
//         ),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Text(
//                       '${promotionFull.pourcentage.toStringAsFixed(0)}% de réduction',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: isActive ? statusColor : Colors.black87,
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     _buildStatusBadge(promotionFull, statusColor),
//                   ],
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   'Du ${DateFormatter.formatDate(promotionFull.dateDebut)} au ${DateFormatter.formatDate(promotionFull.dateFin)}',
//                   style: TextStyle(fontSize: 12, color: Colors.grey[700]),
//                 ),
//                 if (isActive)
//                   Padding(
//                     padding: const EdgeInsets.only(top: 4),
//                     child: Text(
//                       'Prix actuel: ${(serviceWithPromo.prix * (1 - promotionFull.pourcentage / 100)).toStringAsFixed(2)} €',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: statusColor,
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//           Row(
//             children: [
//               IconButton(
//                 icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
//                 onPressed: onEdit,
//                 constraints: const BoxConstraints(),
//                 padding: const EdgeInsets.all(8),
//                 tooltip: 'Modifier',
//               ),
//               IconButton(
//                 icon: const Icon(Icons.delete, color: Colors.red, size: 20),
//                 onPressed: onDelete,
//                 constraints: const BoxConstraints(),
//                 padding: const EdgeInsets.all(8),
//                 tooltip: 'Supprimer',
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildStatusBadge(PromotionFull promo, Color color) {
//     String label = "Inconnue";
//
//     if (PromotionService.isPromotionActive(promo)) {
//       label = "Active";
//     } else if (PromotionService.isPromotionFuture(promo)) {
//       label = "À venir";
//     } else {
//       label = "Terminée";
//     }
//
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//       decoration: BoxDecoration(
//         color: color,
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Text(
//         label,
//         style: const TextStyle(color: Colors.white, fontSize: 12),
//       ),
//     );
//   }
// }