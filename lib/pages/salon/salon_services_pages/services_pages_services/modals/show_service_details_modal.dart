/// *************************************************************************************************
///
/// BANNER : EXPLICATION GÉNÉRALE DU FICHIER
///
/// Ce fichier définit une unique fonction globale, `showServiceDetailsModal`.
///
/// Objectif :
/// Afficher une feuille modale (bottom sheet) détaillée présentant toutes les informations
/// relatives à un service spécifique (`ServiceWithPromo`). Cette modale est conçue pour
/// s'adapter en fonction de l'utilisateur qui la consulte : un propriétaire (coiffeuse)
/// ou un client.
///
/// Fonctionnalités Clés :
/// - Affichage Complet des Données : Présente le nom, la description, la durée, et le prix
/// du service. Gère l'affichage du prix promotionnel si une promotion est active.
/// - Liste des Promotions : Affiche toutes les promotions associées au service (actives,
/// futures et expirées) avec un statut et un style visuel distincts pour chacune.
/// - Logique Conditionnelle par Rôle (`isOwner`) :
/// - Si l'utilisateur est le propriétaire (`isOwner == true`), il voit des boutons pour
/// "Modifier" le service et "Supprimer" les promotions.
/// - Si l'utilisateur est un client (`isOwner == false`), il voit un bouton pour
/// "Ajouter" le service au panier.
/// - Suppression de Promotion : Contient une logique interne pour appeler l'API de
/// suppression de promotion, avec gestion des erreurs et affichage d'un dialogue de
/// confirmation.
/// - Gestion du Rafraîchissement : La modale retourne une valeur (`true` ou `false`)
/// lorsqu'elle est fermée. Cela permet à l'écran parent de savoir s'il doit rafraîchir
/// ses données (par exemple, après une modification ou une suppression).
///
///*************************************************************************************************
library;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../../models/promotion_full.dart';
import '../../../../../models/service_with_promo.dart';

/// Affiche une feuille modale avec les détails d'un service et ses promotions.
///
/// [context] : Le BuildContext de la page appelante.
/// [serviceWithPromo] : Le modèle de données contenant les informations du service et de ses promotions.
/// [isOwner] : Un booléen qui détermine si l'utilisateur actuel est le propriétaire du service.
/// [onEdit] : Callback exécuté lorsque le propriétaire clique sur "Modifier".
/// [onAddToCart] : Callback exécuté lorsque le client clique sur "Ajouter".
Future<void> showServiceDetailsModal({
  required BuildContext context,
  required ServiceWithPromo serviceWithPromo,
  required bool isOwner,
  required VoidCallback onEdit,
  required VoidCallback onAddToCart,
}) async {
  /// Fonction interne pour gérer la suppression d'une promotion via un appel API.
  Future<void> deletePromotion(int promotionId) async {
    try {
      // Appel HTTP DELETE à l'API pour supprimer la promotion.
      final response = await http.delete(
        Uri.parse('https://www.hairbnb.site/api/delete_promotion/$promotionId/'),
      );

      // Si la suppression réussit (codes 200 ou 204), on ferme la modale.
      if (response.statusCode == 200 || response.statusCode == 204) {
        // On retourne `true` pour indiquer à l'écran parent qu'un changement a eu lieu.
        if (context.mounted) Navigator.pop(context, true);
      } else {
        // En cas d'erreur de l'API, on affiche un message d'erreur.
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur lors de la suppression de la promotion"), backgroundColor: Colors.red));
      }
    } catch (e) {
      // En cas d'erreur réseau, on affiche un message d'erreur.
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur de connexion: $e"), backgroundColor: Colors.red));
    }
  }

  // Affiche la feuille modale et attend un résultat.
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      // StatefulBuilder permet de gérer un état local (via setState) à l'intérieur de la modale stateless.
      return StatefulBuilder(
        builder: (context, setState) {
          // Récupère la liste de toutes les promotions associées à ce service.
          List<PromotionFull> allPromotions = serviceWithPromo.getAllPromotions();

          return AnimatedPadding(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            // S'assure que la modale s'ajuste lorsque le clavier apparaît.
            padding: MediaQuery.of(context).viewInsets + const EdgeInsets.all(10),
            child: DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.6, // Hauteur initiale de la modale.
              maxChildSize: 0.9,   // Hauteur maximale lorsque l'utilisateur la fait glisser.
              builder: (context, scrollController) => Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(20),
                child: ListView(
                  controller: scrollController,
                  shrinkWrap: true,
                  children: [
                    // Poignée visuelle pour la feuille déplaçable.
                    Center(child: Container(width: 40, height: 5, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)))),

                    // Titre du service.
                    Text(serviceWithPromo.intitule, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF7B61FF))),
                    const SizedBox(height: 10),

                    // Description du service.
                    Text(serviceWithPromo.description.isNotEmpty ? serviceWithPromo.description : "Pas de description", style: const TextStyle(fontSize: 16, color: Colors.black87)),
                    const SizedBox(height: 20),

                    // Informations sur la durée et le prix.
                    Row(children: [const Icon(Icons.timer_outlined, color: Color(0xFF7B61FF)), const SizedBox(width: 8), Text("${serviceWithPromo.temps} min", style: const TextStyle(fontSize: 16))]),
                    const SizedBox(height: 12),
                    Row(children: [
                      const Icon(Icons.euro_outlined, color: Color(0xFF7B61FF)),
                      const SizedBox(width: 8),
                      // Affiche le prix barré et le prix final si une promotion est active.
                      serviceWithPromo.promotion_active != null
                          ? Row(children: [Text("${serviceWithPromo.prix} €", style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.red)), const SizedBox(width: 6), Text("${serviceWithPromo.prix_final.toStringAsFixed(2)} € 🔥", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green))])
                          : Text("${serviceWithPromo.prix} €", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ]),

                    // Section pour afficher la liste des promotions.
                    if (allPromotions.isNotEmpty) ...[
                      const SizedBox(height: 30),
                      const Text("Promotions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF7B61FF))),
                      const SizedBox(height: 10),

                      // Itération sur chaque promotion pour créer une carte d'information.
                      ...allPromotions.map((promo) {
                        String statusText;
                        Color statusColor;

                        // Détermine le style et le texte du badge de statut.
                        switch (promo.getCurrentStatus()) {
                          case "active": statusText = "Active"; statusColor = Colors.green; break;
                          case "future": statusText = "À venir"; statusColor = Colors.orange; break;
                          case "expired": statusText = "Terminée"; statusColor = Colors.grey; break;
                          default: statusText = "Indéfini"; statusColor = Colors.grey;
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: statusColor, width: statusText == "Active" ? 2 : 1)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Text("${promo.pourcentage.toStringAsFixed(0)}% de réduction", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: statusText == "Active" ? statusColor : Colors.black87)),
                                        Container(margin: const EdgeInsets.only(left: 8), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(10)), child: Text(statusText, style: const TextStyle(color: Colors.white, fontSize: 12))),
                                      ]),
                                      const SizedBox(height: 5),
                                      Text("Du ${promo.dateDebut.toLocal().toString().split(' ')[0]} au ${promo.dateFin.toLocal().toString().split(' ')[0]}", style: const TextStyle(fontSize: 14, color: Colors.grey)),
                                      if (statusText == "Active") ...[const SizedBox(height: 5), Text("Prix promotionnel: ${(serviceWithPromo.prix * (1 - promo.pourcentage/100)).toStringAsFixed(2)} €", style: TextStyle(fontSize: 14, color: statusColor, fontWeight: FontWeight.bold))],
                                    ],
                                  ),
                                ),
                                // Affiche le bouton de suppression uniquement pour le propriétaire.
                                if (isOwner)
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      // Affiche un dialogue de confirmation avant la suppression.
                                      showDialog(
                                        context: context,
                                        builder: (dialogContext) => AlertDialog(
                                          title: const Text("Supprimer la promotion"),
                                          content: const Text("Êtes-vous sûr de vouloir supprimer cette promotion ? Cette action est irréversible."),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Annuler")),
                                            TextButton(onPressed: () { Navigator.pop(dialogContext); deletePromotion(promo.id); }, style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text("Supprimer")),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],

                    const SizedBox(height: 30),
                    // Boutons d'action principaux (Modifier ou Ajouter).
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Bouton "Modifier" pour le propriétaire.
                        if (isOwner)
                          ElevatedButton.icon(
                            onPressed: () {
                              debugPrint("🖊️ EditService() appelé pour : ${serviceWithPromo.intitule}, ID: ${serviceWithPromo.id}");
                              Navigator.pop(context, true); // Retourne `true` pour indiquer une modification.
                              onEdit(); // Exécute le callback onEdit.
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                            icon: const Icon(Icons.edit, color: Colors.white),
                            label: const Text("Modifier", style: TextStyle(color: Colors.white)),
                          ),
                        // Bouton "Ajouter" pour le client.
                        if (!isOwner)
                          ElevatedButton.icon(
                            onPressed: () {
                              debugPrint("🛒 addToCart() appelé pour : ${serviceWithPromo.intitule}, ID: ${serviceWithPromo.id}");
                              Navigator.pop(context, false); // Retourne `false` car aucune modification n'est faite à la liste.
                              onAddToCart(); // Exécute le callback onAddToCart.
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B61FF), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                            label: const Text("Ajouter", style: TextStyle(color: Colors.white)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );

  // Après la fermeture de la modale, si le résultat est `true`, on exécute `onEdit`.
  if (result == true) {
    onEdit();
  }
}






// // 📁 Fichier: show_service_details_modal.dart
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
//
// import '../../../../../models/promotion_full.dart';
// import '../../../../../models/service_with_promo.dart';
//
// Future<void> showServiceDetailsModal({
//   required BuildContext context,
//   required ServiceWithPromo serviceWithPromo,
//   required bool isOwner,
//   required VoidCallback onEdit,
//   required VoidCallback onAddToCart,
// }) async {
//   // Fonction pour supprimer une promotion
//   Future<void> deletePromotion(int promotionId) async {
//     try {
//       final response = await http.delete(
//         Uri.parse('https://www.hairbnb.site/api/delete_promotion/$promotionId/'),
//       );
//
//       if (response.statusCode == 200 || response.statusCode == 204) {
//         // Rafraîchir les données après suppression
//         Navigator.pop(context, true); // Indique qu'une mise à jour est nécessaire
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Erreur lors de la suppression de la promotion"), backgroundColor: Colors.red),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Erreur de connexion: $e"), backgroundColor: Colors.red),
//       );
//     }
//   }
//
//   // Afficher le modal
//   final result = await showModalBottomSheet<bool>(
//     context: context,
//     isScrollControlled: true,
//     backgroundColor: Colors.transparent,
//     builder: (context) {
//       return StatefulBuilder(
//         builder: (context, setState) {
//           // Récupérer toutes les promotions du service
//           List<PromotionFull> allPromotions = serviceWithPromo.getAllPromotions();
//
//           return AnimatedPadding(
//             duration: const Duration(milliseconds: 300),
//             curve: Curves.easeOut,
//             padding: MediaQuery.of(context).viewInsets + const EdgeInsets.all(10),
//             child: DraggableScrollableSheet(
//               expand: false,
//               initialChildSize: 0.6,
//               maxChildSize: 0.9,
//               builder: (context, scrollController) => Container(
//                 decoration: const BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//                 ),
//                 padding: const EdgeInsets.all(20),
//                 child: ListView(
//                   controller: scrollController,
//                   shrinkWrap: true,
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
//                       serviceWithPromo.intitule,
//                       style: const TextStyle(
//                         fontSize: 22,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xFF7B61FF),
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     Text(
//                       serviceWithPromo.description.isNotEmpty ? serviceWithPromo.description : "Pas de description",
//                       style: const TextStyle(fontSize: 16, color: Colors.black87),
//                     ),
//                     const SizedBox(height: 20),
//                     Row(
//                       children: [
//                         const Icon(Icons.timer_outlined, color: Color(0xFF7B61FF)),
//                         const SizedBox(width: 8),
//                         Text("${serviceWithPromo.temps} min", style: const TextStyle(fontSize: 16)),
//                       ],
//                     ),
//                     const SizedBox(height: 12),
//                     Row(
//                       children: [
//                         const Icon(Icons.euro_outlined, color: Color(0xFF7B61FF)),
//                         const SizedBox(width: 8),
//                         serviceWithPromo.promotion_active != null
//                             ? Row(
//                           children: [
//                             Text("${serviceWithPromo.prix} €",
//                                 style: const TextStyle(
//                                     decoration: TextDecoration.lineThrough, color: Colors.red)),
//                             const SizedBox(width: 6),
//                             Text("${serviceWithPromo.prix_final.toStringAsFixed(2)} € 🔥",
//                                 style: const TextStyle(
//                                     fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
//                           ],
//                         )
//                             : Text("${serviceWithPromo.prix} €",
//                             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                       ],
//                     ),
//
//                     // Section des promotions
//                     if (allPromotions.isNotEmpty) ...[
//                       const SizedBox(height: 30),
//                       const Text(
//                         "Promotions",
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: Color(0xFF7B61FF),
//                         ),
//                       ),
//                       const SizedBox(height: 10),
//
//                       // Liste des promotions
//                       ...allPromotions.map((promo) {
//                         // Déterminer le statut de la promotion
//                         String statusText;
//                         Color statusColor;
//
//                         switch (promo.getCurrentStatus()) {
//                           case "active":
//                             statusText = "Active";
//                             statusColor = Colors.green;
//                             break;
//                           case "future":
//                             statusText = "À venir";
//                             statusColor = Colors.orange;
//                             break;
//                           case "expired":
//                             statusText = "Terminée";
//                             statusColor = Colors.grey;
//                             break;
//                           default:
//                             statusText = "Indéfini";
//                             statusColor = Colors.grey;
//                         }
//
//                         return Card(
//                           margin: const EdgeInsets.only(bottom: 10),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(10),
//                             side: BorderSide(
//                               color: statusColor,
//                               width: statusText == "Active" ? 2 : 1,
//                             ),
//                           ),
//                           child: Padding(
//                             padding: const EdgeInsets.all(12),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       Row(
//                                         children: [
//                                           Text(
//                                             "${promo.pourcentage.toStringAsFixed(0)}% de réduction",
//                                             style: TextStyle(
//                                               fontSize: 16,
//                                               fontWeight: FontWeight.bold,
//                                               color: statusText == "Active" ? statusColor : Colors.black87,
//                                             ),
//                                           ),
//                                           Container(
//                                             margin: const EdgeInsets.only(left: 8),
//                                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                                             decoration: BoxDecoration(
//                                               color: statusColor,
//                                               borderRadius: BorderRadius.circular(10),
//                                             ),
//                                             child: Text(
//                                               statusText,
//                                               style: const TextStyle(color: Colors.white, fontSize: 12),
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                       const SizedBox(height: 5),
//                                       Text(
//                                         "Du ${promo.dateDebut.toLocal().toString().split(' ')[0]} au ${promo.dateFin.toLocal().toString().split(' ')[0]}",
//                                         style: const TextStyle(fontSize: 14, color: Colors.grey),
//                                       ),
//                                       if (statusText == "Active") ...[
//                                         const SizedBox(height: 5),
//                                         Text(
//                                           "Prix promotionnel: ${(serviceWithPromo.prix * (1 - promo.pourcentage/100)).toStringAsFixed(2)} €",
//                                           style: TextStyle(fontSize: 14, color: statusColor, fontWeight: FontWeight.bold),
//                                         ),
//                                       ],
//                                     ],
//                                   ),
//                                 ),
//                                 if (isOwner)
//                                   IconButton(
//                                     icon: const Icon(Icons.delete, color: Colors.red),
//                                     onPressed: () {
//                                       // Afficher une boîte de dialogue de confirmation
//                                       showDialog(
//                                         context: context,
//                                         builder: (dialogContext) => AlertDialog(
//                                           title: const Text("Supprimer la promotion"),
//                                           content: const Text(
//                                               "Êtes-vous sûr de vouloir supprimer cette promotion ? Cette action est irréversible."
//                                           ),
//                                           actions: [
//                                             TextButton(
//                                               onPressed: () => Navigator.pop(dialogContext),
//                                               child: const Text("Annuler"),
//                                             ),
//                                             TextButton(
//                                               onPressed: () {
//                                                 Navigator.pop(dialogContext);
//                                                 deletePromotion(promo.id);
//                                               },
//                                               style: TextButton.styleFrom(foregroundColor: Colors.red),
//                                               child: const Text("Supprimer"),
//                                             ),
//                                           ],
//                                         ),
//                                       );
//                                     },
//                                   ),
//                               ],
//                             ),
//                           ),
//                         );
//                       }),
//                     ],
//
//                     const SizedBox(height: 30),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.end,
//                       children: [
//                         if (isOwner)
//                           ElevatedButton.icon(
//                             onPressed: () {
//                               debugPrint("🛒 EditService() called for service show_service_details_modal.dart : "
//                                   "${serviceWithPromo.intitule}, ID: ${serviceWithPromo.id}");
//                               Navigator.pop(context, true);
//                               onEdit();
//                             },
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.blue,
//                               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                             ),
//                             icon: const Icon(Icons.edit, color: Colors.white),
//                             label: const Text("Modifier", style: TextStyle(color: Colors.white)),
//                           ),
//                         // if (!isOwner)
//                         //   ElevatedButton.icon(
//                         //     onPressed: () {
//                         //       debugPrint("🛒 addToCart() called for service from show_service_details_modal.dart : "
//                         //           "${serviceWithPromo.intitule}, ID: ${serviceWithPromo.id}");
//                         //       Navigator.pop(context, true);  // Voici le problème! Retourne true, ce qui déclenche onEdit()
//                         //       onAddToCart();
//                         //     },
//                         //     style: ElevatedButton.styleFrom(
//                         //       backgroundColor: const Color(0xFF7B61FF),
//                         //       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                         //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                         //     ),
//                         //     icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
//                         //     label: const Text("Ajouter", style: TextStyle(color: Colors.white)),
//                         //   ),
//
//                         if (!isOwner)
//                           ElevatedButton.icon(
//                             onPressed: () {
//                               debugPrint("🛒 addToCart() called for service from show_service_details_modal.dart : "
//                                   "${serviceWithPromo.intitule}, ID: ${serviceWithPromo.id}");
//                               Navigator.pop(context, false);  // Retourne false au lieu de true
//                               onAddToCart();
//                             },
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: const Color(0xFF7B61FF),
//                               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                             ),
//                             icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
//                             label: const Text("Ajouter", style: TextStyle(color: Colors.white)),
//                           ),
//                         //-----------------------------
//                         // if (!isOwner)
//                         //   ElevatedButton.icon(
//                         //     onPressed: () {
//                         //       debugPrint("🛒 addToCart() called for service from show_service_details_modal.dart : "
//                         //           "${serviceWithPromo.intitule}, ID: ${serviceWithPromo.id}");
//                         //       Navigator.pop(context, true);
//                         //       onAddToCart();
//                         //     },
//                         //     style: ElevatedButton.styleFrom(
//                         //       backgroundColor: const Color(0xFF7B61FF),
//                         //       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                         //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                         //     ),
//                         //     icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
//                         //     label: const Text("Ajouter", style: TextStyle(color: Colors.white)),
//                         //   ),
//                         //-------------------------------------------------------------------------
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         },
//       );
//     },
//   );
//
//   // Si le résultat est true, la liste a été modifiée et nous devons rafraîchir
//   if (result == true) {
//     onEdit(); // Utiliser la callback onEdit pour rafraîchir la liste des services
//   }
// }
