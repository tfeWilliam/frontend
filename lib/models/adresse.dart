////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                MODÈLES DE DONNÉES POUR LES ADRESSES PHYSIQUES               //
//                                                                            //
//  Ce fichier définit les classes nécessaires pour représenter une adresse   //
//  physique de manière structurée et complète. Il est composé de trois        //
//  classes imbriquées :                                                      //
//                                                                            //
//  - Localite : Représente la localité (commune et code postal).             //
//  - Rue : Représente la rue, qui est liée à une localité.                   //
//  - Adresse : Le modèle principal qui combine un numéro, une rue, et des    //
//    coordonnées géographiques, avec des méthodes utilitaires pour la        //
//    validation, le formatage et les calculs de distance.                    //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

import 'dart:math' as math; // Import nécessaire pour les fonctions mathématiques.

//##############################################################################
//#                            MODÈLE ADRESSE PRINCIPAL                          #
//##############################################################################

/// Représente une adresse physique complète, incluant les détails de la rue,
/// la localité, et les coordonnées géographiques.
class Adresse {
  /// Le numéro dans la rue.
  int? numero;
  /// La boîte postale, si applicable.
  String? boitePostale;
  /// L'objet Rue contenant le nom de la rue et la localité.
  Rue? rue;
  /// La coordonnée de latitude.
  double? latitude;
  /// La coordonnée de longitude.
  double? longitude;
  /// Indique si l'adresse a été validée par un service de géocodage.
  bool? isValidated;
  /// La date de la dernière validation.
  DateTime? validationDate;

  /// Constructeur principal pour créer une instance d'Adresse.
  Adresse({
    this.numero,
    this.boitePostale,
    this.rue,
    this.latitude,
    this.longitude,
    this.isValidated,
    this.validationDate,
  });

  /// Factory constructor pour créer une instance d'Adresse à partir d'un map JSON.
  /// Utile pour la désérialisation des réponses d'API.
  factory Adresse.fromJson(Map<String, dynamic> json) {
    return Adresse(
      numero: json['numero'],
      boitePostale: json['boite_postale'],
      rue: json['rue'] != null ? Rue.fromJson(json['rue']) : null,
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      isValidated: json['is_validated'],
      validationDate: json['validation_date'] != null
          ? DateTime.parse(json['validation_date'])
          : null,
    );
  }

  /// Convertit l'instance d'Adresse en un map JSON.
  /// Utile pour la sérialisation des données à envoyer à une API.
  Map<String, dynamic> toJson() {
    return {
      'numero': numero,
      'boite_postale': boitePostale,
      'rue': rue?.toJson(),
      'latitude': latitude,
      'longitude': longitude,
      'is_validated': isValidated,
      'validation_date': validationDate?.toIso8601String(),
    };
  }

  /// Retourne l'adresse complète formatée de manière lisible.
  String get adresseComplete {
    List<String> parts = [];

    if (numero != null) parts.add(numero.toString());
    if (boitePostale != null && boitePostale!.isNotEmpty) {
      parts.add("Boîte ${boitePostale!}");
    }
    if (rue?.nomRue != null) parts.add(rue!.nomRue!);
    if (rue?.localite?.codePostal != null && rue?.localite?.commune != null) {
      parts.add('${rue!.localite!.codePostal!} ${rue!.localite!.commune!}');
    }

    return parts.join(', ');
  }

  /// Retourne une version simplifiée de l'adresse (numéro et rue).
  String get adresseSimple {
    List<String> parts = [];
    if (numero != null) parts.add(numero.toString());
    if (rue?.nomRue != null) parts.add(rue!.nomRue!);
    return parts.join(' ');
  }

  /// Retourne la localité complète (ex: "1000 Bruxelles").
  String get localiteComplete {
    if (rue?.localite?.codePostal != null && rue?.localite?.commune != null) {
      return '${rue!.localite!.codePostal!} ${rue!.localite!.commune!}';
    }
    return '';
  }

  /// Vérifie si l'adresse possède des coordonnées géographiques valides.
  bool get hasCoordinates => latitude != null && longitude != null;

  /// Vérifie si les champs essentiels de l'adresse sont remplis.
  bool get isComplete {
    return numero != null &&
        rue?.nomRue != null && rue!.nomRue!.isNotEmpty &&
        rue?.localite?.commune != null && rue!.localite!.commune!.isNotEmpty &&
        rue?.localite?.codePostal != null && rue!.localite!.codePostal!.isNotEmpty;
  }

  /// Vérifie si l'adresse a été validée il y a moins de 30 jours.
  bool get isRecentlyValidated {
    if (isValidated != true || validationDate == null) return false;
    final now = DateTime.now();
    final difference = now.difference(validationDate!);
    return difference.inDays <= 30;
  }

  /// Calcule la distance en mètres entre cette adresse et une autre en utilisant
  /// la formule de Haversine, qui tient compte de la courbure de la Terre.
  double? distanceTo(Adresse other) {
    if (!hasCoordinates || !other.hasCoordinates) return null;

    const double earthRadius = 6371000; // Rayon de la Terre en mètres

    // Conversion des degrés en radians
    double lat1Rad = latitude! * (math.pi / 180);
    double lat2Rad = other.latitude! * (math.pi / 180);
    double deltaLatRad = (other.latitude! - latitude!) * (math.pi / 180);
    double deltaLngRad = (other.longitude! - longitude!) * (math.pi / 180);

    // Application de la formule de Haversine
    double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
            math.sin(deltaLngRad / 2) * math.sin(deltaLngRad / 2);
    double c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }

  /// Crée une copie de cette instance d'Adresse, en remplaçant les champs fournis.
  /// Utile pour la gestion d'état immuable.
  Adresse copyWith({
    int? numero,
    String? boitePostale,
    Rue? rue,
    double? latitude,
    double? longitude,
    bool? isValidated,
    DateTime? validationDate,
  }) {
    return Adresse(
      numero: numero ?? this.numero,
      boitePostale: boitePostale ?? this.boitePostale,
      rue: rue ?? this.rue,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isValidated: isValidated ?? this.isValidated,
      validationDate: validationDate ?? this.validationDate,
    );
  }

  /// Met à jour l'état de l'adresse après une validation par géocodage réussie.
  void markAsValidated(double lat, double lng) {
    latitude = lat;
    longitude = lng;
    isValidated = true;
    validationDate = DateTime.now();
  }

  /// Représentation textuelle par défaut de l'objet (adresse complète).
  @override
  String toString() {
    return adresseComplete;
  }

  /// Surcharge de l'opérateur d'égalité pour comparer deux instances d'Adresse
  /// sur la base de leurs valeurs.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Adresse &&
        other.numero == numero &&
        other.boitePostale == boitePostale &&
        other.rue == rue &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  /// Surcharge du hashCode pour assurer la cohérence avec l'opérateur d'égalité.
  @override
  int get hashCode {
    return numero.hashCode ^
    boitePostale.hashCode ^
    rue.hashCode ^
    latitude.hashCode ^
    longitude.hashCode;
  }
}

//##############################################################################
//#                               MODÈLE RUE                                   #
//##############################################################################

/// Représente une rue, contenant son nom et sa localité.
class Rue {
  /// Le nom de la rue.
  String? nomRue;
  /// L'objet Localite associé à cette rue.
  Localite? localite;

  Rue({this.nomRue, this.localite});

  factory Rue.fromJson(Map<String, dynamic> json) {
    return Rue(
      nomRue: json['nom_rue'],
      localite: json['localite'] != null ? Localite.fromJson(json['localite']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom_rue': nomRue,
      'localite': localite?.toJson(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Rue &&
        other.nomRue == nomRue &&
        other.localite == localite;
  }

  @override
  int get hashCode => nomRue.hashCode ^ localite.hashCode;
}

//##############################################################################
//#                              MODÈLE LOCALITE                               #
//##############################################################################

/// Représente une localité, définie par une commune et un code postal.
class Localite {
  /// Le nom de la commune.
  String? commune;
  /// Le code postal.
  String? codePostal;

  Localite({this.commune, this.codePostal});

  factory Localite.fromJson(Map<String, dynamic> json) {
    return Localite(
      commune: json['commune'],
      codePostal: json['code_postal'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'commune': commune,
      'code_postal': codePostal,
    };
  }

  /// Vérifie si le code postal a un format belge valide (4 chiffres).
  bool get isValidBelgianPostcode {
    if (codePostal == null) return false;
    return RegExp(r'^\d{4}$').hasMatch(codePostal!);
  }

  @override
  String toString() {
    return '${codePostal ?? ''} ${commune ?? ''}'.trim();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Localite &&
        other.commune == commune &&
        other.codePostal == codePostal;
  }

  @override
  int get hashCode => commune.hashCode ^ codePostal.hashCode;
}

// // lib/models/adresse.dart
//
// import 'dart:math' as math; // ✅ Import nécessaire pour les fonctions mathématiques
//
// class Adresse {
//   int? numero;
//   String? boitePostale;
//   Rue? rue;
//   double? latitude;
//   double? longitude;
//   bool? isValidated;
//   DateTime? validationDate;
//
//   Adresse({
//     this.numero,
//     this.boitePostale,
//     this.rue,
//     this.latitude,
//     this.longitude,
//     this.isValidated,
//     this.validationDate,
//   });
//
//   factory Adresse.fromJson(Map<String, dynamic> json) {
//     return Adresse(
//       numero: json['numero'],
//       boitePostale: json['boite_postale'],
//       rue: json['rue'] != null ? Rue.fromJson(json['rue']) : null,
//       latitude: json['latitude']?.toDouble(),
//       longitude: json['longitude']?.toDouble(),
//       isValidated: json['is_validated'],
//       validationDate: json['validation_date'] != null
//           ? DateTime.parse(json['validation_date'])
//           : null,
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'numero': numero,
//       'boite_postale': boitePostale,
//       'rue': rue?.toJson(),
//       'latitude': latitude,
//       'longitude': longitude,
//       'is_validated': isValidated,
//       'validation_date': validationDate?.toIso8601String(),
//     };
//   }
//
//   /// Méthode pour obtenir l'adresse complète formatée
//   String get adresseComplete {
//     List<String> parts = [];
//
//     if (numero != null) parts.add(numero.toString());
//     if (boitePostale != null && boitePostale!.isNotEmpty) {
//       parts.add("Boîte ${boitePostale!}");
//     }
//     if (rue?.nomRue != null) parts.add(rue!.nomRue!);
//     if (rue?.localite?.codePostal != null && rue?.localite?.commune != null) {
//       parts.add('${rue!.localite!.codePostal!} ${rue!.localite!.commune!}');
//     }
//
//     return parts.join(', ');
//   }
//
//   /// Adresse courte (sans boîte postale et coordonnées)
//   String get adresseSimple {
//     List<String> parts = [];
//
//     if (numero != null) parts.add(numero.toString());
//     if (rue?.nomRue != null) parts.add(rue!.nomRue!);
//
//     return parts.join(' ');
//   }
//
//   /// Localité complète (code postal + commune)
//   String get localiteComplete {
//     if (rue?.localite?.codePostal != null && rue?.localite?.commune != null) {
//       return '${rue!.localite!.codePostal!} ${rue!.localite!.commune!}';
//     }
//     return '';
//   }
//
//   /// Vérifier si l'adresse a des coordonnées GPS
//   bool get hasCoordinates => latitude != null && longitude != null;
//
//   /// Vérifier si l'adresse est complète
//   bool get isComplete {
//     return numero != null &&
//         rue?.nomRue != null && rue!.nomRue!.isNotEmpty &&
//         rue?.localite?.commune != null && rue!.localite!.commune!.isNotEmpty &&
//         rue?.localite?.codePostal != null && rue!.localite!.codePostal!.isNotEmpty;
//   }
//
//   /// Vérifier si l'adresse est validée et récente (moins de 30 jours)
//   bool get isRecentlyValidated {
//     // ✅ Correction: éviter l'exception si isValidated est null
//     if (isValidated != true || validationDate == null) return false;
//     final now = DateTime.now();
//     final difference = now.difference(validationDate!);
//     return difference.inDays <= 30;
//   }
//
//   /// Distance entre cette adresse et une autre (en mètres)
//   double? distanceTo(Adresse other) {
//     if (!hasCoordinates || !other.hasCoordinates) return null;
//
//     // ✅ Formule de Haversine corrigée avec import dart:math
//     const double earthRadius = 6371000; // Rayon de la Terre en mètres
//
//     double lat1Rad = latitude! * (math.pi / 180);
//     double lat2Rad = other.latitude! * (math.pi / 180);
//     double deltaLatRad = (other.latitude! - latitude!) * (math.pi / 180);
//     double deltaLngRad = (other.longitude! - longitude!) * (math.pi / 180);
//
//     double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
//         math.cos(lat1Rad) * math.cos(lat2Rad) *
//             math.sin(deltaLngRad / 2) * math.sin(deltaLngRad / 2);
//     double c = 2 * math.asin(math.sqrt(a));
//
//     return earthRadius * c;
//   }
//
//   /// Copier l'adresse avec de nouvelles valeurs
//   Adresse copyWith({
//     int? numero,
//     String? boitePostale,
//     Rue? rue,
//     double? latitude,
//     double? longitude,
//     bool? isValidated,
//     DateTime? validationDate,
//   }) {
//     return Adresse(
//       numero: numero ?? this.numero,
//       boitePostale: boitePostale ?? this.boitePostale,
//       rue: rue ?? this.rue,
//       latitude: latitude ?? this.latitude,
//       longitude: longitude ?? this.longitude,
//       isValidated: isValidated ?? this.isValidated,
//       validationDate: validationDate ?? this.validationDate,
//     );
//   }
//
//   /// Marquer l'adresse comme validée avec coordonnées
//   void markAsValidated(double lat, double lng) {
//     latitude = lat;
//     longitude = lng;
//     isValidated = true;
//     validationDate = DateTime.now();
//   }
//
//   @override
//   String toString() {
//     return adresseComplete;
//   }
//
//   @override
//   bool operator ==(Object other) {
//     if (identical(this, other)) return true;
//     return other is Adresse &&
//         other.numero == numero &&
//         other.boitePostale == boitePostale &&
//         other.rue == rue &&
//         other.latitude == latitude &&
//         other.longitude == longitude;
//   }
//
//   @override
//   int get hashCode {
//     return numero.hashCode ^
//     boitePostale.hashCode ^
//     rue.hashCode ^
//     latitude.hashCode ^
//     longitude.hashCode;
//   }
// }
//
// class Rue {
//   String? nomRue;
//   Localite? localite;
//
//   Rue({
//     this.nomRue,
//     this.localite,
//   });
//
//   factory Rue.fromJson(Map<String, dynamic> json) {
//     return Rue(
//       nomRue: json['nom_rue'],
//       localite: json['localite'] != null ? Localite.fromJson(json['localite']) : null,
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'nom_rue': nomRue,
//       'localite': localite?.toJson(),
//     };
//   }
//
//   @override
//   bool operator ==(Object other) {
//     if (identical(this, other)) return true;
//     return other is Rue &&
//         other.nomRue == nomRue &&
//         other.localite == localite;
//   }
//
//   @override
//   int get hashCode => nomRue.hashCode ^ localite.hashCode;
// }
//
// class Localite {
//   String? commune;
//   String? codePostal;
//
//   Localite({
//     this.commune,
//     this.codePostal,
//   });
//
//   factory Localite.fromJson(Map<String, dynamic> json) {
//     return Localite(
//       commune: json['commune'],
//       codePostal: json['code_postal'],
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'commune': commune,
//       'code_postal': codePostal,
//     };
//   }
//
//   /// Vérifier si le code postal est valide pour la Belgique
//   bool get isValidBelgianPostcode {
//     if (codePostal == null) return false;
//     return RegExp(r'^\d{4}$').hasMatch(codePostal!);
//   }
//
//   @override
//   String toString() {
//     return '${codePostal ?? ''} ${commune ?? ''}'.trim();
//   }
//
//   @override
//   bool operator ==(Object other) {
//     if (identical(this, other)) return true;
//     return other is Localite &&
//         other.commune == commune &&
//         other.codePostal == codePostal;
//   }
//
//   @override
//   int get hashCode => commune.hashCode ^ codePostal.hashCode;
// }