/// **************************************************************************************
///
/// SERVICE DE GÉOCODAGE : GEOAPIFY
///
/// OBJECTIF :
/// Ce fichier définit une classe de service statique, `GeocodingService`, dont le rôle
/// est de fournir des fonctionnalités de géocodage. Elle permet de convertir des
/// adresses textuelles (ici, des noms de ville) en coordonnées géographiques
/// (latitude et longitude) en utilisant l'API externe Geoapify.
///
/// CONCEPTION :
/// La classe est entièrement statique, ce qui signifie qu'elle n'a pas besoin d'être
/// instanciée. Elle agit comme une collection de fonctions utilitaires, encapsulant
/// la logique d'appel à l'API et la gestion des erreurs.
///
///***************************************************************************************
library;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// Classe de service statique pour les opérations de géocodage via l'API Geoapify.
class GeocodingService {
  /// Clé d'API privée pour l'accès au service Geoapify.
  static const String _apiKey = 'b097f188b11f46d2a02eb55021d168c1';

  /// Convertit un nom de ville en coordonnées géographiques (latitude et longitude).
  ///
  /// [city] : Le nom de la ville à géocoder.
  ///
  /// Retourne un `Future<Position?>`. L'objet `Position` (du package geolocator)
  /// contient les coordonnées si la conversion réussit.
  /// Retourne `null` en cas d'erreur (ex: erreur réseau) ou si la ville n'est pas trouvée.
  static Future<Position?> getCoordinatesFromCity(String city) async {
    try {
      // Construit l'URL pour l'appel à l'API de géocodage de Geoapify.
      final url = Uri.parse(
          'https://api.geoapify.com/v1/geocode/search?text=$city&apiKey=$_apiKey');

      // Exécute la requête GET vers l'API.
      final response = await http.get(url);

      // Si la requête a abouti avec succès.
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List<dynamic>;

        // Vérifie si l'API a retourné au moins un résultat.
        if (features.isNotEmpty) {
          // Extrait les coordonnées (longitude, latitude) de la première correspondance trouvée.
          final geometry = features[0]['geometry'];
          final lon = geometry['coordinates'][0];
          final lat = geometry['coordinates'][1];

          // Construit et retourne un objet Position avec les coordonnées obtenues.
          // Les autres champs sont remplis avec des valeurs par défaut car non fournis par l'API.
          return Position(
            latitude: lat,
            longitude: lon,
            timestamp: DateTime.now(),
            accuracy: 1.0,
            altitude: 0.0,
            altitudeAccuracy: 1.0,
            heading: 0.0,
            headingAccuracy: 1.0,
            speed: 0.0,
            speedAccuracy: 1.0,
          );
        }
      }
    } catch (e) {
      // En cas d'erreur (réseau, parsing, etc.), la fonction ne fait rien et
      // retournera `null` à la fin.
    }
    // Retourne null si le processus a échoué à une étape quelconque.
    return null;
  }
}








// import 'dart:convert';
// import 'package:geolocator/geolocator.dart';
// import 'package:http/http.dart' as http;
//
// class GeocodingService {
//   static const String _apiKey = 'b097f188b11f46d2a02eb55021d168c1';
//
//   static Future<Position?> getCoordinatesFromCity(String city) async {
//     try {
//       final url = Uri.parse(
//           'https://api.geoapify.com/v1/geocode/search?text=$city&apiKey=$_apiKey');
//
//       final response = await http.get(url);
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         final features = data['features'] as List<dynamic>;
//         if (features.isNotEmpty) {
//           final geometry = features[0]['geometry'];
//           final lon = geometry['coordinates'][0];
//           final lat = geometry['coordinates'][1];
//
//           return Position(
//             latitude: lat,
//             longitude: lon,
//             timestamp: DateTime.now(),
//             accuracy: 1.0,
//             altitude: 0.0,
//             altitudeAccuracy: 1.0,
//             heading: 0.0,
//             headingAccuracy: 1.0,
//             speed: 0.0,
//             speedAccuracy: 1.0,
//           );
//         }
//       }
//     } catch (e) {
//       print("❌ Erreur geocoding (Geoapify) : $e");
//     }
//     return null;
//   }
// }
