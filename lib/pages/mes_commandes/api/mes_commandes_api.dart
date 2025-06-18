////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//          SERVICE (CLIENT API) POUR LA GESTION DES COMMANDES CLIENT           //
//                                                                            //
//  Ce fichier définit la classe `CommandesApiService`, qui centralise toutes //
//  les communications avec l'API backend pour les opérations liées aux       //
//  commandes d'un client ("Mes Commandes").                                  //
//                                                                            //
//  La classe utilise des méthodes statiques, ce qui signifie qu'elle n'a pas //
//  besoin d'être instanciée pour être utilisée. Elle gère l'authentification  //
//  pour chaque requête en récupérant le jeton Firebase de l'utilisateur.     //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;

import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../../models/mes_commandes.dart';

/// Une classe de service fournissant des méthodes statiques pour interagir
/// avec les endpoints de l'API relatifs aux commandes des clients.
class CommandesApiService {
  /// L'URL de base de l'API backend.
  static const String _baseUrl = 'https://www.hairbnb.site/api';

  /// Récupère et trie la liste des commandes pour un utilisateur spécifique.
  ///
  /// Cette méthode effectue un appel authentifié à l'API pour obtenir les commandes,
  /// puis applique une logique de tri personnalisée pour un affichage pertinent :
  ///   1. Les rendez-vous futurs sont affichés en premier, triés du plus proche au plus lointain.
  ///   2. Les rendez-vous passés sont affichés ensuite, triés du plus récent au plus ancien.
  ///
  /// [userId] : L'identifiant de l'utilisateur pour lequel les commandes sont récupérées.
  ///
  /// Retourne une `Future` qui se résoudra en une `List<Commande>`.
  static Future<List<Commande>> chargerCommandes(int userId) async {
    try {
      // Récupération de l'utilisateur et de son jeton d'authentification Firebase.
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken();

      // Si aucun token n'est disponible, l'utilisateur n'est pas authentifié.
      if (token == null) throw Exception("Utilisateur non authentifié.");

      // Effectue la requête GET vers l'API.
      final response = await http.get(
        Uri.parse('$_baseUrl/mes-commandes/$userId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Décode la réponse et la convertit en une liste d'objets Commande.
        final List<dynamic> jsonList = json.decode(utf8.decode(response.bodyBytes));
        List<Commande> commandes = Commande.fromJsonList(jsonList);

        // Applique la logique de tri personnalisée.
        final now = DateTime.now();
        commandes.sort((a, b) {
          final aIsAfter = a.dateHeure.isAfter(now);
          final bIsAfter = b.dateHeure.isAfter(now);

          // Les deux sont dans le futur : trier par ordre chronologique croissant.
          if (aIsAfter && bIsAfter) {
            return a.dateHeure.compareTo(b.dateHeure);
          }
          // `a` est dans le futur, `b` dans le passé : `a` vient avant.
          else if (aIsAfter && !bIsAfter) {
            return -1;
          }
          // `a` est dans le passé, `b` dans le futur : `b` vient avant.
          else if (!aIsAfter && bIsAfter) {
            return 1;
          }
          // Les deux sont dans le passé : trier par ordre chronologique décroissant (plus récent d'abord).
          else {
            return b.dateHeure.compareTo(a.dateHeure);
          }
        });

        return commandes;
      } else {
        // Gère les réponses d'erreur de l'API.
        throw Exception('Erreur lors du chargement des commandes: ${response.statusCode}');
      }
    } catch (e) {
      // Gère les erreurs de connexion ou autres exceptions.
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Envoie une requête à l'API pour annuler une commande spécifique.
  ///
  /// [commandeId] : L'identifiant de la commande à annuler.
  ///
  /// Retourne `true` si l'annulation a réussi (status 200), `false` sinon.
  static Future<bool> annulerCommande(int commandeId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken();
      if (token == null) throw Exception("Utilisateur non authentifié.");

      // Effectue la requête POST pour l'annulation.
      final response = await http.post(
        Uri.parse('$_baseUrl/annuler-commande/$commandeId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erreur lors de l\'annulation: $e');
    }
  }

  /// Récupère l'URL d'un reçu de paiement pour une commande spécifique.
  ///
  /// [commandeId] : L'identifiant de la commande dont on veut le reçu.
  ///
  /// Retourne une `String` contenant l'URL du reçu.
  static Future<String> obtenirUrlRecu(int commandeId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken();
      if (token == null) throw Exception("Utilisateur non authentifié.");

      // Effectue la requête GET pour obtenir l'URL du reçu.
      final response = await http.get(
        Uri.parse('$_baseUrl/recu-commande/$commandeId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Extrait l'URL de la réponse JSON.
        final Map<String, dynamic> data = json.decode(response.body);
        return data['receiptUrl'] ?? '';
      } else {
        throw Exception('Erreur lors de la récupération du reçu: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }
}






// import 'dart:convert';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:http/http.dart' as http;
//
// import '../../../models/mes_commandes.dart';
//
// class CommandesApiService {
//   static const String _baseUrl = 'https://www.hairbnb.site/api';
//
//   // Méthode pour charger les commandes d'un utilisateur
//   static Future<List<Commande>> chargerCommandes(int userId) async {
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       final token = await user?.getIdToken();
//
//       if (token == null) throw Exception("Utilisateur non authentifié.");
//
//       final response = await http.get(
//         Uri.parse('$_baseUrl/mes-commandes/$userId/'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       if (response.statusCode == 200) {
//         final List<dynamic> jsonList = json.decode(utf8.decode(response.bodyBytes));
//         List<Commande> commandes = Commande.fromJsonList(jsonList);
//
//         // Trier les commandes par date (de la plus proche à la plus éloignée)
//         final now = DateTime.now();
//         commandes.sort((a, b) {
//           // Si les deux dates sont dans le futur, on prend la plus proche en premier
//           if (a.dateHeure.isAfter(now) && b.dateHeure.isAfter(now)) {
//             return a.dateHeure.compareTo(b.dateHeure);
//           }
//           // Si une date est dans le passé et l'autre dans le futur, la future d'abord
//           else if (a.dateHeure.isAfter(now) && b.dateHeure.isBefore(now)) {
//             return -1;
//           }
//           else if (a.dateHeure.isBefore(now) && b.dateHeure.isAfter(now)) {
//             return 1;
//           }
//           // Si les deux sont dans le passé, on montre d'abord la plus récente
//           else {
//             return b.dateHeure.compareTo(a.dateHeure);
//           }
//         });
//
//         return commandes;
//       } else {
//         throw Exception('Erreur lors du chargement des commandes: ${response.statusCode}');
//       }
//     } catch (e) {
//       throw Exception('Erreur de connexion: $e');
//     }
//   }
//
//   // Autres méthodes API
//   static Future<bool> annulerCommande(int commandeId) async {
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       final token = await user?.getIdToken();
//
//       if (token == null) throw Exception("Utilisateur non authentifié.");
//
//       final response = await http.post(
//         Uri.parse('$_baseUrl/annuler-commande/$commandeId/'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       return response.statusCode == 200;
//     } catch (e) {
//       throw Exception('Erreur lors de l\'annulation: $e');
//     }
//   }
//
//   static Future<String> obtenirUrlRecu(int commandeId) async {
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       final token = await user?.getIdToken();
//
//       if (token == null) throw Exception("Utilisateur non authentifié.");
//
//       final response = await http.get(
//         Uri.parse('$_baseUrl/recu-commande/$commandeId/'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       if (response.statusCode == 200) {
//         final Map<String, dynamic> data = json.decode(response.body);
//         return data['receiptUrl'] ?? '';
//       } else {
//         throw Exception('Erreur lors de la récupération du reçu: ${response.statusCode}');
//       }
//     } catch (e) {
//       throw Exception('Erreur de connexion: $e');
//     }
//   }
// }
