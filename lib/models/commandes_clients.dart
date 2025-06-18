////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//             MODÈLES DE DONNÉES POUR LES COMMANDES CLIENTS                    //
//                                                                            //
//  Ce fichier définit les classes nécessaires pour représenter une "Commande"//
//  côté professionnel. Une commande est essentiellement une vue détaillée     //
//  d'un rendez-vous, enrichie avec toutes les informations nécessaires pour  //
//  le suivi par la coiffeuse (détails client, statut, paiement, etc.).       //
//                                                                            //
//  - ServiceCommande : Représente un service individuel au sein d'une        //
//    commande.                                                               //
//  - CommandeClient : Le modèle principal qui agrège toutes les informations //
//    d'une commande.                                                         //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

//##############################################################################
//#                   MODÈLE PRINCIPAL POUR UNE COMMANDE CLIENT                #
//##############################################################################

/// Représente une commande client, qui correspond à un rendez-vous détaillé.
/// Cette classe agrège les informations sur le rendez-vous, le client, le salon,
/// le paiement et les services associés.
class CommandeClient {
  //region Propriétés de la Commande

  // --- Infos sur le Rendez-vous ---
  /// L'identifiant unique du rendez-vous.
  final int idRendezVous;
  /// La date et l'heure du rendez-vous au format String ISO 8601.
  final String dateHeure;
  /// Le statut actuel du rendez-vous (ex: "Confirmé", "Terminé", "Annulé").
  final String statut;

  // --- Infos sur le Client ---
  /// Le nom de famille du client.
  final String nomClient;
  /// Le prénom du client.
  final String prenomClient;
  /// Le numéro de téléphone du client.
  final String telephoneClient;
  /// L'adresse e-mail du client.
  final String emailClient;

  // --- Infos sur le Salon ---
  /// Le nom du salon où a lieu le rendez-vous.
  final String nomSalon;

  // --- Infos Financières ---
  /// Le prix total de la commande.
  final double totalPrix;
  /// La durée totale estimée de tous les services, en minutes.
  final int dureeTotale;
  /// Le statut du paiement (ex: "Payé", "En attente"). Peut être nul.
  final String? statutPaiement;
  /// La date du paiement. Peut être nul.
  final String? datePaiement;
  /// Le montant effectivement payé. Peut être nul.
  final double? montantPaye;

  // --- Contenu de la commande ---
  /// La liste des services inclus dans la commande.
  final List<ServiceCommande> services;
  /// Indique si la commande est archivée ou non.
  final bool estArchive;

  //endregion

  /// Constructeur pour créer une instance de `CommandeClient`.
  CommandeClient({
    required this.idRendezVous,
    required this.dateHeure,
    required this.statut,
    required this.nomClient,
    required this.prenomClient,
    required this.telephoneClient,
    required this.emailClient,
    required this.nomSalon,
    required this.totalPrix,
    required this.dureeTotale,
    this.statutPaiement,
    this.datePaiement,
    this.montantPaye,
    required this.services,
    required this.estArchive,
  });

  /// Factory constructor pour créer une instance de `CommandeClient` à partir d'un map JSON.
  /// Gère la désérialisation des données reçues de l'API.
  factory CommandeClient.fromJson(Map<String, dynamic> json) {
    return CommandeClient(
      idRendezVous: json['idRendezVous'],
      dateHeure: json['date_heure'],
      statut: json['statut'],
      nomClient: json['nom_client'],
      prenomClient: json['prenom_client'],
      telephoneClient: json['telephone_client'] ?? 'Non renseigné',
      emailClient: json['email_client'],
      nomSalon: json['nom_salon'],
      // Conversion robuste pour les nombres, qui peuvent arriver en String ou int.
      totalPrix: double.parse(json['total_prix'].toString()),
      dureeTotale: json['duree_totale'] ?? 0,
      statutPaiement: json['statut_paiement'],
      datePaiement: json['date_paiement'],
      montantPaye: json['montant_paye'] != null
          ? double.parse(json['montant_paye'].toString())
          : null,
      // Itération sur la liste de services et conversion de chaque élément.
      services: (json['services'] as List)
          .map((service) => ServiceCommande.fromJson(service))
          .toList(),
      estArchive: json['est_archive'] ?? false,
    );
  }

  /// Convertit l'instance de `CommandeClient` en un map JSON.
  /// Utile pour la sérialisation des données à envoyer vers une API.
  Map<String, dynamic> toJson() {
    return {
      'idRendezVous': idRendezVous,
      'date_heure': dateHeure,
      'statut': statut,
      'nom_client': nomClient,
      'prenom_client': prenomClient,
      'telephone_client': telephoneClient,
      'email_client': emailClient,
      'nom_salon': nomSalon,
      'total_prix': totalPrix,
      'duree_totale': dureeTotale,
      'statut_paiement': statutPaiement,
      'date_paiement': datePaiement,
      'montant_paye': montantPaye,
      'services': services.map((service) => service.toJson()).toList(),
      'est_archive': estArchive,
    };
  }

  /// Crée une copie de cette instance de `CommandeClient` avec les champs fournis modifiés.
  /// Cette méthode est très utile pour la gestion d'état immuable (ex: avec Riverpod, BLoC),
  /// car elle permet de créer un nouvel état mis à jour sans modifier l'original.
  CommandeClient copyWith({
    int? idRendezVous,
    String? dateHeure,
    String? statut,
    String? nomClient,
    String? prenomClient,
    String? telephoneClient,
    String? emailClient,
    String? nomSalon,
    double? totalPrix,
    int? dureeTotale,
    String? statutPaiement,
    String? datePaiement,
    double? montantPaye,
    List<ServiceCommande>? services,
    bool? estArchive,
  }) {
    return CommandeClient(
      idRendezVous: idRendezVous ?? this.idRendezVous,
      dateHeure: dateHeure ?? this.dateHeure,
      statut: statut ?? this.statut,
      nomClient: nomClient ?? this.nomClient,
      prenomClient: prenomClient ?? this.prenomClient,
      telephoneClient: telephoneClient ?? this.telephoneClient,
      emailClient: emailClient ?? this.emailClient,
      nomSalon: nomSalon ?? this.nomSalon,
      totalPrix: totalPrix ?? this.totalPrix,
      dureeTotale: dureeTotale ?? this.dureeTotale,
      statutPaiement: statutPaiement ?? this.statutPaiement,
      datePaiement: datePaiement ?? this.datePaiement,
      montantPaye: montantPaye ?? this.montantPaye,
      services: services ?? this.services,
      estArchive: estArchive ?? this.estArchive,
    );
  }
}

//##############################################################################
//#                   MODÈLE POUR UN SERVICE DANS UNE COMMANDE                 #
//##############################################################################

/// Représente un service individuel au sein d'une commande.
/// Contient les informations clés du service telles qu'elles étaient au moment
/// de la réservation.
class ServiceCommande {
  /// Le nom du service.
  final String intituleService;
  /// Le prix qui a été appliqué pour ce service dans cette commande.
  final double prixApplique;
  /// La durée qui a été estimée pour ce service dans cette commande.
  final int dureeEstimee;

  /// Constructeur pour créer une instance de `ServiceCommande`.
  ServiceCommande({
    required this.intituleService,
    required this.prixApplique,
    required this.dureeEstimee,
  });

  /// Factory constructor pour créer une instance de `ServiceCommande` à partir d'un map JSON.
  factory ServiceCommande.fromJson(Map<String, dynamic> json) {
    return ServiceCommande(
      intituleService: json['intitule_service'],
      prixApplique: double.parse(json['prix_applique'].toString()),
      dureeEstimee: json['duree_estimee'] ?? 0,
    );
  }

  /// Convertit l'instance de `ServiceCommande` en un map JSON.
  Map<String, dynamic> toJson() {
    return {
      'intitule_service': intituleService,
      'prix_applique': prixApplique,
      'duree_estimee': dureeEstimee,
    };
  }
}









// class CommandeClient {
//   final int idRendezVous;
//   final String dateHeure;
//   final String statut;
//   final String nomClient;
//   final String prenomClient;
//   final String telephoneClient;
//   final String emailClient; // Ajout du champ email
//   final String nomSalon;
//   final double totalPrix;
//   final int dureeTotale;
//   final String? statutPaiement;
//   final String? datePaiement;
//   final double? montantPaye;
//   final List<ServiceCommande> services;
//   final bool estArchive;
//
//   CommandeClient({
//     required this.idRendezVous,
//     required this.dateHeure,
//     required this.statut,
//     required this.nomClient,
//     required this.prenomClient,
//     required this.telephoneClient,
//     required this.emailClient, // Paramètre pour l'email
//     required this.nomSalon,
//     required this.totalPrix,
//     required this.dureeTotale,
//     this.statutPaiement,
//     this.datePaiement,
//     this.montantPaye,
//     required this.services,
//     required this.estArchive,
//   });
//
//   // Création à partir d'un JSON
//   factory CommandeClient.fromJson(Map<String, dynamic> json) {
//     return CommandeClient(
//       idRendezVous: json['idRendezVous'],
//       dateHeure: json['date_heure'],
//       statut: json['statut'],
//       nomClient: json['nom_client'],
//       prenomClient: json['prenom_client'],
//       telephoneClient: json['telephone_client'] ?? 'Non renseigné',
//       emailClient: json['email_client'], // Récupération de l'email depuis le JSON
//       nomSalon: json['nom_salon'],
//       totalPrix: double.parse(json['total_prix'].toString()),
//       dureeTotale: json['duree_totale'] ?? 0,
//       statutPaiement: json['statut_paiement'],
//       datePaiement: json['date_paiement'],
//       montantPaye: json['montant_paye'] != null
//           ? double.parse(json['montant_paye'].toString())
//           : null,
//       services: (json['services'] as List)
//           .map((service) => ServiceCommande.fromJson(service))
//           .toList(),
//       estArchive: json['est_archive'] ?? false,
//     );
//   }
//
//   // Conversion en JSON
//   Map<String, dynamic> toJson() {
//     return {
//       'idRendezVous': idRendezVous,
//       'date_heure': dateHeure,
//       'statut': statut,
//       'nom_client': nomClient,
//       'prenom_client': prenomClient,
//       'telephone_client': telephoneClient,
//       'email_client': emailClient, // Ajout de l'email dans le JSON
//       'nom_salon': nomSalon,
//       'total_prix': totalPrix,
//       'duree_totale': dureeTotale,
//       'statut_paiement': statutPaiement,
//       'date_paiement': datePaiement,
//       'montant_paye': montantPaye,
//       'services': services.map((service) => service.toJson()).toList(),
//       'est_archive': estArchive,
//     };
//   }
//
//   // Pour mettre à jour le statut
//   CommandeClient copyWith({
//     int? idRendezVous,
//     String? dateHeure,
//     String? statut,
//     String? nomClient,
//     String? prenomClient,
//     String? telephoneClient,
//     String? emailClient, // Ajout du paramètre email
//     String? nomSalon,
//     double? totalPrix,
//     int? dureeTotale,
//     String? statutPaiement,
//     String? datePaiement,
//     double? montantPaye,
//     List<ServiceCommande>? services,
//     bool? estArchive,
//   }) {
//     return CommandeClient(
//       idRendezVous: idRendezVous ?? this.idRendezVous,
//       dateHeure: dateHeure ?? this.dateHeure,
//       statut: statut ?? this.statut,
//       nomClient: nomClient ?? this.nomClient,
//       prenomClient: prenomClient ?? this.prenomClient,
//       telephoneClient: telephoneClient ?? this.telephoneClient,
//       emailClient: emailClient ?? this.emailClient, // Gestion de la copie de l'email
//       nomSalon: nomSalon ?? this.nomSalon,
//       totalPrix: totalPrix ?? this.totalPrix,
//       dureeTotale: dureeTotale ?? this.dureeTotale,
//       statutPaiement: statutPaiement ?? this.statutPaiement,
//       datePaiement: datePaiement ?? this.datePaiement,
//       montantPaye: montantPaye ?? this.montantPaye,
//       services: services ?? this.services,
//       estArchive: estArchive ?? this.estArchive,
//     );
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
//   // Création à partir d'un JSON
//   factory ServiceCommande.fromJson(Map<String, dynamic> json) {
//     return ServiceCommande(
//       intituleService: json['intitule_service'],
//       prixApplique: double.parse(json['prix_applique'].toString()),
//       dureeEstimee: json['duree_estimee'] ?? 0,
//     );
//   }
//
//   // Conversion en JSON
//   Map<String, dynamic> toJson() {
//     return {
//       'intitule_service': intituleService,
//       'prix_applique': prixApplique,
//       'duree_estimee': dureeEstimee,
//     };
//   }
// }
