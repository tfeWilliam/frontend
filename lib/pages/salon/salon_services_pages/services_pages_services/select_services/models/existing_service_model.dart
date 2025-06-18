////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                MODÈLE DE DONNÉES POUR UN SERVICE EXISTANT                    //
//                                                                            //
//  Ce fichier définit le modèle `ExistingService`.                           //
//                                                                            //
//  Ce modèle est spécifiquement utilisé pour représenter un service trouvé   //
//  lors d'une recherche (par exemple, lors de la création d'un nouveau       //
//  service pour éviter les doublons). Il est enrichi avec des métadonnées    //
//  agrégées, comme les prix et durées populaires, ainsi que le nombre de     //
//  salons qui l'utilisent, afin de fournir un contexte utile à l'utilisateur.//
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;

/// Représente un service existant dans le catalogue global, avec des
/// informations agrégées sur son utilisation.
class ExistingService {
  /// L'identifiant unique du service.
  final int id;
  /// Le nom (intitulé) du service.
  final String nom;
  /// La description du service.
  final String description;
  /// Une liste des prix les plus couramment appliqués pour ce service.
  final List<double> prixPopulaires;
  /// Une liste des durées les plus courantes pour ce service.
  final List<int> dureesPopulaires;
  /// Le nombre de salons qui proposent actuellement ce service.
  final int nbSalonsUtilisant;

  /// Constructeur pour créer une instance de `ExistingService`.
  ExistingService({
    required this.id,
    required this.nom,
    required this.description,
    required this.prixPopulaires,
    required this.dureesPopulaires,
    required this.nbSalonsUtilisant,
  });

  /// Factory constructor pour créer une instance de `ExistingService` à partir d'un map JSON.
  ///
  /// Gère la désérialisation des données reçues de l'API de recherche,
  /// avec des conversions de types et des valeurs par défaut pour la robustesse.
  factory ExistingService.fromJson(Map<String, dynamic> json) {
    return ExistingService(
      id: json['idTblService'] ?? 0,
      nom: json['intitule_service'] ?? '',
      description: json['description'] ?? '',
      // Conversion sécurisée de la liste dynamique en `List<double>`.
      prixPopulaires: (json['prix_populaires'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList() ?? [],
      // Conversion sécurisée de la liste dynamique en `List<int>`.
      dureesPopulaires: (json['durees_populaires'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ?? [],
      nbSalonsUtilisant: json['nb_salons_utilisant'] ?? 0,
    );
  }
}






// // Modèle pour les services existants trouvés
// class ExistingService {
//   final int id;
//   final String nom;
//   final String description;
//   final List<double> prixPopulaires;
//   final List<int> dureesPopulaires;
//   final int nbSalonsUtilisant;
//
//   ExistingService({
//     required this.id,
//     required this.nom,
//     required this.description,
//     required this.prixPopulaires,
//     required this.dureesPopulaires,
//     required this.nbSalonsUtilisant,
//   });
//
//   factory ExistingService.fromJson(Map<String, dynamic> json) {
//     return ExistingService(
//       id: json['idTblService'] ?? 0,
//       nom: json['intitule_service'] ?? '',
//       description: json['description'] ?? '',
//       prixPopulaires: (json['prix_populaires'] as List<dynamic>?)
//           ?.map((e) => (e as num).toDouble())
//           .toList() ?? [],
//       dureesPopulaires: (json['durees_populaires'] as List<dynamic>?)
//           ?.map((e) => (e as num).toInt())
//           .toList() ?? [],
//       nbSalonsUtilisant: json['nb_salons_utilisant'] ?? 0,
//     );
//   }
// }