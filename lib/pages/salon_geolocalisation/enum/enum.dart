////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//      MODÈLES DE DONNÉES POUR LA GÉOLOCALISATION ET LES ITINÉRAIRES           //
//                                                                            //
//  Ce fichier définit des structures de données essentielles pour les        //
//  fonctionnalités de cartographie et de calcul d'itinéraires. Il contient : //
//                                                                            //
//  - TransportMode : Une énumération des différents modes de transport       //
//    possibles.                                                              //
//  - RouteResult : Une classe qui encapsule toutes les informations d'un     //
//    itinéraire calculé (tracé, distance, durée).                            //
//  - POI : Une classe simple pour représenter un Point d'Intérêt sur une     //
//    carte.                                                                  //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;

import 'package:latlong2/latlong.dart';

/// Définit les différents modes de transport utilisables pour le calcul d'itinéraires.
enum TransportMode {
  /// Itinéraire en voiture.
  drive,
  /// Itinéraire à pied.
  walk,
  /// Itinéraire à vélo.
  bicycle,
  /// Itinéraire en transport en commun.
  transit,
}

/// Un modèle de données pour encapsuler le résultat d'un calcul d'itinéraire.
///
/// Il contient la géométrie du tracé (une liste de points), la distance totale,
/// et la durée estimée du trajet.
class RouteResult {
  /// La liste des coordonnées géographiques (`LatLng`) qui forment le tracé de l'itinéraire.
  final List<LatLng> points;
  /// La distance totale de l'itinéraire, exprimée en mètres.
  final double distance;
  /// La durée totale estimée du trajet, exprimée en secondes.
  final int duration;

  /// Constructeur pour un `RouteResult`.
  RouteResult({
    required this.points,
    required this.distance,
    required this.duration,
  });

  /// Getter pour retourner la distance formatée de manière lisible.
  ///
  /// Affiche la distance en mètres si elle est inférieure à 1 km,
  /// sinon en kilomètres avec une décimale.
  /// Exemple: "850 m" ou "2.3 km".
  String get distanceFormatted {
    if (distance < 1000) {
      return '${distance.round()} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
  }

  /// Getter pour retourner la durée formatée de manière lisible.
  ///
  /// Affiche la durée en heures et minutes (ex: "1h 25min"), ou seulement
  /// en minutes si elle est inférieure à une heure (ex: "45min").
  String get durationFormatted {
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}min';
    } else {
      return '${minutes}min';
    }
  }
}

/// Un modèle de données simple pour représenter un Point d'Intérêt (POI) sur une carte.
class POI {
  /// Les coordonnées géographiques du point d'intérêt.
  final LatLng location;
  /// Le nom du point d'intérêt (ex: "Gare Centrale").
  final String name;
  /// Le type ou la catégorie du point d'intérêt (ex: "gare", "restaurant").
  final String type;

  /// Constructeur pour un `POI`.
  POI({
    required this.location,
    required this.name,
    required this.type,
  });
}





// // ✅ ENUMS ET CLASSES DÉFINIES
// import 'package:latlong2/latlong.dart';
//
// enum TransportMode {
//   drive,
//   walk,
//   bicycle,
//   transit,
// }
//
// class RouteResult {
//   final List<LatLng> points;
//   final double distance; // en mètres
//   final int duration; // en secondes
//
//   RouteResult({
//     required this.points,
//     required this.distance,
//     required this.duration,
//   });
//
//   String get distanceFormatted {
//     if (distance < 1000) {
//       return '${distance.round()} m';
//     } else {
//       return '${(distance / 1000).toStringAsFixed(1)} km';
//     }
//   }
//
//   String get durationFormatted {
//     final hours = duration ~/ 3600;
//     final minutes = (duration % 3600) ~/ 60;
//
//     if (hours > 0) {
//       return '${hours}h ${minutes}min';
//     } else {
//       return '${minutes}min';
//     }
//   }
// }
//
// class POI {
//   final LatLng location;
//   final String name;
//   final String type;
//
//   POI({
//     required this.location,
//     required this.name,
//     required this.type,
//   });
// }