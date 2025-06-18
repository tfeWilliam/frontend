////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//          SERVICE (CLIENT API) POUR LA GESTION DES PROFILS UTILISATEUR        //
//                                                                            //
//  Ce fichier définit `ProfileApiService`, une classe qui centralise toutes  //
//  les communications avec l'API backend pour les opérations liées aux       //
//  profils des utilisateurs.                                                 //
//                                                                            //
//  Responsabilités :                                                         //
//  - Création d'un nouveau profil utilisateur, avec gestion de l'envoi de    //
//    fichiers (photo de profil) via une requête `MultipartRequest`.          //
//  - Récupération des informations d'un profil existant.                     //
//  - Mise à jour de données spécifiques comme le numéro de téléphone ou      //
//    l'adresse.                                                              //
//  - Gestion de l'authentification pour les requêtes sécurisées.             //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../models/user_creation.dart';
import '../../../services/firebase_token/token_service.dart';

/// Une classe de service contenant des méthodes statiques pour interagir
/// avec les endpoints de l'API relatifs aux profils utilisateurs.
class ProfileApiService {
  /// L'URL de base de l'API backend.
  static const String baseUrl = "https://www.hairbnb.site/api";

  /// Crée un nouveau profil utilisateur complet, incluant potentiellement une photo de profil.
  ///
  /// Cette méthode orchestre un processus en plusieurs étapes :
  /// 1. Valide les données du modèle localement.
  /// 2. Récupère un token d'authentification Firebase.
  /// 3. Construit une requête `http.MultipartRequest` pour pouvoir envoyer
  ///    à la fois des données textuelles et un fichier image.
  /// 4. Gère la logique d'envoi de l'image différemment pour le web (bytes) et mobile (chemin).
  /// 5. Envoie la requête et parse la réponse dans un objet `UserCreationResponse`.
  ///
  /// [userModel] : L'objet contenant toutes les données du profil à créer.
  /// [firebaseToken] : Un token optionnel. S'il n'est pas fourni, le service tente de le récupérer.
  ///
  /// Retourne un `Future<UserCreationResponse>` qui encapsule le résultat de l'opération.
  static Future<UserCreationResponse> createUserProfile({
    required UserCreationModel userModel,
    String? firebaseToken,
  }) async {
    try {
      // 1. Validation des données du modèle avant l'envoi pour éviter un appel API inutile.
      final validationErrors = userModel.validate();
      if (validationErrors.isNotEmpty) {
        return UserCreationResponse.error(
          message: "Erreurs de validation",
          validationErrors: validationErrors,
        );
      }

      // 2. Définition de l'URL et création de la requête multipart.
      final url = Uri.parse("$baseUrl/create-profile/");
      var request = http.MultipartRequest('POST', url);

      // 3. Récupération et ajout du token d'authentification Firebase pour sécuriser la requête.
      String? authToken = firebaseToken ?? await TokenService.getAuthToken();
      if (authToken != null && authToken.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $authToken';
        if (kDebugMode) print("🔐 Token ajouté à la requête");
      } else if (kDebugMode) {
        print("⚠️ Aucun token d'authentification disponible");
      }

      // 4. Ajout des champs de texte (nom, email, etc.) à la requête.
      request.fields.addAll(userModel.toApiFields());

      // 5. Ajout de la photo de profil (si présente), avec une logique différente pour le web et mobile.
      if (userModel.photoProfilFile != null || userModel.photoProfilBytes != null) {
        if (kIsWeb && userModel.photoProfilBytes != null) {
          // Pour le web, on envoie les données binaires (bytes) de l'image.
          request.files.add(http.MultipartFile.fromBytes(
            'photo_profil',
            userModel.photoProfilBytes!,
            filename: userModel.photoProfilName ?? 'profile_photo.png',
            contentType: MediaType('image', 'png'),
          ));
        } else if (userModel.photoProfilFile != null) {
          // Pour mobile, on envoie le fichier directement depuis son chemin d'accès.
          request.files.add(await http.MultipartFile.fromPath(
            'photo_profil',
            userModel.photoProfilFile!.path,
          ));
        }
      }

      // 6. Envoi de la requête et récupération de la réponse.
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      if (kDebugMode) print("📡 Réponse API (${response.statusCode}): $responseBody");

      // 7. Parsing et retour de la réponse structurée de l'API.
      return UserCreationResponse.fromHttpResponse(
        statusCode: response.statusCode,
        body: responseBody,
      );

    } catch (e) {
      // Gestion des erreurs de connexion ou autres exceptions.
      if (kDebugMode) print("❌ Erreur dans createUserProfile: $e");
      return UserCreationResponse.error(message: "Erreur de connexion: $e");
    }
  }

  /// Récupère les données publiques d'un profil utilisateur à partir de son UUID.
  ///
  /// [userUuid] : L'identifiant universel unique de l'utilisateur à récupérer.
  ///
  /// Retourne un `Map<String, dynamic>` contenant les données du profil en cas de succès,
  /// ou `null` en cas d'échec.
  static Future<Map<String, dynamic>?> getUserProfile(String userUuid) async {
    try {
      final url = Uri.parse("$baseUrl/get_user_profile/$userUuid/");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) print("Erreur lors de la récupération du profil: $e");
      return null;
    }
  }

  /// Met à jour le numéro de téléphone d'un utilisateur via une requête PATCH.
  ///
  /// [userUuid] : L'UUID de l'utilisateur à modifier.
  /// [newPhone] : Le nouveau numéro de téléphone.
  /// [firebaseToken] : Le token d'authentification pour autoriser la requête.
  ///
  /// Retourne `true` si la mise à jour a réussi, `false` sinon.
  static Future<bool> updatePhoneNumber({
    required String userUuid,
    required String newPhone,
    String? firebaseToken,
  }) async {
    try {
      final url = Uri.parse("$baseUrl/update_user_phone/$userUuid/");
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (firebaseToken != null) headers['Authorization'] = 'Bearer $firebaseToken';

      final response = await http.patch(
        url,
        headers: headers,
        body: json.encode({'numeroTelephone': newPhone}),
      );

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print("Erreur lors de la mise à jour du téléphone: $e");
      return false;
    }
  }

  /// Met à jour l'adresse d'un utilisateur via une requête PATCH.
  ///
  /// [userUuid] : L'UUID de l'utilisateur à modifier.
  /// [addressData] : Un `Map` contenant les nouvelles données de l'adresse.
  /// [firebaseToken] : Le token d'authentification pour autoriser la requête.
  ///
  /// Retourne `true` si la mise à jour a réussi, `false` sinon.
  static Future<bool> updateAddress({
    required String userUuid,
    required Map<String, dynamic> addressData,
    String? firebaseToken,
  }) async {
    try {
      final url = Uri.parse("$baseUrl/update_user_address/$userUuid/");
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (firebaseToken != null) headers['Authorization'] = 'Bearer $firebaseToken';

      final response = await http.patch(
        url,
        headers: headers,
        body: json.encode(addressData),
      );

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print("Erreur lors de la mise à jour de l'adresse: $e");
      return false;
    }
  }
}







// // services/profile_api_service.dart
// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http;
// import 'package:http_parser/http_parser.dart';
//
// import '../../../models/user_creation.dart';
// import '../../../services/firebase_token/token_service.dart';
//
// /// Service API pour la gestion des profils utilisateur
// class ProfileApiService {
//   static const String baseUrl = "https://www.hairbnb.site/api";
//
//   /// Crée un profil utilisateur via l'API
//   static Future<UserCreationResponse> createUserProfile({
//     required UserCreationModel userModel,
//     String? firebaseToken,
//   }) async {
//     try {
//       // 1. Validation des données avant l'envoi
//       final validationErrors = userModel.validate();
//       if (validationErrors.isNotEmpty) {
//         return UserCreationResponse.error(
//           message: "Erreurs de validation",
//           validationErrors: validationErrors,
//         );
//       }
//
//       // 2. Définition de l'URL pour la création de profil
//       // L'URL est correcte : baseUrl + /create-profile/
//       final url = Uri.parse("$baseUrl/create-profile/");
//       var request = http.MultipartRequest('POST', url);
//
//       // 3. Récupération et ajout du token d'authentification Firebase
//       String? authToken = firebaseToken;
//       // Si le token n'est pas directement fourni, essayer de le récupérer via TokenService
//       authToken ??= await TokenService.getAuthToken();
//
//       if (authToken != null && authToken.isNotEmpty) {
//         request.headers['Authorization'] = 'Bearer $authToken';
//         if (kDebugMode) {
//           print("🔐 Token ajouté à la requête");
//         }
//       } else {
//         if (kDebugMode) {
//           print("⚠️ Aucun token d'authentification disponible");
//         }
//       }
//
//       // 4. Ajout des champs de texte du modèle utilisateur à la requête
//       // userModel.toApiFields() enverra maintenant le champ 'type'
//       request.fields.addAll(userModel.toApiFields());
//
//       //5. Ajout de la photo de profil (si présente)
//       if (userModel.photoProfilFile != null || userModel.photoProfilBytes != null) {
//         if (kIsWeb && userModel.photoProfilBytes != null) {
//           // Pour le web, utilisez les bytes de l'image
//           request.files.add(
//             http.MultipartFile.fromBytes(
//               'photo_profil',
//               userModel.photoProfilBytes!,
//               filename: userModel.photoProfilName ?? 'profile_photo.png',
//               contentType: MediaType('image', 'png'), // Définir le type de contenu
//             ),
//           );
//         } else if (userModel.photoProfilFile != null) {
//           // Pour les plateformes mobiles/desktop, utilisez le chemin du fichier
//           request.files.add(
//             await http.MultipartFile.fromPath(
//               'photo_profil',
//               userModel.photoProfilFile!.path,
//             ),
//           );
//         }
//       }
//
//       // 6. Envoi de la requête et lecture de la réponse
//       final response = await request.send();
//       final responseBody = await response.stream.bytesToString();
//
//       if (kDebugMode) {
//         print("📡 Réponse API (${response.statusCode}): $responseBody");
//       }
//
//       // 7. Parsing et retour de la réponse de l'API
//       return UserCreationResponse.fromHttpResponse(
//         statusCode: response.statusCode,
//         body: responseBody,
//       );
//
//     } catch (e) {
//       // Gestion des erreurs de connexion ou autres exceptions
//       if (kDebugMode) {
//         print("❌ Erreur dans createUserProfile: $e");
//       }
//       return UserCreationResponse.error(
//         message: "Erreur de connexion: $e",
//       );
//     }
//   }
//
//   /// Récupère le profil d'un utilisateur par son UUID
//   static Future<Map<String, dynamic>?> getUserProfile(String userUuid) async {
//     try {
//       // CORRECTION DE L'URL : Suppression du '/api/' en double
//       final url = Uri.parse("$baseUrl/get_user_profile/$userUuid/");
//       final response = await http.get(url);
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data['success'] == true) {
//           return data['data'];
//         }
//       }
//       return null;
//     } catch (e) {
//       if (kDebugMode) {
//         print("Erreur lors de la récupération du profil: $e");
//       }
//       return null;
//     }
//   }
//
//   /// Met à jour le numéro de téléphone d'un utilisateur
//   static Future<bool> updatePhoneNumber({
//     required String userUuid,
//     required String newPhone,
//     String? firebaseToken,
//   }) async {
//     try {
//       // CORRECTION DE L'URL : Suppression du '/api/' en double
//       final url = Uri.parse("$baseUrl/update_user_phone/$userUuid/");
//       final headers = <String, String>{
//         'Content-Type': 'application/json',
//       };
//
//       if (firebaseToken != null) {
//         headers['Authorization'] = 'Bearer $firebaseToken';
//       }
//
//       final response = await http.patch(
//         url,
//         headers: headers,
//         body: json.encode({
//           'numeroTelephone': newPhone,
//         }),
//       );
//
//       return response.statusCode == 200;
//     } catch (e) {
//       if (kDebugMode) {
//         print("Erreur lors de la mise à jour du téléphone: $e");
//       }
//       return false;
//     }
//   }
//
//   /// Met à jour l'adresse d'un utilisateur
//   static Future<bool> updateAddress({
//     required String userUuid,
//     required Map<String, dynamic> addressData,
//     String? firebaseToken,
//   }) async {
//     try {
//       // CORRECTION DE L'URL : Suppression du '/api/' en double
//       final url = Uri.parse("$baseUrl/update_user_address/$userUuid/");
//       final headers = <String, String>{
//         'Content-Type': 'application/json',
//       };
//
//       if (firebaseToken != null) {
//         headers['Authorization'] = 'Bearer $firebaseToken';
//       }
//
//       final response = await http.patch(
//         url,
//         headers: headers,
//         body: json.encode(addressData),
//       );
//
//       return response.statusCode == 200;
//     } catch (e) {
//       if (kDebugMode) {
//         print("Erreur lors de la mise à jour de l'adresse: $e");
//       }
//       return false;
//     }
//   }
// }
//
