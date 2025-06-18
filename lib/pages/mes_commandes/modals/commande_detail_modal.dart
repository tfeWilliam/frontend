/// **************************************************************************************
///
/// WIDGET UI : MODALE DE DÉTAILS DE COMMANDE
///
/// OBJECTIF :
/// Ce fichier définit un widget, `CommandeDetailModal`, conçu pour être affiché
/// comme une feuille modale (modal bottom sheet). Il présente de manière claire et
/// structurée toutes les informations détaillées d'une commande ou d'un rendez-vous.
///
/// ARCHITECTURE ET FONCTIONNALITÉS CLÉS :
/// - C'est un `StatelessWidget`, ce qui signifie qu'il est purement déclaratif et
/// affiche les données qui lui sont passées en paramètre sans gérer d'état interne.
/// - L'interface est décomposée en méthodes de construction réutilisables
/// (`_buildDetailSection`, `_buildServicesSection`) pour une meilleure lisibilité.
/// - Affiche conditionnellement un widget de compte à rebours (`CountdownWidget`)
/// en fonction du statut et de l'expiration de la commande.
/// - Utilise un service externe (`StatusUtils`) pour déterminer la couleur du badge
/// de statut, centralisant ainsi la logique de style.
/// - Propose un bouton pour naviguer vers une page de reçu (`ReceiptPage`) si
/// l'URL du reçu est disponible.
///
///***************************************************************************************
library;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/mes_commandes.dart';
import '../services/status_utils_service.dart';
import '../sub_pages/recu_page.dart';
import '../widgets/countdown_widget.dart';

/// Un widget qui affiche les détails d'une commande dans une modale.
class CommandeDetailModal extends StatelessWidget {
  /// L'objet Commande contenant toutes les données à afficher.
  final Commande commande;
  /// La durée restante avant le début du rendez-vous.
  final Duration timeLeft;
  /// Un booléen indiquant si le rendez-vous est déjà passé.
  final bool isExpired;

  const CommandeDetailModal({
    super.key,
    required this.commande,
    required this.timeLeft,
    required this.isExpired,
  });

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormatter = DateFormat('dd/MM/yyyy');
    final DateFormat timeFormatter = DateFormat('HH:mm');

    return Container(
      // Définit la hauteur de la modale à 85% de la hauteur de l'écran.
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Poignée visuelle pour indiquer que la modale est déplaçable (draggable).
          Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(5),
            ),
          ),

          // En-tête de la modale avec titre, ID et statut de la commande.
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.purple.shade100, shape: BoxShape.circle),
                  child: const Icon(Icons.receipt_long_rounded, color: Colors.purple, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Détails de commande', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                      Text('Commande #${commande.idRendezVous}', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                // Badge de statut avec couleur dynamique.
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: StatusUtils.getStatusColor(commande.statut).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    commande.statut,
                    style: TextStyle(color: StatusUtils.getStatusColor(commande.statut), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // Affiche le compte à rebours sous certaines conditions de statut et d'expiration.
          if (!isExpired || (isExpired && !["annulé", "terminé"].contains(commande.statut.toLowerCase())))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: CountdownWidget(
                dateHeure: commande.dateHeure,
                statut: commande.statut,
                timeLeft: timeLeft,
                isExpired: isExpired,
              ),
            ),

          // Contenu principal scrollable contenant tous les détails.
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailSection('Salon', Icons.store_rounded, [commande.nomSalon, '${commande.prenomCoiffeuse} ${commande.nomCoiffeuse}']),
                  const SizedBox(height: 20),
                  _buildDetailSection('Date & Heure', Icons.event_rounded, ['${dateFormatter.format(commande.dateHeure)} à ${timeFormatter.format(commande.dateHeure)}', 'Durée: ${commande.dureeTotale} minutes']),
                  const SizedBox(height: 20),
                  _buildServicesSection(),
                  const SizedBox(height: 20),
                  _buildDetailSection('Paiement', Icons.payment_rounded, ['${commande.montantPaye.toStringAsFixed(2)} € - ${commande.methodePaiement}', 'Payé le ${dateFormatter.format(commande.datePaiement)}']),
                  const SizedBox(height: 30),

                  // Affiche le bouton du reçu uniquement si l'URL est disponible.
                  if (commande.receiptUrl != null && commande.receiptUrl!.isNotEmpty)
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => ReceiptPage(receiptUrl: commande.receiptUrl!)),
                          );
                        },
                        icon: const Icon(Icons.receipt_long),
                        label: const Text('Voir le reçu'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade400,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construit une section de détails générique avec un titre, une icône et une liste d'informations.
  Widget _buildDetailSection(String title, IconData icon, List<String> details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.purple.shade400),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ...details.map((detail) => Padding(
          padding: const EdgeInsets.only(left: 26, bottom: 4),
          child: Text(detail, style: TextStyle(fontSize: 15, color: Colors.grey.shade700)),
        )),
      ],
    );
  }

  /// Construit la section qui liste les services de la commande et affiche le total.
  Widget _buildServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.content_cut_rounded, size: 18, color: Colors.purple.shade400),
            const SizedBox(width: 8),
            const Text('Services', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        // Itère sur la liste des services de la commande pour les afficher.
        ...commande.services.map((service) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(service.intituleService, style: const TextStyle(fontSize: 15))),
              Text('${service.prixApplique.toStringAsFixed(2)} €', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.purple.shade700)),
            ],
          ),
        )),
        // Affiche le montant total de la commande.
        Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('${commande.montantPaye.toStringAsFixed(2)} €', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.purple)),
            ],
          ),
        ),
      ],
    );
  }
}









// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import '../../../models/mes_commandes.dart';
// import '../services/status_utils_service.dart';
// import '../sub_pages/recu_page.dart';
// import '../widgets/countdown_widget.dart';
//
// class CommandeDetailModal extends StatelessWidget {
//   final Commande commande;
//   final Duration timeLeft;
//   final bool isExpired;
//
//   const CommandeDetailModal({
//     super.key,
//     required this.commande,
//     required this.timeLeft,
//     required this.isExpired,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final DateFormat dateFormatter = DateFormat('dd/MM/yyyy');
//     final DateFormat timeFormatter = DateFormat('HH:mm');
//
//     return Container(
//       height: MediaQuery.of(context).size.height * 0.85,
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.only(
//           topLeft: Radius.circular(24),
//           topRight: Radius.circular(24),
//         ),
//       ),
//       child: Column(
//         children: [
//           // Barre d'indication
//           Container(
//             width: 40,
//             height: 5,
//             margin: const EdgeInsets.symmetric(vertical: 12),
//             decoration: BoxDecoration(
//               color: Colors.grey.shade300,
//               borderRadius: BorderRadius.circular(5),
//             ),
//           ),
//
//           // Titre
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(10),
//                   decoration: BoxDecoration(
//                     color: Colors.purple.shade100,
//                     shape: BoxShape.circle,
//                   ),
//                   child: const Icon(
//                       Icons.receipt_long_rounded,
//                       color: Colors.purple,
//                       size: 24
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Détails de commande',
//                         style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.grey.shade800,
//                         ),
//                       ),
//                       Text(
//                         'Commande #${commande.idRendezVous}',
//                         style: TextStyle(
//                           fontSize: 14,
//                           color: Colors.grey.shade600,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 10,
//                     vertical: 5,
//                   ),
//                   decoration: BoxDecoration(
//                     color: StatusUtils.getStatusColor(commande.statut).withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Text(
//                     commande.statut,
//                     style: TextStyle(
//                       color: StatusUtils.getStatusColor(commande.statut),
//                       fontWeight: FontWeight.bold,
//                       fontSize: 13,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           const Divider(),
//
//           // Compte à rebours dans les détails
//           if (!isExpired || (isExpired && !["annulé", "terminé"].contains(commande.statut.toLowerCase())))
//             Padding(
//               padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//               child: CountdownWidget(
//                 dateHeure: commande.dateHeure,
//                 statut: commande.statut,
//                 timeLeft: timeLeft,
//                 isExpired: isExpired,
//               ),
//             ),
//
//           // Contenu détaillé
//           Expanded(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Informations sur le salon
//                   _buildDetailSection(
//                     'Salon',
//                     Icons.store_rounded,
//                     [
//                       commande.nomSalon,
//                       '${commande.prenomCoiffeuse} ${commande.nomCoiffeuse}',
//                     ],
//                   ),
//
//                   const SizedBox(height: 20),
//
//                   // Informations sur la date
//                   _buildDetailSection(
//                     'Date & Heure',
//                     Icons.event_rounded,
//                     [
//                       '${dateFormatter.format(commande.dateHeure)} à ${timeFormatter.format(commande.dateHeure)}',
//                       'Durée: ${commande.dureeTotale} minutes',
//                     ],
//                   ),
//
//                   const SizedBox(height: 20),
//
//                   // Services commandés
//                   _buildServicesSection(),
//
//                   const SizedBox(height: 20),
//
//                   // Paiement
//                   _buildDetailSection(
//                     'Paiement',
//                     Icons.payment_rounded,
//                     [
//                       '${commande.montantPaye.toStringAsFixed(2)} € - ${commande.methodePaiement}',
//                       'Payé le ${dateFormatter.format(commande.datePaiement)}',
//                     ],
//                   ),
//
//                   const SizedBox(height: 30),
//
//                   // Bouton pour accéder au reçu si disponible
//                   if (commande.receiptUrl != null && commande.receiptUrl!.isNotEmpty)
//                     Center(
//                       child: ElevatedButton.icon(
//                         onPressed: () {
//                           Navigator.of(context).push(
//                             MaterialPageRoute(
//                               builder: (context) => ReceiptPage(receiptUrl: commande.receiptUrl!),
//                             ),
//                           );
//                         },
//                         icon: const Icon(Icons.receipt_long),
//                         label: const Text('Voir le reçu'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.purple.shade400,
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildDetailSection(String title, IconData icon, List<String> details) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Icon(icon, size: 18, color: Colors.purple.shade400),
//             const SizedBox(width: 8),
//             Text(
//               title,
//               style: const TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 8),
//         ...details.map((detail) => Padding(
//           padding: const EdgeInsets.only(left: 26, bottom: 4),
//           child: Text(
//             detail,
//             style: TextStyle(
//               fontSize: 15,
//               color: Colors.grey.shade700,
//             ),
//           ),
//         )).toList(),
//       ],
//     );
//   }
//
//   Widget _buildServicesSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Icon(Icons.content_cut_rounded, size: 18, color: Colors.purple.shade400),
//             const SizedBox(width: 8),
//             const Text(
//               'Services',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 12),
//         ...commande.services.map((service) => Container(
//           margin: const EdgeInsets.only(bottom: 10),
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: Colors.grey.shade50,
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: Colors.grey.shade200),
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Expanded(
//                 child: Text(
//                   service.intituleService,
//                   style: const TextStyle(fontSize: 15),
//                 ),
//               ),
//               Text(
//                 '${service.prixApplique.toStringAsFixed(2)} €',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16,
//                   color: Colors.purple.shade700,
//                 ),
//               ),
//             ],
//           ),
//         )).toList(),
//
//         // Total
//         Container(
//           margin: const EdgeInsets.only(top: 10),
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
//           decoration: BoxDecoration(
//             color: Colors.purple.shade50,
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text(
//                 'Total',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16,
//                 ),
//               ),
//               Text(
//                 '${commande.montantPaye.toStringAsFixed(2)} €',
//                 style: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 18,
//                   color: Colors.purple,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }