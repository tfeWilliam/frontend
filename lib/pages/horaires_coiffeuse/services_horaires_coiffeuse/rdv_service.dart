/// **************************************************************************************
///
/// SERVICE API : GESTION DES RENDEZ-VOUS (RDV)
///
/// OBJECTIF :
/// Ce fichier définit une classe de service, `RdvService`, qui sert d'interface
/// pour communiquer avec l'API backend. Son rôle est de centraliser la logique des
/// appels réseau pour récupérer les informations sur les rendez-vous d'une coiffeuse.
///
/// CONCEPTION :
/// La classe est conçue pour être instanciée et encapsule la logique d'appel à l'API,
/// rendant le code qui l'utilise plus propre et plus facile à maintenir.
///
///***************************************************************************************
library;
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../models/reservation_light.dart';

/// Classe de service pour interagir avec les points de terminaison de l'API liés aux rendez-vous.
class RdvService {
  /// L'URL de base du serveur backend.
  final baseUrl = "https://www.hairbnb.site/api";

  /// Récupère une liste de rendez-vous (en format léger) pour une coiffeuse spécifique.
  ///
  /// [coiffeuseId] : L'identifiant de la coiffeuse dont les rendez-vous sont demandés.
  /// [archived] : Un booléen pour déterminer s'il faut récupérer les rendez-vous archivés (`true`) ou actifs (`false`).
  ///
  /// Retourne un `Future<List<ReservationLight>>` contenant la liste des rendez-vous.
  /// Lance une [Exception] si la réponse du serveur n'a pas le statut 200.
  Future<List<ReservationLight>> fetchRendezVous({
    required int coiffeuseId,
    required bool archived,
  }) async {
    // Sélectionne le point de terminaison de l'API en fonction du paramètre 'archived'.
    final endpoint = archived
        ? "/get_archived_rendezvous_by_coiffeuse_id/$coiffeuseId/"
        : "/get_rendezvous_by_coiffeuse_id/$coiffeuseId/";

    // Exécute la requête GET vers l'API.
    final response = await http.get(Uri.parse("$baseUrl$endpoint"));

    // Si la requête a abouti avec succès (statut 200 OK).
    if (response.statusCode == 200) {
      // Décode la réponse JSON.
      final data = jsonDecode(response.body);
      // Extrait la liste des résultats.
      final List<dynamic> results = data['results'];
      // Convertit chaque objet JSON de la liste en un objet Dart [ReservationLight].
      return results.map((e) => ReservationLight.fromJson(e)).toList();
    } else {
      // Lance une exception si le serveur retourne un code d'erreur.
      throw Exception("Erreur serveur : ${response.statusCode}");
    }
  }
}






// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../../../models/reservation_light.dart';
//
// class RdvService {
//   final baseUrl = "https://www.hairbnb.site/api";
//
//   Future<List<ReservationLight>> fetchRendezVous({
//     required int coiffeuseId,
//     required bool archived,
//   }) async {
//     final endpoint = archived
//         ? "/get_archived_rendezvous_by_coiffeuse_id/$coiffeuseId/"
//         : "/get_rendezvous_by_coiffeuse_id/$coiffeuseId/";
//
//
//     final response = await http.get(Uri.parse("$baseUrl$endpoint"));
//
//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       final List<dynamic> results = data['results'];
//       return results.map((e) => ReservationLight.fromJson(e)).toList();
//     } else {
//       throw Exception("Erreur serveur : ${response.statusCode}");
//     }
//   }
// }
