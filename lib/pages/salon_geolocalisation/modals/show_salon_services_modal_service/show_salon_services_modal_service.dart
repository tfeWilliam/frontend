/// *************************************************************************************************
///
/// BANNER : EXPLICATION GÉNÉRALE DE LA CLASSE DE SERVICE
///
/// Ce fichier définit la classe `SalonServicesModalService`.
///
/// Objectif :
/// Cette classe agit comme un "service d'assistance" (helper service) pour simplifier
/// et centraliser la logique d'affichage d'une feuille modale spécifique : `SalonServicesModal`.
/// Au lieu d'appeler `showModalBottomSheet` manuellement à chaque fois, les autres parties
/// de l'application peuvent utiliser les méthodes statiques fournies ici.
///
/// Méthodes :
/// - `afficherServicesModal`: La méthode de base pour afficher le modal et récupérer
/// les services sélectionnés par l'utilisateur.
/// - `afficherServicesModalAvecOptions`: Une version améliorée qui permet de configurer
/// des options avancées, comme l'affichage de notifications (SnackBar) après la sélection.
/// - `afficherApercuServices`: Une version pour simplement afficher les services en
/// mode "aperçu", sans permettre de sélection ni attendre de résultat.
///
/// Utilisation :
/// La classe est composée uniquement de méthodes statiques, ce qui signifie qu'il n'est pas
/// nécessaire de créer une instance. On l'appelle directement, par exemple :
/// `SalonServicesModalService.afficherServicesModal(context, salon: monSalon);`
///
///*************************************************************************************************
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hairbnb/models/salon_details_geo.dart';
import 'package:hairbnb/models/service_with_promo.dart';
import 'package:hairbnb/models/current_user.dart';

import '../show_salon_services_modal.dart';

/// Classe de service pour gérer l'affichage de la feuille modale des services du salon.
class SalonServicesModalService {

  /// Affiche la feuille modale standard pour que les utilisateurs puissent voir et sélectionner des services.
  ///
  /// [context] : Le contexte de build de l'application.
  /// [salon] : L'objet salon dont les services doivent être affichés.
  /// [currentUser] : L'utilisateur actuellement connecté, pour déterminer les actions disponibles.
  /// [primaryColor], [accentColor] : Couleurs pour personnaliser le thème de la modale.
  /// [onServicesSelected] : Une fonction de rappel optionnelle exécutée avec la liste des services sélectionnés.
  ///
  /// Retourne une `Future` qui se complète avec la `List<ServiceWithPromo>` des services
  /// sélectionnés, ou `null` si l'utilisateur ferme la modale sans rien sélectionner.
  static Future<List<ServiceWithPromo>?> afficherServicesModal(
      BuildContext context, {
        required SalonDetailsForGeo salon,
        CurrentUser? currentUser,
        Color primaryColor = const Color(0xFF7B61FF),
        Color accentColor = const Color(0xFFE67E22),
        Function(List<ServiceWithPromo>)? onServicesSelected,
      }) async {

    // Affiche la feuille modale et attend qu'elle se ferme pour récupérer un résultat.
    final selectedServices = await showModalBottomSheet<List<ServiceWithPromo>>(
      context: context,
      isScrollControlled: true, // Permet à la modale de prendre plus de hauteur.
      backgroundColor: Colors.transparent, // Le fond est géré par le widget enfant.
      builder: (context) => SalonServicesModal(
        salon: salon,
        currentUser: currentUser, // Passe l'utilisateur à la modale.
        primaryColor: primaryColor,
        accentColor: accentColor,
      ),
    );

    // Traite le résultat après la fermeture de la modale.
    if (selectedServices != null && selectedServices.isNotEmpty) {
      if (kDebugMode) {
        print("Services sélectionnés depuis le modal: ${selectedServices.length}");
      }

      // Exécute le callback s'il a été fourni.
      onServicesSelected?.call(selectedServices);

      // Retourne la liste des services sélectionnés.
      return selectedServices;
    }

    // Retourne null si aucun service n'a été sélectionné.
    return null;
  }

  /// Affiche la feuille modale avec des options de notification avancées.
  ///
  /// Utile pour les flux où une confirmation visuelle (comme un ajout au panier) est nécessaire.
  ///
  /// [afficherNotification] : Si `true`, affiche une `SnackBar` de confirmation.
  /// [messageNotificationPersonnalise] : Permet de personnaliser le texte de la notification.
  /// [onPanierClique] : Callback pour l'action du bouton dans la `SnackBar`.
  static Future<List<ServiceWithPromo>?> afficherServicesModalAvecOptions(
      BuildContext context, {
        required SalonDetailsForGeo salon,
        CurrentUser? currentUser,
        Color primaryColor = const Color(0xFF7B61FF),
        Color accentColor = const Color(0xFFE67E22),
        bool afficherNotification = false,
        String? messageNotificationPersonnalise,
        Function(List<ServiceWithPromo>)? onServicesSelected,
        VoidCallback? onPanierClique,
      }) async {

    // Le processus d'affichage et de récupération est le même que la méthode de base.
    final selectedServices = await showModalBottomSheet<List<ServiceWithPromo>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SalonServicesModal(
        salon: salon,
        currentUser: currentUser,
        primaryColor: primaryColor,
        accentColor: accentColor,
      ),
    );

    if (selectedServices != null && selectedServices.isNotEmpty) {
      // Si l'option d'affichage de notification est activée.
      if (afficherNotification) {
        final message = messageNotificationPersonnalise ?? "${selectedServices.length} service(s) ajouté(s) au panier !";

        // Affiche une SnackBar de confirmation stylisée.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: "Voir le panier",
              textColor: Colors.white,
              onPressed: onPanierClique ?? () {
                if (kDebugMode) {
                  print("Navigation vers le panier - À implémenter selon votre app");
                }
              },
            ),
            behavior: SnackBarBehavior.floating, // La SnackBar flotte au-dessus du contenu.
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }

      onServicesSelected?.call(selectedServices);
      return selectedServices;
    }

    return null;
  }

  /// Affiche la feuille modale en mode "aperçu" seulement.
  ///
  /// Cette méthode est utile lorsque l'on veut juste montrer les services sans permettre
  /// de sélection ni attendre de retour. La méthode ne retourne rien (`Future<void>`).
  static Future<void> afficherApercuServices(
      BuildContext context, {
        required SalonDetailsForGeo salon,
        CurrentUser? currentUser,
        Color primaryColor = const Color(0xFF7B61FF),
        Color accentColor = const Color(0xFFE67E22),
      }) async {

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SalonServicesModal(
        salon: salon,
        currentUser: currentUser,
        primaryColor: primaryColor,
        accentColor: accentColor,
      ),
    );
  }
}







// // show_salon_services_modal_service.dart - Avec currentUser et notifications centrées
//
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:hairbnb/models/salon_details_geo.dart';
// import 'package:hairbnb/models/service_with_promo.dart';
// import 'package:hairbnb/models/current_user.dart';
//
// import '../show_salon_services_modal.dart';
//
// class SalonServicesModalService {
//
//   /// Affiche le modal des services pour un salon donné
//   ///
//   /// [context] - Le contexte Flutter
//   /// [salon] - Le salon pour lequel afficher les services
//   /// [currentUser] - L'utilisateur connecté (NOUVEAU)
//   /// [primaryColor] - Couleur primaire pour le thème (optionnel)
//   /// [accentColor] - Couleur d'accent pour le thème (optionnel)
//   /// [onServicesSelected] - Callback appelé quand des services sont sélectionnés (optionnel)
//   static Future<List<ServiceWithPromo>?> afficherServicesModal(
//       BuildContext context, {
//         required SalonDetailsForGeo salon,
//         CurrentUser? currentUser, // ✅ NOUVEAU
//         Color primaryColor = const Color(0xFF7B61FF),
//         Color accentColor = const Color(0xFFE67E22),
//         Function(List<ServiceWithPromo>)? onServicesSelected,
//       }) async {
//
//     // ✅ Modal avec notifications centrées intégrées
//     final selectedServices = await showModalBottomSheet<List<ServiceWithPromo>>(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => SalonServicesModal(
//         salon: salon,
//         currentUser: currentUser, // ✅ NOUVEAU
//         primaryColor: primaryColor,
//         accentColor: accentColor,
//       ),
//     );
//
//     // Si des services ont été sélectionnés
//     if (selectedServices != null && selectedServices.isNotEmpty) {
//
//       if (kDebugMode) {
//         print("✅ Services sélectionnés depuis le modal: ${selectedServices.length}");
//       }
//
//       // Appeler le callback si fourni (pour compatibilité arrière)
//       if (onServicesSelected != null) {
//         onServicesSelected(selectedServices);
//       }
//
//       return selectedServices;
//     }
//
//     return null;
//   }
//
//   /// Affiche le modal avec des options personnalisées avancées
//   static Future<List<ServiceWithPromo>?> afficherServicesModalAvecOptions(
//       BuildContext context, {
//         required SalonDetailsForGeo salon,
//         CurrentUser? currentUser, // ✅ NOUVEAU
//         Color primaryColor = const Color(0xFF7B61FF),
//         Color accentColor = const Color(0xFFE67E22),
//         bool afficherNotification = false,
//         String? messageNotificationPersonnalise,
//         Function(List<ServiceWithPromo>)? onServicesSelected,
//         VoidCallback? onPanierClique,
//       }) async {
//
//     final selectedServices = await showModalBottomSheet<List<ServiceWithPromo>>(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => SalonServicesModal(
//         salon: salon,
//         currentUser: currentUser, // ✅ NOUVEAU
//         primaryColor: primaryColor,
//         accentColor: accentColor,
//       ),
//     );
//
//     if (selectedServices != null && selectedServices.isNotEmpty) {
//
//       if (afficherNotification) {
//         final message = messageNotificationPersonnalise ??
//             "${selectedServices.length} service(s) ajouté(s) au panier !";
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(message),
//             backgroundColor: Colors.green,
//             duration: Duration(seconds: 3),
//             action: SnackBarAction(
//               label: "Voir le panier",
//               textColor: Colors.white,
//               onPressed: onPanierClique ?? () {
//                 if (kDebugMode) {
//                   print("🛒 Navigation vers le panier - À implémenter selon votre app");
//                 }
//               },
//             ),
//             behavior: SnackBarBehavior.floating,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//           ),
//         );
//       }
//
//       if (onServicesSelected != null) {
//         onServicesSelected(selectedServices);
//       }
//
//       return selectedServices;
//     }
//
//     return null;
//   }
//
//   /// Affiche le modal en mode "aperçu seulement" (sans sélection)
//   static Future<void> afficherApercuServices(
//       BuildContext context, {
//         required SalonDetailsForGeo salon,
//         CurrentUser? currentUser, // ✅ NOUVEAU
//         Color primaryColor = const Color(0xFF7B61FF),
//         Color accentColor = const Color(0xFFE67E22),
//       }) async {
//
//     await showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => SalonServicesModal(
//         salon: salon,
//         currentUser: currentUser, // ✅ NOUVEAU
//         primaryColor: primaryColor,
//         accentColor: accentColor,
//       ),
//     );
//   }
// }
