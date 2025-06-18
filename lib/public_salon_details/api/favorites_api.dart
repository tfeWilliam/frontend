////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//             SERVICE (CLIENT API) POUR LA GESTION DES FAVORIS                 //
//                                                                            //
//  Ce fichier définit `FavoritesApi`, une classe qui centralise tous les     //
//  appels à l'API backend pour les opérations liées aux favoris des          //
//  utilisateurs.                                                             //
//                                                                            //
//  Elle utilise des méthodes statiques pour permettre des appels directs et  //
//  s'appuie sur une autre classe de service (`APIService`) pour obtenir      //
//  l'URL de base et les en-têtes d'authentification, ce qui assure une bonne //
//  séparation des préoccupations.                                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../models/favorites.dart';
import '../../services/api_services/api_service.dart';

/// Une classe de service contenant des méthodes statiques pour interagir avec
/// les endpoints de l'API relatifs aux favoris.
class FavoritesApi {
  /// Récupère la liste de tous les favoris pour un utilisateur donné.
  ///
  /// [userId] : L'identifiant de l'utilisateur dont on veut récupérer les favoris.
  ///
  /// Retourne une `Future<List<FavoriteModel>>`.
  /// Lève une `Exception` en cas d'échec de la requête.
  static Future<List<FavoriteModel>> getUserFavorites(int userId) async {
    final response = await http.get(
      Uri.parse('${APIService.baseURL}/get_user_favorites/?user=$userId'),
      // Utilise les en-têtes fournis par `APIService`, qui incluent le token d'authentification.
      headers: await APIService.headers,
    );

    if (response.statusCode == 200) {
      // Si la requête réussit, décode le corps de la réponse et le transforme en une liste d'objets `FavoriteModel`.
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((json) => FavoriteModel.fromJson(json)).toList();
    } else {
      // Gère les réponses d'erreur de l'API.
      throw Exception('Échec de la récupération des favoris: ${response.body}');
    }
  }

  /// Ajoute un salon à la liste des favoris d'un utilisateur.
  ///
  /// [userId] : L'identifiant de l'utilisateur qui ajoute le favori.
  /// [salonId] : L'identifiant du salon à ajouter.
  ///
  /// Retourne un `Future<FavoriteModel>` représentant la nouvelle entrée de favori créée.
  /// Lève une `Exception` en cas d'échec.
  static Future<FavoriteModel> addToFavorites(int userId, int salonId) async {
    final response = await http.post(
      Uri.parse('${APIService.baseURL}/favorites/add/'),
      headers: await APIService.headers,
      body: jsonEncode({
        'user': userId,
        'salon': salonId,
      }),
    );

    // Un statut 201 (Created) ou 200 (OK) est considéré comme un succès.
    if (response.statusCode == 201 || response.statusCode == 200) {
      return FavoriteModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Échec de l\'ajout aux favoris: ${response.body}');
    }
  }

  /// Vérifie si un salon spécifique est déjà dans les favoris d'un utilisateur.
  ///
  /// [userId] : L'identifiant de l'utilisateur.
  /// [salonId] : L'identifiant du salon à vérifier.
  ///
  /// Retourne l'objet `FavoriteModel` si le favori existe (status 200),
  /// ou `null` si le favori n'existe pas (status 404) ou en cas d'autre erreur.
  static Future<FavoriteModel?> checkFavorite(int userId, int salonId) async {
    try {
      final response = await http.get(
        Uri.parse('${APIService.baseURL}/check_favorite/?user=$userId&salon=$salonId'),
        headers: await APIService.headers,
      );

      if (response.statusCode == 200) {
        // Le favori existe, on retourne l'objet désérialisé.
        final json = jsonDecode(response.body);
        return FavoriteModel.fromJson(json);
      } else if (response.statusCode == 404) {
        // Le favori n'existe pas.
        return null;
      } else {
        // Gère les autres erreurs sans lever d'exception, en retournant simplement null.
        if (kDebugMode) {
          print('Erreur check_favorite: ${response.statusCode} - ${response.body}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Exception dans checkFavorite: $e');
      }
      return null;
    }
  }

  /// Supprime une entrée de favori en utilisant son identifiant unique.
  ///
  /// [favoriteId] : L'identifiant de l'entrée `TblFavorite` à supprimer.
  ///
  /// Retourne `true` si la suppression a réussi (status 204 No Content).
  /// Lève une `Exception` en cas d'échec.
  static Future<bool> removeFavorite(int favoriteId) async {
    final response = await http.delete(
      Uri.parse('${APIService.baseURL}/favorites/remove/'),
      headers: await APIService.headers,
      body: jsonEncode({
        'id': favoriteId,
      }),
    );

    // 204 No Content est la réponse standard pour une suppression réussie.
    if (response.statusCode == 204) {
      return true;
    } else {
      throw Exception('Échec de la suppression du favori: ${response.statusCode} - ${response.body}');
    }
  }
}





// // api/favorites_api.dart
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:flutter/foundation.dart';
// import '../../models/favorites.dart';
// import '../../services/api_services/api_service.dart';
//
// class FavoritesApi {
//   // Récupère les favoris d'un utilisateur
//   static Future<List<FavoriteModel>> getUserFavorites(int userId) async {
//     final response = await http.get(
//       Uri.parse('${APIService.baseURL}/get_user_favorites/?user=$userId'),
//       headers: await APIService.headers, // 🎯 Token Firebase inclus automatiquement
//     );
//
//     if (response.statusCode == 200) {
//       final List<dynamic> jsonData = jsonDecode(response.body);
//       if (kDebugMode) {
//         print("Données reçues: ${jsonData.length} favoris");
//         if (jsonData.isNotEmpty) {
//           print("Premier favori: ${jsonData.first}");
//         }
//       }
//       return jsonData.map((json) => FavoriteModel.fromJson(json)).toList();
//     } else {
//       throw Exception('Échec de la récupération des favoris: ${response.body}');
//     }
//   }
//
//   // Ajoute un salon aux favoris
//   static Future<FavoriteModel> addToFavorites(int userId, int salonId) async {
//     final response = await http.post(
//       Uri.parse('${APIService.baseURL}/favorites/add/'),
//       headers: await APIService.headers, // 🎯 Auth Firebase automatique
//       body: jsonEncode({
//         'user': userId,
//         'salon': salonId,
//       }),
//     );
//
//     if (response.statusCode == 201 || response.statusCode == 200) {
//       return FavoriteModel.fromJson(jsonDecode(response.body));
//     } else {
//       throw Exception('Échec de l\'ajout aux favoris: ${response.body}');
//     }
//   }
//
//   // Vérifie si un salon est en favori pour un utilisateur
//   static Future<FavoriteModel?> checkFavorite(int userId, int salonId) async {
//     try {
//       final response = await http.get(
//         Uri.parse('${APIService.baseURL}/check_favorite/?user=$userId&salon=$salonId'),
//         headers: await APIService.headers, // 🎯 Headers automatiques avec auth
//       );
//
//       if (response.statusCode == 200) {
//         final json = jsonDecode(response.body);
//         return FavoriteModel.fromJson(json);
//       } else if (response.statusCode == 404) {
//         return null;
//       } else {
//         if (kDebugMode) {
//           print('Erreur check_favorite: ${response.statusCode} - ${response.body}');
//         }
//         return null;
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('Exception dans checkFavorite: $e');
//       }
//       return null;
//     }
//   }
//
//   // // Ajoute un salon aux favoris
//   // static Future<FavoriteModel> addToFavorites(int userId, int salonId) async {
//   //   final response = await http.post(
//   //     Uri.parse('${APIService.baseURL}/favorites/add/'),
//   //     headers: await APIService.headers, // 🎯 Token d'auth inclus automatiquement
//   //     body: jsonEncode({
//   //       'user': userId,
//   //       'salon': salonId,
//   //     }),
//   //   );
//   //
//   //   if (response.statusCode == 201 || response.statusCode == 200) {
//   //     return FavoriteModel.fromJson(jsonDecode(response.body));
//   //   } else {
//   //     throw Exception('Échec de l\'ajout aux favoris: ${response.body}');
//   //   }
//   // }
//
//   // Supprime un favori par son ID
//   static Future<bool> removeFavorite(int favoriteId) async {
//     final response = await http.delete(
//       Uri.parse('${APIService.baseURL}/favorites/remove/'),
//       headers: await APIService.headers, // 🎯 Auth + version app automatique
//       body: jsonEncode({
//         'id': favoriteId,
//       }),
//     );
//
//     if (response.statusCode == 204) {
//       return true;
//     } else {
//       throw Exception('Échec de la suppression du favori: ${response.statusCode} - ${response.body}');
//     }
//   }
// }
