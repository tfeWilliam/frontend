/// *************************************************************************************************
///
/// BANNER : EXPLICATION GÉNÉRALE DE LA CLASSE DE SERVICE
///
/// Ce fichier définit la classe `PromotionService`.
///
/// Objectif :
/// Cette classe sert de couche de logique métier (business logic) entre l'interface
/// utilisateur (UI) et la couche d'accès aux données (`PromotionApi`). Elle orchestre
/// les opérations, transforme les données brutes de l'API en modèles de données
/// structurés, et fournit des fonctions utilitaires pour la gestion des promotions.
///
/// Responsabilités :
/// - Récupérer et mapper les services d'une coiffeuse en objets `ServiceWithPromo`.
/// - Gérer la suppression d'une promotion en encapsulant l'appel API.
/// - Agréger et trier les promotions d'un service pour un affichage unifié.
/// - Fournir des méthodes pour déterminer le statut d'une promotion (Active, À venir).
///
///*************************************************************************************************
library;

import '../../../../../models/promotion_full.dart';
import '../../../../../models/service_with_promo.dart';
import '../api/promotion_api.dart';

/// Classe de service qui gère la logique métier pour les services et promotions.
class PromotionService {
  /// Récupère les services d'une coiffeuse et les transforme en une liste d'objets `ServiceWithPromo`.
  ///
  /// [coiffeuseId] : L'identifiant de la coiffeuse dont on veut les services.
  ///
  /// Cette méthode appelle l'API, traite la structure JSON de la réponse (qui peut être
  /// imbriquée), et mappe chaque service en un objet `ServiceWithPromo`, en injectant
  /// les informations du salon parent dans chaque service.
  ///
  /// Retourne une `Map` contenant :
  /// - `services`: Une `List<ServiceWithPromo>` si la requête réussit.
  /// - `totalCount`: Le nombre total de services.
  /// - `error`: Un message d'erreur si une erreur survient.
  static Future<Map<String, dynamic>> getServices(String coiffeuseId) async {
    try {
      // Délègue l'appel réseau à la classe API.
      final result = await PromotionApi.getServicesByCoiffeuse(coiffeuseId);

      // Si l'API retourne une erreur, on la propage.
      if (result['error'] != null) {
        return {'services': null, 'error': result['error']};
      }

      final data = result['data'];

      // Gère la structure potentiellement imbriquée de la réponse API pour trouver les données du salon.
      Map<String, dynamic> salonData;
      if (data.containsKey('results')) {
        // Cas où les données sont sous une clé 'results' (pagination, etc.).
        salonData = data['results']['salon'];
      } else {
        // Cas où les données du salon sont à la racine.
        salonData = data['salon'];
      }

      // Extrait les informations du salon avec des valeurs de repli pour plus de robustesse.
      final int salonId = salonData['idTblSalon'] ?? salonData['id'] ?? 0;
      final String? salonNom = salonData['nom_salon'] ?? salonData['nom'] ?? salonData['name'];


      // Récupère la liste des services depuis les données du salon.
      final serviceList = salonData['services'] ?? [];

      // Mappe chaque élément JSON de la liste de services en un objet `ServiceWithPromo`.
      // Crucial : `parentSalonId` et `parentSalonNom` sont passés au constructeur pour
      // que chaque service connaisse son salon parent.
      final List<ServiceWithPromo> services = (serviceList as List)
          .map((json) => ServiceWithPromo.fromJson(
        json,
        parentSalonId: salonId,
        parentSalonNom: salonNom,
      ))
          .toList();

      // Retourne une structure de données propre pour la couche UI.
      return {
        'services': services,
        'totalCount': data['count'] ?? services.length,
        'error': null,
      };
    } catch (e) {

      return {'services': null, 'error': 'Erreur lors du traitement des services: $e'};
    }
  }

  /// Gère la suppression d'une promotion et retourne un résultat structuré.
  ///
  /// [promotionId] : L'identifiant de la promotion à supprimer.
  /// Retourne une `Map` indiquant le succès ou l'échec de l'opération.
  static Future<Map<String, dynamic>> deletePromotion(int promotionId) async {
    try {
      // Délègue l'appel de suppression à la classe API.
      final bool success = await PromotionApi.deletePromotion(promotionId);

      return success
          ? {'success': true, 'message': '✅ Promotion supprimée avec succès'}
          : {'success': false, 'error': '❌ Impossible de supprimer la promotion.'};
    } catch (e) {
      return {
        'success': false,
        'error': '🚨 Une erreur est survenue : ${e.toString()}',
      };
    }
  }

  /// Regroupe toutes les promotions (active, à venir, expirées) d'un service en une seule liste triée.
  ///
  /// [service] : Le service dont on veut agréger les promotions.
  /// Retourne une `Map` avec la liste des promotions ou une erreur.
  static Future<Map<String, dynamic>> getAllPromotionsForService(ServiceWithPromo service) async {
    try {
      List<PromotionFull> allPromotions = [];

      // Ajoute la promotion active, si elle existe.
      if (service.promotion_active != null) {
        allPromotions.add(service.promotion_active!);
      }
      // Ajoute toutes les promotions à venir.
      if (service.promotions_a_venir.isNotEmpty) {
        allPromotions.addAll(service.promotions_a_venir);
      }
      // Ajoute toutes les promotions expirées.
      if (service.promotions_expirees.isNotEmpty) {
        allPromotions.addAll(service.promotions_expirees);
      }

      // Trie la liste fusionnée selon les règles définies (active > à venir > expirée).
      _sortPromotions(allPromotions);

      return {'promotions': allPromotions, 'error': null};
    } catch (e) {
      return {'promotions': [], 'error': 'Erreur lors de la fusion des promotions: $e'};
    }
  }

  /// Vérifie si une promotion est actuellement en cours.
  ///
  /// [promotion] : La promotion à vérifier.
  /// Retourne `true` si la date actuelle se situe entre la date de début et de fin.
  static bool isPromotionActive(PromotionFull promotion) {
    final now = DateTime.now();
    return now.isAfter(promotion.dateDebut) && now.isBefore(promotion.dateFin);
  }

  /// Vérifie si une promotion est programmée pour le futur.
  ///
  /// [promotion] : La promotion à vérifier.
  /// Retourne `true` si la date de début est après la date actuelle.
  static bool isPromotionFuture(PromotionFull promotion) {
    return promotion.dateDebut.isAfter(DateTime.now());
  }

  /// Trie une liste de promotions selon un ordre de priorité :
  /// 1. Promotions actives en premier.
  /// 2. Promotions à venir ensuite.
  /// 3. Promotions expirées en dernier.
  /// À l'intérieur de chaque groupe, le tri se fait par date de début.
  static void _sortPromotions(List<PromotionFull> promotions) {
    promotions.sort((a, b) {
      final aActive = isPromotionActive(a);
      final bActive = isPromotionActive(b);

      // Si 'a' est active et 'b' ne l'est pas, 'a' vient en premier.
      if (aActive && !bActive) return -1;
      // Si 'b' est active et 'a' ne l'est pas, 'b' vient en premier.
      if (!aActive && bActive) return 1;

      final aFuture = isPromotionFuture(a);
      final bFuture = isPromotionFuture(b);

      // Si 'a' est future et 'b' ne l'est pas (et qu'aucune n'est active), 'a' vient en premier.
      if (aFuture && !bFuture) return -1;
      // Si 'b' est future et 'a' ne l'est pas, 'b' vient en premier.
      if (!aFuture && bFuture) return 1;

      // Pour les promotions du même groupe (toutes actives, toutes futures ou toutes expirées),
      // on les trie par leur date de début.
      return a.dateDebut.compareTo(b.dateDebut);
    });
  }
}






// // 📁 lib/services/promotion_service.dart
//
// import '../../../../../models/promotion_full.dart';
// import '../../../../../models/service_with_promo.dart';
// import '../api/promotion_api.dart';
//
// class PromotionService {
//   // ✅ Récupère tous les services et les mappe correctement
//   static Future<Map<String, dynamic>> getServices(String coiffeuseId) async {
//     try {
//       final result = await PromotionApi.getServicesByCoiffeuse(coiffeuseId);
//
//       if (result['error'] != null) {
//         return {'services': null, 'error': result['error']};
//       }
//
//       final data = result['data'];
//
//       // 🔥 CORRECTION : Récupérer les informations du salon parent
//       Map<String, dynamic> salonData;
//       if (data.containsKey('results')) {
//         salonData = data['results']['salon'];
//       } else {
//         salonData = data['salon'];
//       }
//
//       final int salonId = salonData['idTblSalon'] ?? salonData['id'] ?? 0;
//       final String? salonNom = salonData['nom_salon'] ?? salonData['nom'] ?? salonData['name'];
//
//       // 🔍 DEBUG
//       print('🏢 Salon trouvé: ID=$salonId, Nom=$salonNom');
//
//       final serviceList = salonData['services'] ?? [];
//
//       // 🔥 CORRECTION : Passer salonId et salonNom lors du mapping
//       final List<ServiceWithPromo> services = (serviceList as List)
//           .map((json) => ServiceWithPromo.fromJson(
//             json,
//             parentSalonId: salonId,
//             parentSalonNom: salonNom
//           ))
//           .toList();
//
//       return {
//         'services': services,
//         'totalCount': data['count'] ?? services.length,
//         'error': null,
//       };
//     } catch (e) {
//       print('❌ Erreur dans getServices: $e');
//       return {'services': null, 'error': 'Erreur lors du traitement des services: $e'};
//     }
//   }
//
//   // ✅ Supprimer une promotion
//   static Future<Map<String, dynamic>> deletePromotion(int promotionId) async {
//     try {
//       final bool success = await PromotionApi.deletePromotion(promotionId);
//
//       return success
//           ? {'success': true, 'message': '✅ Promotion supprimée avec succès'}
//           : {'success': false, 'error': '❌ Impossible de supprimer la promotion.'};
//
//     } catch (e) {
//       return {
//         'success': false,
//         'error': '🚨 Une erreur est survenue : ${e.toString()}',
//       };
//     }
//   }
//
//   // ✅ Fusionne toutes les promos dans un seul tableau pour le modal
//   static Future<Map<String, dynamic>> getAllPromotionsForService(ServiceWithPromo service) async {
//     try {
//       List<PromotionFull> allPromotions = [];
//
//       if (service.promotion_active != null) {
//         allPromotions.add(service.promotion_active!);
//       }
//       if (service.promotions_a_venir.isNotEmpty) {
//         allPromotions.addAll(service.promotions_a_venir);
//       }
//       if (service.promotions_expirees.isNotEmpty) {
//         allPromotions.addAll(service.promotions_expirees);
//       }
//
//       _sortPromotions(allPromotions);
//
//       return {'promotions': allPromotions, 'error': null};
//     } catch (e) {
//       return {'promotions': [], 'error': 'Erreur: $e'};
//     }
//   }
//
//   // ✅ Statut actif
//   static bool isPromotionActive(PromotionFull promotion) {
//     final now = DateTime.now();
//     return now.isAfter(promotion.dateDebut) && now.isBefore(promotion.dateFin);
//   }
//
//   // ✅ Statut à venir
//   static bool isPromotionFuture(PromotionFull promotion) {
//     return promotion.dateDebut.isAfter(DateTime.now());
//   }
//
//   // ✅ Tri : actives -> futures -> expirées
//   static void _sortPromotions(List<PromotionFull> promotions) {
//     promotions.sort((a, b) {
//       final aActive = isPromotionActive(a);
//       final bActive = isPromotionActive(b);
//
//       if (aActive && !bActive) return -1;
//       if (!aActive && bActive) return 1;
//
//       final aFuture = isPromotionFuture(a);
//       final bFuture = isPromotionFuture(b);
//
//       if (aFuture && !bFuture) return -1;
//       if (!aFuture && bFuture) return 1;
//
//       return a.dateDebut.compareTo(b.dateDebut);
//     });
//   }
// }
