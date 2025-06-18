/// *************************************************************************************************
///
/// BANNER : EXPLICATION GÉNÉRALE DE LA CLASSE API
///
/// Ce fichier définit la classe `PromotionApi`.
///
/// Objectif :
/// Cette classe sert de couche de service pour interagir avec l'API backend
/// (https://www.hairbnb.site) spécifiquement pour les fonctionnalités liées aux services
/// d'une coiffeuse et à la suppression de promotions. Elle encapsule la logique des
/// appels HTTP (GET, DELETE) pour simplifier leur utilisation depuis d'autres parties
/// de l'application.
///
/// Méthodes :
/// - `getServicesByCoiffeuse`: Récupère la liste de tous les services proposés par une
/// coiffeuse spécifique.
/// - `deletePromotion`: Supprime une promotion existante en utilisant son identifiant.
///
/// Utilisation :
/// La classe ne contient que des méthodes statiques, ce qui signifie qu'il n'est pas
/// nécessaire de créer une instance de `PromotionApi`. Les méthodes peuvent être
/// appelées directement, par exemple : `PromotionApi.deletePromotion(123);`.
///
///*************************************************************************************************
library;

import 'dart:convert';
import 'package:http/http.dart' as http;

/// Classe de service pour les appels API liés aux services et promotions.
class PromotionApi {
  /// L'URL de base pour toutes les requêtes de cette API.
  static const String baseUrl = 'https://www.hairbnb.site/api';

  /// Récupère la liste complète des services pour une coiffeuse donnée.
  ///
  /// [coiffeuseId] : L'identifiant unique de la coiffeuse dont on veut récupérer les services.
  ///
  /// Retourne une `Future` contenant une Map. La structure de la Map est :
  /// - En cas de succès : `{'data': [liste des services], 'error': null}`
  /// - En cas d'erreur : `{'data': null, 'error': 'Message d'erreur'}`
  static Future<Map<String, dynamic>> getServicesByCoiffeuse(String coiffeuseId) async {
    try {
      // Construit l'URL de la requête GET, en incluant la pagination pour récupérer jusqu'à 100 services.
      final response = await http.get(
        Uri.parse('$baseUrl/get_services_by_coiffeuse/$coiffeuseId/?page=1&page_size=100'),
      );

      // Vérifie si la requête a réussi (code de statut 200).
      if (response.statusCode == 200) {
        // Décode le corps de la réponse en utilisant UTF-8 pour gérer correctement les caractères spéciaux.
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        // Retourne les données dans la structure de retour personnalisée.
        return {'data': decoded, 'error': null};
      } else {
        // En cas d'erreur du serveur, retourne une structure d'erreur avec le code de statut.
        return {'data': null, 'error': 'Erreur serveur: ${response.statusCode}'};
      }
    } catch (e) {
      // En cas d'exception (ex: erreur réseau), retourne une structure d'erreur.
      return {'data': null, 'error': 'Erreur lors de l\'appel API: $e'};
    }
  }

  /// Supprime une promotion en utilisant son identifiant unique.
  ///
  /// [promotionId] : L'identifiant de la promotion à supprimer.
  ///
  /// Retourne une `Future<bool>` :
  /// - `true` si la suppression a réussi (le serveur a répondu avec 204 No Content ou 200 OK).
  /// - `false` en cas d'échec (erreur serveur, erreur réseau, etc.).
  static Future<bool> deletePromotion(int promotionId) async {
    try {
      // Effectue un appel DELETE à l'endpoint de suppression de la promotion.
      final response = await http.delete(
        Uri.parse('$baseUrl/delete_promotion/$promotionId/'),
      );

      // Le backend peut répondre avec 204 (sans contenu) ou 200 (avec un message),
      // les deux indiquent un succès.
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      // En cas d'exception (ex: pas de connexion), la suppression a échoué.
      return false;
    }
  }
}





// // 📁 lib/api/promotion_api.dart
//
// import 'dart:convert';
// import 'package:http/http.dart' as http;
//
// class PromotionApi {
//   static const String baseUrl = 'https://www.hairbnb.site/api';
//
//   // ✅ Récupérer tous les services avec promo
//   static Future<Map<String, dynamic>> getServicesByCoiffeuse(
//       String coiffeuseId) async {
//     try {
//       final response = await http.get(
//         Uri.parse(
//             '$baseUrl/get_services_by_coiffeuse/$coiffeuseId/?page=1&page_size=100'),
//       );
//
//       if (response.statusCode == 200) {
//         final decoded = json.decode(utf8.decode(response.bodyBytes));
//         return {'data': decoded, 'error': null};
//       } else {
//         return {
//           'data': null,
//           'error': 'Erreur serveur: ${response.statusCode}'
//         };
//       }
//     } catch (e) {
//       return {'data': null, 'error': 'Erreur lors de l\'appel API: $e'};
//     }
//   }
//
//   // ✅ Supprimer une promotion
//   static Future<bool> deletePromotion(int promotionId) async {
//     try {
//       final response = await http.delete(
//         Uri.parse('$baseUrl/delete_promotion/$promotionId/'),
//       );
//
//       return response.statusCode == 204 || response.statusCode == 200;
//     } catch (e) {
//       return false;
//     }
//   }
// }