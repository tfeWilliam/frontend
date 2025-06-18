////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//         SERVICE DE RÉCUPÉRATION DES DONNÉES UTILISATEUR (MULTI-STRATÉGIE)    //
//                                                                            //
//  Ce fichier définit un service avancé pour récupérer les profils complets  //
//  des utilisateurs (`CurrentUser`). Il est conçu pour être résilient et    //
//  performant en employant plusieurs stratégies de récupération de données,   //
//  ainsi qu'un système de cache.                                             //
//                                                                            //
//  Fonctionnalités Clés :                                                    //
//  - Stratégie de Fallback : Tente de récupérer les données via des          //
//    endpoints authentifiés, puis non-authentifiés, puis spécialisés.        //
//  - Gestion du Cache : Un cache en mémoire simple pour éviter les appels    //
//    réseau répétitifs pour un même utilisateur.                             //
//  - Refresh de Token : Gère automatiquement le rafraîchissement des jetons  //
//    d'authentification en cas d'expiration (status 401).                    //
//  - Parsing Robuste : Une fonction de parsing peut gérer plusieurs          //
//    structures de réponse JSON différentes de l'API.                        //
//  - Intégration Firebase RTDB : Une fonction pour extraire des UUIDs depuis //
//    la Realtime Database.                                                   //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:hairbnb/models/current_user.dart';
import 'package:hairbnb/services/firebase_token/token_service.dart';

/// Cache simple en mémoire pour stocker les objets CurrentUser déjà récupérés.
/// La clé est l'UUID de l'utilisateur.
Map<String, CurrentUser?> _usersCache = {};

/// L'URL de base pour toutes les requêtes API.
final String baseUrl = "https://www.hairbnb.site";

/// Fonction principale pour récupérer les données complètes d'un autre utilisateur.
///
/// Orchestre une série de tentatives de récupération avec différentes stratégies
/// pour maximiser les chances de succès.
///
/// [otherUserId] : L'UUID de l'utilisateur à récupérer.
///
/// Retourne un objet `CurrentUser` si trouvé, sinon `null`.
Future<CurrentUser?> fetchOtherUserComplete(String otherUserId) async {
  if (kDebugMode) print("🔍 [fetchOtherUserComplete] Recherche UUID: $otherUserId");

  // Stratégie 1 : Vérifier le cache d'abord pour une performance optimale.
  if (_usersCache.containsKey(otherUserId)) {
    if (kDebugMode) print("✅ [fetchOtherUserComplete] Trouvé dans le cache");
    return _usersCache[otherUserId];
  }

  CurrentUser? user;

  // Stratégie 2 : Tenter la récupération via des endpoints sécurisés avec authentification.
  user = await _fetchWithAuthentication(otherUserId);

  // Stratégie 3 (Fallback) : Si échec, tenter via un endpoint public sans authentification.
  user ??= await _fetchWithoutAuthentication(otherUserId);

  // Stratégie 4 (Fallback) : Si échec, tenter via un endpoint spécialisé pour les coiffeuses.
  user ??= await _fetchFromCoiffeusesEndpoint(otherUserId);

  // Met en cache le résultat (même s'il est nul) pour éviter de refaire les mêmes requêtes.
  _usersCache[otherUserId] = user;

  if (user != null && kDebugMode) {
    if (kDebugMode) {
      print("✅ [fetchOtherUserComplete] Utilisateur récupéré: ${user.prenom} ${user.nom}");
    }
  } else if (kDebugMode) {
    print("❌ [fetchOtherUserComplete] Impossible de récupérer l'utilisateur");
  }

  return user;
}

/// STRATÉGIE 1: Tente de récupérer un utilisateur en utilisant plusieurs endpoints authentifiés.
/// Gère également le rafraîchissement automatique du token en cas d'expiration.
Future<CurrentUser?> _fetchWithAuthentication(String otherUserId) async {
  try {
    // Récupère le jeton d'authentification via le service dédié.
    final token = await TokenService.getAuthToken();
    if (token == null) {
      if (kDebugMode) print("❌ [_fetchWithAuthentication] Aucun token disponible");
      return null;
    }
    if (kDebugMode) print("🔑 [_fetchWithAuthentication] Token récupéré");

    // Liste des endpoints à essayer en séquence.
    final endpoints = [
      '/api/get_user_by_uuid/$otherUserId/',
      '/api/get_current_user/$otherUserId/',
      '/api/user_profile/$otherUserId/',
    ];

    for (String endpoint in endpoints) {
      try {
        final url = '$baseUrl$endpoint';
        if (kDebugMode) print("🌐 [_fetchWithAuthentication] Test: $endpoint");

        final response = await http.get(
          Uri.parse(url),
          headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = json.decode(utf8.decode(response.bodyBytes));
          CurrentUser? user = _parseUserFromJson(data);
          if (user != null) {
            if (kDebugMode) print("✅ [_fetchWithAuthentication] Succès avec $endpoint");
            return user;
          }
        }
        // Gère le cas où le token est expiré.
        else if (response.statusCode == 401) {
          if (kDebugMode) print("❌ [_fetchWithAuthentication] Token expiré, refresh...");
          // Force le rafraîchissement du token.
          final newToken = await TokenService.getAuthToken(forceRefresh: true);
          if (newToken != null) {
            // Réessaie la requête une seule fois avec le nouveau token.
            final retryResponse = await http.get(
              Uri.parse(url),
              headers: {'Authorization': 'Bearer $newToken', 'Content-Type': 'application/json'},
            ).timeout(const Duration(seconds: 10));

            if (retryResponse.statusCode == 200) {
              final data = json.decode(utf8.decode(retryResponse.bodyBytes));
              CurrentUser? user = _parseUserFromJson(data);
              if (user != null) {
                if (kDebugMode) print("✅ [_fetchWithAuthentication] Succès après refresh");
                return user;
              }
            }
          }
        }
      } catch (e) {
        // Si un endpoint échoue, on passe au suivant sans arrêter le processus.
        if (kDebugMode) print("❌ [_fetchWithAuthentication] Erreur sur $endpoint: $e");
        continue;
      }
    }
  } catch (e) {
    if (kDebugMode) print("❌ [_fetchWithAuthentication] Erreur générale: $e");
  }
  return null;
}

/// STRATÉGIE 2 (FALLBACK): Tente de récupérer un utilisateur via un endpoint public.
Future<CurrentUser?> _fetchWithoutAuthentication(String otherUserId) async {
  try {
    if (kDebugMode) print("🔄 [_fetchWithoutAuthentication] Tentative sans auth");
    final url = '$baseUrl/api/get_current_user/$otherUserId/';
    final response = await http.get(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      CurrentUser? user = _parseUserFromJson(data);
      if (user != null) {
        if (kDebugMode) print("✅ [_fetchWithoutAuthentication] Succès sans auth");
        return user;
      }
    } else {
      if (kDebugMode) print("❌ [_fetchWithoutAuthentication] Status ${response.statusCode}");
    }
  } catch (e) {
    if (kDebugMode) print("❌ [_fetchWithoutAuthentication] Erreur: $e");
  }
  return null;
}

/// STRATÉGIE 3 (FALLBACK): Tente de récupérer un utilisateur via un endpoint spécialisé pour les coiffeuses.
Future<CurrentUser?> _fetchFromCoiffeusesEndpoint(String otherUserId) async {
  try {
    if (kDebugMode) print("🔄 [_fetchFromCoiffeusesEndpoint] Tentative endpoint coiffeuses");
    final response = await http.post(
      Uri.parse('$baseUrl/api/get_coiffeuses_info/'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"uuids": [otherUserId]}),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData["status"] == "success" && jsonData["coiffeuses"] is List) {
        for (var coiffeuseData in jsonData["coiffeuses"]) {
          if (coiffeuseData['uuid'] == otherUserId) {
            // Transforme manuellement la structure "coiffeuse" en une structure "user"
            // que le parser `CurrentUser.fromJson` peut comprendre.
            final userData = {
              'idTblUser': coiffeuseData['idTblUser'] ?? 0,
              'uuid': coiffeuseData['uuid'], 'nom': coiffeuseData['nom'] ?? '', 'prenom': coiffeuseData['prenom'] ?? '',
              'email': coiffeuseData['email'] ?? '', 'numero_telephone': coiffeuseData['numero_telephone'], 'date_naissance': coiffeuseData['date_naissance'],
              'is_active': coiffeuseData['is_active'] ?? true, 'photo_profil': coiffeuseData['photo_profil'], 'type': 'coiffeuse',
            };
            CurrentUser? user = _parseUserFromJson({'user': userData});
            if (user != null) {
              if (kDebugMode) print("✅ [_fetchFromCoiffeusesEndpoint] Coiffeuse trouvée");
              return user;
            }
          }
        }
      }
    }
  } catch (e) {
    if (kDebugMode) print("❌ [_fetchFromCoiffeusesEndpoint] Erreur: $e");
  }
  return null;
}

/// Fonction utilitaire pour parser un JSON en objet `CurrentUser`.
///
/// Elle est capable de gérer plusieurs structures de JSON différentes
/// retournées par l'API pour une meilleure robustesse.
CurrentUser? _parseUserFromJson(Map<String, dynamic> data) {
  try {
    if (data['user'] != null) {
      // Structure la plus courante: {"user": {...}}
      return CurrentUser.fromJson(data['user']);
    } else if (data['data'] != null && data['success'] == true) {
      // Structure alternative: {"success": true, "data": {...}}
      return CurrentUser.fromJson(data['data']);
    } else if (data['uuid'] != null) {
      // Structure directe où l'objet est à la racine.
      return CurrentUser.fromJson(data);
    }
    return null;
  } catch (e) {
    if (kDebugMode) print("❌ [_parseUserFromJson] Erreur parsing: $e");
    return null;
  }
}

/// Fonction legacy pour la compatibilité ascendante. Appelle simplement la nouvelle fonction principale.
Future<CurrentUser?> fetchOtherUser(String otherUserId) async {
  return await fetchOtherUserComplete(otherUserId);
}

/// Vide complètement le cache des utilisateurs.
void clearUserCache() {
  _usersCache.clear();
  if (kDebugMode) print("🧹 [clearUserCache] Cache vidé");
}

/// Force le rechargement des données d'un utilisateur spécifique en vidant
/// son entrée de cache avant de lancer une nouvelle récupération.
Future<CurrentUser?> forceRefreshUser(String otherUserId) async {
  _usersCache.remove(otherUserId);
  return await fetchOtherUserComplete(otherUserId);
}

/// Récupère depuis la Firebase Realtime Database tous les UUIDs des coiffeuses
/// avec qui un utilisateur donné a eu une conversation.
Future<List<String>> fetchCoiffeusesUUIDsFromFirebase(String userUuid) async {
  final databaseRef = FirebaseDatabase.instance.ref();
  List<String> coiffeusesUUIDs = [];

  try {
    if (kDebugMode) print("🔍 [fetchCoiffeusesUUIDsFromFirebase] Recherche pour: $userUuid");
    final snapshot = await databaseRef.get();

    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>? ?? {};
      // Les clés de la base de données sont sous la forme "uuid1_uuid2".
      for (var entry in data.entries) {
        final participants = entry.key.split("_");
        if (participants.contains(userUuid)) {
          // Extrait l'UUID qui n'est pas celui de l'utilisateur actuel.
          final otherUserId = participants[0] == userUuid ? participants[1] : participants[0];
          if (!coiffeusesUUIDs.contains(otherUserId)) {
            coiffeusesUUIDs.add(otherUserId);
          }
        }
      }
      if (kDebugMode) print("✅ [fetchCoiffeusesUUIDsFromFirebase] ${coiffeusesUUIDs.length} trouvées");
    } else {
      if (kDebugMode) print("❌ [fetchCoiffeusesUUIDsFromFirebase] Aucune donnée Firebase");
    }
  } catch (error) {
    if (kDebugMode) print("❌ [fetchCoiffeusesUUIDsFromFirebase] Erreur: $error");
  }

  return coiffeusesUUIDs;
}













// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:http/http.dart' as http;
// import 'package:hairbnb/models/current_user.dart';
// import 'package:hairbnb/services/firebase_token/token_service.dart';
//
// // Cache simple pour éviter les appels répétés
// Map<String, CurrentUser?> _usersCache = {};
//
// final String baseUrl = "https://www.hairbnb.site";
//
// /// Fonction principale pour récupérer un autre utilisateur
// /// Utilise TokenService pour l'authentification
// Future<CurrentUser?> fetchOtherUserComplete(String otherUserId) async {
//   if (kDebugMode) {
//     print("🔍 [fetchOtherUserComplete] Recherche UUID: $otherUserId");
//   }
//
//   // Vérifier le cache
//   if (_usersCache.containsKey(otherUserId)) {
//     if (kDebugMode) {
//       print("✅ [fetchOtherUserComplete] Trouvé dans le cache");
//     }
//     return _usersCache[otherUserId];
//   }
//
//   CurrentUser? user;
//
//   user = await _fetchWithAuthentication(otherUserId);
//
//   // Stratégie 2: Fallback sans auth
//   user ??= await _fetchWithoutAuthentication(otherUserId);
//
//   // Stratégie 3: Endpoint coiffeuses spécialisé
//   user ??= await _fetchFromCoiffeusesEndpoint(otherUserId);
//
//   // Mettre en cache
//   _usersCache[otherUserId] = user;
//
//   if (user != null && kDebugMode) {
//     if (kDebugMode) {
//       print("✅ [fetchOtherUserComplete] Utilisateur récupéré: ${user.prenom} ${user.nom}");
//     }
//   } else if (kDebugMode) {
//     print("❌ [fetchOtherUserComplete] Impossible de récupérer l'utilisateur");
//   }
//
//   return user;
// }
//
// /// Récupération avec authentification via TokenService
// Future<CurrentUser?> _fetchWithAuthentication(String otherUserId) async {
//   try {
//     // Utiliser TokenService pour récupérer le token
//     final token = await TokenService.getAuthToken();
//
//     if (token == null) {
//       if (kDebugMode) {
//         print("❌ [_fetchWithAuthentication] Aucun token disponible");
//       }
//       return null;
//     }
//
//     if (kDebugMode) {
//       print("🔑 [_fetchWithAuthentication] Token récupéré");
//     }
//
//     final endpoints = [
//       '/api/get_user_by_uuid/$otherUserId/',
//       '/api/get_current_user/$otherUserId/',
//       '/api/user_profile/$otherUserId/',
//     ];
//
//     for (String endpoint in endpoints) {
//       try {
//         final url = '$baseUrl$endpoint';
//
//         if (kDebugMode) {
//           print("🌐 [_fetchWithAuthentication] Test: $endpoint");
//         }
//
//         final response = await http.get(
//           Uri.parse(url),
//           headers: {
//             'Authorization': 'Bearer $token',
//             'Content-Type': 'application/json',
//           },
//         ).timeout(Duration(seconds: 10));
//
//         if (response.statusCode == 200) {
//           final decodedBody = utf8.decode(response.bodyBytes);
//           final data = json.decode(decodedBody);
//
//           CurrentUser? user = _parseUserFromJson(data);
//           if (user != null) {
//             if (kDebugMode) {
//               print("✅ [_fetchWithAuthentication] Succès avec $endpoint");
//             }
//             return user;
//           }
//         } else if (response.statusCode == 401) {
//           if (kDebugMode) {
//             print("❌ [_fetchWithAuthentication] Token expiré, refresh...");
//           }
//           // Utiliser TokenService pour forcer le refresh
//           final newToken = await TokenService.getAuthToken(forceRefresh: true);
//           if (newToken != null) {
//             // Réessayer avec le nouveau token
//             final retryResponse = await http.get(
//               Uri.parse(url),
//               headers: {
//                 'Authorization': 'Bearer $newToken',
//                 'Content-Type': 'application/json',
//               },
//             ).timeout(Duration(seconds: 10));
//
//             if (retryResponse.statusCode == 200) {
//               final decodedBody = utf8.decode(retryResponse.bodyBytes);
//               final data = json.decode(decodedBody);
//               CurrentUser? user = _parseUserFromJson(data);
//               if (user != null) {
//                 if (kDebugMode) {
//                   print("✅ [_fetchWithAuthentication] Succès après refresh");
//                 }
//                 return user;
//               }
//             }
//           }
//         }
//       } catch (e) {
//         if (kDebugMode) {
//           print("❌ [_fetchWithAuthentication] Erreur $endpoint: $e");
//         }
//         continue;
//       }
//     }
//   } catch (e) {
//     if (kDebugMode) {
//       print("❌ [_fetchWithAuthentication] Erreur générale: $e");
//     }
//   }
//
//   return null;
// }
//
// /// Récupération sans authentification (fallback)
// Future<CurrentUser?> _fetchWithoutAuthentication(String otherUserId) async {
//   try {
//     if (kDebugMode) {
//       print("🔄 [_fetchWithoutAuthentication] Tentative sans auth");
//     }
//
//     final url = '$baseUrl/api/get_current_user/$otherUserId/';
//     final response = await http.get(
//       Uri.parse(url),
//       headers: {'Content-Type': 'application/json'},
//     ).timeout(Duration(seconds: 10));
//
//     if (response.statusCode == 200) {
//       final decodedBody = utf8.decode(response.bodyBytes);
//       final data = json.decode(decodedBody);
//
//       CurrentUser? user = _parseUserFromJson(data);
//       if (user != null) {
//         if (kDebugMode) {
//           print("✅ [_fetchWithoutAuthentication] Succès sans auth");
//         }
//         return user;
//       }
//     } else {
//       if (kDebugMode) {
//         print("❌ [_fetchWithoutAuthentication] Status ${response.statusCode}");
//       }
//     }
//   } catch (e) {
//     if (kDebugMode) {
//       print("❌ [_fetchWithoutAuthentication] Erreur: $e");
//     }
//   }
//
//   return null;
// }
//
// /// Récupération via l'endpoint coiffeuses
// Future<CurrentUser?> _fetchFromCoiffeusesEndpoint(String otherUserId) async {
//   try {
//     if (kDebugMode) {
//       print("🔄 [_fetchFromCoiffeusesEndpoint] Tentative endpoint coiffeuses");
//     }
//
//     final response = await http.post(
//       Uri.parse('$baseUrl/api/get_coiffeuses_info/'),
//       headers: {"Content-Type": "application/json"},
//       body: jsonEncode({"uuids": [otherUserId]}),
//     ).timeout(Duration(seconds: 10));
//
//     if (response.statusCode == 200) {
//       final jsonData = jsonDecode(response.body);
//
//       if (jsonData["status"] == "success" && jsonData["coiffeuses"] is List) {
//         for (var coiffeuseData in jsonData["coiffeuses"]) {
//           if (coiffeuseData['uuid'] == otherUserId) {
//             // Transformer les données coiffeuse en CurrentUser
//             final userData = {
//               'idTblUser': coiffeuseData['idTblUser'] ?? 0,
//               'uuid': coiffeuseData['uuid'],
//               'nom': coiffeuseData['nom'] ?? '',
//               'prenom': coiffeuseData['prenom'] ?? '',
//               'email': coiffeuseData['email'] ?? '',
//               'numero_telephone': coiffeuseData['numero_telephone'],
//               'date_naissance': coiffeuseData['date_naissance'],
//               'is_active': coiffeuseData['is_active'] ?? true,
//               'photo_profil': coiffeuseData['photo_profil'],
//               'type': 'coiffeuse',
//             };
//
//             CurrentUser? user = _parseUserFromJson({'user': userData});
//             if (user != null) {
//               if (kDebugMode) {
//                 print("✅ [_fetchFromCoiffeusesEndpoint] Coiffeuse trouvée");
//               }
//               return user;
//             }
//           }
//         }
//       }
//     }
//   } catch (e) {
//     if (kDebugMode) {
//       print("❌ [_fetchFromCoiffeusesEndpoint] Erreur: $e");
//     }
//   }
//
//   return null;
// }
//
// /// Parser les données JSON en CurrentUser
// CurrentUser? _parseUserFromJson(Map<String, dynamic> data) {
//   try {
//     CurrentUser? user;
//
//     if (data['user'] != null) {
//       // Structure: {"user": {...}}
//       user = CurrentUser.fromJson(data['user']);
//     } else if (data['data'] != null && data['success'] == true) {
//       // Structure: {"success": true, "data": {...}}
//       user = CurrentUser.fromJson(data['data']);
//     } else if (data['uuid'] != null) {
//       // Structure directe: {...}
//       user = CurrentUser.fromJson(data);
//     }
//
//     return user;
//   } catch (e) {
//     if (kDebugMode) {
//       print("❌ [_parseUserFromJson] Erreur parsing: $e");
//     }
//     return null;
//   }
// }
//
// /// Fonction legacy pour compatibilité
// Future<CurrentUser?> fetchOtherUser(String otherUserId) async {
//   return await fetchOtherUserComplete(otherUserId);
// }
//
// /// Vider le cache
// void clearUserCache() {
//   _usersCache.clear();
//   if (kDebugMode) {
//     print("🧹 [clearUserCache] Cache vidé");
//   }
// }
//
// /// Forcer le rechargement d'un utilisateur
// Future<CurrentUser?> forceRefreshUser(String otherUserId) async {
//   _usersCache.remove(otherUserId);
//   return await fetchOtherUserComplete(otherUserId);
// }
//
// /// Récupérer les UUIDs des conversations depuis Firebase
// Future<List<String>> fetchCoiffeusesUUIDsFromFirebase(String userUuid) async {
//   final databaseRef = FirebaseDatabase.instance.ref();
//   List<String> coiffeusesUUIDs = [];
//
//   try {
//     if (kDebugMode) {
//       print("🔍 [fetchCoiffeusesUUIDsFromFirebase] Recherche pour: $userUuid");
//     }
//
//     final snapshot = await databaseRef.get();
//
//     if (snapshot.exists) {
//       final data = snapshot.value as Map<dynamic, dynamic>? ?? {};
//
//       for (var entry in data.entries) {
//         final participants = entry.key.split("_");
//         if (participants.contains(userUuid)) {
//           final otherUserId = participants[0] == userUuid ? participants[1] : participants[0];
//           if (!coiffeusesUUIDs.contains(otherUserId)) {
//             coiffeusesUUIDs.add(otherUserId);
//           }
//         }
//       }
//
//       if (kDebugMode) {
//         print("✅ [fetchCoiffeusesUUIDsFromFirebase] ${coiffeusesUUIDs.length} trouvées");
//       }
//     } else {
//       if (kDebugMode) {
//         print("❌ [fetchCoiffeusesUUIDsFromFirebase] Aucune donnée Firebase");
//       }
//     }
//   } catch (error) {
//     if (kDebugMode) {
//       print("❌ [fetchCoiffeusesUUIDsFromFirebase] Erreur: $error");
//     }
//   }
//
//   return coiffeusesUUIDs;
// }
