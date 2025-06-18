////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                PAGE D'INTERFACE UTILISATEUR POUR "MES COMMANDES"             //
//                                                                            //
//  Ce fichier définit l'écran `MesCommandesPage`, qui permet à un client de  //
//  consulter l'historique de ses rendez-vous (commandes).                    //
//                                                                            //
//  Fonctionnalités Clés :                                                    //
//  - Affiche une liste de commandes récupérées via `CommandesApiService`.    //
//  - Implémente un système d'onglets pour filtrer les commandes par statut.  //
//  - Intègre un `CommandesPaginationMixin` pour gérer la pagination          //
//    ("infinite scroll") de manière efficace et réutilisable.                //
//  - Gère les différents états de l'interface : chargement, erreur, liste    //
//    vide, et liste peuplée.                                                 //
//  - Utilise `RefreshIndicator` pour permettre à l'utilisateur de rafraîchir //
//    manuellement la liste des commandes.                                    //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;

import 'package:flutter/material.dart';
import 'package:hairbnb/pages/mes_commandes/services/card_service.dart';
import 'package:hairbnb/pages/mes_commandes/services/pagination_service.dart';
import 'package:hairbnb/pages/mes_commandes/widgets/loading_indicator_widget.dart';
import 'dart:async';
import '../../models/current_user.dart';
import '../../models/mes_commandes.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/custom_app_bar.dart';
import 'api/mes_commandes_api.dart';

/// Widget principal de la page "Mes Commandes".
class MesCommandesPage extends StatefulWidget {
  /// L'objet représentant l'utilisateur (client) actuellement connecté.
  final CurrentUser currentUser;

  /// Constructeur de la page, nécessitant l'utilisateur actuel.
  const MesCommandesPage({super.key, required this.currentUser});

  @override
  State<MesCommandesPage> createState() => _MesCommandesPageState();
}

/// Classe d'état pour `MesCommandesPage`.
/// Utilise `CommandesPaginationMixin` pour hériter de la logique de pagination.
class _MesCommandesPageState extends State<MesCommandesPage> with CommandesPaginationMixin {
  //region Déclaration des variables d'état
  /// `true` si les données initiales sont en cours de chargement.
  bool _isLoading = true;
  /// Stocke un message d'erreur en cas de problème.
  String? _error;
  /// L'index du filtre actuellement sélectionné dans la liste `_filters`.
  int _selectedFilterIndex = 0;
  /// La liste des libellés pour les onglets de filtre.
  final List<String> _filters = ['Tous', 'Confirmés', 'En attente', 'Terminés', 'Annulés'];
  /// L'index de l'onglet actuellement sélectionné dans le `BottomNavBar`.
  int _currentNavIndex = 0;
  /// La liste complète et non filtrée de toutes les commandes de l'utilisateur.
  List<Commande> _commandes = [];
  //endregion

  @override
  void initState() {
    super.initState();
    // Lance le chargement initial des commandes.
    _chargerCommandes();
    // Définit l'index initial pour la barre de navigation.
    _currentNavIndex = 2;
  }

  /// Gère le changement d'index de la barre de navigation.
  void _onNavIndexChanged(int index) {
    setState(() {
      _currentNavIndex = index;
    });
  }

  /// Récupère la liste complète des commandes depuis l'API.
  Future<void> _chargerCommandes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Appelle le service API pour obtenir les commandes.
      final commandes = await CommandesApiService.chargerCommandes(widget.currentUser.idTblUser);
      setState(() {
        _commandes = commandes;
        _isLoading = false;

        // Met à jour la liste complète dans le mixin de pagination.
        setFullCommandesList(_filteredCommandes);
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Un `getter` qui retourne une liste de commandes filtrée en fonction de `_selectedFilterIndex`.
  List<Commande> get _filteredCommandes {
    // Si l'index est 0 ("Tous"), retourne la liste complète.
    if (_selectedFilterIndex == 0) return _commandes;

    // Map pour faire correspondre les libellés de filtre aux statuts réels du modèle.
    // Gère plusieurs variations possibles pour chaque statut.
    Map<String, List<String>> statusMap = {
      'confirmés': ['confirmé', 'confirme', 'confirmes'],
      'en attente': ['en attente', 'en_attente', 'attente'],
      'terminés': ['terminé', 'termine', 'termines'],
      'annulés': ['annulé', 'annule', 'annules'],
    };

    final String filterLabel = _filters[_selectedFilterIndex].toLowerCase().trim();
    final List<String> matchingStatuses = statusMap[filterLabel] ?? [filterLabel];

    // Filtre la liste des commandes.
    return _commandes.where((commande) {
      final normalizedStatus = commande.statut.toLowerCase().trim();
      return matchingStatuses.contains(normalizedStatus);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: _onNavIndexChanged,
      ),
      // Le corps de la page est construit par une méthode dédiée.
      body: _buildBody(),
    );
  }

  //region Méthodes de construction de l'UI (Widgets)
  /// Construit le corps principal de la page en fonction de l'état actuel (chargement, erreur, etc.).
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: LoadingIndicator(message: 'Chargement de vos commandes...'));
    }
    if (_error != null) {
      return _buildErrorView();
    }
    if (_commandes.isEmpty) {
      return _buildEmptyView();
    }
    // Affiche le contenu principal si tout est chargé correctement.
    return Column(
      children: [
        _buildFilterTabs(), // Les onglets de filtre en haut.
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await _chargerCommandes();
              await refreshList(); // Méthode du mixin de pagination.
            },
            color: Colors.purple.shade400,
            child: paginatedCommandes.isEmpty // `paginatedCommandes` vient du mixin.
                ? _buildNoFilterMatchView()
                : _buildCommandesList(),
          ),
        ),
      ],
    );
  }

  /// Construit la barre d'onglets horizontale pour les filtres.
  Widget _buildFilterTabs() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilterIndex = index;
                // Met à jour la liste à paginer lorsque le filtre change.
                setFullCommandesList(_filteredCommandes);
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: _selectedFilterIndex == index ? Colors.purple.shade400 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(25),
              ),
              alignment: Alignment.center,
              child: Text(
                _filters[index],
                style: TextStyle(
                  color: _selectedFilterIndex == index ? Colors.white : Colors.grey.shade700,
                  fontWeight: _selectedFilterIndex == index ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Construit la liste des commandes avec un défilement infini.
  Widget _buildCommandesList() {
    return ListView.builder(
      controller: scrollController, // Le contrôleur vient du mixin de pagination.
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      // La longueur de la liste est augmentée de 1 si on charge plus d'éléments.
      itemCount: paginatedCommandes.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Affiche l'indicateur de chargement à la fin de la liste.
        if (isLoadingMore && index == paginatedCommandes.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(child: CircularProgressIndicator(color: Colors.purple.shade400, strokeWidth: 3)),
          );
        }
        // Affiche une carte de commande.
        return CommandeCard(commande: paginatedCommandes[index]);
      },
    );
  }

  /// Construit la vue affichée lorsqu'aucun résultat ne correspond au filtre sélectionné.
  Widget _buildNoFilterMatchView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_list_off, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Aucune commande ${_filters[_selectedFilterIndex].toLowerCase()}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade700), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Essayez un autre filtre pour voir vos commandes', style: TextStyle(color: Colors.grey.shade600, fontSize: 16), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  /// Construit la vue affichée en cas d'erreur de chargement des données.
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.error_outline_rounded, size: 60, color: Colors.redAccent),
          ),
          const SizedBox(height: 20),
          Text('Oups! Quelque chose s\'est mal passé', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(_error!, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _chargerCommandes,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade400, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  /// Construit la vue affichée lorsque l'utilisateur n'a aucune commande.
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(100)),
            child: Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.purple.shade300),
          ),
          const SizedBox(height: 24),
          const Text('Aucune commande pour le moment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text('Découvrez nos salons et faites votre première réservation', style: TextStyle(fontSize: 16, color: Colors.grey.shade600), textAlign: TextAlign.center),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pushNamed('/catalogue'),
            icon: const Icon(Icons.storefront_rounded),
            label: const Text('Découvrir les salons'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade400, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

//endregion
}








// import 'package:flutter/material.dart';
// import 'package:hairbnb/models/current_user.dart';
// import 'package:hairbnb/pages/mes_commandes/services/card_service.dart';
// import 'package:hairbnb/pages/mes_commandes/services/pagination_service.dart';
// import 'package:hairbnb/pages/mes_commandes/widgets/loading_indicator_widget.dart';
// import 'dart:async';
// import '../../models/mes_commandes.dart';
// import '../../widgets/bottom_nav_bar.dart';
// import '../../widgets/custom_app_bar.dart';
// import 'api/mes_commandes_api.dart';
//
// class MesCommandesPage extends StatefulWidget {
//   final CurrentUser currentUser;
//
//   const MesCommandesPage({super.key, required this.currentUser});
//
//   @override
//   State<MesCommandesPage> createState() => _MesCommandesPageState();
// }
//
// class _MesCommandesPageState extends State<MesCommandesPage> with CommandesPaginationMixin {
//   bool _isLoading = true;
//   String? _error;
//   int _selectedFilterIndex = 0;
//   final List<String> _filters = ['Tous', 'Confirmés', 'En attente', 'Terminés', 'Annulés'];
//   int _currentNavIndex = 0;
//
//   // Liste complète des commandes (non filtrées)
//   List<Commande> _commandes = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _chargerCommandes();
//     _currentNavIndex = 2;
//   }
//
//   // La méthode pour gérer les changements d'onglet
//   void _onNavIndexChanged(int index) {
//     setState(() {
//       _currentNavIndex = index;
//     });
//   }
//
//   Future<void> _chargerCommandes() async {
//     setState(() {
//       _isLoading = true;
//       _error = null;
//     });
//
//     try {
//       final commandes = await CommandesApiService.chargerCommandes(widget.currentUser.idTblUser);
//       setState(() {
//         _commandes = commandes;
//         _isLoading = false;
//
//         // Mettre à jour la liste pour la pagination
//         setFullCommandesList(_filteredCommandes);
//       });
//     } catch (e) {
//       setState(() {
//         _error = e.toString();
//         _isLoading = false;
//       });
//     }
//   }
//
//   // Filtrer les commandes selon le statut sélectionné
//   List<Commande> get _filteredCommandes {
//     if (_selectedFilterIndex == 0) return _commandes;
//
//     // Convertir les statuts pour qu'ils correspondent
//     Map<String, List<String>> statusMap = {
//       'confirmés': ['confirmé', 'confirme', 'confirmes'],
//       'en attente': ['en attente', 'en_attente', 'attente'],
//       'terminés': ['terminé', 'termine', 'termines'],
//       'annulés': ['annulé', 'annule', 'annules'],
//     };
//
//     final String filterLabel = _filters[_selectedFilterIndex].toLowerCase().trim();
//     final List<String> matchingStatuses = statusMap[filterLabel] ?? [filterLabel];
//
//     return _commandes.where((commande) {
//       final normalizedStatus = commande.statut.toLowerCase().trim();
//       return matchingStatuses.contains(normalizedStatus);
//     }).toList();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: const CustomAppBar(),
//       bottomNavigationBar: BottomNavBar(
//         currentIndex: _currentNavIndex,
//         onTap: _onNavIndexChanged,
//       ),
//       body: _buildBody(),
//     );
//   }
//
//   Widget _buildBody() {
//     if (_isLoading) {
//       return const Center(
//         child: LoadingIndicator(message: 'Chargement de vos commandes...'),
//       );
//     }
//
//     if (_error != null) {
//       return _buildErrorView();
//     }
//
//     if (_commandes.isEmpty) {
//       return _buildEmptyView();
//     }
//
//     return Column(
//       children: [
//         // Filtres en haut
//         _buildFilterTabs(),
//
//         // Liste des commandes avec pagination
//         Expanded(
//           child: RefreshIndicator(
//             onRefresh: () async {
//               await _chargerCommandes();
//               await refreshList();
//             },
//             color: Colors.purple.shade400,
//             child: paginatedCommandes.isEmpty
//                 ? _buildNoFilterMatchView()
//                 : _buildCommandesList(),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildFilterTabs() {
//     return Container(
//       height: 50,
//       margin: const EdgeInsets.symmetric(vertical: 16),
//       child: ListView.builder(
//         scrollDirection: Axis.horizontal,
//         padding: const EdgeInsets.symmetric(horizontal: 16),
//         itemCount: _filters.length,
//         itemBuilder: (context, index) {
//           return GestureDetector(
//             onTap: () {
//               setState(() {
//                 _selectedFilterIndex = index;
//                 // Mettre à jour la liste paginée lorsque le filtre change
//                 setFullCommandesList(_filteredCommandes);
//               });
//             },
//             child: Container(
//               margin: const EdgeInsets.only(right: 12),
//               padding: const EdgeInsets.symmetric(horizontal: 20),
//               decoration: BoxDecoration(
//                 color: _selectedFilterIndex == index
//                     ? Colors.purple.shade400
//                     : Colors.grey.shade200,
//                 borderRadius: BorderRadius.circular(25),
//               ),
//               alignment: Alignment.center,
//               child: Text(
//                 _filters[index],
//                 style: TextStyle(
//                   color: _selectedFilterIndex == index
//                       ? Colors.white
//                       : Colors.grey.shade700,
//                   fontWeight: _selectedFilterIndex == index
//                       ? FontWeight.bold
//                       : FontWeight.normal,
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildCommandesList() {
//     return ListView.builder(
//       controller: scrollController, // Utiliser le contrôleur de la pagination
//       padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//       itemCount: paginatedCommandes.length + (isLoadingMore ? 1 : 0),
//       itemBuilder: (context, index) {
//         // Afficher l'indicateur de chargement si on charge plus d'éléments
//         if (isLoadingMore && index == paginatedCommandes.length) {
//           return Padding(
//             padding: const EdgeInsets.symmetric(vertical: 16.0),
//             child: Center(
//               child: CircularProgressIndicator(
//                 color: Colors.purple.shade400,
//                 strokeWidth: 3,
//               ),
//             ),
//           );
//         }
//
//         // Afficher une carte de commande
//         return CommandeCard(commande: paginatedCommandes[index]);
//       },
//     );
//   }
//
//   Widget _buildNoFilterMatchView() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 32.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.filter_list_off,
//               size: 60,
//               color: Colors.grey.shade400,
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'Aucune commande ${_filters[_selectedFilterIndex].toLowerCase()}',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey.shade700,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Essayez un autre filtre pour voir vos commandes',
//               style: TextStyle(
//                 color: Colors.grey.shade600,
//                 fontSize: 16,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildErrorView() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               color: Colors.red.shade50,
//               borderRadius: BorderRadius.circular(16),
//             ),
//             child: const Icon(
//               Icons.error_outline_rounded,
//               size: 60,
//               color: Colors.redAccent,
//             ),
//           ),
//           const SizedBox(height: 20),
//           Text(
//             'Oups! Quelque chose s\'est mal passé',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: Colors.grey.shade800,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 40),
//             child: Text(
//               _error!,
//               textAlign: TextAlign.center,
//               style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
//             ),
//           ),
//           const SizedBox(height: 24),
//           ElevatedButton.icon(
//             onPressed: _chargerCommandes,
//             icon: const Icon(Icons.refresh_rounded),
//             label: const Text('Réessayer'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.purple.shade400,
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               elevation: 0,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildEmptyView() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             padding: const EdgeInsets.all(30),
//             decoration: BoxDecoration(
//               color: Colors.purple.shade50,
//               borderRadius: BorderRadius.circular(100),
//             ),
//             child: Icon(
//               Icons.shopping_bag_outlined,
//               size: 80,
//               color: Colors.purple.shade300,
//             ),
//           ),
//           const SizedBox(height: 24),
//           const Text(
//             'Aucune commande pour le moment',
//             style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 8),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 40),
//             child: Text(
//               'Découvrez nos salons et faites votre première réservation',
//               style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
//               textAlign: TextAlign.center,
//             ),
//           ),
//           const SizedBox(height: 32),
//           ElevatedButton.icon(
//             onPressed: () {
//               Navigator.of(context).pushNamed('/catalogue');
//             },
//             icon: const Icon(Icons.storefront_rounded),
//             label: const Text('Découvrir les salons'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.purple.shade400,
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               elevation: 0,
//               textStyle: const TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
