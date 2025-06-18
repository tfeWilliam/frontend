/****************************************************************************************
 *
 * MODÈLE DE DONNÉES : Service
 *
 * OBJECTIF :
 * Cette classe représente un service de salon de manière générique. Elle encapsule
 * toutes les informations pertinentes d'un service, y compris ses détails de base,
 * sa catégorie, et gère de manière intégrée une promotion optionnelle.
 *
 * FONCTIONNALITÉS CLÉS :
 * - Le modèle peut contenir un objet `Promotion` optionnel.
 * - La méthode `fromJson` est conçue pour être robuste :
 * - Elle gère de manière sécurisée le parsing de la promotion imbriquée.
 * - Elle calcule le prix final (`prixFinal`) directement côté client à partir
 * du prix de base et du pourcentage de la promotion.
 * - Inclut des méthodes et accesseurs utilitaires pour faciliter l'affichage
 * des données dans l'interface utilisateur (ex: `getCategoryDisplayName`).
 *
 *****************************************************************************************/
import 'package:hairbnb/models/promotion.dart';

/// Modèle représentant un service, avec gestion intégrée des promotions.
class Service {
  /// L'identifiant unique du service.
  final int id;
  /// Le nom ou l'intitulé du service.
  final String intitule;
  /// La description détaillée du service.
  final String description;
  /// Le prix de base du service, avant toute promotion.
  final double prix;
  /// La durée estimée du service, en minutes.
  final int temps;
  /// L'objet Promotion associé, s'il y en a un (peut être nul).
  final Promotion? promotion;
  /// Le prix final après application de la promotion (calculé côté client).
  final double prixFinal;
  /// L'identifiant de la catégorie du service (optionnel).
  final int? categorieId;
  /// Le nom de la catégorie du service (optionnel).
  final String? categorieNom;

  /// Constructeur pour créer une instance de [Service].
  Service({
    required this.id,
    required this.intitule,
    required this.description,
    required this.prix,
    required this.temps,
    this.promotion,
    required this.prixFinal,
    this.categorieId,
    this.categorieNom,
  });

  /// Construit une instance de [Service] à partir d'une map JSON.
  factory Service.fromJson(Map<String, dynamic> json) {
    // Conversion sécurisée du prix de base.
    double prixBase = 0.0;
    try {
      prixBase = (json['prix'] != null)
          ? double.parse(json['prix'].toString())
          : 0.0;
    } catch (e) { /* Ignore l'erreur pour ne pas bloquer le parsing */ }

    // Gère la promotion de manière sécurisée : si le parsing de la promotion échoue,
    // l'objet Service est quand même créé, mais sans promotion.
    Promotion? promo;
    if (json['promotion'] != null) {
      try {
        promo = Promotion.fromJson(json['promotion']);
      } catch (e) {
        promo = null;
      }
    }

    // Calcule le prix final côté client en appliquant le pourcentage de réduction.
    double prixReduit = prixBase;
    if (promo != null) {
      prixReduit = prixBase * (1 - (promo.pourcentage / 100));
      // Arrondit à 2 décimales pour éviter les erreurs de précision.
      prixReduit = double.parse(prixReduit.toStringAsFixed(2));
    }

    // Conversion sécurisée de l'ID.
    int idValue = 0;
    try {
      idValue = int.tryParse(json['idTblService']?.toString() ?? '0') ?? 0;
    } catch (e) { /* Ignore l'erreur */ }

    // Conversion sécurisée du temps.
    int tempsValue = 0;
    try {
      tempsValue = int.tryParse(json['temps_minutes']?.toString() ?? '0') ?? 0;
    } catch (e) { /* Ignore l'erreur */ }

    // Extraction sécurisée des données de catégorie.
    int? categorieIdValue;
    String? categorieNomValue;
    try {
      categorieIdValue = json['categorie_id'] != null
          ? int.tryParse(json['categorie_id'].toString())
          : null;
      categorieNomValue = json['categorie_nom']?.toString();
    } catch (e) { /* Ignore l'erreur */ }

    return Service(
      id: idValue,
      intitule: json['intitule_service'] ?? 'Nom indisponible',
      description: json['description'] ?? 'Aucune description',
      prix: prixBase,
      temps: tempsValue,
      promotion: promo,
      prixFinal: prixReduit,
      categorieId: categorieIdValue,
      categorieNom: categorieNomValue,
    );
  }

  /// Convertit l'objet [Service] en une map JSON pour l'envoyer à une API.
  Map<String, dynamic> toJson() {
    return {
      "intitule_service": intitule,
      "description": description,
      "prix": prix.toString(),
      "temps": temps.toString(),
      "promotion": promotion?.toJson(), // Inclut la promotion si elle existe.
      "categorie_id": categorieId,
      "categorie_nom": categorieNom,
    };
  }

  /// Retourne le prix final déjà calculé, incluant la réduction promotionnelle.
  double getPrixAvecReduction() {
    return prixFinal;
  }

  /// Vérifie si le service est associé à une catégorie.
  bool hasCategory() {
    return categorieId != null && categorieNom != null;
  }

  /// Retourne le nom de la catégorie pour l'affichage, avec une valeur par défaut.
  String getCategoryDisplayName() {
    return categorieNom ?? "Sans catégorie";
  }
}







// import 'package:hairbnb/models/promotion.dart';
//
// class Service {
//   final int id;
//   final String intitule;
//   final String description;
//   final double prix;
//   final int temps;
//   final Promotion? promotion; // Promotion peut être null
//   final double prixFinal; // Prix après promotion
//   final int? categorieId;
//   final String? categorieNom;
//
//   Service({
//     required this.id,
//     required this.intitule,
//     required this.description,
//     required this.prix,
//     required this.temps,
//     this.promotion,
//     required this.prixFinal,
//     // ✅ Paramètres catégories
//     this.categorieId,
//     this.categorieNom,
//   });
//
//   /// **✅ Convertir une réponse JSON en objet Service**
//   factory Service.fromJson(Map<String, dynamic> json) {
//     print("DEBUG: JSON Service reçu: $json");
//
//     // Conversion du prix
//     double prixBase = 0.0;
//     try {
//       prixBase = (json['prix'] != null)
//           ? double.parse(json['prix'].toString())
//           : 0.0;
//       print("DEBUG: Conversion prix: ${json['prix']} -> $prixBase");
//     } catch (e) {
//       print("❌ Erreur conversion prix: ${json['prix']}, error: $e");
//     }
//
//     // Vérification et conversion de la promotion
//     Promotion? promo;
//     if (json['promotion'] != null) {
//       try {
//         promo = Promotion.fromJson(json['promotion']);
//         print("DEBUG: Conversion promotion réussie: ${json['promotion']}");
//       } catch (e) {
//         print("❌ ++Model services++ Erreur conversion Promotion : $e");
//         promo = null;
//       }
//     } else {
//       print("DEBUG: Aucun champ promotion présent dans le JSON.");
//     }
//
//     // Calcul du prix final avec réduction (si promotion existante)
//     double prixReduit = prixBase;
//     if (promo != null) {
//       prixReduit = prixBase * (1 - (promo.pourcentage / 100));
//       // Arrondir à 2 décimales pour éviter les erreurs de précision
//       prixReduit = double.parse(prixReduit.toStringAsFixed(2));
//     }
//
//     print(
//         "DEBUG: Calcul du prix final: prixBase = $prixBase, pourcentage = ${promo?.pourcentage}, prixFinal = $prixReduit");
//
//     // Conversion de l'ID
//     int idValue = 0;
//     try {
//       idValue = int.tryParse(json['idTblService']?.toString() ?? '0') ?? 0;
//       print("DEBUG: Conversion id: ${json['idTblService']} -> $idValue");
//     } catch (e) {
//       print("❌ Erreur conversion id: ${json['idTblService']}, error: $e");
//     }
//
//     // Conversion du temps (en minutes)
//     int tempsValue = 0;
//     try {
//       tempsValue = int.tryParse(json['temps_minutes']?.toString() ?? '0') ?? 0;
//       print("DEBUG: Conversion temps: ${json['temps_minutes']} -> $tempsValue");
//     } catch (e) {
//       print("❌ Erreur conversion temps: ${json['temps_minutes']}, error: $e");
//     }
//
//     // ✅ Extraction des données de catégorie
//     int? categorieIdValue;
//     String? categorieNomValue;
//
//     try {
//       // Support pour les deux formats de réponse API
//       categorieIdValue = json['categorie_id'] != null
//           ? int.tryParse(json['categorie_id'].toString())
//           : null;
//       categorieNomValue = json['categorie_nom']?.toString();
//
//       print("DEBUG: Conversion catégorie: ID = $categorieIdValue, Nom = $categorieNomValue");
//     } catch (e) {
//       print("❌ Erreur conversion catégorie: $e");
//     }
//
//     return Service(
//       id: idValue,
//       intitule: json['intitule_service'] ?? 'Nom indisponible',
//       description: json['description'] ?? 'Aucune description',
//       prix: prixBase,
//       temps: tempsValue,
//       promotion: promo,
//       prixFinal: prixReduit,
//       // ✅ Ajout des champs catégorie
//       categorieId: categorieIdValue,
//       categorieNom: categorieNomValue,
//     );
//   }
//
//   /// **✅ Convertir un objet Service en JSON**
//   Map<String, dynamic> toJson() {
//     return {
//       "intitule_service": intitule,
//       "description": description,
//       "prix": prix.toString(),
//       "temps": temps.toString(),
//       "promotion": promotion?.toJson(), // Inclure la promotion si présente
//       "categorie_id": categorieId,
//       "categorie_nom": categorieNom,
//     };
//   }
//
//   /// **🔥 Retourne le prix après réduction si une promotion est active**
//   double getPrixAvecReduction() {
//     return prixFinal; // Utilisation du prix déjà calculé
//   }
//
//   /// **✅ Vérifie si le service a une catégorie**
//   bool hasCategory() {
//     return categorieId != null && categorieNom != null;
//   }
//
//   /// **✅ Retourne le nom de la catégorie ou "Sans catégorie"**
//   String getCategoryDisplayName() {
//     return categorieNom ?? "Sans catégorie";
//   }
// }