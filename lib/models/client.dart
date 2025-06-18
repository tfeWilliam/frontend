////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                 MODÈLE DE DONNÉES POUR UN UTILISATEUR CLIENT                 //
//                                                                            //
//  Ce fichier définit le modèle `Client`, qui représente un utilisateur de   //
//  type "Client" dans l'application. Cette classe est conçue pour "aplatir"  //
//  une structure de données JSON imbriquée provenant de l'API, afin de        //
//  simplifier la manipulation des données du client et de son adresse dans   //
//  le code Dart.                                                             //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


class Client {
  //region Propriétés du Client

  // --- Informations de base de l'utilisateur ---

  /// L'identifiant numérique unique de l'utilisateur.
  int idTblUser;
  /// L'identifiant universel unique (UUID) de l'utilisateur.
  String uuid;
  /// Le nom de famille du client.
  String nom;
  /// Le prénom du client.
  String prenom;
  /// L'adresse e-mail du client.
  String email;
  /// Le numéro de téléphone du client.
  String numeroTelephone;
  /// La date de naissance du client (format String ISO 8601).
  String? dateNaissance;
  /// Le sexe du client.
  String sexe;
  /// Indique si le compte du client est actif.
  bool isActive;
  /// L'URL de la photo de profil du client (peut être nulle).
  String? photoProfil;

  // --- Informations sur l'adresse (aplaties) ---

  /// Le numéro de la rue.
  String? numero;
  /// La boîte postale, si applicable.
  String? boitePostale;
  /// Le nom de la rue.
  String? nomRue;
  /// La commune de l'adresse.
  String? commune;
  /// Le code postal de l'adresse.
  String? codePostal;

  //endregion

  /// Constructeur principal pour créer une instance de `Client`.
  Client({
    required this.idTblUser,
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
    this.boitePostale,
    this.nomRue,
    this.commune,
    this.codePostal,
  });

  /// Factory constructor pour créer une instance de `Client` à partir d'un map JSON.
  ///
  /// Cette méthode gère la désérialisation d'une structure JSON imbriquée, où les
  /// informations de l'utilisateur et de l'adresse sont contenues dans des sous-objets.
  factory Client.fromJson(Map<String, dynamic> json) {
    // La structure attendue est `{'idTblUser': ..., 'user': {'nom': ..., 'adresse': ...}}`
    return Client(
      idTblUser: json['idTblUser'],
      uuid: json['user']['uuid'],
      nom: json['user']['nom'],
      prenom: json['user']['prenom'],
      email: json['user']['email'],
      numeroTelephone: json['user']['numero_telephone'],
      dateNaissance: json['user']['date_naissance'],
      sexe: json['user']['sexe'],
      isActive: json['user']['is_active'],
      photoProfil: json['user']['photo_profil'],

      // Accès sécurisé aux données d'adresse profondément imbriquées.
      // L'opérateur `?` (null-aware access) prévient les erreurs si un niveau
      // de la hiérarchie est manquant (par exemple, si 'adresse' est null).
      numero: json['user']['adresse']?['numero'],
      boitePostale: json['user']['adresse']?['boite_postale'],
      nomRue: json['user']['adresse']?['rue']?['nom_rue'],
      commune: json['user']['adresse']?['rue']?['localite']?['commune'],
      codePostal: json['user']['adresse']?['rue']?['localite']?['code_postal'],
    );
  }

  /// Convertit l'instance de `Client` en un map JSON.
  ///
  /// Cette méthode reconstruit la structure JSON imbriquée attendue par l'API
  /// à partir de l'objet "aplati" utilisé dans l'application Dart.
  Map<String, dynamic> toJson() {
    return {
      'idTblUser': idTblUser,
      // Reconstruction de l'objet 'user' imbriqué.
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
        // Reconstruction de l'objet 'adresse' profondément imbriqué.
        'adresse': {
          'numero': numero,
          'boite_postale': boitePostale,
          'rue': {
            'nom_rue': nomRue,
            'localite': {
              'commune': commune,
              'code_postal': codePostal,
            }
          }
        }
      }
    };
  }
}






// class Client {
//   int idTblUser;
//   String uuid;
//   String nom;
//   String prenom;
//   String email;
//   String numeroTelephone;
//   String? dateNaissance;
//   String sexe;
//   bool isActive;
//   String? photoProfil;
//
//   // Adresse
//   String? numero;
//   String? boitePostale;
//   String? nomRue;
//   String? commune;
//   String? codePostal;
//
//   Client({
//     required this.idTblUser,
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
//     this.boitePostale,
//     this.nomRue,
//     this.commune,
//     this.codePostal,
//   });
//
//   // 🔹 Convertir depuis JSON
//   factory Client.fromJson(Map<String, dynamic> json) {
//     return Client(
//       idTblUser: json['idTblUser'],
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
//       boitePostale: json['user']['adresse']?['boite_postale'],
//       nomRue: json['user']['adresse']?['rue']?['nom_rue'],
//       commune: json['user']['adresse']?['rue']?['localite']?['commune'],
//       codePostal: json['user']['adresse']?['rue']?['localite']?['code_postal'],
//     );
//   }
//
//   // 🔹 Convertir en JSON
//   Map<String, dynamic> toJson() {
//     return {
//       'idTblUser': idTblUser,
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
//           'boite_postale': boitePostale,
//           'rue': {
//             'nom_rue': nomRue,
//             'localite': {
//               'commune': commune,
//               'code_postal': codePostal,
//             }
//           }
//         }
//       }
//     };
//   }
// }
