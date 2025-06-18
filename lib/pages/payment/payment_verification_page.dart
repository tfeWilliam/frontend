////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                PAGE DE VÉRIFICATION DU STATUT DE PAIEMENT                   //
//                                                                            //
//  Ce fichier définit l'écran `PaymentVerificationPage`. C'est une page      //
//  "d'attente" affichée à l'utilisateur après qu'il a été redirigé vers une  //
//  plateforme de paiement externe comme Stripe.                              //
//                                                                            //
//  Fonctionnement :                                                          //
//  - À l'initialisation, la page commence à interroger périodiquement le     //
//    backend (`PaiementService.checkPaymentStatus`) pour vérifier si le      //
//    paiement a été confirmé.                                                //
//  - Elle écoute également les "deep links" pour une confirmation potentielle//
//    plus rapide si l'utilisateur est redirigé vers l'application.           //
//  - L'interface utilisateur est mise à jour dynamiquement pour refléter     //
//    l'état actuel : en cours de vérification, succès ou échec.              //
//  - En cas de succès, l'utilisateur est redirigé vers la page d'accueil.    //
//  - En cas d'échecs répétés, un dialogue d'erreur est affiché.              //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hairbnb/pages/home_page.dart';
import 'package:hairbnb/pages/payment/payment_services/paiement_service.dart';

/// Un `StatefulWidget` qui gère la vérification en arrière-plan du statut d'un paiement.
class PaymentVerificationPage extends StatefulWidget {
  /// L'identifiant du rendez-vous pour lequel le paiement est vérifié.
  final int rendezVousId;

  /// Constructeur de la page de vérification de paiement.
  const PaymentVerificationPage({
    super.key,
    required this.rendezVousId,
  });

  @override
  State<PaymentVerificationPage> createState() => _PaymentVerificationPageState();
}

/// La classe d'état pour `PaymentVerificationPage`.
class _PaymentVerificationPageState extends State<PaymentVerificationPage> {
  //region Déclaration des variables d'état
  /// `true` si la vérification est activement en cours.
  bool _isVerifying = true;
  /// Le message affiché à l'utilisateur pour l'informer de l'état actuel.
  String _statusMessage = "Vérification du paiement en cours...";
  /// Compteur pour le nombre de tentatives de vérification échouées.
  int _failureCount = 0;
  /// Nombre maximum de tentatives avant d'abandonner et d'afficher une erreur.
  final int _maxFailures = 10;
  /// Le `Timer` qui déclenche les vérifications périodiques.
  Timer? _statusCheckTimer;
  /// Un drapeau pour éviter les redirections multiples si plusieurs confirmations arrivent.
  bool _redirecting = false;
  //endregion

  @override
  void initState() {
    super.initState();
    // Initialise l'écouteur de deep links pour une confirmation rapide.
    PaiementService.listenForDeepLinks(_handleDeepLink);
    // Lance la première vérification immédiatement sans attendre le timer.
    _checkPaymentStatus();
    // Configure le timer pour vérifier le statut toutes les 3 secondes.
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_redirecting) {
        _checkPaymentStatus();
      }
    });
  }

  @override
  void dispose() {
    // Annule le timer pour éviter les fuites de mémoire lorsque le widget est détruit.
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  /// Gère les deep links entrants pour mettre à jour l'état de la page.
  void _handleDeepLink(Uri uri) {
    if (kDebugMode) print("Deep link reçu dans PaymentVerificationPage: $uri");

    if (uri.path.contains('/paiement/success')) {
      // Si le lien est un succès, on force une vérification immédiate.
      _checkPaymentStatus();
    } else if (uri.path.contains('/paiement/error')) {
      // Si le lien est une erreur, on met à jour l'UI pour afficher l'échec.
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _statusMessage = "Le paiement a été annulé ou a échoué.";
          _statusCheckTimer?.cancel();
        });
      }
    }
  }

  /// Interroge le backend pour vérifier le statut du paiement.
  Future<void> _checkPaymentStatus() async {
    // Évite de lancer une nouvelle vérification si on est déjà en train de rediriger.
    if (_redirecting) return;

    try {
      final isPaid = await PaiementService.checkPaymentStatus(widget.rendezVousId);
      if (isPaid) {
        _redirecting = true;
        _statusCheckTimer?.cancel();
        if (mounted) {
          setState(() {
            _isVerifying = false;
            _statusMessage = "Paiement confirmé ! Redirection...";
          });
          // Attend 2 secondes pour que l'utilisateur voie le message de succès.
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              // Navigue vers la page d'accueil et supprime toutes les routes précédentes.
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomePage()),
                    (route) => false,
              );
            }
          });
        }
      }
      // Si la requête réussit mais que le paiement n'est pas encore confirmé,
      // on réinitialise le compteur d'échecs.
      _failureCount = 0;
    } catch (e) {
      if (kDebugMode) print("Erreur vérification paiement: $e");
      _failureCount++;

      // Si le nombre maximum de tentatives est atteint, on arrête le processus.
      if (_failureCount >= _maxFailures) {
        _statusCheckTimer?.cancel();
        if (mounted) {
          setState(() {
            _isVerifying = false;
            _statusMessage = "Impossible de vérifier le statut du paiement après plusieurs tentatives.";
          });
          _showErrorDialog();
        }
      }
    }
  }

  /// Affiche une boîte de dialogue lorsque la vérification échoue de manière persistante.
  void _showErrorDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Erreur de vérification"),
        content: const Text("Nous n'avons pas pu vérifier le statut de votre paiement. Veuillez vérifier votre connexion internet."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Ferme le dialogue
              // Réinitialise l'état et redémarre le processus de vérification.
              setState(() {
                _failureCount = 0;
                _isVerifying = true;
                _statusMessage = "Vérification du paiement en cours...";
              });
              _checkPaymentStatus();
              _statusCheckTimer = Timer.periodic(const Duration(seconds: 3), (_) {
                if (!_redirecting) _checkPaymentStatus();
              });
            },
            child: const Text("Réessayer"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Ferme le dialogue
              Navigator.of(context).pop(); // Retourne à l'écran précédent (la page de paiement)
            },
            child: const Text("Retour"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // `WillPopScope` empêche l'utilisateur de quitter l'écran avec le bouton "retour"
    // du système pendant que la vérification est en cours.
    return WillPopScope(
      onWillPop: () async => !_isVerifying,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Vérification du paiement"),
          centerTitle: true,
          automaticallyImplyLeading: !_isVerifying, // Masque le bouton retour pendant la vérification.
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Affiche un indicateur de progression, une icône de succès ou d'échec
                // en fonction de l'état actuel.
                if (_isVerifying)
                  const CircularProgressIndicator()
                else if (_statusMessage.contains("confirmé"))
                  const Icon(Icons.check_circle, color: Colors.green, size: 64)
                else
                  const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 24),
                // Affiche le message de statut.
                Text(
                  _statusMessage,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _isVerifying
                        ? Colors.black
                        : _statusMessage.contains("confirmé")
                        ? Colors.green
                        : Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                // Affiche un bouton "Réessayer" en cas d'échec non définitif.
                if (!_isVerifying && !_statusMessage.contains("confirmé"))
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _failureCount = 0;
                          _isVerifying = true;
                          _statusMessage = "Vérification du paiement en cours...";
                        });
                        _checkPaymentStatus();
                        _statusCheckTimer = Timer.periodic(const Duration(seconds: 3), (_) {
                          if (!_redirecting) _checkPaymentStatus();
                        });
                      },
                      child: const Text("Réessayer"),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}





// // pages/payment/payment_verification_page.dart
//
// import 'dart:async';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:hairbnb/pages/home_page.dart'; // Importez votre page d'accueil
// import 'package:hairbnb/pages/payment/payment_services/paiement_service.dart';
//
// class PaymentVerificationPage extends StatefulWidget {
//   final int rendezVousId;
//
//   const PaymentVerificationPage({
//     super.key,
//     required this.rendezVousId,
//   });
//
//   @override
//   State<PaymentVerificationPage> createState() => _PaymentVerificationPageState();
// }
//
// class _PaymentVerificationPageState extends State<PaymentVerificationPage> {
//   bool _isVerifying = true;
//   String _statusMessage = "Vérification du paiement en cours...";
//   int _failureCount = 0;
//   final int _maxFailures = 10; // Maximum de tentatives avant d'abandonner
//   Timer? _statusCheckTimer;
//   bool _redirecting = false;
//
//   @override
//   void initState() {
//     super.initState();
//
//     // Configurer l'écouteur de deep links
//     PaiementService.listenForDeepLinks(_handleDeepLink);
//
//     // Commencer immédiatement la vérification
//     _checkPaymentStatus();
//
//     // Configurer la vérification périodique
//     _statusCheckTimer = Timer.periodic(const Duration(seconds: 3), (_) {
//       if (!_redirecting) {
//         _checkPaymentStatus();
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     // Annuler le timer et les écouteurs
//     _statusCheckTimer?.cancel();
//     super.dispose();
//   }
//
//   void _handleDeepLink(Uri uri) {
//     if (kDebugMode) {
//       print("Deep link reçu dans PaymentVerificationPage: $uri");
//     }
//
//     if (uri.path.contains('/paiement/success')) {
//       // Forcer une vérification immédiate
//       _checkPaymentStatus();
//     } else if (uri.path.contains('/paiement/error')) {
//       // Mettre à jour l'interface
//       if (mounted) {
//         setState(() {
//           _isVerifying = false;
//           _statusMessage = "Le paiement a été annulé ou a échoué.";
//           _statusCheckTimer?.cancel();
//         });
//       }
//     }
//   }
//
//   Future<void> _checkPaymentStatus() async {
//     if (_redirecting) return; // Éviter les vérifications multiples pendant la redirection
//
//     try {
//       final isPaid = await PaiementService.checkPaymentStatus(widget.rendezVousId);
//
//       if (isPaid) {
//         // Marquer comme en redirection pour éviter des appels multiples
//         _redirecting = true;
//
//         // Arrêter les vérifications
//         _statusCheckTimer?.cancel();
//
//         if (mounted) {
//           setState(() {
//             _isVerifying = false;
//             _statusMessage = "Paiement confirmé ! Redirection...";
//           });
//
//           // Attendre un court moment pour montrer le succès, puis rediriger
//           Future.delayed(const Duration(seconds: 2), () {
//             if (mounted) {
//               Navigator.of(context).pushAndRemoveUntil(
//                 MaterialPageRoute(builder: (context) => const HomePage()),
//                     (route) => false, // Supprimer toutes les routes précédentes
//               );
//             }
//           });
//         }
//       }
//
//       // En cas de succès de la requête, réinitialiser le compteur d'échecs
//       _failureCount = 0;
//     } catch (e) {
//       if (kDebugMode) {
//         print("Erreur vérification paiement: $e");
//       }
//       _failureCount++;
//
//       if (_failureCount >= _maxFailures) {
//         // Arrêter les vérifications après plusieurs échecs
//         _statusCheckTimer?.cancel();
//
//         if (mounted) {
//           setState(() {
//             _isVerifying = false;
//             _statusMessage = "Impossible de vérifier le statut du paiement après plusieurs tentatives.";
//           });
//
//           _showErrorDialog();
//         }
//       }
//     }
//   }
//
//   void _showErrorDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         title: const Text("Erreur de vérification"),
//         content: const Text(
//             "Nous n'avons pas pu vérifier le statut de votre paiement. "
//                 "Veuillez vérifier votre connexion internet."
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pop(); // Fermer le dialogue
//
//               // Recommencer les vérifications
//               setState(() {
//                 _failureCount = 0;
//                 _isVerifying = true;
//                 _statusMessage = "Vérification du paiement en cours...";
//               });
//
//               _checkPaymentStatus();
//               _statusCheckTimer = Timer.periodic(const Duration(seconds: 3), (_) {
//                 if (!_redirecting) {
//                   _checkPaymentStatus();
//                 }
//               });
//             },
//             child: const Text("Réessayer"),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pop(); // Fermer le dialogue
//               Navigator.of(context).pop(); // Retourner à l'écran précédent
//             },
//             child: const Text("Retour"),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       // Empêcher le retour en arrière pendant la vérification
//       onWillPop: () async => !_isVerifying,
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text("Vérification du paiement"),
//           centerTitle: true,
//           automaticallyImplyLeading: !_isVerifying, // Désactiver le bouton retour pendant la vérification
//         ),
//         body: Center(
//           child: Padding(
//             padding: const EdgeInsets.all(24.0),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 if (_isVerifying)
//                   const CircularProgressIndicator()
//                 else if (_statusMessage.contains("confirmé"))
//                   const Icon(Icons.check_circle, color: Colors.green, size: 64)
//                 else
//                   const Icon(Icons.error_outline, color: Colors.red, size: 64),
//
//                 const SizedBox(height: 24),
//
//                 Text(
//                   _statusMessage,
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: _isVerifying
//                         ? Colors.black
//                         : _statusMessage.contains("confirmé")
//                         ? Colors.green
//                         : Colors.red,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//
//                 if (!_isVerifying && !_statusMessage.contains("confirmé"))
//                   Padding(
//                     padding: const EdgeInsets.only(top: 24),
//                     child: ElevatedButton(
//                       onPressed: () {
//                         // Recommencer les vérifications
//                         setState(() {
//                           _failureCount = 0;
//                           _isVerifying = true;
//                           _statusMessage = "Vérification du paiement en cours...";
//                         });
//
//                         _checkPaymentStatus();
//                         _statusCheckTimer = Timer.periodic(const Duration(seconds: 3), (_) {
//                           if (!_redirecting) {
//                             _checkPaymentStatus();
//                           }
//                         });
//                       },
//                       child: const Text("Réessayer"),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }