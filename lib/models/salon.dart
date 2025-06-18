/****************************************************************************************
 *
 * MODÈLES DE DONNÉES : SALON ET RÉPONSES API ASSOCIÉES
 *
 * OBJECTIF :
 * Ce fichier définit les modèles de données nécessaires pour manipuler les informations
 * relatives aux salons de coiffure. Il inclut le modèle principal `Salon`, ainsi que
 * des modèles pour les réponses spécifiques de l'API.
 *
 * STRUCTURE DES CLASSES :
 * - Salon : Le modèle de données central représentant un salon, avec ses détails,
 * sa géolocalisation et les informations sur les coiffeuses qui y travaillent.
 *
 * - CoiffeuseDetails : Un sous-modèle pour représenter les informations détaillées
 * d'une coiffeuse spécifique au sein d'un salon.
 *
 * - SalonsProchesResponse : Modèle "enveloppe" pour la réponse de l'API qui retourne
 * une liste de salons à proximité.
 *
 * - SalonDetailsResponse : Modèle "enveloppe" pour la réponse de l'API qui retourne
 * les détails complets d'un seul salon.
 *
 *****************************************************************************************/

/// Modèle de données central représentant un salon de coiffure.
class Salon {
  /// L'identifiant unique du salon dans la base de données.
  final int idSalon;
  /// Le nom commercial du salon.
  final String nomSalon;
  /// Le slogan ou la phrase d'accroche du salon (optionnel).
  final String? slogan;
  /// L'URL du logo du salon (optionnel).
  final String? logo;
  /// L'identifiant de la coiffeuse propriétaire ou principale.
  final int coiffeuseId;

  // --- Propriétés pour la géolocalisation et la distance ---
  /// L'adresse textuelle du salon (optionnel).
  final String? position;
  /// La coordonnée de latitude du salon (optionnelle).
  final double? latitude;
  /// La coordonnée de longitude du salon (optionnelle).
  final double? longitude;
  /// La distance calculée entre l'utilisateur et le salon (optionnelle).
  final double? distance;

  // --- Propriétés pour les coiffeuses associées ---
  /// Une liste des identifiants de toutes les coiffeuses travaillant dans le salon.
  final List<int>? coiffeuseIds;
  /// Une liste d'objets détaillés pour chaque coiffeuse du salon.
  final List<CoiffeuseDetails>? coiffeusesDetails;

  /// Constructeur pour créer une instance de Salon.
  Salon({
    required this.idSalon,
    required this.nomSalon,
    this.slogan,
    this.logo,
    required this.coiffeuseId,
    this.position,
    this.latitude,
    this.longitude,
    this.distance,
    this.coiffeuseIds,
    this.coiffeusesDetails,
  });

  /// Construit une instance de [Salon] à partir d'une map JSON.
  factory Salon.fromJson(Map<String, dynamic> json) {
    // Gère la conversion de la liste des IDs de coiffeuses si elle existe.
    List<int>? coiffeuseIds;
    if (json['coiffeuse_ids'] != null) {
      coiffeuseIds = List<int>.from(json['coiffeuse_ids']);
    }

    // Gère la conversion de la liste détaillée des coiffeuses si elle existe.
    List<CoiffeuseDetails>? coiffeusesDetails;
    if (json['coiffeuses_details'] != null) {
      coiffeusesDetails = (json['coiffeuses_details'] as List)
          .map((coiffeuseJson) => CoiffeuseDetails.fromJson(coiffeuseJson))
          .toList();
    }

    return Salon(
      idSalon: json['idTblSalon'],
      // Logique de fallback pour gérer plusieurs noms de clés possibles pour le nom du salon.
      nomSalon: json['nom'] ?? json['nomSalon'] ?? "Salon sans nom",
      slogan: json['slogan'],
      // Logique de fallback pour le logo.
      logo: json['logo'] ?? json['logo_salon'],
      coiffeuseId: json['coiffeuse'] ?? 0,
      position: json['position'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      distance: json['distance']?.toDouble(),
      coiffeuseIds: coiffeuseIds,
      coiffeusesDetails: coiffeusesDetails,
    );
  }

  /// Convertit l'objet [Salon] en une map JSON, prête à être envoyée à une API.
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'idTblSalon': idSalon,
      'nom': nomSalon, // Assure la compatibilité avec les nouvelles versions de l'API.
      'slogan': slogan,
      'logo': logo,   // Assure la compatibilité avec les nouvelles versions de l'API.
      'coiffeuse': coiffeuseId,
    };

    // Ajoute les propriétés de géolocalisation et de coiffeuses uniquement si elles ne sont pas nulles.
    if (position != null) data['position'] = position;
    if (latitude != null) data['latitude'] = latitude;
    if (longitude != null) data['longitude'] = longitude;
    if (distance != null) data['distance'] = distance;
    if (coiffeuseIds != null) data['coiffeuse_ids'] = coiffeuseIds;
    if (coiffeusesDetails != null) {
      data['coiffeuses_details'] = coiffeusesDetails!.map((c) => c.toJson()).toList();
    }

    return data;
  }
}

/// Sous-modèle pour les détails d'une coiffeuse associée à un salon.
class CoiffeuseDetails {
  /// L'identifiant unique de la coiffeuse.
  final int idTblCoiffeuse;
  /// Le nom de famille de la coiffeuse.
  final String nom;
  /// Le prénom de la coiffeuse.
  final String prenom;
  /// L'URL de la photo de profil de la coiffeuse (optionnel).
  final String? photoProfilUrl;
  /// Booléen indiquant si la coiffeuse est la propriétaire du salon.
  final bool estProprietaire;
  /// Le nom commercial de la coiffeuse (si différent de son nom propre).
  final String? nomCommercial;

  /// Constructeur pour créer une instance de CoiffeuseDetails.
  CoiffeuseDetails({
    required this.idTblCoiffeuse,
    required this.nom,
    required this.prenom,
    this.photoProfilUrl,
    required this.estProprietaire,
    this.nomCommercial,
  });

  /// Construit une instance de [CoiffeuseDetails] à partir d'une map JSON.
  factory CoiffeuseDetails.fromJson(Map<String, dynamic> json) {
    return CoiffeuseDetails(
      idTblCoiffeuse: json['idTblCoiffeuse'],
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      photoProfilUrl: json['photo_profil'],
      estProprietaire: json['est_proprietaire'] ?? false,
      nomCommercial: json['nom_commercial'],
    );
  }

  /// Convertit l'objet [CoiffeuseDetails] en une map JSON.
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'idTblCoiffeuse': idTblCoiffeuse,
      'nom': nom,
      'prenom': prenom,
      'est_proprietaire': estProprietaire,
    };

    // N'ajoute les champs optionnels que s'ils ont une valeur.
    if (photoProfilUrl != null) data['photo_profil'] = photoProfilUrl;
    if (nomCommercial != null) data['nom_commercial'] = nomCommercial;

    return data;
  }
}

/// Modèle "enveloppe" pour la réponse de l'API listant les salons proches.
class SalonsProchesResponse {
  /// Le statut de la réponse de l'API (ex: "success").
  final String status;
  /// Le nombre de salons retournés dans la liste.
  final int count;
  /// La liste des objets [Salon] à proximité.
  final List<Salon> salons;

  /// Constructeur pour créer une instance de SalonsProchesResponse.
  SalonsProchesResponse({
    required this.status,
    required this.count,
    required this.salons,
  });

  /// Construit une instance de [SalonsProchesResponse] à partir d'une map JSON.
  factory SalonsProchesResponse.fromJson(Map<String, dynamic> json) {
    List<Salon> salons = [];
    if (json['salons'] != null) {
      salons = (json['salons'] as List)
          .map((salonJson) => Salon.fromJson(salonJson))
          .toList();
    }

    return SalonsProchesResponse(
      status: json['status'] ?? '',
      count: json['count'] ?? 0,
      salons: salons,
    );
  }
}

/// Modèle "enveloppe" pour la réponse de l'API retournant les détails d'un salon unique.
class SalonDetailsResponse {
  /// Le statut de la réponse de l'API (ex: "success").
  final String status;
  /// L'objet [Salon] contenant les détails complets.
  final Salon salon;

  /// Constructeur pour créer une instance de SalonDetailsResponse.
  SalonDetailsResponse({
    required this.status,
    required this.salon,
  });

  /// Construit une instance de [SalonDetailsResponse] à partir d'une map JSON.
  factory SalonDetailsResponse.fromJson(Map<String, dynamic> json) {
    return SalonDetailsResponse(
      status: json['status'] ?? '',
      salon: Salon.fromJson(json['salon']),
    );
  }
}








// class Salon {
//   final int idSalon;
//   final String nomSalon;
//   final String? slogan;
//   final String? logo;
//   final int coiffeuseId;
//
//   // Propriétés pour la géolocalisation
//   final String? position;
//   final double? latitude;
//   final double? longitude;
//   final double? distance;
//   final List<int>? coiffeuseIds;
//   final List<CoiffeuseDetails>? coiffeusesDetails;
//
//   Salon({
//     required this.idSalon,
//     required this.nomSalon,
//     this.slogan,
//     this.logo,
//     required this.coiffeuseId,
//     this.position,
//     this.latitude,
//     this.longitude,
//     this.distance,
//     this.coiffeuseIds,
//     this.coiffeusesDetails,
//   });
//
//   /// **🟢 Convertir JSON vers `Salon`**
//   factory Salon.fromJson(Map<String, dynamic> json) {
//     // Convertir la liste des IDs de coiffeuses si elle existe
//     List<int>? coiffeuseIds;
//     if (json['coiffeuse_ids'] != null) {
//       coiffeuseIds = List<int>.from(json['coiffeuse_ids']);
//     }
//
//     // Convertir la liste détaillée des coiffeuses si elle existe
//     List<CoiffeuseDetails>? coiffeusesDetails;
//     if (json['coiffeuses_details'] != null) {
//       coiffeusesDetails = (json['coiffeuses_details'] as List)
//           .map((coiffeuseJson) => CoiffeuseDetails.fromJson(coiffeuseJson))
//           .toList();
//     }
//
//     return Salon(
//       idSalon: json['idTblSalon'],
//       nomSalon: json['nom'] ?? json['nomSalon'] ?? "Salon sans nom",
//       slogan: json['slogan'],
//       logo: json['logo'] ?? json['logo_salon'],
//       coiffeuseId: json['coiffeuse'] ?? 0,
//       position: json['position'],
//       latitude: json['latitude']?.toDouble(),
//       longitude: json['longitude']?.toDouble(),
//       distance: json['distance']?.toDouble(),
//       coiffeuseIds: coiffeuseIds,
//       coiffeusesDetails: coiffeusesDetails,
//     );
//   }
//
//   /// **🟢 Convertir `Salon` en JSON**
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = {
//       'idTblSalon': idSalon,
//       'nom': nomSalon,          // Pour le nouveau sérialiseur backend
//       'slogan': slogan,
//       'logo': logo,             // Pour le nouveau sérialiseur backend
//       'coiffeuse': coiffeuseId,
//     };
//
//     // Ajouter les propriétés de géolocalisation si elles existent
//     if (position != null) data['position'] = position;
//     if (latitude != null) data['latitude'] = latitude;
//     if (longitude != null) data['longitude'] = longitude;
//     if (distance != null) data['distance'] = distance;
//     if (coiffeuseIds != null) data['coiffeuse_ids'] = coiffeuseIds;
//     if (coiffeusesDetails != null) {
//       data['coiffeuses_details'] = coiffeusesDetails!.map((c) => c.toJson()).toList();
//     }
//
//     return data;
//   }
// }
//
// /// Modèle pour les détails d'une coiffeuse associée à un salon
// class CoiffeuseDetails {
//   final int idTblCoiffeuse;
//   final String nom;
//   final String prenom;
//   final String? photoProfilUrl;
//   final bool estProprietaire;
//   final String? nomCommercial;
//
//   CoiffeuseDetails({
//     required this.idTblCoiffeuse,
//     required this.nom,
//     required this.prenom,
//     this.photoProfilUrl,
//     required this.estProprietaire,
//     this.nomCommercial,
//   });
//
//   factory CoiffeuseDetails.fromJson(Map<String, dynamic> json) {
//     return CoiffeuseDetails(
//       idTblCoiffeuse: json['idTblCoiffeuse'],
//       nom: json['nom'] ?? '',
//       prenom: json['prenom'] ?? '',
//       photoProfilUrl: json['photo_profil'],
//       estProprietaire: json['est_proprietaire'] ?? false,
//       nomCommercial: json['nom_commercial'],
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = {
//       'idTblCoiffeuse': idTblCoiffeuse,
//       'nom': nom,
//       'prenom': prenom,
//       'est_proprietaire': estProprietaire,
//     };
//
//     if (photoProfilUrl != null) data['photo_profil'] = photoProfilUrl;
//     if (nomCommercial != null) data['nom_commercial'] = nomCommercial;
//
//     return data;
//   }
// }
//
// /// Modèle pour la réponse de l'API salons-proches
// class SalonsProchesResponse {
//   final String status;
//   final int count;
//   final List<Salon> salons;
//
//   SalonsProchesResponse({
//     required this.status,
//     required this.count,
//     required this.salons,
//   });
//
//   factory SalonsProchesResponse.fromJson(Map<String, dynamic> json) {
//     List<Salon> salons = [];
//     if (json['salons'] != null) {
//       salons = (json['salons'] as List)
//           .map((salonJson) => Salon.fromJson(salonJson))
//           .toList();
//     }
//
//     return SalonsProchesResponse(
//       status: json['status'] ?? '',
//       count: json['count'] ?? 0,
//       salons: salons,
//     );
//   }
// }
//
// /// Modèle pour la réponse de l'API salon/<id>
// class SalonDetailsResponse {
//   final String status;
//   final Salon salon;
//
//   SalonDetailsResponse({
//     required this.status,
//     required this.salon,
//   });
//
//   factory SalonDetailsResponse.fromJson(Map<String, dynamic> json) {
//     return SalonDetailsResponse(
//       status: json['status'] ?? '',
//       salon: Salon.fromJson(json['salon']),
//     );
//   }
// }
