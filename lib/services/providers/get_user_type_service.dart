/// *****************************************************************************
///
/// FONCTION UTILITAIRE DE RÉSOLUTION D'UUID
///
/// Ce fichier contient une fonction d'aide globale, `getIdAndTypeFromUuid`.
/// Son rôle est de servir de pont entre l'identifiant public d'un utilisateur
/// (son UUID, généralement fourni par un service d'authentification comme Firebase)
/// et les identifiants internes utilisés dans la base de données de l'application.
///
/// En fournissant un UUID, cette fonction interroge une API spécifique pour
/// récupérer deux informations cruciales :
/// 1.  `idTblUser` : La clé primaire de l'utilisateur dans la base de données interne.
/// 2.  `type` : Le type de compte de l'utilisateur (ex: 'client', 'coiffeuse').
///
/// Cette fonction est essentielle après la connexion pour diriger l'utilisateur
/// vers la bonne interface et récupérer les données qui lui sont propres.
///
///*****************************************************************************
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Interroge l'API pour obtenir l'ID interne et le type de compte d'un utilisateur à partir de son UUID.
///
/// [uuid] : L'identifiant unique universel de l'utilisateur (généralement fourni par Firebase Auth).
/// Retourne une `Future` qui se résout en une `Map` contenant 'idTblUser' et 'type' en cas de succès,
/// ou `null` en cas d'erreur ou si l'utilisateur n'est pas trouvé.
Future<Map<String, dynamic>?> getIdAndTypeFromUuid(String uuid) async {
  // Construit l'URL de l'API en incluant l'UUID de l'utilisateur dans le chemin.
  final url = Uri.parse('https://www.hairbnb.site/api/get_id_and_type_from_uuid/$uuid/');

  // Enveloppe l'appel réseau dans un bloc try-catch pour gérer les erreurs de connexion.
  try {
    // Effectue la requête HTTP GET vers l'URL construite.
    final response = await http.get(url);

    // Vérifie si la requête a abouti avec un code de succès.
    if (response.statusCode == 200) {
      // Décode la réponse JSON reçue du serveur.
      final data = json.decode(response.body);

      // Vérifie le drapeau de succès dans la réponse de l'API elle-même.
      if (data['success']) {
        // Si l'opération a réussi côté serveur, retourne les données utiles.
        return {
          'idTblUser': data['idTblUser'],
          'type': data['type'],
        };
      } else {
        // Si le serveur retourne une erreur métier.
        if (kDebugMode) {
          print("Erreur : ${data['error']}");
        }
        return null;
      }
    } else {
      // Gère les erreurs de statut HTTP (ex: 404 Not Found, 500 Server Error).
      if (kDebugMode) {
        print("Erreur HTTP : ${response.statusCode}");
      }
      return null;
    }
  } catch (e) {
    // Gère les erreurs au niveau du réseau (ex: pas d'internet, DNS introuvable).
    if (kDebugMode) {
      print("Erreur réseau : $e");
    }
    return null;
  }
}





//
// import 'dart:convert';
//
// import 'package:http/http.dart' as http;
//
// Future<Map<String, dynamic>?> getIdAndTypeFromUuid(String uuid) async {
//   final url = Uri.parse('https://www.hairbnb.site/api/get_id_and_type_from_uuid/$uuid/');
//
//   try {
//     final response = await http.get(url);
//
//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);
//       if (data['success']) {
//         return {
//           'idTblUser': data['idTblUser'],
//           'type': data['type'],
//         };
//       } else {
//         print("Erreur : ${data['error']}");
//         return null;
//       }
//     } else {
//       print("Erreur HTTP : ${response.statusCode}");
//       return null;
//     }
//   } catch (e) {
//     print("Erreur réseau : $e");
//     return null;
//   }
// }
//
//
