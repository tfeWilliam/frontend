////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                 MODÈLE DE DONNÉES POUR LES FAVORIS UTILISATEUR               //
//                                                                            //
//  Ce fichier définit le modèle `FavoriteModel`, qui représente la mise en   //
//  favori d'un salon par un utilisateur. La particularité de ce modèle est   //
//  sa capacité à gérer une représentation flexible du salon (soit un ID,      //
//  soit un objet complet), ce qui le rend robuste face à différentes         //
//  réponses de l'API.                                                        //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


/// Représente une entrée de "favori", liant un utilisateur à un salon.
class FavoriteModel {
  /// L'identifiant unique de l'enregistrement de favori lui-même.
  final int idTblFavorite;
  /// L'identifiant de l'utilisateur qui a ajouté le favori. Peut être nul.
  final int? user;
  /// Le salon mis en favori. Ce champ est de type `dynamic` car l'API
  /// peut retourner soit l'ID du salon (un `int`), soit l'objet salon complet
  /// (un `Map<String, dynamic>`).
  final dynamic salon;
  /// La date et l'heure auxquelles le favori a été ajouté. Peut être nul.
  final String? addedAt;

  /// Constructeur pour créer une instance de `FavoriteModel`.
  FavoriteModel({
    required this.idTblFavorite,
    this.user,
    required this.salon,
    this.addedAt,
  });

  /// Méthode utilitaire pour extraire de manière fiable l'ID du salon.
  ///
  /// Quelle que soit la forme de la propriété `salon` (`int` ou `Map`),
  /// cette méthode retourne son identifiant numérique.
  /// Retourne `0` si l'ID ne peut pas être déterminé.
  int getSalonId() {
    // Si 'salon' est déjà un entier, on le retourne directement.
    if (salon is int) {
      return salon;
    }
    // Si 'salon' est un objet Map, on en extrait la clé 'idTblSalon'.
    else if (salon is Map<String, dynamic> && salon.containsKey('idTblSalon')) {
      return salon['idTblSalon'];
    }
    // Valeur par défaut en cas de format inattendu.
    return 0;
  }

  /// Factory constructor pour créer une instance de `FavoriteModel` à partir d'un map JSON.
  ///
  /// Cette méthode est utilisée pour la désérialisation des données reçues de l'API.
  /// Le champ `salon` est conservé tel quel (en `dynamic`) pour être traité par `getSalonId()`.
  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      idTblFavorite: json['idTblFavorite'],
      user: json['user'],
      salon: json['salon'],
      addedAt: json['added_at'],
    );
  }

  /// Convertit l'instance de `FavoriteModel` en un map JSON.
  ///
  /// Cette méthode est utilisée pour la sérialisation, par exemple pour envoyer
  /// des données à une API. Elle s'assure de n'envoyer que l'ID du salon.
  Map<String, dynamic> toJson() {
    return {
      'idTblFavorite': idTblFavorite,
      'user': user,
      // Logique pour s'assurer que seul l'ID du salon est envoyé, quel que soit le type de `salon`.
      'salon': salon is int ? salon : (salon is Map ? salon['idTblSalon'] : 0),
      'added_at': addedAt,
    };
  }

  /// Fournit une représentation textuelle de l'objet pour faciliter le débogage.
  @override
  String toString() {
    return 'FavoriteModel(idTblFavorite: $idTblFavorite, user: $user, salon: ${getSalonId()}, addedAt: $addedAt)';
  }
}


// // models/favorites.dart
// class FavoriteModel {
//   final int idTblFavorite;
//   final int? user;  // Nullable car parfois absent dans la réponse
//   final dynamic salon; // Peut être un int ou un objet complet
//   final String? addedAt; // Nullable car parfois absent dans la réponse
//
//   FavoriteModel({
//     required this.idTblFavorite,
//     this.user,
//     required this.salon,
//     this.addedAt,
//   });
//
//   // Méthode pour obtenir l'ID du salon quelle que soit sa représentation
//   int getSalonId() {
//     if (salon is int) {
//       return salon;
//     } else if (salon is Map<String, dynamic> && salon.containsKey('idTblSalon')) {
//       return salon['idTblSalon'];
//     }
//     return 0; // Valeur par défaut en cas d'erreur
//   }
//
//   factory FavoriteModel.fromJson(Map<String, dynamic> json) {
//     return FavoriteModel(
//       idTblFavorite: json['idTblFavorite'],
//       user: json['user'],
//       salon: json['salon'], // Peut être un int ou un objet complet
//       addedAt: json['added_at'],
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'idTblFavorite': idTblFavorite,
//       'user': user,
//       'salon': salon is int ? salon : (salon is Map ? salon['idTblSalon'] : 0),
//       'added_at': addedAt,
//     };
//   }
//
//   @override
//   String toString() {
//     return 'FavoriteModel(idTblFavorite: $idTblFavorite, user: $user, salon: ${salon is int ? salon : "Objet Salon"}, addedAt: $addedAt)';
//   }
// }
