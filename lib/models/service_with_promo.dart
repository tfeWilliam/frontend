/****************************************************************************************
 *
 * MODÈLE DE DONNÉES : SERVICE AVEC GESTION DE PROMOTIONS
 * Fichier: models/service_with_promo.dart
 *
 * OBJECTIF :
 * Cette classe représente un modèle de données "riche" pour un service de salon.
 * Elle agrège non seulement les détails du service lui-même, mais aussi l'ensemble
 * de ses promotions associées, qu'elles soient actives, futures ou expirées.
 *
 * FONCTIONNALITÉS CLÉS :
 * - Gestion complète des promotions : Sépare les promotions en trois listes
 * distinctes pour une manipulation aisée.
 * - Méthodes utilitaires : Contient de nombreuses méthodes et accesseurs (getters) pour
 * encapsuler la logique métier (ex: `hasActivePromotion`, `getNextPromotion`).
 * - Parsing robuste : La méthode `fromJson` est conçue pour être très résiliente,
 * gérant des données JSON potentiellement manquantes ou inconsistantes, notamment
 * pour la durée du service où une estimation est faite si aucune valeur n'est trouvée.
 * - Immuabilité : Inclut une méthode `copyWith` pour une gestion d'état immuable.
 * - Égalité personnalisée : Surcharge les opérateurs `==` et `hashCode` pour définir
 * une égalité logique basée sur l'ID du service et l'ID du salon.
 *
 *****************************************************************************************/
import 'package:hairbnb/models/promotion_full.dart';

/// Modèle de données complet représentant un service et l'ensemble de ses promotions.
class ServiceWithPromo {
  /// L'identifiant unique du service.
  final int id;
  /// Le nom ou l'intitulé du service.
  final String intitule;
  /// La description détaillée du service.
  final String description;
  /// La durée estimée du service en minutes.
  final int temps;
  /// Le prix de base du service, hors promotion.
  final double prix;
  /// L'identifiant de la catégorie du service (optionnel).
  final int? categoryId;
  /// Le nom de la catégorie du service (optionnel).
  final String? categoryName;
  /// L'identifiant du salon qui propose ce service.
  final int salonId;
  /// Le nom du salon qui propose ce service (optionnel).
  final String? salonNom;
  /// La promotion actuellement active pour ce service (s'il y en a une).
  final PromotionFull? promotion_active;
  /// La liste des promotions futures pour ce service.
  final List<PromotionFull> promotions_a_venir;
  /// La liste des promotions expirées pour ce service.
  final List<PromotionFull> promotions_expirees;
  /// Le prix final du service, incluant la réduction de la promotion active.
  final double prix_final;

  /// Constructeur pour créer une instance de [ServiceWithPromo].
  ServiceWithPromo({
    required this.id,
    required this.intitule,
    required this.description,
    required this.temps,
    required this.prix,
    this.categoryId,
    this.categoryName,
    required this.salonId,
    this.salonNom,
    this.promotion_active,
    required this.promotions_a_venir,
    required this.promotions_expirees,
    required this.prix_final,
  });

  /// Retourne le prix final après application de la réduction.
  double getPrixAvecReduction() => prix_final;
  /// Calcule et retourne le montant total économisé grâce à la promotion active.
  double getMontantEconomise() => prix - prix_final;
  /// Vérifie si une promotion est actuellement active sur ce service.
  bool hasActivePromotion() => promotion_active != null;
  /// Retourne le pourcentage de la promotion active, ou null s'il n'y en a pas.
  double? getCurrentDiscountPercentage() => promotion_active?.pourcentage;

  /// Retourne une liste unique contenant toutes les promotions (actives, futures, expirées).
  List<PromotionFull> getAllPromotions() {
    List<PromotionFull> allPromotions = [];
    if (promotion_active != null) {
      allPromotions.add(promotion_active!);
    }
    allPromotions.addAll(promotions_a_venir);
    allPromotions.addAll(promotions_expirees);
    return allPromotions;
  }

  /// Retourne le nombre total de promotions associées à ce service.
  int getTotalPromotionsCount() => getAllPromotions().length;
  /// Vérifie s'il y a des promotions programmées pour le futur.
  bool hasFuturePromotions() => promotions_a_venir.isNotEmpty;

  /// Recherche et retourne la promotion à venir la plus proche dans le temps.
  PromotionFull? getNextPromotion() {
    if (promotions_a_venir.isEmpty) return null;
    promotions_a_venir.sort((a, b) => a.dateDebut.compareTo(b.dateDebut));
    return promotions_a_venir.first;
  }

  /// Vérifie si le service appartient à une catégorie spécifique.
  bool belongsToCategory(int categoryIdToCheck) => categoryId == categoryIdToCheck;
  /// Vérifie si le service est associé à une catégorie.
  bool hasCategory() => categoryId != null;
  /// Vérifie si le service appartient à un salon spécifique.
  bool belongsToSalon(int salonIdToCheck) => salonId == salonIdToCheck;

  /// Construit une instance de [ServiceWithPromo] à partir d'une map JSON.
  /// [parentSalonId] et [parentSalonNom] peuvent être fournis pour forcer l'association
  /// à un salon, utile lors du parsing d'une liste de services d'un même salon.
  factory ServiceWithPromo.fromJson(Map<String, dynamic> json, {int? parentSalonId, String? parentSalonNom}) {
    PromotionFull? activePromo;
    List<PromotionFull> futurePromos = [];
    List<PromotionFull> expiredPromos = [];

    // Tente de parser les promotions de manière sécurisée.
    if (json['promotion_active'] != null) {
      try {
        activePromo = PromotionFull.fromJson(json['promotion_active']);
      } catch (e) { /* Ignore les erreurs de parsing pour ne pas bloquer tout l'objet */ }
    }
    if (json['promotions_a_venir'] != null) {
      try {
        futurePromos = (json['promotions_a_venir'] as List)
            .map((promoJson) => PromotionFull.fromJson(promoJson))
            .toList();
      } catch (e) { /* Ignore les erreurs de parsing */ }
    }
    if (json['promotions_expirees'] != null) {
      try {
        expiredPromos = (json['promotions_expirees'] as List)
            .map((promoJson) => PromotionFull.fromJson(promoJson))
            .toList();
      } catch (e) { /* Ignore les erreurs de parsing */ }
    }

    // Logique pour déterminer l'ID et le nom du salon.
    // Priorité au salon parent fourni, sinon recherche dans le JSON du service.
    int finalSalonId;
    String? finalSalonNom;
    if (parentSalonId != null) {
      finalSalonId = parentSalonId;
      finalSalonNom = parentSalonNom;
    } else {
      finalSalonId = json['salon_id'] ?? json['idTblSalon'] ?? 0;
      finalSalonNom = json['salon_nom'] ?? json['nom_salon'];
    }

    // Logique de parsing robuste pour la durée, essayant plusieurs clés JSON possibles.
    int finalTemps = 0;
    var tempsValue = json['temps_minutes'] ?? json['temps'] ?? json['duree'] ?? json['duration'] ?? json['duree_minutes'] ?? json['temps_service'] ?? json['duree_service'];
    if (tempsValue != null) {
      if (tempsValue is int) {
        finalTemps = tempsValue;
      } else if (tempsValue is String) {
        finalTemps = int.tryParse(tempsValue) ?? 0;
      }
    }

    // Si aucune durée n'est trouvée, une estimation est faite en fonction du nom du service.
    if (finalTemps <= 0) {
      String serviceName = (json['intitule_service'] ?? '').toLowerCase();
      if (serviceName.contains('coupe') || serviceName.contains('shampooing')) {
        finalTemps = 30;
      } else if (serviceName.contains('couleur') || serviceName.contains('coloration')) {
        finalTemps = 120;
      } else if (serviceName.contains('permanente') || serviceName.contains('lissage')) {
        finalTemps = 180;
      } else if (serviceName.contains('brushing')) {
        finalTemps = 45;
      } else if (serviceName.contains('massage')) {
        finalTemps = 60;
      } else {
        finalTemps = 45; // Valeur par défaut générale
      }
    }

    return ServiceWithPromo(
      id: json['idTblService'] ?? 0,
      intitule: json['intitule_service'] ?? '',
      description: json['description'] ?? '',
      temps: finalTemps,
      prix: json['prix'] != null ? double.tryParse(json['prix'].toString()) ?? 0.0 : 0.0,
      categoryId: json['category_id'],
      categoryName: json['category_name'],
      salonId: finalSalonId,
      salonNom: finalSalonNom,
      promotion_active: activePromo,
      promotions_a_venir: futurePromos,
      promotions_expirees: expiredPromos,
      prix_final: json['prix_final'] != null ? double.tryParse(json['prix_final'].toString()) ?? 0.0 : 0.0,
    );
  }

  /// Convertit l'objet en une map JSON pour la sérialisation.
  Map<String, dynamic> toJson() {
    return {
      'idTblService': id,
      'intitule_service': intitule,
      'description': description,
      'temps_minutes': temps,
      'prix': prix,
      'category_id': categoryId,
      'category_name': categoryName,
      'salon_id': salonId,
      'salon_nom': salonNom,
      'promotion_active': promotion_active?.toJson(),
      'promotions_a_venir': promotions_a_venir.map((p) => p.toJson()).toList(),
      'promotions_expirees': promotions_expirees.map((p) => p.toJson()).toList(),
      'prix_final': prix_final,
    };
  }

  /// Crée une copie de l'objet avec des valeurs potentiellement modifiées.
  ServiceWithPromo copyWith({
    int? id,
    String? intitule,
    String? description,
    int? temps,
    double? prix,
    int? categoryId,
    String? categoryName,
    int? salonId,
    String? salonNom,
    PromotionFull? promotion_active,
    List<PromotionFull>? promotions_a_venir,
    List<PromotionFull>? promotions_expirees,
    double? prix_final,
  }) {
    return ServiceWithPromo(
      id: id ?? this.id,
      intitule: intitule ?? this.intitule,
      description: description ?? this.description,
      temps: temps ?? this.temps,
      prix: prix ?? this.prix,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      salonId: salonId ?? this.salonId,
      salonNom: salonNom ?? this.salonNom,
      promotion_active: promotion_active ?? this.promotion_active,
      promotions_a_venir: promotions_a_venir ?? this.promotions_a_venir,
      promotions_expirees: promotions_expirees ?? this.promotions_expirees,
      prix_final: prix_final ?? this.prix_final,
    );
  }

  /// Fournit une représentation textuelle de l'objet pour le débogage.
  @override
  String toString() {
    return 'ServiceWithPromo(id: $id, intitule: $intitule, salonId: $salonId, prix: $prix, prix_final: $prix_final)';
  }

  /// Surcharge des opérateurs pour définir l'égalité basée sur la combinaison de
  /// l'ID du service et de l'ID du salon, identifiant un service unique dans un salon.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServiceWithPromo && other.id == id && other.salonId == salonId;
  }

  /// Surcharge du hash code pour correspondre à la logique de l'opérateur d'égalité.
  @override
  int get hashCode => id.hashCode ^ salonId.hashCode;
}




// // Fichier: models/service_with_promo.dart
// import 'package:hairbnb/models/promotion_full.dart';
//
// class ServiceWithPromo {
//   final int id;
//   final String intitule;
//   final String description;
//   final int temps;
//   final double prix;
//   final int? categoryId;
//   final String? categoryName;
//   final int salonId;
//   final String? salonNom;
//   final PromotionFull? promotion_active;
//   final List<PromotionFull> promotions_a_venir;
//   final List<PromotionFull> promotions_expirees;
//   final double prix_final;
//
//   ServiceWithPromo({
//     required this.id,
//     required this.intitule,
//     required this.description,
//     required this.temps,
//     required this.prix,
//     this.categoryId,
//     this.categoryName,
//     required this.salonId,
//     this.salonNom,
//     this.promotion_active,
//     required this.promotions_a_venir,
//     required this.promotions_expirees,
//     required this.prix_final,
//   });
//
//   double getPrixAvecReduction() => prix_final;
//   double getMontantEconomise() => prix - prix_final;
//   bool hasActivePromotion() => promotion_active != null;
//   double? getCurrentDiscountPercentage() => promotion_active?.pourcentage;
//
//   List<PromotionFull> getAllPromotions() {
//     List<PromotionFull> allPromotions = [];
//     if (promotion_active != null) {
//       allPromotions.add(promotion_active!);
//     }
//     allPromotions.addAll(promotions_a_venir);
//     allPromotions.addAll(promotions_expirees);
//     return allPromotions;
//   }
//
//   int getTotalPromotionsCount() => getAllPromotions().length;
//   bool hasFuturePromotions() => promotions_a_venir.isNotEmpty;
//
//   PromotionFull? getNextPromotion() {
//     if (promotions_a_venir.isEmpty) return null;
//     promotions_a_venir.sort((a, b) => a.dateDebut.compareTo(b.dateDebut));
//     return promotions_a_venir.first;
//   }
//
//   bool belongsToCategory(int categoryIdToCheck) => categoryId == categoryIdToCheck;
//   bool hasCategory() => categoryId != null;
//   bool belongsToSalon(int salonIdToCheck) => salonId == salonIdToCheck;
//
//   // 🔥 MODIFICATION SIMPLE : Ajouter salonId optionnel en paramètre
//   factory ServiceWithPromo.fromJson(Map<String, dynamic> json, {int? parentSalonId, String? parentSalonNom}) {
//     PromotionFull? activePromo;
//     List<PromotionFull> futurePromos = [];
//     List<PromotionFull> expiredPromos = [];
//
//     // 🔍 DEBUG - Affichage du JSON pour diagnostic
//     print("🧩 ServiceWithPromo.fromJson - JSON reçu: $json");
//
//     if (json['promotion_active'] != null) {
//       try {
//         activePromo = PromotionFull.fromJson(json['promotion_active']);
//       } catch (e) {
//         print('❌ Erreur promotion_active: $e');
//       }
//     }
//
//     if (json['promotions_a_venir'] != null) {
//       try {
//         futurePromos = (json['promotions_a_venir'] as List)
//             .map((promoJson) => PromotionFull.fromJson(promoJson))
//             .toList();
//       } catch (e) {
//         print('❌ Erreur promotions_a_venir: $e');
//       }
//     }
//
//     if (json['promotions_expirees'] != null) {
//       try {
//         expiredPromos = (json['promotions_expirees'] as List)
//             .map((promoJson) => PromotionFull.fromJson(promoJson))
//             .toList();
//       } catch (e) {
//         print('❌ Erreur promotions_expirees: $e');
//       }
//     }
//
//     // 🔥 LOGIQUE SIMPLE : Utiliser parentSalonId si fourni, sinon chercher dans le JSON
//     int finalSalonId;
//     String? finalSalonNom;
//
//     if (parentSalonId != null) {
//       finalSalonId = parentSalonId;
//       finalSalonNom = parentSalonNom;
//     } else {
//       finalSalonId = json['salon_id'] ?? json['idTblSalon'] ?? 0;
//       finalSalonNom = json['salon_nom'] ?? json['nom_salon'];
//
//       if (finalSalonId == 0) {
//         print('⚠️ WARNING: Aucun salonId valide trouvé pour le service ${json['idTblService']}');
//       }
//     }
//
//     // 🛡️ CORRECTION PRINCIPALE - Gestion robuste du temps
//     int finalTemps = 0;
//
//     // Essayer plusieurs noms de champs possibles pour la durée
//     var tempsValue = json['temps_minutes'] ??
//         json['temps'] ??
//         json['duree'] ??
//         json['duration'] ??
//         json['duree_minutes'] ??
//         json['temps_service'] ??
//         json['duree_service'];
//
//     if (tempsValue != null) {
//       if (tempsValue is int) {
//         finalTemps = tempsValue;
//       } else if (tempsValue is String) {
//         finalTemps = int.tryParse(tempsValue) ?? 0;
//       } else {
//         finalTemps = 0;
//       }
//     }
//
//     // 🔍 DEBUG - Log des valeurs trouvées
//     print("🕒 Temps pour service ${json['intitule_service'] ?? 'Unknown'}: $finalTemps minutes");
//     print("   - Champs temps trouvés dans JSON: ${json.keys.where((k) => k.toLowerCase().contains('temps') || k.toLowerCase().contains('duree')).toList()}");
//
//     // Si aucune durée trouvée, utiliser une valeur par défaut basée sur le type de service
//     if (finalTemps <= 0) {
//       String serviceName = (json['intitule_service'] ?? '').toLowerCase();
//
//       // Estimation intelligente basée sur le nom du service
//       if (serviceName.contains('coupe') || serviceName.contains('shampooing')) {
//         finalTemps = 30;
//       } else if (serviceName.contains('couleur') || serviceName.contains('coloration')) {
//         finalTemps = 120;
//       } else if (serviceName.contains('permanente') || serviceName.contains('lissage')) {
//         finalTemps = 180;
//       } else if (serviceName.contains('brushing')) {
//         finalTemps = 45;
//       } else if (serviceName.contains('massage')) {
//         finalTemps = 60;
//       } else {
//         finalTemps = 45; // Valeur par défaut générale
//       }
//
//       print("⚠️ Temps non trouvé pour '${json['intitule_service']}', utilisation de $finalTemps min par défaut");
//     }
//
//     return ServiceWithPromo(
//       id: json['idTblService'] ?? 0,
//       intitule: json['intitule_service'] ?? '',
//       description: json['description'] ?? '',
//       temps: finalTemps, // 🛡️ Utilisation de la valeur calculée
//       prix: json['prix'] != null ? double.tryParse(json['prix'].toString()) ?? 0.0 : 0.0,
//       categoryId: json['category_id'],
//       categoryName: json['category_name'],
//       salonId: finalSalonId,
//       salonNom: finalSalonNom,
//       promotion_active: activePromo,
//       promotions_a_venir: futurePromos,
//       promotions_expirees: expiredPromos,
//       prix_final: json['prix_final'] != null ? double.tryParse(json['prix_final'].toString()) ?? 0.0 : 0.0,
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'idTblService': id,
//       'intitule_service': intitule,
//       'description': description,
//       'temps_minutes': temps,
//       'prix': prix,
//       'category_id': categoryId,
//       'category_name': categoryName,
//       'salon_id': salonId,
//       'salon_nom': salonNom,
//       'promotion_active': promotion_active?.toJson(),
//       'promotions_a_venir': promotions_a_venir.map((p) => p.toJson()).toList(),
//       'promotions_expirees': promotions_expirees.map((p) => p.toJson()).toList(),
//       'prix_final': prix_final,
//     };
//   }
//
//   ServiceWithPromo copyWith({
//     int? id,
//     String? intitule,
//     String? description,
//     int? temps,
//     double? prix,
//     int? categoryId,
//     String? categoryName,
//     int? salonId,
//     String? salonNom,
//     PromotionFull? promotion_active,
//     List<PromotionFull>? promotions_a_venir,
//     List<PromotionFull>? promotions_expirees,
//     double? prix_final,
//   }) {
//     return ServiceWithPromo(
//       id: id ?? this.id,
//       intitule: intitule ?? this.intitule,
//       description: description ?? this.description,
//       temps: temps ?? this.temps,
//       prix: prix ?? this.prix,
//       categoryId: categoryId ?? this.categoryId,
//       categoryName: categoryName ?? this.categoryName,
//       salonId: salonId ?? this.salonId,
//       salonNom: salonNom ?? this.salonNom,
//       promotion_active: promotion_active ?? this.promotion_active,
//       promotions_a_venir: promotions_a_venir ?? this.promotions_a_venir,
//       promotions_expirees: promotions_expirees ?? this.promotions_expirees,
//       prix_final: prix_final ?? this.prix_final,
//     );
//   }
//
//   @override
//   String toString() {
//     return 'ServiceWithPromo(id: $id, intitule: $intitule, salonId: $salonId, prix: $prix, prix_final: $prix_final)';
//   }
//
//   @override
//   bool operator ==(Object other) {
//     if (identical(this, other)) return true;
//     return other is ServiceWithPromo && other.id == id && other.salonId == salonId;
//   }
//
//   @override
//   int get hashCode => id.hashCode ^ salonId.hashCode;
// }
