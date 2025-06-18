/****************************************************************************************
 *
 * MODÈLE DE DONNÉES : Promotion
 *
 * OBJECTIF :
 * Cette classe modélise une offre promotionnelle ou une réduction applicable à un
 * service spécifique. Elle définit le pourcentage de la réduction ainsi que sa
 * période de validité (dates de début et de fin).
 *
 * FONCTIONNALITÉS CLÉS :
 * - Contient les informations essentielles d'une promotion.
 * - Inclut des méthodes `fromJson` et `toJson` pour la communication avec une API.
 * - La méthode `fromJson` est conçue pour être très robuste, gérant les valeurs
 * nulles ou les types de données incorrects venant du backend.
 * - Le statut d'activité (`isActive`) est déterminé directement par une valeur
 * (`is_active`) fournie par le backend, plutôt que d'être calculé côté client
 * à partir de la date actuelle.
 * - La méthode `toJson` formate les dates en 'AAAA-MM-JJ' pour l'envoi à l'API.
 *
 *****************************************************************************************/

class Promotion {
  /// Identifiant unique de la promotion dans la base de données.
  final int id;
  /// L'identifiant du service auquel cette promotion s'applique.
  final int serviceId;
  /// Le pourcentage de réduction offert par la promotion.
  final double pourcentage;
  /// La date à laquelle la promotion devient active.
  final DateTime dateDebut;
  /// La date à laquelle la promotion expire.
  final DateTime dateFin;
  /// Stocke directement le statut d'activité (true/false) tel que fourni par le backend.
  final bool isActiveValue;

  /// Constructeur pour créer une nouvelle instance de Promotion.
  Promotion({
    required this.id,
    required this.serviceId,
    required this.pourcentage,
    required this.dateDebut,
    required this.dateFin,
    this.isActiveValue = true,
  });

  /// Crée une instance de [Promotion] à partir d'une map JSON.
  /// Cette méthode est conçue pour être robuste face à des données potentiellement nulles.
  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: int.tryParse(json['idPromotion']?.toString() ?? '') ?? 0,
      serviceId: int.tryParse(json['service_id']?.toString() ?? '') ?? 0,
      pourcentage: double.tryParse(json['discount_percentage']?.toString() ?? '') ?? 0.0,
      dateDebut: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : DateTime.now(),
      dateFin: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : DateTime.now(),
      // Le statut d'activité est lu directement depuis la valeur du backend.
      isActiveValue: json['is_active'] == true,
    );
  }

  /// Convertit l'objet [Promotion] en une map JSON, prête à être envoyée à une API.
  Map<String, dynamic> toJson() {
    return {
      "idPromotion": id,
      "service_id": serviceId,
      "discount_percentage": pourcentage,
      // Le format est 'AAAA-MM-JJ' pour n'envoyer que la date, sans l'heure.
      "start_date": dateDebut.toIso8601String().split('T')[0],
      "end_date": dateFin.toIso8601String().split('T')[0],
      // Note : Le statut 'is_active' n'est pas envoyé, car il est géré par le backend.
    };
  }

  /// Vérifie si la promotion est active.
  /// Retourne simplement la valeur `isActiveValue` qui est fournie par le backend,
  /// sans faire de calcul basé sur la date actuelle côté client.
  bool isActive() {
    return isActiveValue;
  }
}






// class Promotion {
//   final int id;
//   final int serviceId;
//   final double pourcentage;
//   final DateTime dateDebut;
//   final DateTime dateFin;
//   final bool isActiveValue; // Nouvelle propriété
//
//   Promotion({
//     required this.id,
//     required this.serviceId,
//     required this.pourcentage,
//     required this.dateDebut,
//     required this.dateFin,
//     this.isActiveValue = true,
//   });
//
//   factory Promotion.fromJson(Map<String, dynamic> json) {
//     print("DEBUG: Promotion JSON: $json"); // Pour vérifier le contenu du JSON
//     return Promotion(
//       id: int.tryParse(json['idPromotion']?.toString() ?? '') ?? 0,
//       serviceId: int.tryParse(json['service_id']?.toString() ?? '') ?? 0,
//       pourcentage: double.tryParse(json['discount_percentage']?.toString() ?? '') ?? 0.0,
//       dateDebut: json['start_date'] != null
//           ? DateTime.parse(json['start_date'])
//           : DateTime.now(),
//       dateFin: json['end_date'] != null
//           ? DateTime.parse(json['end_date'])
//           : DateTime.now(),
//       isActiveValue: json['is_active'] == true, // Utiliser directement la valeur du backend
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       "idPromotion": id,
//       "service_id": serviceId,
//       "discount_percentage": pourcentage,
//       "start_date": dateDebut.toIso8601String().split('T')[0], // Envoyer uniquement la date
//       "end_date": dateFin.toIso8601String().split('T')[0],     // Envoyer uniquement la date
//     };
//   }
//
//   /// Utilise directement la valeur du backend si disponible
//   bool isActive() {
//     return isActiveValue;
//   }
// }