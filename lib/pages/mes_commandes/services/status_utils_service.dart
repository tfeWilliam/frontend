////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//             CLASSE UTILITAIRE POUR LA GESTION DES STATUTS                    //
//                                                                            //
//  Ce fichier définit `StatusUtils`, une classe contenant des méthodes        //
//  statiques pour centraliser et standardiser la logique liée aux statuts    //
//  des commandes (rendez-vous) dans l'application.                           //
//                                                                            //
//  Elle permet de :                                                          //
//  - Associer une couleur à chaque statut pour une UI cohérente.             //
//  - Normaliser les différentes variations textuelles d'un même statut en    //
//    une seule valeur canonique.                                             //
//  - Fournir des méthodes de vérification simples (ex: est-ce un statut      //
//    actif ?).                                                               //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;

import 'package:flutter/material.dart';

/// Une classe utilitaire avec des méthodes statiques pour gérer les statuts.
///
/// Cette classe n'est pas destinée à être instanciée. Elle sert de "namespace"
/// pour regrouper des fonctions logiques liées aux statuts.
class StatusUtils {

  /// Retourne une couleur spécifique en fonction d'une chaîne de caractères de statut.
  ///
  /// Gère plusieurs variations pour chaque statut (avec/sans accent, pluriel)
  /// pour plus de robustesse.
  ///
  /// [status] : La chaîne de statut à évaluer.
  ///
  /// Retourne un objet `Color`.
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmé':
      case 'confirme':
      case 'confirmes':
        return Colors.green;
      case 'en attente':
      case 'en_attente':
      case 'attente':
        return Colors.orange;
      case 'annulé':
      case 'annule':
      case 'annules':
        return Colors.red;
      case 'terminé':
      case 'termine':
      case 'termines':
        return Colors.blue;
      default:
      // Retourne une couleur par défaut pour les statuts inconnus.
        return Colors.grey;
    }
  }

  /// Normalise une chaîne de statut pour la rendre canonique et cohérente.
  ///
  /// Par exemple, 'confirme' ou 'confirmes' seront tous deux convertis en 'confirmé'.
  /// Cela simplifie les comparaisons et les logiques de filtrage.
  ///
  /// [status] : La chaîne de statut brute.
  ///
  /// Retourne la version normalisée du statut sous forme de `String`.
  static String normalizeStatus(String status) {
    final statusLower = status.toLowerCase().trim();

    if (['confirmé', 'confirme', 'confirmes'].contains(statusLower)) {
      return 'confirmé';
    }

    if (['en attente', 'en_attente', 'attente'].contains(statusLower)) {
      return 'en attente';
    }

    if (['terminé', 'termine', 'termines'].contains(statusLower)) {
      return 'terminé';
    }

    if (['annulé', 'annule', 'annules'].contains(statusLower)) {
      return 'annulé';
    }

    // Si le statut n'est pas reconnu, retourne la chaîne originale.
    return status;
  }

  /// Vérifie si un statut correspond à un état "actif" (en attente ou confirmé).
  ///
  /// Utile pour déterminer si des actions sont encore possibles sur une commande.
  ///
  /// [status] : La chaîne de statut à vérifier.
  ///
  /// Retourne `true` si le statut est actif, `false` sinon.
  static bool isActiveStatus(String status) {
    final normalized = normalizeStatus(status);
    return ['en attente', 'confirmé'].contains(normalized);
  }

  /// Vérifie si un statut correspond à un état "final" (terminé ou annulé).
  ///
  /// Utile pour déterminer si une commande est clôturée.
  ///
  /// [status] : La chaîne de statut à vérifier.
  ///
  /// Retourne `true` si le statut est final, `false` sinon.
  static bool isCompletedStatus(String status) {
    final normalized = normalizeStatus(status);
    return ['terminé', 'annulé'].contains(normalized);
  }
}





// import 'package:flutter/material.dart';
//
// class StatusUtils {
//   // Méthode pour obtenir la couleur correspondant à chaque statut
//   static Color getStatusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'confirmé':
//       case 'confirme':
//       case 'confirmes':
//         return Colors.green;
//       case 'en attente':
//       case 'en_attente':
//       case 'attente':
//         return Colors.orange;
//       case 'annulé':
//       case 'annule':
//       case 'annules':
//         return Colors.red;
//       case 'terminé':
//       case 'termine':
//       case 'termines':
//         return Colors.blue;
//       default:
//         return Colors.grey;
//     }
//   }
//
//   // Méthode pour normaliser les statuts (pour les filtres)
//   static String normalizeStatus(String status) {
//     final statusLower = status.toLowerCase().trim();
//
//     if (['confirmé', 'confirme', 'confirmes'].contains(statusLower)) {
//       return 'confirmé';
//     }
//
//     if (['en attente', 'en_attente', 'attente'].contains(statusLower)) {
//       return 'en attente';
//     }
//
//     if (['terminé', 'termine', 'termines'].contains(statusLower)) {
//       return 'terminé';
//     }
//
//     if (['annulé', 'annule', 'annules'].contains(statusLower)) {
//       return 'annulé';
//     }
//
//     return status;
//   }
//
//   // Vérifie si un statut est actif (en attente ou confirmé)
//   static bool isActiveStatus(String status) {
//     final normalized = normalizeStatus(status);
//     return ['en attente', 'confirmé'].contains(normalized);
//   }
//
//   // Vérifie si un statut est terminé (terminé ou annulé)
//   static bool isCompletedStatus(String status) {
//     final normalized = normalizeStatus(status);
//     return ['terminé', 'annulé'].contains(normalized);
//   }
// }