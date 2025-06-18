/****************************************************************************************
 *
 * MODÈLES DE DONNÉES : GESTION DE SALONS GÉOLOCALISÉS
 * Fichiers : models/salon_details_for_geo.dart, models/salons_response.dart
 *
 * OBJECTIF :
 * Cet ensemble de classes modélise les données nécessaires pour gérer et afficher des
 * salons de coiffure avec un accent particulier sur la géolocalisation. Ils sont conçus
 * pour parser des réponses d'API qui retournent des salons à proximité d'un utilisateur,
 * et incluent de nombreux accesseurs (getters) pour faciliter la manipulation et
 * l'affichage de ces données dans l'interface utilisateur.
 *
 * STRUCTURE DES CLASSES :
 * - SalonsResponse : Le modèle "enveloppe" de haut niveau qui représente la réponse
 * complète de l'API, incluant un statut et une liste de salons.
 * - SalonDetailsForGeo : Le modèle de données principal pour un salon, contenant ses
 * informations, sa géolocalisation, sa distance, et une liste de ses coiffeuses.
 * - CoiffeuseDetailsForGeo : Un modèle détaillé pour une coiffeuse au sein d'un salon.
 *
 *****************************************************************************************/

// Fichier : models/salon_details_for_geo.dart

/// Modèle détaillé pour une coiffeuse, optimisé pour les contextes de géolocalisation.
class CoiffeuseDetailsForGeo {
  /// L'identifiant unique de l'entité coiffeuse.
  final int idTblCoiffeuse;
  /// L'identifiant de l'utilisateur associé.
  final int idTblUser;
  /// L'identifiant unique universel (UUID) de l'utilisateur.
  final String uuid;
  /// Le nom de famille de la coiffeuse.
  final String nom;
  /// Le prénom de la coiffeuse.
  final String prenom;
  /// Le rôle de la coiffeuse dans le salon (ex: "Gérante").
  final String role;
  /// Le type de profil (ex: "Coiffeuse").
  final String type;
  /// Booléen indiquant si cette coiffeuse est la propriétaire du salon.
  final bool estProprietaire;
  /// Le nom commercial de la coiffeuse, si elle en a un.
  final String? nomCommercial;

  /// Constructeur pour créer une instance de [CoiffeuseDetailsForGeo].
  CoiffeuseDetailsForGeo({
    required this.idTblCoiffeuse,
    required this.idTblUser,
    required this.uuid,
    required this.nom,
    required this.prenom,
    required this.role,
    required this.type,
    required this.estProprietaire,
    this.nomCommercial,
  });

  /// Construit une instance de [CoiffeuseDetailsForGeo] à partir d'une map JSON.
  factory CoiffeuseDetailsForGeo.fromJson(Map<String, dynamic> json) {
    return CoiffeuseDetailsForGeo(
      idTblCoiffeuse: json['idTblCoiffeuse'] ?? 0,
      idTblUser: json['idTblUser'] ?? 0,
      uuid: json['uuid'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      role: json['role'] ?? '',
      type: json['type'] ?? '',
      estProprietaire: json['est_proprietaire'] ?? false,
      nomCommercial: json['nom_commercial'],
    );
  }

  /// Convertit l'instance en une map JSON.
  Map<String, dynamic> toJson() {
    return {
      'idTblCoiffeuse': idTblCoiffeuse,
      'idTblUser': idTblUser,
      'uuid': uuid,
      'nom': nom,
      'prenom': prenom,
      'role': role,
      'type': type,
      'est_proprietaire': estProprietaire,
      'nom_commercial': nomCommercial,
    };
  }

  /// Accesseur (getter) qui retourne le nom complet (prénom + nom).
  String get nomComplet => '$prenom $nom';

  /// Accesseur (getter) qui retourne le nom à afficher, en priorisant le nom
  /// commercial sur le nom complet personnel.
  String get affichageNom => nomCommercial?.isNotEmpty == true ? nomCommercial! : nomComplet;
}

/// Modèle principal pour un salon, enrichi d'informations de géolocalisation.
class SalonDetailsForGeo {
  /// L'identifiant unique du salon.
  final int idTblSalon;
  /// Le nom du salon.
  final String nom;
  /// Le slogan du salon (optionnel).
  final String? slogan;
  /// L'URL du logo du salon (optionnel).
  final String? logo;
  /// L'adresse textuelle du salon.
  final String position;
  /// La coordonnée de latitude du salon (optionnelle).
  final double? latitude;
  /// La coordonnée de longitude du salon (optionnelle).
  final double? longitude;
  /// La liste des identifiants des coiffeuses du salon.
  final List<int> coiffeuseIds;
  /// La liste des objets détaillés pour chaque coiffeuse du salon.
  final List<CoiffeuseDetailsForGeo> coiffeusesDetails;
  /// La distance calculée entre l'utilisateur et le salon (en km).
  final double distance;

  /// Constructeur pour créer une instance de [SalonDetailsForGeo].
  SalonDetailsForGeo({
    required this.idTblSalon,
    required this.nom,
    this.slogan,
    this.logo,
    required this.position,
    this.latitude,
    this.longitude,
    required this.coiffeuseIds,
    required this.coiffeusesDetails,
    required this.distance,
  });

  /// Construit une instance de [SalonDetailsForGeo] à partir d'une map JSON.
  factory SalonDetailsForGeo.fromJson(Map<String, dynamic> json) {
    return SalonDetailsForGeo(
      idTblSalon: json['idTblSalon'] ?? 0,
      nom: json['nom'] ?? '',
      slogan: json['slogan'],
      logo: json['logo'],
      position: json['position'] ?? '0,0',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      coiffeuseIds: List<int>.from(json['coiffeuse_ids'] ?? []),
      coiffeusesDetails: (json['coiffeuses_details'] as List?)
          ?.map((x) => CoiffeuseDetailsForGeo.fromJson(x))
          .toList() ?? [],
      distance: json['distance']?.toDouble() ?? 0.0,
    );
  }

  /// Convertit l'instance en une map JSON.
  Map<String, dynamic> toJson() {
    return {
      'idTblSalon': idTblSalon,
      'nom': nom,
      'slogan': slogan,
      'logo': logo,
      'position': position,
      'latitude': latitude,
      'longitude': longitude,
      'coiffeuse_ids': coiffeuseIds,
      'coiffeuses_details': coiffeusesDetails.map((x) => x.toJson()).toList(),
      'distance': distance,
    };
  }

  /// Accesseur (getter) qui recherche et retourne la coiffeuse propriétaire du salon.
  /// Retourne `null` si aucune propriétaire n'est trouvée, évitant ainsi les erreurs.
  CoiffeuseDetailsForGeo? get proprietaire {
    try {
      return coiffeusesDetails.firstWhere((c) => c.estProprietaire);
    } catch (e) {
      return null;
    }
  }

  /// Accesseur (getter) qui retourne le nombre total de coiffeuses dans le salon.
  int get nombreCoiffeuses => coiffeusesDetails.length;

  /// Accesseur (getter) qui vérifie si le salon a un logo valide.
  bool get hasLogo => logo != null && logo!.isNotEmpty;

  /// Méthode pour obtenir l'URL complète du logo.
  /// Si l'URL du logo est relative, elle la préfixe avec une URL de base.
  String? getLogoUrl(String? baseUrl) {
    if (!hasLogo || baseUrl == null) return logo;
    return logo!.startsWith('http') ? logo : '$baseUrl$logo';
  }

  /// Accesseur (getter) qui formate la distance pour un affichage lisible.
  /// Affiche en mètres (m) si moins d'1 km, sinon en kilomètres (km).
  String get distanceFormatee {
    if (distance < 1) {
      return '${(distance * 1000).round()} m';
    }
    return '${distance.toStringAsFixed(1)} km';
  }
}

// --- Fichier : models/salons_response.dart ---

/// Modèle "enveloppe" qui représente la structure complète de la réponse de l'API des salons.
class SalonsResponse {
  /// Le statut de la réponse de l'API (ex: "success", "error").
  final String status;
  /// Le nombre total de résultats trouvés.
  final int count;
  /// La liste des salons retournés par l'API.
  final List<SalonDetailsForGeo> salons;

  /// Constructeur pour créer une instance de [SalonsResponse].
  SalonsResponse({
    required this.status,
    required this.count,
    required this.salons,
  });

  /// Construit une instance de [SalonsResponse] à partir d'une map JSON.
  factory SalonsResponse.fromJson(Map<String, dynamic> json) {
    return SalonsResponse(
      status: json['status'] ?? 'error',
      count: json['count'] ?? 0,
      salons: (json['salons'] as List?)
          ?.map((x) => SalonDetailsForGeo.fromJson(x))
          .toList() ?? [],
    );
  }

  /// Convertit l'instance en une map JSON.
  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'count': count,
      'salons': salons.map((x) => x.toJson()).toList(),
    };
  }

  /// Accesseur (getter) qui retourne `true` si le statut de la réponse est "success".
  bool get isSuccess => status == 'success';

  /// Accesseur (getter) qui retourne une nouvelle liste des salons triés par
  /// distance croissante, sans modifier la liste originale.
  List<SalonDetailsForGeo> get salonsTries {
    final List<SalonDetailsForGeo> sorted = List.from(salons);
    sorted.sort((a, b) => a.distance.compareTo(b.distance));
    return sorted;
  }
}








// // models/salon_details_for_geo.dart
// class CoiffeuseDetailsForGeo {
//   final int idTblCoiffeuse;
//   final int idTblUser;
//   final String uuid;
//   final String nom;
//   final String prenom;
//   final String role;
//   final String type;
//   final bool estProprietaire;
//   final String? nomCommercial;
//
//   CoiffeuseDetailsForGeo({
//     required this.idTblCoiffeuse,
//     required this.idTblUser,
//     required this.uuid,
//     required this.nom,
//     required this.prenom,
//     required this.role,
//     required this.type,
//     required this.estProprietaire,
//     this.nomCommercial,
//   });
//
//   factory CoiffeuseDetailsForGeo.fromJson(Map<String, dynamic> json) {
//     return CoiffeuseDetailsForGeo(
//       idTblCoiffeuse: json['idTblCoiffeuse'] ?? 0,
//       idTblUser: json['idTblUser'] ?? 0,
//       uuid: json['uuid'] ?? '',
//       nom: json['nom'] ?? '',
//       prenom: json['prenom'] ?? '',
//       role: json['role'] ?? '',
//       type: json['type'] ?? '',
//       estProprietaire: json['est_proprietaire'] ?? false,
//       nomCommercial: json['nom_commercial'],
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'idTblCoiffeuse': idTblCoiffeuse,
//       'idTblUser': idTblUser,
//       'uuid': uuid,
//       'nom': nom,
//       'prenom': prenom,
//       'role': role,
//       'type': type,
//       'est_proprietaire': estProprietaire,
//       'nom_commercial': nomCommercial,
//     };
//   }
//
//   // Getter pour le nom complet
//   String get nomComplet => '$prenom $nom';
//
//   // Getter pour affichage commercial
//   String get affichageNom => nomCommercial?.isNotEmpty == true ? nomCommercial! : nomComplet;
// }
//
// class SalonDetailsForGeo {
//   final int idTblSalon;
//   final String nom;
//   final String? slogan;
//   final String? logo;
//   final String position;
//   final double? latitude;
//   final double? longitude;
//   final List<int> coiffeuseIds;
//   final List<CoiffeuseDetailsForGeo> coiffeusesDetails;
//   final double distance;
//
//   SalonDetailsForGeo({
//     required this.idTblSalon,
//     required this.nom,
//     this.slogan,
//     this.logo,
//     required this.position,
//     this.latitude,
//     this.longitude,
//     required this.coiffeuseIds,
//     required this.coiffeusesDetails,
//     required this.distance,
//   });
//
//   factory SalonDetailsForGeo.fromJson(Map<String, dynamic> json) {
//     return SalonDetailsForGeo(
//       idTblSalon: json['idTblSalon'] ?? 0,
//       nom: json['nom'] ?? '',
//       slogan: json['slogan'],
//       logo: json['logo'],
//       position: json['position'] ?? '0,0',
//       latitude: json['latitude']?.toDouble(),
//       longitude: json['longitude']?.toDouble(),
//       coiffeuseIds: List<int>.from(json['coiffeuse_ids'] ?? []),
//       coiffeusesDetails: (json['coiffeuses_details'] as List?)
//           ?.map((x) => CoiffeuseDetailsForGeo.fromJson(x))
//           .toList() ?? [],
//       distance: json['distance']?.toDouble() ?? 0.0,
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'idTblSalon': idTblSalon,
//       'nom': nom,
//       'slogan': slogan,
//       'logo': logo,
//       'position': position,
//       'latitude': latitude,
//       'longitude': longitude,
//       'coiffeuse_ids': coiffeuseIds,
//       'coiffeuses_details': coiffeusesDetails.map((x) => x.toJson()).toList(),
//       'distance': distance,
//     };
//   }
//
//   // Getter pour le propriétaire du salon
//   CoiffeuseDetailsForGeo? get proprietaire {
//     try {
//       return coiffeusesDetails.firstWhere((c) => c.estProprietaire);
//     } catch (e) {
//       return null;
//     }
//   }
//
//   // Getter pour le nombre de coiffeuses
//   int get nombreCoiffeuses => coiffeusesDetails.length;
//
//   // Getter pour savoir si le salon a un logo
//   bool get hasLogo => logo != null && logo!.isNotEmpty;
//
//   // Getter pour l'URL complète du logo (si besoin d'ajouter base URL)
//   String? getLogoUrl(String? baseUrl) {
//     if (!hasLogo || baseUrl == null) return logo;
//     return logo!.startsWith('http') ? logo : '$baseUrl$logo';
//   }
//
//   // Getter pour la distance formatée
//   String get distanceFormatee {
//     if (distance < 1) {
//       return '${(distance * 1000).round()} m';
//     }
//     return '${distance.toStringAsFixed(1)} km';
//   }
// }
//
// // models/salons_response.dart
// class SalonsResponse {
//   final String status;
//   final int count;
//   final List<SalonDetailsForGeo> salons;
//
//   SalonsResponse({
//     required this.status,
//     required this.count,
//     required this.salons,
//   });
//
//   factory SalonsResponse.fromJson(Map<String, dynamic> json) {
//     return SalonsResponse(
//       status: json['status'] ?? 'error',
//       count: json['count'] ?? 0,
//       salons: (json['salons'] as List?)
//           ?.map((x) => SalonDetailsForGeo.fromJson(x))
//           .toList() ?? [],
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'status': status,
//       'count': count,
//       'salons': salons.map((x) => x.toJson()).toList(),
//     };
//   }
//
//   // Getter pour vérifier si la requête a réussi
//   bool get isSuccess => status == 'success';
//
//   // Getter pour les salons triés par distance
//   List<SalonDetailsForGeo> get salonsTries {
//     final List<SalonDetailsForGeo> sorted = List.from(salons);
//     sorted.sort((a, b) => a.distance.compareTo(b.distance));
//     return sorted;
//   }
// }