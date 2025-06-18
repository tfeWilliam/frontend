////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//             CLASSE DE STOCKAGE EN MÉMOIRE POUR LES SERVICES                  //
//                                                                            //
//  Ce fichier définit `ServicesStorage`, une classe utilitaire qui fournit   //
//  un système de cache simple et non-persistent (en mémoire vive) pour       //
//  gérer des listes de services associées à des utilisateurs.                //
//                                                                            //
//  Son but est de conserver temporairement des données durant la session de  //
//  l'application pour éviter des appels réseau répétitifs. Les données sont  //
//  perdues lorsque l'application est redémarrée.                             //
//                                                                            //
//  La classe utilise des membres statiques, elle n'a donc pas besoin d'être  //
//  instanciée.                                                               //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;

import 'package:hairbnb/models/services.dart';

/// Une classe utilitaire fournissant un cache en mémoire pour les services.
class ServicesStorage {

  /// Le cache interne, privé et statique.
  /// C'est un `Map` où la clé est l'identifiant de l'utilisateur (`userId`)
  /// et la valeur est la liste de `Service` qui lui est associée.
  static final Map<int, List<Service>> _cache = {};

  /// Sauvegarde (ou écrase) une liste complète de services pour un utilisateur donné.
  ///
  /// [userId] : L'identifiant de l'utilisateur pour lequel les services sont sauvegardés.
  /// [services] : La liste des objets `Service` à stocker.
  static void sauvegarderServices(int userId, List<Service> services) {
    // Crée une nouvelle liste pour éviter les problèmes de référence.
    _cache[userId] = List.from(services);
  }

  /// Charge la liste des services sauvegardés pour un utilisateur donné.
  ///
  /// [userId] : L'identifiant de l'utilisateur dont on veut charger les services.
  ///
  /// Retourne une `List<Service>`. Retourne une liste vide si aucun service
  /// n'a été sauvegardé pour cet utilisateur.
  static List<Service> chargerServices(int userId) {
    // L'opérateur `??` fournit une liste vide comme valeur par défaut.
    final services = _cache[userId] ?? [];
    return List.from(services);
  }

  /// Ajoute un unique service à la liste d'un utilisateur, en évitant les doublons.
  ///
  /// Le service n'est ajouté que s'il n'existe pas déjà un service avec le même ID
  /// dans la liste de l'utilisateur.
  ///
  /// [userId] : L'identifiant de l'utilisateur.
  /// [service] : Le `Service` à ajouter.
  static void ajouterService(int userId, Service service) {
    // Si l'utilisateur n'a pas encore de liste, on en crée une.
    if (_cache[userId] == null) {
      _cache[userId] = [];
    }

    // Vérifie l'unicité de l'ID du service avant de l'ajouter.
    if (!_cache[userId]!.any((s) => s.id == service.id)) {
      _cache[userId]!.add(service);
    }
  }

  /// Supprime un service de la liste d'un utilisateur en se basant sur son ID.
  ///
  /// [userId] : L'identifiant de l'utilisateur.
  /// [serviceId] : L'ID du service à supprimer.
  static void supprimerService(int userId, int serviceId) {
    // Vérifie que la liste existe avant de tenter une suppression.
    if (_cache[userId] != null) {
      _cache[userId]!.removeWhere((s) => s.id == serviceId);
    }
  }

  /// Vide la liste des services pour un utilisateur spécifique.
  ///
  /// Cela ne supprime pas l'entrée de l'utilisateur du cache, mais
  /// la remplace par une liste vide.
  ///
  /// [userId] : L'identifiant de l'utilisateur dont le cache de services doit être vidé.
  static void viderServices(int userId) {
    _cache[userId] = [];
  }
}







// import 'package:hairbnb/models/services.dart';
//
// class ServicesStorage {
//
//   // Stockage en mémoire (simple Map)
//   static final Map<int, List<Service>> _cache = {};
//
//   /// Sauvegarder les services ajoutés pour un utilisateur
//   static void sauvegarderServices(int userId, List<Service> services) {
//     _cache[userId] = List.from(services);
//     print("💾 Services sauvegardés localement pour user $userId: ${services.length}");
//   }
//
//   /// Charger les services ajoutés pour un utilisateur
//   static List<Service> chargerServices(int userId) {
//     final services = _cache[userId] ?? [];
//     print("📖 Services chargés localement pour user $userId: ${services.length}");
//     return List.from(services);
//   }
//
//   /// Ajouter un service à la liste existante
//   static void ajouterService(int userId, Service service) {
//     if (_cache[userId] == null) {
//       _cache[userId] = [];
//     }
//
//     // Vérifier qu'il n'existe pas déjà
//     if (!_cache[userId]!.any((s) => s.id == service.id)) {
//       _cache[userId]!.add(service);
//       print("➕ Service ajouté localement: ${service.intitule}");
//     }
//   }
//
//   /// Supprimer un service de la liste
//   static void supprimerService(int userId, int serviceId) {
//     if (_cache[userId] != null) {
//       _cache[userId]!.removeWhere((s) => s.id == serviceId);
//       print("🗑️ Service supprimé localement: $serviceId");
//     }
//   }
//
//   /// Vider le cache pour un utilisateur
//   static void viderServices(int userId) {
//     _cache[userId] = [];
//     print("🧹 Cache vidé pour user $userId");
//   }
// }