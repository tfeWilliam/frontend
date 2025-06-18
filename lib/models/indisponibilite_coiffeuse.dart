/****************************************************************************************
 *
 * MODÈLE DE DONNÉES : IndisponibiliteCoiffeuse
 *
 * OBJECTIF :
 * Cette classe sert de modèle de données pour représenter une période d'indisponibilité
 * spécifique pour une coiffeuse. Elle structure toutes les informations nécessaires,
 * comme la date, l'heure de début et de fin.
 *
 * FONCTIONNALITÉS CLÉS :
 * - Contient les propriétés d'une indisponibilité (ID, date, heures, motif).
 * - Inclut une méthode factory `fromJson` pour créer une instance de cette classe
 * à partir de données JSON (typiquement reçues d'une API).
 * - Inclut une méthode `toJson` pour convertir une instance de la classe en un
 * format JSON (typiquement pour l'envoyer à une API).
 *
 * UTILISATION :
 * Cet objet est utilisé dans l'application pour manipuler, afficher et transmettre
 * les plages horaires où une coiffeuse n'est pas disponible pour des rendez-vous.
 *
 *****************************************************************************************/

class IndisponibiliteCoiffeuse {
  // Identifiant unique de cette période d'indisponibilité dans la base de données.
  final int id;

  // Identifiant de la coiffeuse concernée par cette indisponibilité.
  final int coiffeuseId;

  // La date de l'indisponibilité, au format "AAAA-MM-JJ".
  final String date;

  // L'heure à laquelle l'indisponibilité commence, au format "HH:MM".
  final String heureDebut;

  // L'heure à laquelle l'indisponibilité se termine, au format "HH:MM".
  final String heureFin;

  // Un motif ou une raison optionnelle pour l'indisponibilité (peut être nul).
  final String? motif;

  // Constructeur principal pour créer une instance de la classe.
  IndisponibiliteCoiffeuse({
    required this.id,
    required this.coiffeuseId,
    required this.date,
    required this.heureDebut,
    required this.heureFin,
    this.motif,
  });

  /// Méthode "factory" qui construit une instance de [IndisponibiliteCoiffeuse]
  /// à partir d'une map JSON. C'est le processus de désérialisation.
  factory IndisponibiliteCoiffeuse.fromJson(Map<String, dynamic> json) {
    return IndisponibiliteCoiffeuse(
      id: json['id'],
      coiffeuseId: json['coiffeuse_id'],
      date: json['date'],
      heureDebut: json['heure_debut'],
      heureFin: json['heure_fin'],
      motif: json['motif'],
    );
  }

  /// Méthode qui convertit l'instance actuelle de [IndisponibiliteCoiffeuse]
  /// en une map JSON. C'est le processus de sérialisation, utile pour envoyer
  /// des données à un serveur ou une API.
  Map<String, dynamic> toJson() {
    return {
      // Note : L'ID de l'indisponibilité n'est généralement pas envoyé lors de la création/mise à jour.
      'coiffeuse': coiffeuseId,
      'date': date,
      'heure_debut': heureDebut,
      'heure_fin': heureFin,
      'motif': motif,
    };
  }
}



// class IndisponibiliteCoiffeuse {
//   final int id;
//   final int coiffeuseId;
//   final String date;       // Format: "2025-05-01"
//   final String heureDebut; // Format: "10:00"
//   final String heureFin;   // Format: "16:00"
//   final String? motif;
//
//   IndisponibiliteCoiffeuse({
//     required this.id,
//     required this.coiffeuseId,
//     required this.date,
//     required this.heureDebut,
//     required this.heureFin,
//     this.motif,
//   });
//
//   factory IndisponibiliteCoiffeuse.fromJson(Map<String, dynamic> json) {
//     return IndisponibiliteCoiffeuse(
//       id: json['id'],
//       coiffeuseId: json['coiffeuse_id'],
//       date: json['date'],
//       heureDebut: json['heure_debut'],
//       heureFin: json['heure_fin'],
//       motif: json['motif'],
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'coiffeuse': coiffeuseId,
//       'date': date,
//       'heure_debut': heureDebut,
//       'heure_fin': heureFin,
//       'motif': motif,
//     };
//   }
// }
