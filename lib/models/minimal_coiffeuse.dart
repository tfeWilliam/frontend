/****************************************************************************************
 *
 * MODÈLE DE DONNÉES : MinimalCoiffeuse
 *
 * OBJECTIF :
 * Cette classe représente un modèle de données "minimal" ou "léger" d'une coiffeuse.
 * Elle est conçue pour ne contenir que les informations essentielles nécessaires
 * pour des affichages de type liste ou résumé, évitant ainsi de charger des
 * données plus complexes et lourdes inutilement, ce qui améliore les performances.
 *
 * FONCTIONNALITÉS CLÉS :
 * - Contient les informations d'identification de base (ID, nom, prénom).
 * - Inclut des données de profil optionnelles (photo, nom commercial).
 * - Peut contenir des informations sur un salon principal (sous forme de Map) et
 * une liste d'autres salons.
 * - Possède une méthode factory `fromJson` robuste qui gère les valeurs nulles
 * pour les champs critiques.
 * - Propose des "accesseurs" (getters) pour extraire de manière sûre et pratique
 * les informations imbriquées dans la map du salon principal.
 *
 *****************************************************************************************/

class MinimalCoiffeuse {
  // Identifiant numérique unique de l'utilisateur (coiffeuse) dans la base de données.
  final int idTblUser;
  // Identifiant unique universel (UUID) de l'utilisateur.
  final String uuid;
  // Nom de famille de la coiffeuse.
  final String nom;
  // Prénom de la coiffeuse.
  final String prenom;
  // URL vers la photo de profil de la coiffeuse (peut être nul).
  final String? photoProfil;
  // Nom commercial utilisé par la coiffeuse (peut être nul).
  final String? nomCommercial;
  // Map (dictionnaire) contenant les informations du salon principal associé (peut être nul).
  final Map<String, dynamic>? salon;
  // Liste contenant d'autres salons où la coiffeuse travaille (peut être nulle).
  final List<dynamic>? autresSalons;

  // Constructeur pour créer une instance du modèle MinimalCoiffeuse.
  MinimalCoiffeuse({
    required this.idTblUser,
    required this.uuid,
    required this.nom,
    required this.prenom,
    this.photoProfil,
    this.nomCommercial,
    this.salon,
    this.autresSalons,
  });

  /// Crée une instance de MinimalCoiffeuse à partir d'une map JSON.
  /// Gère les valeurs nulles pour les champs requis en leur assignant une
  /// valeur par défaut afin de garantir la stabilité de l'objet.
  factory MinimalCoiffeuse.fromJson(Map<String, dynamic> json) {
    return MinimalCoiffeuse(
      idTblUser: json['idTblUser'] ?? 0,
      uuid: json['uuid'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      photoProfil: json['photo_profil'],
      nomCommercial: json['nom_commercial'],
      salon: json['salon'],
      autresSalons: json['autres_salons'],
    );
  }

  // ACCESSEURS (GETTERS) PRATIQUES
  // Ces accesseurs permettent d'accéder de manière sûre aux données imbriquées
  // dans la map `salon`. Si `salon` est nul, ils retournent `null` au lieu de
  // provoquer une erreur.

  /// Récupère le nom du salon principal.
  String? get nomSalon => salon?['nom_salon'];

  /// Récupère le slogan du salon principal.
  String? get salonSlogan => salon?['slogan'];

  /// Récupère l'URL du logo du salon principal.
  String? get logoSalon => salon?['logo_salon'];

  /// Récupère les informations de position du salon principal.
  String? get salonPosition => salon?['position'];

  /// Récupère l'identifiant unique du salon principal.
  int? get idSalon => salon?['idTblSalon'];
}





// class MinimalCoiffeuse {
//   final int idTblUser;
//   final String uuid;
//   final String nom;
//   final String prenom;
//   final String? photoProfil;
//   final String? nomCommercial;
//   final Map<String, dynamic>? salon;
//   final List<dynamic>? autresSalons;
//
//   MinimalCoiffeuse({
//     required this.idTblUser,
//     required this.uuid,
//     required this.nom,
//     required this.prenom,
//     this.photoProfil,
//     this.nomCommercial,
//     this.salon,
//     this.autresSalons,
//   });
//
//   factory MinimalCoiffeuse.fromJson(Map<String, dynamic> json) {
//     return MinimalCoiffeuse(
//       idTblUser: json['idTblUser'] ?? 0,
//       uuid: json['uuid'] ?? '',
//       nom: json['nom'] ?? '',
//       prenom: json['prenom'] ?? '',
//       photoProfil: json['photo_profil'],
//       nomCommercial: json['nom_commercial'],
//       salon: json['salon'],
//       autresSalons: json['autres_salons'],
//     );
//   }
//
// // Quelques accesseurs utiles
//   String? get nomSalon => salon?['nom_salon'];
//
//   String? get salonSlogan => salon?['slogan'];
//
//   String? get logoSalon => salon?['logo_salon'];
//
//   String? get salonPosition => salon?['position'];
//
//   int? get idSalon => salon?['idTblSalon'];
// }
