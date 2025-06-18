/****************************************************************************************
 *
 * MODÈLES DE DONNÉES : CONFIRMATION DE RENDEZ-VOUS (RDV)
 *
 * OBJECTIF :
 * Ce fichier définit les modèles de données nécessaires pour représenter un rendez-vous
 * (RDV) confirmé. L'ensemble de ces classes est conçu pour structurer les informations
 * complètes d'un RDV, typiquement pour être utilisées sur un écran de confirmation
 * après une réservation réussie.
 *
 * STRUCTURE DES CLASSES :
 * - RdvConfirmation : La classe principale qui sert de conteneur pour toutes les
 * informations relatives à la confirmation du RDV.
 *
 * - ClientLite & CoiffeuseLite : Ces classes héritent des modèles de base `Client`
 * et `Coiffeuse`. Elles sont utilisées ici comme des versions spécifiques ("Lite")
 * pour instancier les objets à partir de la structure de la réponse JSON de l'API
 * de confirmation.
 *
 * - ServiceRdv : Un modèle simple représentant un service individuel inclus dans
 * le rendez-vous, avec le prix qui a été effectivement appliqué.
 *
 *****************************************************************************************/
import 'package:hairbnb/models/salon.dart';

import 'client.dart';
import 'coiffeuse.dart';

/// Modèle principal qui agrège toutes les informations d'un rendez-vous confirmé.
class RdvConfirmation {
  /// L'identifiant unique du rendez-vous.
  final int idRendezVous;
  /// Les informations (version "Lite") du client qui a pris le rendez-vous.
  final ClientLite client;
  /// Les informations (version "Lite") de la coiffeuse qui effectuera la prestation.
  final CoiffeuseLite coiffeuse;
  /// Les informations du salon où le rendez-vous aura lieu.
  final Salon salon;
  /// La date et l'heure exactes du rendez-vous.
  final DateTime dateHeure;
  /// Le statut actuel du rendez-vous (ex: "Confirmé").
  final String statut;
  /// Le prix total de toutes les prestations du rendez-vous.
  final double totalPrix;
  /// La durée totale estimée en minutes pour l'ensemble des services.
  final int dureeTotale;
  /// La liste des services inclus dans ce rendez-vous.
  final List<ServiceRdv> services;

  /// Constructeur pour créer une instance de [RdvConfirmation].
  RdvConfirmation({
    required this.idRendezVous,
    required this.client,
    required this.coiffeuse,
    required this.salon,
    required this.dateHeure,
    required this.statut,
    required this.totalPrix,
    required this.dureeTotale,
    required this.services,
  });

  /// Construit une instance de [RdvConfirmation] à partir d'une map JSON.
  factory RdvConfirmation.fromJson(Map<String, dynamic> json) {
    return RdvConfirmation(
      idRendezVous: json['idRendezVous'],
      client: ClientLite.fromJson(json['client']),
      coiffeuse: CoiffeuseLite.fromJson(json['coiffeuse']),
      salon: Salon.fromJson(json['salon']),
      dateHeure: DateTime.parse(json['date_heure']),
      statut: json['statut'] ?? '',
      totalPrix: (json['total_prix'] as num).toDouble(),
      dureeTotale: json['duree_totale'],
      services: (json['services'] as List)
          .map((s) => ServiceRdv.fromJson(s))
          .toList(),
    );
  }
}

/// Modèle "léger" du client, héritant de la classe [Client] de base.
/// Il est spécifiquement utilisé ici pour représenter le client dans le
/// contexte d'une confirmation de RDV, en se basant sur la structure JSON reçue.
class ClientLite extends Client {
  /// Le constructeur passe tous les paramètres au constructeur de la classe parente [Client].
  ClientLite({
    required super.idTblUser,
    required super.uuid,
    required super.nom,
    required super.prenom,
    required super.email,
    required super.numeroTelephone,
    required super.sexe,
    required super.isActive,
    super.dateNaissance,
    super.photoProfil,
    super.numero,
    super.boitePostale,
    super.nomRue,
    super.commune,
    super.codePostal,
  });

  /// Construit une instance de [ClientLite] à partir de la section 'client' de la réponse JSON.
  factory ClientLite.fromJson(Map<String, dynamic> json) {
    return ClientLite(
      idTblUser: json['idTblUser'],
      uuid: json['uuid'],
      nom: json['nom'],
      prenom: json['prenom'],
      email: json['email'],
      numeroTelephone: json['numero_telephone'],
      dateNaissance: json['date_naissance'],
      sexe: json['sexe'],
      isActive: json['is_active'],
      photoProfil: json['photo_profil'],
      numero: json['numero'],
      boitePostale: json['boite_postale'],
      nomRue: json['nom_rue'],
      commune: json['commune'],
      codePostal: json['code_postal'],
    );
  }
}

/// Modèle "léger" de la coiffeuse, héritant de la classe [Coiffeuse] de base.
/// Il est spécifiquement utilisé pour représenter la coiffeuse dans le
/// contexte d'une confirmation de RDV, en se basant sur la structure JSON reçue.
class CoiffeuseLite extends Coiffeuse {
  /// Le constructeur passe tous les paramètres au constructeur de la classe parente [Coiffeuse].
  CoiffeuseLite({
    required super.idTblUser,
    required super.id,
    super.nomCommercial,
    super.position,
    required super.uuid,
    required super.nom,
    required super.prenom,
    required super.email,
    required super.numeroTelephone,
    super.dateNaissance,
    required super.sexe,
    required super.isActive,
    super.photoProfil,
    super.numero,
    super.nomRue,
    super.commune,
    super.codePostal,
  });

  /// Construit une instance de [CoiffeuseLite] à partir de la section 'coiffeuse' de la réponse JSON.
  factory CoiffeuseLite.fromJson(Map<String, dynamic> json) {
    return CoiffeuseLite(
      idTblUser: json['idTblUser'],
      id: json['id'],
      nomCommercial: json['nom_commercial'],
      position: json['position'],
      uuid: json['uuid'],
      nom: json['nom'],
      prenom: json['prenom'],
      email: json['email'],
      numeroTelephone: json['numero_telephone'],
      dateNaissance: json['date_naissance'],
      sexe: json['sexe'],
      isActive: json['is_active'],
      photoProfil: json['photo_profil'],
      numero: json['numero'],
      nomRue: json['nom_rue'],
      commune: json['commune'],
      codePostal: json['code_postal'],
    );
  }
}

/// Représente un service spécifique tel qu'il est listé dans un rendez-vous confirmé.
class ServiceRdv {
  /// L'identifiant du service.
  final int id;
  /// Le nom ou l'intitulé du service.
  final String intitule;
  /// Le prix réellement appliqué pour ce service lors du RDV (peut inclure une promotion).
  final double prixApplique;

  /// Constructeur pour créer une instance de [ServiceRdv].
  ServiceRdv({required this.id, required this.intitule, required this.prixApplique});

  /// Construit une instance de [ServiceRdv] à partir d'une map JSON.
  factory ServiceRdv.fromJson(Map<String, dynamic> json) {
    return ServiceRdv(
      id: json['idTblService'],
      intitule: json['intitule_service'],
      prixApplique: json['prix_applique'].toDouble(),
    );
  }

  /// Convertit l'instance en une map JSON.
  Map<String, dynamic> toJson() {
    return {
      'idTblService': id,
      'intitule_service': intitule,
      'prix_applique': prixApplique,
    };
  }
}








// import 'package:hairbnb/models/salon.dart';
//
// import 'client.dart';
// import 'coiffeuse.dart';
//
// class RdvConfirmation {
//   final int idRendezVous;
//   final ClientLite client;
//   final CoiffeuseLite coiffeuse;
//   final Salon salon;
//   final DateTime dateHeure;
//   final String statut;
//   final double totalPrix;
//   final int dureeTotale;
//   final List<ServiceRdv> services;
//
//   RdvConfirmation({
//     required this.idRendezVous,
//     required this.client,
//     required this.coiffeuse,
//     required this.salon,
//     required this.dateHeure,
//     required this.statut,
//     required this.totalPrix,
//     required this.dureeTotale,
//     required this.services,
//   });
//
//   factory RdvConfirmation.fromJson(Map<String, dynamic> json) {
//     print("DEBUG RDV JSON: $json");
//
//     return RdvConfirmation(
//       idRendezVous: json['idRendezVous'],
//       client: ClientLite.fromJson(json['client']),
//       coiffeuse: CoiffeuseLite.fromJson(json['coiffeuse']),
//       salon: Salon.fromJson(json['salon']),
//       dateHeure: DateTime.parse(json['date_heure']),
//       statut: json['statut'] ?? '',
//       totalPrix: (json['total_prix'] as num).toDouble(),
//       dureeTotale: json['duree_totale'],
//       services: (json['services'] as List)
//           .map((s) => ServiceRdv.fromJson(s))
//           .toList(),
//     );
//   }
// }
//
//
//
//
//
// //------------------------------------------------------------------------------
// class ClientLite extends Client {
//   ClientLite({
//     required super.idTblUser,
//     required super.uuid,
//     required super.nom,
//     required super.prenom,
//     required super.email,
//     required super.numeroTelephone,
//     required super.sexe,
//     required super.isActive,
//     super.dateNaissance,
//     super.photoProfil,
//     super.numero,
//     super.boitePostale,
//     super.nomRue,
//     super.commune,
//     super.codePostal,
//   });
//
//   factory ClientLite.fromJson(Map<String, dynamic> json) {
//     return ClientLite(
//       idTblUser: json['idTblUser'],
//       uuid: json['uuid'],
//       nom: json['nom'],
//       prenom: json['prenom'],
//       email: json['email'],
//       numeroTelephone: json['numero_telephone'],
//       dateNaissance: json['date_naissance'],
//       sexe: json['sexe'],
//       isActive: json['is_active'],
//       photoProfil: json['photo_profil'],
//       numero: json['numero'],
//       boitePostale: json['boite_postale'],
//       nomRue: json['nom_rue'],
//       commune: json['commune'],
//       codePostal: json['code_postal'],
//     );
//   }
// }
//
// //------------------------------------------------------------------------------
// class CoiffeuseLite extends Coiffeuse {
//   CoiffeuseLite({
//     required super.idTblUser,
//     required super.id,
//     super.nomCommercial,
//     super.position,
//     required super.uuid,
//     required super.nom,
//     required super.prenom,
//     required super.email,
//     required super.numeroTelephone,
//     super.dateNaissance,
//     required super.sexe,
//     required super.isActive,
//     super.photoProfil,
//     super.numero,
//     super.nomRue,
//     super.commune,
//     super.codePostal,
//   });
//
//   factory CoiffeuseLite.fromJson(Map<String, dynamic> json) {
//     return CoiffeuseLite(
//       idTblUser: json['idTblUser'],
//       id: json['id'],
//       nomCommercial: json['nom_commercial'],
//       position: json['position'],
//       uuid: json['uuid'],
//       nom: json['nom'],
//       prenom: json['prenom'],
//       email: json['email'],
//       numeroTelephone: json['numero_telephone'],
//       dateNaissance: json['date_naissance'],
//       sexe: json['sexe'],
//       isActive: json['is_active'],
//       photoProfil: json['photo_profil'],
//       numero: json['numero'],
//       nomRue: json['nom_rue'],
//       commune: json['commune'],
//       codePostal: json['code_postal'],
//     );
//   }
// }
//
//
// /// **📌 Modèle pour un service dans le RDV**
// class ServiceRdv {
//   final int id;
//   final String intitule;
//   final double prixApplique;
//
//   ServiceRdv({required this.id, required this.intitule, required this.prixApplique});
//
//   factory ServiceRdv.fromJson(Map<String, dynamic> json) {
//     return ServiceRdv(
//       id: json['idTblService'],
//       intitule: json['intitule_service'],
//       prixApplique: json['prix_applique'].toDouble(),
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'idTblService': id,
//       'intitule_service': intitule,
//       'prix_applique': prixApplique,
//     };
//   }
// }
