/// *************************************************************************************************
///
/// BANNER : EXPLICATION GÉNÉRALE DE LA CLASSE API
///
/// Ce fichier définit la classe `ServicesApiService`.
///
/// Objectif :
/// Cette classe sert de couche de service (ou "couche d'accès aux données") dédiée à toutes
/// les interactions avec l'API backend concernant les services et leurs catégories. Elle
/// centralise et abstrait la complexité des appels HTTP (GET, POST, PUT, DELETE).
///
/// Fonctionnalités :
/// - Gère l'authentification des requêtes en récupérant et en ajoutant automatiquement
/// un token d'authentification Firebase.
/// - Récupère la liste globale des catégories de services.
/// - Récupère les services spécifiques à une catégorie ou à un salon.
/// - Gère l'ajout, la modification et la suppression de services pour le profil d'une coiffeuse.
/// - Gère les erreurs de manière structurée en levant des exceptions ou en retournant
/// des données vides en cas d'échec.
///
/// Utilisation :
/// La classe est composée exclusivement de méthodes statiques, ce qui signifie qu'il n'est
/// pas nécessaire de l'instancier. On appelle ses méthodes directement depuis d'autres
/// parties de l'application (généralement depuis une couche de logique métier ou un Provider),
/// par exemple : `ServicesApiService.chargerCategories();`.
///
///*************************************************************************************************
library;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../../../models/categorie.dart';
import '../../../../../../models/services.dart';

/// Classe statique pour tous les appels API liés aux services.
class ServicesApiService {
  /// L'URL de base pour toutes les requêtes de cette API.
  static const String baseUrl = 'https://www.hairbnb.site/api';

  /// Méthode privée pour récupérer le token d'identification Firebase de l'utilisateur actuel.
  ///
  /// Retourne le token sous forme de `String` si l'utilisateur est connecté, sinon `null`.
  /// Ce token est essentiel pour authentifier les requêtes auprès du backend.
  static Future<String?> _obtenirTokenFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Demande à Firebase de générer ou de rafraîchir le token d'ID.
        final token = await user.getIdToken();
        return token;
      } else {
        // Aucun utilisateur connecté.
        return null;
      }
    } catch (e) {
      // Gère les erreurs potentielles lors de la récupération du token.
      return null;
    }
  }

  /// Charge la liste complète des catégories de services depuis l'API.
  ///
  /// Lève une exception en cas d'erreur (token manquant, erreur serveur, etc.).
  /// Retourne une `List<Categorie>` en cas de succès.
  static Future<List<Categorie>> chargerCategories() async {
    try {
      final token = await _obtenirTokenFirebase();
      if (token == null) {
        throw Exception('Token Firebase manquant - Utilisateur non connecté');
      }

      // Effectue l'appel GET à l'endpoint des catégories.
      final response = await http.get(
        Uri.parse('$baseUrl/categories/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Ajoute le token pour l'authentification.
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Vérifie le statut de la réponse de notre API personnalisée.
        if (data['status'] == 'success') {
          final categoriesJson = data['categories'] as List;
          if (kDebugMode) print("Catégories JSON reçues: $categoriesJson");

          // Convertit chaque objet JSON en un objet Dart `Categorie`.
          List<Categorie> categoriesConverties = [];
          for (final categorieJson in categoriesJson) {
            final categorie = Categorie.fromJson(categorieJson);
            categoriesConverties.add(categorie);
          }

          if (kDebugMode) print("Catégories finales converties: ${categoriesConverties.length} catégories");
          return categoriesConverties;
        } else {
          throw Exception(data['message'] ?? 'Erreur lors du chargement des catégories');
        }
      } else if (response.statusCode == 401) {
        // Gère spécifiquement les erreurs d'authentification.
        throw Exception('Non autorisé - Token Firebase invalide ou expiré');
      } else {
        // Gère toutes les autres erreurs HTTP.
        throw Exception('Erreur serveur: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      // Capture et logue toute exception pour faciliter le débogage.
      if (kDebugMode) print("ERREUR lors du chargement des catégories: $e");
      // Fait remonter l'exception pour que la couche supérieure puisse la gérer.
      rethrow;
    }
  }

  /// Charge les services associés à une catégorie spécifique.
  ///
  /// [categorieId] : L'identifiant de la catégorie pour laquelle charger les services.
  /// Retourne une `List<Service>` ou une liste vide en cas d'erreur.
  static Future<List<Service>> chargerServicesPourCategorie(int categorieId) async {
    try {
      final token = await _obtenirTokenFirebase();
      if (token == null) {
        if (kDebugMode) print("Token manquant pour charger les services de la catégorie $categorieId");
        return [];
      }

      if (kDebugMode) print("Appel API pour les services de la catégorie $categorieId");
      final response = await http.get(
        Uri.parse('$baseUrl/categories/$categorieId/services/'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final servicesJson = data['services'] as List;
          final services = servicesJson.map((json) => Service.fromJson(json)).toList();
          if (kDebugMode) print(" ${services.length} services chargés pour la catégorie $categorieId");
          return services;
        }
      } else {
        if (kDebugMode) print(" Erreur de chargement des services pour la catégorie $categorieId: ${response.statusCode}");
      }
      return []; // Retourne une liste vide en cas d'échec pour ne pas bloquer l'UI.
    } catch (e) {
      if (kDebugMode) print(' Exception lors du chargement des services de la catégorie $categorieId: $e');
      return [];
    }
  }

  /// Charge les services qu'une coiffeuse a ajoutés à son propre profil.
  ///
  /// Cette méthode tente plusieurs URLs possibles pour une meilleure compatibilité avec l'API.
  /// [userId] : L'ID de l'utilisateur (coiffeuse) dont on veut les services.
  static Future<List<Service>> chargerServicesAjoutes(int userId) async {
    try {
      final token = await _obtenirTokenFirebase();
      if (token == null) {
        if (kDebugMode) print(" Token manquant pour charger les services ajoutés");
        return [];
      }
      if (kDebugMode) print(" Chargement des services ajoutés pour l'utilisateur $userId");

      // Liste d'URLs à essayer pour trouver le bon endpoint.
      List<String> urlsAEssayer = [
        '$baseUrl/users/$userId/services/',
        '$baseUrl/services/user/$userId/',
        '$baseUrl/user-services/$userId/',
        '$baseUrl/my-services/',
      ];

      for (String url in urlsAEssayer) {
        if (kDebugMode) print("🔄 Tentative avec l'URL: $url");
        final response = await http.get(Uri.parse(url), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'});

        if (response.statusCode == 200) {
          try {
            final data = json.decode(response.body);
            List<dynamic>? servicesJson;

            // Tente de parser différents formats de réponse JSON possibles.
            if (data is Map<String, dynamic>) {
              if (data.containsKey('status') && data['status'] == 'success') {
                servicesJson = data['services'] as List?;
              } else if (data.containsKey('data')) servicesJson = data['data'] as List?;
              else if (data.containsKey('results')) servicesJson = data['results'] as List?;
              else if (data.containsKey('userServices')) servicesJson = data['userServices'] as List?;
            } else if (data is List) {
              servicesJson = data;
            }

            if (servicesJson != null) {
              if (kDebugMode) print("Services JSON trouvés: $servicesJson");
              final services = servicesJson.map((json) => Service.fromJson(json)).toList();
              if (kDebugMode) print("${services.length} services ajoutés récupérés avec succès !");
              return services; // Retourne les services dès qu'une URL fonctionne.
            }
          } catch (e) {
            if (kDebugMode) print(" Erreur de parsing JSON pour l'URL $url: $e");
            continue; // Si le parsing échoue, essaie l'URL suivante.
          }
        }
      }
      if (kDebugMode) print(" Aucune URL n'a fonctionné pour récupérer les services ajoutés.");
      return [];
    } catch (e) {
      if (kDebugMode) print(' Exception lors du chargement des services ajoutés: $e');
      return [];
    }
  }

  /// Ajoute un service du catalogue général au profil d'une coiffeuse.
  ///
  /// Lève une exception en cas d'erreur.
  static Future<bool> ajouterServiceExistant({
    required int userId, required int serviceId, required int categoryId,
    required double prix, required int tempsMinutes,
  }) async {
    try {
      final token = await _obtenirTokenFirebase();
      if (token == null) throw Exception('Token Firebase manquant');

      if (kDebugMode) print(" Ajout du service ID $serviceId - Prix: $prix€ - Durée: ${tempsMinutes}min");
      final response = await http.post(
        Uri.parse('$baseUrl/services/add-existing/'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: json.encode({'userId': userId, 'service_id': serviceId, 'category_id': categoryId, 'prix': prix, 'temps_minutes': tempsMinutes}),
      );

      if (response.statusCode == 201) {
        if (kDebugMode) print(" Service ajouté avec succès");
        return true;
      } else {
        final errorData = json.decode(response.body);
        throw Exception("Erreur lors de l'ajout du service: ${errorData['message']}");
      }
    } catch (e) {
      if (kDebugMode) print(" Erreur lors de l'ajout du service: $e");
      rethrow;
    }
  }

  /// Ajoute plusieurs services en une seule opération en appelant `ajouterServiceExistant` en boucle.
  ///
  /// Retourne une liste de messages d'erreur (vide si tout réussit).
  static Future<List<String>> ajouterPlusieursServices({required int userId, required List<Map<String, dynamic>> services}) async {
    List<String> erreurs = [];
    for (final serviceData in services) {
      try {
        await ajouterServiceExistant(
          userId: userId, serviceId: serviceData['service_id'], categoryId: serviceData['category_id'],
          prix: serviceData['prix'], tempsMinutes: serviceData['temps_minutes'],
        );
      } catch (e) {
        erreurs.add("Service ${serviceData['service_id']}: $e");
      }
    }
    return erreurs;
  }

  /// Supprime un service du profil d'une coiffeuse.
  static Future<bool> supprimerServiceUtilisateur({required int userId, required int serviceId}) async {
    try {
      final token = await _obtenirTokenFirebase();
      if (token == null) throw Exception('Token Firebase manquant');

      if (kDebugMode) print(" Suppression du service ID $serviceId pour l'utilisateur $userId");
      final response = await http.delete(
        Uri.parse('$baseUrl/users/$userId/services/$serviceId/'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      );

      if (kDebugMode) print(" Réponse de la suppression du service: ${response.statusCode}");
      if (response.statusCode == 200 || response.statusCode == 204) {
        if (kDebugMode) print(" Service supprimé avec succès");
        return true;
      } else {
        throw Exception("Erreur lors de la suppression du service: ${response.statusCode}");
      }
    } catch (e) {
      if (kDebugMode) print(" Erreur lors de la suppression du service: $e");
      rethrow;
    }
  }

  /// Modifie le prix et/ou la durée d'un service pour une coiffeuse.
  static Future<bool> modifierServiceUtilisateur({
    required int userId, required int serviceId,
    required double prix, required int tempsMinutes,
  }) async {
    try {
      final token = await _obtenirTokenFirebase();
      if (token == null) throw Exception('Token Firebase manquant');

      if (kDebugMode) print(" Modification du service ID $serviceId - Prix: $prix€ - Durée: ${tempsMinutes}min");
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId/services/$serviceId/'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: json.encode({'prix': prix, 'temps_minutes': tempsMinutes}),
      );

      if (kDebugMode) print("📡 Réponse de la modification du service: ${response.statusCode}");
      if (response.statusCode == 200) {
        if (kDebugMode) print(" Service modifié avec succès");
        return true;
      } else {
        throw Exception("Erreur lors de la modification du service: ${response.statusCode}");
      }
    } catch (e) {
      if (kDebugMode) print(" Erreur lors de la modification du service: $e");
      rethrow;
    }
  }

  /// Récupère tous les services d'un salon, déjà organisés par catégorie par le backend.
  ///
  /// [salonId] : L'identifiant du salon dont on veut les services.
  /// Retourne une `Map` brute de l'API contenant les données structurées.
  static Future<Map<String, dynamic>> chargerServicesParCategoriePourSalon(int salonId) async {
    try {
      final token = await _obtenirTokenFirebase();
      if (token == null) throw Exception('Token Firebase manquant - Utilisateur non connecté');

      if (kDebugMode) print(" Chargement des services du salon ID: $salonId");
      final response = await http.get(
        Uri.parse('$baseUrl/salon/$salonId/services-by-category/'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          if (kDebugMode) print(" Services du salon récupérés: ${data['total_services']} services au total");
          return data;
        } else {
          throw Exception(data['message'] ?? 'Erreur lors du chargement des services du salon');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Non autorisé - Token Firebase invalide');
      } else {
        throw Exception('Erreur serveur: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) print(" ERREUR lors du chargement des services du salon: $e");
      rethrow;
    }
  }
}










// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:firebase_auth/firebase_auth.dart';
//
// import '../../../../../../models/categorie.dart';
// import '../../../../../../models/services.dart';
//
// class ServicesApiService {
//   static const String baseUrl = 'https://www.hairbnb.site/api';
//
//   /// Récupération du token Firebase
//   static Future<String?> _obtenirTokenFirebase() async {
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user != null) {
//         final token = await user.getIdToken();
//         return token;
//       } else {
//         return null;
//       }
//     } catch (e) {
//       return null;
//     }
//   }
//
//   /// Charger toutes les catégories
//   static Future<List<Categorie>> chargerCategories() async {
//     try {
//       final token = await _obtenirTokenFirebase();
//
//       if (token == null) {
//         throw Exception('Token Firebase manquant - Utilisateur non connecté');
//       }
//
//       final response = await http.get(
//         Uri.parse('$baseUrl/categories/'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//
//         if (data['status'] == 'success') {
//           final categoriesJson = data['categories'] as List;
//           print("📂 CATEGORIES JSON: $categoriesJson");
//
//           // Conversion avec debug individuel
//           List<Categorie> categoriesConverties = [];
//           for (int i = 0; i < categoriesJson.length; i++) {
//             print("🔄 Conversion catégorie $i:");
//             final categorieJson = categoriesJson[i];
//             final categorie = Categorie.fromJson(categorieJson);
//             categoriesConverties.add(categorie);
//             print("🎯 Catégorie $i convertie: ${categorie.toString()}");
//           }
//
//           print("✅ CATEGORIES FINALES: ${categoriesConverties.map((c) => 'ID:${c.id} Nom:${c.nom}').toList()}");
//           return categoriesConverties;
//         } else {
//           throw Exception(data['message'] ?? 'Erreur lors du chargement des catégories');
//         }
//       } else if (response.statusCode == 401) {
//         throw Exception('Non autorisé - Token Firebase invalide');
//       } else {
//         throw Exception('Erreur serveur: ${response.statusCode} - ${response.body}');
//       }
//     } catch (e) {
//       print("❌ ERREUR CATEGORIES: $e");
//       throw e;
//     }
//   }
//
//   /// Charger les services pour une catégorie
//   static Future<List<Service>> chargerServicesPourCategorie(int categorieId) async {
//     try {
//       final token = await _obtenirTokenFirebase();
//       if (token == null) {
//         print("❌ Token manquant pour charger services catégorie $categorieId");
//         return [];
//       }
//
//       print("🔄 Appel API pour catégorie $categorieId");
//       final response = await http.get(
//         Uri.parse('$baseUrl/categories/$categorieId/services/'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data['status'] == 'success') {
//           final servicesJson = data['services'] as List;
//           final services = servicesJson.map((json) => Service.fromJson(json)).toList();
//
//           print("✅ ${services.length} services chargés pour catégorie $categorieId");
//           return services;
//         }
//       } else {
//         print("❌ Erreur chargement services catégorie $categorieId: ${response.statusCode}");
//       }
//       return [];
//     } catch (e) {
//       print('❌ Erreur chargement services catégorie $categorieId: $e');
//       return [];
//     }
//   }
//
//   /// Charger les services ajoutés par un utilisateur
//   static Future<List<Service>> chargerServicesAjoutes(int userId) async {
//     try {
//       final token = await _obtenirTokenFirebase();
//       if (token == null) {
//         print("❌ Token manquant pour charger les services ajoutés");
//         return [];
//       }
//
//       print("🔄 Chargement des services ajoutés pour l'utilisateur $userId");
//
//       // Essayons plusieurs URLs possibles
//       List<String> urlsAEssayer = [
//         '$baseUrl/users/$userId/services/',
//         '$baseUrl/services/user/$userId/',
//         '$baseUrl/user-services/$userId/',
//         '$baseUrl/my-services/',
//       ];
//
//       for (String url in urlsAEssayer) {
//         print("🔄 Tentative avec URL: $url");
//
//         final response = await http.get(
//           Uri.parse(url),
//           headers: {
//             'Content-Type': 'application/json',
//             'Authorization': 'Bearer $token',
//           },
//         );
//
//         if (response.statusCode == 200) {
//           try {
//             final data = json.decode(response.body);
//
//             // Essayons différents formats de réponse
//             List<dynamic>? servicesJson;
//
//             if (data is Map<String, dynamic>) {
//               if (data.containsKey('status') && data['status'] == 'success') {
//                 servicesJson = data['services'] as List?;
//               } else if (data.containsKey('data')) {
//                 servicesJson = data['data'] as List?;
//               } else if (data.containsKey('results')) {
//                 servicesJson = data['results'] as List?;
//               } else if (data.containsKey('userServices')) {
//                 servicesJson = data['userServices'] as List?;
//               }
//             } else if (data is List) {
//               servicesJson = data;
//             }
//
//             if (servicesJson != null) {
//               print("📂 Services JSON trouvés: $servicesJson");
//
//               final services = servicesJson.map((json) {
//                 print("🔄 Conversion service: $json");
//                 return Service.fromJson(json);
//               }).toList();
//
//               print("✅ ${services.length} services ajoutés récupérés");
//               return services;
//             }
//           } catch (e) {
//             print("❌ Erreur parsing JSON pour URL $url: $e");
//             continue; // Essayer l'URL suivante
//           }
//         }
//       }
//
//       print("❌ Aucune URL n'a fonctionné pour récupérer les services ajoutés");
//       return [];
//     } catch (e) {
//       print('❌ Erreur chargement services ajoutés: $e');
//       return [];
//     }
//   }
//
//   /// Ajouter un service existant à un utilisateur
//   static Future<bool> ajouterServiceExistant({
//     required int userId,
//     required int serviceId,
//     required int categoryId,
//     required double prix,
//     required int tempsMinutes,
//   }) async {
//     try {
//       final token = await _obtenirTokenFirebase();
//       if (token == null) {
//         throw Exception('Token Firebase manquant');
//       }
//
//       print("🔄 Ajout service ID $serviceId - Prix: ${prix}€ - Durée: ${tempsMinutes}min");
//
//       final response = await http.post(
//         Uri.parse('$baseUrl/services/add-existing/'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: json.encode({
//           'userId': userId,
//           'service_id': serviceId,
//           'category_id': categoryId,
//           'prix': prix,
//           'temps_minutes': tempsMinutes,
//         }),
//       );
//
//       if (response.statusCode == 201) {
//         print("✅ Service ajouté avec succès");
//         return true;
//       } else {
//         final errorData = json.decode(response.body);
//         throw Exception("Erreur ajout service: ${errorData['message']}");
//       }
//     } catch (e) {
//       print("❌ Erreur ajout service: $e");
//       throw e;
//     }
//   }
//
//   /// Ajouter plusieurs services en une fois
//   static Future<List<String>> ajouterPlusieursServices({
//     required int userId,
//     required List<Map<String, dynamic>> services,
//   }) async {
//     List<String> erreurs = [];
//
//     for (final serviceData in services) {
//       try {
//         await ajouterServiceExistant(
//           userId: userId,
//           serviceId: serviceData['service_id'],
//           categoryId: serviceData['category_id'],
//           prix: serviceData['prix'],
//           tempsMinutes: serviceData['temps_minutes'],
//         );
//       } catch (e) {
//         erreurs.add("Service ${serviceData['service_id']}: $e");
//       }
//     }
//
//     return erreurs;
//   }
//
//   /// Supprimer un service ajouté par un utilisateur
//   static Future<bool> supprimerServiceUtilisateur({
//     required int userId,
//     required int serviceId,
//   }) async {
//     try {
//       final token = await _obtenirTokenFirebase();
//       if (token == null) {
//         throw Exception('Token Firebase manquant');
//       }
//
//       print("🔄 Suppression service ID $serviceId pour utilisateur $userId");
//
//       final response = await http.delete(
//         Uri.parse('$baseUrl/users/$userId/services/$serviceId/'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       print("📡 Réponse suppression service: ${response.statusCode}");
//
//       if (response.statusCode == 200 || response.statusCode == 204) {
//         print("✅ Service supprimé avec succès");
//         return true;
//       } else {
//         throw Exception("Erreur suppression service: ${response.statusCode}");
//       }
//     } catch (e) {
//       print("❌ Erreur suppression service: $e");
//       throw e;
//     }
//   }
//
//   /// Modifier un service utilisateur (prix, durée)
//   static Future<bool> modifierServiceUtilisateur({
//     required int userId,
//     required int serviceId,
//     required double prix,
//     required int tempsMinutes,
//   }) async {
//     try {
//       final token = await _obtenirTokenFirebase();
//       if (token == null) {
//         throw Exception('Token Firebase manquant');
//       }
//
//       print("🔄 Modification service ID $serviceId - Prix: ${prix}€ - Durée: ${tempsMinutes}min");
//
//       final response = await http.put(
//         Uri.parse('$baseUrl/users/$userId/services/$serviceId/'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: json.encode({
//           'prix': prix,
//           'temps_minutes': tempsMinutes,
//         }),
//       );
//
//       print("📡 Réponse modification service: ${response.statusCode}");
//
//       if (response.statusCode == 200) {
//         print("✅ Service modifié avec succès");
//         return true;
//       } else {
//         throw Exception("Erreur modification service: ${response.statusCode}");
//       }
//     } catch (e) {
//       print("❌ Erreur modification service: $e");
//       throw e;
//     }
//   }
//
//   /// Récupérer tous les services d'un salon organisés par catégorie
//   static Future<Map<String, dynamic>> chargerServicesParCategoriePourSalon(int salonId) async {
//     try {
//       final token = await _obtenirTokenFirebase();
//       if (token == null) {
//         throw Exception('Token Firebase manquant - Utilisateur non connecté');
//       }
//
//       print("🔄 Chargement des services du salon ID: $salonId");
//
//       final response = await http.get(
//         Uri.parse('$baseUrl/salon/$salonId/services-by-category/'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//
//         if (data['status'] == 'success') {
//           print("✅ Services du salon récupérés: ${data['total_services']} services");
//           return data;
//         } else {
//           throw Exception(data['message'] ?? 'Erreur lors du chargement des services du salon');
//         }
//       } else if (response.statusCode == 401) {
//         throw Exception('Non autorisé - Token Firebase invalide');
//       } else {
//         throw Exception('Erreur serveur: ${response.statusCode} - ${response.body}');
//       }
//     } catch (e) {
//       print("❌ ERREUR chargement services salon: $e");
//       throw e;
//     }
//   }
// }