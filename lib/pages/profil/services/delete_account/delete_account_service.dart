////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//             SERVICE DE GESTION DE LA SUPPRESSION DE COMPTE                   //
//                                                                            //
//  Ce fichier définit `DeleteAccountService`, une classe utilitaire avec des //
//  méthodes statiques qui orchestrent le processus complet et irréversible   //
//  de suppression d'un compte utilisateur.                                   //
//                                                                            //
//  Le processus est sécurisé par plusieurs étapes :                          //
//  1. Une double confirmation via une boîte de dialogue interactive.         //
//  2. Un appel authentifié à l'API backend pour supprimer les données        //
//     côté serveur (Django). La suppression du compte Firebase est           //
//     également gérée par le backend.                                        //
//  3. L'affichage d'un résumé détaillé des éléments supprimés.               //
//  4. La déconnexion et la redirection finale de l'utilisateur.              //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'package:hairbnb/models/current_user.dart';
import 'package:hairbnb/pages/authentification/login_page.dart';
import 'package:hairbnb/services/providers/current_user_provider.dart';

/// Une classe de service contenant uniquement des méthodes statiques pour
/// gérer la suppression de compte.
class DeleteAccountService {
  /// L'URL de base de l'API backend.
  static const String baseUrl = 'https://www.hairbnb.site';

  /// Orchestre le processus complet de suppression du compte de l'utilisateur.
  ///
  /// [context] : Le `BuildContext` pour afficher les dialogues et les snackbars.
  /// [currentUser] : L'objet de l'utilisateur à supprimer.
  /// [successGreen] : La couleur à utiliser pour les messages de succès.
  /// [errorRed] : La couleur à utiliser pour les messages d'erreur.
  /// [setLoadingState] : Une fonction de callback pour gérer l'état de chargement dans l'UI parente.
  static Future<void> deleteUserAccount({
    required BuildContext context,
    required CurrentUser currentUser,
    required Color successGreen,
    required Color errorRed,
    required Function(bool) setLoadingState,
  }) async {
    // Étape 1 : Demande une confirmation explicite et sécurisée à l'utilisateur.
    bool confirmed = await _showDeleteConfirmationDialog(context, errorRed);
    if (!confirmed) return; // Arrête le processus si l'utilisateur annule.

    setLoadingState(true); // Active l'indicateur de chargement dans l'UI.

    try {
      // Étape 2 : Récupère le token d'authentification Firebase pour la requête API.
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) throw Exception('Utilisateur non authentifié');

      final String? idToken = await firebaseUser.getIdToken();
      if (idToken == null) throw Exception('Impossible de récupérer le token d\'authentification');

      // Étape 3 : Appelle l'API backend pour effectuer la suppression côté serveur.
      final response = await http.post(
        Uri.parse('$baseUrl/api/delete_my_profile_firebase/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          // Le backend exige ces paramètres comme double sécurité.
          'confirmation': 'SUPPRIMER',
          'anonymize_reviews': true,
        }),
      );

      setLoadingState(false); // Désactive le chargement.

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        // Étape 4 : Affiche un résumé de ce qui a été supprimé. La redirection est gérée dans cette méthode.
        await _showDeletionSummary(context, responseData, successGreen);
      } else {
        // Gère les erreurs renvoyées par l'API.
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la suppression du compte');
      }
    } catch (e) {
      // Gère les erreurs de connexion ou autres exceptions.
      setLoadingState(false);
      _showErrorDialog(context, 'Erreur lors de la suppression du compte: $e', errorRed);
    }
  }

  /// Affiche une boîte de dialogue de confirmation très stricte avant la suppression.
  ///
  /// L'utilisateur doit taper le mot "SUPPRIMER" pour activer le bouton de suppression,
  /// ce qui empêche les suppressions accidentelles.
  static Future<bool> _showDeleteConfirmationDialog(BuildContext context, Color errorRed) async {
    final TextEditingController confirmController = TextEditingController();
    bool isConfirmed = false;

    // `showDialog` retourne la valeur passée à `Navigator.of(context).pop()`.
    // Ici, nous ne l'utilisons pas car `isConfirmed` est géré dans la portée de la méthode principale.
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // `StatefulBuilder` est utilisé pour gérer l'état local du bouton (activé/désactivé)
        // sans avoir besoin de créer un widget `StatefulWidget` complet.
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(children: [Icon(Icons.warning, color: errorRed, size: 28), const SizedBox(width: 8), const Expanded(child: Text('Supprimer le compte', style: TextStyle(fontWeight: FontWeight.bold)))]),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('⚠️ ATTENTION: Cette action est IRRÉVERSIBLE!', style: TextStyle(color: errorRed, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  const Text('La suppression de votre compte entraînera la perte définitive de:', style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 8),
                  const Text('• Toutes vos informations personnelles\n• Votre salon et ses images\n• Vos services et promotions\n• Votre historique de rendez-vous\n• Votre compte Firebase', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 16),
                  const Text('Pour confirmer, tapez "SUPPRIMER" ci-dessous:', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: confirmController,
                    decoration: InputDecoration(
                      hintText: 'Tapez SUPPRIMER',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: errorRed)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: errorRed, width: 2)),
                    ),
                    onChanged: (value) {
                      // Met à jour l'état du bouton à chaque frappe.
                      setState(() {
                        isConfirmed = value.toUpperCase() == 'SUPPRIMER';
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Annule et ferme le dialogue.
                    isConfirmed = false;
                  },
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: isConfirmed ? () {
                    Navigator.of(context).pop(); // Confirme et ferme le dialogue.
                    isConfirmed = true; // La valeur sera conservée dans la portée externe.
                  } : null, // Le bouton est désactivé si la condition n'est pas remplie.
                  style: ElevatedButton.styleFrom(backgroundColor: errorRed, foregroundColor: Colors.white),
                  child: const Text('SUPPRIMER'),
                ),
              ],
            );
          },
        );
      },
    );

    // Retourne `true` uniquement si le dialogue a été confirmé.
    return isConfirmed;
  }

  /// Affiche une boîte de dialogue résumant les données qui ont été supprimées.
  static Future<void> _showDeletionSummary(BuildContext context, Map<String, dynamic> responseData, Color successGreen) async {
    final deletionSummary = responseData['deletion_summary'];
    final deletedItems = deletionSummary['deleted_items'];

    await showDialog(
      context: context,
      barrierDismissible: false, // Empêche la fermeture en cliquant à l'extérieur.
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [Icon(Icons.check_circle, color: successGreen, size: 28), const SizedBox(width: 8), const Text('Compte supprimé')]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('✅ ${responseData['message']}'),
              const SizedBox(height: 12),
              const Text('Éléments supprimés:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              // Itère sur les résultats pour afficher un résumé.
              ...deletedItems.entries.map((entry) {
                if (entry.value > 0) return Text('• ${entry.key}: ${entry.value}');
                return const SizedBox.shrink(); // N'affiche rien si la valeur est 0.
              }).toList(),
              if (responseData['firebase_account_deleted'] == true)
                const Text('• Compte Firebase supprimé', style: TextStyle(color: Colors.green)),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Ferme le dialogue.
                await _logoutAndRedirect(context); // Déclenche la redirection finale.
              },
              style: ElevatedButton.styleFrom(backgroundColor: successGreen),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  /// Affiche une boîte de dialogue d'erreur générique.
  static void _showErrorDialog(BuildContext context, String message, Color errorRed) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [Icon(Icons.error, color: errorRed, size: 28), const SizedBox(width: 8), const Text('Erreur')]),
          content: Text(message),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
        );
      },
    );
  }

  /// Gère la déconnexion finale de l'utilisateur et la redirection vers la page de connexion.
  static Future<void> _logoutAndRedirect(BuildContext context) async {
    try {
      // Nettoie l'état local de l'utilisateur.
      Provider.of<CurrentUserProvider>(context, listen: false).clearUser();

      // Déconnecte de Firebase.
      await FirebaseAuth.instance.signOut();

      // Redirige vers la page de connexion et supprime toutes les routes précédentes
      // pour empêcher l'utilisateur de revenir en arrière.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
            (Route<dynamic> route) => false,
      );
    } catch (e) {
      // En cas d'erreur de déconnexion, force la redirection pour éviter que l'utilisateur
      // reste bloqué sur une page qui requiert une authentification.
      Provider.of<CurrentUserProvider>(context, listen: false).clearUser();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
            (Route<dynamic> route) => false,
      );
    }
  }
}






// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:hairbnb/models/current_user.dart';
// import 'package:hairbnb/pages/authentification/login_page.dart';
// import 'package:hairbnb/services/providers/current_user_provider.dart';
// import 'package:http/http.dart' as http;
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:provider/provider.dart';
//
//
// class DeleteAccountService {
//   static const String baseUrl = 'https://www.hairbnb.site';
//
//   /// Supprime complètement le compte de l'utilisateur (Django + Firebase)
//   static Future<void> deleteUserAccount({
//     required BuildContext context,
//     required CurrentUser currentUser,
//     required Color successGreen,
//     required Color errorRed,
//     required Function(bool) setLoadingState,
//   }) async {
//     // 1. Confirmation avec dialog de sécurité
//     bool confirmed = await _showDeleteConfirmationDialog(context, errorRed);
//     if (!confirmed) return;
//
//     setLoadingState(true);
//
//     try {
//       // 2. Récupérer le token Firebase
//       final User? firebaseUser = FirebaseAuth.instance.currentUser;
//       if (firebaseUser == null) {
//         throw Exception('Utilisateur non authentifié');
//       }
//
//       final String? idToken = await firebaseUser.getIdToken();
//       if (idToken == null) {
//         throw Exception('Impossible de récupérer le token d\'authentification');
//       }
//
//       // 3. Appel à l'API Django pour supprimer le compte
//       final response = await http.post(
//         Uri.parse('$baseUrl/api/delete_my_profile_firebase/'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $idToken',
//         },
//         body: jsonEncode({
//           'confirmation': 'SUPPRIMER',
//           'anonymize_reviews': true,
//         }),
//       );
//
//       setLoadingState(false);
//
//       if (response.statusCode == 200) {
//         final responseData = jsonDecode(utf8.decode(response.bodyBytes));
//
//         // 4. Afficher le résultat de la suppression
//         // The redirection will now be handled within _showDeletionSummary
//         await _showDeletionSummary(context, responseData, successGreen);
//
//
//       } else {
//         // Gérer les erreurs de l'API
//         final errorData = jsonDecode(response.body);
//         throw Exception(errorData['message'] ?? 'Erreur lors de la suppression du compte');
//       }
//
//     } catch (e) {
//       setLoadingState(false);
//       _showErrorDialog(context, 'Erreur lors de la suppression du compte: $e', errorRed);
//     }
//   }
//
//   /// Dialog de confirmation avec double vérification
//   static Future<bool> _showDeleteConfirmationDialog(BuildContext context, Color errorRed) async {
//     final TextEditingController confirmController = TextEditingController();
//     bool isConfirmed = false;
//
//     await showDialog<bool>(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return StatefulBuilder(
//           builder: (context, setState) {
//             return AlertDialog(
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//               title: Row(
//                 children: [
//                   Icon(Icons.warning, color: errorRed, size: 28),
//                   const SizedBox(width: 8),
//                   const Expanded(
//                     child: Text(
//                       'Supprimer le compte',
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                   ),
//                 ],
//               ),
//               content: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     '⚠️ ATTENTION: Cette action est IRRÉVERSIBLE!',
//                     style: TextStyle(
//                       color: errorRed,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   const Text(
//                     'La suppression de votre compte entraînera la perte définitive de:',
//                     style: TextStyle(fontSize: 14),
//                   ),
//                   const SizedBox(height: 8),
//                   const Text(
//                     '• Toutes vos informations personnelles\n'
//                         '• Votre salon et ses images\n'
//                         '• Vos services et promotions\n'
//                         '• Votre historique de rendez-vous\n'
//                         '• Votre compte Firebase',
//                     style: TextStyle(fontSize: 13),
//                   ),
//                   const SizedBox(height: 16),
//                   Text(
//                     'Pour confirmer, tapez "SUPPRIMER" ci-dessous:',
//                     style: TextStyle(fontWeight: FontWeight.w500),
//                   ),
//                   const SizedBox(height: 8),
//                   TextField(
//                     controller: confirmController,
//                     decoration: InputDecoration(
//                       hintText: 'Tapez SUPPRIMER',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                         borderSide: BorderSide(color: errorRed),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                         borderSide: BorderSide(color: errorRed, width: 2),
//                       ),
//                     ),
//                     onChanged: (value) {
//                       setState(() {
//                         isConfirmed = value.toUpperCase() == 'SUPPRIMER';
//                       });
//                     },
//                   ),
//                 ],
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () {
//                     Navigator.of(context).pop();
//                     isConfirmed = false;
//                   },
//                   child: const Text('Annuler'),
//                 ),
//                 ElevatedButton(
//                   onPressed: isConfirmed
//                       ? () {
//                     Navigator.of(context).pop();
//                     isConfirmed = true;
//                   }
//                       : null,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: errorRed,
//                     foregroundColor: Colors.white,
//                   ),
//                   child: const Text('SUPPRIMER'),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//
//     return isConfirmed;
//   }
//
//   /// Affiche le résumé de la suppression
//   static Future<void> _showDeletionSummary(BuildContext context, Map<String, dynamic> responseData, Color successGreen) async {
//     final deletionSummary = responseData['deletion_summary'];
//     final deletedItems = deletionSummary['deleted_items'];
//
//     await showDialog( // Changed to await showDialog
//       context: context,
//       barrierDismissible: false, // Make it non-dismissible until OK is pressed or countdown finishes
//       builder: (context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//           title: Row(
//             children: [
//               Icon(Icons.check_circle, color: successGreen, size: 28),
//               const SizedBox(width: 8),
//               const Text('Compte supprimé'),
//             ],
//           ),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text('✅ ${responseData['message']}'),
//               const SizedBox(height: 12),
//               const Text('Éléments supprimés:', style: TextStyle(fontWeight: FontWeight.bold)),
//               const SizedBox(height: 8),
//               ...deletedItems.entries.map((entry) {
//                 if (entry.value > 0) {
//                   return Text('• ${entry.key}: ${entry.value}');
//                 }
//                 return const SizedBox.shrink();
//               }).toList(),
//               if (responseData['firebase_account_deleted'] == true)
//                 const Text('• Compte Firebase supprimé', style: TextStyle(color: Colors.green)),
//             ],
//           ),
//           actions: [
//             ElevatedButton(
//               onPressed: () async {
//                 Navigator.of(context).pop(); // Dismiss the dialog
//                 await _logoutAndRedirect(context); // Redirect to login page
//               },
//               style: ElevatedButton.styleFrom(backgroundColor: successGreen),
//               child: const Text('OK', style: TextStyle(color: Colors.white)),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   /// Affiche un dialog d'erreur
//   static void _showErrorDialog(BuildContext context, String message, Color errorRed) {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//           title: Row(
//             children: [
//               Icon(Icons.error, color: errorRed, size: 28),
//               const SizedBox(width: 8),
//               const Text('Erreur'),
//             ],
//           ),
//           content: Text(message),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: const Text('OK'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   /// Déconnecte l'utilisateur et redirige vers la page de connexion
//   static Future<void> _logoutAndRedirect(BuildContext context) async {
//     try {
//       Provider.of<CurrentUserProvider>(context, listen: false).clearUser();
//
//       await FirebaseAuth.instance.signOut();
//
//       // Rediriger vers LoginPage et vider la pile de navigation
//       Navigator.of(context).pushAndRemoveUntil(
//         MaterialPageRoute(builder: (context) => const LoginPage()),
//             (Route<dynamic> route) => false,
//       );
//     } catch (e) {
//       // En cas d'erreur de déconnexion, forcer la redirection
//
//       Provider.of<CurrentUserProvider>(context, listen: false).clearUser();
//       Navigator.of(context).pushAndRemoveUntil(
//         MaterialPageRoute(builder: (context) => const LoginPage()),
//             (Route<dynamic> route) => false,
//       );
//     }
//   }
// }
