/// **************************************************************************************
///
/// SERVICE API : GESTION DES COIFFEUSES
///
/// OBJECTIF :
/// Ce fichier définit une classe de service statique, `ApiService`, qui sert
/// d'interface pour communiquer avec l'API backend. Son rôle est de centraliser
/// la logique des appels réseau liés aux coiffeuses.
///
/// CONCEPTION :
/// La classe utilise une méthode statique, ce qui signifie qu'elle n'a pas besoin
/// d'être instanciée pour être utilisée. Elle agit comme une collection de fonctions
/// utilitaires pour interagir avec les points de terminaison (endpoints) de l'API.
///
///***************************************************************************************
library;
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Classe de service statique pour interagir avec les points de terminaison de l'API.
class ApiService {
  /// Récupère une liste de coiffeuses à proximité d'un point géographique donné.
  ///
  /// [lat] : La latitude du point central de la recherche.
  /// [lon] : La longitude du point central de la recherche.
  /// [distance] : Le rayon de recherche (généralement en kilomètres).
  ///
  /// Retourne un `Future<List<dynamic>>`. Chaque élément de la liste est une map
  /// représentant les données brutes d'une coiffeuse, prête à être parsée par un modèle.
  /// Lance une [Exception] si la requête échoue ou si une erreur de connexion se produit.
  static Future<List<dynamic>> fetchNearbyCoiffeuses(double lat, double lon, double distance) async {
    // Construit l'URL avec les paramètres de géolocalisation.
    final url = Uri.parse('https://www.hairbnb.site/api/coiffeuses_proches/?lat=$lat&lon=$lon&distance=$distance');

    try {
      // Exécute la requête GET vers l'API.
      final response = await http.get(url);

      // Si la requête a réussi (statut 200 OK).
      if (response.statusCode == 200) {
        // Décode la réponse JSON.
        final responseData = json.decode(response.body);
        // Extrait et retourne la liste brute des coiffeuses.
        return responseData['coiffeuses'];
      } else {
        // Lance une exception si le serveur retourne un code d'erreur.
        throw Exception('Erreur de chargement des coiffeuses');
      }
    } catch (e) {
      // Attrape les erreurs de connexion (ex: pas d'internet) et relance une exception.
      throw Exception('Erreur de connexion au serveur');
    }
  }
}






// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// class ApiService {
//   static Future<List<dynamic>> fetchNearbyCoiffeuses(double lat, double lon, double distance) async {
//     final url = Uri.parse('https://www.hairbnb.site/api/coiffeuses_proches/?lat=$lat&lon=$lon&distance=$distance');
//
//     try {
//       final response = await http.get(url);
//       if (response.statusCode == 200) {
//         final responseData = json.decode(response.body);
//         return responseData['coiffeuses'];
//       } else {
//         throw Exception('Erreur de chargement des coiffeuses');
//       }
//     } catch (e) {
//       throw Exception('Erreur de connexion au serveur');
//     }
//   }
// }
