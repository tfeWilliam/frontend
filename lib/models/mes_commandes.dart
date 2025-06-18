/****************************************************************************************
 *
 * MODÈLES DE DONNÉES : Commande et ServiceCommande
 * Fichier : mes_commandes.dart
 *
 * OBJECTIF :
 * Ce fichier définit les modèles de données pour représenter les commandes des clients.
 * Il est structuré en deux classes principales :
 *
 * 1. Commande : Représente une commande complète (ou un rendez-vous) avec toutes
 * ses informations : détails du rendez-vous, salon, coiffeuse, paiement, et une
 * liste des services effectués.
 *
 * 2. ServiceCommande : Représente un service individuel inclus dans une commande,
 * avec son propre intitulé, prix et durée.
 *
 * FONCTIONNALITÉS CLÉS :
 * - Conversion depuis JSON : Les deux classes possèdent une méthode factory `fromJson`
 * pour créer des objets à partir de données reçues d'une API.
 * - Gestion robuste des types : Des fonctions d'aide (`_parseDouble`, `_parseInt`)
 * sont utilisées pour convertir les données JSON en types Dart (double, int) de
 * manière sécurisée, même si l'API renvoie des nombres sous forme de chaînes.
 * - Utilitaire de liste : Une méthode `fromJsonList` est fournie pour convertir
 * facilement une liste entière de commandes JSON.
 *
 *****************************************************************************************/

/// Représente une commande client complète, associée à un rendez-vous.
class Commande {
  // L'identifiant unique du rendez-vous qui correspond à cette commande.
  final int idRendezVous;
  // La date et l'heure exactes du rendez-vous.
  final DateTime dateHeure;
  // Le statut actuel de la commande (ex: "Confirmé", "Terminé", "Annulé").
  final String statut;
  // Le nom du salon de coiffure où la commande a été passée.
  final String nomSalon;
  // Le nom de famille de la coiffeuse assignée.
  final String nomCoiffeuse;
  // Le prénom de la coiffeuse assignée.
  final String prenomCoiffeuse;
  // Le prix total de tous les services combinés dans la commande.
  final double totalPrix;
  // La durée totale estimée de tous les services, en minutes.
  final int dureeTotale;
  // La date à laquelle le paiement a été effectué.
  final DateTime datePaiement;
  // Le montant exact qui a été payé par le client.
  final double montantPaye;
  // La méthode de paiement utilisée (ex: "Stripe", "Carte de crédit").
  final String methodePaiement;
  // L'URL optionnelle pour accéder au reçu de paiement (peut être nulle).
  final String? receiptUrl;
  // La liste des services individuels inclus dans cette commande.
  final List<ServiceCommande> services;

  // Constructeur pour créer une instance de Commande.
  Commande({
    required this.idRendezVous,
    required this.dateHeure,
    required this.statut,
    required this.nomSalon,
    required this.nomCoiffeuse,
    required this.prenomCoiffeuse,
    required this.totalPrix,
    required this.dureeTotale,
    required this.datePaiement,
    required this.montantPaye,
    required this.methodePaiement,
    this.receiptUrl,
    required this.services,
  });

  /// Méthode factory pour créer une instance de [Commande] à partir d'une map JSON.
  /// Elle utilise des fonctions d'aide pour garantir une conversion de type sûre.
  factory Commande.fromJson(Map<String, dynamic> json) {
    return Commande(
      idRendezVous: json['idRendezVous'],
      dateHeure: DateTime.parse(json['date_heure']),
      statut: json['statut'],
      nomSalon: json['nom_salon'],
      nomCoiffeuse: json['nom_coiffeuse'],
      prenomCoiffeuse: json['prenom_coiffeuse'],
      totalPrix: _parseDouble(json['total_prix']),
      dureeTotale: _parseInt(json['duree_totale']),
      datePaiement: DateTime.parse(json['date_paiement']),
      montantPaye: _parseDouble(json['montant_paye']),
      methodePaiement: json['methode_paiement'],
      receiptUrl: json['receipt_url'],
      services: (json['services'] as List)
          .map((s) => ServiceCommande.fromJson(s))
          .toList(),
    );
  }

  /// Méthode statique utilitaire pour convertir une liste de JSON en une liste d'objets [Commande].
  static List<Commande> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => Commande.fromJson(json)).toList();
  }

  /// Fonction d'aide privée pour convertir une valeur dynamique en [double] de manière robuste.
  /// Gère les cas où la valeur est nulle, un int, un double, ou une chaîne de caractères.
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Fonction d'aide privée pour convertir une valeur dynamique en [int] de manière robuste.
  /// Gère les cas où la valeur est nulle, un int, un double (arrondi), ou une chaîne de caractères.
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

/// Représente un service individuel qui fait partie d'une [Commande].
class ServiceCommande {
  // Le nom du service (ex: "Coupe homme", "Coloration").
  final String intituleService;
  // Le prix du service tel qu'il a été appliqué dans la commande.
  final double prixApplique;
  // La durée estimée du service en minutes.
  final int dureeEstimee;

  // Constructeur pour créer une instance de ServiceCommande.
  ServiceCommande({
    required this.intituleService,
    required this.prixApplique,
    required this.dureeEstimee,
  });

  /// Méthode factory pour créer une instance de [ServiceCommande] à partir d'une map JSON.
  factory ServiceCommande.fromJson(Map<String, dynamic> json) {
    return ServiceCommande(
      intituleService: json['intitule_service'],
      // Réutilise les fonctions d'aide de la classe Commande pour une conversion sûre.
      prixApplique: Commande._parseDouble(json['prix_applique']),
      dureeEstimee: Commande._parseInt(json['duree_estimee']),
    );
  }
}







// // Modification du modèle mes_commandes.dart
//
// class Commande {
//   final int idRendezVous;
//   final DateTime dateHeure;
//   final String statut;
//   final String nomSalon;
//   final String nomCoiffeuse;
//   final String prenomCoiffeuse;
//   final double totalPrix;
//   final int dureeTotale;
//   final DateTime datePaiement;
//   final double montantPaye;
//   final String methodePaiement;
//   final String? receiptUrl;
//   final List<ServiceCommande> services;
//
//   Commande({
//     required this.idRendezVous,
//     required this.dateHeure,
//     required this.statut,
//     required this.nomSalon,
//     required this.nomCoiffeuse,
//     required this.prenomCoiffeuse,
//     required this.totalPrix,
//     required this.dureeTotale,
//     required this.datePaiement,
//     required this.montantPaye,
//     required this.methodePaiement,
//     this.receiptUrl,
//     required this.services,
//   });
//
//   factory Commande.fromJson(Map<String, dynamic> json) {
//     // Parser avec gestion des différents types possibles
//     return Commande(
//       idRendezVous: json['idRendezVous'],
//       dateHeure: DateTime.parse(json['date_heure']),
//       statut: json['statut'],
//       nomSalon: json['nom_salon'],
//       nomCoiffeuse: json['nom_coiffeuse'],
//       prenomCoiffeuse: json['prenom_coiffeuse'],
//       // Gérer correctement les nombres qui peuvent être des chaînes
//       totalPrix: _parseDouble(json['total_prix']),
//       dureeTotale: _parseInt(json['duree_totale']),
//       datePaiement: DateTime.parse(json['date_paiement']),
//       montantPaye: _parseDouble(json['montant_paye']),
//       methodePaiement: json['methode_paiement'],
//       receiptUrl: json['receipt_url'],
//       services: (json['services'] as List)
//           .map((s) => ServiceCommande.fromJson(s))
//           .toList(),
//     );
//   }
//
//   // Méthode statique pour traiter une liste de commandes
//   static List<Commande> fromJsonList(List<dynamic> jsonList) {
//     return jsonList.map((json) => Commande.fromJson(json)).toList();
//   }
//
//   // Méthodes d'aide pour gérer les conversions de types
//   static double _parseDouble(dynamic value) {
//     if (value == null) return 0.0;
//     if (value is double) return value;
//     if (value is int) return value.toDouble();
//     if (value is String) return double.tryParse(value) ?? 0.0;
//     return 0.0;
//   }
//
//   static int _parseInt(dynamic value) {
//     if (value == null) return 0;
//     if (value is int) return value;
//     if (value is double) return value.round();
//     if (value is String) return int.tryParse(value) ?? 0;
//     return 0;
//   }
// }
//
// class ServiceCommande {
//   final String intituleService;
//   final double prixApplique;
//   final int dureeEstimee;
//
//   ServiceCommande({
//     required this.intituleService,
//     required this.prixApplique,
//     required this.dureeEstimee,
//   });
//
//   factory ServiceCommande.fromJson(Map<String, dynamic> json) {
//     return ServiceCommande(
//       intituleService: json['intitule_service'],
//       // Utiliser les méthodes helper pour gérer différents types
//       prixApplique: Commande._parseDouble(json['prix_applique']),
//       dureeEstimee: Commande._parseInt(json['duree_estimee']),
//     );
//   }
// }