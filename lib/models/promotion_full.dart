/****************************************************************************************
 *
 * MODÈLE DE DONNÉES : PromotionFull
 *
 * OBJECTIF :
 * Cette classe représente le modèle de données complet et détaillé d'une promotion.
 * Elle est utilisée pour manipuler toutes les informations relatives à une offre,
 * y compris son état (active, future, expirée).
 *
 * FONCTIONNALITÉS CLÉS :
 * - Gestion de statut hybride : La classe peut utiliser un statut fourni
 * directement par une API. Si ce statut n'est pas disponible, elle est capable
 * de le calculer elle-même côté client en se basant sur la date actuelle.
 *
 * - Méthodes de calcul : Des fonctions (`isActive`, `isFuture`, `isExpired`)
 * sont disponibles pour déterminer l'état de la promotion à tout moment.
 *
 * - Parsing robuste : La méthode `fromJson` inclut une logique de parsing de
 * date flexible pour gérer différents formats potentiellement reçus du backend.
 *
 * - Sérialisation ciblée : La méthode `toJson` formate les données pour l'envoi
 * vers l'API, notamment en n'envoyant que la partie date des objets DateTime.
 *
 *****************************************************************************************/
class PromotionFull {
  /// L'identifiant unique de la promotion.
  final int id;
  /// L'identifiant du service auquel la promotion est associée.
  final int serviceId;
  /// Le pourcentage de réduction offert.
  final double pourcentage;
  /// La date et l'heure de début de la promotion.
  final DateTime dateDebut;
  /// La date et l'heure de fin de la promotion.
  final DateTime dateFin;
  /// Le statut textuel tel que fourni par l'API (ex: "active"). Peut être vide.
  final String status;

  /// Constructeur pour initialiser une instance de PromotionFull.
  PromotionFull({
    required this.id,
    required this.serviceId,
    required this.pourcentage,
    required this.dateDebut,
    required this.dateFin,
    this.status = "",
  });

  // --- MÉTHODES DE CALCUL DE STATUT (CÔTÉ CLIENT) ---

  /// Calcule si la promotion est actuellement en cours en se basant sur la date système.
  bool isActive() {
    final now = DateTime.now();
    return now.isAfter(dateDebut) && now.isBefore(dateFin);
  }

  /// Calcule si la promotion est programmée pour une date future.
  bool isFuture() {
    final now = DateTime.now();
    return dateDebut.isAfter(now);
  }

  /// Calcule si la promotion est déjà terminée.
  bool isExpired() {
    final now = DateTime.now();
    return dateFin.isBefore(now);
  }

  // --- GESTION DE STATUT HYBRIDE ---

  /// Détermine le statut final de la promotion de manière hybride.
  String getCurrentStatus() {
    // Priorité 1: Utiliser le statut s'il est fourni par le backend.
    if (status.isNotEmpty) {
      return status;
    }

    // Priorité 2: Si le backend ne fournit pas de statut, le calculer côté client.
    if (isActive()) {
      return "active";
    } else if (isFuture()) {
      return "future";
    } else {
      return "expired";
    }
  }

  /// Crée une instance de PromotionFull à partir d'une map JSON.
  factory PromotionFull.fromJson(Map<String, dynamic> json) {
    // Fonction d'aide locale pour parser les dates de manière flexible.
    DateTime parseDateTime(String dateStr) {
      try {
        // Tente de parser la date avec les informations de fuseau horaire.
        return DateTime.parse(dateStr);
      } catch (e) {
        // En cas d'échec, tente de parser uniquement la partie date (AAAA-MM-JJ).
        return DateTime.parse(dateStr.split('T')[0]);
      }
    }

    return PromotionFull(
      id: json['idPromotion'],
      serviceId: json['service_id'],
      pourcentage: json['discount_percentage'] != null
          ? double.parse(json['discount_percentage'].toString())
          : 0.0,
      dateDebut: json['start_date'] != null ? parseDateTime(json['start_date']) : DateTime.now(),
      dateFin: json['end_date'] != null ? parseDateTime(json['end_date']) : DateTime.now(),
      status: json['status'] ?? "",
    );
  }

  /// Convertit l'objet en une map JSON pour l'envoyer à une API.
  Map<String, dynamic> toJson() {
    return {
      'service_id': serviceId,
      'discount_percentage': pourcentage,
      // Envoie les dates au format 'AAAA-MM-JJ' (sans l'heure).
      'start_date': dateDebut.toIso8601String().split('T')[0],
      'end_date': dateFin.toIso8601String().split('T')[0],
      // Note: 'id' et 'status' ne sont pas inclus, car ils sont gérés par le serveur.
    };
  }
}






// // Fichier: models/promotion.dart
// class PromotionFull {
//   final int id;
//   final int serviceId;
//   final double pourcentage;
//   final DateTime dateDebut;
//   final DateTime dateFin;
//   final String status; // "active", "future", ou "expired"
//
//   PromotionFull({
//     required this.id,
//     required this.serviceId,
//     required this.pourcentage,
//     required this.dateDebut,
//     required this.dateFin,
//     this.status = "", // Valeur par défaut pour compatibilité avec le code existant
//   });
//
//   // Détermine si la promotion est active à la date actuelle
//   bool isActive() {
//     final now = DateTime.now();
//     return now.isAfter(dateDebut) && now.isBefore(dateFin);
//   }
//
//   // Détermine si la promotion est future
//   bool isFuture() {
//     final now = DateTime.now();
//     return dateDebut.isAfter(now);
//   }
//
//   // Détermine si la promotion est expirée
//   bool isExpired() {
//     final now = DateTime.now();
//     return dateFin.isBefore(now);
//   }
//
//   // Obtient le statut actuel de la promotion
//   String getCurrentStatus() {
//     if (status.isNotEmpty) {
//       return status; // Utiliser le statut fourni par l'API
//     }
//
//     // Sinon, calculer le statut
//     if (isActive()) {
//       return "active";
//     } else if (isFuture()) {
//       return "future";
//     } else {
//       return "expired";
//     }
//   }
//
//   factory PromotionFull.fromJson(Map<String, dynamic> json) {
//     DateTime parseDateTime(String dateStr) {
//       // Gérer les formats de date avec ou sans fuseau horaire
//       try {
//         return DateTime.parse(dateStr);
//       } catch (e) {
//         // En cas d'erreur, essayer d'autres formats
//         return DateTime.parse(dateStr.split('T')[0]);
//       }
//     }
//
//     return PromotionFull(
//       id: json['idPromotion'],
//       serviceId: json['service_id'],
//       pourcentage: json['discount_percentage'] != null
//           ? double.parse(json['discount_percentage'].toString())
//           : 0.0,
//       dateDebut: json['start_date'] != null ? parseDateTime(json['start_date']) : DateTime.now(),
//       dateFin: json['end_date'] != null ? parseDateTime(json['end_date']) : DateTime.now(),
//       status: json['status'] ?? "",
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'service_id': serviceId,
//       'discount_percentage': pourcentage,
//       'start_date': dateDebut.toIso8601String().split('T')[0],
//       'end_date': dateFin.toIso8601String().split('T')[0],
//     };
//   }
// }