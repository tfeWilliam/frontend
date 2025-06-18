/// *************************************************************************************************
///
/// BANNER : EXPLICATION GÉNÉRALE DU SERVICE DE MISE À JOUR DU TÉLÉPHONE
///
/// Ce fichier contient l'ensemble de la logique nécessaire pour communiquer avec l'API
/// backend afin de mettre à jour le numéro de téléphone d'un utilisateur.
///
/// Il est structuré en plusieurs parties :
///
/// 1.  `PhoneApiService` :
/// La classe principale qui contient la logique d'appel réseau. Elle prépare et envoie
/// la requête HTTP PATCH, gère l'authentification en récupérant un token, et délègue
/// l'analyse de la réponse à une méthode dédiée.
///
/// 2.  `PhoneUpdateRequest` :
/// Une classe de données simple (DTO) qui structure le corps de la requête JSON
/// envoyée à l'API, garantissant que le format correspond à ce que le backend attend.
///
/// 3.  `PhoneUpdateResult` :
/// Une classe de résultat structurée qui encapsule le dénouement de l'appel API.
/// Plutôt que de lever des exceptions pour les erreurs API, les méthodes retournent
/// cet objet, qui contient un statut de succès, un message pour l'utilisateur,
/// et un type d'erreur catégorisé.
///
/// 4.  `PhoneUpdateErrorType` :
/// Une énumération qui définit des catégories d'erreurs claires. Cela permet à
/// la couche UI de réagir différemment selon le type d'erreur (ex: afficher une
/// erreur de validation sur un champ, ou rediriger vers la page de connexion).
///
///*************************************************************************************************
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../../services/firebase_token/token_service.dart';

/// Classe de service gérant les appels API pour le numéro de téléphone de l'utilisateur.
class PhoneApiService {
  /// L'URL de base pour toutes les requêtes de l'API.
  static const String baseUrl = 'https://www.hairbnb.site/api';

  /// Tente de mettre à jour le numéro de téléphone pour un utilisateur donné.
  ///
  /// Cette méthode gère l'obtention du token, la construction de la requête, l'appel réseau
  /// et retourne un objet `PhoneUpdateResult` détaillé.
  /// [userUuid] L'identifiant unique de l'utilisateur.
  /// [newPhone] Le nouveau numéro de téléphone à assigner.
  static Future<PhoneUpdateResult> updatePhone(String userUuid, String newPhone) async {
    try {
      // Construit l'URL complète de l'endpoint de l'API.
      final apiUrl = '$baseUrl/update_user_phone/$userUuid/';

      // Récupère le token d'authentification de manière asynchrone.
      final String? authToken = await TokenService.getAuthToken();

      // Si aucun token n'est disponible, la requête ne peut pas être authentifiée.
      if (authToken == null) {
        if (kDebugMode) {
          print('Erreur: Token d\'authentification non disponible');
        }
        return PhoneUpdateResult(
          success: false,
          message: 'Token d\'authentification non disponible. Veuillez vous reconnecter.',
          errorType: PhoneUpdateErrorType.authentication,
        );
      }

      // Prépare les en-têtes HTTP, incluant le type de contenu et le token d'autorisation.
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
        'Accept': 'application/json',
      };

      // Crée un objet structuré pour la requête et le convertit en JSON.
      final request = PhoneUpdateRequest(numeroTelephone: newPhone);
      final jsonBody = jsonEncode(request.toJson());

      // Logs de débogage pour suivre la requête sortante.
      if (kDebugMode) {
        print('🔍 Envoi de la requête de mise à jour téléphone...');
      }
      if (kDebugMode) {
        print('🔍 URL: $apiUrl');
      }
      if (kDebugMode) {
        print('🔍 Corps: $jsonBody');
      }

      // Envoie la requête HTTP PATCH au serveur.
      final response = await http.patch(
        Uri.parse(apiUrl),
        headers: headers,
        body: jsonBody,
      );

      // Logs de débogage pour la réponse reçue.
      if (kDebugMode) {
        print('🔍 Statut de la réponse: ${response.statusCode}');
      }
      if (kDebugMode) {
        print('🔍 Corps de la réponse: ${response.body}');
      }

      // Délègue l'analyse de la réponse à une méthode spécialisée.
      return _handleResponse(response);
    } catch (e) {
      // Capture les exceptions (ex: erreur réseau, timeout) et retourne un résultat d'erreur.
      if (kDebugMode) {
        print('❌ Exception lors de la mise à jour du téléphone: $e');
      }
      return PhoneUpdateResult(
        success: false,
        message: 'Impossible de se connecter au serveur. Veuillez vérifier votre connexion internet.',
        errorType: PhoneUpdateErrorType.network,
      );
    }
  }

  /// Méthode privée qui analyse la réponse HTTP et la transforme en `PhoneUpdateResult`.
  static PhoneUpdateResult _handleResponse(http.Response response) {
    // Utilise le code de statut HTTP pour déterminer le résultat de l'opération.
    switch (response.statusCode) {
      case 200: // OK: La mise à jour a réussi.
        try {
          final responseData = jsonDecode(response.body);
          return PhoneUpdateResult(
            success: true,
            message: responseData['message'] ?? 'Numéro de téléphone mis à jour avec succès.',
            data: responseData,
          );
        } catch (e) {
          // Fallback au cas où la réponse 200 ne serait pas un JSON valide.
          return PhoneUpdateResult(
            success: true,
            message: 'Numéro de téléphone mis à jour avec succès.',
          );
        }

      case 400: // Bad Request: Erreur de validation des données envoyées.
        try {
          final errorData = jsonDecode(response.body);
          // Tente d'extraire un message d'erreur spécifique du backend.
          String errorMessage = errorData['error'] ?? errorData['message'] ?? 'Données invalides.';
          return PhoneUpdateResult(
            success: false,
            message: errorMessage,
            errorType: PhoneUpdateErrorType.validation,
            data: errorData,
          );
        } catch (e) {
          return PhoneUpdateResult(
            success: false,
            message: 'Le format du numéro de téléphone est invalide.',
            errorType: PhoneUpdateErrorType.validation,
          );
        }

      case 401: // Unauthorized: Token invalide ou expiré.
        return PhoneUpdateResult(
          success: false,
          message: 'Session expirée, veuillez vous reconnecter.',
          errorType: PhoneUpdateErrorType.authentication,
        );

      case 403: // Forbidden: L'utilisateur est authentifié mais n'a pas les droits.
        return PhoneUpdateResult(
          success: false,
          message: 'Vous n\'êtes pas autorisé à effectuer cette modification.',
          errorType: PhoneUpdateErrorType.authorization,
        );

      case 404: // Not Found: La ressource (l'utilisateur) n'a pas été trouvée.
        return PhoneUpdateResult(
          success: false,
          message: 'L\'utilisateur cible n\'a pas été trouvé.',
          errorType: PhoneUpdateErrorType.notFound,
        );

      case 500: // Internal Server Error: Erreur côté serveur.
        try {
          final errorData = jsonDecode(response.body);
          final String errorMessage = 'Erreur serveur: ${errorData['error'] ?? 'Veuillez réessayer plus tard.'}';
          return PhoneUpdateResult(
            success: false,
            message: errorMessage,
            errorType: PhoneUpdateErrorType.server,
            data: errorData,
          );
        } catch (e) {
          return PhoneUpdateResult(
            success: false,
            message: 'Une erreur est survenue sur le serveur. Veuillez réessayer plus tard.',
            errorType: PhoneUpdateErrorType.server,
          );
        }

      default: // Gère tous les autres codes de statut inattendus.
        return PhoneUpdateResult(
          success: false,
          message: 'Une erreur inattendue est survenue (${response.statusCode}).',
          errorType: PhoneUpdateErrorType.unknown,
        );
    }
  }
}

/// Représente le corps de la requête de mise à jour, formaté pour l'API.
class PhoneUpdateRequest {
  final String numeroTelephone;

  PhoneUpdateRequest({required this.numeroTelephone});

  /// Convertit l'objet en une Map JSON.
  Map<String, dynamic> toJson() {
    return {
      // La clé 'numeroTelephone' doit correspondre exactement à ce qu'attend le backend.
      'numeroTelephone': numeroTelephone,
    };
  }
}

/// Représente le résultat d'une tentative de mise à jour du téléphone.
class PhoneUpdateResult {
  /// `true` si la mise à jour a réussi, sinon `false`.
  final bool success;
  /// Message descriptif à afficher à l'utilisateur.
  final String message;
  /// Type d'erreur catégorisé, `null` en cas de succès.
  final PhoneUpdateErrorType? errorType;
  /// Données supplémentaires retournées par l'API (ex: détails de l'erreur).
  final Map<String, dynamic>? data;

  PhoneUpdateResult({
    required this.success,
    required this.message,
    this.errorType,
    this.data,
  });
}

/// Énumération des types d'erreurs possibles pour une meilleure gestion dans l'UI.
enum PhoneUpdateErrorType {
  /// Erreur de validation (ex: format de numéro incorrect).
  validation,
  /// Problème de token (manquant, invalide ou expiré).
  authentication,
  /// L'utilisateur n'a pas les droits pour cette action.
  authorization,
  /// Le numéro est déjà utilisé par un autre compte (non géré par cette API actuellement).
  conflict,
  /// La ressource (utilisateur) n'a pas été trouvée.
  notFound,
  /// Erreur de connectivité réseau.
  network,
  /// Erreur interne du serveur (5xx).
  server,
  /// Toute autre erreur non catégorisée.
  unknown,
}






// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../../../../../services/firebase_token/token_service.dart';
//
// class PhoneApiService {
//   static const String baseUrl = 'https://www.hairbnb.site/api';
//
//   /// Met à jour uniquement le numéro de téléphone d'un utilisateur
//   /// Format corrigé pour correspondre au backend Django
//   static Future<PhoneUpdateResult> updatePhone(String userUuid, String newPhone) async {
//     try {
//       final apiUrl = '$baseUrl/update_user_phone/$userUuid/';
//
//       // Récupérer le token d'authentification
//       final String? authToken = await TokenService.getAuthToken();
//
//       if (authToken == null) {
//         print('Erreur: Token d\'authentification non disponible');
//         return PhoneUpdateResult(
//           success: false,
//           message: 'Token d\'authentification non disponible',
//           errorType: PhoneUpdateErrorType.authentication,
//         );
//       }
//
//       // Préparer les headers avec le token d'authentification
//       final headers = {
//         'Content-Type': 'application/json',
//         'Authorization': 'Bearer $authToken',
//         'Accept': 'application/json',
//       };
//
//       // CORRECTION : Utiliser "numeroTelephone" (camelCase) comme attendu par Django
//       final request = PhoneUpdateRequest(numeroTelephone: newPhone);
//       final jsonBody = jsonEncode(request.toJson());
//
//       print('🔍 Envoi de la requête de mise à jour téléphone');
//       print('🔍 URL: $apiUrl');
//       print('🔍 Corps: $jsonBody');
//
//       // Envoyer la requête PATCH
//       final response = await http.patch(
//         Uri.parse(apiUrl),
//         headers: headers,
//         body: jsonBody,
//       );
//
//       print('🔍 Statut réponse: ${response.statusCode}');
//       print('🔍 Corps réponse: ${response.body}');
//
//       // Analyser la réponse
//       return _handleResponse(response);
//     } catch (e) {
//       print('❌ Exception lors de la mise à jour du téléphone: $e');
//       return PhoneUpdateResult(
//         success: false,
//         message: 'Erreur de connexion: $e',
//         errorType: PhoneUpdateErrorType.network,
//       );
//     }
//   }
//
//   /// Analyse la réponse du serveur et retourne un résultat structuré
//   static PhoneUpdateResult _handleResponse(http.Response response) {
//     switch (response.statusCode) {
//       case 200:
//         try {
//           final responseData = jsonDecode(response.body);
//           return PhoneUpdateResult(
//             success: true,
//             message: responseData['message'] ?? 'Numéro de téléphone mis à jour avec succès',
//             data: responseData,
//           );
//         } catch (e) {
//           return PhoneUpdateResult(
//             success: true,
//             message: 'Numéro de téléphone mis à jour avec succès',
//           );
//         }
//
//       case 400:
//         try {
//           final errorData = jsonDecode(response.body);
//           String errorMessage = 'Données invalides';
//
//           // Extraire le message d'erreur du backend Django
//           if (errorData['error'] != null) {
//             errorMessage = errorData['error'];
//           } else if (errorData['message'] != null) {
//             errorMessage = errorData['message'];
//           }
//
//           return PhoneUpdateResult(
//             success: false,
//             message: errorMessage,
//             errorType: PhoneUpdateErrorType.validation,
//             data: errorData,
//           );
//         } catch (e) {
//           return PhoneUpdateResult(
//             success: false,
//             message: 'Format de numéro de téléphone invalide',
//             errorType: PhoneUpdateErrorType.validation,
//           );
//         }
//
//       case 401:
//         return PhoneUpdateResult(
//           success: false,
//           message: 'Session expirée, veuillez vous reconnecter',
//           errorType: PhoneUpdateErrorType.authentication,
//         );
//
//       case 403:
//         return PhoneUpdateResult(
//           success: false,
//           message: 'Vous n\'êtes pas autorisé à modifier ce numéro',
//           errorType: PhoneUpdateErrorType.authorization,
//         );
//
//       case 404:
//         return PhoneUpdateResult(
//           success: false,
//           message: 'Utilisateur non trouvé',
//           errorType: PhoneUpdateErrorType.notFound,
//         );
//
//       case 500:
//         try {
//           final errorData = jsonDecode(response.body);
//           String errorMessage = 'Erreur serveur, veuillez réessayer plus tard';
//
//           if (errorData['error'] != null) {
//             errorMessage = 'Erreur serveur: ${errorData['error']}';
//           }
//
//           return PhoneUpdateResult(
//             success: false,
//             message: errorMessage,
//             errorType: PhoneUpdateErrorType.server,
//             data: errorData,
//           );
//         } catch (e) {
//           return PhoneUpdateResult(
//             success: false,
//             message: 'Erreur serveur, veuillez réessayer plus tard',
//             errorType: PhoneUpdateErrorType.server,
//           );
//         }
//
//       default:
//         return PhoneUpdateResult(
//           success: false,
//           message: 'Erreur inattendue (${response.statusCode}): ${response.body}',
//           errorType: PhoneUpdateErrorType.unknown,
//         );
//     }
//   }
// }
//
// /// Classe pour représenter le corps de la requête de mise à jour du téléphone
// /// CORRECTION : Utilise "numeroTelephone" comme attendu par le backend Django
// class PhoneUpdateRequest {
//   final String numeroTelephone;
//
//   PhoneUpdateRequest({required this.numeroTelephone});
//
//   Map<String, dynamic> toJson() {
//     return {
//       'numeroTelephone': numeroTelephone, // camelCase comme attendu par Django
//     };
//   }
// }
//
// /// Résultat de la mise à jour du numéro de téléphone
// class PhoneUpdateResult {
//   final bool success;
//   final String message;
//   final PhoneUpdateErrorType? errorType;
//   final Map<String, dynamic>? data;
//
//   PhoneUpdateResult({
//     required this.success,
//     required this.message,
//     this.errorType,
//     this.data,
//   });
// }
//
// /// Types d'erreurs possibles lors de la mise à jour du téléphone
// enum PhoneUpdateErrorType {
//   validation,      // Erreur de validation (format incorrect, etc.)
//   authentication,  // Problème d'authentification
//   authorization,   // Problème d'autorisation
//   conflict,        // Numéro déjà utilisé (pas utilisé par cette API)
//   notFound,        // Utilisateur non trouvé
//   network,         // Erreur réseau
//   server,          // Erreur serveur
//   unknown,         // Erreur inconnue
// }
//
