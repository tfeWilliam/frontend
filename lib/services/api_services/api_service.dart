/// *************************************************************************************************
/// *
/// BANNIÈRE : SERVICE DE CONFIGURATION DES APPELS API                                              *
/// --------------------------------------------------                                              *
/// *
/// OBJECTIF :                                                                                      *
/// Ce fichier définit la classe `APIService`, qui a pour rôle de centraliser et de standardiser    *
/// la configuration des appels vers l'API backend du projet. Elle fournit des méthodes et          *
/// des propriétés statiques pour simplifier la création des requêtes HTTP dans toute               *
/// l'application.                                                                                  *
/// *
/// FONCTIONNALITÉS PRINCIPales :                                                                   *
/// 1. URL DE BASE : Définit une constante `baseURL` pour l'API, évitant la duplication et          *
/// facilitant les mises à jour.                                                                 *
/// 2. GESTION DES EN-TÊTES (HEADERS) : Propose plusieurs getters pour construire les en-têtes      *
/// HTTP adaptés à différents contextes :                                                        *
/// - `headers` : Pour les requêtes nécessitant une authentification (inclut le token JWT).     *
/// - `headersPublic` : Pour les requêtes publiques qui n'ont pas besoin de token.               *
/// - `headersBasic` : Pour des cas très simples nécessitant uniquement le 'Content-Type'.        *
/// *
/// 3. INCLUSION D'INFORMATIONS : Ajoute automatiquement la version de l'application dans les        *
/// en-têtes pour le suivi et le débogage côté serveur.                                          *
/// *
///*************************************************************************************************
library;

import 'package:package_info_plus/package_info_plus.dart';

// Importation du service responsable de la gestion du token d'authentification.
import '../firebase_token/token_service.dart';


/// Classe utilitaire qui centralise les configurations pour les appels API.
class APIService {

  /// L'URL de base pour toutes les requêtes dirigées vers l'API HairBNB.
  static const String baseURL = 'https://www.hairbnb.site/api';

  /// Construit les en-têtes HTTP pour les requêtes qui nécessitent une **authentification**.
  ///
  /// Cette méthode asynchrone récupère la version de l'application et le token
  /// d'authentification (JWT) pour les inclure dans les en-têtes.
  static Future<Map<String, String>> get headers async {
    // Obtient les informations du package de l'application, comme le numéro de version.
    final packageInfo = await PackageInfo.fromPlatform();
    // Récupère le token d'authentification de l'utilisateur.
    final token = await TokenService.getAuthToken();

    // Crée le dictionnaire de base pour les en-têtes.
    final baseHeaders = {
      'Content-Type': 'application/json',
      'X-App-Version': packageInfo.version,
    };

    // Ajoute l'en-tête d'autorisation seulement si un token valide est disponible.
    if (token != null && token.isNotEmpty) {
      baseHeaders['Authorization'] = 'Bearer $token';
    }

    return baseHeaders;
  }

  /// Construit les en-têtes HTTP pour les requêtes **publiques** (sans authentification).
  ///
  /// Utile pour les points d'API accessibles à tous (ex: connexion, création de compte).
  static Future<Map<String, String>> get headersPublic async {
    // Récupère les informations du package pour la version de l'application.
    final packageInfo = await PackageInfo.fromPlatform();

    // Retourne les en-têtes sans le token d'autorisation.
    return {
      'Content-Type': 'application/json',
      'X-App-Version': packageInfo.version,
    };
  }

  /// Retourne un dictionnaire d'en-têtes minimal de manière synchrone.
  ///
  /// À utiliser dans les cas simples où seule la spécification du 'Content-Type' est requise,
  /// sans avoir besoin d'opérations asynchrones.
  static Map<String, String> get headersBasic => {
    'Content-Type': 'application/json',
  };
}





// // lib/services/api_service.dart
//
// //==============================================================================
// // SERVICE DE CONFIGURATION DES APPELS API
// //------------------------------------------------------------------------------
// // Ce fichier définit la classe `APIService`, qui centralise la configuration
// // nécessaire pour communiquer avec l'API backend du projet HairBNB.
// //
// // Rôles principaux :
// // 1. Fournir l'URL de base de l'API.
// // 2. Construire dynamiquement les en-têtes (headers) HTTP pour les requêtes.
// // 3. Gérer différents types d'en-têtes :
// //    - `headers` : Pour les requêtes authentifiées (avec token JWT).
// //    - `headersPublic` : Pour les requêtes publiques (sans token).
// //    - `headersBasic` : Pour les cas les plus simples.
// //
// // L'utilisation de ce service garantit que toutes les requêtes API sont
// // cohérentes et incluent des informations importantes comme la version de
// // l'application et le token d'authentification lorsque nécessaire.
// //==============================================================================
//
// import 'package:package_info_plus/package_info_plus.dart';
//
// // Service pour la gestion du token d'authentification.
// import '../firebase_token/token_service.dart';
//
//
// /// Fournit des configurations centralisées pour les appels à l'API.
// class APIService {
//
//   /// L'URL de base pour toutes les requêtes de l'API HairBNB.
//   static const String baseURL = 'https://www.hairbnb.site/api';
//
//   /// Construit et retourne les en-têtes HTTP pour les requêtes **authentifiées**.
//   ///
//   /// Cette méthode asynchrone récupère la version de l'application et le
//   /// token d'authentification pour les inclure dans les en-têtes.
//   /// Le token n'est ajouté que s'il est disponible.
//   static Future<Map<String, String>> get headers async {
//     // Récupère les informations du package de l'application (version, etc.).
//     final packageInfo = await PackageInfo.fromPlatform();
//     // Récupère le token d'authentification stocké localement.
//     final token = await TokenService.getAuthToken();
//
//     // Crée une base d'en-têtes commune à la plupart des requêtes.
//     final baseHeaders = {
//       'Content-Type': 'application/json',
//       'X-App-Version': packageInfo.version,
//     };
//
//     // Ajoute l'en-tête 'Authorization' conditionnellement.
//     // Il n'est inclus que si un token valide a été trouvé.
//     if (token != null && token.isNotEmpty) {
//       baseHeaders['Authorization'] = 'Bearer $token';
//     }
//
//     return baseHeaders;
//   }
//
//   /// Construit et retourne les en-têtes HTTP pour les requêtes **publiques**.
//   ///
//   /// Similaire à `headers`, mais n'inclut jamais le token d'authentification.
//   /// Idéal pour les points d'API qui ne nécessitent pas de connexion (ex: login, signup).
//   static Future<Map<String, String>> get headersPublic async {
//     // Récupère les informations du package pour la version de l'application.
//     final packageInfo = await PackageInfo.fromPlatform();
//
//     return {
//       'Content-Type': 'application/json',
//       'X-App-Version': packageInfo.version,
//     };
//   }
//
//   /// Retourne un dictionnaire d'en-têtes de base de manière synchrone.
//   ///
//   /// Utile pour les cas simples où seule la définition du type de contenu
//   /// est nécessaire et où une opération asynchrone n'est pas souhaitable.
//   static Map<String, String> get headersBasic => {
//     'Content-Type': 'application/json',
//   };
// }