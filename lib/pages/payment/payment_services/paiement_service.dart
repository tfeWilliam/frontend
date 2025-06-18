/// **************************************************************************************
///
/// SERVICE API : GESTION DES PAIEMENTS
/// Fichier: payment_services/paiement_service.dart
///
/// OBJECTIF :
/// Cette classe définit un service statique qui centralise toutes les interactions avec
/// l'API backend pour la création et la vérification des transactions de paiement.
///
/// FONCTIONNALITÉS CLÉS :
/// - Crée des sessions de paiement sécurisées pour les rendez-vous.
/// - Vérifie le statut d'un paiement après l'interaction de l'utilisateur.
/// - Implémente une logique de vérification de statut très robuste pour contourner
/// d'éventuels problèmes d'encodage de caractères venant du backend.
/// - Fournit une fonctionnalité pour écouter les "deep links", ce qui est essentiel
/// pour gérer les flux de redirection après un paiement sur une application mobile.
///
///***************************************************************************************
library;
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_links/app_links.dart';

/// Classe de service statique pour toutes les opérations liées aux paiements.
class PaiementService {
  /// L'URL de base de l'API backend.
  static const String _baseUrl = 'https://www.hairbnb.site/api';
  /// Instance du gestionnaire de liens d'application (deep links).
  static AppLinks? _appLinks;

  /// Initialise l'écouteur de deep links pour gérer les redirections après un paiement externe.
  ///
  /// Un deep link (ex: `myapp://payment/success`) permet à une application externe
  /// (comme un navigateur ou une application de paiement) de rouvrir cette application
  /// et de la diriger vers un état ou une page spécifique.
  ///
  /// [callback] : La fonction à exécuter lorsqu'un deep link est reçu.
  static Future<void> listenForDeepLinks(Function(Uri) callback) async {
    try {
      _appLinks = AppLinks();
      // Écoute les nouveaux liens qui arrivent pendant que l'application est ouverte.
      _appLinks!.uriLinkStream.listen((uri) {
        callback(uri);
      });
      // Vérifie si l'application a été ouverte initialement par un lien.
      final initialLink = await _appLinks!.getLatestLink();
      if (initialLink != null) {
        callback(initialLink);
      }
    } catch (e) {
      // Gère les erreurs lors de l'initialisation.
    }
  }

  /// Appelle le backend pour créer une session de paiement Stripe pour un rendez-vous.
  ///
  /// [rendezVousId] : L'ID du rendez-vous à payer.
  /// Retourne une `Map<String, dynamic>` contenant les informations de la session
  /// (ex: clientSecret pour mobile, checkout_url pour web).
  static Future<Map<String, dynamic>> createCheckoutSession(int rendezVousId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken();
      if (token == null) throw Exception("Utilisateur non authentifié.");

      final response = await http.post(
        Uri.parse('$_baseUrl/paiement/create-checkout-session/'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'rendez_vous_id': rendezVousId}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['error'] ?? "Erreur serveur");
        } catch (e) {
          throw Exception("Erreur serveur: ${response.body}");
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Vérifie le statut d'un paiement sur le backend pour un rendez-vous donné.
  ///
  /// [rendezVousId] : L'ID du rendez-vous dont le statut de paiement doit être vérifié.
  /// Retourne `true` si le paiement est confirmé comme étant payé, `false` sinon.
  static Future<bool> checkPaymentStatus(int rendezVousId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken();
      if (token == null) throw Exception("Utilisateur non authentifié.");

      final response = await http.get(
        Uri.parse('$_baseUrl/paiement/status/$rendezVousId/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        throw Exception("Erreur lors de la vérification du statut de paiement.");
      }
      final data = jsonDecode(response.body);

      // La logique de vérification suivante est volontairement robuste pour gérer des
      // problèmes d'encodage potentiels où "payé" pourrait être reçu sous une forme altérée.

      // ETAPE 1: Vérification directe du champ 'status', tolérant l'erreur d'encodage.
      if (data['status'] == 'payÃ©' || data['status'] == 'payé') {
        return true;
      }

      // ETAPE 2: Vérification dans la structure de détails imbriquée, tolérant aussi l'erreur.
      if (data['details'] != null && data['details']['statut'] != null &&
          (data['details']['statut']['code'] == 'payÃ©' || data['details']['statut']['code'] == 'payé')) {
        return true;
      }

      // ETAPE 3: Vérification de secours non sensible à la casse et aux accents.
      if (data['status'] != null && data['status'].toString().toLowerCase().contains('pay')) {
        return true;
      }

      // ETAPE 4: Vérification finale basée sur la présence d'un reçu, un indicateur fort de succès.
      if (data['details'] != null && data['details']['receipt_url'] != null) {
        return true;
      }

      return false;
    } catch (e) {
      rethrow;
    }
  }
}






// // payment_services/paiement_service.dart - avec correction d'encodage
//
// import 'dart:async';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:app_links/app_links.dart';
//
// class PaiementService {
//   static const String _baseUrl = 'https://www.hairbnb.site/api';
//   static AppLinks? _appLinks;
//
//   // Initialise les deep links (pour les redirections)
//   static Future<void> listenForDeepLinks(Function(Uri) callback) async {
//     try {
//       _appLinks = AppLinks();
//
//       // Écouter les liens entrants
//       _appLinks!.uriLinkStream.listen((uri) {
//         print("Deep link reçu: $uri");
//         callback(uri);
//       });
//
//       // Vérifier si l'app a été ouverte par un lien
//       try {
//         final initialLink = await _appLinks!.getLatestLink();
//         if (initialLink != null) {
//           print("Lien initial: $initialLink");
//           callback(initialLink);
//         }
//       } catch (e) {
//         print("Impossible de récupérer le lien initial : $e");
//       }
//     } catch (e) {
//       print("Erreur lors de l'initialisation des deep links: $e");
//     }
//   }
//
//   // Crée une session de paiement
//   static Future<Map<String, dynamic>> createCheckoutSession(int rendezVousId) async {
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       final token = await user?.getIdToken();
//
//       if (token == null) throw Exception("Utilisateur non authentifié.");
//
//       final response = await http.post(
//         Uri.parse('$_baseUrl/paiement/create-checkout-session/'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: jsonEncode({
//           'rendez_vous_id': rendezVousId,
//         }),
//       );
//
//       print("Status code: ${response.statusCode}");
//
//       if (response.statusCode == 200) {
//         try {
//           final jsonResponse = jsonDecode(response.body);
//           return jsonResponse;
//         } catch (e) {
//           throw Exception("Erreur lors du décodage de la réponse: $e");
//         }
//       } else {
//         try {
//           final errorData = jsonDecode(response.body);
//           throw Exception(errorData['error'] ?? "Erreur serveur");
//         } catch (e) {
//           throw Exception("Erreur serveur: ${response.body}");
//         }
//       }
//     } catch (e) {
//       print("❌ Exception: $e");
//       rethrow;
//     }
//   }
//
//   // Vérifie le statut du paiement avec une correction pour l'encodage
//   static Future<bool> checkPaymentStatus(int rendezVousId) async {
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       final token = await user?.getIdToken();
//
//       if (token == null) throw Exception("Utilisateur non authentifié.");
//
//       print("Vérification du paiement pour RDV #$rendezVousId");
//
//       final response = await http.get(
//         Uri.parse('$_baseUrl/paiement/status/$rendezVousId/'),
//         headers: {
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       if (response.statusCode != 200) {
//         print("Erreur HTTP: ${response.statusCode}");
//         print("Réponse: ${response.body}");
//         throw Exception("Erreur lors de la vérification du statut de paiement.");
//       }
//
//       final data = jsonDecode(response.body);
//
//       // Afficher la réponse complète pour debug
//       print("Réponse complète: $data");
//
//       // ⚠️ CORRECTION: Problème d'encodage détecté
//       // La réponse contient "payÃ©" au lieu de "payé" à cause d'un problème d'encodage
//
//       // 1. Vérifier le status direct avec tolérance d'encodage
//       if (data['status'] == 'payÃ©' || data['status'] == 'payé') {
//         print("✅ Paiement confirmé par status (avec correction d'encodage)");
//         return true;
//       }
//
//       // 2. Vérifier dans details.statut.code avec tolérance d'encodage
//       if (data['details'] != null &&
//           data['details']['statut'] != null &&
//           (data['details']['statut']['code'] == 'payÃ©' ||
//               data['details']['statut']['code'] == 'payé')) {
//         print("✅ Paiement confirmé par details.statut.code (avec correction d'encodage)");
//         return true;
//       }
//
//       // 3. Méthode alternative: vérifier si le texte contient "pay" (sans accents)
//       if (data['status'] != null &&
//           data['status'].toString().toLowerCase().contains('pay')) {
//         print("✅ Paiement confirmé par contenu de status");
//         return true;
//       }
//
//       // 4. Fallback: Si aucune des vérifications précédentes n'a fonctionné,
//       // mais que la structure ressemble à un paiement confirmé (présence de receipt_url)
//       if (data['details'] != null &&
//           data['details']['receipt_url'] != null) {
//         print("✅ Paiement confirmé par la présence d'un reçu");
//         return true;
//       }
//
//       print("❌ Paiement non confirmé selon la réponse");
//       return false;
//     } catch (e) {
//       print("Erreur checkPaymentStatus: $e");
//       rethrow;
//     }
//   }
// }
