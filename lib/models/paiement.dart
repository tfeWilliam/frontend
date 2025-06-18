/****************************************************************************************
 *
 * MODÈLES DE DONNÉES POUR LA GESTION DES PAIEMENTS
 *
 * OBJECTIF :
 * Ce fichier définit les modèles de données nécessaires à la gestion des transactions
 * de paiement dans l'application. Il est structuré en trois classes :
 *
 * 1. Paiement : La classe centrale qui représente une transaction complète,
 * incluant les détails du montant, de la date, les liens vers le rendez-vous
 * et l'utilisateur, ainsi que des identifiants spécifiques au fournisseur
 * de paiement (Stripe).
 *
 * 2. StatutPaiement : Un modèle simple pour définir le statut d'un paiement
 * (ex: "Réussi", "En attente", "Échoué").
 *
 * 3. MethodePaiement : Un modèle simple pour définir la méthode de paiement
 * utilisée (ex: "Carte de crédit", "Bancontact").
 *
 * FONCTIONNALITÉS :
 * Chaque classe inclut des méthodes `fromJson` et `toJson` pour permettre une
 * sérialisation et désérialisation faciles, assurant une communication fluide avec
 * une API externe.
 *
 *****************************************************************************************/

/// Représente une transaction de paiement complète dans le système.
class Paiement {
  /// Identifiant unique du paiement dans la base de données (nul si non encore sauvegardé).
  final int? idTblPaiement;
  /// ID du rendez-vous pour lequel ce paiement a été effectué.
  final int rendezVousId;
  /// ID de l'utilisateur qui a initié le paiement (peut être nul).
  final int? utilisateurId;
  /// Le montant total qui a été payé.
  final double montantPaye;
  /// La date et l'heure exactes de la transaction.
  final DateTime datePaiement;
  /// L'objet représentant le statut actuel du paiement (ex: réussi, en attente).
  final StatutPaiement statut;
  /// L'objet représentant la méthode de paiement utilisée (peut être nul).
  final MethodePaiement? methode;
  /// L'identifiant de l'intention de paiement de Stripe, pour le suivi de la transaction.
  final String? stripePaymentIntentId;
  /// L'identifiant de la charge (paiement effectif) de Stripe.
  final String? stripeChargeId;
  /// L'identifiant du client chez Stripe.
  final String? stripeCustomerId;
  /// L'identifiant de la session de checkout Stripe, si utilisée.
  final String? stripeCheckoutSessionId;
  /// L'email du client associé à la transaction.
  final String? emailClient;
  /// L'URL du reçu de paiement, généralement fourni par Stripe.
  final String? receiptUrl;

  /// Constructeur pour créer une nouvelle instance de Paiement.
  Paiement({
    this.idTblPaiement,
    required this.rendezVousId,
    this.utilisateurId,
    required this.montantPaye,
    required this.datePaiement,
    required this.statut,
    this.methode,
    this.stripePaymentIntentId,
    this.stripeChargeId,
    this.stripeCustomerId,
    this.stripeCheckoutSessionId,
    this.emailClient,
    this.receiptUrl,
  });

  /// Crée une instance de [Paiement] à partir d'une map JSON.
  factory Paiement.fromJson(Map<String, dynamic> json) {
    return Paiement(
      idTblPaiement: json['idTblPaiement'],
      rendezVousId: json['rendez_vous'],
      utilisateurId: json['utilisateur'],
      // Conversion robuste du montant pour accepter String, int ou double.
      montantPaye: double.parse(json['montant_paye'].toString()),
      datePaiement: DateTime.parse(json['date_paiement']),
      // Gère la désérialisation de l'objet StatutPaiement imbriqué.
      statut: StatutPaiement.fromJson(json['statut']),
      // Gère la désérialisation de l'objet MethodePaiement s'il n'est pas nul.
      methode: json['methode'] != null ? MethodePaiement.fromJson(json['methode']) : null,
      stripePaymentIntentId: json['stripe_payment_intent_id'],
      stripeChargeId: json['stripe_charge_id'],
      stripeCustomerId: json['stripe_customer_id'],
      stripeCheckoutSessionId: json['stripe_checkout_session_id'],
      emailClient: json['email_client'],
      receiptUrl: json['receipt_url'],
    );
  }

  /// Convertit l'objet [Paiement] en une map JSON, prête à être envoyée à une API.
  Map<String, dynamic> toJson() {
    return {
      'idTblPaiement': idTblPaiement,
      'rendez_vous': rendezVousId,
      'utilisateur': utilisateurId,
      'montant_paye': montantPaye,
      'date_paiement': datePaiement.toIso8601String(),
      'statut': statut.toJson(),
      // Gère la sérialisation de l'objet MethodePaiement s'il n'est pas nul.
      'methode': methode?.toJson(),
      'stripe_payment_intent_id': stripePaymentIntentId,
      'stripe_charge_id': stripeChargeId,
      'stripe_customer_id': stripeCustomerId,
      'stripe_checkout_session_id': stripeCheckoutSessionId,
      'email_client': emailClient,
      'receipt_url': receiptUrl,
    };
  }
}

/// Modèle simple pour représenter le statut d'un paiement.
class StatutPaiement {
  /// ID unique du statut dans la base de données (optionnel).
  final int? idTblPaiementStatut;
  /// Code machine du statut (ex: "SUCCEEDED", "PENDING").
  final String code;
  /// Libellé lisible par un humain (ex: "Paiement réussi").
  final String libelle;

  /// Constructeur pour créer une instance de StatutPaiement.
  StatutPaiement({
    this.idTblPaiementStatut,
    required this.code,
    required this.libelle,
  });

  /// Crée une instance de [StatutPaiement] à partir d'une map JSON.
  factory StatutPaiement.fromJson(Map<String, dynamic> json) {
    return StatutPaiement(
      idTblPaiementStatut: json['idTblPaiementStatut'],
      code: json['code'],
      libelle: json['libelle'],
    );
  }

  /// Convertit l'instance en une map JSON.
  Map<String, dynamic> toJson() {
    return {
      'idTblPaiementStatut': idTblPaiementStatut,
      'code': code,
      'libelle': libelle,
    };
  }
}

/// Modèle simple pour représenter une méthode de paiement.
class MethodePaiement {
  /// ID unique de la méthode dans la base de données (optionnel).
  final int? idTblMethodePaiement;
  /// Code machine de la méthode (ex: "CARD", "BANCONTACT").
  final String code;
  /// Libellé lisible par un humain (ex: "Carte de crédit").
  final String libelle;

  /// Constructeur pour créer une instance de MethodePaiement.
  MethodePaiement({
    this.idTblMethodePaiement,
    required this.code,
    required this.libelle,
  });

  /// Crée une instance de [MethodePaiement] à partir d'une map JSON.
  factory MethodePaiement.fromJson(Map<String, dynamic> json) {
    return MethodePaiement(
      idTblMethodePaiement: json['idTblMethodePaiement'],
      code: json['code'],
      libelle: json['libelle'],
    );
  }

  /// Convertit l'instance en une map JSON.
  Map<String, dynamic> toJson() {
    return {
      'idTblMethodePaiement': idTblMethodePaiement,
      'code': code,
      'libelle': libelle,
    };
  }
}






// class Paiement {
//   final int? idTblPaiement;
//   final int rendezVousId;
//   final int? utilisateurId;
//   final double montantPaye;
//   final DateTime datePaiement;
//   final StatutPaiement statut;
//   final MethodePaiement? methode;
//   final String? stripePaymentIntentId;
//   final String? stripeChargeId;
//   final String? stripeCustomerId;
//   final String? stripeCheckoutSessionId;
//   final String? emailClient;
//   final String? receiptUrl;
//
//   Paiement({
//     this.idTblPaiement,
//     required this.rendezVousId,
//     this.utilisateurId,
//     required this.montantPaye,
//     required this.datePaiement,
//     required this.statut,
//     this.methode,
//     this.stripePaymentIntentId,
//     this.stripeChargeId,
//     this.stripeCustomerId,
//     this.stripeCheckoutSessionId,
//     this.emailClient,
//     this.receiptUrl,
//   });
//
//   factory Paiement.fromJson(Map<String, dynamic> json) {
//     return Paiement(
//       idTblPaiement: json['idTblPaiement'],
//       rendezVousId: json['rendez_vous'],
//       utilisateurId: json['utilisateur'],
//       montantPaye: double.parse(json['montant_paye'].toString()),
//       datePaiement: DateTime.parse(json['date_paiement']),
//       statut: StatutPaiement.fromJson(json['statut']),
//       methode: json['methode'] != null ? MethodePaiement.fromJson(json['methode']) : null,
//       stripePaymentIntentId: json['stripe_payment_intent_id'],
//       stripeChargeId: json['stripe_charge_id'],
//       stripeCustomerId: json['stripe_customer_id'],
//       stripeCheckoutSessionId: json['stripe_checkout_session_id'],
//       emailClient: json['email_client'],
//       receiptUrl: json['receipt_url'],
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'idTblPaiement': idTblPaiement,
//       'rendez_vous': rendezVousId,
//       'utilisateur': utilisateurId,
//       'montant_paye': montantPaye,
//       'date_paiement': datePaiement.toIso8601String(),
//       'statut': statut.toJson(),
//       'methode': methode?.toJson(),
//       'stripe_payment_intent_id': stripePaymentIntentId,
//       'stripe_charge_id': stripeChargeId,
//       'stripe_customer_id': stripeCustomerId,
//       'stripe_checkout_session_id': stripeCheckoutSessionId,
//       'email_client': emailClient,
//       'receipt_url': receiptUrl,
//     };
//   }
// }
//
// class StatutPaiement {
//   final int? idTblPaiementStatut;
//   final String code;
//   final String libelle;
//
//   StatutPaiement({
//     this.idTblPaiementStatut,
//     required this.code,
//     required this.libelle,
//   });
//
//   factory StatutPaiement.fromJson(Map<String, dynamic> json) {
//     return StatutPaiement(
//       idTblPaiementStatut: json['idTblPaiementStatut'],
//       code: json['code'],
//       libelle: json['libelle'],
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'idTblPaiementStatut': idTblPaiementStatut,
//       'code': code,
//       'libelle': libelle,
//     };
//   }
// }
//
// class MethodePaiement {
//   final int? idTblMethodePaiement;
//   final String code;
//   final String libelle;
//
//   MethodePaiement({
//     this.idTblMethodePaiement,
//     required this.code,
//     required this.libelle,
//   });
//
//   factory MethodePaiement.fromJson(Map<String, dynamic> json) {
//     return MethodePaiement(
//       idTblMethodePaiement: json['idTblMethodePaiement'],
//       code: json['code'],
//       libelle: json['libelle'],
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'idTblMethodePaiement': idTblMethodePaiement,
//       'code': code,
//       'libelle': libelle,
//     };
//   }
// }
