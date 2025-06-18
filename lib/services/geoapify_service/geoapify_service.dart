/// *************************************************************************************************
/// *
/// BANNIÈRE : SERVICE D'INTERFACE AVEC L'API GEOAPIFY                                                *
/// ----------------------------------------------------                                            *
/// *
/// OBJECTIF :                                                                                      *
/// Ce fichier définit la classe `GeoapifyService`, qui sert de client pour l'API Geoapify.         *
/// Elle fournit des méthodes statiques pour interagir avec deux services principaux de Geoapify :  *
/// *
/// 1. CALCUL D'ITINÉRAIRES (ROUTING) :                                                             *
/// La méthode `getRoute` calcule un itinéraire entre un point de départ et un point d'arrivée    *
/// pour un mode de transport donné (voiture, marche, vélo, etc.). Elle retourne une polyligne     *
/// (liste de coordonnées géographiques), la distance et la durée estimée du trajet.              *
/// *
/// 2. RECHERCHE DE LIEUX (PLACES) :                                                                *
/// La méthode `findNearbyParking` recherche des points d'intérêt (POI) spécifiques, ici des      *
/// parkings, dans un rayon défini autour d'un point géographique. Elle retourne une liste de      *
/// parkings avec leur nom et leurs coordonnées.                                                  *
/// *
/// La classe gère la construction des URLs, les appels HTTP, l'analyse des réponses JSON et la     *
/// gestion des erreurs potentielles.                                                               *
/// *
///*************************************************************************************************
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../pages/salon_geolocalisation/enum/enum.dart';

class GeoapifyService {
  // Clé d'API nécessaire pour authentifier les requêtes auprès de Geoapify.
  static const String apiKey = 'b097f188b11f46d2a02eb55021d168c1';
  // URL de base pour tous les points de terminaison de l'API Geoapify.
  static const String baseUrl = 'https://api.geoapify.com/v1';

  /// Calcule un itinéraire entre deux points pour un mode de transport spécifique.
  ///
  /// [start] : Coordonnées du point de départ.
  /// [end] : Coordonnées du point d'arrivée.
  /// [mode] : Le mode de transport (voiture, marche, etc.) à utiliser pour le calcul.
  /// Retourne un objet `RouteResult` contenant les détails de l'itinéraire, ou `null` en cas d'erreur.
  static Future<RouteResult?> getRoute({
    required LatLng start,
    required LatLng end,
    required TransportMode mode,
  }) async {
    try {
      // Convertit l'énumération `TransportMode` en une chaîne de caractères compatible avec l'API.
      String modeStr;
      switch (mode) {
        case TransportMode.drive:
          modeStr = 'drive';
          break;
        case TransportMode.walk:
          modeStr = 'walk';
          break;
        case TransportMode.bicycle:
          modeStr = 'bicycle';
          break;
        case TransportMode.transit:
          modeStr = 'transit';
          break;
      }

      // Construit l'URL complète pour la requête de calcul d'itinéraire.
      final url = '$baseUrl/routing?waypoints=${start.latitude},${start.longitude}|${end.latitude},${end.longitude}&mode=$modeStr&apiKey=$apiKey';

      // Effectue l'appel HTTP GET à l'API.
      final response = await http.get(Uri.parse(url));

      // Vérifie si la requête a abouti (statut 200 OK).
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // S'assure que la réponse contient des données d'itinéraire (`features`).
        if (data['features'] != null && data['features'].isNotEmpty) {
          final feature = data['features'][0];
          final geometry = feature['geometry'];
          final properties = feature['properties'];

          List<LatLng> points = [];
          // Analyse la géométrie de l'itinéraire pour extraire la liste des points.
          if (geometry['coordinates'] != null) {
            _parseCoordinates(geometry['coordinates'], points);
          }

          // Retourne le résultat formaté avec les points, la distance et la durée.
          return RouteResult(
            points: points,
            distance: properties['distance']?.toDouble() ?? 0.0,
            duration: properties['time']?.toInt() ?? 0,
          );
        }
      }
    } catch (e) {
      // En cas d'exception, affiche l'erreur dans la console.
      if (kDebugMode) {
        print('Erreur Geoapify routing: $e');
      }
    }

    // Retourne `null` si une erreur survient ou si aucun itinéraire n'est trouvé.
    return null;
  }

  /// Fonction utilitaire pour analyser récursivement les coordonnées de la géométrie de l'itinéraire.
  /// Gère les formats de géométrie simples (LineString) et multiples (MultiLineString).
  static void _parseCoordinates(dynamic coords, List<LatLng> points) {
    if (coords is List && coords.isNotEmpty) {
      // Vérifie si les coordonnées sont imbriquées (liste de listes).
      if (coords[0] is List) {
        // Gère les géométries de type MultiLineString, qui ont un niveau d'imbrication supplémentaire.
        if (coords[0][0] is List) {
          for (var subList in coords) {
            _parseCoordinates(subList, points);
          }
        } else { // Gère les géométries de type LineString.
          for (var coord in coords) {
            if (coord is List && coord.length >= 2) {
              // Ajoute le point LatLng à la liste (longitude, latitude -> latitude, longitude).
              points.add(LatLng(coord[1].toDouble(), coord[0].toDouble()));
            }
          }
        }
      }
    }
  }

  /// Recherche les parkings à proximité d'un point géographique donné.
  ///
  /// [location] : Les coordonnées autour desquelles effectuer la recherche.
  /// Retourne une liste d'objets `POI` (Point Of Interest) représentant les parkings, ou une liste vide en cas d'erreur.
  static Future<List<POI>> findNearbyParking(LatLng location) async {
    try {
      // Construit l'URL pour rechercher des parkings dans un rayon de 1000 mètres, avec une limite de 10 résultats.
      final url = '$baseUrl/places?categories=parking&filter=circle:${location.longitude},${location.latitude},1000&limit=10&apiKey=$apiKey';

      // Effectue l'appel HTTP GET.
      final response = await http.get(Uri.parse(url));

      // Vérifie si la requête a abouti.
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<POI> parkings = [];

        // Itère sur chaque lieu trouvé dans la réponse.
        if (data['features'] != null) {
          for (var feature in data['features']) {
            final geometry = feature['geometry'];
            final properties = feature['properties'];

            // Crée un objet POI pour chaque parking avec ses coordonnées et son nom.
            if (geometry['coordinates'] != null) {
              parkings.add(POI(
                location: LatLng(
                  geometry['coordinates'][1],
                  geometry['coordinates'][0],
                ),
                name: properties['name'] ?? 'Parking',
                type: 'parking',
              ));
            }
          }
        }

        return parkings;
      }
    } catch (e) {
      // En cas d'exception, affiche l'erreur dans la console.
      if (kDebugMode) {
        print('Erreur Geoapify parking: $e');
      }
    }

    // Retourne une liste vide si une erreur survient ou si aucun parking n'est trouvé.
    return [];
  }
}






// // ✅ SERVICE GEOAPIFY SIMPLIFIÉ
// import 'dart:convert';
//
// import 'package:http/http.dart' as http;
// import 'package:latlong2/latlong.dart';
//
// import '../../pages/salon_geolocalisation/enum/enum.dart';
//
// class GeoapifyService {
//   static const String apiKey = 'b097f188b11f46d2a02eb55021d168c1';
//   static const String baseUrl = 'https://api.geoapify.com/v1';
//
//   static Future<RouteResult?> getRoute({
//     required LatLng start,
//     required LatLng end,
//     required TransportMode mode,
//   }) async {
//     try {
//       String modeStr;
//       switch (mode) {
//         case TransportMode.drive:
//           modeStr = 'drive';
//           break;
//         case TransportMode.walk:
//           modeStr = 'walk';
//           break;
//         case TransportMode.bicycle:
//           modeStr = 'bicycle';
//           break;
//         case TransportMode.transit:
//           modeStr = 'transit';
//           break;
//       }
//
//       final url = '$baseUrl/routing?waypoints=${start.latitude},${start.longitude}|${end.latitude},${end.longitude}&mode=$modeStr&apiKey=$apiKey';
//
//       final response = await http.get(Uri.parse(url));
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//
//         if (data['features'] != null && data['features'].isNotEmpty) {
//           final feature = data['features'][0];
//           final geometry = feature['geometry'];
//           final properties = feature['properties'];
//
//           List<LatLng> points = [];
//           if (geometry['coordinates'] != null) {
//             // Updated logic to handle different geometry types (e.g., LineString, MultiLineString)
//             _parseCoordinates(geometry['coordinates'], points);
//           }
//
//           return RouteResult(
//             points: points,
//             distance: properties['distance']?.toDouble() ?? 0.0,
//             duration: properties['time']?.toInt() ?? 0,
//           );
//         }
//       }
//     } catch (e) {
//       print('❌ Erreur Geoapify routing: $e');
//     }
//
//     return null;
//   }
//
//   // Helper function to recursively parse coordinates
//   static void _parseCoordinates(dynamic coords, List<LatLng> points) {
//     if (coords is List && coords.isNotEmpty) {
//       // Check if the first element is a list (nested coordinates)
//       if (coords[0] is List) {
//         // If it's a list of lists, recurse
//         if (coords[0][0] is List) { // Likely a MultiLineString [[[]]]
//           for (var subList in coords) {
//             _parseCoordinates(subList, points);
//           }
//         } else { // Likely a LineString [[]]
//           for (var coord in coords) {
//             if (coord is List && coord.length >= 2) {
//               points.add(LatLng(coord[1].toDouble(), coord[0].toDouble()));
//             }
//           }
//         }
//       }
//     }
//   }
//
//   static Future<List<POI>> findNearbyParking(LatLng location) async {
//     try {
//       final url = '$baseUrl/places?categories=parking&filter=circle:${location.longitude},${location.latitude},1000&limit=10&apiKey=$apiKey';
//
//       final response = await http.get(Uri.parse(url));
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         List<POI> parkings = [];
//
//         if (data['features'] != null) {
//           for (var feature in data['features']) {
//             final geometry = feature['geometry'];
//             final properties = feature['properties'];
//
//             if (geometry['coordinates'] != null) {
//               parkings.add(POI(
//                 location: LatLng(
//                   geometry['coordinates'][1],
//                   geometry['coordinates'][0],
//                 ),
//                 name: properties['name'] ?? 'Parking',
//                 type: 'parking',
//               ));
//             }
//           }
//         }
//
//         return parkings;
//       }
//     } catch (e) {
//       print('❌ Erreur Geoapify parking: $e');
//     }
//
//     return [];
//   }
// }
