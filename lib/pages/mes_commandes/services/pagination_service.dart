/// **************************************************************************************
///
/// SYSTÈME DE PAGINATION CÔTÉ CLIENT
///
/// OBJECTIF :
/// Ce fichier fournit un système réutilisable pour implémenter une pagination de type
/// "load more" ou "infinite scroll" côté client. Il est conçu pour prendre une
/// liste complète de données et l'afficher de manière incrémentale à l'utilisateur
/// au fur et à mesure qu'il fait défiler la page.
///
/// ARCHITECTURE :
/// - PaginationService : Une classe utilitaire statique qui contient la logique
/// pure de "découpage" d'une liste pour extraire une sous-liste paginée.
///
/// - CommandesPaginationMixin : Un `mixin` puissant et réutilisable qui peut être
/// ajouté à n'importe quelle classe `State` d'un `StatefulWidget`. Ce mixin gère
/// toute la logique d'état de la pagination : écoute du défilement, chargement de
/// plus d'éléments, rafraîchissement, etc.
///
/// UTILISATION :
/// Une page (widget) qui a besoin de cette fonctionnalité doit :
/// 1. Utiliser le mixin : `with CommandesPaginationMixin`.
/// 2. Passer son `scrollController` (fourni par le mixin) à sa `ListView`.
/// 3. Appeler `setFullCommandesList` une fois la liste complète des données récupérée.
/// 4. Utiliser la liste `paginatedCommandes` (fournie par le mixin) comme source de
/// données pour sa `ListView.builder`.
///
///***************************************************************************************
library;
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/mes_commandes.dart';

/// Classe utilitaire statique contenant la logique de pagination de base.
class PaginationService {
  /// Nombre d'éléments à afficher lors du chargement initial.
  static const int kInitialItemsPerPage = 5;
  /// Nombre d'éléments à ajouter à chaque fois que l'utilisateur charge plus.
  static const int kItemsPerPageIncrement = 5;
  /// Nombre maximum d'éléments par "page" (non utilisé dans ce mixin).
  static const int kMaxItemsPerPage = 20;

  /// Extrait une sous-liste d'une liste complète pour simuler une pagination.
  /// Implémente une logique de type "load more", affichant les éléments de 0 à l'index de fin.
  ///
  /// [commandes] : La liste complète de toutes les commandes.
  /// [page] : La "page" actuelle, qui détermine le nombre total d'éléments à afficher.
  /// [itemsPerPage] : Le nombre d'éléments par page.
  static List<Commande> paginerCommandes({
    required List<Commande> commandes,
    required int page,
    required int itemsPerPage,
  }) {
    if (commandes.isEmpty) return [];

    // Calcule l'index de fin pour la sous-liste.
    final startIndex = 0;
    final endIndex = page * itemsPerPage;

    // S'assure de ne pas dépasser la longueur de la liste.
    if (startIndex >= commandes.length) return [];

    return commandes.sublist(
        startIndex,
        endIndex > commandes.length ? commandes.length : endIndex
    );
  }
}

/// Un `mixin` qui fournit une logique de pagination de type "infinite scroll" ou "load more"
/// à un `State` de `StatefulWidget`.
mixin CommandesPaginationMixin<T extends StatefulWidget> on State<T> {
  /// Nombre d'éléments à afficher par page.
  int _itemsPerPage = PaginationService.kInitialItemsPerPage;
  /// La "page" actuelle, utilisée pour calculer le nombre total d'items à montrer.
  int _currentPage = 1;
  /// Le contrôleur de défilement pour détecter la position de l'utilisateur.
  final ScrollController _scrollController = ScrollController();
  /// La liste complète des commandes, fournie de l'extérieur.
  List<Commande> _fullCommandesList = [];
  /// La sous-liste des commandes à afficher dans l'interface utilisateur.
  List<Commande> _paginatedCommandes = [];
  /// Booléen pour gérer l'état de chargement lors de l'ajout de nouveaux éléments.
  bool _isLoadingMore = false;
  /// Booléen pour indiquer si tous les éléments ont été chargés.
  bool _hasReachedEnd = false;

  @override
  void initState() {
    super.initState();
    // Ajoute un listener pour détecter quand l'utilisateur atteint le bas de la liste.
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  /// Méthode d'entrée pour initialiser le mixin avec la liste complète des données.
  void setFullCommandesList(List<Commande> commandes) {
    setState(() {
      _fullCommandesList = commandes;
      // Met à jour la liste affichée avec la première page.
      _updatePaginatedList();
    });
  }

  /// Détecte lorsque l'utilisateur s'approche de la fin de la liste pour déclencher le chargement.
  void _scrollListener() {
    // Si l'utilisateur est à moins de 200 pixels de la fin de la liste.
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        !_hasReachedEnd) {
      _loadMoreItems();
    }
  }

  /// Gère le chargement asynchrone des éléments suivants en incrémentant la page.
  Future<void> _loadMoreItems() async {
    if (_isLoadingMore || _hasReachedEnd) return;
    setState(() => _isLoadingMore = true);

    // Simule un délai réseau pour une meilleure expérience utilisateur.
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _currentPage++;
      _updatePaginatedList();
      _isLoadingMore = false;
    });
  }

  /// Réinitialise l'état de la pagination, typiquement pour une action "pull-to-refresh".
  Future<void> refreshList() async {
    setState(() {
      _currentPage = 1;
      _itemsPerPage = PaginationService.kInitialItemsPerPage;
      _hasReachedEnd = false;
    });
    // Applique la pagination à nouveau avec les paramètres réinitialisés.
    _updatePaginatedList();
  }

  /// Met à jour la liste des commandes affichées en appliquant la logique de pagination.
  void _updatePaginatedList() {
    final paginatedList = PaginationService.paginerCommandes(
      commandes: _fullCommandesList,
      page: _currentPage,
      itemsPerPage: _itemsPerPage,
    );

    // Vérifie si tous les éléments de la liste complète sont maintenant affichés.
    if (paginatedList.length == _fullCommandesList.length) {
      _hasReachedEnd = true;
    }

    setState(() {
      _paginatedCommandes = paginatedList;
    });
  }

  /// Getter pour accéder à la liste paginée à afficher dans l'interface utilisateur.
  List<Commande> get paginatedCommandes => _paginatedCommandes;

  /// Getter pour que le widget puisse utiliser le `ScrollController` géré par le mixin.
  ScrollController get scrollController => _scrollController;

  /// Getter pour savoir si le chargement de nouveaux éléments est en cours.
  bool get isLoadingMore => _isLoadingMore;
}






// import 'dart:async';
// import 'package:flutter/material.dart';
// import '../../../models/mes_commandes.dart';
//
// class PaginationService {
//   // Paramètres de pagination
//   static const int kInitialItemsPerPage = 5;  // Nombre d'éléments à afficher initialement
//   static const int kItemsPerPageIncrement = 5;  // Incrément lors du chargement de plus d'éléments
//   static const int kMaxItemsPerPage = 20;  // Maximum d'éléments par page
//
//   // Paginer les commandes avec un système intelligent
//   static List<Commande> paginerCommandes({
//     required List<Commande> commandes,
//     required int page,
//     required int itemsPerPage,
//   }) {
//     if (commandes.isEmpty) return [];
//
//     final startIndex = 0;
//     final endIndex = page * itemsPerPage;
//
//     if (startIndex >= commandes.length) return [];
//
//     return commandes.sublist(
//         startIndex,
//         endIndex > commandes.length ? commandes.length : endIndex
//     );
//   }
// }
//
// // Mixin à utiliser dans la page de commandes pour gérer la pagination
// mixin CommandesPaginationMixin<T extends StatefulWidget> on State<T> {
//   // Nombre d'éléments à afficher par page
//   int _itemsPerPage = PaginationService.kInitialItemsPerPage;
//
//   // Page actuelle
//   int _currentPage = 1;
//
//   // Contrôleur pour la liste déroulante
//   final ScrollController _scrollController = ScrollController();
//
//   // Liste complète des commandes
//   List<Commande> _fullCommandesList = [];
//
//   // Liste paginée des commandes à afficher
//   List<Commande> _paginatedCommandes = [];
//
//   // État de chargement des pages supplémentaires
//   bool _isLoadingMore = false;
//
//   // Flag si toutes les commandes sont chargées
//   bool _hasReachedEnd = false;
//
//   @override
//   void initState() {
//     super.initState();
//
//     // Ajouter un listener pour détecter quand l'utilisateur atteint le bas de la liste
//     _scrollController.addListener(_scrollListener);
//   }
//
//   @override
//   void dispose() {
//     _scrollController.removeListener(_scrollListener);
//     _scrollController.dispose();
//     super.dispose();
//   }
//
//   // Méthode pour définir la liste complète des commandes
//   void setFullCommandesList(List<Commande> commandes) {
//     setState(() {
//       _fullCommandesList = commandes;
//       _updatePaginatedList();
//     });
//   }
//
//   // Listener de défilement pour détecter quand charger plus de commandes
//   void _scrollListener() {
//     // Si on est au bas de la liste et qu'on n'est pas en train de charger
//     if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
//         !_isLoadingMore &&
//         !_hasReachedEnd) {
//       _loadMoreItems();
//     }
//   }
//
//   // Charger plus d'éléments
//   Future<void> _loadMoreItems() async {
//     if (_isLoadingMore || _hasReachedEnd) return;
//
//     setState(() {
//       _isLoadingMore = true;
//     });
//
//     // Simuler un chargement réseau
//     await Future.delayed(const Duration(milliseconds: 500));
//
//     setState(() {
//       _currentPage++;
//       _updatePaginatedList();
//       _isLoadingMore = false;
//     });
//   }
//
//   // Rafraîchir la liste (pour les cas où l'utilisateur tire vers le bas)
//   Future<void> refreshList() async {
//     setState(() {
//       _currentPage = 1;
//       _itemsPerPage = PaginationService.kInitialItemsPerPage;
//       _hasReachedEnd = false;
//     });
//
//     // Appliquer la pagination à nouveau
//     _updatePaginatedList();
//   }
//
//   // Mettre à jour la liste paginée
//   void _updatePaginatedList() {
//     final paginatedList = PaginationService.paginerCommandes(
//       commandes: _fullCommandesList,
//       page: _currentPage,
//       itemsPerPage: _itemsPerPage,
//     );
//
//     // Vérifier si on a atteint la fin des commandes
//     if (paginatedList.length == _fullCommandesList.length) {
//       _hasReachedEnd = true;
//     }
//
//     setState(() {
//       _paginatedCommandes = paginatedList;
//     });
//   }
//
//   // Getter pour la liste paginée des commandes
//   List<Commande> get paginatedCommandes => _paginatedCommandes;
//
//   // Getter pour le contrôleur de défilement
//   ScrollController get scrollController => _scrollController;
//
//   // Getter pour savoir si on charge plus d'éléments
//   bool get isLoadingMore => _isLoadingMore;
// }