/// *************************************************************************************************
///
/// BANNER : EXPLICATION GÉNÉRALE DU WIDGET
///
/// Ce fichier définit `ServicesAjoutesWidget`, un `StatefulWidget` réutilisable.
///
/// Objectif :
/// Ce widget est conçu pour afficher, dans une tuile extensible (`ExpansionTile`), la
/// liste des services qu'une coiffeuse a déjà ajoutés à son profil. Il sert de
/// résumé visuel et de point d'accès rapide.
///
/// Fonctionnalités :
/// - Affichage Conditionnel : La tuile affiche le nombre de services ajoutés et peut être
/// étendue pour voir la liste détaillée.
/// - Gestion des États : Gère visuellement l'état de chargement (`isLoading`) et le cas
/// où aucun service n'a encore été ajouté (état vide).
/// - Interaction Utilisateur :
/// - Un bouton de rafraîchissement (`onRefresh`) permet de recharger la liste.
/// - Un bouton de navigation permet de passer à l'étape suivante (la galerie).
/// - Section de Débogage : Inclut une section distincte et clairement identifiée pour
/// aider au développement. Elle contient un bouton pour tester manuellement l'appel API
/// qui charge les services, fournissant un retour immédiat dans la console et via
/// des SnackBars.
///
///*************************************************************************************************
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hairbnb/models/current_user.dart';
import 'package:hairbnb/pages/salon/gallery/add_gallery_page.dart';

import '../../../../../models/services.dart';
import 'create_firsts_services_api/services_api_service.dart';

/// Un widget qui affiche la liste des services déjà ajoutés par la coiffeuse.
/// Il se présente sous la forme d'une tuile extensible.
class ServicesAjoutesWidget extends StatefulWidget {
  /// L'utilisateur actuellement connecté.
  final CurrentUser currentUser;
  /// La liste des services déjà ajoutés à afficher.
  final List<Service> servicesAjoutes;
  /// Un booléen pour indiquer si un chargement est en cours.
  final bool isLoading;
  /// Une fonction de rappel pour rafraîchir la liste des services.
  final VoidCallback onRefresh;

  const ServicesAjoutesWidget({
    super.key,
    required this.currentUser,
    required this.servicesAjoutes,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  State<ServicesAjoutesWidget> createState() => _ServicesAjoutesWidgetState();
}

class _ServicesAjoutesWidgetState extends State<ServicesAjoutesWidget> {
  // État local pour gérer le chargement du test API de débogage.
  bool _isTestingApi = false;

  @override
  Widget build(BuildContext context) {
    // Conteneur principal avec une couleur de fond verte claire.
    return Container(
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border(bottom: BorderSide(color: Colors.green.shade200)),
      ),
      // Utilise une ExpansionTile pour afficher/masquer la liste des services.
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(8)),
          child: Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
        ),
        // Titre de la tuile.
        title: Row(
          children: [
            Expanded(
              child: Text(
                "Mes services ajoutés",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700),
              ),
            ),
            // Bouton pour rafraîchir manuellement les données.
            IconButton(
              onPressed: widget.onRefresh,
              icon: Icon(Icons.refresh, color: Colors.green.shade600, size: 16),
              tooltip: "Recharger les services",
            ),
          ],
        ),
        // Sous-titre affichant le statut de chargement ou le nombre de services.
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isLoading)
              const Text("Chargement...")
            else
              Text(
                "${widget.servicesAjoutes.length} service(s)",
                style: TextStyle(color: Colors.green.shade600, fontSize: 12),
              ),
            // Affiche des informations de débogage utiles.
            Text(
              "UserID: ${widget.currentUser.idTblUser} | Debug actif",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
            ),
          ],
        ),
        // Contenu de la tuile une fois étendue.
        children: [
          if (widget.isLoading)
            const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
          else if (widget.servicesAjoutes.isEmpty)
            _construireEtatVide() // Affiche l'état vide si aucun service n'est ajouté.
          else
            _construireListeServices(), // Affiche la liste des services.

          // Affiche la section de débogage.
          _construireSectionDebug(),
        ],
      ),
    );
  }

  /// Construit le widget à afficher lorsqu'aucun service n'a été ajouté.
  Widget _construireEtatVide() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 32, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text("Aucun service ajouté pour le moment", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          const SizedBox(height: 12),
          // Bouton pour naviguer vers l'étape suivante.
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AddGalleryPage()));
            },
            icon: const Icon(Icons.photo_library),
            label: const Text("Aller à la galerie"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ],
      ),
    );
  }

  /// Construit la liste visuelle des services ajoutés.
  Widget _construireListeServices() {
    return Column(
      children: [
        // Conteneur avec une hauteur maximale pour que la liste soit scrollable si elle est longue.
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.servicesAjoutes.length,
            itemBuilder: (context, index) {
              final service = widget.servicesAjoutes[index];
              // Chaque service est affiché dans un conteneur stylisé.
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.shade200)),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.green.shade400, shape: BoxShape.circle)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(service.intitule, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                          if (service.description.isNotEmpty)
                            Text(service.description, style: TextStyle(fontSize: 12, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Icon(Icons.check_circle, color: Colors.green.shade400, size: 16),
                  ],
                ),
              );
            },
          ),
        ),
        // Bouton pour passer à l'étape suivante, affiché sous la liste.
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AddGalleryPage()));
              },
              icon: const Icon(Icons.photo_library),
              label: const Text("Aller à la galerie"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
        ),
      ],
    );
  }

  /// Construit la section de débogage pour tester l'API.
  Widget _construireSectionDebug() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.grey.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Informations de débogage:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
          const SizedBox(height: 4),
          Text("UserID: ${widget.currentUser.idTblUser}", style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          Text("Services chargés: ${widget.servicesAjoutes.length}", style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          Text("État de chargement: ${widget.isLoading}", style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          // Bouton pour lancer manuellement le test de l'API.
          ElevatedButton.icon(
            onPressed: _isTestingApi ? null : _testerApi, // Désactivé pendant le test.
            icon: _isTestingApi
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.bug_report, size: 14),
            label: Text(_isTestingApi ? "Test en cours..." : "Test API", style: const TextStyle(fontSize: 10)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, minimumSize: const Size(0, 30)),
          ),
        ],
      ),
    );
  }

  /// Fonction pour tester l'appel API qui charge les services ajoutés.
  Future<void> _testerApi() async {
    setState(() => _isTestingApi = true);
    try {
      if (kDebugMode) {
        print("Début du test API direct...");
        print("UserID utilisé pour le test: ${widget.currentUser.idTblUser}");
      }
      final services = await ServicesApiService.chargerServicesAjoutes(widget.currentUser.idTblUser);

      // Affiche le résultat dans une SnackBar.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Test API: ${services.length} services récupérés. Vérifiez la console pour les détails."), backgroundColor: Colors.blue));
      }
    } catch (e) {
      if (kDebugMode) print("Erreur lors du test API: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur lors du test: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isTestingApi = false);
      }
    }
  }
}







// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:hairbnb/models/current_user.dart';
// import 'package:hairbnb/pages/salon/gallery/add_gallery_page.dart';
//
// import '../../../../../models/services.dart';
// import 'create_firsts_services_api/services_api_service.dart';
//
// class ServicesAjoutesWidget extends StatefulWidget {
//   final CurrentUser currentUser;
//   final List<Service> servicesAjoutes;
//   final bool isLoading;
//   final VoidCallback onRefresh;
//
//   const ServicesAjoutesWidget({
//     super.key,
//     required this.currentUser,
//     required this.servicesAjoutes,
//     required this.isLoading,
//     required this.onRefresh,
//   });
//
//   @override
//   State<ServicesAjoutesWidget> createState() => _ServicesAjoutesWidgetState();
// }
//
// class _ServicesAjoutesWidgetState extends State<ServicesAjoutesWidget> {
//   bool _isTestingApi = false;
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.green.shade50,
//         border: Border(bottom: BorderSide(color: Colors.green.shade200)),
//       ),
//       child: ExpansionTile(
//         leading: Container(
//           padding: const EdgeInsets.all(6),
//           decoration: BoxDecoration(
//             color: Colors.green.shade100,
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
//         ),
//         title: Row(
//           children: [
//             Expanded(
//               child: Text(
//                 "Mes services ajoutés",
//                 style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700),
//               ),
//             ),
//             // Bouton de refresh
//             IconButton(
//               onPressed: widget.onRefresh,
//               icon: Icon(Icons.refresh, color: Colors.green.shade600, size: 16),
//               tooltip: "Recharger les services",
//             ),
//           ],
//         ),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             if (widget.isLoading)
//               const Text("Chargement...")
//             else
//               Text(
//                 "${widget.servicesAjoutes.length} service(s)",
//                 style: TextStyle(color: Colors.green.shade600, fontSize: 12),
//               ),
//             // Info de debug
//             Text(
//               "UserID: ${widget.currentUser.idTblUser} | Debug actif",
//               style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
//             ),
//           ],
//         ),
//         children: [
//           if (widget.isLoading)
//             const Padding(
//               padding: EdgeInsets.all(16),
//               child: Center(child: CircularProgressIndicator()),
//             )
//           else if (widget.servicesAjoutes.isEmpty)
//             _construireEtatVide()
//           else
//             _construireListeServices(),
//
//           // Section debug
//           _construireSectionDebug(),
//         ],
//       ),
//     );
//   }
//
//   Widget _construireEtatVide() {
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         children: [
//           Icon(Icons.inbox_outlined, size: 32, color: Colors.grey.shade400),
//           const SizedBox(height: 8),
//           Text(
//             "Aucun service ajouté pour le moment",
//             style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
//           ),
//           const SizedBox(height: 12),
//           ElevatedButton.icon(
//             onPressed: () {
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(builder: (context) => const AddGalleryPage()),
//               );
//             },
//             icon: const Icon(Icons.photo_library),
//             label: const Text("Aller à la galerie"),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.orange,
//               foregroundColor: Colors.white,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _construireListeServices() {
//     return Column(
//       children: [
//         Container(
//           constraints: const BoxConstraints(maxHeight: 200),
//           child: ListView.builder(
//             shrinkWrap: true,
//             itemCount: widget.servicesAjoutes.length,
//             itemBuilder: (context, index) {
//               final service = widget.servicesAjoutes[index];
//               return Container(
//                 margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.green.shade200),
//                 ),
//                 child: Row(
//                   children: [
//                     Container(
//                       width: 8,
//                       height: 8,
//                       decoration: BoxDecoration(
//                         color: Colors.green.shade400,
//                         shape: BoxShape.circle,
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             service.intitule,
//                             style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                           if (service.description.isNotEmpty)
//                             Text(
//                               service.description,
//                               style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                         ],
//                       ),
//                     ),
//                     Icon(Icons.check_circle, color: Colors.green.shade400, size: 16),
//                   ],
//                 ),
//               );
//             },
//           ),
//         ),
//         Padding(
//           padding: const EdgeInsets.all(12),
//           child: SizedBox(
//             width: double.infinity,
//             child: ElevatedButton.icon(
//               onPressed: () {
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(builder: (context) => const AddGalleryPage()),
//                 );
//               },
//               icon: const Icon(Icons.photo_library),
//               label: const Text("Aller à la galerie"),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.orange,
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _construireSectionDebug() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(12),
//       color: Colors.grey.shade100,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             "🔍 Debug Info:",
//             style: TextStyle(
//               fontSize: 12,
//               fontWeight: FontWeight.bold,
//               color: Colors.grey.shade700,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             "• UserID: ${widget.currentUser.idTblUser}",
//             style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
//           ),
//           Text(
//             "• Services chargés: ${widget.servicesAjoutes.length}",
//             style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
//           ),
//           Text(
//             "• État loading: ${widget.isLoading}",
//             style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
//           ),
//           const SizedBox(height: 8),
//           ElevatedButton.icon(
//             onPressed: _isTestingApi ? null : _testerApi,
//             icon: _isTestingApi
//                 ? SizedBox(
//               width: 14,
//               height: 14,
//               child: CircularProgressIndicator(strokeWidth: 2),
//             )
//                 : Icon(Icons.bug_report, size: 14),
//             label: Text(
//               _isTestingApi ? "Test en cours..." : "Test API",
//               style: TextStyle(fontSize: 10),
//             ),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.blue,
//               foregroundColor: Colors.white,
//               minimumSize: Size(0, 30),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _testerApi() async {
//     setState(() => _isTestingApi = true);
//
//     try {
//       if (kDebugMode) {
//         print("🔄 DEBUG: Test API direct");
//       }
//       if (kDebugMode) {
//         print("🔄 UserID utilisé: ${widget.currentUser.idTblUser}");
//       }
//
//       final services = await ServicesApiService.chargerServicesAjoutes(widget.currentUser.idTblUser);
//
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Debug: ${services.length} services récupérés. Vérifiez la console."),
//             backgroundColor: Colors.blue,
//           ),
//         );
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print("❌ Erreur lors du test API: $e");
//       }
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Erreur lors du test: $e"),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _isTestingApi = false);
//       }
//     }
//   }
// }