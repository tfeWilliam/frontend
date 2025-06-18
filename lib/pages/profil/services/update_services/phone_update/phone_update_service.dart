////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//       SERVICE DE GESTION DE LA MISE À JOUR DU NUMÉRO DE TÉLÉPHONE            //
//                                                                            //
//  Ce fichier définit `PhoneUpdateService`, une classe de service qui        //
//  centralise toute la logique métier pour la validation, le formatage et la //
//  mise à jour du numéro de téléphone d'un utilisateur.                      //
//                                                                            //
//  Responsabilités :                                                         //
//  - Valider un numéro de téléphone selon des règles locales et des formats  //
//    internationaux courants.                                                //
//  - Formater les numéros pour un affichage cohérent.                        //
//  - Orchestrer le processus de mise à jour complet : validation locale,     //
//    appel à l'API (`PhoneApiService`), et gestion des retours (succès ou    //
//    erreur) avec des notifications à l'utilisateur.                         //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../models/current_user.dart';
import '../../../../../services/providers/current_user_provider.dart';
import 'phone_api_service.dart';

/// Une classe de service contenant uniquement des méthodes statiques pour
/// gérer la validation et la mise à jour des numéros de téléphone.
class PhoneUpdateService {
  /// Valide le format du numéro de téléphone en fonction des règles du backend et de formats courants.
  ///
  /// [phone] : Le numéro de téléphone à valider.
  ///
  /// Retourne un `PhoneValidationResult` contenant le résultat de la validation.
  static PhoneValidationResult validatePhoneNumber(String phone) {
    // Nettoie le numéro pour une validation de base.
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');

    if (phone.trim().isEmpty) {
      return PhoneValidationResult(isValid: false, message: 'Le numéro de téléphone est requis');
    }

    // Validation de base correspondant aux règles du backend Django.
    if (cleanPhone.length < 3) {
      return PhoneValidationResult(isValid: false, message: 'Numéro de téléphone invalide (trop court)');
    }
    if (cleanPhone.length > 20) {
      return PhoneValidationResult(isValid: false, message: 'Le numéro de téléphone ne peut pas dépasser 20 caractères');
    }
    if (!RegExp(r'^[\d\+\s\-\(\)]*$').hasMatch(phone)) {
      return PhoneValidationResult(isValid: false, message: 'Le numéro de téléphone contient des caractères invalides');
    }

    // Validation plus poussée pour des formats internationaux connus.
    final phonePatterns = [
      RegExp(r'^\+?[1-9]\d{2,19}$'), // International
      RegExp(r'^\+?32\d{8,9}$'),   // Belgique
      RegExp(r'^\+?33\d{9}$'),     // France
      RegExp(r'^0\d{8,9}$'),       // National BE/FR
      RegExp(r'^\+?1\d{10}$'),     // US/Canada
      RegExp(r'^\+?44\d{10}$'),    // UK
    ];
    bool matchesKnownPattern = phonePatterns.any((pattern) => pattern.hasMatch(cleanPhone));

    // Si le numéro respecte les règles de base, il est accepté même s'il ne correspond
    // à aucun format international spécifique pour plus de flexibilité.
    return PhoneValidationResult(
      isValid: true,
      message: matchesKnownPattern ? 'Numéro de téléphone valide' : 'Numéro de téléphone accepté',
      formattedPhone: _formatPhone(phone),
    );
  }

  /// Formate un numéro de téléphone pour un affichage lisible et standardisé.
  static String _formatPhone(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Formats spécifiques pour la Belgique et la France.
    if (cleanPhone.startsWith('+32')) {
      final number = cleanPhone.substring(3);
      if (number.length >= 8) return '+32 ${number.substring(0, 3)} ${number.substring(3, 5)} ${number.substring(5)}';
    }
    if (cleanPhone.startsWith('+33')) {
      final number = cleanPhone.substring(3);
      if (number.length >= 9) return '+33 ${number.substring(0, 1)} ${number.substring(1, 3)} ${number.substring(3, 5)} ${number.substring(5, 7)} ${number.substring(7)}';
    }
    // Format par défaut pour les numéros nationaux.
    if (cleanPhone.startsWith('0') && cleanPhone.length >= 9) {
      return '${cleanPhone.substring(0, 3)} ${cleanPhone.substring(3, 5)} ${cleanPhone.substring(5, 7)} ${cleanPhone.substring(7)}';
    }

    return phone; // Retourne l'original si aucun format ne correspond.
  }

  /// Orchestre le processus complet de mise à jour du numéro de téléphone.
  ///
  /// [context] : Le `BuildContext` pour afficher les notifications.
  /// [currentUser] : L'objet de l'utilisateur dont le numéro doit être mis à jour.
  /// [newPhone] : Le nouveau numéro de téléphone.
  /// [setLoadingState] : Callback pour gérer l'état de chargement dans l'UI parente.
  ///
  /// Retourne `true` en cas de succès complet, `false` sinon.
  static Future<bool> updateUserPhoneNumber(
      BuildContext context,
      CurrentUser currentUser,
      String newPhone, {
        required Color successGreen,
        required Color errorRed,
        required Function(bool) setLoadingState,
      }) async {
    // 1. Validation locale du format du numéro.
    final validation = validatePhoneNumber(newPhone);
    if (!validation.isValid) {
      _showErrorSnackBar(context, validation.message, errorRed);
      return false;
    }

    // 2. Vérification pour éviter un appel API inutile si le numéro n'a pas changé.
    final formattedNewPhone = validation.formattedPhone ?? newPhone;
    if (currentUser.numeroTelephone == formattedNewPhone || currentUser.numeroTelephone == newPhone) {
      _showInfoSnackBar(context, 'Le numéro de téléphone est identique', Colors.orange);
      return false;
    }

    // 3. Activation de l'état de chargement.
    setLoadingState(true);

    try {
      // 4. Appel au service API pour effectuer la mise à jour.
      final result = await PhoneApiService.updatePhone(currentUser.uuid, newPhone.trim());
      setLoadingState(false); // Désactivation du chargement après l'appel.

      // 5. Traitement du résultat de l'API.
      if (result.success) {
        await _handleSuccessfulUpdate(context, currentUser, newPhone.trim(), successGreen);
        return true;
      } else {
        _handleUpdateError(context, result, errorRed);
        return false;
      }
    } catch (e) {
      // 6. Gestion des erreurs de connexion ou autres exceptions.
      setLoadingState(false);
      _showErrorSnackBar(context, 'Erreur inattendue: $e', errorRed);
      return false;
    }
  }

  //region Méthodes de gestion de la réponse
  /// Gère les actions à effectuer après une mise à jour réussie.
  static Future<void> _handleSuccessfulUpdate(BuildContext context, CurrentUser currentUser, String newPhone, Color successGreen) async {
    // Met à jour l'objet utilisateur localement pour un feedback immédiat.
    currentUser.numeroTelephone = newPhone;
    try {
      // Déclenche une mise à jour complète de l'utilisateur via le provider pour assurer la synchronisation.
      final userProvider = Provider.of<CurrentUserProvider>(context, listen: false);
      await userProvider.fetchCurrentUser();
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors du rafraîchissement des données utilisateur: $e');
      }
    }
    _showSuccessSnackBar(context, 'Numéro de téléphone mis à jour avec succès', successGreen);
  }

  /// Gère les erreurs de l'API en affichant un message pertinent.
  static void _handleUpdateError(BuildContext context, PhoneUpdateResult result, Color errorRed) {
    String message = result.message;
    IconData icon = Icons.error_outline;

    // Personnalise le message et l'icône en fonction du type d'erreur renvoyé par l'API.
    switch (result.errorType) {
      case PhoneUpdateErrorType.validation: icon = Icons.warning; break;
      case PhoneUpdateErrorType.authentication: icon = Icons.lock_outline; message = 'Session expirée. Veuillez vous reconnecter.'; break;
      case PhoneUpdateErrorType.authorization: icon = Icons.block; message = 'Vous n\'êtes pas autorisé à modifier ce numéro.'; break;
      case PhoneUpdateErrorType.notFound: icon = Icons.person_off; message = 'Utilisateur non trouvé.'; break;
      case PhoneUpdateErrorType.network: icon = Icons.wifi_off; message = 'Problème de connexion. Vérifiez votre réseau.'; break;
      case PhoneUpdateErrorType.server: icon = Icons.cloud_off; break;
      default: break;
    }
    _showErrorSnackBar(context, message, errorRed, icon: icon);
  }
  //endregion

  //region Méthodes d'affichage des SnackBars
  /// Affiche un `SnackBar` stylisé pour un message de succès.
  static void _showSuccessSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [const Icon(Icons.check_circle, color: Colors.white), const SizedBox(width: 12), Expanded(child: Text(message))]),
      backgroundColor: color, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(10), duration: const Duration(seconds: 3),
    ));
  }

  /// Affiche un `SnackBar` stylisé pour un message d'erreur.
  static void _showErrorSnackBar(BuildContext context, String message, Color color, {IconData? icon}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [Icon(icon ?? Icons.error_outline, color: Colors.white), const SizedBox(width: 12), Expanded(child: Text(message))]),
      backgroundColor: color, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(10), duration: const Duration(seconds: 4),
    ));
  }

  /// Affiche un `SnackBar` stylisé pour un message d'information.
  static void _showInfoSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [const Icon(Icons.info_outline, color: Colors.white), const SizedBox(width: 12), Expanded(child: Text(message))]),
      backgroundColor: color, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(10), duration: const Duration(seconds: 2),
    ));
  }
//endregion
}

/// Un modèle de données pour encapsuler le résultat d'une validation de numéro de téléphone.
class PhoneValidationResult {
  /// `true` si le numéro est considéré comme valide.
  final bool isValid;
  /// Le message à afficher à l'utilisateur concernant la validation.
  final String message;
  /// Le numéro formaté, si la validation a réussi.
  final String? formattedPhone;

  PhoneValidationResult({required this.isValid, required this.message, this.formattedPhone});
}











// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../../../../models/current_user.dart';
// import '../../../../../services/providers/current_user_provider.dart';
// import 'phone_api_service.dart';
//
// class PhoneUpdateService {
//   /// Valide le format du numéro de téléphone selon les règles du backend
//   static PhoneValidationResult validatePhoneNumber(String phone) {
//     // Supprimer les espaces et caractères spéciaux pour la validation
//     final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
//
//     // Vérifier que le numéro n'est pas vide
//     if (phone.trim().isEmpty) {
//       return PhoneValidationResult(
//         isValid: false,
//         message: 'Le numéro de téléphone est requis',
//       );
//     }
//
//     // Vérification correspondant au backend Django (longueur > 3)
//     if (cleanPhone.length < 3) {
//       return PhoneValidationResult(
//         isValid: false,
//         message: 'Numéro de téléphone invalide (trop court)',
//       );
//     }
//
//     // Vérifier la longueur maximum raisonnable
//     if (cleanPhone.length > 20) {
//       return PhoneValidationResult(
//         isValid: false,
//         message: 'Le numéro de téléphone ne peut pas dépasser 20 caractères',
//       );
//     }
//
//     // Vérifier que le numéro ne contient que des chiffres et caractères autorisés
//     if (!RegExp(r'^[\d\+\s\-\(\)]*$').hasMatch(phone)) {
//       return PhoneValidationResult(
//         isValid: false,
//         message: 'Le numéro de téléphone contient des caractères invalides',
//       );
//     }
//
//     // Validation plus poussée pour les formats courants
//     final phonePatterns = [
//       RegExp(r'^\+?[1-9]\d{2,19}$'),     // Format international basique
//       RegExp(r'^\+?32\d{8,9}$'),         // Format belge
//       RegExp(r'^\+?33\d{9}$'),           // Format français
//       RegExp(r'^0\d{8,9}$'),             // Format national belge/français
//       RegExp(r'^\+?1\d{10}$'),           // Format américain/canadien
//       RegExp(r'^\+?44\d{10}$'),          // Format britannique
//     ];
//
//     // Vérifier qu'au moins un pattern correspond (pour les numéros bien formatés)
//     bool matchesKnownPattern = phonePatterns.any((pattern) => pattern.hasMatch(cleanPhone));
//
//     // Si le numéro ne correspond à aucun pattern mais respecte les règles de base, l'accepter quand même
//     // (pour permettre des formats moins courants)
//
//     return PhoneValidationResult(
//       isValid: true,
//       message: matchesKnownPattern ? 'Numéro de téléphone valide' : 'Numéro de téléphone accepté',
//       formattedPhone: _formatPhone(phone),
//     );
//   }
//
//   /// Formate le numéro de téléphone pour un affichage cohérent
//   static String _formatPhone(String phone) {
//     final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
//
//     // Si le numéro commence par +32 (Belgique)
//     if (cleanPhone.startsWith('+32')) {
//       final number = cleanPhone.substring(3);
//       if (number.length >= 8) {
//         return '+32 ${number.substring(0, 3)} ${number.substring(3, 5)} ${number.substring(5)}';
//       }
//     }
//
//     // Si le numéro commence par +33 (France)
//     if (cleanPhone.startsWith('+33')) {
//       final number = cleanPhone.substring(3);
//       if (number.length >= 9) {
//         return '+33 ${number.substring(0, 1)} ${number.substring(1, 3)} ${number.substring(3, 5)} ${number.substring(5, 7)} ${number.substring(7)}';
//       }
//     }
//
//     // Format par défaut : groupes de 2 ou 3 chiffres
//     if (cleanPhone.startsWith('0') && cleanPhone.length >= 9) {
//       return '${cleanPhone.substring(0, 3)} ${cleanPhone.substring(3, 5)} ${cleanPhone.substring(5, 7)} ${cleanPhone.substring(7)}';
//     }
//
//     return phone; // Retourner le numéro original si aucun format spécifique
//   }
//
//   /// Met à jour le numéro de téléphone de l'utilisateur
//   static Future<bool> updateUserPhoneNumber(
//       BuildContext context,
//       CurrentUser currentUser,
//       String newPhone, {
//         required Color successGreen,
//         required Color errorRed,
//         required Function(bool) setLoadingState,
//       }) async {
//     // 1. Validation du numéro de téléphone
//     final validation = validatePhoneNumber(newPhone);
//     if (!validation.isValid) {
//       _showErrorSnackBar(context, validation.message, errorRed);
//       return false;
//     }
//
//     // 2. Vérifier si le numéro a vraiment changé
//     final formattedNewPhone = validation.formattedPhone ?? newPhone;
//     if (currentUser.numeroTelephone == formattedNewPhone ||
//         currentUser.numeroTelephone == newPhone) {
//       _showInfoSnackBar(context, 'Le numéro de téléphone est identique', Colors.orange);
//       return false;
//     }
//
//     // 3. Démarrer l'état de chargement
//     setLoadingState(true);
//
//     try {
//       // 4. Appeler l'API pour mettre à jour le numéro
//       final result = await PhoneApiService.updatePhone(currentUser.uuid, newPhone.trim());
//
//       // 5. Désactiver l'état de chargement
//       setLoadingState(false);
//
//       // 6. Traiter le résultat
//       if (result.success) {
//         // Succès : mettre à jour localement et rafraîchir
//         await _handleSuccessfulUpdate(context, currentUser, newPhone.trim(), successGreen);
//         return true;
//       } else {
//         // Échec : afficher le message d'erreur approprié
//         _handleUpdateError(context, result, errorRed);
//         return false;
//       }
//     } catch (e) {
//       // 7. Gestion des erreurs inattendues
//       setLoadingState(false);
//       _showErrorSnackBar(context, 'Erreur inattendue: $e', errorRed);
//       return false;
//     }
//   }
//
//   /// Gère la mise à jour réussie
//   static Future<void> _handleSuccessfulUpdate(
//       BuildContext context,
//       CurrentUser currentUser,
//       String newPhone,
//       Color successGreen,
//       ) async {
//     // 1. Mettre à jour localement
//     currentUser.numeroTelephone = newPhone;
//
//     // 2. Mettre à jour via le provider pour propager le changement
//     try {
//       final userProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//       await userProvider.fetchCurrentUser();
//     } catch (e) {
//       print('Erreur lors du rafraîchissement des données utilisateur: $e');
//       // Continuer même si le rafraîchissement échoue
//     }
//
//     // 3. Afficher le message de succès
//     _showSuccessSnackBar(context, 'Numéro de téléphone mis à jour avec succès', successGreen);
//   }
//
//   /// Gère les erreurs de mise à jour avec messages spécifiques au backend Django
//   static void _handleUpdateError(
//       BuildContext context,
//       PhoneUpdateResult result,
//       Color errorRed,
//       ) {
//     String message = result.message;
//     IconData icon = Icons.error_outline;
//
//     // Personnaliser le message et l'icône selon le type d'erreur
//     switch (result.errorType) {
//       case PhoneUpdateErrorType.validation:
//         icon = Icons.warning;
//         // Le message du backend Django est déjà descriptif
//         break;
//       case PhoneUpdateErrorType.authentication:
//         icon = Icons.lock_outline;
//         message = 'Session expirée. Veuillez vous reconnecter.';
//         break;
//       case PhoneUpdateErrorType.authorization:
//         icon = Icons.block;
//         message = 'Vous n\'êtes pas autorisé à modifier ce numéro.';
//         break;
//       case PhoneUpdateErrorType.notFound:
//         icon = Icons.person_off;
//         message = 'Utilisateur non trouvé.';
//         break;
//       case PhoneUpdateErrorType.network:
//         icon = Icons.wifi_off;
//         message = 'Problème de connexion. Vérifiez votre réseau.';
//         break;
//       case PhoneUpdateErrorType.server:
//         icon = Icons.cloud_off;
//         // Utiliser le message du serveur qui peut être plus descriptif
//         break;
//       default:
//         break;
//     }
//
//     _showErrorSnackBar(context, message, errorRed, icon: icon);
//   }
//
//   /// Affiche un SnackBar de succès
//   static void _showSuccessSnackBar(BuildContext context, String message, Color color) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             const Icon(Icons.check_circle, color: Colors.white),
//             const SizedBox(width: 12),
//             Expanded(child: Text(message)),
//           ],
//         ),
//         backgroundColor: color,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//         margin: const EdgeInsets.all(10),
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }
//
//   /// Affiche un SnackBar d'erreur
//   static void _showErrorSnackBar(BuildContext context, String message, Color color, {IconData? icon}) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             Icon(icon ?? Icons.error_outline, color: Colors.white),
//             const SizedBox(width: 12),
//             Expanded(child: Text(message)),
//           ],
//         ),
//         backgroundColor: color,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//         margin: const EdgeInsets.all(10),
//         duration: const Duration(seconds: 4),
//       ),
//     );
//   }
//
//   /// Affiche un SnackBar d'information
//   static void _showInfoSnackBar(BuildContext context, String message, Color color) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             const Icon(Icons.info_outline, color: Colors.white),
//             const SizedBox(width: 12),
//             Expanded(child: Text(message)),
//           ],
//         ),
//         backgroundColor: color,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//         margin: const EdgeInsets.all(10),
//         duration: const Duration(seconds: 2),
//       ),
//     );
//   }
// }
//
// /// Résultat de la validation du numéro de téléphone
// class PhoneValidationResult {
//   final bool isValid;
//   final String message;
//   final String? formattedPhone;
//
//   PhoneValidationResult({
//     required this.isValid,
//     required this.message,
//     this.formattedPhone,
//   });
// }
