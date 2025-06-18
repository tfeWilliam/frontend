/****************************************************************************************
 *
 * MODÈLE DE DONNÉES : ReservationLight
 *
 * OBJECTIF :
 * Cette classe représente un modèle de données "léger" (lightweight) ou "résumé"
 * d'une réservation ou d'un rendez-vous. Elle est conçue pour contenir uniquement
 * les informations essentielles nécessaires à un affichage rapide dans des listes,
 * des calendriers ou des tableaux de bord.
 *
 * UTILISATION :
 * L'utilisation de ce modèle léger permet d'améliorer les performances en évitant
 * de charger l'intégralité des données détaillées d'un rendez-vous lorsqu'on
 * affiche de multiples réservations à la fois.
 *
 *****************************************************************************************/

class ReservationLight {
  /// L'identifiant unique du rendez-vous dans la base de données.
  final int idRendezVous;
  /// Le nom de famille du client associé à la réservation.
  final String clientNom;
  /// Le prénom du client associé à la réservation.
  final String clientPrenom;
  /// L'URL de la photo de profil du client (peut être nulle).
  final String? photoProfil;
  /// La date et l'heure exactes du rendez-vous.
  final DateTime dateHeure;
  /// Le statut actuel du rendez-vous (ex: "Confirmé", "En attente", "Annulé").
  final String statut;
  /// Le prix total estimé pour l'ensemble des services de ce rendez-vous.
  final double totalPrix;
  /// La durée totale estimée en minutes pour la réalisation des services.
  final int dureeTotale;

  /// Constructeur pour créer une nouvelle instance de [ReservationLight].
  ReservationLight({
    required this.idRendezVous,
    required this.clientNom,
    required this.clientPrenom,
    this.photoProfil,
    required this.dateHeure,
    required this.statut,
    required this.totalPrix,
    required this.dureeTotale,
  });

  /// Construit une instance de [ReservationLight] à partir d'une map JSON.
  /// Cette méthode est utilisée pour désérialiser les données venant d'une API.
  factory ReservationLight.fromJson(Map<String, dynamic> json) {
    return ReservationLight(
      idRendezVous: json['idRendezVous'],
      clientNom: json['client_nom'],
      clientPrenom: json['client_prenom'],
      photoProfil: json['client_photo'],
      dateHeure: DateTime.parse(json['date_heure']),
      statut: json['statut'],
      // Conversion robuste pour s'assurer que le prix est toujours un double.
      totalPrix: (json['total_prix'] as num).toDouble(),
      dureeTotale: json['duree_totale'],
    );
  }
}








// class ReservationLight {
//   final int idRendezVous;
//   final String clientNom;
//   final String clientPrenom;
//   final String? photoProfil;
//   final DateTime dateHeure;
//   final String statut;
//   final double totalPrix;
//   final int dureeTotale;
//
//   ReservationLight({
//     required this.idRendezVous,
//     required this.clientNom,
//     required this.clientPrenom,
//     this.photoProfil,
//     required this.dateHeure,
//     required this.statut,
//     required this.totalPrix,
//     required this.dureeTotale,
//   });
//
//   factory ReservationLight.fromJson(Map<String, dynamic> json) {
//     return ReservationLight(
//       idRendezVous: json['idRendezVous'],
//       clientNom: json['client_nom'],
//       clientPrenom: json['client_prenom'],
//       photoProfil: json['client_photo'],
//       dateHeure: DateTime.parse(json['date_heure']),
//       statut: json['statut'],
//       totalPrix: (json['total_prix'] as num).toDouble(),
//       dureeTotale: json['duree_totale'],
//     );
//   }
// }
