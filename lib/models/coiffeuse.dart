////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                MODÈLE DE DONNÉES POUR UN UTILISATEUR COIFFEUSE               //
//                                                                            //
//  Ce fichier définit le modèle `Coiffeuse`, qui représente un utilisateur   //
//  de type "Coiffeuse" (professionnel) dans l'application. Cette classe      //
//  "aplatit" une structure de données JSON imbriquée provenant de l'API pour  //
//  simplifier la manipulation des données de la coiffeuse, de son adresse,   //
//  et de son salon principal dans le code Dart.                              //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


class Coiffeuse {
  //region Propriétés du Modèle

  // --- Informations spécifiques à la Coiffeuse ---

  /// L'identifiant de la table `TblUser` (clé étrangère).
  int idTblUser;
  /// L'identifiant de la table `TblCoiffeuse`.
  int id;
  /// Le nom commercial ou la dénomination sociale de la coiffeuse.
  String? nomCommercial;
  /// Les coordonnées géographiques sous forme de chaîne "latitude,longitude".
  String? position;

  // --- Informations de base de l'utilisateur (imbriquées dans le JSON) ---

  /// L'identifiant universel unique (UUID) de l'utilisateur.
  String uuid;
  /// Le nom de famille.
  String nom;
  /// Le prénom.
  String prenom;
  /// L'adresse e-mail.
  String email;
  /// Le numéro de téléphone.
  String numeroTelephone;
  /// La date de naissance (format String ISO 8601).
  String? dateNaissance;
  /// Le sexe.
  String sexe;
  /// Indique si le compte est actif.
  bool isActive;
  /// L'URL de la photo de profil.
  String? photoProfil;

  // --- Informations sur l'adresse (aplaties depuis le JSON) ---

  /// Le numéro dans la rue.
  String? numero;
  /// Le nom de la rue.
  String? nomRue;
  /// La commune de l'adresse.
  String? commune;
  /// Le code postal de l'adresse.
  String? codePostal;

  // --- Informations sur le salon principal (aplaties depuis le JSON) ---

  /// Le numéro de TVA du salon principal.
  String? salonPrincipalTva;
  /// Le nom du salon principal.
  String? salonPrincipalNom;
  /// L'identifiant du salon principal.
  int? salonPrincipalId;

  //endregion

  /// Constructeur principal pour créer une instance de `Coiffeuse`.
  Coiffeuse({
    required this.idTblUser,
    required this.id,
    this.nomCommercial,
    this.position,
    required this.uuid,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.numeroTelephone,
    this.dateNaissance,
    required this.sexe,
    required this.isActive,
    this.photoProfil,
    this.numero,
    this.nomRue,
    this.commune,
    this.codePostal,
    this.salonPrincipalTva,
    this.salonPrincipalNom,
    this.salonPrincipalId,
  });

  /// Factory constructor pour créer une instance de `Coiffeuse` à partir d'un map JSON.
  ///
  /// Gère la désérialisation d'une structure JSON imbriquée (`user`, `adresse`, `salon_principal`).
  factory Coiffeuse.fromJson(Map<String, dynamic> json) {
    return Coiffeuse(
      // Champs directs
      idTblUser: json['idTblUser'],
      id: json['id'],
      nomCommercial: json['nom_commercial'],
      position: json['position'],
      // Champs de l'objet 'user'
      uuid: json['user']['uuid'],
      nom: json['user']['nom'],
      prenom: json['user']['prenom'],
      email: json['user']['email'],
      numeroTelephone: json['user']['numero_telephone'],
      dateNaissance: json['user']['date_naissance'],
      sexe: json['user']['sexe'],
      isActive: json['user']['is_active'],
      photoProfil: json['user']['photo_profil'],
      // Champs de l'objet 'adresse', avec accès sécurisé (null-aware).
      numero: json['user']['adresse']?['numero'],
      nomRue: json['user']['adresse']?['rue']?['nom_rue'],
      commune: json['user']['adresse']?['rue']?['localite']?['commune'],
      codePostal: json['user']['adresse']?['rue']?['localite']?['code_postal'],
      // Champs de l'objet 'salon_principal', avec accès sécurisé.
      salonPrincipalTva: json['salon_principal']?['numero_tva'],
      salonPrincipalNom: json['salon_principal']?['nom_salon'],
      salonPrincipalId: json['salon_principal']?['idTblSalon'],
    );
  }

  /// Convertit l'instance de `Coiffeuse` en un map JSON.
  ///
  /// Reconstruit la structure JSON imbriquée attendue par l'API.
  Map<String, dynamic> toJson() {
    return {
      'idTblUser': idTblUser,
      'nom_commercial': nomCommercial,
      'position': position,
      'user': {
        'uuid': uuid,
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'numero_telephone': numeroTelephone,
        'date_naissance': dateNaissance,
        'sexe': sexe,
        'is_active': isActive,
        'photo_profil': photoProfil,
        'adresse': {
          'numero': numero,
          'rue': {
            'nom_rue': nomRue,
            'localite': {
              'commune': commune,
              'code_postal': codePostal,
            }
          }
        }
      },
      // L'objet 'salon_principal' n'est inclus que si un ID de salon existe.
      'salon_principal': salonPrincipalId != null ? {
        'idTblSalon': salonPrincipalId,
        'nom_salon': salonPrincipalNom,
        'numero_tva': salonPrincipalTva,
      } : null,
    };
  }

  //region Propriétés de Compatibilité
  /// Getter pour la compatibilité avec l'ancien nom de champ `denominationSociale`.
  String? get denominationSociale => nomCommercial;
  /// Setter pour la compatibilité avec l'ancien nom de champ `denominationSociale`.
  set denominationSociale(String? value) => nomCommercial = value;

  /// Getter pour la compatibilité avec l'ancien nom de champ `tva`.
  String? get tva => salonPrincipalTva;
  /// Setter pour la compatibilité avec l'ancien nom de champ `tva`.
  set tva(String? value) => salonPrincipalTva = value;
  //endregion

  //region Propriétés Utilitaires
  /// Vérifie si la coiffeuse est associée à un salon principal actif.
  bool get hasActiveSalon => salonPrincipalId != null;

  /// Retourne le nom complet (prénom + nom).
  String get fullName => '$prenom $nom';

  /// Retourne le nom à afficher : le nom commercial s'il existe, sinon le nom complet.
  String get displayName => nomCommercial?.isNotEmpty == true ? nomCommercial! : fullName;
//endregion
}








// class Coiffeuse {
//   int idTblUser;
//   int id;
//   String? nomCommercial; // ✅ Changé de denominationSociale à nomCommercial
//   String? position;
//   // Infos utilisateur
//   String uuid;
//   String nom;
//   String prenom;
//   String email;
//   String numeroTelephone;
//   String? dateNaissance;
//   String sexe;
//   bool isActive;
//   String? photoProfil;
//   // Adresse
//   String? numero;
//   String? nomRue;
//   String? commune;
//   String? codePostal;
//   // ✅ Ajout des informations salon (salon principal)
//   String? salonPrincipalTva;
//   String? salonPrincipalNom;
//   int? salonPrincipalId;
//
//   Coiffeuse({
//     required this.idTblUser,
//     required this.id,
//     this.nomCommercial,
//     this.position,
//     required this.uuid,
//     required this.nom,
//     required this.prenom,
//     required this.email,
//     required this.numeroTelephone,
//     this.dateNaissance,
//     required this.sexe,
//     required this.isActive,
//     this.photoProfil,
//     this.numero,
//     this.nomRue,
//     this.commune,
//     this.codePostal,
//     this.salonPrincipalTva,
//     this.salonPrincipalNom,
//     this.salonPrincipalId,
//   });
//
//   // 🔹 Convertir depuis JSON
//   factory Coiffeuse.fromJson(Map<String, dynamic> json) {
//     return Coiffeuse(
//       idTblUser: json['idTblUser'],
//       id: json['id'],
//       nomCommercial: json['nom_commercial'], // ✅ Mise à jour du champ
//       position: json['position'],
//       uuid: json['user']['uuid'],
//       nom: json['user']['nom'],
//       prenom: json['user']['prenom'],
//       email: json['user']['email'],
//       numeroTelephone: json['user']['numero_telephone'],
//       dateNaissance: json['user']['date_naissance'],
//       sexe: json['user']['sexe'],
//       isActive: json['user']['is_active'],
//       photoProfil: json['user']['photo_profil'],
//       numero: json['user']['adresse']?['numero'],
//       nomRue: json['user']['adresse']?['rue']?['nom_rue'],
//       commune: json['user']['adresse']?['rue']?['localite']?['commune'],
//       codePostal: json['user']['adresse']?['rue']?['localite']?['code_postal'],
//       // ✅ Récupération des infos du salon principal depuis la nouvelle structure
//       salonPrincipalTva: json['salon_principal']?['numero_tva'],
//       salonPrincipalNom: json['salon_principal']?['nom_salon'],
//       salonPrincipalId: json['salon_principal']?['idTblSalon'],
//     );
//   }
//
//   // 🔹 Convertir en JSON
//   Map<String, dynamic> toJson() {
//     return {
//       'idTblUser': idTblUser,
//       'nom_commercial': nomCommercial, // ✅ Mise à jour du champ
//       'position': position,
//       'user': {
//         'uuid': uuid,
//         'nom': nom,
//         'prenom': prenom,
//         'email': email,
//         'numero_telephone': numeroTelephone,
//         'date_naissance': dateNaissance,
//         'sexe': sexe,
//         'is_active': isActive,
//         'photo_profil': photoProfil,
//         'adresse': {
//           'numero': numero,
//           'rue': {
//             'nom_rue': nomRue,
//             'localite': {
//               'commune': commune,
//               'code_postal': codePostal,
//             }
//           }
//         }
//       },
//       // ✅ Ajout des infos salon principal
//       'salon_principal': salonPrincipalId != null ? {
//         'idTblSalon': salonPrincipalId,
//         'nom_salon': salonPrincipalNom,
//         'numero_tva': salonPrincipalTva,
//       } : null,
//     };
//   }
//
//   // ✅ Propriétés de compatibilité avec l'ancien code
//   String? get denominationSociale => nomCommercial;
//   set denominationSociale(String? value) => nomCommercial = value;
//
//   String? get tva => salonPrincipalTva; // La TVA vient maintenant du salon principal
//   set tva(String? value) => salonPrincipalTva = value;
//
//   // ✅ Propriétés utilitaires
//   bool get hasActiveSalon => salonPrincipalId != null;
//   String get fullName => '$prenom $nom';
//   String get displayName => nomCommercial?.isNotEmpty == true ? nomCommercial! : fullName;
// }
