/// *************************************************************************************************
///
/// BANNER : EXPLICATION GÉNÉRALE DU SERVICE
///
/// Ce fichier définit la classe `AddressApiService`.
///
/// Objectif :
/// Cette classe sert de couche de service pour communiquer avec une API backend
/// (probablement https://www.hairbnb.site) afin de gérer les adresses des utilisateurs.
/// Elle centralise la logique des appels réseau liés aux adresses.
///
/// Fonctionnalités :
/// -   Mettre à jour l'adresse d'un utilisateur existant via une requête HTTP PATCH.
/// -   Récupérer l'adresse d'un utilisateur via une requête HTTP GET.
///
/// Utilisation :
/// La classe ne contient que des méthodes statiques, il n'est donc pas nécessaire
/// de l'instancier. On peut appeler ses méthodes directement :
/// `AddressApiService.updateUserAddress(...)` ou `AddressApiService.getUserAddress(...)`.
///
///*************************************************************************************************
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../chat/chat_services/user_service.dart'; // Import probablement utilisé pour des variables partagées comme `baseUrl`.


/// Classe de service pour gérer les appels API liés à l'adresse de l'utilisateur.
class AddressApiService {
  /// Met à jour l'adresse d'un utilisateur spécifique sur le serveur.
  ///
  /// Utilise une requête HTTP PATCH pour n'envoyer que les champs modifiés.
  /// [userUuid] est l'identifiant unique de l'utilisateur.
  /// [addressData] est une Map contenant les nouvelles données d'adresse.
  /// Retourne une `Future` avec la réponse du serveur (les données mises à jour).
  /// En cas d'erreur, une exception est levée et doit être gérée par l'appelant.
  static Future<Map<String, dynamic>> updateUserAddress({
    required String userUuid,
    required Map<String, dynamic> addressData,
  }) async {
    try {
      // Construction de l'URL cible pour la mise à jour de l'adresse.
      final String url = 'https://www.hairbnb.site/api/users/$userUuid/address/';

      // Envoi de la requête PATCH avec les nouvelles données.
      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // Une authentification (par exemple un token JWT) devrait être ajoutée ici si l'API est protégée.
        },
        // Encodage de la Map de données en une chaîne de caractères JSON.
        body: json.encode(addressData),
      );

      // Vérifie si la requête a été traitée avec succès par le serveur.
      if (response.statusCode == 200) {
        // Décode la réponse JSON du serveur et la retourne.
        return json.decode(response.body);
      } else {
        // Si le serveur retourne une erreur, on lève une exception détaillée.
        throw Exception("Erreur ${response.statusCode}: ${response.body}");
      }

    } catch (e) {
      // Capture toute exception (réseau, formatage, etc.), l'affiche dans la console.
      if (kDebugMode) {
        print("❌ Erreur lors de la mise à jour de l'adresse: $e");
      }
      // Fait remonter l'exception pour que la couche supérieure (UI) puisse la traiter.
      rethrow;
    }
  }

  /// Récupère l'adresse d'un utilisateur spécifique depuis le serveur.
  ///
  /// [userUuid] est l'identifiant unique de l'utilisateur dont on veut l'adresse.
  /// Retourne une `Future` contenant une Map avec les données de l'adresse,
  /// ou `null` si une erreur survient (API, réseau, timeout, etc.).
  static Future<Map<String, dynamic>?> getUserAddress(String userUuid) async {
    try {
      // Construction de l'URL cible pour la récupération de l'adresse.
      // La variable `baseUrl` est probablement définie dans `user_service.dart`.
      final url = Uri.parse('$baseUrl/users/$userUuid/address');

      // Envoi de la requête GET pour récupérer les données.
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        // Ajout d'un timeout pour éviter que l'application ne se bloque sur une requête trop longue.
      ).timeout(
        const Duration(seconds: 15),
      );

      // Si le serveur répond positivement.
      if (response.statusCode == 200) {
        // Décode la réponse JSON.
        final data = json.decode(response.body);
        // Retourne uniquement la partie 'data' de la réponse.
        return data['data'];
      } else {
        // En cas d'erreur de l'API, on affiche l'erreur et on retourne null.
        if (kDebugMode) {
          print('❌ Erreur de récupération d\'adresse (API): ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      // En cas d'exception (timeout, réseau...), on affiche l'erreur et on retourne null.
      if (kDebugMode) {
        print('❌ Exception lors de la récupération d\'adresse: $e');
      }
      return null;
    }
  }
}






// // lib/pages/profil/services/update_services/adress_update/adress_api_service.dart
//
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../../../../chat/chat_services/user_service.dart';
//
//
// class AddressApiService {
//   static Future<Map<String, dynamic>> updateUserAddress({
//     required String userUuid,
//     required Map<String, dynamic> addressData,
//   }) async {
//     try {
//       final String url = 'https://www.hairbnb.site/api/users/$userUuid/address/';
//
//       final response = await http.patch(
//         Uri.parse(url),
//         headers: {
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//           // Ajoutez l'authentification si nécessaire
//         },
//         body: json.encode(addressData),
//       );
//
//       if (response.statusCode == 200) {
//         return json.decode(response.body);
//       } else {
//         throw Exception("Erreur ${response.statusCode}: ${response.body}");
//       }
//
//     } catch (e) {
//       print("❌ Erreur: $e");
//       rethrow;
//     }
//   }
//
//   static Future<Map<String, dynamic>?> getUserAddress(String userUuid) async {
//     try {
//       final url = Uri.parse('$baseUrl/users/$userUuid/address');
//
//       final response = await http.get(
//         url,
//         headers: {
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//         },
//       ).timeout(
//         const Duration(seconds: 15),
//       );
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         return data['data'];
//       } else {
//         print('❌ Erreur récupération: ${response.statusCode}');
//         return null;
//       }
//     } catch (e) {
//       print('❌ Exception récupération: $e');
//       return null;
//     }
//   }
// }