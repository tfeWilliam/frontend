/****************************************************************************************
 *
 * SERVICE API : GESTION DES RENDEZ-VOUS (RDV)
 *
 * OBJECTIF :
 * Cette classe agit comme un service de communication avec l'API backend. Son rôle
 * est d'abstraire la logique des appels HTTP pour tout ce qui concerne la gestion
 * des rendez-vous (RDV).
 *
 * CLASSE :
 * - RdvService : Contient les méthodes pour interagir avec les points de terminaison
 * (endpoints) de l'API relatifs aux rendez-vous.
 *
 * FONCTIONNALITÉS :
 * - Récupère la liste des rendez-vous pour une coiffeuse donnée.
 * - Gère le filtrage des rendez-vous (par exemple, archivés ou non).
 * - S'occupe de la désérialisation de la réponse JSON en une liste d'objets Dart
 * fortement typés (`RdvConfirmation`).
 * - Gère les erreurs de communication avec l'API.
 *
 *****************************************************************************************/
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'rdvConfirmation.dart';

/// Classe de service responsable de la communication avec l'API pour les rendez-vous.
class RdvService {
  /// L'URL de base de l'API backend.
  final String baseUrl = "https://www.hairbnb.site/api";

  /// Récupère une liste de rendez-vous pour une coiffeuse spécifique depuis l'API.
  ///
  /// [coiffeuseId] : L'identifiant de la coiffeuse dont on veut récupérer les RDV.
  /// [archived] : Un booléen optionnel pour filtrer les RDV archivés. Par défaut à `false`.
  ///
  /// Retourne un `Future<List<RdvConfirmation>>` contenant la liste des rendez-vous.
  /// Lance une [Exception] si la requête HTTP échoue (code de statut autre que 200).
  Future<List<RdvConfirmation>> fetchRendezVous({
    required int coiffeuseId,
    bool archived = false,
  }) async {
    try {
      // Construction de l'URI avec les paramètres de la requête.
      final response = await http.get(
        Uri.parse("$baseUrl/rendezvous/?coiffeuse_id=$coiffeuseId&archived=$archived"),
        headers: {"Content-Type": "application/json"},
      );

      // Vérifie si la requête a réussi.
      if (response.statusCode == 200) {
        // Décode la réponse JSON.
        final data = json.decode(response.body);
        // Extrait la liste des résultats.
        final List<dynamic> rdvList = data['results'];

        // Mappe chaque élément JSON de la liste à un objet RdvConfirmation et retourne la liste.
        return rdvList.map((rdv) => RdvConfirmation.fromJson(rdv)).toList();
      } else {
        // En cas d'échec, lance une exception avec les détails de l'erreur.
        throw Exception("Erreur ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      // Relance l'exception pour que la couche appelante (UI, BLoC, etc.) puisse la gérer.
      rethrow;
    }
  }
}





// // /// **📌 Modèle pour un service dans le RDV**
//
//
// import 'dart:convert';
//
// import 'package:http/http.dart' as http;
//
// import 'rdvConfirmation.dart';
//
// class RdvService {
//   final String baseUrl = "https://www.hairbnb.site/api";
//
//   Future<List<RdvConfirmation>> fetchRendezVous({
//     required int coiffeuseId,
//     bool archived = false,
//   }) async {
//     try {
//       final response = await http.get(
//         Uri.parse("$baseUrl/rendezvous/?coiffeuse_id=$coiffeuseId&archived=$archived"),
//         headers: {"Content-Type": "application/json"},
//       );
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         final List<dynamic> rdvList = data['results'];
//
//         return rdvList.map((rdv) => RdvConfirmation.fromJson(rdv)).toList();
//       } else {
//         throw Exception("Erreur ${response.statusCode}: ${response.body}");
//       }
//     } catch (e) {
//       print("Erreur fetchRendezVous: $e");
//       rethrow;
//     }
//   }
// }