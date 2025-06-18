////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                MODÈLE DE DONNÉES POUR L'HORAIRE DE TRAVAIL                   //
//                                                                            //
//  Ce fichier définit le modèle `HoraireCoiffeuse`, qui représente une plage  //
//  horaire de travail récurrente dans l'emploi du temps hebdomadaire d'une    //
//  coiffeuse. Cette classe est utilisée pour afficher et gérer les           //
//  disponibilités de travail standard.                                       //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


/// Représente une plage horaire de travail fixe pour un jour de la semaine.
///
/// Par exemple, "Lundi de 08:00 à 17:00".
class HoraireCoiffeuse {
  /// L'identifiant unique de cette plage horaire en base de données.
  final int id;
  /// L'identifiant de la coiffeuse à qui cet horaire appartient.
  final int coiffeuseId;
  /// La représentation numérique du jour de la semaine (ex: 0 pour Lundi, 1 pour Mardi, etc.).
  final int jour;
  /// Le nom lisible du jour de la semaine (ex: "Lundi").
  final String jourLabel;
  /// L'heure de début de la plage de travail, au format "HH:mm".
  final String heureDebut;
  /// L'heure de fin de la plage de travail, au format "HH:mm".
  final String heureFin;

  /// Constructeur pour créer une instance de `HoraireCoiffeuse`.
  HoraireCoiffeuse({
    required this.id,
    required this.coiffeuseId,
    required this.jour,
    required this.jourLabel,
    required this.heureDebut,
    required this.heureFin,
  });

  /// Factory constructor pour créer une instance de `HoraireCoiffeuse` à partir d'un map JSON.
  ///
  /// Utilisé pour la désérialisation des données reçues d'une API.
  factory HoraireCoiffeuse.fromJson(Map<String, dynamic> json) {
    return HoraireCoiffeuse(
      id: json['id'],
      coiffeuseId: json['coiffeuse_id'] ?? json['coiffeuse'], // Compatible avec les deux clés
      jour: json['jour'],
      jourLabel: json['jour_label'],
      heureDebut: json['heure_debut'],
      heureFin: json['heure_fin'],
    );
  }

  /// Convertit l'instance de `HoraireCoiffeuse` en un map JSON.
  ///
  /// Utilisé pour la sérialisation des données à envoyer vers une API (par exemple,
  /// pour la création ou la modification d'un horaire). Notez que seuls les
  /// champs nécessaires pour une requête sont inclus.
  Map<String, dynamic> toJson() {
    return {
      'coiffeuse': coiffeuseId,
      'jour': jour,
      'heure_debut': heureDebut,
      'heure_fin': heureFin,
    };
  }
}






// class HoraireCoiffeuse {
//   final int id;
//   final int coiffeuseId;
//   final int jour; // Ex: 0 = Lundi
//   final String jourLabel; // Ex: "Lundi"
//   final String heureDebut; // Format: "08:00"
//   final String heureFin;   // Format: "17:00"
//
//   HoraireCoiffeuse({
//     required this.id,
//     required this.coiffeuseId,
//     required this.jour,
//     required this.jourLabel,
//     required this.heureDebut,
//     required this.heureFin,
//   });
//
//   factory HoraireCoiffeuse.fromJson(Map<String, dynamic> json) {
//     return HoraireCoiffeuse(
//       id: json['id'],
//       coiffeuseId: json['coiffeuse_id'],
//       jour: json['jour'],
//       jourLabel: json['jour_label'],
//       heureDebut: json['heure_debut'],
//       heureFin: json['heure_fin'],
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'coiffeuse': coiffeuseId,
//       'jour': jour,
//       'heure_debut': heureDebut,
//       'heure_fin': heureFin,
//     };
//   }
// }
