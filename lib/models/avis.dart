////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//             MODÈLES DE DONNÉES POUR LE SYSTÈME D'AVIS CLIENTS               //
//                                                                            //
//  Ce fichier définit toutes les classes nécessaires pour gérer le système   //
//  d'avis de l'application. Chaque classe modélise une structure de données   //
//  spécifique échangée avec l'API.                                           //
//                                                                            //
//  - RdvEligible : Représente un rendez-vous terminé, en attente d'avis.     //
//  - Avis : Le modèle principal pour un avis (création et affichage).        //
//  - AvisStatistiques : Agrège les statistiques d'avis pour un salon.        //
//  - RdvEligiblesResponse : Modélise la réponse de l'API listant les RDV à   //
//    noter.                                                                  //
//  - ApiResponse : Un modèle générique pour les réponses standard de l'API.  //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

import 'package:intl/intl.dart';

//##############################################################################
//#                   MODÈLE 1: RENDEZ-VOUS ÉLIGIBLE AUX AVIS                  #
//##############################################################################

/// Modélise un rendez-vous qui est terminé et pour lequel le client peut laisser un avis.
/// Utilisé par l'API `/mes-rdv-avis-en-attente/`.
class RdvEligible {
  /// L'identifiant unique du rendez-vous.
  final int idRendezVous;
  /// Le nom du salon où a eu lieu le rendez-vous.
  final String salonNom;
  /// L'URL relative du logo du salon (peut être nulle).
  final String? salonLogo;
  /// L'adresse formatée du salon (peut être nulle).
  final String? salonAdresse;
  /// La date et l'heure du rendez-vous.
  final DateTime dateHeure;
  /// Le prix total payé pour le rendez-vous.
  final double totalPrix;
  /// La liste des noms des services effectués.
  final List<String> servicesNoms;
  /// Le statut final du rendez-vous (ex: "Terminé").
  final String statusRendezVous;

  /// Constructeur pour créer une instance de `RdvEligible`.
  RdvEligible({
    required this.idRendezVous,
    required this.salonNom,
    this.salonLogo,
    this.salonAdresse,
    required this.dateHeure,
    required this.totalPrix,
    required this.servicesNoms,
    required this.statusRendezVous,
  });

  /// Factory constructor pour créer une instance à partir d'un map JSON (désérialisation).
  factory RdvEligible.fromJson(Map<String, dynamic> json) {
    return RdvEligible(
      idRendezVous: json['idRendezVous'] ?? 0,
      salonNom: json['salon_nom'] ?? '',
      salonLogo: json['salon_logo'],
      salonAdresse: json['salon_adresse'],
      dateHeure: DateTime.parse(json['date_heure']),
      totalPrix: double.tryParse(json['total_prix'].toString()) ?? 0.0,
      servicesNoms: List<String>.from(json['services_noms'] ?? []),
      statusRendezVous: json['status_rendez_vous'] ?? '',
    );
  }

  /// Getter pour formater la date pour l'affichage (ex: "17/06/2025 à 18:36").
  String get dateFormatee => DateFormat('dd/MM/yyyy à HH:mm').format(dateHeure);

  /// Getter pour formater le prix avec deux décimales et le symbole euro.
  String get prixFormate => '${totalPrix.toStringAsFixed(2)}€';

  /// Getter pour construire l'URL complète et absolue du logo du salon.
  String get logoUrl {
    if (salonLogo == null || salonLogo!.isEmpty) return '';
    if (salonLogo!.startsWith('http')) return salonLogo!;
    // Construit l'URL complète si le chemin est relatif.
    return 'https://www.hairbnb.site$salonLogo';
  }

  /// Getter pour afficher la liste des services sous forme d'une seule chaîne de caractères.
  String get servicesTexte => servicesNoms.join(', ');

  /// Représentation textuelle de l'objet pour le débogage.
  @override
  String toString() {
    return 'RdvEligible{salon: $salonNom, date: $dateFormatee, prix: $prixFormate}';
  }
}

//##############################################################################
//#                   MODÈLE 2: AVIS CRÉÉ/REÇU                                 #
//##############################################################################

/// Modélise un avis client. Peut être utilisé à la fois pour envoyer un nouvel
/// avis à l'API et pour afficher un avis reçu du serveur.
class Avis {
  /// L'identifiant de l'avis (nul lors de la création).
  final int? id;
  /// L'ID du rendez-vous auquel cet avis est associé.
  final int idRendezVous;
  /// La note attribuée, de 1 à 5.
  final int note;
  /// Le commentaire textuel de l'avis.
  final String commentaire;
  /// La date de création de l'avis (fournie par le serveur).
  final DateTime? dateCreation;
  /// Le nom du client ayant laissé l'avis (fourni par le serveur).
  final String? clientNom;
  /// Le prénom du client (fourni par le serveur).
  final String? clientPrenom;
  /// Le nom du salon concerné (fourni par le serveur).
  final String? salonNom;
  /// Le logo du salon concerné (fourni par le serveur).
  final String? salonLogo;

  /// Constructeur pour créer une instance d'`Avis`.
  Avis({
    this.id,
    required this.idRendezVous,
    required this.note,
    required this.commentaire,
    this.dateCreation,
    this.clientNom,
    this.clientPrenom,
    this.salonNom,
    this.salonLogo,
  });

  /// Factory constructor pour créer une instance à partir d'un map JSON.
  factory Avis.fromJson(Map<String, dynamic> json) {
    return Avis(
      id: json['id'],
      idRendezVous: json['idRendezVous'] ?? json['rdv_id'] ?? 0, // Gère plusieurs noms de clés
      note: json['note'] ?? 5,
      commentaire: json['commentaire'] ?? '',
      dateCreation: json['date_creation'] != null
          ? DateTime.parse(json['date_creation'])
          : null,
      clientNom: json['client_nom'],
      clientPrenom: json['client_prenom'],
      salonNom: json['salon_nom'],
      salonLogo: json['salon_logo'],
    );
  }

  /// Convertit l'instance en un map JSON, typiquement pour l'envoi à une API.
  Map<String, dynamic> toJson() {
    return {
      'idRendezVous': idRendezVous,
      'note': note,
      'commentaire': commentaire,
      if (id != null) 'id': id, // Inclut l'ID seulement s'il existe (pour une mise à jour).
    };
  }

  /// Getter pour formater la date de création pour l'affichage (ex: "17/06/2025").
  String get dateFormatee {
    if (dateCreation == null) return '';
    return DateFormat('dd/MM/yyyy').format(dateCreation!);
  }

  /// Getter pour obtenir le nom complet du client.
  String get clientNomComplet {
    if (clientNom == null && clientPrenom == null) return 'Client anonyme';
    return '${clientPrenom ?? ''} ${clientNom ?? ''}'.trim();
  }

  /// Getter pour générer une représentation visuelle de la note avec des étoiles.
  String get etoilesVisuelles => '⭐' * note + '☆' * (5 - note);

  /// Getter pour construire l'URL complète du logo du salon.
  String get logoUrl {
    if (salonLogo == null || salonLogo!.isEmpty) return '';
    if (salonLogo!.startsWith('http')) return salonLogo!;
    return 'https://www.hairbnb.site$salonLogo';
  }

  /// Getter pour une validation simple côté client avant l'envoi.
  bool get isValid {
    return note >= 1 && note <= 5 && commentaire.trim().length >= 10;
  }

  /// Représentation textuelle de l'objet pour le débogage.
  @override
  String toString() {
    return 'Avis{id: $id, note: $note/5, salon: $salonNom}';
  }
}

//##############################################################################
//#                   MODÈLE 3: STATISTIQUES D'AVIS D'UN SALON                 #
//##############################################################################

/// Modélise les statistiques agrégées des avis pour un salon donné.
/// Utilisé par l'API `/salon/{id}/avis/`.
class AvisStatistiques {
  /// La note moyenne du salon.
  final double moyenneNotes;
  /// Le nombre total d'avis reçus.
  final int totalAvis;
  /// Une liste des avis les plus récents.
  final List<Avis> avisRecents;
  /// Un map de la répartition des notes (ex: {5: 120, 4: 50, ...}).
  final Map<int, int> repartitionNotes;

  /// Constructeur pour créer une instance d'`AvisStatistiques`.
  AvisStatistiques({
    required this.moyenneNotes,
    required this.totalAvis,
    required this.avisRecents,
    required this.repartitionNotes,
  });

  /// Factory constructor pour créer une instance à partir d'un map JSON.
  factory AvisStatistiques.fromJson(Map<String, dynamic> json) {
    return AvisStatistiques(
      moyenneNotes: double.tryParse(json['moyenne_notes'].toString()) ?? 0.0,
      totalAvis: json['total_avis'] ?? 0,
      avisRecents: (json['avis_recents'] as List<dynamic>? ?? [])
          .map((avis) => Avis.fromJson(avis))
          .toList(),
      // Conversion robuste du map de notes.
      repartitionNotes: Map<int, int>.from(
          (json['repartition_notes'] as Map<String, dynamic>? ?? {}).map(
                (key, value) => MapEntry(int.parse(key), value),
          )),
    );
  }

  /// Getter pour formater la moyenne avec une seule décimale.
  String get moyenneFormatee => moyenneNotes.toStringAsFixed(1);

  /// Calcule le pourcentage que représente un certain niveau de note.
  double getPourcentageNote(int note) {
    if (totalAvis == 0) return 0.0;
    return ((repartitionNotes[note] ?? 0) / totalAvis) * 100;
  }

  /// Représentation textuelle de l'objet pour le débogage.
  @override
  String toString() {
    return 'AvisStatistiques{moyenne: $moyenneFormatee/5, total: $totalAvis}';
  }
}

//##############################################################################
//#                MODÈLE 4: RÉPONSE API POUR LES RDV ÉLIGIBLES                 #
//##############################################################################

/// Modélise la structure de réponse complète de l'API `/mes-rdv-avis-en-attente/`.
class RdvEligiblesResponse {
  /// Le nombre total de rendez-vous en attente d'avis.
  final int count;
  /// La liste des objets `RdvEligible`.
  final List<RdvEligible> rdvEligibles;
  /// Un message informatif de l'API.
  final String message;

  /// Constructeur pour créer une instance de `RdvEligiblesResponse`.
  RdvEligiblesResponse({
    required this.count,
    required this.rdvEligibles,
    required this.message,
  });

  /// Factory constructor pour créer une instance à partir d'un map JSON.
  factory RdvEligiblesResponse.fromJson(Map<String, dynamic> json) {
    return RdvEligiblesResponse(
      count: json['count'] ?? 0,
      rdvEligibles: (json['rdv_eligibles'] as List<dynamic>? ?? [])
          .map((rdv) => RdvEligible.fromJson(rdv))
          .toList(),
      message: json['message'] ?? '',
    );
  }

  /// Getter de convenance pour savoir s'il y a des avis à laisser.
  bool get hasAvisEnAttente => count > 0;

  /// Représentation textuelle de l'objet pour le débogage.
  @override
  String toString() {
    return 'RdvEligiblesResponse{count: $count, message: $message}';
  }
}

//##############################################################################
//#                MODÈLE 5: RÉPONSE API GÉNÉRIQUE (CRUD)                      #
//##############################################################################

/// Modélise une réponse API standard et générique, utilisée pour les opérations
/// de création, modification ou suppression (CRUD).
class ApiResponse {
  /// `true` si l'opération a réussi, `false` sinon.
  final bool success;
  /// Le message de statut retourné par l'API.
  final String message;
  /// Un conteneur optionnel pour des données supplémentaires.
  final Map<String, dynamic>? data;

  /// Constructeur pour créer une instance d'`ApiResponse`.
  ApiResponse({
    required this.success,
    required this.message,
    this.data,
  });

  /// Factory constructor pour créer une instance à partir d'un map JSON.
  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      success: json['success'] ?? json['status'] == 'success' ?? false,
      message: json['message'] ?? '',
      data: json['data'],
    );
  }

  /// Représentation textuelle de l'objet pour le débogage.
  @override
  String toString() {
    return 'ApiResponse{success: $success, message: $message}';
  }
}







// // models/avis_models.dart
// import 'package:intl/intl.dart';
//
// /// 🎯 MODÈLE 1: RDV éligible aux avis
// /// Utilisé par l'API /mes-rdv-avis-en-attente/
// class RdvEligible {
//   final int idRendezVous;
//   final String salonNom;
//   final String? salonLogo;
//   final String? salonAdresse;
//   final DateTime dateHeure;
//   final double totalPrix;
//   final List<String> servicesNoms;
//   final String statusRendezVous;
//
//   RdvEligible({
//     required this.idRendezVous,
//     required this.salonNom,
//     this.salonLogo,
//     this.salonAdresse,
//     required this.dateHeure,
//     required this.totalPrix,
//     required this.servicesNoms,
//     required this.statusRendezVous,
//   });
//
//   /// 🔄 Création depuis JSON (réponse API)
//   factory RdvEligible.fromJson(Map<String, dynamic> json) {
//     return RdvEligible(
//       idRendezVous: json['idRendezVous'] ?? 0,
//       salonNom: json['salon_nom'] ?? '',
//       salonLogo: json['salon_logo'],
//       salonAdresse: json['salon_adresse'],
//       dateHeure: DateTime.parse(json['date_heure']),
//       totalPrix: double.tryParse(json['total_prix'].toString()) ?? 0.0,
//       servicesNoms: List<String>.from(json['services_noms'] ?? []),
//       statusRendezVous: json['status_rendez_vous'] ?? '',
//     );
//   }
//
//   /// 📅 Formatage de la date pour l'affichage
//   String get dateFormatee => DateFormat('dd/MM/yyyy à HH:mm').format(dateHeure);
//
//   /// 💰 Prix formaté
//   String get prixFormate => '${totalPrix.toStringAsFixed(2)}€';
//
//   /// 🏪 URL complète du logo salon
//   String get logoUrl {
//     if (salonLogo == null || salonLogo!.isEmpty) return '';
//     if (salonLogo!.startsWith('http')) return salonLogo!;
//     return 'https://www.hairbnb.site$salonLogo';
//   }
//
//   /// 🛍️ Services en format texte
//   String get servicesTexte => servicesNoms.join(', ');
//
//   @override
//   String toString() {
//     return 'RdvEligible{salon: $salonNom, date: $dateFormatee, prix: $prixFormate}';
//   }
// }
//
// /// 🎯 MODÈLE 2: Avis créé/reçu
// /// Utilisé pour créer un avis et récupérer des avis existants
// class Avis {
//   final int? id;
//   final int idRendezVous;
//   final int note;
//   final String commentaire;
//   final DateTime? dateCreation;
//   final String? clientNom;
//   final String? clientPrenom;
//   final String? salonNom;
//   final String? salonLogo;
//
//   Avis({
//     this.id,
//     required this.idRendezVous,
//     required this.note,
//     required this.commentaire,
//     this.dateCreation,
//     this.clientNom,
//     this.clientPrenom,
//     this.salonNom,
//     this.salonLogo,
//   });
//
//   /// 🔄 Création depuis JSON (réponse API)
//   factory Avis.fromJson(Map<String, dynamic> json) {
//     return Avis(
//       id: json['id'],
//       idRendezVous: json['idRendezVous'] ?? json['rdv_id'] ?? 0,
//       note: json['note'] ?? 5,
//       commentaire: json['commentaire'] ?? '',
//       dateCreation: json['date_creation'] != null
//           ? DateTime.parse(json['date_creation'])
//           : null,
//       clientNom: json['client_nom'],
//       clientPrenom: json['client_prenom'],
//       salonNom: json['salon_nom'],
//       salonLogo: json['salon_logo'],
//     );
//   }
//
//   /// 🔄 Conversion vers JSON (envoi API)
//   Map<String, dynamic> toJson() {
//     return {
//       'idRendezVous': idRendezVous,
//       'note': note,
//       'commentaire': commentaire,
//       if (id != null) 'id': id,
//     };
//   }
//
//   /// 📅 Date formatée pour l'affichage
//   String get dateFormatee {
//     if (dateCreation == null) return '';
//     return DateFormat('dd/MM/yyyy').format(dateCreation!);
//   }
//
//   /// 👤 Nom complet du client
//   String get clientNomComplet {
//     if (clientNom == null && clientPrenom == null) return 'Client anonyme';
//     return '${clientPrenom ?? ''} ${clientNom ?? ''}'.trim();
//   }
//
//   /// ⭐ Étoiles visuelles
//   String get etoilesVisuelles => '⭐' * note + '☆' * (5 - note);
//
//   /// 🏪 URL complète du logo salon
//   String get logoUrl {
//     if (salonLogo == null || salonLogo!.isEmpty) return '';
//     if (salonLogo!.startsWith('http')) return salonLogo!;
//     return 'https://www.hairbnb.site$salonLogo';
//   }
//
//   /// ✅ Validation de l'avis
//   bool get isValid {
//     return note >= 1 && note <= 5 && commentaire.trim().length >= 10;
//   }
//
//   @override
//   String toString() {
//     return 'Avis{id: $id, note: $note/5, salon: $salonNom}';
//   }
// }
//
// /// 🎯 MODÈLE 3: Statistiques d'avis d'un salon
// /// Utilisé par l'API /salon/{id}/avis/
// class AvisStatistiques {
//   final double moyenneNotes;
//   final int totalAvis;
//   final List<Avis> avisRecents;
//   final Map<int, int> repartitionNotes; // {5: 10, 4: 5, 3: 2, 2: 1, 1: 0}
//
//   AvisStatistiques({
//     required this.moyenneNotes,
//     required this.totalAvis,
//     required this.avisRecents,
//     required this.repartitionNotes,
//   });
//
//   /// 🔄 Création depuis JSON (réponse API)
//   factory AvisStatistiques.fromJson(Map<String, dynamic> json) {
//     return AvisStatistiques(
//       moyenneNotes: double.tryParse(json['moyenne_notes'].toString()) ?? 0.0,
//       totalAvis: json['total_avis'] ?? 0,
//       avisRecents: (json['avis_recents'] as List<dynamic>? ?? [])
//           .map((avis) => Avis.fromJson(avis))
//           .toList(),
//       repartitionNotes: Map<int, int>.from(json['repartition_notes'] ?? {}),
//     );
//   }
//
//   /// ⭐ Moyenne formatée
//   String get moyenneFormatee => moyenneNotes.toStringAsFixed(1);
//
//   /// 📊 Pourcentage pour chaque note
//   double getPourcentageNote(int note) {
//     if (totalAvis == 0) return 0.0;
//     return ((repartitionNotes[note] ?? 0) / totalAvis) * 100;
//   }
//
//   /// ⭐ Étoiles visuelles pour la moyenne
//   String get etoilesVisuelles {
//     final etoilesCompletes = moyenneNotes.floor();
//     final aFraction = moyenneNotes - etoilesCompletes;
//
//     String result = '⭐' * etoilesCompletes;
//
//     if (aFraction >= 0.5) {
//       result += '⭐';
//     } else if (aFraction > 0) {
//       result += '☆';
//     }
//
//     final etoilesVides = 5 - result.length;
//     result += '☆' * etoilesVides;
//
//     return result;
//   }
//
//   @override
//   String toString() {
//     return 'AvisStatistiques{moyenne: $moyenneFormatee/5, total: $totalAvis}';
//   }
// }
//
// /// 🎯 MODÈLE 4: Réponse API pour les RDV éligibles
// /// Structure complète retournée par /mes-rdv-avis-en-attente/
// class RdvEligiblesResponse {
//   final int count;
//   final List<RdvEligible> rdvEligibles;
//   final String message;
//
//   RdvEligiblesResponse({
//     required this.count,
//     required this.rdvEligibles,
//     required this.message,
//   });
//
//   /// 🔄 Création depuis JSON (réponse API)
//   factory RdvEligiblesResponse.fromJson(Map<String, dynamic> json) {
//     return RdvEligiblesResponse(
//       count: json['count'] ?? 0,
//       rdvEligibles: (json['rdv_eligibles'] as List<dynamic>? ?? [])
//           .map((rdv) => RdvEligible.fromJson(rdv))
//           .toList(),
//       message: json['message'] ?? '',
//     );
//   }
//
//   /// 📊 Y a-t-il des avis en attente ?
//   bool get hasAvisEnAttente => count > 0;
//
//   @override
//   String toString() {
//     return 'RdvEligiblesResponse{count: $count, message: $message}';
//   }
// }
//
// /// 🎯 MODÈLE 5: Réponse API générique
// /// Pour les opérations CRUD (création, modification, suppression)
// class ApiResponse {
//   final bool success;
//   final String message;
//   final Map<String, dynamic>? data;
//
//   ApiResponse({
//     required this.success,
//     required this.message,
//     this.data,
//   });
//
//   /// 🔄 Création depuis JSON (réponse API)
//   factory ApiResponse.fromJson(Map<String, dynamic> json) {
//     return ApiResponse(
//       success: json['success'] ?? false,
//       message: json['message'] ?? '',
//       data: json['data'],
//     );
//   }
//
//   @override
//   String toString() {
//     return 'ApiResponse{success: $success, message: $message}';
//   }
// }