////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//      SERVICE (CLIENT API) POUR LA RÉCUPÉRATION DE SALON PAR COIFFEUSE        //
//                                                                            //
//  Ce fichier définit `SalonByCoiffeuseApi`, une classe de service dédiée à   //
//  une tâche unique : trouver et récupérer les informations d'un salon en se  //
//  basant sur l'identifiant de la coiffeuse qui lui est associée.             //
//                                                                            //
//  La classe utilise des méthodes statiques pour permettre des appels directs//
//  sans avoir besoin d'instancier la classe.                                 //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../models/salon.dart';

/// Une classe de service fournissant des méthodes statiques pour interagir
/// avec l'API concernant la récupération d'un salon via une coiffeuse.
class SalonByCoiffeuseApi {
  /// L'URL de base de l'API backend.
  static const String baseUrl = 'https://www.hairbnb.site/api';

  /// Récupère l'objet `Salon` associé à l'identifiant d'une coiffeuse.
  ///
  /// Cette méthode interroge un endpoint spécifique et s'attend à une réponse
  /// JSON contenant une clé `exists` et un objet `salon`. Elle gère les cas
  /// où le salon n'existe pas, les erreurs de l'API et les problèmes de connexion.
  ///
  /// [coiffeuseId] : L'identifiant numérique de la coiffeuse.
  ///
  /// Retourne une `Future<Salon?>` qui se résout en un objet `Salon` en cas de succès,
  /// ou `null` dans tous les autres cas (salon non trouvé, erreur API, etc.).
  static Future<Salon?> getSalonByCoiffeuseId(int coiffeuseId) async {
    try {
      // Effectue la requête GET vers l'endpoint de l'API.
      final response = await http.get(
        Uri.parse('$baseUrl/get_salon_by_coiffeuse/$coiffeuseId/'),
      );

      // Vérifie si la requête a réussi.
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Vérifie la structure de la réponse attendue par l'API.
        if (data['exists'] == true && data['salon'] != null) {
          // Si le salon existe, le désérialise en un objet Salon.
          return Salon.fromJson(data['salon']);
        } else {
          // Si l'API indique que le salon n'existe pas, retourne null.
          return null;
        }
      } else {
        // Gère les autres codes de statut HTTP (ex: 404, 500) en retournant null.
        if (kDebugMode) {
          print('Erreur API: ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      // Gère les erreurs de connexion réseau ou autres exceptions.
      if (kDebugMode) {
        print('Exception lors de la récupération du salon: $e');
      }
      return null;
    }
  }
}




// // services/salon_api_service.dart
// import 'dart:convert';
// import 'package:http/http.dart' as http;
//
// import '../../../../models/salon.dart';
//
// class SalonByCoiffeuseApi {
//   static const String baseUrl = 'https://www.hairbnb.site/api';
//
//   // Récupérer le salon associé à une coiffeuse
//   static Future<Salon?> getSalonByCoiffeuseId(int coiffeuseId) async {
//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl/get_salon_by_coiffeuse/$coiffeuseId/'),
//       );
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//
//         if (data['exists'] == true && data['salon'] != null) {
//           return Salon.fromJson(data['salon']);
//         } else {
//           return null;
//         }
//       } else {
//         // Si le statut n'est pas 200, on retourne null
//         print('Erreur API: ${response.statusCode}');
//         return null;
//       }
//     } catch (e) {
//       // En cas d'erreur réseau ou autre
//       print('Exception lors de la récupération du salon: $e');
//       return null;
//     }
//   }
// }