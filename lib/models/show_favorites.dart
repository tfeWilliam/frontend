/****************************************************************************************
 *
 * MODÈLES DE DONNÉES : AFFICHAGE DES FAVORIS
 *
 * OBJECTIF :
 * Ce fichier définit les modèles de données nécessaires pour représenter et afficher
 * la liste des salons favoris d'un utilisateur.
 *
 * STRUCTURE DES CLASSES :
 * - ShowFavorite : Le modèle principal qui représente une entrée unique dans la liste
 * des favoris. Il associe un identifiant de favori à un objet Salon.
 *
 * - Salon : Un modèle de données "léger" ou "résumé" qui contient les informations
 * essentielles d'un salon pour un affichage concis dans une liste.
 *
 *****************************************************************************************/

/// Modèle représentant une entrée unique dans la liste des favoris d'un utilisateur.
class ShowFavorite {
  /// L'identifiant unique de l'enregistrement "favori" lui-même.
  /// Utile pour des actions comme la suppression du favori.
  final int idTblFavorite;
  /// L'objet [Salon] qui a été mis en favori, contenant ses détails.
  final Salon salon;

  /// Constructeur pour créer une instance de [ShowFavorite].
  ShowFavorite({
    required this.idTblFavorite,
    required this.salon,
  });

  /// Construit une instance de [ShowFavorite] à partir d'une map JSON.
  /// Cette méthode est utilisée pour désérialiser les données venant d'une API.
  factory ShowFavorite.fromJson(Map<String, dynamic> json) {
    return ShowFavorite(
      idTblFavorite: json['idTblFavorite'],
      salon: Salon.fromJson(json['salon']),
    );
  }
}

/// Modèle léger représentant les informations essentielles d'un salon pour un affichage en liste.
class Salon {
  /// L'identifiant unique du salon.
  final int idTblSalon;
  /// L'identifiant de la coiffeuse principale ou propriétaire du salon.
  final int coiffeuse;
  /// Le nom commercial du salon.
  final String nomSalon;
  /// Le slogan ou la phrase d'accroche du salon.
  final String slogan;
  /// L'URL du logo du salon.
  final String logoSalon;

  /// Constructeur pour créer une instance de [Salon].
  Salon({
    required this.idTblSalon,
    required this.coiffeuse,
    required this.nomSalon,
    required this.slogan,
    required this.logoSalon,
  });

  /// Construit une instance de [Salon] à partir d'une map JSON.
  factory Salon.fromJson(Map<String, dynamic> json) {
    return Salon(
      idTblSalon: json['idTblSalon'],
      coiffeuse: json['coiffeuse'],
      nomSalon: json['nom_salon'],
      slogan: json['slogan'],
      logoSalon: json['logo_salon'],
    );
  }
}





// class ShowFavorite {
//   final int idTblFavorite;
//   final Salon salon;
//
//   ShowFavorite({
//     required this.idTblFavorite,
//     required this.salon,
//   });
//
//   factory ShowFavorite.fromJson(Map<String, dynamic> json) {
//     return ShowFavorite(
//       idTblFavorite: json['idTblFavorite'],
//       salon: Salon.fromJson(json['salon']),
//     );
//   }
// }
//
// class Salon {
//   final int idTblSalon;
//   final int coiffeuse;
//   final String nomSalon;
//   final String slogan;
//   final String logoSalon;
//
//   Salon({
//     required this.idTblSalon,
//     required this.coiffeuse,
//     required this.nomSalon,
//     required this.slogan,
//     required this.logoSalon,
//   });
//
//   factory Salon.fromJson(Map<String, dynamic> json) {
//     return Salon(
//       idTblSalon: json['idTblSalon'],
//       coiffeuse: json['coiffeuse'],
//       nomSalon: json['nom_salon'],
//       slogan: json['slogan'],
//       logoSalon: json['logo_salon'],
//     );
//   }
// }
