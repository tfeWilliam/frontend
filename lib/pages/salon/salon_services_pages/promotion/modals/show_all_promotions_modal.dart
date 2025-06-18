////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//          FONCTIONNALITÉ D'AFFICHAGE ET GESTION DES PROMOTIONS (MODAL)          //
//                                                                            //
//  Ce fichier définit une unique fonction `showAllPromotionsModal` qui       //
//  affiche une "modal bottom sheet" pour visualiser et gérer toutes les      //
//  promotions (actives, futures, expirées) associées à un service            //
//  spécifique.                                                               //
//                                                                            //
//  Approche :                                                                //
//  - La fonction récupère d'abord toutes les promotions avant d'afficher la  //
//    modal.                                                                  //
//  - Un `StatefulBuilder` est utilisé pour gérer l'état local de la modal    //
//    (le filtre sélectionné) sans nécessiter une classe `StatefulWidget`     //
//    distincte.                                                              //
//  - Des `ChoiceChip` permettent de filtrer la liste des promotions.         //
//  - Chaque promotion est affichée dans une carte stylisée avec des actions  //
//    pour la modifier ou la supprimer.                                       //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;

import 'package:flutter/material.dart';
import 'package:hairbnb/models/promotion_full.dart';
import 'package:hairbnb/models/service_with_promo.dart';
import '../services/promotion_service.dart';

/// Détermine le statut d'une promotion ('active', 'future', 'expired') en
/// comparant ses dates avec la date et l'heure actuelles.
String getPromotionStatus(PromotionFull promo) {
  final now = DateTime.now();
  if (now.isBefore(promo.dateDebut)) return "future";
  if (now.isAfter(promo.dateFin)) return "expired";
  return "active";
}

/// Affiche une feuille modale (bottom sheet) listant toutes les promotions
/// pour un service donné, avec des options de filtrage et de gestion.
///
/// [context] : Le `BuildContext` pour afficher la modal.
/// [serviceWithPromo] : Le service pour lequel les promotions sont affichées.
/// [onRefresh] : Un callback exécuté après une suppression réussie pour rafraîchir l'écran parent.
Future<void> showAllPromotionsModal({
  required BuildContext context,
  required ServiceWithPromo serviceWithPromo,
  required VoidCallback onRefresh,
}) async {
  // Récupère d'abord toutes les promotions pour le service.
  final result = await PromotionService.getAllPromotionsForService(serviceWithPromo);
  final List<PromotionFull> allPromotions = result['promotions'] ?? [];

  // Affiche la feuille modale.
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Permet à la modal de prendre plus de place.
    backgroundColor: Colors.transparent,
    builder: (context) {
      // `StatefulBuilder` permet à la modal d'avoir son propre état local,
      // ici pour gérer le filtre sélectionné (`currentFilter`).
      return StatefulBuilder(
        builder: (context, setState) {
          String currentFilter = "Toutes";

          // Fonction locale pour filtrer la liste complète des promotions.
          List<PromotionFull> getFilteredPromotions() {
            return allPromotions.where((promo) {
              final status = getPromotionStatus(promo);
              return currentFilter == "Toutes" ||
                  (currentFilter == "Actives" && status == "active") ||
                  (currentFilter == "À venir" && status == "future") ||
                  (currentFilter == "Expirées" && status == "expired");
            }).toList();
          }

          final filteredPromotions = getFilteredPromotions();

          // Calcule le nombre de promotions pour chaque statut pour l'affichage dans les filtres.
          int activeCount = allPromotions.where((p) => getPromotionStatus(p) == "active").length;
          int futureCount = allPromotions.where((p) => getPromotionStatus(p) == "future").length;
          int expiredCount = allPromotions.where((p) => getPromotionStatus(p) == "expired").length;

          // La feuille modale est redimensionnable par l'utilisateur.
          return DraggableScrollableSheet(
            initialChildSize: 0.7, maxChildSize: 0.9, minChildSize: 0.5,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Poignée de redimensionnement en haut de la modal.
                    Center(
                      child: Container(
                        width: 40, height: 5, margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    // Titre de la modal.
                    Text(
                      'Promotions - ${serviceWithPromo.intitule}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF7B61FF)),
                    ),
                    const SizedBox(height: 16),

                    // Barre de filtres.
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip("Toutes (${allPromotions.length})", currentFilter == "Toutes", () => setState(() => currentFilter = "Toutes")),
                          _buildFilterChip("Actives ($activeCount)", currentFilter == "Actives", () => setState(() => currentFilter = "Actives")),
                          _buildFilterChip("À venir ($futureCount)", currentFilter == "À venir", () => setState(() => currentFilter = "À venir")),
                          _buildFilterChip("Expirées ($expiredCount)", currentFilter == "Expirées", () => setState(() => currentFilter = "Expirées")),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Liste des promotions filtrées.
                    Expanded(
                      child: filteredPromotions.isEmpty
                      // Affiche un message si aucun résultat ne correspond au filtre.
                          ? Center(child: Text('Aucune promotion ${currentFilter.toLowerCase()}', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[600])))
                      // Affiche la liste des cartes de promotion.
                          : ListView.builder(
                        controller: scrollController,
                        itemCount: filteredPromotions.length,
                        itemBuilder: (context, index) {
                          final promo = filteredPromotions[index];
                          final status = getPromotionStatus(promo);

                          // Détermine la couleur et le texte du statut.
                          Color statusColor = Colors.grey;
                          String statusText = "Expirée";
                          if (status == "active") { statusColor = Colors.green; statusText = "Active"; }
                          else if (status == "future") { statusColor = Colors.orange; statusText = "À venir"; }

                          // Construit la carte pour une promotion.
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: statusColor, width: status == "active" ? 2 : 1)),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text("${promo.pourcentage.toStringAsFixed(0)}% de réduction", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: statusColor)),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(10)),
                                              child: Text(statusText, style: const TextStyle(color: Colors.white, fontSize: 12)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Text("Du ${promo.dateDebut.day}/${promo.dateDebut.month}/${promo.dateDebut.year} au ${promo.dateFin.day}/${promo.dateFin.month}/${promo.dateFin.year}", style: const TextStyle(fontSize: 14, color: Colors.grey)),
                                        if (status == "active") ...[
                                          const SizedBox(height: 5),
                                          Text("Prix promotionnel: ${(serviceWithPromo.prix * (1 - promo.pourcentage / 100)).toStringAsFixed(2)} €", style: TextStyle(fontSize: 14, color: statusColor, fontWeight: FontWeight.bold)),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      // Bouton d'édition (logique à implémenter).
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                        onPressed: () {
                                          // TODO: Implémenter showEditPromotionModal(promo)
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Édition à venir"), backgroundColor: Colors.orange));
                                        },
                                      ),
                                      // Bouton de suppression.
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              title: const Text("Supprimer la promotion"),
                                              content: const Text("Confirmer la suppression ?"),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
                                                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Supprimer")),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            final res = await PromotionService.deletePromotion(promo.id);
                                            if (!context.mounted) return;
                                            if (res['success']) {
                                              Navigator.pop(context); // Ferme la modal.
                                              onRefresh(); // Recharge les données de la page parente.
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['error'] ?? "Erreur"), backgroundColor: Colors.red));
                                            }
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}

/// Widget privé pour construire une puce de filtre (`ChoiceChip`).
Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
  return Padding(
    padding: const EdgeInsets.only(right: 8.0),
    child: ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.grey.shade200,
      selectedColor: const Color(0xFF7B61FF).withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF7B61FF) : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    ),
  );
}






// import 'package:flutter/material.dart';
// import 'package:hairbnb/models/promotion_full.dart';
// import 'package:hairbnb/models/service_with_promo.dart';
// import '../services/promotion_service.dart';
//
// String getPromotionStatus(PromotionFull promo) {
//   final now = DateTime.now();
//   if (now.isBefore(promo.dateDebut)) return "future";
//   if (now.isAfter(promo.dateFin)) return "expired";
//   return "active";
// }
//
// Future<void> showAllPromotionsModal({
//   required BuildContext context,
//   required ServiceWithPromo serviceWithPromo,
//   required VoidCallback onRefresh,
// }) async {
//   final result = await PromotionService.getAllPromotionsForService(serviceWithPromo);
//   final List<PromotionFull> allPromotions = result['promotions'] ?? [];
//
//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     backgroundColor: Colors.transparent,
//     builder: (context) {
//       return StatefulBuilder(
//         builder: (context, setState) {
//           String currentFilter = "Toutes";
//
//           List<PromotionFull> getFilteredPromotions() {
//             return allPromotions.where((promo) {
//               final status = getPromotionStatus(promo);
//               return currentFilter == "Toutes" ||
//                   (currentFilter == "Actives" && status == "active") ||
//                   (currentFilter == "À venir" && status == "future") ||
//                   (currentFilter == "Expirées" && status == "expired");
//             }).toList();
//           }
//
//           final filteredPromotions = getFilteredPromotions();
//
//           int activeCount = allPromotions.where((p) => getPromotionStatus(p) == "active").length;
//           int futureCount = allPromotions.where((p) => getPromotionStatus(p) == "future").length;
//           int expiredCount = allPromotions.where((p) => getPromotionStatus(p) == "expired").length;
//
//           return DraggableScrollableSheet(
//             initialChildSize: 0.7,
//             maxChildSize: 0.9,
//             minChildSize: 0.5,
//             builder: (context, scrollController) {
//               return Container(
//                 decoration: const BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//                 ),
//                 padding: const EdgeInsets.all(20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Center(
//                       child: Container(
//                         width: 40,
//                         height: 5,
//                         margin: const EdgeInsets.only(bottom: 20),
//                         decoration: BoxDecoration(
//                           color: Colors.grey[300],
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                     ),
//                     Text(
//                       'Promotions - ${serviceWithPromo.intitule}',
//                       style: const TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xFF7B61FF),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//
//                     // Filtres
//                     SingleChildScrollView(
//                       scrollDirection: Axis.horizontal,
//                       child: Row(
//                         children: [
//                           _buildFilterChip("Toutes (${allPromotions.length})", currentFilter == "Toutes",
//                                   () => setState(() => currentFilter = "Toutes")),
//                           _buildFilterChip("Actives ($activeCount)", currentFilter == "Actives",
//                                   () => setState(() => currentFilter = "Actives")),
//                           _buildFilterChip("À venir ($futureCount)", currentFilter == "À venir",
//                                   () => setState(() => currentFilter = "À venir")),
//                           _buildFilterChip("Expirées ($expiredCount)", currentFilter == "Expirées",
//                                   () => setState(() => currentFilter = "Expirées")),
//                         ],
//                       ),
//                     ),
//
//                     const SizedBox(height: 16),
//
//                     // Liste des promotions filtrées
//                     Expanded(
//                       child: filteredPromotions.isEmpty
//                           ? Center(
//                         child: Text(
//                           'Aucune promotion ${currentFilter.toLowerCase()}',
//                           style: TextStyle(
//                             fontStyle: FontStyle.italic,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                       )
//                           : ListView.builder(
//                         controller: scrollController,
//                         itemCount: filteredPromotions.length,
//                         itemBuilder: (context, index) {
//                           final promo = filteredPromotions[index];
//                           final status = getPromotionStatus(promo);
//
//                           Color statusColor = Colors.grey;
//                           String statusText = "Expirée";
//
//                           if (status == "active") {
//                             statusColor = Colors.green;
//                             statusText = "Active";
//                           } else if (status == "future") {
//                             statusColor = Colors.orange;
//                             statusText = "À venir";
//                           }
//
//                           return Card(
//                             margin: const EdgeInsets.only(bottom: 10),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(10),
//                               side: BorderSide(
//                                 color: statusColor,
//                                 width: status == "active" ? 2 : 1,
//                               ),
//                             ),
//                             child: Padding(
//                               padding: const EdgeInsets.all(12),
//                               child: Row(
//                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   Expanded(
//                                     child: Column(
//                                       crossAxisAlignment: CrossAxisAlignment.start,
//                                       children: [
//                                         Row(
//                                           children: [
//                                             Text(
//                                               "${promo.pourcentage.toStringAsFixed(0)}% de réduction",
//                                               style: TextStyle(
//                                                 fontSize: 16,
//                                                 fontWeight: FontWeight.bold,
//                                                 color: statusColor,
//                                               ),
//                                             ),
//                                             const SizedBox(width: 8),
//                                             Container(
//                                               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                                               decoration: BoxDecoration(
//                                                 color: statusColor,
//                                                 borderRadius: BorderRadius.circular(10),
//                                               ),
//                                               child: Text(
//                                                 statusText,
//                                                 style: const TextStyle(color: Colors.white, fontSize: 12),
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                         const SizedBox(height: 5),
//                                         Text(
//                                           "Du ${promo.dateDebut.day}/${promo.dateDebut.month}/${promo.dateDebut.year} "
//                                               "au ${promo.dateFin.day}/${promo.dateFin.month}/${promo.dateFin.year}",
//                                           style: const TextStyle(fontSize: 14, color: Colors.grey),
//                                         ),
//                                         if (status == "active") ...[
//                                           const SizedBox(height: 5),
//                                           Text(
//                                             "Prix promotionnel: ${(serviceWithPromo.prix * (1 - promo.pourcentage / 100)).toStringAsFixed(2)} €",
//                                             style: TextStyle(
//                                               fontSize: 14,
//                                               color: statusColor,
//                                               fontWeight: FontWeight.bold,
//                                             ),
//                                           ),
//                                         ],
//                                       ],
//                                     ),
//                                   ),
//                                   Row(
//                                     children: [
//                                       IconButton(
//                                         icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
//                                         onPressed: () {
//                                           // TODO: Implémenter showEditPromotionModal(promo)
//                                           ScaffoldMessenger.of(context).showSnackBar(
//                                             const SnackBar(
//                                               content: Text("Édition à venir"),
//                                               backgroundColor: Colors.orange,
//                                             ),
//                                           );
//                                         },
//                                       ),
//                                       IconButton(
//                                         icon: const Icon(Icons.delete, color: Colors.red, size: 20),
//                                         onPressed: () async {
//                                           final confirm = await showDialog<bool>(
//                                             context: context,
//                                             builder: (_) => AlertDialog(
//                                               title: const Text("Supprimer la promotion"),
//                                               content: const Text("Confirmer la suppression ?"),
//                                               actions: [
//                                                 TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
//                                                 TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Supprimer")),
//                                               ],
//                                             ),
//                                           );
//
//                                           if (confirm == true) {
//                                             final res = await PromotionService.deletePromotion(promo.id);
//
//                                             if (!context.mounted) return; // ✅ Vérifie que le widget est toujours dans l’arbre
//
//                                             if (res['success']) {
//                                               Navigator.pop(context); // Fermer le modal
//                                               onRefresh(); // Recharger les données
//                                             } else {
//                                               ScaffoldMessenger.of(context).showSnackBar(
//                                                 SnackBar(
//                                                   content: Text(res['error'] ?? "Erreur"),
//                                                   backgroundColor: Colors.red,
//                                                 ),
//                                               );
//                                             }
//                                           }
//
//
//                                           // if (confirm == true) {
//                                           //   final res = await PromotionService.deletePromotion(promo.id);
//                                           //   if (res['success']) {
//                                           //     Navigator.pop(context); // Fermer le modal
//                                           //     onRefresh(); // Recharger les données
//                                           //   } else {
//                                           //     ScaffoldMessenger.of(context).showSnackBar(
//                                           //       SnackBar(
//                                           //         content: Text(res['error'] ?? "Erreur"),
//                                           //         backgroundColor: Colors.red,
//                                           //       ),
//                                           //     );
//                                           //   }
//                                           // }
//                                         },
//                                       ),
//                                     ],
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             },
//           );
//         },
//       );
//     },
//   );
// }
//
// Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
//   return Padding(
//     padding: const EdgeInsets.only(right: 8.0),
//     child: ChoiceChip(
//       label: Text(label),
//       selected: isSelected,
//       onSelected: (_) => onTap(),
//       backgroundColor: Colors.grey.shade200,
//       selectedColor: const Color(0xFF7B61FF).withOpacity(0.2),
//       labelStyle: TextStyle(
//         color: isSelected ? const Color(0xFF7B61FF) : Colors.black,
//         fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//       ),
//     ),
//   );
// }
//
