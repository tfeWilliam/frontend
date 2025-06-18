////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                PAGE D'INITIATION DU PAIEMENT VIA STRIPE                      //
//                                                                            //
//  Ce fichier définit l'écran `PaiementPage`, qui sert de pont entre votre   //
//  application et la page de paiement sécurisée hébergée par Stripe.         //
//                                                                            //
//  Fonctionnement :                                                          //
//  1. Un bouton "Payer maintenant" est présenté à l'utilisateur.             //
//  2. Au clic, la méthode `_lancerPaiementStripeCheckout` appelle votre      //
//     backend pour créer une session de checkout Stripe.                     //
//  3. L'URL de checkout reçue est ensuite ouverte dans une application       //
//     externe (généralement le navigateur web de l'utilisateur).             //
//  4. Immédiatement après avoir lancé l'URL, l'application redirige          //
//     l'utilisateur vers une page de vérification (`PaymentVerificationPage`)//
//     où il attendra la confirmation du paiement.                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:hairbnb/pages/payment/payment_services/paiement_service.dart';
import 'package:hairbnb/pages/payment/payment_verification_page.dart';

/// Un `StatefulWidget` qui gère l'initiation du processus de paiement.
class PaiementPage extends StatefulWidget {
  /// L'identifiant du rendez-vous pour lequel le paiement est effectué.
  final int rendezVousId;

  /// Constructeur de la page de paiement.
  const PaiementPage({
    required this.rendezVousId,
    super.key,
  });

  @override
  State<PaiementPage> createState() => _PaiementPageState();
}

/// La classe d'état pour `PaiementPage`.
/// Gère l'état de chargement et d'erreur pendant la création de la session de paiement.
class _PaiementPageState extends State<PaiementPage> {
  /// `true` si une opération est en cours (ex: appel à l'API).
  bool _isLoading = false;
  /// Stocke un message d'erreur à afficher à l'utilisateur.
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
  }

  /// Orchestre la création d'une session de checkout Stripe et la redirection de l'utilisateur.
  Future<void> _lancerPaiementStripeCheckout() async {
    // Met à jour l'UI pour afficher un indicateur de chargement.
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      // Étape 1: Appelle le service pour créer la session de paiement côté backend.
      final response = await PaiementService.createCheckoutSession(widget.rendezVousId);
      final checkoutUrl = response['checkout_url'];

      // Valide que l'URL a bien été reçue.
      if (checkoutUrl == null || checkoutUrl.toString().isEmpty) {
        throw Exception("URL de paiement manquante.");
      }

      // Étape 2: Lance l'URL de paiement dans une application externe (navigateur).
      final uri = Uri.parse(checkoutUrl);
      // `launchUrl` retourne `false` si l'URL ne peut pas être ouverte.
      if (!await url_launcher.launchUrl(
          uri,
          mode: url_launcher.LaunchMode.externalApplication // Assure l'ouverture hors de l'app.
      )) {
        throw Exception("Impossible d'ouvrir la page de paiement.");
      }

      // Étape 3: Une fois l'URL lancée, redirige immédiatement l'utilisateur vers
      // la page de vérification sans attendre la fin du paiement.
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PaymentVerificationPage(
              rendezVousId: widget.rendezVousId,
            ),
          ),
        );
      }
    } catch (e) {
      // En cas d'erreur, met à jour l'UI pour afficher le message d'erreur.
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll("Exception: ", "");
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Paiement"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Finalisez votre paiement sécurisé",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Affiche soit le bouton de paiement, soit un indicateur de chargement.
            if (_isLoading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text("Redirection en cours..."),
                  ],
                ),
              )
            else
              ElevatedButton(
                onPressed: _lancerPaiementStripeCheckout,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: const Text(
                  "Payer maintenant",
                  style: TextStyle(fontSize: 18),
                ),
              ),

            // Affiche un message d'erreur s'il y en a un.
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 24),

            // Section d'information sur la sécurité du paiement.
            const Text(
              "Votre paiement est sécurisé via Stripe.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  "Paiement 100% sécurisé",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}






// // payment_page.dart - version corrigée
//
// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart' as url_launcher;
// import 'package:hairbnb/pages/payment/payment_services/paiement_service.dart';
// import 'package:hairbnb/pages/payment/payment_verification_page.dart';
//
// class PaiementPage extends StatefulWidget {
//   final int rendezVousId;
//
//   const PaiementPage({
//     required this.rendezVousId,
//     super.key,
//   });
//
//   @override
//   State<PaiementPage> createState() => _PaiementPageState();
// }
//
// class _PaiementPageState extends State<PaiementPage> {
//   bool _isLoading = false;
//   String _errorMessage = "";
//
//   @override
//   void initState() {
//     super.initState();
//   }
//
//   // ⚠️ IMPORTANT: Fonction corrigée pour éviter la récursion infinie
//   Future<void> _lancerPaiementStripeCheckout() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = "";
//     });
//
//     try {
//       final response = await PaiementService.createCheckoutSession(widget.rendezVousId);
//       final checkoutUrl = response['checkout_url'];
//
//       if (checkoutUrl == null || checkoutUrl.toString().isEmpty) {
//         throw Exception("URL de paiement manquante.");
//       }
//
//       // ⚠️ Utilisation directe de url_launcher sans appeler notre propre fonction
//       final uri = Uri.parse(checkoutUrl);
//
//       // CORRECTION: Éviter la récursion en utilisant directement le package
//       if (!await url_launcher.launchUrl(
//           uri,
//           mode: url_launcher.LaunchMode.externalApplication
//       )) {
//         throw Exception("Impossible d'ouvrir la page de paiement.");
//       }
//
//       // Rediriger vers la page de vérification
//       if (mounted) {
//         Navigator.of(context).pushReplacement(
//           MaterialPageRoute(
//             builder: (context) => PaymentVerificationPage(
//               rendezVousId: widget.rendezVousId,
//             ),
//           ),
//         );
//       }
//
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _errorMessage = e.toString().replaceAll("Exception: ", "");
//           _isLoading = false;
//         });
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Paiement"),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             const Text(
//               "Finalisez votre paiement sécurisé",
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 32),
//             if (_isLoading)
//               const Center(
//                 child: Column(
//                   children: [
//                     CircularProgressIndicator(),
//                     SizedBox(height: 16),
//                     Text("Redirection en cours..."),
//                   ],
//                 ),
//               )
//             else
//               ElevatedButton(
//                 onPressed: _lancerPaiementStripeCheckout,
//                 style: ElevatedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(vertical: 16.0),
//                 ),
//                 child: const Text(
//                   "Payer maintenant",
//                   style: TextStyle(fontSize: 18),
//                 ),
//               ),
//             if (_errorMessage.isNotEmpty)
//               Padding(
//                 padding: const EdgeInsets.only(top: 16),
//                 child: Text(
//                   _errorMessage,
//                   style: const TextStyle(color: Colors.red),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//             const SizedBox(height: 24),
//             const Text(
//               "Votre paiement est sécurisé via Stripe.",
//               style: TextStyle(fontSize: 14, color: Colors.grey),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 8),
//             const Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.lock, size: 16, color: Colors.grey),
//                 SizedBox(width: 4),
//                 Text(
//                   "Paiement 100% sécurisé",
//                   style: TextStyle(fontSize: 14, color: Colors.grey),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }