import 'package:flutter/foundation.dart';

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                 MODÈLE DE DONNÉES POUR UNE CATÉGORIE DE SERVICE              //
//                                                                            //
//  Ce fichier définit le modèle `Categorie`, qui représente une catégorie    //
//  de service (par exemple, "Coupe Homme", "Coloration", "Soin Capillaire").  //
//  Cette classe est utilisée pour organiser et regrouper les services dans    //
//  l'application.                                                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


class Categorie {
  /// L'identifiant unique de la catégorie.
  final int id;
  /// Le nom ou l'intitulé de la catégorie.
  final String nom;
  /// Une description détaillée de ce que la catégorie englobe.
  final String description;

  /// Constructeur principal pour créer une instance de `Categorie`.
  Categorie({
    required this.id,
    required this.nom,
    required this.description,
  });

  /// Factory constructor pour créer une instance de `Categorie` à partir d'un map JSON.
  ///
  /// Cette méthode est conçue pour être robuste et gérer différents types de données
  /// potentiellement reçus de l'API (par exemple, un ID sous forme de String ou d'int).
  factory Categorie.fromJson(Map<String, dynamic> json) {
    int categorieId = 0;
    String nom = 'Catégorie sans nom';
    final String description = json['description']?.toString() ?? '';

    // Bloc de conversion sécurisé pour l'identifiant de la catégorie.
    try {
      final idValue = json['idTblCategorie'];
      if (idValue != null) {
        // Gère les cas où l'ID est un entier, une chaîne de caractères, ou un autre type.
        if (idValue is int) {
          categorieId = idValue;
        } else {
          categorieId = int.parse(idValue.toString());
        }
      }
    } catch (e) {
      // En cas d'erreur de conversion, l'ID reste à sa valeur par défaut (0).
      if (kDebugMode) {
        print("Erreur lors de la conversion de l'ID de la catégorie: $e");
      }
    }

    // Bloc de conversion sécurisé pour le nom de la catégorie.
    try {
      final nomValue = json['intitule_categorie'];
      if (nomValue != null) {
        nom = nomValue.toString();
      }
    } catch (e) {
      // En cas d'erreur, le nom conserve sa valeur par défaut.
      if (kDebugMode) {
        print("Erreur lors de la conversion du nom de la catégorie: $e");
      }
    }

    // Retourne la nouvelle instance de Categorie avec les données nettoyées.
    return Categorie(
      id: categorieId,
      nom: nom,
      description: description,
    );
  }

  /// Convertit l'instance de `Categorie` en un map JSON.
  ///
  /// Utilise les noms de clés attendus par l'API backend pour la sérialisation.
  Map<String, dynamic> toJson() {
    return {
      'idTblCategorie': id,
      'intitule_categorie': nom,
      'description': description,
    };
  }

  /// Fournit une représentation textuelle de l'objet pour faciliter le débogage.
  @override
  String toString() {
    return 'Categorie(id: $id, nom: "$nom", description: "$description")';
  }
}



// class Categorie {
//   final int id;
//   final String nom;
//   final String description;
//
//   Categorie({
//     required this.id,
//     required this.nom,
//     required this.description,
//   });
//
//   factory Categorie.fromJson(Map<String, dynamic> json) {
//     print("🔍 DEBUG CATEGORIE: JSON brut reçu: $json");
//     print("🔍 DEBUG CATEGORIE: Type de json: ${json.runtimeType}");
//     print("🔍 DEBUG CATEGORIE: Clés disponibles: ${json.keys.toList()}");
//
//     // ✅ Récupération de l'ID avec debug détaillé
//     int categorieId = 0;
//     try {
//       final idValue = json['idTblCategorie'];
//       print("🔍 DEBUG CATEGORIE: Valeur idTblCategorie: $idValue (type: ${idValue.runtimeType})");
//
//       if (idValue != null) {
//         if (idValue is int) {
//           categorieId = idValue;
//         } else if (idValue is String) {
//           categorieId = int.parse(idValue);
//         } else {
//           categorieId = int.parse(idValue.toString());
//         }
//         print("✅ ID converti avec succès: $categorieId");
//       } else {
//         print("❌ idTblCategorie est null !");
//       }
//     } catch (e) {
//       print("❌ ERREUR conversion ID catégorie: $e");
//       print("❌ Valeur brute: ${json['idTblCategorie']}");
//     }
//
//     // ✅ Récupération du nom avec debug détaillé
//     String nom = '';
//     try {
//       final nomValue = json['intitule_categorie'];
//       print("🔍 DEBUG CATEGORIE: Valeur intitule_categorie: $nomValue (type: ${nomValue.runtimeType})");
//
//       if (nomValue != null) {
//         nom = nomValue.toString();
//         print("✅ Nom converti avec succès: '$nom'");
//       } else {
//         nom = 'Catégorie sans nom';
//         print("⚠️ intitule_categorie est null, utilisation du nom par défaut");
//       }
//     } catch (e) {
//       print("❌ ERREUR conversion nom catégorie: $e");
//       nom = 'Erreur nom';
//     }
//
//     final description = json['description']?.toString() ?? '';
//
//     print("🎯 CATEGORIE CONSTRUITE: ID=$categorieId, Nom='$nom', Description='$description'");
//
//     final categorie = Categorie(
//       id: categorieId,
//       nom: nom,
//       description: description,
//     );
//
//     print("🎯 VERIFICATION FINALE: categorie.id=${categorie.id}, categorie.nom='${categorie.nom}'");
//
//     return categorie;
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'idTblCategorie': id,
//       'intitule_categorie': nom,
//       'description': description,
//     };
//   }
//
//   @override
//   String toString() {
//     return 'Categorie(id: $id, nom: "$nom", description: "$description")';
//   }
// }
