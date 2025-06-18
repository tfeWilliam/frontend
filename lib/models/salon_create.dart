/****************************************************************************************
 *
 * MODÈLE DE DONNÉES : SalonCreateModel
 * Fichier : hairbnb/lib/models/salon_create.dart
 *
 * OBJECTIF :
 * Cette classe sert de modèle de données pour agréger toutes les informations
 * nécessaires à la création d'un nouveau salon. Elle est typiquement peuplée par les
 * données d'un formulaire dans l'interface utilisateur.
 *
 * FONCTIONNALITÉS CLÉS :
 * - Contient tous les champs requis pour la création d'un salon.
 * - La propriété `logo` est de type `dynamic` pour pouvoir contenir un objet
 * fichier (`File` ou `XFile`) qui sera téléversé (uploadé).
 * - Inclut une méthode `toFields()` qui formate les données textuelles pour être
 * envoyées dans une requête HTTP de type `multipart/form-data`, un format
 * utilisé pour transmettre des fichiers en même temps que des données textuelles.
 *
 *****************************************************************************************/

class SalonCreateModel {
  /// L'identifiant de l'utilisateur qui crée le salon.
  final int idTblUser;
  /// Le nom commercial du nouveau salon.
  final String nomSalon;
  /// Le slogan ou la phrase d'accroche du salon.
  final String slogan;
  /// Le fichier du logo. Il s'agit d'un objet de type 'File' ou 'XFile' prêt à être uploadé.
  final dynamic logo;
  /// Le texte de description "À propos" du salon.
  final String aPropos;
  /// Le numéro de TVA du salon.
  final String numeroTva;
  /// L'adresse textuelle complète du salon.
  final String position;
  /// L'identifiant de l'objet TblAdresse associé (généralement depuis une autre table).
  final int adresse;

  /// Constructeur pour initialiser le modèle avec toutes les données requises du formulaire.
  SalonCreateModel({
    required this.idTblUser,
    required this.nomSalon,
    required this.slogan,
    required this.logo,
    required this.aPropos,
    required this.numeroTva,
    required this.position,
    required this.adresse,
  });

  /// Convertit les données du modèle en une map de champs textuels.
  /// Cette map est destinée à être utilisée comme partie "fields" d'une requête HTTP
  /// multipart, idéale pour l'envoi de formulaires contenant à la fois des données
  /// textuelles et des fichiers.
  /// Notez que le champ 'logo' (le fichier) n'est pas inclus ici et doit être
  /// ajouté séparément à la partie "files" de la requête.
  Map<String, String> toFields() {
    return {
      'idTblUser': idTblUser.toString(),
      'nom_salon': nomSalon,
      'slogan': slogan,
      'a_propos': aPropos,
      'numero_tva': numeroTva,
      'position': position,
      'adresse': adresse.toString(),
    };
  }
}







// // hairbnb/lib/models/salon_create.dart
// class SalonCreateModel {
//   final int idTblUser;
//   final String nomSalon;
//   final String slogan;
//   final dynamic logo; // File ou XFile pour le logo
//   final String aPropos;     // ✅ OBLIGATOIRE maintenant
//   final String numeroTva;   // ✅ OBLIGATOIRE maintenant
//   final String position;    // ✅ OBLIGATOIRE maintenant
//   final int adresse;        // ✅ OBLIGATOIRE et AJOUTÉ (ID de TblAdresse)
//
//   SalonCreateModel({
//     required this.idTblUser,
//     required this.nomSalon,
//     required this.slogan,
//     required this.logo,
//     required this.aPropos,     // ✅ Plus optionnel
//     required this.numeroTva,   // ✅ Plus optionnel
//     required this.position,    // ✅ Plus optionnel
//     required this.adresse,     // ✅ Nouveau champ obligatoire
//   });
//
//   /// Convertir en champs texte pour la requête multipart
//   Map<String, String> toFields() {
//     return {
//       'idTblUser': idTblUser.toString(),
//       'nom_salon': nomSalon,
//       'slogan': slogan,
//       'a_propos': aPropos,           // ✅ Toujours inclus
//       'numero_tva': numeroTva,       // ✅ Toujours inclus
//       'position': position,          // ✅ Toujours inclus
//       'adresse': adresse.toString(), // ✅ Nouveau champ obligatoire
//     };
//   }
// }
