/// **************************************************************************************
///
/// FONCTION DE SERVICE : GESTION DU PAIEMENT (STRIPE)
///
/// OBJECTIF :
/// Cette fonction orchestre le processus de paiement pour un rendez-vous spécifique.
/// Elle est conçue pour fonctionner sur plusieurs plateformes (Web et Mobile) en
/// adaptant le flux de paiement Stripe.
///
/// WORKFLOW :
/// 1. Récupère le token d'authentification de l'utilisateur via Firebase.
/// 2. Appelle le backend personnalisé pour créer une session de paiement Stripe,
/// en transmettant l'ID du rendez-vous.
/// 3. Le backend communique avec Stripe et retourne les informations nécessaires.
/// 4. La fonction initie le paiement côté client de manière différente selon la plateforme :
/// - Sur le Web : Redirige l'utilisateur vers une page de paiement
/// Stripe Checkout hébergée.
/// - Sur Mobile : Utilise le package `flutter_stripe` pour afficher une feuille
/// de paiement native (Payment Sheet).
///
/// DÉPENDANCES :
/// - `firebase_auth` pour l'authentification.
/// - `http` pour la communication avec le backend.
/// - `flutter_stripe` pour le paiement natif sur mobile.
/// - `dart:html` pour la redirection sur le web.
///
///***************************************************************************************
library;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html show window;

/// Orchestre le processus de paiement pour un rendez-vous donné, en s'adaptant à la plateforme (Web ou Mobile).
///
/// [rendezVousId] : L'identifiant du rendez-vous à payer.
/// Lance une [Exception] en cas d'échec d'authentification, d'erreur de l'API,
/// ou si les données nécessaires (URL ou clientSecret) sont manquantes dans la réponse du backend.
Future<void> handlePayment(int rendezVousId) async {
  try {
    // --- ETAPE 1: Récupération du token d'authentification de l'utilisateur ---
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken();
    if (token == null) throw Exception("Utilisateur non authentifié.");

    // --- ETAPE 2: Appel au backend pour créer une session de paiement Stripe ---
    final response = await http.post(
      Uri.parse('https://www.hairbnb.site/api/paiement/create-checkout-session/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'rendez_vous_id': rendezVousId,
      }),
    );

    // --- ETAPE 3: Vérification de la réponse du backend ---
    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? "Erreur serveur");
    }
    final data = jsonDecode(response.body);

    // --- ETAPE 4: Exécution du flux de paiement en fonction de la plateforme ---
    if (kIsWeb) {
      // Sur le Web : redirection vers la page de paiement hébergée par Stripe.
      final checkoutUrl = data['checkout_url'];
      if (checkoutUrl != null) {
        html.window.open(checkoutUrl, '_blank');
      } else {
        throw Exception("URL de paiement manquante dans la réponse");
      }
    } else {
      // Sur Mobile : initialisation et affichage de la feuille de paiement native de Stripe.
      final clientSecret = data['clientSecret'];
      if (clientSecret != null) {
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: 'Hairbnb',
          ),
        );
        await Stripe.instance.presentPaymentSheet();
      } else {
        throw Exception("Client secret manquant dans la réponse");
      }
    }
  } catch (e) {
    // --- ETAPE 5: Gestion des erreurs globales ---
    // Relance l'exception pour que la couche appelante (UI) puisse la gérer et
    // afficher un message à l'utilisateur.
    rethrow;
  }
}








// import 'dart:convert';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:flutter_stripe/flutter_stripe.dart';
// import 'package:http/http.dart' as http;
// import 'dart:html' as html show window;
//
// // Fonction qui gère le paiement selon la plateforme
// Future<void> handlePayment(int rendezVousId) async {
//   try {
//     final user = FirebaseAuth.instance.currentUser;
//     final token = await user?.getIdToken();
//
//     if (token == null) throw Exception("Utilisateur non authentifié.");
//
//     // Appel à votre backend pour créer une session de paiement
//     final response = await http.post(
//       Uri.parse('https://www.hairbnb.site/api/paiement/create-checkout-session/'),
//       headers: {
//         'Content-Type': 'application/json',
//         'Authorization': 'Bearer $token',
//       },
//       body: jsonEncode({
//         'rendez_vous_id': rendezVousId,
//       }),
//     );
//
//     if (response.statusCode != 200) {
//       final errorData = jsonDecode(response.body);
//       throw Exception(errorData['error'] ?? "Erreur serveur");
//     }
//
//     final data = jsonDecode(response.body);
//
//     if (kIsWeb) {
//       // Sur le web, utiliser la redirection vers Stripe Checkout
//       // Votre backend doit renvoyer une URL de checkout
//       if (data['checkout_url'] != null) {
//         html.window.open(data['checkout_url'], '_blank');
//       } else {
//         throw Exception("URL de paiement manquante dans la réponse");
//       }
//     } else {
//       // Sur mobile, utiliser la feuille de paiement native
//       if (data['clientSecret'] != null) {
//         await Stripe.instance.initPaymentSheet(
//           paymentSheetParameters: SetupPaymentSheetParameters(
//             paymentIntentClientSecret: data['clientSecret'],
//             merchantDisplayName: 'Hairbnb',
//           ),
//         );
//         await Stripe.instance.presentPaymentSheet();
//       } else {
//         throw Exception("Client secret manquant dans la réponse");
//       }
//     }
//   } catch (e) {
//     print("Erreur: $e");
//     rethrow;
//   }
// }