/// *************************************************************************************************
///
/// BANNER : EXPLICATION GÉNÉRALE DE LA CLASSE DE SERVICE
///
/// Ce fichier définit la classe `FavoritesService`.
///
/// Objectif :
/// Cette classe sert de couche de logique métier (business logic) qui se place entre
/// l'interface utilisateur (UI) et la couche d'accès aux données (`FavoritesApi`).
/// Son rôle est d'orchestrer les opérations liées aux favoris, de gérer les flux
/// logiques complexes (comme le "toggle") et de fournir des méthodes simples à
/// utiliser pour le reste de l'application.
///
///*************************************************************************************************
library;

import 'package:flutter/foundation.dart';
import '../../models/favorites.dart';
import '../api/favorites_api.dart';

/// Classe de service qui gère la logique métier pour les favoris.
class FavoritesService {
  /// Récupère la liste complète des favoris pour un utilisateur donné.
  ///
  /// Délègue simplement l'appel à la couche API.
  /// [userId] : L'identifiant de l'utilisateur dont on veut les favoris.
  /// Retourne une `Future<List<FavoriteModel>>`.
  static Future<List<FavoriteModel>> getUserFavorites(int userId) async {
    return await FavoritesApi.getUserFavorites(userId);
  }

  /// Vérifie si un salon est dans les favoris d'un utilisateur et retourne
  /// l'objet `FavoriteModel` correspondant si c'est le cas.
  ///
  /// Cette méthode essaie d'abord un endpoint API optimisé pour la vérification.
  /// En cas d'échec ou si l'endpoint n'existe pas, elle se rabat sur la récupération
  /// de la liste complète pour une vérification manuelle.
  ///
  /// [userId] : L'identifiant de l'utilisateur.
  /// [salonId] : L'identifiant du salon à vérifier.
  /// Retourne un `FavoriteModel` si le salon est en favori, sinon `null`.
  static Future<FavoriteModel?> getFavoriteForSalon(int userId, int salonId) async {
    try {
      // Tente d'abord d'utiliser l'endpoint de vérification directe pour plus d'efficacité.
      final favorite = await FavoritesApi.checkFavorite(userId, salonId);
      if (favorite != null) {
        return favorite;
      }

      // Si la vérification directe échoue ou n'est pas implémentée,
      // on récupère la liste complète comme solution de repli.
      final favorites = await FavoritesApi.getUserFavorites(userId);
      for (var fav in favorites) {
        // Utilise une méthode `getSalonId` sur le modèle pour gérer les cas où
        // l'ID du salon pourrait être dans une structure imbriquée.
        if (fav.getSalonId() == salonId) {
          return fav;
        }
      }
      return null; // Le salon n'a pas été trouvé dans la liste.
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la vérification des favoris: $e');
      }
      // En cas d'erreur, on considère que le salon n'est pas en favori.
      return null;
    }
  }

  /// Vérifie si un salon est dans les favoris (méthode de convenance).
  ///
  /// [userId] : L'identifiant de l'utilisateur.
  /// [salonId] : L'identifiant du salon à vérifier.
  /// Retourne `true` si le salon est en favori, sinon `false`.
  static Future<bool> isSalonFavorite(int userId, int salonId) async {
    final favorite = await getFavoriteForSalon(userId, salonId);
    return favorite != null;
  }

  /// Ajoute un salon aux favoris de l'utilisateur.
  ///
  /// [userId] : L'identifiant de l'utilisateur.
  /// [salonId] : L'identifiant du salon à ajouter.
  /// Retourne le `FavoriteModel` nouvellement créé, ou `null` en cas d'erreur.
  static Future<FavoriteModel?> addToFavorites(int userId, int salonId) async {
    try {
      // Délègue l'appel d'ajout à la couche API.
      return await FavoritesApi.addToFavorites(userId, salonId);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de l\'ajout aux favoris: $e');
      }
      return null;
    }
  }

  /// Supprime un favori en utilisant son identifiant unique.
  ///
  /// [favoriteId] : L'ID de l'entrée "favori" (et non l'ID du salon).
  /// Retourne `true` si la suppression a réussi, sinon `false`.
  static Future<bool> removeFavorite(int favoriteId) async {
    try {
      // Délègue l'appel de suppression à la couche API.
      return await FavoritesApi.removeFavorite(favoriteId);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la suppression du favori: $e');
      }
      return false;
    }
  }

  /// Gère la logique de basculement d'un favori.
  /// Ajoute le salon aux favoris s'il n'y est pas, le supprime s'il y est.
  ///
  /// [userId] : L'identifiant de l'utilisateur.
  /// [salonId] : L'identifiant du salon.
  /// Retourne le nouvel état du favori (`true` si le salon est maintenant en favori, `false` sinon).
  static Future<bool> toggleFavorite(int userId, int salonId) async {
    try {
      // Récupère d'abord l'état actuel du favori.
      final favorite = await getFavoriteForSalon(userId, salonId);

      if (favorite != null) {
        // Si le favori existe, on le supprime.
        final success = await removeFavorite(favorite.idTblFavorite);
        // Si la suppression a réussi, le nouvel état est "non favori" (false).
        // Si elle échoue, on retourne l'ancien état (true), car il n'a pas changé.
        return !success;
      } else {
        // Si le favori n'existe pas, on l'ajoute.
        final newFavorite = await addToFavorites(userId, salonId);
        // Si l'ajout a réussi (newFavorite n'est pas null), le nouvel état est "favori" (true).
        return newFavorite != null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors du toggle favori: $e');
      }
      // En cas d'erreur, on retourne `false` par défaut.
      return false;
    }
  }
}





// // services/favorites_services.dart
// import 'package:flutter/foundation.dart';
// import '../../models/favorites.dart';
// import '../api/favorites_api.dart';
//
// class FavoritesService {
//   // Récupère tous les favoris d'un utilisateur
//   static Future<List<FavoriteModel>> getUserFavorites(int userId) async {
//     return await FavoritesApi.getUserFavorites(userId);
//   }
//
//   // Vérifie si un salon est dans les favoris de l'utilisateur et retourne l'objet favori
//   static Future<FavoriteModel?> getFavoriteForSalon(int userId, int salonId) async {
//     try {
//       // Essayer d'abord avec l'endpoint spécifique de vérification
//       final favorite = await FavoritesApi.checkFavorite(userId, salonId);
//       if (favorite != null) {
//         return favorite;
//       }
//
//       // Sinon, rechercher dans la liste complète
//       final favorites = await FavoritesApi.getUserFavorites(userId);
//       for (var fav in favorites) {
//         // Utiliser getSalonId pour gérer les différentes représentations possibles du salon
//         if (fav.getSalonId() == salonId) {
//           return fav;
//         }
//       }
//       return null; // Salon pas trouvé dans les favoris
//     } catch (e) {
//       if (kDebugMode) {
//         print('Erreur lors de la vérification des favoris: $e');
//       }
//       return null;
//     }
//   }
//
//   // Vérifie si un salon est dans les favoris (retourne true/false)
//   static Future<bool> isSalonFavorite(int userId, int salonId) async {
//     final favorite = await getFavoriteForSalon(userId, salonId);
//     return favorite != null;
//   }
//
//   // Ajoute un salon aux favoris
//   static Future<FavoriteModel?> addToFavorites(int userId, int salonId) async {
//     try {
//       return await FavoritesApi.addToFavorites(userId, salonId);
//     } catch (e) {
//       if (kDebugMode) {
//         print('Erreur lors de l\'ajout aux favoris: $e');
//       }
//       return null;
//     }
//   }
//
//   // Supprime un favori par son ID
//   static Future<bool> removeFavorite(int favoriteId) async {
//     try {
//       return await FavoritesApi.removeFavorite(favoriteId);
//     } catch (e) {
//       if (kDebugMode) {
//         print('Erreur lors de la suppression du favori: $e');
//       }
//       return false;
//     }
//   }
//
//   // Toggle favori - ajoute ou supprime selon l'état actuel
//   static Future<bool> toggleFavorite(int userId, int salonId) async {
//     try {
//       final favorite = await getFavoriteForSalon(userId, salonId);
//
//       if (favorite != null) {
//         // Le salon est déjà en favori, on le supprime
//         final success = await removeFavorite(favorite.idTblFavorite);
//         return !success; // Si suppression réussie, retourne false (plus en favori)
//       } else {
//         // Le salon n'est pas en favori, on l'ajoute
//         final newFavorite = await addToFavorites(userId, salonId);
//         return newFavorite != null; // Si ajout réussi, retourne true (maintenant en favori)
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('Erreur lors du toggle favori: $e');
//       }
//       return false;
//     }
//   }
// }
