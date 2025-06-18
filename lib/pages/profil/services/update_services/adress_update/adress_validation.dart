////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                SERVICE DE VALIDATION D'ADRESSE VIA GEOAPIFY                  //
//                                                                            //
//  Ce fichier définit les classes et la logique nécessaires pour valider une //
//  adresse physique en utilisant l'API de géocodage externe Geoapify.        //
//                                                                            //
//  Son rôle principal est de prendre un objet `Adresse` structuré, de le     //
//  soumettre à l'API, et de retourner un résultat standardisé indiquant si    //
//  l'adresse est valide, tout en récupérant ses coordonnées GPS si elle      //
//  est trouvée.                                                              //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../../models/adresse.dart';

/// Un modèle de données pour encapsuler le résultat d'une tentative de validation d'adresse.
class AddressValidationResult {
  /// `true` si l'adresse a été trouvée et validée par l'API.
  final bool isValid;
  /// La coordonnée de latitude, si la validation a réussi.
  final double? latitude;
  /// La coordonnée de longitude, si la validation a réussi.
  final double? longitude;
  /// L'adresse complète et formatée retournée par l'API.
  final String? formattedAddress;
  /// Un message d'erreur en cas d'échec de la validation.
  final String? errorMessage;

  /// Constructeur pour un résultat de validation d'adresse.
  AddressValidationResult({
    required this.isValid,
    this.latitude,
    this.longitude,
    this.formattedAddress,
    this.errorMessage,
  });
}

/// Une classe de service contenant des méthodes statiques pour interagir avec l'API Geoapify.
/// Cette classe n'est pas destinée à être instanciée.
class AddressValidationService {
  /// La clé API pour accéder au service Geoapify.
  static const String _apiKey = 'b097f188b11f46d2a02eb55021d168c1';
  /// L'URL de base de l'API Geoapify.
  static const String _baseUrl = 'https://api.geoapify.com/v1';

  /// Valide une adresse en interrogeant l'API de géocodage de Geoapify.
  ///
  /// [adresse] : L'objet `Adresse` structuré à valider.
  ///
  /// Retourne une `Future` qui se résoudra en un `AddressValidationResult`.
  static Future<AddressValidationResult> validateAddress(Adresse adresse) async {
    try {
      // Étape 1 : Construire une chaîne de requête à partir de l'objet Adresse.
      String addressQuery = _buildAddressQuery(adresse);

      // Si l'adresse est trop incomplète, retourne une erreur immédiatement.
      if (addressQuery.isEmpty) {
        return AddressValidationResult(isValid: false, errorMessage: "Adresse incomplète");
      }

      // Étape 2 : Construire l'URL complète pour l'appel API.
      final url = Uri.parse(
          '$_baseUrl/geocode/search?text=${Uri.encodeComponent(addressQuery)}&filter=countrycode:be&limit=1&apiKey=$_apiKey'
      );

      // Étape 3 : Effectuer la requête HTTP GET avec un timeout de 10 secondes.
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      // Étape 4 : Traiter la réponse de l'API.
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Vérifie si l'API a retourné au moins un résultat ("feature").
        if (data['features'] != null && data['features'].isNotEmpty) {
          final feature = data['features'][0];
          final geometry = feature['geometry'];
          final properties = feature['properties'];

          // L'adresse est considérée comme valide si un résultat est trouvé.
          return AddressValidationResult(
            isValid: true,
            latitude: geometry['coordinates'][1].toDouble(),
            longitude: geometry['coordinates'][0].toDouble(),
            formattedAddress: properties['formatted']?.toString(),
          );
        } else {
          // Aucun résultat trouvé pour cette adresse.
          return AddressValidationResult(isValid: false, errorMessage: "Adresse non trouvée");
        }
      } else {
        // Gère les codes d'erreur HTTP de l'API.
        return AddressValidationResult(isValid: false, errorMessage: "Erreur de validation (${response.statusCode})");
      }
    } catch (e) {
      // Gère les erreurs de connexion ou autres exceptions.
      return AddressValidationResult(isValid: false, errorMessage: "Erreur de connexion");
    }
  }

  /// Méthode privée pour construire une chaîne de requête d'adresse bien formatée.
  ///
  /// Combine les différentes parties de l'objet `Adresse` en une seule chaîne de
  /// caractères, en ajoutant "Belgium" pour améliorer la pertinence des résultats.
  static String _buildAddressQuery(Adresse adresse) {
    List<String> parts = [];

    if (adresse.numero != null) parts.add(adresse.numero.toString());
    if (adresse.rue?.nomRue != null && adresse.rue!.nomRue!.isNotEmpty) parts.add(adresse.rue!.nomRue!);
    if (adresse.rue?.localite?.codePostal != null && adresse.rue!.localite!.codePostal!.isNotEmpty) parts.add(adresse.rue!.localite!.codePostal!);
    if (adresse.rue?.localite?.commune != null && adresse.rue!.localite!.commune!.isNotEmpty) parts.add(adresse.rue!.localite!.commune!);

    // Ajoute toujours le pays pour affiner la recherche.
    parts.add("Belgium");

    return parts.join(" ");
  }
}




// // lib/services/address_validation_service.dart
// // Créer ce nouveau fichier
//
// import 'dart:convert';
// import 'package:http/http.dart' as http;
//
// import '../../../../../models/adresse.dart';
//
// class AddressValidationResult {
//   final bool isValid;
//   final double? latitude;
//   final double? longitude;
//   final String? formattedAddress;
//   final String? errorMessage;
//
//   AddressValidationResult({
//     required this.isValid,
//     this.latitude,
//     this.longitude,
//     this.formattedAddress,
//     this.errorMessage,
//   });
// }
//
// class AddressValidationService {
//   static const String _apiKey = 'b097f188b11f46d2a02eb55021d168c1';
//   static const String _baseUrl = 'https://api.geoapify.com/v1';
//
//   static Future<AddressValidationResult> validateAddress(Adresse adresse) async {
//     try {
//       // Construire l'adresse complète
//       String addressQuery = _buildAddressQuery(adresse);
//
//       if (addressQuery.isEmpty) {
//         return AddressValidationResult(
//           isValid: false,
//           errorMessage: "Adresse incomplète",
//         );
//       }
//
//       print("🔍 Validation: $addressQuery");
//
//       final url = Uri.parse(
//           '$_baseUrl/geocode/search?text=${Uri.encodeComponent(addressQuery)}&filter=countrycode:be&limit=1&apiKey=$_apiKey'
//       );
//
//       final response = await http.get(url).timeout(
//         const Duration(seconds: 10),
//       );
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//
//         if (data['features'] != null && data['features'].isNotEmpty) {
//           final feature = data['features'][0];
//           final geometry = feature['geometry'];
//           final properties = feature['properties'];
//
//           print("✅ Adresse validée avec coordonnées");
//
//           return AddressValidationResult(
//             isValid: true,
//             latitude: geometry['coordinates'][1].toDouble(),
//             longitude: geometry['coordinates'][0].toDouble(),
//             formattedAddress: properties['formatted']?.toString(),
//           );
//         } else {
//           return AddressValidationResult(
//             isValid: false,
//             errorMessage: "Adresse non trouvée",
//           );
//         }
//       } else {
//         return AddressValidationResult(
//           isValid: false,
//           errorMessage: "Erreur de validation (${response.statusCode})",
//         );
//       }
//     } catch (e) {
//       print("❌ Erreur validation: $e");
//       return AddressValidationResult(
//         isValid: false,
//         errorMessage: "Erreur de connexion",
//       );
//     }
//   }
//
//   static String _buildAddressQuery(Adresse adresse) {
//     List<String> parts = [];
//
//     if (adresse.numero != null) {
//       parts.add(adresse.numero.toString());
//     }
//
//     if (adresse.rue?.nomRue != null && adresse.rue!.nomRue!.isNotEmpty) {
//       parts.add(adresse.rue!.nomRue!);
//     }
//
//     if (adresse.rue?.localite?.codePostal != null && adresse.rue!.localite!.codePostal!.isNotEmpty) {
//       parts.add(adresse.rue!.localite!.codePostal!);
//     }
//
//     if (adresse.rue?.localite?.commune != null && adresse.rue!.localite!.commune!.isNotEmpty) {
//       parts.add(adresse.rue!.localite!.commune!);
//     }
//
//     parts.add("Belgium");
//
//     return parts.join(" ");
//   }
// }