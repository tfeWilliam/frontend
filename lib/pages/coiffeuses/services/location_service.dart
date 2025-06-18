////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                SERVICE DE GESTION DE LA GÉOLOCALISATION                      //
//                                                                            //
//  Ce fichier définit `LocationService`, une classe de service qui           //
//  centralise la logique de récupération de la position géographique de      //
//  l'appareil. Elle agit comme une façade (wrapper) pour le package          //
//  `geolocator`, simplifiant le processus complexe de vérification des       //
//  services, de demande de permissions et de récupération des coordonnées.   //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;

import 'package:geolocator/geolocator.dart';

/// Une classe de service qui fournit des méthodes statiques pour interagir
/// avec les services de localisation de l'appareil.
class LocationService {

  /// Tente de récupérer la position géographique actuelle de l'utilisateur.
  ///
  /// Cette méthode asynchrone effectue une série de vérifications nécessaires :
  /// 1. Elle vérifie si les services de localisation sont activés sur l'appareil.
  /// 2. Elle vérifie si l'application a déjà obtenu la permission d'accéder à la localisation.
  /// 3. Si la permission est refusée, elle la demande à l'utilisateur.
  /// 4. Si la permission est accordée, elle récupère et retourne la position actuelle.
  ///
  /// Retourne un objet `Position` en cas de succès, ou `null` si les services sont
  /// désactivés ou si l'utilisateur refuse définitivement la permission.
  static Future<Position?> getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Étape 1 : Vérifier si le service de localisation est activé sur l'appareil.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Si les services de localisation ne sont pas activés, on ne peut pas continuer.
      return null;
    }

    // Étape 2 : Vérifier l'état actuel des permissions pour l'application.
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Si la permission n'a pas encore été accordée ou refusée, on la demande à l'utilisateur.
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        // Si l'utilisateur a définitivement refusé la permission, on ne peut plus la demander.
        return null;
      }
    }

    // Si la permission est refusée une seule fois (mais pas définitivement),
    // l'application peut continuer mais ne pourra pas obtenir la position.
    // Le `geolocator` lèvera une `PermissionDeniedException` si on continue,
    // il est donc préférable de retourner null si la permission n'est pas accordée.
    if (permission == LocationPermission.denied) {
      return null;
    }

    // Étape 3 : Si les services sont activés et les permissions accordées, récupérer la position.
    return await Geolocator.getCurrentPosition();
  }
}






// import 'package:geolocator/geolocator.dart';
//
// class LocationService {
//   static Future<Position?> getUserLocation() async {
//     bool serviceEnabled;
//     LocationPermission permission;
//
//     // Vérifier si la localisation est activée
//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       return null;
//     }
//
//     // Vérifier les permissions
//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.deniedForever) {
//         return null;
//       }
//     }
//
//     // Récupérer la position actuelle
//     return await Geolocator.getCurrentPosition();
//   }
// }
