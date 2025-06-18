////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//          WIDGETS POUR L'AFFICHAGE ET LA GESTION DES PROMOTIONS               //
//                                                                            //
//  Ce fichier définit un ensemble de composants d'interface utilisateur      //
//  réutilisables, conçus pour afficher et gérer les promotions associées à    //
//  un service.                                                               //
//                                                                            //
//  - `PromotionItem` : Un widget compact qui affiche les détails d'une       //
//    seule promotion avec un style visuel adapté à son statut (active,       //
//    future, expirée).                                                       //
//                                                                            //
//  - `ServicePromotionCard` : Une carte complète qui affiche les             //
//    informations d'un service et qui intègre l'affichage de ses promotions  //
//    actives et futures, ainsi que les actions pour en ajouter, modifier ou  //
//    supprimer.                                                              //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;

import 'package:flutter/material.dart';
import '../../../../../models/promotion_full.dart';
import '../../../../../models/service_with_promo.dart';
import '../../services_pages_services/modals/create_promotion_modal.dart';
import '../modals/edit_promotion_modal.dart';
import '../modals/show_all_promotions_modal.dart';
import '../utils/date_formatter.dart';
import 'promotion_dialogs_widget.dart';

/// Un widget qui affiche les informations d'une seule promotion de manière stylisée.
class PromotionItem extends StatelessWidget {
  /// L'objet `PromotionFull` contenant les données de la promotion.
  final PromotionFull promotion;
  /// Le service associé, utilisé pour calculer le prix promotionnel.
  final ServiceWithPromo service;
  /// Callback exécuté lorsque l'utilisateur clique sur l'icône de suppression.
  final VoidCallback onDelete;
  /// Callback exécuté lorsque l'utilisateur clique sur l'icône de modification.
  final VoidCallback onEdit;
  /// Un booléen pour un affichage potentiellement plus compact (non utilisé actuellement).
  final bool isCompact;

  /// Constructeur du widget `PromotionItem`.
  const PromotionItem({
    super.key,
    required this.promotion,
    required this.service,
    required this.onDelete,
    required this.onEdit,
    this.isCompact = true,
  });

  @override
  Widget build(BuildContext context) {
    // Détermine le statut et la couleur associée pour le style conditionnel.
    final status = promotion.getCurrentStatus();
    final statusColor = status == 'active'
        ? const Color(0xFF4CAF50)
        : (status == 'future' ? const Color(0xFFFF9800) : Colors.grey);
    final discount = promotion.pourcentage;
    final discountedPrice = service.getPrixAvecReduction();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: statusColor.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 2))],
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icône de promotion.
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.local_offer, size: 20, color: statusColor),
          ),
          const SizedBox(width: 12),
          // Contenu principal de la promotion.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Badge de pourcentage de réduction.
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Text('-${discount.toStringAsFixed(0)}%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: statusColor)),
                    ),
                    const SizedBox(width: 8),
                    // Période de validité.
                    Expanded(
                      child: Text(
                        '${DateFormatter.formatDate(promotion.dateDebut)} → ${DateFormatter.formatDate(promotion.dateFin)}',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Affiche des informations contextuelles basées sur le statut.
                if (status == 'active')
                  Row(
                    children: [
                      const Icon(Icons.check_circle, size: 14, color: Color(0xFF4CAF50)),
                      const SizedBox(width: 4),
                      Text('Actuel: ${discountedPrice.toStringAsFixed(2)} €', style: const TextStyle(fontSize: 13, color: Color(0xFF4CAF50), fontWeight: FontWeight.bold)),
                      if (service.hasActivePromotion()) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFF4CAF50).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text('Économie: ${service.getMontantEconomise().toStringAsFixed(2)} €', style: const TextStyle(fontSize: 11, color: Color(0xFF4CAF50), fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                if (status == 'future')
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 14, color: Color(0xFFFF9800)),
                      const SizedBox(width: 4),
                      Text('À venir: ${(service.prix * (1 - discount / 100)).toStringAsFixed(2)} €', style: const TextStyle(fontSize: 13, color: Color(0xFFFF9800), fontWeight: FontWeight.bold)),
                    ],
                  ),
                if (status == 'expired')
                  Row(
                    children: [
                      Icon(Icons.event_busy, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('Expiré', style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                    ],
                  ),
              ],
            ),
          ),
          // Boutons d'action (Modifier, Supprimer).
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: const Icon(Icons.edit_outlined, size: 20), color: const Color(0xFF7B61FF), tooltip: 'Modifier', onPressed: onEdit, splashRadius: 24, constraints: const BoxConstraints(minWidth: 36, minHeight: 36)),
              IconButton(icon: const Icon(Icons.delete_outline, size: 20), color: Colors.redAccent, tooltip: 'Supprimer', onPressed: onDelete, splashRadius: 24, constraints: const BoxConstraints(minWidth: 36, minHeight: 36)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Une carte complète qui affiche les détails d'un service et gère l'affichage
/// de toutes ses promotions associées (actives et futures).
class ServicePromotionCard extends StatelessWidget {
  /// Le service avec ses promotions, à afficher.
  final ServiceWithPromo service;
  /// Callback pour rafraîchir la page parente après une action (ajout/suppression).
  final VoidCallback onRefresh;

  /// Constructeur de la carte de promotion de service.
  const ServicePromotionCard({
    super.key,
    required this.service,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    // Logique pour déterminer l'état des promotions pour un affichage conditionnel.
    final hasActivePromo = service.hasActivePromotion();
    final futurePromos = service.promotions_a_venir;
    final bool hasPromos = hasActivePromo || service.hasFuturePromotions();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête affichant les détails du service et le bouton "Ajouter Promo".
            Row(
              children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(color: const Color(0xFF7B61FF).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.spa, color: Color(0xFF7B61FF), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(service.intitule, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Affiche durée et prix (original barré si promo active).
                          const Icon(Icons.access_time, size: 14, color: Color(0xFF7B61FF)), const SizedBox(width: 4), Text('${service.temps} min', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                          Container(margin: const EdgeInsets.symmetric(horizontal: 6), width: 4, height: 4, decoration: BoxDecoration(color: Colors.grey[400], shape: BoxShape.circle)),
                          const Icon(Icons.euro, size: 14, color: Color(0xFF7B61FF)), const SizedBox(width: 4),
                          if (hasActivePromo) ...[
                            Text('${service.prix} €', style: TextStyle(color: Colors.grey[500], fontSize: 13, decoration: TextDecoration.lineThrough)),
                            const SizedBox(width: 4),
                            Text('${service.getPrixAvecReduction().toStringAsFixed(2)} €', style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 13, fontWeight: FontWeight.bold)),
                          ] else Text('${service.prix} €', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                        ],
                      ),
                      // Affiche le nom du salon si disponible.
                      if (service.salonNom != null) ...[ const SizedBox(height: 2), Row(children: [Icon(Icons.store, size: 12, color: Colors.grey[600]), const SizedBox(width: 4), Text(service.salonNom!, style: TextStyle(color: Colors.grey[600], fontSize: 11, fontStyle: FontStyle.italic))])],
                    ],
                  ),
                ),
                // Bouton pour ajouter une nouvelle promotion.
                ElevatedButton(
                  onPressed: () => showCreatePromotionModal(context: context, salonId: service.salonId, serviceId: service.id, onPromoAdded: onRefresh),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B61FF), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add, size: 18), SizedBox(width: 4), Text('Promo')]),
                ),
              ],
            ),

            // Badge affichant le nombre total de promotions si > 0.
            if (service.getTotalPromotionsCount() > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF7B61FF).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Text('${service.getTotalPromotionsCount()} promotion${service.getTotalPromotionsCount() > 1 ? 's' : ''}', style: const TextStyle(fontSize: 12, color: Color(0xFF7B61FF), fontWeight: FontWeight.w600)),
              ),
            ],

            if (hasPromos) const Divider(height: 30),

            // Affiche la promotion active si elle existe.
            if (hasActivePromo)
              PromotionItem(
                promotion: service.promotion_active!, service: service, isCompact: true,
                onDelete: () => showDeletePromotionDialog(context: context, promotionFull: service.promotion_active!, onSuccess: onRefresh),
                onEdit: () => showEditPromotionModal(context: context, salonId: service.salonId, serviceId: service.id, promotion: service.promotion_active!, onPromoUpdated: onRefresh),
              ),

            // Affiche les 2 prochaines promotions à venir.
            ...futurePromos.take(2).map((promo) => PromotionItem(
              promotion: promo, service: service, isCompact: true,
              onDelete: () => showDeletePromotionDialog(context: context, promotionFull: promo, onSuccess: onRefresh),
              onEdit: () => showEditPromotionModal(context: context, salonId: service.salonId, serviceId: service.id, promotion: promo, onPromoUpdated: onRefresh),
            )),

            // Affiche un bandeau d'information s'il n'y a pas de promo active mais qu'une est à venir.
            if (!hasActivePromo && service.getNextPromotion() != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFFF9800).withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.3))),
                child: Row(children: [const Icon(Icons.upcoming, color: Color(0xFFFF9800), size: 20), const SizedBox(width: 8), Expanded(child: Text('Prochaine promo: ${service.getNextPromotion()!.pourcentage.toStringAsFixed(0)}% dès le ${DateFormatter.formatDate(service.getNextPromotion()!.dateDebut)}', style: const TextStyle(fontSize: 13, color: Color(0xFFFF9800), fontWeight: FontWeight.w600)))]),
              ),
            ],

            // Affiche un bouton "Voir toutes les promotions" si nécessaire.
            if (futurePromos.length > 2 || hasActivePromo)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Align(
                  alignment: Alignment.center,
                  child: TextButton.icon(
                    onPressed: () => showAllPromotionsModal(context: context, serviceWithPromo: service, onRefresh: onRefresh),
                    icon: const Icon(Icons.calendar_month, size: 18),
                    label: Text('Voir toutes les promotions (${service.getTotalPromotionsCount()})'),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), foregroundColor: const Color(0xFF7B61FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), backgroundColor: const Color(0xFF7B61FF).withOpacity(0.1)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}






// // 📁 lib/ui/widgets/promotion_widgets.dart
// import 'package:flutter/material.dart';
// import '../../../../../models/promotion_full.dart';
// import '../../../../../models/service_with_promo.dart';
// import '../../services_pages_services/modals/create_promotion_modal.dart';
// import '../modals/edit_promotion_modal.dart';
// import '../modals/show_all_promotions_modal.dart';
// import '../utils/date_formatter.dart';
// import 'promotion_dialogs_widget.dart';
//
// class PromotionItem extends StatelessWidget {
//   final PromotionFull promotion;
//   final ServiceWithPromo service;
//   final VoidCallback onDelete;
//   final VoidCallback onEdit;
//   final bool isCompact;
//
//   const PromotionItem({
//     super.key,
//     required this.promotion,
//     required this.service,
//     required this.onDelete,
//     required this.onEdit,
//     this.isCompact = true,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final status = promotion.getCurrentStatus();
//     final statusColor = status == 'active'
//         ? const Color(0xFF4CAF50)
//         : (status == 'future' ? const Color(0xFFFF9800) : Colors.grey);
//     final discount = promotion.pourcentage;
//
//     final discountedPrice = service.getPrixAvecReduction();
//
//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 6),
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: statusColor.withOpacity(0.15),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//         border: Border.all(color: statusColor.withOpacity(0.2)),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: statusColor.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Icon(
//               Icons.local_offer,
//               size: 20,
//               color: statusColor,
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                       decoration: BoxDecoration(
//                         color: statusColor.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Text(
//                         '-${discount.toStringAsFixed(0)}%',
//                         style: TextStyle(
//                           fontSize: 13,
//                           fontWeight: FontWeight.bold,
//                           color: statusColor,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: Text(
//                         '${DateFormatter.formatDate(promotion.dateDebut)} → ${DateFormatter.formatDate(promotion.dateFin)}',
//                         style: TextStyle(
//                           fontSize: 13,
//                           fontWeight: FontWeight.w500,
//                           color: Colors.grey[700],
//                         ),
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 4),
//                 if (status == 'active')
//                   Row(
//                     children: [
//                       const Icon(Icons.check_circle, size: 14, color: Color(0xFF4CAF50)),
//                       const SizedBox(width: 4),
//                       Text(
//                         'Actuel: ${discountedPrice.toStringAsFixed(2)} €',
//                         style: const TextStyle(
//                           fontSize: 13,
//                           color: Color(0xFF4CAF50),
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       // 🔥 NOUVEAU : Affichage du montant économisé
//                       if (service.hasActivePromotion()) ...[
//                         const SizedBox(width: 8),
//                         Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                           decoration: BoxDecoration(
//                             color: const Color(0xFF4CAF50).withOpacity(0.1),
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: Text(
//                             'Économie: ${service.getMontantEconomise().toStringAsFixed(2)} €',
//                             style: const TextStyle(
//                               fontSize: 11,
//                               color: Color(0xFF4CAF50),
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ],
//                   ),
//                 if (status == 'future')
//                   Row(
//                     children: [
//                       const Icon(Icons.schedule, size: 14, color: Color(0xFFFF9800)),
//                       const SizedBox(width: 4),
//                       Text(
//                         'À venir: ${(service.prix * (1 - discount / 100)).toStringAsFixed(2)} €',
//                         style: const TextStyle(
//                           fontSize: 13,
//                           color: Color(0xFFFF9800),
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ],
//                   ),
//                 if (status == 'expired')
//                   Row(
//                     children: [
//                       Icon(Icons.event_busy, size: 14, color: Colors.grey[600]),
//                       const SizedBox(width: 4),
//                       Text(
//                         'Expiré',
//                         style: TextStyle(
//                           fontSize: 13,
//                           color: Colors.grey[600],
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ],
//                   ),
//               ],
//             ),
//           ),
//           Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               IconButton(
//                 icon: const Icon(Icons.edit_outlined, size: 20),
//                 color: const Color(0xFF7B61FF),
//                 tooltip: 'Modifier',
//                 onPressed: onEdit,
//                 splashRadius: 24,
//                 constraints: const BoxConstraints(
//                   minWidth: 36,
//                   minHeight: 36,
//                 ),
//               ),
//               IconButton(
//                 icon: const Icon(Icons.delete_outline, size: 20),
//                 color: Colors.redAccent,
//                 tooltip: 'Supprimer',
//                 onPressed: onDelete,
//                 splashRadius: 24,
//                 constraints: const BoxConstraints(
//                   minWidth: 36,
//                   minHeight: 36,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class ServicePromotionCard extends StatelessWidget {
//   final ServiceWithPromo service;
//   final VoidCallback onRefresh;
//
//   const ServicePromotionCard({
//     super.key,
//     required this.service,
//     required this.onRefresh,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     // 🔥 AMÉLIORATION : Utilisation des nouvelles méthodes du modèle
//     final hasActivePromo = service.hasActivePromotion();
//     final futurePromos = service.promotions_a_venir;
//     final bool hasPromos = hasActivePromo || service.hasFuturePromotions();
//
//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
//       elevation: 2,
//       shadowColor: Colors.black.withOpacity(0.1),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Container(
//                   width: 46,
//                   height: 46,
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF7B61FF).withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: const Icon(
//                     Icons.spa,
//                     color: Color(0xFF7B61FF),
//                     size: 24,
//                   ),
//                 ),
//                 const SizedBox(width: 14),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         service.intitule,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Row(
//                         children: [
//                           const Icon(
//                             Icons.access_time,
//                             size: 14,
//                             color: Color(0xFF7B61FF),
//                           ),
//                           const SizedBox(width: 4),
//                           Text(
//                             '${service.temps} min',
//                             style: TextStyle(
//                               color: Colors.grey[700],
//                               fontSize: 13,
//                             ),
//                           ),
//                           Container(
//                             margin: const EdgeInsets.symmetric(horizontal: 6),
//                             width: 4,
//                             height: 4,
//                             decoration: BoxDecoration(
//                               color: Colors.grey[400],
//                               shape: BoxShape.circle,
//                             ),
//                           ),
//                           const Icon(
//                             Icons.euro,
//                             size: 14,
//                             color: Color(0xFF7B61FF),
//                           ),
//                           const SizedBox(width: 4),
//                           // 🔥 AMÉLIORATION : Affichage du prix original et du prix final
//                           if (hasActivePromo) ...[
//                             Text(
//                               '${service.prix} €',
//                               style: TextStyle(
//                                 color: Colors.grey[500],
//                                 fontSize: 13,
//                                 decoration: TextDecoration.lineThrough,
//                               ),
//                             ),
//                             const SizedBox(width: 4),
//                             Text(
//                               '${service.getPrixAvecReduction().toStringAsFixed(2)} €',
//                               style: const TextStyle(
//                                 color: Color(0xFF4CAF50),
//                                 fontSize: 13,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ] else
//                             Text(
//                               '${service.prix} €',
//                               style: TextStyle(
//                                 color: Colors.grey[700],
//                                 fontSize: 13,
//                               ),
//                             ),
//                         ],
//                       ),
//                       // 🔥 NOUVEAU : Affichage du nom du salon si disponible
//                       if (service.salonNom != null) ...[
//                         const SizedBox(height: 2),
//                         Row(
//                           children: [
//                             Icon(
//                               Icons.store,
//                               size: 12,
//                               color: Colors.grey[600],
//                             ),
//                             const SizedBox(width: 4),
//                             Text(
//                               service.salonNom!,
//                               style: TextStyle(
//                                 color: Colors.grey[600],
//                                 fontSize: 11,
//                                 fontStyle: FontStyle.italic,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ],
//                   ),
//                 ),
//                 ElevatedButton(
//                   onPressed: () {
//                     showCreatePromotionModal(
//                       context: context,
//                       salonId: service.salonId,
//                       serviceId: service.id,
//                       onPromoAdded: onRefresh,
//                     );
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF7B61FF),
//                     foregroundColor: Colors.white,
//                     elevation: 0,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//                   ),
//                   child: const Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(Icons.add, size: 18),
//                       SizedBox(width: 4),
//                       Text('Promo'),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//
//             // 🔥 NOUVEAU : Badge promotions si il y en a plusieurs
//             if (service.getTotalPromotionsCount() > 0) ...[
//               const SizedBox(height: 8),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF7B61FF).withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Text(
//                   '${service.getTotalPromotionsCount()} promotion${service.getTotalPromotionsCount() > 1 ? 's' : ''}',
//                   style: const TextStyle(
//                     fontSize: 12,
//                     color: Color(0xFF7B61FF),
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//             ],
//
//             if (hasPromos) const Divider(height: 30),
//
//             // Active promotion
//             if (hasActivePromo)
//               PromotionItem(
//                 promotion: service.promotion_active!,
//                 service: service,
//                 isCompact: true,
//                 onDelete: () => showDeletePromotionDialog(
//                   context: context,
//                   promotionFull: service.promotion_active!,
//                   onSuccess: onRefresh,
//                 ),
//                 onEdit: () {
//                   showEditPromotionModal(
//                     context: context,
//                     salonId: service.salonId,
//                     serviceId: service.id,
//                     promotion: service.promotion_active!,
//                     onPromoUpdated: onRefresh,
//                   );
//                 },
//               ),
//
//             // Future promotions
//             ...futurePromos.take(2).map((promo) => PromotionItem(
//               promotion: promo,
//               service: service,
//               isCompact: true,
//               onDelete: () => showDeletePromotionDialog(
//                 context: context,
//                 promotionFull: promo,
//                 onSuccess: onRefresh,
//               ),
//               onEdit: () {
//                 showEditPromotionModal(
//                   context: context,
//                   salonId: service.salonId,
//                   serviceId: service.id,
//                   promotion: promo,
//                   onPromoUpdated: onRefresh,
//                 );
//               },
//             )),
//
//             if (!hasActivePromo && service.getNextPromotion() != null) ...[
//               const SizedBox(height: 8),
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFFF9800).withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.3)),
//                 ),
//                 child: Row(
//                   children: [
//                     const Icon(Icons.upcoming, color: Color(0xFFFF9800), size: 20),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: Text(
//                         'Prochaine promo: ${service.getNextPromotion()!.pourcentage.toStringAsFixed(0)}% dès le ${DateFormatter.formatDate(service.getNextPromotion()!.dateDebut)}',
//                         style: const TextStyle(
//                           fontSize: 13,
//                           color: Color(0xFFFF9800),
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//
//             // View all button
//             if (futurePromos.length > 2 || hasActivePromo)
//               Padding(
//                 padding: const EdgeInsets.only(top: 12),
//                 child: Align(
//                   alignment: Alignment.center,
//                   child: TextButton.icon(
//                     onPressed: () => showAllPromotionsModal(
//                       context: context,
//                       serviceWithPromo: service,
//                       onRefresh: onRefresh,
//                     ),
//                     icon: const Icon(Icons.calendar_month, size: 18),
//                     label: Text('Voir toutes les promotions (${service.getTotalPromotionsCount()})'),
//                     style: TextButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                       foregroundColor: const Color(0xFF7B61FF),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       backgroundColor: const Color(0xFF7B61FF).withOpacity(0.1),
//                     ),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
