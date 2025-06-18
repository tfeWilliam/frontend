/// *************************************************************************************************
///
/// BANNER : EXPLICATION GÉNÉRALE DE LA CLASSE DE SERVICE
///
/// Ce fichier définit la classe `FavoritesService`.
///
/// Objectif :
/// Cette classe centralise toute la communication avec l'API backend pour la gestion
/// des favoris des utilisateurs. Elle fournit un ensemble de méthodes statiques pour
/// récupérer, ajouter, supprimer et vérifier les salons favoris d'un utilisateur.
///
/// Utilisation :
/// En tant que classe de service avec des méthodes statiques, il n'est pas nécessaire
/// de l'instancier. Les méthodes sont appelées directement depuis la couche UI ou la
/// logique métier (par exemple, un Provider ou un BLoC).
///
/// Note sur l'Authentification :
/// Les méthodes actuelles n'incluent pas de token d'authentification dans les en-têtes
/// des requêtes. Dans une application de production, il serait essentiel d'ajouter
/// un mécanisme (ex: 'Authorization': 'Bearer <token>') pour sécuriser ces actions
/// et s'assurer qu'un utilisateur ne modifie que ses propres favoris.
///
///*************************************************************************************************
library;

import 'dart:convert';
import 'package:http/http.dart' as http;

/// Classe de service pour gérer les appels API liés aux favoris des utilisateurs.
class FavoritesService {
  /// L'URL de base pour toutes les requêtes de cette API.
  static const String baseUrl = 'https://www.hairbnb.site/api';

  /// Récupère la liste des salons favoris pour un utilisateur spécifique.
  ///
  /// [userId] : L'identifiant de l'utilisateur dont on veut les favoris.
  /// Retourne une `Future<List<dynamic>>` contenant la liste des favoris.
  /// Lève une exception si la requête échoue.
  static Future<List<dynamic>> getUserFavorites(int userId) async {
    // Construit l'URL pour requêter les favoris d'un utilisateur spécifique.
    final response = await http.get(
      Uri.parse('$baseUrl/favorites/?user=$userId'),
      headers: {'Content-Type': 'application/json'},
    );

    // Si la requête est un succès (code 200), on décode et retourne la liste.
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      // Si le serveur retourne une erreur, on lève une exception.
      throw Exception('Échec de la récupération des favoris: ${response.body}');
    }
  }

  /// Vérifie si un salon spécifique fait partie des favoris d'un utilisateur.
  ///
  /// [userId] : L'identifiant de l'utilisateur.
  /// [salonId] : L'identifiant du salon à vérifier.
  /// Retourne `true` si le salon est en favori, sinon `false`.
  static Future<bool> isSalonFavorite(int userId, int salonId) async {
    try {
      // Récupère d'abord la liste complète des favoris de l'utilisateur.
      final favorites = await getUserFavorites(userId);
      // Vérifie si l'un des objets favoris dans la liste correspond à l'ID du salon.
      return favorites.any((favorite) => favorite['salon'] == salonId);
    } catch (e) {
      // En cas d'erreur lors de la récupération (ex: réseau), on suppose par sécurité
      // que le salon n'est pas en favori pour éviter un état d'UI incorrect.
      return false;
    }
  }

  /// Ajoute un salon à la liste des favoris d'un utilisateur.
  ///
  /// [userId] : L'identifiant de l'utilisateur.
  /// [salonId] : L'identifiant du salon à ajouter.
  /// Lève une exception si l'ajout échoue.
  static Future<void> addToFavorites(int userId, int salonId) async {
    // Effectue une requête POST pour créer une nouvelle entrée de favori.
    final response = await http.post(
      Uri.parse('$baseUrl/favorites/add/'),
      headers: {'Content-Type': 'application/json'},
      // Le corps de la requête contient les IDs de l'utilisateur et du salon.
      body: jsonEncode({
        'user': userId,
        'salon': salonId,
      }),
    );

    // Une création réussie peut retourner 201 (Created) ou 200 (OK).
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Échec de l\'ajout aux favoris: ${response.body}');
    }
  }

  /// Supprime un salon de la liste des favoris d'un utilisateur.
  ///
  /// [userId] : L'identifiant de l'utilisateur.
  /// [salonId] : L'identifiant du salon à supprimer.
  /// Lève une exception si la suppression échoue.
  static Future<void> removeFromFavorites(int userId, int salonId) async {
    // Effectue une requête DELETE sur l'endpoint de suppression.
    // Note: L'API semble attendre les IDs dans le corps, ce qui est inhabituel pour un DELETE.
    // Idéalement, les IDs seraient dans l'URL.
    final response = await http.delete(
      Uri.parse('$baseUrl/favorites/remove/$salonId/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user': userId,
        'salon': salonId,
      }),
    );

    // Une suppression réussie retourne généralement un code 204 (No Content).
    if (response.statusCode != 204) {
      throw Exception('Échec de la suppression des favoris: ${response.body}');
    }
  }

  /// Bascule l'état de favori d'un salon (ajoute s'il n'y est pas, supprime s'il y est).
  ///
  /// [userId] : L'identifiant de l'utilisateur.
  /// [salonId] : L'identifiant du salon à basculer.
  /// Retourne un `bool` indiquant le nouvel état du favori :
  /// - `true` si le salon est maintenant en favori.
  /// - `false` si le salon n'est plus en favori.
  static Future<bool> toggleFavorite(int userId, int salonId) async {
    // Vérifie d'abord l'état actuel du favori.
    final isFavorite = await isSalonFavorite(userId, salonId);

    // En fonction de l'état, appelle la méthode appropriée (suppression ou ajout).
    if (isFavorite) {
      await removeFromFavorites(userId, salonId);
      return false; // Le nouvel état est "non favori".
    } else {
      await addToFavorites(userId, salonId);
      return true; // Le nouvel état est "favori".
    }
  }
}





// import 'dart:convert';
// import 'package:http/http.dart' as http;
//
// class FavoritesService {
//   static const String baseUrl = 'https://www.hairbnb.site/api';
//
//   // Récupère les favoris d'un utilisateur
//   static Future<List<dynamic>> getUserFavorites(int userId) async {
//     final response = await http.get(
//       Uri.parse('$baseUrl/favorites/?user=$userId'),
//       headers: {'Content-Type': 'application/json'},
//     );
//
//     if (response.statusCode == 200) {
//       return jsonDecode(response.body);
//     } else {
//       throw Exception('Échec de la récupération des favoris: ${response.body}');
//     }
//   }
//
//   // Vérifie si un salon est dans les favoris de l'utilisateur
//   static Future<bool> isSalonFavorite(int userId, int salonId) async {
//     try {
//       final favorites = await getUserFavorites(userId);
//       return favorites.any((favorite) => favorite['salon'] == salonId);
//     } catch (e) {
//       // En cas d'erreur, on considère que le salon n'est pas en favori
//       return false;
//     }
//   }
//
//   // Ajoute un salon aux favoris
//   static Future<void> addToFavorites(int userId, int salonId) async {
//     final response = await http.post(
//       Uri.parse('$baseUrl/favorites/add/'),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({
//         'user': userId,
//         'salon': salonId,
//       }),
//     );
//
//     if (response.statusCode != 201 && response.statusCode != 200) {
//       throw Exception('Échec de l\'ajout aux favoris: ${response.body}');
//     }
//   }
//
//   // Supprime un salon des favoris
//   static Future<void> removeFromFavorites(int userId, int salonId) async {
//     final response = await http.delete(
//       Uri.parse('$baseUrl/favorites/remove/$salonId/'),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({
//         'user': userId,
//         'salon': salonId,
//       }),
//     );
//
//     if (response.statusCode != 204) {
//       throw Exception('Échec de la suppression des favoris: ${response.body}');
//     }
//   }
//
//   // Toggle favori - ajoute ou supprime selon l'état actuel
//   static Future<bool> toggleFavorite(int userId, int salonId) async {
//     final isFavorite = await isSalonFavorite(userId, salonId);
//
//     if (isFavorite) {
//       await removeFromFavorites(userId, salonId);
//       return false; // Le salon n'est plus un favori
//     } else {
//       await addToFavorites(userId, salonId);
//       return true; // Le salon est maintenant un favori
//     }
//   }
// }