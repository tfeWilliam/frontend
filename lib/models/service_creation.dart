/****************************************************************************************
 *
 * MODÈLES DE DONNÉES : CRÉATION DE SERVICE ET CATÉGORIES
 *
 * OBJECTIF :
 * Ce fichier définit les modèles de données utilisés pour le processus de création
 * d'un nouveau service par un utilisateur.
 *
 * STRUCTURE DES CLASSES :
 * - ServiceCreation : Un modèle de type "form model" ou "view model" qui agrège,
 * valide et formate les données d'un formulaire de création de service avant de
 * les soumettre à une API.
 *
 * - Categorie : Un modèle simple représentant une catégorie de service, souvent utilisé
 * pour peupler des listes de sélection ou des menus déroulants.
 *
 * FONCTIONNALITÉS CLÉS :
 * - Le modèle `ServiceCreation` inclut une méthode de validation (`validate`) et une
 * méthode `copyWith` pour faciliter la gestion d'état immuable.
 * - Le modèle `Categorie` est doté d'une méthode `fromJson` robuste, capable de
 * parser des clés JSON variées, et d'une surcharge `toString` optimisée pour l'UI.
 *
 *****************************************************************************************/

/// Modèle représentant les données d'un formulaire de création de service.
class ServiceCreation {
  /// L'identifiant de l'utilisateur créant le service.
  final int userId;
  /// Le nom ou l'intitulé du service.
  final String intituleService;
  /// La description détaillée du service.
  final String description;
  /// Le prix du service.
  final double prix;
  /// La durée estimée du service, en minutes.
  final int tempsMinutes;
  /// L'identifiant de la catégorie à laquelle le service appartient.
  final int categorieId;

  /// Constructeur pour créer une instance de [ServiceCreation].
  ServiceCreation({
    required this.userId,
    required this.intituleService,
    required this.description,
    required this.prix,
    required this.tempsMinutes,
    required this.categorieId,
  });

  /// Convertit l'objet en une map JSON, prête à être envoyée au serveur via une API.
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'intitule_service': intituleService,
      'description': description,
      'prix': prix,
      'temps_minutes': tempsMinutes,
      'categorie_id': categorieId,
    };
  }

  /// Crée une instance à partir d'une map JSON, utile pour pré-remplir un formulaire (ex: pour l'édition).
  factory ServiceCreation.fromJson(Map<String, dynamic> json) {
    return ServiceCreation(
      userId: json['userId'] ?? 0,
      intituleService: json['intitule_service'] ?? '',
      description: json['description'] ?? '',
      prix: (json['prix'] as num?)?.toDouble() ?? 0.0,
      tempsMinutes: json['temps_minutes'] ?? 0,
      categorieId: json['categorie_id'] ?? 0,
    );
  }

  /// Valide les champs du modèle.
  /// Retourne une chaîne de caractères contenant le premier message d'erreur trouvé,
  /// ou `null` si toutes les données sont valides.
  String? validate() {
    if (intituleService.trim().isEmpty) {
      return 'Le nom du service est obligatoire';
    }
    if (intituleService.trim().length < 2) {
      return 'Le nom doit contenir au moins 2 caractères';
    }
    if (description.trim().isEmpty) {
      return 'La description est obligatoire';
    }
    if (prix <= 0) {
      return 'Le prix doit être supérieur à 0';
    }
    if (tempsMinutes <= 0) {
      return 'La durée doit être supérieure à 0';
    }
    if (categorieId <= 0) {
      return 'Une catégorie doit être sélectionnée';
    }
    return null; // Indique qu'il n'y a pas d'erreur de validation.
  }

  /// Crée une copie de l'instance actuelle avec des valeurs modifiées.
  /// Très utile pour la gestion d'état immuable (ex: avec BLoC, Riverpod, etc.).
  ServiceCreation copyWith({
    int? userId,
    String? intituleService,
    String? description,
    double? prix,
    int? tempsMinutes,
    int? categorieId,
  }) {
    return ServiceCreation(
      userId: userId ?? this.userId,
      intituleService: intituleService ?? this.intituleService,
      description: description ?? this.description,
      prix: prix ?? this.prix,
      tempsMinutes: tempsMinutes ?? this.tempsMinutes,
      categorieId: categorieId ?? this.categorieId,
    );
  }

  /// Fournit une représentation textuelle de l'objet pour le débogage.
  @override
  String toString() {
    return 'ServiceCreation(userId: $userId, intituleService: $intituleService, description: $description, prix: $prix, tempsMinutes: $tempsMinutes, categorieId: $categorieId)';
  }

  /// Surcharge de l'opérateur d'égalité pour comparer deux instances.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServiceCreation &&
        other.userId == userId &&
        other.intituleService == intituleService &&
        other.description == description &&
        other.prix == prix &&
        other.tempsMinutes == tempsMinutes &&
        other.categorieId == categorieId;
  }

  /// Surcharge du hash code pour correspondre à la logique de l'opérateur d'égalité.
  @override
  int get hashCode {
    return userId.hashCode ^
    intituleService.hashCode ^
    description.hashCode ^
    prix.hashCode ^
    tempsMinutes.hashCode ^
    categorieId.hashCode;
  }
}

/// Modèle simple représentant une catégorie de service.
class Categorie {
  /// L'identifiant unique de la catégorie.
  final int id;
  /// Le nom ou l'intitulé de la catégorie.
  final String intituleCategorie;

  /// Constructeur pour créer une instance de [Categorie].
  Categorie({
    required this.id,
    required this.intituleCategorie,
  });

  /// Crée une instance à partir d'une map JSON.
  /// Gère de manière flexible plusieurs noms de clés possibles pour l'ID et l'intitulé,
  /// assurant la robustesse face à des réponses d'API variées.
  factory Categorie.fromJson(Map<String, dynamic> json) {
    return Categorie(
      id: json['idTblCategorie'] ?? json['id'] ?? 0,
      intituleCategorie: json['intitule_categorie'] ?? json['nom'] ?? json['libelle'] ?? '',
    );
  }

  /// Convertit l'objet en map JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'intitule_categorie': intituleCategorie,
    };
  }

  /// Retourne directement l'intitulé, ce qui est très pratique pour l'affichage
  /// dans les widgets de l'interface utilisateur comme les `DropdownButton`.
  @override
  String toString() {
    return intituleCategorie;
  }

  /// Surcharge de l'opérateur d'égalité pour comparer deux instances de catégories.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Categorie &&
        other.id == id &&
        other.intituleCategorie == intituleCategorie;
  }

  /// Surcharge du hash code pour correspondre à l'opérateur d'égalité.
  @override
  int get hashCode => id.hashCode ^ intituleCategorie.hashCode;
}






// // Modèle pour la création d'un nouveau service
// class ServiceCreation {
//   final int userId;
//   final String intituleService;
//   final String description;
//   final double prix;
//   final int tempsMinutes;
//   final int categorieId;
//
//   ServiceCreation({
//     required this.userId,
//     required this.intituleService,
//     required this.description,
//     required this.prix,
//     required this.tempsMinutes,
//     required this.categorieId,
//   });
//
//   /// Convertit l'objet en Map pour l'envoi à l'API
//   Map<String, dynamic> toJson() {
//     return {
//       'userId': userId,
//       'intitule_service': intituleService,
//       'description': description,
//       'prix': prix,
//       'temps_minutes': tempsMinutes,
//       'categorie_id': categorieId,
//     };
//   }
//
//   /// Crée un objet ServiceCreation depuis un Map JSON
//   factory ServiceCreation.fromJson(Map<String, dynamic> json) {
//     return ServiceCreation(
//       userId: json['userId'] ?? 0,
//       intituleService: json['intitule_service'] ?? '',
//       description: json['description'] ?? '',
//       prix: (json['prix'] as num?)?.toDouble() ?? 0.0,
//       tempsMinutes: json['temps_minutes'] ?? 0,
//       categorieId: json['categorie_id'] ?? 0,
//     );
//   }
//
//   /// Validation des données avant envoi
//   String? validate() {
//     if (intituleService.trim().isEmpty) {
//       return 'Le nom du service est obligatoire';
//     }
//     if (intituleService.trim().length < 2) {
//       return 'Le nom doit contenir au moins 2 caractères';
//     }
//     if (description.trim().isEmpty) {
//       return 'La description est obligatoire';
//     }
//     if (prix <= 0) {
//       return 'Le prix doit être supérieur à 0';
//     }
//     if (tempsMinutes <= 0) {
//       return 'La durée doit être supérieure à 0';
//     }
//     if (categorieId <= 0) {
//       return 'Une catégorie doit être sélectionnée';
//     }
//     return null; // Pas d'erreur
//   }
//
//   /// Méthode pour créer une copie avec des valeurs modifiées
//   ServiceCreation copyWith({
//     int? userId,
//     String? intituleService,
//     String? description,
//     double? prix,
//     int? tempsMinutes,
//     int? categorieId,
//   }) {
//     return ServiceCreation(
//       userId: userId ?? this.userId,
//       intituleService: intituleService ?? this.intituleService,
//       description: description ?? this.description,
//       prix: prix ?? this.prix,
//       tempsMinutes: tempsMinutes ?? this.tempsMinutes,
//       categorieId: categorieId ?? this.categorieId,
//     );
//   }
//
//   @override
//   String toString() {
//     return 'ServiceCreation(userId: $userId, intituleService: $intituleService, description: $description, prix: $prix, tempsMinutes: $tempsMinutes, categorieId: $categorieId)';
//   }
//
//   @override
//   bool operator ==(Object other) {
//     if (identical(this, other)) return true;
//     return other is ServiceCreation &&
//         other.userId == userId &&
//         other.intituleService == intituleService &&
//         other.description == description &&
//         other.prix == prix &&
//         other.tempsMinutes == tempsMinutes &&
//         other.categorieId == categorieId;
//   }
//
//   @override
//   int get hashCode {
//     return userId.hashCode ^
//     intituleService.hashCode ^
//     description.hashCode ^
//     prix.hashCode ^
//     tempsMinutes.hashCode ^
//     categorieId.hashCode;
//   }
// }
//
// // Modèle pour les catégories de services
// class Categorie {
//   final int id;
//   final String intituleCategorie;
//
//   Categorie({
//     required this.id,
//     required this.intituleCategorie,
//   });
//
//   /// Crée un objet Categorie depuis un Map JSON
//   factory Categorie.fromJson(Map<String, dynamic> json) {
//     return Categorie(
//       id: json['idTblCategorie'] ?? json['id'] ?? 0,
//       intituleCategorie: json['intitule_categorie'] ?? json['nom'] ?? json['libelle'] ?? '',
//     );
//   }
//
//   /// Convertit l'objet en Map
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'intitule_categorie': intituleCategorie,
//     };
//   }
//
//   @override
//   String toString() {
//     return intituleCategorie;
//   }
//
//   @override
//   bool operator ==(Object other) {
//     if (identical(this, other)) return true;
//     return other is Categorie &&
//         other.id == id &&
//         other.intituleCategorie == intituleCategorie;
//   }
//
//   @override
//   int get hashCode => id.hashCode ^ intituleCategorie.hashCode;
// }