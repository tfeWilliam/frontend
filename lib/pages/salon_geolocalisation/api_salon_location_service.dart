////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//          SERVICE (CLIENT API) POUR LA GÉOLOCALISATION DES SALONS             //
//                                                                            //
//  Ce fichier définit `ApiSalonService`, une classe qui centralise tous les  //
//  appels à l'API backend concernant la recherche et la récupération des     //
//  informations sur les salons en fonction de leur localisation              //
//  géographique.                                                             //
//                                                                            //
//  Elle fournit des méthodes statiques pour :                                //
//  - Récupérer les salons à proximité d'un point donné.                      //
//  - Obtenir les détails publics d'un salon spécifique.                      //
//  - Des méthodes de convenance pour extraire directement les listes de     //
//    salons depuis les réponses de l'API.                                    //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/salon_details_geo.dart';
import '../../services/firebase_token/token_service.dart';

/// Une classe de service avec des méthodes statiques pour interagir avec les
/// endpoints de l'API relatifs à la géolocalisation des salons.
class ApiSalonService {

  /// Récupère la réponse complète de l'API pour les salons à proximité.
  ///
  /// Effectue un appel authentifié à l'endpoint `/salons-proches-public/` en
  /// fournissant les coordonnées géographiques et une distance de recherche.
  ///
  /// [lat] : La latitude du point de recherche.
  /// [lon] : La longitude du point de recherche.
  /// [distance] : Le rayon de recherche en kilomètres.
  ///
  /// Retourne un `Future<SalonsResponse>` qui contient la liste des salons
  /// et d'autres métadonnées. Lève une `Exception` en cas d'erreur.
  static Future<SalonsResponse> fetchNearbySalons(double lat, double lon, double distance) async {
    final url = Uri.parse('https://www.hairbnb.site/api/salons-proches-public/?lat=$lat&lon=$lon&distance=$distance');

    try {
      // Récupère le token d'authentification pour sécuriser la requête.
      final token = await TokenService.getAuthToken();
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Si la requête réussit, désérialise la réponse JSON en un objet SalonsResponse.
        final responseData = json.decode(response.body);
        return SalonsResponse.fromJson(responseData);
      } else {
        // Gère les réponses d'erreur de l'API.
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      // Gère les erreurs de connexion ou autres exceptions.
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupère les détails publics d'un salon spécifique à partir de son ID.
  ///
  /// Effectue un appel public (non authentifié) à l'API.
  ///
  /// [salonId] : L'identifiant du salon à récupérer.
  ///
  /// Retourne un `Future<SalonDetailsForGeo>`. Lève une `Exception` en cas d'erreur.
  static Future<SalonDetailsForGeo> fetchSalonDetails(int salonId) async {
    final url = Uri.parse('https://www.hairbnb.site/api/salon-public/$salonId/');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        // Transforme la sous-partie 'salon' du JSON en un objet SalonDetailsForGeo.
        return SalonDetailsForGeo.fromJson(responseData['salon']);
      } else {
        throw Exception('Erreur de chargement des détails du salon: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion au serveur: $e');
    }
  }

  /// Méthode de convenance pour récupérer directement la liste de `SalonDetailsForGeo`
  /// des salons à proximité, sans les métadonnées de la réponse complète.
  ///
  /// Elle appelle `fetchNearbySalons` et extrait uniquement la liste des salons.
  static Future<List<SalonDetailsForGeo>> fetchNearbySalonsList(double lat, double lon, double distance) async {
    final salonsResponse = await fetchNearbySalons(lat, lon, distance);

    if (salonsResponse.isSuccess) {
      return salonsResponse.salons;
    } else {
      throw Exception('Échec de récupération des salons');
    }
  }

  /// Méthode de convenance pour récupérer la liste des salons à proximité, déjà triée par distance.
  ///
  /// Elle appelle `fetchNearbySalons` et extrait la liste `salonsTries` de la réponse.
  static Future<List<SalonDetailsForGeo>> fetchNearbySalonsSorted(double lat, double lon, double distance) async {
    final salonsResponse = await fetchNearbySalons(lat, lon, distance);

    if (salonsResponse.isSuccess) {
      return salonsResponse.salonsTries;
    } else {
      throw Exception('Échec de récupération des salons');
    }
  }
}





// // lib/services/api_salon_location_service.dart
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../models/salon_details_geo.dart';
// import '../../services/firebase_token/token_service.dart'; // Import du nouveau modèle
//
// class ApiSalonService {
//   // Utilise maintenant SalonsResponse et SalonDetailsForGeo
//
//   // Dans ton ApiSalonService
//   static Future<SalonsResponse> fetchNearbySalons(double lat, double lon, double distance) async {
//     final url = Uri.parse('https://www.hairbnb.site/api/salons-proches-public/?lat=$lat&lon=$lon&distance=$distance');
//
//     try {
//       final token = await TokenService.getAuthToken();
//       final response = await http.get(
//         url,
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//       );
//
//       if (response.statusCode == 200) {
//         final responseData = json.decode(response.body);
//         return SalonsResponse.fromJson(responseData);
//       } else {
//         throw Exception('Erreur ${response.statusCode}: ${response.body}');
//       }
//     } catch (e) {
//       print('Erreur détaillée: $e');
//       throw Exception('Erreur de connexion: $e');
//     }
//   }
//
//   // Retourne maintenant un seul modèle SalonDetailsForGeo
//   static Future<SalonDetailsForGeo> fetchSalonDetails(int salonId) async {
//     final url = Uri.parse('https://www.hairbnb.site/api/salon-public/$salonId/');
//
//     try {
//
//       final response = await http.get(url);
//
//       if (response.statusCode == 200) {
//         final responseData = json.decode(response.body);
//         // On transforme le JSON du salon en un objet SalonDetailsForGeo
//         return SalonDetailsForGeo.fromJson(responseData['salon']);
//       } else {
//         throw Exception('Erreur de chargement des détails du salon: ${response.statusCode}');
//       }
//     } catch (e) {
//       throw Exception('Erreur de connexion au serveur: $e');
//     }
//   }
//
//   // Méthode helper pour récupérer seulement la liste des salons
//   static Future<List<SalonDetailsForGeo>> fetchNearbySalonsList(double lat, double lon, double distance) async {
//     final salonsResponse = await fetchNearbySalons(lat, lon, distance);
//
//     if (salonsResponse.isSuccess) {
//       return salonsResponse.salons;
//     } else {
//       throw Exception('Échec de récupération des salons');
//     }
//   }
//
//   // Méthode pour récupérer les salons triés par distance
//   static Future<List<SalonDetailsForGeo>> fetchNearbySalonsSorted(double lat, double lon, double distance) async {
//     final salonsResponse = await fetchNearbySalons(lat, lon, distance);
//
//     if (salonsResponse.isSuccess) {
//       return salonsResponse.salonsTries;
//     } else {
//       throw Exception('Échec de récupération des salons');
//     }
//   }
//
// }