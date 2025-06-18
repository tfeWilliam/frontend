/****************************************************************************************
 *
 * MODÈLES DE DONNÉES : SERVICES DE SALON ET PROMOTIONS
 *
 * OBJECTIF :
 * Ce fichier définit les modèles de données pour représenter les services offerts
 * par un salon, avec un système robuste pour gérer les promotions associées.
 *
 * STRUCTURE DES CLASSES :
 * - SalonService : Le modèle principal pour un service, qui inclut tous ses
 * détails (prix, durée, catégorie) et peut contenir un objet de promotion.
 *
 * - SalonServicePromotion : Un modèle détaillé qui encapsule toutes les informations
 * d'une promotion spécifique appliquée à un service (pourcentage, économie, etc.).
 *
 * FONCTIONNALITÉS CLÉS :
 * - Contient de nombreux accesseurs (getters) pour formater les données pour l'UI
 * (ex: prix, durée) et pour encapsuler la logique métier (ex: hasPromotion).
 * - Utilise des méthodes de parsing sécurisées pour une conversion robuste depuis JSON.
 * - Surcharge les opérateurs `==` et `hashCode` dans `SalonService` pour permettre
 * des comparaisons d'objets fiables, ce qui est essentiel dans les listes et les sets.
 *
 *****************************************************************************************/

/// Modèle représentant les détails d'une promotion appliquée à un service.
class SalonServicePromotion {
  /// L'identifiant unique de la promotion.
  final int id;
  /// Le pourcentage de réduction offert.
  final double pourcentage;
  /// Le prix du service avant l'application de la promotion.
  final double prixOriginal;
  /// Le prix du service après l'application de la promotion.
  final double prixFinal;
  /// Le montant de l'économie réalisée grâce à la promotion.
  final double economie;
  /// La date de début de la promotion au format chaîne de caractères.
  final String dateDebut;
  /// La date de fin de la promotion au format chaîne de caractères.
  final String dateFin;
  /// Booléen indiquant si la promotion est actuellement active.
  final bool estActive;

  /// Constructeur pour créer une instance de [SalonServicePromotion].
  const SalonServicePromotion({
    required this.id,
    required this.pourcentage,
    required this.prixOriginal,
    required this.prixFinal,
    required this.economie,
    required this.dateDebut,
    required this.dateFin,
    required this.estActive,
  });

  /// Construit une instance de [SalonServicePromotion] à partir d'une map JSON.
  factory SalonServicePromotion.fromJson(Map<String, dynamic> json) {
    return SalonServicePromotion(
      id: _parseIntSafe(json['id']),
      pourcentage: _parseDoubleSafe(json['pourcentage']),
      prixOriginal: _parseDoubleSafe(json['prix_original']),
      prixFinal: _parseDoubleSafe(json['prix_final']),
      economie: _parseDoubleSafe(json['economie']),
      dateDebut: json['date_debut']?.toString() ?? '',
      dateFin: json['date_fin']?.toString() ?? '',
      estActive: json['est_active'] == true,
    );
  }

  /// Fonction d'aide privée et statique pour parser un `double` de manière sécurisée.
  static double _parseDoubleSafe(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Fonction d'aide privée et statique pour parser un `int` de manière sécurisée.
  static int _parseIntSafe(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Formate le pourcentage pour l'affichage (ex: "-20%").
  String get pourcentageFormate => "-${pourcentage.toStringAsFixed(0)}%";

  /// Formate le montant de l'économie pour l'affichage (ex: "Économisez 15€").
  String get economieFormatee => "Économisez ${economie.toStringAsFixed(0)}€";

  /// Fournit une représentation textuelle de l'objet pour le débogage.
  @override
  String toString() {
    return 'Promotion ${pourcentageFormate} (${economieFormatee})';
  }
}

/// Modèle principal représentant un service offert par un salon.
class SalonService {
  /// L'identifiant unique du service (table générique des services).
  final int idTblService;
  /// Le nom ou l'intitulé du service.
  final String intituleService;
  /// La description détaillée du service.
  final String description;
  /// L'identifiant de la catégorie du service.
  final int categorieId;
  /// Le nom de la catégorie du service.
  final String categorieNom;
  /// L'identifiant de l'association entre ce service et le salon.
  final int salonServiceId;
  /// Le prix de base du service.
  final double prix;
  /// Le prix final du service (peut être égal au prix de base ou au prix promotionnel).
  final double prixFinal;
  /// La durée estimée du service en minutes.
  final int dureeMinutes;
  /// L'objet de promotion associé à ce service (peut être nul s'il n'y a pas de promotion).
  final SalonServicePromotion? promotion;

  /// Constructeur pour créer une instance de [SalonService].
  const SalonService({
    required this.idTblService,
    required this.intituleService,
    required this.description,
    required this.categorieId,
    required this.categorieNom,
    required this.salonServiceId,
    required this.prix,
    required this.prixFinal,
    required this.dureeMinutes,
    this.promotion,
  });

  /// Construit une instance de [SalonService] à partir d'une map JSON.
  factory SalonService.fromJson(Map<String, dynamic> json) {
    // Tente de parser la promotion si elle est présente dans le JSON.
    SalonServicePromotion? promo;
    if (json['promotion'] != null) {
      promo = SalonServicePromotion.fromJson(json['promotion']);
    }

    return SalonService(
      idTblService: _parseIntSafe(json['idTblService']),
      intituleService: json['intitule_service']?.toString() ?? 'Service sans nom',
      description: json['description']?.toString() ?? 'Aucune description',
      categorieId: _parseIntSafe(json['categorie_id']),
      categorieNom: json['categorie_nom']?.toString() ?? 'Sans catégorie',
      salonServiceId: _parseIntSafe(json['salon_service_id']),
      prix: _parseDoubleSafe(json['prix']),
      prixFinal: _parseDoubleSafe(json['prix_final']),
      dureeMinutes: _parseIntSafe(json['duree_minutes']),
      promotion: promo,
    );
  }

  /// Fonction d'aide privée et statique pour parser un `int` de manière sécurisée.
  static int _parseIntSafe(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Fonction d'aide privée et statique pour parser un `double` de manière sécurisée.
  static double _parseDoubleSafe(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Convertit l'objet en map JSON, en incluant les détails pertinents de la promotion.
  Map<String, dynamic> toJson() {
    return {
      'idTblService': idTblService,
      'intitule_service': intituleService,
      'description': description,
      'categorie_id': categorieId,
      'categorie_nom': categorieNom,
      'salon_service_id': salonServiceId,
      'prix': prix,
      'prix_final': prixFinal,
      'duree_minutes': dureeMinutes,
      'promotion': promotion != null ? {
        'pourcentage': promotion!.pourcentage,
        'economie': promotion!.economie,
        'date_debut': promotion!.dateDebut,
        'date_fin': promotion!.dateFin,
      } : null,
    };
  }

  /// Accesseur (getter) qui vérifie si une promotion est active pour ce service.
  bool get hasPromotion => promotion != null && promotion!.estActive;

  /// Formate le prix original pour l'affichage (ex: "50€").
  String get prixFormate => "${prix.toStringAsFixed(0)}€";

  /// Formate le prix final (avec ou sans promotion) pour l'affichage.
  String get prixFinalFormate => "${prixFinal.toStringAsFixed(0)}€";

  /// Formate la durée en une chaîne de caractères lisible (ex: "45min", "1h", "1h30min").
  String get dureeFormatee {
    if (dureeMinutes < 60) {
      return "${dureeMinutes}min";
    } else {
      final heures = dureeMinutes ~/ 60;
      final minutes = dureeMinutes % 60;
      if (minutes == 0) {
        return "${heures}h";
      } else {
        return "${heures}h${minutes}min";
      }
    }
  }

  /// Vérifie si l'objet service contient les données minimales pour être considéré valide.
  bool get isValid {
    return idTblService > 0 &&
        intituleService.isNotEmpty &&
        prix > 0 &&
        dureeMinutes > 0;
  }

  /// Fournit une représentation textuelle concise de l'objet pour le débogage.
  @override
  String toString() {
    String promoInfo = hasPromotion ? " (${promotion!.pourcentageFormate})" : "";
    return 'SalonService(id: $idTblService, nom: "$intituleService", prix: $prixFinalFormate$promoInfo, durée: ${dureeMinutes}min)';
  }

  /// Surcharge de l'opérateur d'égalité.
  /// Deux instances de [SalonService] sont considérées comme égales si leur
  /// [idTblService] et [salonServiceId] sont identiques.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SalonService &&
        other.idTblService == idTblService &&
        other.salonServiceId == salonServiceId;
  }

  /// Surcharge du hash code pour correspondre à la logique de l'opérateur d'égalité.
  /// Assure que des objets égaux ont le même hash code.
  @override
  int get hashCode => Object.hash(idTblService, salonServiceId);
}





//
// /// Modèle pour les promotions d'un service dans un salon
// class SalonServicePromotion {
//   final int id;
//   final double pourcentage;
//   final double prixOriginal;
//   final double prixFinal;
//   final double economie;
//   final String dateDebut;
//   final String dateFin;
//   final bool estActive;
//
//   const SalonServicePromotion({
//     required this.id,
//     required this.pourcentage,
//     required this.prixOriginal,
//     required this.prixFinal,
//     required this.economie,
//     required this.dateDebut,
//     required this.dateFin,
//     required this.estActive,
//   });
//
//   factory SalonServicePromotion.fromJson(Map<String, dynamic> json) {
//     return SalonServicePromotion(
//       id: _parseIntSafe(json['id']),
//       pourcentage: _parseDoubleSafe(json['pourcentage']),
//       prixOriginal: _parseDoubleSafe(json['prix_original']),
//       prixFinal: _parseDoubleSafe(json['prix_final']),
//       economie: _parseDoubleSafe(json['economie']),
//       dateDebut: json['date_debut']?.toString() ?? '',  // ✅ AJOUT
//       dateFin: json['date_fin']?.toString() ?? '',
//       estActive: json['est_active'] == true,
//     );
//   }
//
//   static double _parseDoubleSafe(dynamic value) {
//     if (value == null) return 0.0;
//     if (value is double) return value;
//     if (value is int) return value.toDouble();
//     if (value is String) return double.tryParse(value) ?? 0.0;
//     return 0.0;
//   }
//
//   static int _parseIntSafe(dynamic value) {
//     if (value == null) return 0;
//     if (value is int) return value;
//     if (value is double) return value.toInt();
//     if (value is String) return int.tryParse(value) ?? 0;
//     return 0;
//   }
//
//   /// Formatage du pourcentage pour l'affichage
//   String get pourcentageFormate => "-${pourcentage.toStringAsFixed(0)}%";
//
//   /// Formatage de l'économie pour l'affichage
//   String get economieFormatee => "Économisez ${economie.toStringAsFixed(0)}€";
//
//   @override
//   String toString() {
//     return 'Promotion ${pourcentageFormate} (${economieFormatee})';
//   }
// }
//
// /// Modèle pour les services d'un salon spécifique avec gestion des promotions
// class SalonService {
//   final int idTblService;
//   final String intituleService;
//   final String description;
//   final int categorieId;
//   final String categorieNom;
//   final int salonServiceId;
//   final double prix;
//   final double prixFinal;
//   final int dureeMinutes;
//   final SalonServicePromotion? promotion;
//
//   const SalonService({
//     required this.idTblService,
//     required this.intituleService,
//     required this.description,
//     required this.categorieId,
//     required this.categorieNom,
//     required this.salonServiceId,
//     required this.prix,
//     required this.prixFinal,
//     required this.dureeMinutes,
//     this.promotion,
//   });
//
//   /// Créer un SalonService depuis la réponse JSON de l'API
//   factory SalonService.fromJson(Map<String, dynamic> json) {
//     try {
//       // Parser la promotion si elle existe
//       SalonServicePromotion? promo;
//       if (json['promotion'] != null) {
//         promo = SalonServicePromotion.fromJson(json['promotion']);
//       }
//
//       return SalonService(
//         idTblService: _parseIntSafe(json['idTblService']),
//         intituleService: json['intitule_service']?.toString() ?? 'Service sans nom',
//         description: json['description']?.toString() ?? 'Aucune description',
//         categorieId: _parseIntSafe(json['categorie_id']),
//         categorieNom: json['categorie_nom']?.toString() ?? 'Sans catégorie',
//         salonServiceId: _parseIntSafe(json['salon_service_id']),
//         prix: _parseDoubleSafe(json['prix']),
//         prixFinal: _parseDoubleSafe(json['prix_final']),
//         dureeMinutes: _parseIntSafe(json['duree_minutes']),
//         promotion: promo,
//       );
//     } catch (e) {
//       print("❌ Erreur parsing SalonService: $e");
//       print("🔍 JSON reçu: $json");
//       rethrow;
//     }
//   }
//
//   /// Helper pour parser les entiers de manière sécurisée
//   static int _parseIntSafe(dynamic value) {
//     if (value == null) return 0;
//     if (value is int) return value;
//     if (value is double) return value.toInt();
//     if (value is String) return int.tryParse(value) ?? 0;
//     return 0;
//   }
//
//   /// Helper pour parser les doubles de manière sécurisée
//   static double _parseDoubleSafe(dynamic value) {
//     if (value == null) return 0.0;
//     if (value is double) return value;
//     if (value is int) return value.toDouble();
//     if (value is String) return double.tryParse(value) ?? 0.0;
//     return 0.0;
//   }
//
//   /// Convertir en JSON pour les appels API
//   Map<String, dynamic> toJson() {
//     return {
//       'idTblService': idTblService,
//       'intitule_service': intituleService,
//       'description': description,
//       'categorie_id': categorieId,
//       'categorie_nom': categorieNom,
//       'salon_service_id': salonServiceId,
//       'prix': prix,
//       'prix_final': prixFinal,
//       'duree_minutes': dureeMinutes,
//       'promotion': promotion != null ? {
//         'pourcentage': promotion!.pourcentage,
//         'economie': promotion!.economie,
//         'date_debut': promotion!.dateDebut,  // ✅ AJOUT
//         'date_fin': promotion!.dateFin,
//       } : null,
//     };
//   }
//
//   /// Vérifier si le service a une promotion active
//   bool get hasPromotion => promotion != null && promotion!.estActive;
//
//   /// Formatage du prix original pour l'affichage
//   String get prixFormate => "${prix.toStringAsFixed(0)}€";
//
//   /// Formatage du prix final pour l'affichage (avec ou sans promotion)
//   String get prixFinalFormate => "${prixFinal.toStringAsFixed(0)}€";
//
//   /// Formatage de la durée pour l'affichage
//   String get dureeFormatee {
//     if (dureeMinutes < 60) {
//       return "${dureeMinutes}min";
//     } else {
//       final heures = dureeMinutes ~/ 60;
//       final minutes = dureeMinutes % 60;
//       if (minutes == 0) {
//         return "${heures}h";
//       } else {
//         return "${heures}h${minutes}min";
//       }
//     }
//   }
//
//
//
//   /// Vérifier si le service est valide
//   bool get isValid {
//     return idTblService > 0 &&
//         intituleService.isNotEmpty &&
//         prix > 0 &&
//         dureeMinutes > 0;
//   }
//
//   @override
//   String toString() {
//     String promoInfo = hasPromotion ? " (${promotion!.pourcentageFormate})" : "";
//     return 'SalonService(id: $idTblService, nom: "$intituleService", prix: $prixFinalFormate$promoInfo, durée: ${dureeMinutes}min)';
//   }
//
//   @override
//   bool operator ==(Object other) {
//     if (identical(this, other)) return true;
//     return other is SalonService &&
//         other.idTblService == idTblService &&
//         other.salonServiceId == salonServiceId;
//   }
//
//   @override
//   int get hashCode => Object.hash(idTblService, salonServiceId);
// }