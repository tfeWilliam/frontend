/****************************************************************************************
 *
 * MODÈLES DE DONNÉES : CRÉATION D'UTILISATEUR
 * Fichier: models/user_creation.dart
 *
 * OBJECTIF :
 * Ce fichier définit les modèles de données nécessaires pour le workflow complet
 * de création d'un nouvel utilisateur, de la collecte des données à la gestion de
 * la réponse de l'API.
 *
 * STRUCTURE DES CLASSES :
 * - UserCreationModel : Un modèle de type "form model" qui agrège toutes les données
 * saisies par l'utilisateur dans le formulaire d'inscription. Il inclut une
 * logique de validation complète et des méthodes pour préparer les données pour l'API.
 *
 * - UserCreationResponse : Un modèle "enveloppe" qui représente la réponse structurée
 * de l'API, capable de gérer aussi bien les cas de succès que les différentes
 * sortes d'erreurs (validation, serveur, etc.).
 *
 *****************************************************************************************/
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Modèle de données pour agréger et valider les informations d'un formulaire de création d'utilisateur.
class UserCreationModel {
  // --- Champs obligatoires de base ---
  /// L'identifiant unique universel (UUID) de l'utilisateur, généralement fourni par le système d'authentification.
  final String userUuid;
  /// L'adresse email de l'utilisateur.
  final String email;
  /// Le type de profil à créer ("Coiffeuse" ou "Client").
  final String type;
  /// Le nom de famille de l'utilisateur.
  final String nom;
  /// Le prénom de l'utilisateur.
  final String prenom;
  /// Le sexe de l'utilisateur.
  final String sexe;
  /// Le numéro de téléphone de l'utilisateur.
  final String telephone;
  /// La date de naissance au format DD-MM-YYYY.
  final String dateNaissance;

  // --- Champs d'adresse obligatoires ---
  /// Le code postal de l'adresse.
  final String codePostal;
  /// La commune de l'adresse.
  final String commune;
  /// Le nom de la rue.
  final String rue;
  /// Le numéro de voirie.
  final String numero;

  // --- Champs optionnels ---
  /// La boîte postale (optionnelle).
  final String? boitePostale;
  /// Le nom commercial (requis uniquement pour le type "Coiffeuse").
  final String? nomCommercial;
  /// Le fichier de la photo de profil pour un upload mobile (`dart:io`).
  final File? photoProfilFile;
  /// Les bytes de la photo de profil pour un upload web (`dart:typed_data`).
  final Uint8List? photoProfilBytes;
  /// Le nom du fichier de la photo de profil.
  final String? photoProfilName;

  /// Constructeur principal du modèle.
  UserCreationModel({
    required this.userUuid,
    required this.email,
    required this.type,
    required this.nom,
    required this.prenom,
    required this.sexe,
    required this.telephone,
    required this.dateNaissance,
    required this.codePostal,
    required this.commune,
    required this.rue,
    required this.numero,
    this.boitePostale,
    this.nomCommercial,
    this.photoProfilFile,
    this.photoProfilBytes,
    this.photoProfilName,
  });

  /// Factory pour construire le modèle à partir de données brutes, typiquement issues d'un formulaire UI.
  factory UserCreationModel.fromForm({
    required String userUuid,
    required String email,
    required bool isCoiffeuse,
    required String nom,
    required String prenom,
    required String sexe,
    required String telephone,
    required String dateNaissance,
    required String codePostal,
    required String commune,
    required String rue,
    required String numero,
    String? boitePostale,
    String? nomCommercial,
    File? photoProfilFile,
    Uint8List? photoProfilBytes,
    String? photoProfilName,
  }) {
    return UserCreationModel(
      userUuid: userUuid,
      email: email,
      type: isCoiffeuse ? "Coiffeuse" : "Client",
      nom: nom,
      prenom: prenom,
      sexe: sexe,
      telephone: telephone,
      dateNaissance: dateNaissance,
      codePostal: codePostal,
      commune: commune,
      rue: rue,
      numero: numero,
      boitePostale: boitePostale,
      nomCommercial: nomCommercial,
      photoProfilFile: photoProfilFile,
      photoProfilBytes: photoProfilBytes,
      photoProfilName: photoProfilName,
    );
  }

  /// Exécute une validation complète sur tous les champs du modèle.
  /// Retourne une map des erreurs, où la clé est le nom du champ et la valeur est le message d'erreur.
  /// Retourne une map vide si la validation réussit.
  Map<String, String> validate() {
    Map<String, String> errors = {};

    // Validation des champs de base
    if (userUuid.isEmpty) errors['userUuid'] = 'UUID utilisateur requis';
    if (email.isEmpty) errors['email'] = 'Email requis';
    if (!_isValidEmail(email)) errors['email'] = 'Format email invalide';
    if (nom.isEmpty) errors['nom'] = 'Nom requis';
    if (prenom.isEmpty) errors['prenom'] = 'Prénom requis';
    if (sexe.isEmpty) errors['sexe'] = 'Sexe requis';
    if (telephone.isEmpty) errors['telephone'] = 'Téléphone requis';
    if (dateNaissance.isEmpty) errors['dateNaissance'] = 'Date de naissance requise';
    if (!_isValidDate(dateNaissance)) errors['dateNaissance'] = 'Format date invalide (DD-MM-YYYY)';

    // Validation des champs d'adresse
    if (codePostal.isEmpty) errors['codePostal'] = 'Code postal requis';
    if (commune.isEmpty) errors['commune'] = 'Commune requise';
    if (rue.isEmpty) errors['rue'] = 'Rue requise';
    if (numero.isEmpty) errors['numero'] = 'Numéro requis';

    // Validation spécifique pour le type "Coiffeuse"
    if (type == "coiffeuse") {
      if (nomCommercial == null || nomCommercial!.isEmpty) {
        errors['nomCommercial'] = 'Nom commercial requis pour une coiffeuse';
      }
    }

    return errors;
  }

  /// Méthode privée pour valider le format d'un email.
  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  /// Méthode privée pour valider le format et la validité d'une date (DD-MM-YYYY).
  bool _isValidDate(String date) {
    final regex = RegExp(r'^\d{2}-\d{2}-\d{4}$');
    if (!regex.hasMatch(date)) return false;

    try {
      final parts = date.split('-');
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      final parsedDate = DateTime(year, month, day);
      return parsedDate.year == year && parsedDate.month == month && parsedDate.day == day;
    } catch (e) {
      return false;
    }
  }

  /// Convertit le modèle en une map de champs textuels prêts à être envoyés à l'API
  /// dans une requête multipart/form-data.
  Map<String, String> toApiFields() {
    Map<String, String> fields = {
      'userUuid': userUuid,
      'email': email,
      'type': type,
      'nom': nom,
      'prenom': prenom,
      'sexe': sexe,
      'telephone': telephone,
      'date_naissance': dateNaissance,
      'code_postal': codePostal,
      'commune': commune,
      'rue': rue,
      'numero': numero,
    };

    // Ajoute les champs optionnels seulement s'ils sont renseignés.
    if (boitePostale != null && boitePostale!.isNotEmpty) {
      fields['boite_postale'] = boitePostale!;
    }
    if (nomCommercial != null && nomCommercial!.isNotEmpty) {
      fields['nom_commercial'] = nomCommercial!;
    }

    return fields;
  }

  /// Crée une copie de l'objet avec des valeurs modifiées, pour la gestion d'état immuable.
  UserCreationModel copyWith({
    String? userUuid,
    String? email,
    String? type,
    String? nom,
    String? prenom,
    String? sexe,
    String? telephone,
    String? dateNaissance,
    String? codePostal,
    String? commune,
    String? rue,
    String? numero,
    String? boitePostale,
    String? nomCommercial,
    File? photoProfilFile,
    Uint8List? photoProfilBytes,
    String? photoProfilName,
  }) {
    return UserCreationModel(
      userUuid: userUuid ?? this.userUuid,
      email: email ?? this.email,
      type: type ?? this.type,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      sexe: sexe ?? this.sexe,
      telephone: telephone ?? this.telephone,
      dateNaissance: dateNaissance ?? this.dateNaissance,
      codePostal: codePostal ?? this.codePostal,
      commune: commune ?? this.commune,
      rue: rue ?? this.rue,
      numero: numero ?? this.numero,
      boitePostale: boitePostale ?? this.boitePostale,
      nomCommercial: nomCommercial ?? this.nomCommercial,
      photoProfilFile: photoProfilFile ?? this.photoProfilFile,
      photoProfilBytes: photoProfilBytes ?? this.photoProfilBytes,
      photoProfilName: photoProfilName ?? this.photoProfilName,
    );
  }

  /// Fournit une représentation textuelle de l'objet pour le débogage.
  @override
  String toString() {
    return 'UserCreationModel(userUuid: $userUuid, email: $email, type: $type, nom: $nom, prenom: $prenom)';
  }
}

/// Modèle représentant la réponse structurée de l'API suite à une tentative de création d'utilisateur.
class UserCreationResponse {
  /// Indique si l'opération a réussi.
  final bool success;
  /// Le message retourné par l'API.
  final String message;
  /// Les données retournées par l'API en cas de succès (ex: infos sur l'utilisateur créé).
  final Map<String, dynamic>? data;
  /// Une map des erreurs de validation retournées par l'API.
  final Map<String, String>? validationErrors;
  /// Le code de statut HTTP de la réponse.
  final int? statusCode;

  /// Constructeur principal pour la réponse.
  UserCreationResponse({
    required this.success,
    required this.message,
    this.data,
    this.validationErrors,
    this.statusCode,
  });

  /// Factory pour créer une réponse de succès standard.
  factory UserCreationResponse.success({
    required String message,
    Map<String, dynamic>? data,
  }) {
    return UserCreationResponse(
      success: true,
      message: message,
      data: data,
      statusCode: 201,
    );
  }

  /// Factory pour créer une réponse d'erreur standard.
  factory UserCreationResponse.error({
    required String message,
    Map<String, String>? validationErrors,
    int? statusCode,
  }) {
    return UserCreationResponse(
      success: false,
      message: message,
      validationErrors: validationErrors,
      statusCode: statusCode,
    );
  }

  /// Factory pour construire une instance à partir d'une réponse HTTP brute (statusCode et body).
  /// Gère les différents cas de figure : succès, erreur de validation, erreur serveur.
  factory UserCreationResponse.fromHttpResponse({
    required int statusCode,
    required String body,
  }) {
    try {
      final responseData = json.decode(body);

      if (statusCode == 201 && responseData['status'] == 'success') {
        return UserCreationResponse.success(
          message: responseData['message'] ?? 'Profil créé avec succès',
          data: responseData['data'],
        );
      } else if (statusCode == 400) {
        Map<String, String> errors = {};
        if (responseData['errors'] != null) {
          Map<String, dynamic> apiErrors = responseData['errors'];
          apiErrors.forEach((field, messages) {
            if (messages is List) {
              errors[field] = messages.join(', ');
            } else {
              errors[field] = messages.toString();
            }
          });
        }
        return UserCreationResponse.error(
          message: responseData['message'] ?? 'Erreurs de validation',
          validationErrors: errors,
          statusCode: statusCode,
        );
      } else {
        return UserCreationResponse.error(
          message: responseData['message'] ?? 'Erreur serveur',
          statusCode: statusCode,
        );
      }
    } catch (e) {
      return UserCreationResponse.error(
        message: "Erreur lors du parsing de la réponse: $e",
        statusCode: statusCode,
      );
    }
  }

  /// Accesseur pour récupérer les données de l'utilisateur créé en cas de succès.
  Map<String, dynamic>? get createdUserData => data;

  /// Accesseur pratique pour vérifier s'il s'agit d'une erreur d'authentification.
  bool get isAuthError => statusCode == 401;

  /// Accesseur pratique pour vérifier s'il s'agit d'une erreur de validation.
  bool get isValidationError => statusCode == 400 && validationErrors != null;

  /// Fournit une représentation textuelle de l'objet pour le débogage.
  @override
  String toString() {
    return 'UserCreationResponse(success: $success, message: $message, statusCode: $statusCode)';
  }
}







// // models/user_creation.dart
// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/foundation.dart';
//
// /// Modèle pour la création d'un profil utilisateur
// class UserCreationModel {
//   // Champs obligatoires de base
//   final String userUuid;
//   final String email;
//   final String type;
//   final String nom;
//   final String prenom;
//   final String sexe;
//   final String telephone;
//   final String dateNaissance;
//
//   // Champs d'adresse obligatoires
//   final String codePostal;
//   final String commune;
//   final String rue;
//   final String numero;
//
//   // Champs optionnels
//   final String? boitePostale;
//   final String? nomCommercial;
//   final File? photoProfilFile;
//   final Uint8List? photoProfilBytes;
//   final String? photoProfilName;
//
//   UserCreationModel({
//     required this.userUuid,
//     required this.email,
//     required this.type,
//     required this.nom,
//     required this.prenom,
//     required this.sexe,
//     required this.telephone,
//     required this.dateNaissance,
//     required this.codePostal,
//     required this.commune,
//     required this.rue,
//     required this.numero,
//     this.boitePostale,
//     this.nomCommercial,
//     this.photoProfilFile,
//     this.photoProfilBytes,
//     this.photoProfilName,
//   });
//
//   /// Factory pour créer le modèle depuis un formulaire
//   factory UserCreationModel.fromForm({
//     required String userUuid,
//     required String email,
//     required bool isCoiffeuse,
//     required String nom,
//     required String prenom,
//     required String sexe,
//     required String telephone,
//     required String dateNaissance,
//     required String codePostal,
//     required String commune,
//     required String rue,
//     required String numero,
//     String? boitePostale,
//     String? nomCommercial,
//     File? photoProfilFile,
//     Uint8List? photoProfilBytes,
//     String? photoProfilName,
//   }) {
//     return UserCreationModel(
//       userUuid: userUuid,
//       email: email,
//       type: isCoiffeuse ? "Coiffeuse" : "Client",
//       nom: nom,
//       prenom: prenom,
//       sexe: sexe, // S'assure que le sexe est en minuscules
//       telephone: telephone,
//       dateNaissance: dateNaissance,
//       codePostal: codePostal,
//       commune: commune,
//       rue: rue,
//       numero: numero,
//       boitePostale: boitePostale,
//       nomCommercial: nomCommercial,
//       photoProfilFile: photoProfilFile,
//       photoProfilBytes: photoProfilBytes,
//       photoProfilName: photoProfilName,
//     );
//   }
//
//   /// Validation du modèle
//   Map<String, String> validate() {
//     Map<String, String> errors = {};
//
//     // Validation des champs obligatoires de base
//     if (userUuid.isEmpty) errors['userUuid'] = 'UUID utilisateur requis';
//     if (email.isEmpty) errors['email'] = 'Email requis';
//     if (!_isValidEmail(email)) errors['email'] = 'Format email invalide';
//     if (nom.isEmpty) errors['nom'] = 'Nom requis';
//     if (prenom.isEmpty) errors['prenom'] = 'Prénom requis';
//     if (sexe.isEmpty) errors['sexe'] = 'Sexe requis';
//     if (telephone.isEmpty) errors['telephone'] = 'Téléphone requis';
//     if (dateNaissance.isEmpty) errors['dateNaissance'] = 'Date de naissance requise';
//     if (!_isValidDate(dateNaissance)) errors['dateNaissance'] = 'Format date invalide (DD-MM-YYYY)';
//
//     // Validation des champs d'adresse
//     if (codePostal.isEmpty) errors['codePostal'] = 'Code postal requis';
//     if (commune.isEmpty) errors['commune'] = 'Commune requise';
//     if (rue.isEmpty) errors['rue'] = 'Rue requise';
//     if (numero.isEmpty) errors['numero'] = 'Numéro requis';
//
//     // Validation spécifique pour coiffeuse (basée sur le champ 'type')
//     if (type == "coiffeuse") { // CHANGEMENT ICI : Utilise 'type' pour la validation
//       if (nomCommercial == null || nomCommercial!.isEmpty) {
//         errors['nomCommercial'] = 'Nom commercial requis pour une coiffeuse';
//       }
//     }
//
//     return errors;
//   }
//
//   /// Validation de l'email
//   bool _isValidEmail(String email) {
//     return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
//   }
//
//   /// Validation de la date
//   bool _isValidDate(String date) {
//     final regex = RegExp(r'^\d{2}-\d{2}-\d{4}$');
//     if (!regex.hasMatch(date)) return false;
//
//     try {
//       final parts = date.split('-');
//       final day = int.parse(parts[0]);
//       final month = int.parse(parts[1]);
//       final year = int.parse(parts[2]);
//       final parsedDate = DateTime(year, month, day);
//       return parsedDate.year == year &&
//           parsedDate.month == month &&
//           parsedDate.day == day;
//     } catch (e) {
//       return false;
//     }
//   }
//
//   /// Conversion en Map pour l'envoi API
//   Map<String, String> toApiFields() {
//     Map<String, String> fields = {
//       'userUuid': userUuid,
//       'email': email,
//       'type': type, // CHANGEMENT ICI : Envoie 'type' à l'API
//       'nom': nom,
//       'prenom': prenom,
//       'sexe': sexe,
//       'telephone': telephone,
//       'date_naissance': dateNaissance,
//       'code_postal': codePostal,
//       'commune': commune,
//       'rue': rue,
//       'numero': numero,
//     };
//
//     // Ajouter la boîte postale si présente
//     if (boitePostale != null && boitePostale!.isNotEmpty) {
//       fields['boite_postale'] = boitePostale!;
//     }
//
//     // Ajouter le nom commercial pour les coiffeuses
//     if (nomCommercial != null && nomCommercial!.isNotEmpty) {
//       fields['nom_commercial'] = nomCommercial!;
//     }
//
//     return fields;
//   }
//
//   /// Copie du modèle avec modifications
//   UserCreationModel copyWith({
//     String? userUuid,
//     String? email,
//     String? type, // CHANGEMENT ICI : Utilise 'type'
//     String? nom,
//     String? prenom,
//     String? sexe,
//     String? telephone,
//     String? dateNaissance,
//     String? codePostal,
//     String? commune,
//     String? rue,
//     String? numero,
//     String? boitePostale,
//     String? nomCommercial,
//     File? photoProfilFile,
//     Uint8List? photoProfilBytes,
//     String? photoProfilName,
//   }) {
//     return UserCreationModel(
//       userUuid: userUuid ?? this.userUuid,
//       email: email ?? this.email,
//       type: type ?? this.type, // CHANGEMENT ICI : Copie le champ 'type'
//       nom: nom ?? this.nom,
//       prenom: prenom ?? this.prenom,
//       sexe: sexe ?? this.sexe,
//       telephone: telephone ?? this.telephone,
//       dateNaissance: dateNaissance ?? this.dateNaissance,
//       codePostal: codePostal ?? this.codePostal,
//       commune: commune ?? this.commune,
//       rue: rue ?? this.rue,
//       numero: numero ?? this.numero,
//       boitePostale: boitePostale ?? this.boitePostale,
//       nomCommercial: nomCommercial ?? this.nomCommercial,
//       photoProfilFile: photoProfilFile ?? this.photoProfilFile,
//       photoProfilBytes: photoProfilBytes ?? this.photoProfilBytes,
//       photoProfilName: photoProfilName ?? this.photoProfilName,
//     );
//   }
//
//   @override
//   String toString() {
//     // CHANGEMENT ICI : Affiche le champ 'type'
//     return 'UserCreationModel(userUuid: $userUuid, email: $email, type: $type, nom: $nom, prenom: $prenom)';
//   }
// }
//
// /// Classe pour gérer la réponse de l'API
// class UserCreationResponse {
//   final bool success;
//   final String message;
//   final Map<String, dynamic>? data;
//   final Map<String, String>? validationErrors;
//   final int? statusCode;
//
//   UserCreationResponse({
//     required this.success,
//     required this.message,
//     this.data,
//     this.validationErrors,
//     this.statusCode,
//   });
//
//   /// Factory pour une réponse de succès
//   factory UserCreationResponse.success({
//     required String message,
//     Map<String, dynamic>? data,
//   }) {
//     return UserCreationResponse(
//       success: true,
//       message: message,
//       data: data,
//       statusCode: 201,
//     );
//   }
//
//   /// Factory pour une réponse d'erreur
//   factory UserCreationResponse.error({
//     required String message,
//     Map<String, String>? validationErrors,
//     int? statusCode,
//   }) {
//     return UserCreationResponse(
//       success: false,
//       message: message,
//       validationErrors: validationErrors,
//       statusCode: statusCode,
//     );
//   }
//
//   /// Factory depuis une réponse HTTP
//   factory UserCreationResponse.fromHttpResponse({
//     required int statusCode,
//     required String body,
//   }) {
//     try {
//       final responseData = json.decode(body);
//
//       if (statusCode == 201 && responseData['status'] == 'success') {
//         return UserCreationResponse.success(
//           message: responseData['message'] ?? 'Profil créé avec succès',
//           data: responseData['data'],
//         );
//       } else if (statusCode == 400) {
//         // Erreurs de validation
//         Map<String, String> errors = {};
//         if (responseData['errors'] != null) {
//           Map<String, dynamic> apiErrors = responseData['errors'];
//           apiErrors.forEach((field, messages) {
//             if (messages is List) {
//               errors[field] = messages.join(', ');
//             } else {
//               errors[field] = messages.toString();
//             }
//           });
//         }
//
//         return UserCreationResponse.error(
//           message: responseData['message'] ?? 'Erreurs de validation',
//           validationErrors: errors,
//           statusCode: statusCode,
//         );
//       } else {
//         return UserCreationResponse.error(
//           message: responseData['message'] ?? 'Erreur serveur',
//           statusCode: statusCode,
//         );
//       }
//     } catch (e) {
//       return UserCreationResponse.error(
//         message: "Erreur lors du parsing de la réponse: $e",
//         statusCode: statusCode,
//       );
//     }
//   }
//
//   /// Récupérer les informations utilisateur créé
//   Map<String, dynamic>? get createdUserData => data;
//
//   /// Vérifier si c'est une erreur d'authentification
//   bool get isAuthError => statusCode == 401;
//
//   /// Vérifier si c'est une erreur de validation
//   bool get isValidationError => statusCode == 400 && validationErrors != null;
//
//   @override
//   String toString() {
//     return 'UserCreationResponse(success: $success, message: $message, statusCode: $statusCode)';
//   }
// }