// // services/salon_service.dart
// import 'dart:convert';
// import 'package:http/http.dart' as http;
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//        SERVICE (CLIENT API) POUR LES DÉTAILS PUBLICS D'UN SALON              //
//                                                                            //
//  Ce fichier définit `PublicSalonDetailsApi`, une classe de service dédiée  //
//  à une tâche unique : récupérer toutes les informations publiques et       //
//  détaillées d'un salon spécifique en utilisant son identifiant.            //
//                                                                            //
//  La classe utilise des méthodes statiques pour permettre des appels directs//
//  sans avoir besoin d'instancier la classe, ce qui est courant pour des     //
//  services API simples.                                                     //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;


import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../models/public_salon_details.dart';

/// Une classe de service contenant des méthodes statiques pour interagir avec
/// les endpoints publics de l'API relatifs aux détails des salons.
class PublicSalonDetailsApi {
  /// L'URL de base de l'API backend.
  static const String baseUrl = 'https://hairbnb.site/api';

  /// Récupère l'ensemble des détails publics pour un salon spécifique à partir de son ID.
  ///
  /// Effectue un appel GET public (non authentifié) à l'endpoint `/salons/{salonId}/`.
  ///
  /// [salonId] : L'identifiant numérique du salon à récupérer.
  ///
  /// Retourne un `Future<PublicSalonDetails>` qui se résout avec l'objet
  /// complet du salon en cas de succès.
  /// Lève une `Exception` en cas d'échec de la requête (ex: statut non 200)
  /// ou en cas d'erreur de connexion.
  static Future<PublicSalonDetails> getSalonDetails(int salonId) async {
    // Construit l'URL complète pour l'appel API.
    final response = await http.get(Uri.parse('$baseUrl/salons/$salonId/'));

    // Vérifie si la requête a abouti avec succès.
    if (response.statusCode == 200) {
      // Si c'est le cas, décode le corps de la réponse JSON et le désérialise
      // en un objet `PublicSalonDetails`.
      return PublicSalonDetails.fromJson(json.decode(response.body));
    } else {
      // Si l'API renvoie un code d'erreur, lève une exception pour le signaler.
      throw Exception('Échec du chargement des détails du salon');
    }
  }
}





//
// import '../../models/public_salon_details.dart';
//
// class PublicSalonDetailsApi {
//   static const String baseUrl = 'https://hairbnb.site/api';
//
//   static Future<PublicSalonDetails> getSalonDetails(int salonId) async {
//     final response = await http.get(Uri.parse('$baseUrl/salons/$salonId/'));
//
//     if (response.statusCode == 200) {
//       return PublicSalonDetails.fromJson(json.decode(response.body));
//     } else {
//       throw Exception('Échec du chargement des détails du salon');
//     }
//   }
// }