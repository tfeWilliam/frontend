/// **************************************************************************************
///
/// SERVICE API : GESTION DES COIFFEUSES
///
/// OBJECTIF :
/// Cette classe définit un service statique qui centralise la communication avec
/// l'API backend pour récupérer des informations sur les coiffeuses.
///
/// CONCEPTION :
/// La classe utilise uniquement des méthodes statiques, ce qui signifie qu'elle n'a pas
/// besoin d'être instanciée pour être utilisée. Elle agit comme une collection de
/// fonctions utilitaires pour interagir avec les points de terminaison (endpoints)
/// spécifiques aux coiffeuses.
///
///***************************************************************************************
library;
import 'dart:convert';
import 'package:hairbnb/models/minimal_coiffeuse.dart';
import 'package:http/http.dart' as http;

/// Classe de service statique pour interagir avec les points de terminaison de l'API liés aux coiffeuses.
class CoiffeuseService {
  /// L'URL de base du serveur backend.
  static const String baseUrl = "https://www.hairbnb.site";

  /// Récupère les informations minimales pour une liste de coiffeuses via leurs UUIDs.
  ///
  /// Cette méthode utilise une requête POST pour envoyer une liste d'identifiants au serveur,
  /// ce qui est une approche efficace pour récupérer plusieurs enregistrements en une seule fois.
  ///
  /// [uuids] : Une liste de `String` représentant les UUIDs des coiffeuses à récupérer.
  /// Retourne un `Future<List<MinimalCoiffeuse>>` contenant les informations des coiffeuses.
  /// Lance une [Exception] si la requête échoue ou si l'API retourne un statut d'erreur.
  static Future<List<MinimalCoiffeuse>> fetchCoiffeuses(List<String> uuids) async {
    final url = Uri.parse('$baseUrl/api/get_coiffeuses_info/');

    try {
      // Envoie une requête POST avec la liste des UUIDs dans le corps de la requête.
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"uuids": uuids}),
      );

      // Si la requête HTTP a abouti avec succès.
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Vérifie le statut applicatif dans la réponse JSON.
        if (data['status'] == "success") {
          // Convertit chaque objet JSON de la liste en un objet Dart [MinimalCoiffeuse].
          return (data['coiffeuses'] as List)
              .map((json) => MinimalCoiffeuse.fromJson(json))
              .toList();
        } else {
          // Lance une erreur si l'API retourne un message d'échec.
          throw Exception("Erreur : ${data['message']}");
        }
      } else {
        // Lance une erreur pour les codes de statut HTTP autres que 200.
        throw Exception("Erreur API : ${response.statusCode}");
      }
    } catch (e) {
      // Attrape toute autre exception (ex: réseau) et la relance.
      throw Exception("Erreur lors de la récupération des coiffeuses : $e");
    }
  }
}








// import 'dart:convert';
// import 'package:hairbnb/models/minimal_coiffeuse.dart';
// import 'package:http/http.dart' as http;
//
// class CoiffeuseService {
//   static const String baseUrl = "https://www.hairbnb.site";
//
//   static Future<List<MinimalCoiffeuse>> fetchCoiffeuses(List<String> uuids) async {
//     final url = Uri.parse('$baseUrl/api/get_coiffeuses_info/');
//
//     try {
//       final response = await http.post(
//         url,
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode({"uuids": uuids}),
//       );
//
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         if (data['status'] == "success") {
//           return (data['coiffeuses'] as List)
//               .map((json) => MinimalCoiffeuse.fromJson(json))
//               .toList();
//         } else {
//           throw Exception("Erreur : ${data['message']}");
//         }
//       } else {
//         throw Exception("Erreur API : ${response.statusCode}");
//       }
//     } catch (e) {
//       throw Exception("Erreur lors de la récupération des coiffeuses : $e");
//     }
//   }
// }
