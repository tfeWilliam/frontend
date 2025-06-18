////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//             MODÈLES DE DONNÉES POUR L'UTILISATEUR ACTUEL (CURRENTUSER)       //
//                                                                            //
//  Ce fichier définit le modèle `CurrentUser`, qui est un des modèles les     //
//  plus importants de l'application, car il représente l'utilisateur         //
//  actuellement authentifié. Il agrège les informations personnelles, le      //
//  rôle, et les données professionnelles (si l'utilisateur est une coiffeuse).//
//                                                                            //
//  Ce fichier contient une structure de classes refactorisée :                //
//  - `CurrentUser` : Le modèle principal.                                    //
//  - `CoiffeuseData` et `SalonData` : Les nouveaux modèles canoniques pour les //
//    données professionnelles et de salon.                                   //
//  - `Salon` et `Coiffeuse` : Des classes maintenues pour la compatibilité    //
//    ascendante, qui étendent les nouveaux modèles.                          //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


//##############################################################################
//#                   MODÈLE PRINCIPAL : UTILISATEUR CONNECTÉ                  #
//##############################################################################

/// Représente l'utilisateur actuellement authentifié dans l'application.
/// Ce modèle est polyvalent et peut contenir les données d'un client ou
/// les données professionnelles étendues d'une coiffeuse.
class CurrentUser {
  // --- Informations personnelles de base ---
  /// L'identifiant numérique unique de l'utilisateur.
  final int idTblUser;
  /// L'identifiant universel unique (UUID).
  final String uuid;
  /// Le nom de famille.
  final String nom;
  /// Le prénom.
  final String prenom;
  /// L'adresse e-mail.
  final String email;
  /// Le numéro de téléphone (mutable).
  String? numeroTelephone;
  /// La date de naissance (format String ISO 8601).
  final String? dateNaissance;
  /// Indique si le compte est actif.
  final bool isActive;
  /// L'URL de la photo de profil.
  final String? photoProfil;
  /// L'objet Adresse associé à l'utilisateur.
  final Adresse? adresse;
  /// Le rôle de l'utilisateur (ex: "admin").
  final String? role;
  /// Le sexe de l'utilisateur.
  final String? sexe;
  /// Le type d'utilisateur ("client" ou "coiffeuse").
  final String? type;

  // --- Données professionnelles ---
  /// Contient les données supplémentaires si l'utilisateur est une coiffeuse.
  final CoiffeuseData? extraData;

  /// Constructeur pour créer une instance de `CurrentUser`.
  CurrentUser({
    required this.idTblUser,
    required this.uuid,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.numeroTelephone,
    this.dateNaissance,
    required this.isActive,
    this.photoProfil,
    this.adresse,
    this.role,
    this.sexe,
    this.type,
    this.extraData,
  });

  /// Factory constructor pour créer une instance de `CurrentUser` à partir d'un map JSON.
  /// Gère plusieurs formats de JSON pour assurer la compatibilité.
  factory CurrentUser.fromJson(Map<String, dynamic> json) {
    // Gère les JSON où les données utilisateur sont dans une sous-clé "user".
    final userData = json.containsKey('user') ? json['user'] : json;

    // Gère la récupération des données de coiffeuse depuis l'ancienne clé "coiffeuse"
    // ou la nouvelle clé "extra_data" pour la compatibilité.
    var extraDataJson;
    if (userData['extra_data'] != null) {
      extraDataJson = userData['extra_data'];
    } else if (userData['coiffeuse'] != null) {
      extraDataJson = userData['coiffeuse'];
    }

    return CurrentUser(
      idTblUser: userData['idTblUser'],
      uuid: userData['uuid'],
      nom: userData['nom'],
      prenom: userData['prenom'],
      email: userData['email'],
      numeroTelephone: userData['numero_telephone'],
      dateNaissance: userData['date_naissance'],
      isActive: userData['is_active'] ?? true,
      photoProfil: userData['photo_profil'],
      adresse: userData['adresse'] != null ? Adresse.fromJson(userData['adresse']) : null,
      role: userData['role'],
      sexe: userData['sexe'],
      type: userData['type'],
      // Crée l'objet CoiffeuseData seulement si le type d'utilisateur est "coiffeuse".
      extraData: extraDataJson != null && userData['type']?.toLowerCase() == 'coiffeuse'
          ? CoiffeuseData.fromJson(extraDataJson)
          : null,
    );
  }

  /// Convertit l'instance en un map JSON pour l'envoyer à une API.
  Map<String, dynamic> toJson() {
    return {
      'idTblUser': idTblUser,
      'uuid': uuid,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'numero_telephone': numeroTelephone,
      'date_naissance': dateNaissance,
      'is_active': isActive,
      'photo_profil': photoProfil,
      'adresse': adresse?.toJson(),
      'role': role,
      'sexe': sexe,
      'type': type,
      'extra_data': extraData?.toJson(),
    };
  }

  // --- Méthodes utilitaires ---

  /// Vérifie si l'utilisateur est une coiffeuse.
  bool isCoiffeuseUser() => type?.toLowerCase() == 'coiffeuse' || extraData != null;

  /// Vérifie si l'utilisateur est un client.
  bool isClientUser() => type?.toLowerCase() == 'client';

  /// Vérifie si l'utilisateur a un rôle d'administrateur.
  bool isAdminUser() => role?.toLowerCase() == 'admin';

  /// Getter pour maintenir la compatibilité avec l'ancien code qui utilisait `currentUser.coiffeuse`.
  CoiffeuseData? get coiffeuse => extraData;
}


//##############################################################################
//#                   MODÈLES DE DONNÉES POUR L'ADRESSE                        #
//##############################################################################

/// Représente une adresse physique.
class Adresse {
  String? numero;
  final Rue? rue;

  Adresse({ this.numero, this.rue });

  factory Adresse.fromJson(Map<String, dynamic> json) {
    return Adresse(
      numero: json['numero']?.toString(),
      rue: json['rue'] != null ? Rue.fromJson(json['rue']) : null,
    );
  }

  Map<String, dynamic> toJson() => { 'numero': numero, 'rue': rue?.toJson() };

  /// Retourne une chaîne de caractères formatée de l'adresse complète.
  String getFullAddress() {
    if (rue == null) return numero ?? '';
    List<String> parts = [];
    if (numero != null) parts.add(numero!);
    if (rue!.nomRue != null) parts.add(rue!.nomRue!);
    if (rue!.localite != null) {
      parts.add('${rue!.localite!.codePostal ?? ''} ${rue!.localite!.commune ?? ''}'.trim());
    }
    return parts.join(', ');
  }
}

/// Représente une rue, liant un nom de rue à une localité.
class Rue {
  String? nomRue;
  final Localite? localite;

  Rue({ this.nomRue, this.localite });

  factory Rue.fromJson(Map<String, dynamic> json) {
    return Rue(
      nomRue: json['nom_rue'],
      localite: json['localite'] != null ? Localite.fromJson(json['localite']) : null,
    );
  }

  Map<String, dynamic> toJson() => { 'nom_rue': nomRue, 'localite': localite?.toJson() };
}

/// Représente une localité (commune et code postal).
class Localite {
  String? commune;
  String? codePostal;

  Localite({ this.commune, this.codePostal });

  factory Localite.fromJson(Map<String, dynamic> json) {
    return Localite(
      commune: json['commune'],
      codePostal: json['code_postal'],
    );
  }

  Map<String, dynamic> toJson() => { 'commune': commune, 'code_postal': codePostal };
}


//##############################################################################
//#            NOUVEAUX MODÈLES CANONIQUES (POST-REFACTORING)                  #
//##############################################################################

/// Nouveau modèle de données pour les informations professionnelles d'une coiffeuse.
/// Sépare la logique métier de la coiffeuse de l'entité utilisateur de base.
class CoiffeuseData {
  /// Le nom commercial de la coiffeuse.
  final String? nomCommercial;
  /// Les données du salon principal dont la coiffeuse est propriétaire.
  final SalonData? salonPrincipal;
  /// La liste de toutes les relations de la coiffeuse avec des salons.
  final List<SalonRelation>? tousSalons;

  CoiffeuseData({ this.nomCommercial, this.salonPrincipal, this.tousSalons });

  factory CoiffeuseData.fromJson(Map<String, dynamic> json) {
    // Gère la désérialisation de la liste des salons, compatible avec les clés 'tous_salons' et 'salons'.
    List<SalonRelation>? salonsList;
    var rawSalons = json['tous_salons'] ?? json['salons'];
    if (rawSalons != null && rawSalons is List) {
      salonsList = rawSalons.map((s) => SalonRelation.fromJson(s)).toList();
    }

    var salonPrincipalJson = json['salon_principal'];

    return CoiffeuseData(
      nomCommercial: json['nom_commercial'],
      salonPrincipal: salonPrincipalJson != null ? SalonData.fromJson(salonPrincipalJson) : null,
      tousSalons: salonsList,
    );
  }

  Map<String, dynamic> toJson() => {
    'nom_commercial': nomCommercial,
    'salon_principal': salonPrincipal?.toJson(),
    'tous_salons': tousSalons?.map((s) => s.toJson()).toList(),
  };

  // --- Getters pour compatibilité et utilité ---
  String? get denominationSociale => nomCommercial;
  String? get position => salonPrincipal?.position;
  SalonData? get salon => salonPrincipal;
  SalonData? get salonDirect => salonPrincipal;
  String? get tva => salonPrincipal?.numeroTva;
  String? get numeroTva => salonPrincipal?.numeroTva;
}

/// Représente la relation entre une coiffeuse et un salon.
class SalonRelation {
  final int idTblSalon;
  final String? nomSalon;
  /// `true` si la coiffeuse est propriétaire de ce salon.
  final bool estProprietaire;
  /// Le numéro de TVA du salon.
  final String? numeroTva;

  SalonRelation({
    required this.idTblSalon,
    this.nomSalon,
    required this.estProprietaire,
    this.numeroTva,
  });

  factory SalonRelation.fromJson(Map<String, dynamic> json) {
    return SalonRelation(
      idTblSalon: json['idTblSalon'],
      nomSalon: json['nom_salon'],
      estProprietaire: json['est_proprietaire'] ?? false,
      numeroTva: json['numero_tva'],
    );
  }

  Map<String, dynamic> toJson() => {
    'idTblSalon': idTblSalon,
    'nom_salon': nomSalon,
    'est_proprietaire': estProprietaire,
    'numero_tva': numeroTva,
  };
}

/// Nouveau modèle de données canonique pour un salon.
class SalonData {
  final int idTblSalon;
  final String? nomSalon;
  final String? slogan;
  final String? aPropos;
  final String? logoSalon;
  final String? position;
  final Adresse? adresse;
  /// Le numéro de TVA est maintenant un simple champ texte.
  final String? numeroTva;

  SalonData({
    required this.idTblSalon,
    this.nomSalon, this.slogan, this.aPropos,
    this.logoSalon, this.position, this.adresse, this.numeroTva
  });

  factory SalonData.fromJson(Map<String, dynamic> json) {
    return SalonData(
      idTblSalon: json['idTblSalon'],
      nomSalon: json['nom_salon'],
      slogan: json['slogan'],
      aPropos: json['a_propos'],
      logoSalon: json['logo_salon'],
      position: json['position'],
      adresse: json['adresse'] != null ? Adresse.fromJson(json['adresse']) : null,
      numeroTva: json['numero_tva']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'idTblSalon': idTblSalon, 'nom_salon': nomSalon, 'slogan': slogan,
    'a_propos': aPropos, 'logo_salon': logoSalon, 'position': position,
    'adresse': adresse?.toJson(), 'numero_tva': numeroTva,
  };
}


//##############################################################################
//#                   CLASSES DE COMPATIBILITÉ ASCENDANTE                      #
//##############################################################################

/// Classe de compatibilité pour `Salon`.
/// N'est maintenue que pour assurer que l'ancien code ne casse pas.
/// Le nouveau code doit utiliser `SalonData` directement.
class Salon extends SalonData {
  Salon({
    required int idTblSalon,
    String? nomSalon, String? slogan, String? aPropos,
    String? logoSalon, String? position, Adresse? adresse, String? numeroTva,
  }) : super(
      idTblSalon: idTblSalon, nomSalon: nomSalon, slogan: slogan, aPropos: aPropos,
      logoSalon: logoSalon, position: position, adresse: adresse, numeroTva: numeroTva
  );

  /// Le factory constructor délègue simplement à `SalonData.fromJson` et crée une instance de `Salon`.
  factory Salon.fromJson(Map<String, dynamic> json) {
    var data = SalonData.fromJson(json);
    return Salon(
        idTblSalon: data.idTblSalon, nomSalon: data.nomSalon, slogan: data.slogan,
        aPropos: data.aPropos, logoSalon: data.logoSalon, position: data.position,
        adresse: data.adresse, numeroTva: data.numeroTva
    );
  }
}

/// Classe de compatibilité pour `Coiffeuse`.
/// N'est maintenue que pour assurer que l'ancien code ne casse pas.
/// Le nouveau code doit utiliser `CoiffeuseData` directement.
class Coiffeuse extends CoiffeuseData {
  Coiffeuse({
    String? nomCommercial, SalonData? salonPrincipal, List<SalonRelation>? tousSalons,
  }) : super(
      nomCommercial: nomCommercial, salonPrincipal: salonPrincipal, tousSalons: tousSalons
  );

  /// Le factory constructor délègue simplement à `CoiffeuseData.fromJson` et crée une instance de `Coiffeuse`.
  factory Coiffeuse.fromJson(Map<String, dynamic> json) {
    var data = CoiffeuseData.fromJson(json);
    return Coiffeuse(
      nomCommercial: data.nomCommercial,
      salonPrincipal: data.salonPrincipal,
      tousSalons: data.tousSalons,
    );
  }
}




// class CurrentUser {
//   final int idTblUser;
//   final String uuid;
//   final String nom;
//   final String prenom;
//   final String email;
//   String? numeroTelephone;
//   final String? dateNaissance;
//   final bool isActive;
//   final String? photoProfil;
//   final Adresse? adresse;
//   final String? role;
//   final String? sexe;
//   final String? type;
//   final CoiffeuseData? extraData; // Changé de Coiffeuse à CoiffeuseData
//
//   CurrentUser({
//     required this.idTblUser,
//     required this.uuid,
//     required this.nom,
//     required this.prenom,
//     required this.email,
//     required this.numeroTelephone,
//     this.dateNaissance,
//     required this.isActive,
//     this.photoProfil,
//     this.adresse,
//     this.role,
//     this.sexe,
//     this.type,
//     this.extraData,
//   });
//
//   factory CurrentUser.fromJson(Map<String, dynamic> json) {
//     // Si le JSON contient le champ "user", utilisez-le
//     final userData = json.containsKey('user') ? json['user'] : json;
//
//     // Nouveau traitement pour extraData basé sur la structure backend
//     var extraDataJson;
//     if (userData['extra_data'] != null) {
//       extraDataJson = userData['extra_data'];
//     } else if (userData['coiffeuse'] != null) {
//       // Maintenir la compatibilité avec l'ancien format d'API
//       extraDataJson = userData['coiffeuse'];
//     }
//
//     // Récupérer l'URL de la photo telle quelle, sans modification
//     var photoProfilUrl = userData['photo_profil'];
//
//     return CurrentUser(
//       idTblUser: userData['idTblUser'],
//       uuid: userData['uuid'],
//       nom: userData['nom'],
//       prenom: userData['prenom'],
//       email: userData['email'],
//       numeroTelephone: userData['numero_telephone'],
//       dateNaissance: userData['date_naissance'],
//       isActive: userData['is_active'] ?? true,
//       photoProfil: photoProfilUrl,
//       adresse: userData['adresse'] != null ? Adresse.fromJson(userData['adresse']) : null,
//       role: userData['role'],
//       sexe: userData['sexe'],
//       type: userData['type'],
//       extraData: extraDataJson != null && userData['type']?.toLowerCase() == 'coiffeuse'
//           ? CoiffeuseData.fromJson(extraDataJson)
//           : null,
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'idTblUser': idTblUser,
//       'uuid': uuid,
//       'nom': nom,
//       'prenom': prenom,
//       'email': email,
//       'numero_telephone': numeroTelephone,
//       'date_naissance': dateNaissance,
//       'is_active': isActive,
//       'photo_profil': photoProfil,
//       'adresse': adresse?.toJson(),
//       'role': role,
//       'sexe': sexe,
//       'type': type,
//       'extra_data': extraData?.toJson(),
//     };
//   }
//
//   // Méthodes utilitaires
//   bool isCoiffeuseUser() {
//     return type?.toLowerCase() == 'coiffeuse' || extraData != null;
//   }
//
//   bool isClientUser() {
//     return type?.toLowerCase() == 'client';
//   }
//
//   bool isAdminUser() {
//     return role?.toLowerCase() == 'admin';
//   }
//
//   // Propriété pour maintenir la compatibilité avec l'ancien code
//   CoiffeuseData? get coiffeuse => extraData;
// }
//
// class Adresse {
//   String? numero;
//   final Rue? rue;
//
//   Adresse({
//     this.numero,
//     this.rue,
//   });
//
//   factory Adresse.fromJson(Map<String, dynamic> json) {
//     return Adresse(
//       numero: json['numero']?.toString(),
//       rue: json['rue'] != null ? Rue.fromJson(json['rue']) : null,
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'numero': numero,
//       'rue': rue?.toJson(),
//     };
//   }
//
//   // Pour la compatibilité avec les formats différents d'adresses
//   String getFullAddress() {
//     if (rue == null) return numero ?? '';
//
//     String address = '';
//     if (numero != null) address += '$numero, ';
//     if (rue?.nomRue != null) address += '${rue!.nomRue}';
//     if (rue?.localite?.commune != null) {
//       address += ', ${rue!.localite!.commune}';
//       if (rue?.localite?.codePostal != null) {
//         address += ' ${rue!.localite!.codePostal}';
//       }
//     }
//     return address;
//   }
// }
//
// class Rue {
//   String? nomRue;
//   final Localite? localite;
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
// }
//
// // ⚠️ SUPPRIMÉ - Plus besoin de NumeroTVA car c'est maintenant un champ direct
// // La classe NumeroTVA a été supprimée car elle n'est plus utilisée
//
// // Nouvelle classe qui match avec la structure backend
// class CoiffeuseData {
//   final String? nomCommercial;
//   final SalonData? salonPrincipal;
//   final List<SalonRelation>? tousSalons;
//
//   CoiffeuseData({
//     this.nomCommercial,
//     this.salonPrincipal,
//     this.tousSalons,
//   });
//
//   factory CoiffeuseData.fromJson(Map<String, dynamic> json) {
//     List<SalonRelation>? salonsList;
//
//     // Gérer les deux formats possibles pour les salons
//     if (json['tous_salons'] != null && json['tous_salons'] is List) {
//       salonsList = (json['tous_salons'] as List)
//           .map((salon) => SalonRelation.fromJson(salon))
//           .toList();
//     } else if (json['salons'] != null && json['salons'] is List) {
//       salonsList = (json['salons'] as List)
//           .map((salon) => SalonRelation.fromJson(salon))
//           .toList();
//     }
//
//     // Gérer les deux formats possibles pour salon principal
//     var salonPrincipalJson = json['salon_principal'];
//
//     return CoiffeuseData(
//       nomCommercial: json['nom_commercial'],
//       salonPrincipal: salonPrincipalJson != null ? SalonData.fromJson(salonPrincipalJson) : null,
//       tousSalons: salonsList,
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'nom_commercial': nomCommercial,
//       'salon_principal': salonPrincipal?.toJson(),
//       'tous_salons': tousSalons?.map((salon) => salon.toJson()).toList(),
//     };
//   }
//
//   // Propriétés pour compatibilité avec l'ancien code
//   String? get denominationSociale => nomCommercial;
//   String? get position => salonPrincipal?.position;
//   SalonData? get salon => salonPrincipal;
//   SalonData? get salonDirect => salonPrincipal;
//
//   // ⚠️ MODIFIÉ - La TVA vient maintenant du salon principal
//   String? get tva => salonPrincipal?.numeroTva;
//   String? get numeroTva => salonPrincipal?.numeroTva;
// }
//
// // Mise à jour de SalonRelation pour inclure plus d'informations
// class SalonRelation {
//   final int idTblSalon;
//   final String? nomSalon;
//   final bool estProprietaire;
//   final String? numeroTva; // ✅ Ajouté - TVA maintenant dans le salon
//
//   SalonRelation({
//     required this.idTblSalon,
//     this.nomSalon,
//     required this.estProprietaire,
//     this.numeroTva,
//   });
//
//   factory SalonRelation.fromJson(Map<String, dynamic> json) {
//     return SalonRelation(
//       idTblSalon: json['idTblSalon'],
//       nomSalon: json['nom_salon'],
//       estProprietaire: json['est_proprietaire'] ?? false,
//       numeroTva: json['numero_tva'], // ✅ Maintenant récupéré du salon
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'idTblSalon': idTblSalon,
//       'nom_salon': nomSalon,
//       'est_proprietaire': estProprietaire,
//       'numero_tva': numeroTva,
//     };
//   }
// }
//
// // Révisé pour correspondre à SalonData dans le backend
// class SalonData {
//   final int idTblSalon;
//   final String? nomSalon;
//   final String? slogan;
//   final String? aPropos;
//   final String? logoSalon;
//   final String? position;
//   final Adresse? adresse;
//   final String? numeroTva; // ✅ Simplifié - maintenant directement une String
//
//   SalonData({
//     required this.idTblSalon,
//     this.nomSalon,
//     this.slogan,
//     this.aPropos,
//     this.logoSalon,
//     this.position,
//     this.adresse,
//     this.numeroTva,
//   });
//
//   factory SalonData.fromJson(Map<String, dynamic> json) {
//     // ✅ SIMPLIFIÉ - Plus besoin de gérer les objets complexes pour TVA
//     String? tvaParsed = json['numero_tva']?.toString();
//
//     // Récupérer l'URL du logo telle quelle, sans modification
//     var logoUrl = json['logo_salon'];
//
//     return SalonData(
//       idTblSalon: json['idTblSalon'],
//       nomSalon: json['nom_salon'],
//       slogan: json['slogan'],
//       aPropos: json['a_propos'],
//       logoSalon: logoUrl,
//       position: json['position'],
//       adresse: json['adresse'] != null ? Adresse.fromJson(json['adresse']) : null,
//       numeroTva: tvaParsed,
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'idTblSalon': idTblSalon,
//       'nom_salon': nomSalon,
//       'slogan': slogan,
//       'a_propos': aPropos,
//       'logo_salon': logoSalon,
//       'position': position,
//       'adresse': adresse?.toJson(),
//       'numero_tva': numeroTva,
//     };
//   }
// }
//
// // Maintenir la compatibilité avec l'ancien format de Salon
// class Salon extends SalonData {
//   Salon({
//     required int idTblSalon,
//     String? nomSalon,
//     String? slogan,
//     String? aPropos,
//     String? logoSalon,
//     String? position,
//     Adresse? adresse,
//     String? numeroTva,
//   }) : super(
//     idTblSalon: idTblSalon,
//     nomSalon: nomSalon,
//     slogan: slogan,
//     aPropos: aPropos,
//     logoSalon: logoSalon,
//     position: position,
//     adresse: adresse,
//     numeroTva: numeroTva,
//   );
//
//   factory Salon.fromJson(Map<String, dynamic> json) {
//     return Salon(
//       idTblSalon: json['idTblSalon'],
//       nomSalon: json['nom_salon'],
//       slogan: json['slogan'],
//       aPropos: json['a_propos'],
//       logoSalon: json['logo_salon'],
//       position: json['position'],
//       adresse: json['adresse'] != null ? Adresse.fromJson(json['adresse']) : null,
//       numeroTva: json['numero_tva']?.toString(), // ✅ Simplifié
//     );
//   }
// }
//
// // Maintenir la compatibilité avec l'ancien format de Coiffeuse
// class Coiffeuse extends CoiffeuseData {
//   Coiffeuse({
//     String? nomCommercial,
//     SalonData? salonPrincipal,
//     List<SalonRelation>? tousSalons,
//   }) : super(
//     nomCommercial: nomCommercial,
//     salonPrincipal: salonPrincipal,
//     tousSalons: tousSalons,
//   );
//
//   factory Coiffeuse.fromJson(Map<String, dynamic> json) {
//     var data = CoiffeuseData.fromJson(json);
//     return Coiffeuse(
//       nomCommercial: data.nomCommercial,
//       salonPrincipal: data.salonPrincipal,
//       tousSalons: data.tousSalons,
//     );
//   }
// }
