/// *************************************************************************************************
///
/// BANNER : EXPLICATION GÉNÉRALE DU SERVICE
///
/// Ce fichier définit la classe `AddressUpdateService`.
///
/// Objectif :
/// Cette classe agit comme un "orchestrateur" ou une couche logique métier pour le processus
/// de mise à jour de l'adresse d'un utilisateur. Elle ne communique pas directement avec l'API
/// mais utilise d'autres services spécialisés (`AddressApiService` pour les appels réseau et
/// `AddressValidationService` pour la validation des données).
///
/// Fonctionnement :
/// 1.  Coordonne la validation de l'adresse avant l'envoi à l'API.
/// 2.  Appelle le service API pour effectuer la mise à jour.
/// 3.  Gère les retours de l'API (succès ou erreur).
/// 4.  Interagit avec l'interface utilisateur (via `BuildContext`) pour :
/// - Gérer un état de chargement (`setLoadingState`).
/// - Afficher des messages de succès ou d'erreur (`SnackBar`).
/// 5.  Met à jour l'état global de l'application via `Provider` après une mise à jour réussie.
///
/// Utilisation :
/// Les méthodes sont statiques et conçues pour être appelées depuis la couche UI (par exemple,
/// depuis l'événement `onPressed` d'un bouton de formulaire).
///
///*************************************************************************************************
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../models/adresse.dart' as AdresseModel;
import '../../../../../models/current_user.dart' as UserModel;
import '../../../../../services/providers/current_user_provider.dart';
import 'adress_api_service.dart';
import 'adress_validation.dart';

/// Service orchestrant la mise à jour de l'adresse d'un utilisateur.
class AddressUpdateService {
  /// Gère le flux complet de mise à jour de l'adresse d'un utilisateur.
  ///
  /// [context] : Le BuildContext de l'UI pour afficher les SnackBars et accéder au Provider.
  /// [currentUser] : L'objet utilisateur actuel contenant son UUID.
  /// [addressData] : Une Map des données d'adresse à mettre à jour.
  /// [successGreen], [errorRed] : Couleurs pour les messages de feedback.
  /// [setLoadingState] : Une fonction callback pour activer/désactiver l'indicateur de chargement dans l'UI.
  static Future<void> updateUserAddress(
      BuildContext context,
      UserModel.CurrentUser currentUser,
      Map<String, dynamic> addressData, {
        required Color successGreen,
        required Color errorRed,
        required Function(bool) setLoadingState,
      }) async {
    try {
      // Signale à l'UI de démarrer l'état de chargement.
      setLoadingState(true);

      if (kDebugMode) {
        print("🚀 Début du processus de mise à jour d'adresse pour ${currentUser.uuid}");
      }

      // Détermine si une validation externe est nécessaire (si l'adresse n'est pas déjà validée).
      bool needsValidation = addressData['is_validated'] != true;

      if (needsValidation) {
        if (kDebugMode) {
          print("🔍 Adresse non validée, lancement de la validation externe...");
        }

        // Crée un objet Adresse temporaire pour le service de validation.
        final tempAdresse = AdresseModel.Adresse(
          numero: addressData['numero'],
          rue: AdresseModel.Rue(
            nomRue: addressData['rue']['nomRue'],
            localite: AdresseModel.Localite(
              commune: addressData['rue']['localite']['commune'],
              codePostal: addressData['rue']['localite']['codePostal'],
            ),
          ),
        );

        // Appelle le service de validation pour vérifier l'adresse et obtenir les coordonnées GPS.
        final validationResult = await AddressValidationService.validateAddress(tempAdresse);

        // Si la validation échoue, arrête le processus en lançant une erreur.
        if (!validationResult.isValid) {
          throw Exception(validationResult.errorMessage ?? "L'adresse fournie est invalide.");
        }

        // Enrichit la Map `addressData` avec les résultats de la validation.
        addressData['latitude'] = validationResult.latitude;
        addressData['longitude'] = validationResult.longitude;
        addressData['is_validated'] = true;
        addressData['validation_date'] = DateTime.now().toIso8601String();
      }

      // Délègue l'appel réseau au service API dédié.
      final result = await AddressApiService.updateUserAddress(
        userUuid: currentUser.uuid,
        addressData: addressData,
      );

      // Traite la réponse de l'API.
      if (result['success'] == true) {
        if (kDebugMode) {
          print("✅ Mise à jour de l'adresse réussie via l'API.");
        }

        // Met à jour les données de l'utilisateur dans l'état global de l'application.
        await _refreshUserInProvider(context);

        // Affiche un message de succès à l'utilisateur.
        _showSuccessMessage(context, "Adresse mise à jour avec succès", successGreen);

      } else {
        // Si l'API renvoie un échec, lance une exception avec le message d'erreur fourni.
        throw Exception(result['message'] ?? "Une erreur inconnue est survenue lors de la mise à jour.");
      }

    } catch (e) {
      // Capture toute exception levée durant le processus (validation, API, etc.).
      if (kDebugMode) {
        print("❌ Erreur globale dans AddressUpdateService: $e");
      }
      // Affiche un message d'erreur générique à l'utilisateur.
      _showErrorMessage(context, "Erreur: $e", errorRed);
      // Fait remonter l'erreur pour que l'UI puisse également réagir si nécessaire.
      rethrow;
    } finally {
      // Quoi qu'il arrive (succès ou erreur), signale à l'UI de terminer l'état de chargement.
      setLoadingState(false);
    }
  }

  /// Méthode privée pour rafraîchir les données de l'utilisateur via le Provider.
  ///
  /// Ceci assure que toute l'application dispose des informations les plus récentes
  /// après une modification réussie.
  static Future<void> _refreshUserInProvider(BuildContext context) async {
    try {
      // Accède au CurrentUserProvider sans écouter les changements (car on effectue une action).
      final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
      // Déclenche la méthode de rafraîchissement des données de l'utilisateur.
      await currentUserProvider.refreshCurrentUser();

      if (kDebugMode) {
        print("🔄 Données de l'utilisateur rafraîchies dans le Provider.");
      }
    } catch (e) {
      // Capture les erreurs éventuelles lors du rafraîchissement du provider pour ne pas planter l'app.
      if (kDebugMode) {
        print("⚠️ Erreur lors du rafraîchissement du Provider: $e");
      }
    }
  }

  /// Affiche une SnackBar de succès.
  static void _showSuccessMessage(BuildContext context, String message, Color successColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Affiche une SnackBar d'erreur.
  static void _showErrorMessage(BuildContext context, String message, Color errorColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Récupère l'adresse de l'utilisateur actuel et la convertit en un objet typé.
  ///
  /// [userUuid] : L'identifiant de l'utilisateur dont on veut récupérer l'adresse.
  /// Retourne un objet `UserModel.Adresse` ou `null` si l'adresse n'est pas trouvée ou en cas d'erreur.
  static Future<UserModel.Adresse?> getCurrentUserAddress(String userUuid) async {
    try {
      // Appelle le service API pour obtenir les données brutes de l'adresse.
      final addressData = await AddressApiService.getUserAddress(userUuid);

      // Vérifie si les données reçues sont valides et contiennent une clé 'adresse'.
      if (addressData != null && addressData['adresse'] != null) {
        // Convertit la Map JSON en un objet `Adresse` fortement typé.
        return UserModel.Adresse.fromJson(addressData['adresse']);
      }

      // Si aucune donnée n'est trouvée, retourne null.
      return null;
    } catch (e) {
      // En cas d'erreur durant le processus, l'affiche et retourne null.
      if (kDebugMode) {
        print("❌ Erreur lors de la récupération et de la conversion de l'adresse: $e");
      }
      return null;
    }
  }
}





// // lib/pages/profil/services/update_services/adress_update/adress_update_service.dart
//
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../../../../models/adresse.dart' as AdresseModel;
// import '../../../../../models/current_user.dart' as UserModel;
// import '../../../../../services/providers/current_user_provider.dart';
// import 'adress_api_service.dart';
// import 'adress_validation.dart';
//
// class AddressUpdateService {
//   static Future<void> updateUserAddress(
//       BuildContext context,
//       UserModel.CurrentUser currentUser,
//       Map<String, dynamic> addressData, {
//         required Color successGreen,
//         required Color errorRed,
//         required Function(bool) setLoadingState,
//       }) async {
//     try {
//       setLoadingState(true);
//
//       if (kDebugMode) {
//         print("🚀 Mise à jour adresse pour ${currentUser.uuid}");
//       }
//
//       // Validation supplémentaire si nécessaire
//       bool needsValidation = addressData['is_validated'] != true;
//
//       if (needsValidation) {
//         if (kDebugMode) {
//           print("🔍 Validation supplémentaire...");
//         }
//
//         final tempAdresse = AdresseModel.Adresse(
//           numero: addressData['numero'],
//           rue: AdresseModel.Rue(
//             nomRue: addressData['rue']['nomRue'],
//             localite: AdresseModel.Localite(
//               commune: addressData['rue']['localite']['commune'],
//               codePostal: addressData['rue']['localite']['codePostal'],
//             ),
//           ),
//         );
//
//         final validationResult = await AddressValidationService.validateAddress(tempAdresse);
//
//         if (!validationResult.isValid) {
//           throw Exception(validationResult.errorMessage ?? "Adresse invalide");
//         }
//
//         addressData['latitude'] = validationResult.latitude;
//         addressData['longitude'] = validationResult.longitude;
//         addressData['is_validated'] = true;
//         addressData['validation_date'] = DateTime.now().toIso8601String();
//       }
//
//       // Appel API
//       final result = await AddressApiService.updateUserAddress(
//         userUuid: currentUser.uuid,
//         addressData: addressData,
//       );
//
//       if (result['success'] == true) {
//         if (kDebugMode) {
//           print("✅ Succès mise à jour");
//         }
//
//         // ✅ NOUVELLE LIGNE - Recharger l'utilisateur depuis le provider
//         await _refreshUserInProvider(context);
//
//         _showSuccessMessage(context, "Adresse mise à jour avec succès", successGreen);
//
//       } else {
//         throw Exception(result['message'] ?? "Erreur inconnue");
//       }
//
//     } catch (e) {
//       if (kDebugMode) {
//         print("❌ Erreur: $e");
//       }
//       _showErrorMessage(context, "Erreur: $e", errorRed);
//       rethrow;
//     } finally {
//       setLoadingState(false);
//     }
//   }
//
//   // ✅ NOUVELLE MÉTHODE - Recharge l'utilisateur via le provider
//   static Future<void> _refreshUserInProvider(BuildContext context) async {
//     try {
//       // Importer le provider
//       final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//       await currentUserProvider.refreshCurrentUser();
//
//       if (kDebugMode) {
//         print("🔄 Provider mis à jour après modification adresse");
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print("⚠️ Erreur rechargement provider: $e");
//       }
//     }
//   }
//
//
//
//   static void _showSuccessMessage(BuildContext context, String message, Color successColor) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             Icon(Icons.check_circle, color: Colors.white),
//             SizedBox(width: 8),
//             Expanded(child: Text(message)),
//           ],
//         ),
//         backgroundColor: successColor,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//         duration: Duration(seconds: 3),
//       ),
//     );
//   }
//
//   static void _showErrorMessage(BuildContext context, String message, Color errorColor) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             Icon(Icons.error, color: Colors.white),
//             SizedBox(width: 8),
//             Expanded(child: Text(message)),
//           ],
//         ),
//         backgroundColor: errorColor,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//         duration: Duration(seconds: 4),
//       ),
//     );
//   }
//
//
//
//   static Future<UserModel.Adresse?> getCurrentUserAddress(String userUuid) async {
//     try {
//       final addressData = await AddressApiService.getUserAddress(userUuid);
//
//       if (addressData != null && addressData['adresse'] != null) {
//         // Utiliser le bon constructeur selon votre modèle CurrentUser
//         return UserModel.Adresse.fromJson(addressData['adresse']);
//       }
//
//       return null;
//     } catch (e) {
//       if (kDebugMode) {
//         print("❌ Erreur récupération: $e");
//       }
//       return null;
//     }
//   }
// }