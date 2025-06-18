// // lib/api/gallery_api.dart
//
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//         SERVICE (CLIENT API) POUR LA GESTION DE LA GALERIE D'IMAGES          //
//                                                                            //
//  Ce fichier définit `GalleryApi`, une classe qui centralise tous les       //
//  appels à l'API backend pour la gestion de la galerie de photos d'un salon.//
//                                                                            //
//  Responsabilités :                                                         //
//  - Récupérer la liste des images d'un salon.                               //
//  - Télécharger de nouvelles images, avec une logique distincte pour les    //
//    plateformes natives (utilisant `File`) et pour le web (utilisant       //
//    `http.MultipartFile`).                                                  //
//  - Supprimer une image existante.                                          //
//  - Fournir des méthodes utilitaires (ex: déterminer le type MIME).         //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;


import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../models/public_salon_details.dart';

/// Une classe de service contenant des méthodes statiques pour interagir avec
/// les endpoints de l'API relatifs à la galerie d'images d'un salon.
class GalleryApi {
  /// L'URL de base de l'API backend.
  static const String baseUrl = 'https://hairbnb.site/api';

  /// Récupère la liste de toutes les images pour un salon donné.
  ///
  /// [salonId] : L'identifiant du salon dont on veut les images.
  ///
  /// Retourne une `Future<List<SalonImage>>`. Lève une `Exception` en cas d'échec.
  static Future<List<SalonImage>> getSalonImages(int salonId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/salon/$salonId/images/'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => SalonImage.fromJson(json)).toList();
      } else {
        throw Exception('Échec de récupération des images: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération des images: $e');
    }
  }

  /// Télécharge une ou plusieurs images vers le serveur pour un salon donné.
  /// Cette méthode est conçue pour les plateformes NATIVES (mobile, desktop).
  ///
  /// [salonId] : L'ID du salon auquel ajouter les images.
  /// [images] : Une liste d'objets `File` représentant les images à télécharger.
  ///
  /// Retourne une liste d'objets `SalonImage` simulés à partir des IDs
  /// retournés par l'API.
  static Future<List<SalonImage>> uploadImages(int salonId, List<File> images) async {
    try {
      final url = Uri.parse('$baseUrl/add_images_to_salon/');
      // Utilise `MultipartRequest` pour pouvoir envoyer des fichiers.
      final request = http.MultipartRequest('POST', url);

      // Ajoute l'ID du salon comme un champ de formulaire.
      request.fields['salon'] = salonId.toString();

      // Ajoute chaque image à la requête.
      for (final image in images) {
        final fileStream = http.ByteStream(image.openRead());
        final fileLength = await image.length();
        final fileName = image.path.split('/').last;

        final multipartFile = http.MultipartFile(
          'image', // Le nom du champ attendu par l'API pour chaque fichier.
          fileStream,
          fileLength,
          filename: fileName,
          contentType: MediaType('image', _getImageMimeType(fileName)),
        );
        request.files.add(multipartFile);
      }

      // Envoie la requête et attend la réponse.
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) { // 201 Created
        final responseData = json.decode(response.body);
        // Traite la réponse qui contient une liste d'IDs des images créées.
        if (responseData.containsKey('image_ids')) {
          final List<dynamic> imageIds = responseData['image_ids'];
          // Crée des objets `SalonImage` "fictifs" pour un retour immédiat.
          // L'interface devra probablement se rafraîchir pour obtenir les objets complets.
          return imageIds.map((id) => SalonImage(
              id: id,
              image: 'https://hairbnb.site/media/photos/salons/salon_${salonId}_image_$id.jpg'
          )).toList();
        }
        throw Exception('Format de réponse non reconnu');
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error'] ?? 'Échec du téléchargement: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Erreur lors du téléchargement des images: $e');
    }
  }

  /// Télécharge une ou plusieurs images vers le serveur pour un salon donné.
  /// Cette méthode est conçue pour la plateforme WEB.
  ///
  /// [salonId] : L'ID du salon auquel ajouter les images.
  /// [webFiles] : Une liste d'objets `http.MultipartFile` déjà préparés par un file picker web.
  ///
  /// Retourne une liste d'objets `SalonImage` simulés.
  static Future<List<SalonImage>> uploadImagesForWeb(int salonId, List<http.MultipartFile> webFiles) async {
    try {
      final url = Uri.parse('$baseUrl/add_images_to_salon/');
      final request = http.MultipartRequest('POST', url);
      request.fields['salon'] = salonId.toString();
      request.files.addAll(webFiles);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData.containsKey('image_ids')) {
          final List<dynamic> imageIds = responseData['image_ids'];
          return imageIds.map((id) => SalonImage(
            image: 'https://hairbnb.site/media/photos/salons/salon_${salonId}_image_$id.jpg', id: id,
          )).toList();
        }
        throw Exception('Format de réponse non reconnu');
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error'] ?? 'Échec du téléchargement: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Erreur lors du téléchargement des images: $e');
    }
  }

  /// Supprime une image spécifique en utilisant son identifiant unique.
  ///
  /// [imageId] : L'ID de l'image à supprimer.
  ///
  /// Retourne `true` si la suppression a réussi (status 204 No Content).
  /// Lève une `Exception` en cas d'échec.
  static Future<bool> deleteImage(int imageId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/salon/images/$imageId/delete/'),
      );
      // 204 No Content est la réponse standard et attendue pour une suppression réussie.
      return response.statusCode == 204;
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'image: $e');
    }
  }

  /// Méthode utilitaire privée pour déterminer le sous-type MIME d'un fichier
  /// à partir de l'extension de son nom.
  ///
  /// Exemple: 'photo.jpg' -> 'jpeg'.
  static String _getImageMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'jpeg';
      case 'png':
        return 'png';
      case 'gif':
        return 'gif';
      case 'webp':
        return 'webp';
      default:
      // Retourne 'jpeg' comme type par défaut.
        return 'jpeg';
    }
  }
}// import 'dart:convert';
// import 'dart:io';






// import 'package:http/http.dart' as http;
// import 'package:http_parser/http_parser.dart';
// import '../../models/public_salon_details.dart';
//
// class GalleryApi {
//   static const String baseUrl = 'https://hairbnb.site/api';
//
//   /// Récupère les images d'un salon
//   static Future<List<SalonImage>> getSalonImages(int salonId) async {
//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl/salon/$salonId/images/'),
//       );
//
//       if (response.statusCode == 200) {
//         final List<dynamic> data = json.decode(response.body);
//         return data.map((json) => SalonImage.fromJson(json)).toList();
//       } else {
//         throw Exception('Échec de récupération des images: ${response.statusCode}');
//       }
//     } catch (e) {
//       throw Exception('Erreur lors de la récupération des images: $e');
//     }
//   }
//
//   /// Télécharge des images sur le serveur (pour les plateformes natives)
//   static Future<List<SalonImage>> uploadImages(int salonId, List<File> images) async {
//     try {
//       final url = Uri.parse('$baseUrl/add_images_to_salon/');
//       final request = http.MultipartRequest('POST', url);
//
//       // Ajouter l'ID du salon
//       request.fields['salon'] = salonId.toString();
//
//       // Ajouter chaque image à la requête
//       for (final image in images) {
//         final fileStream = http.ByteStream(image.openRead());
//         final fileLength = await image.length();
//         final fileName = image.path.split('/').last;
//
//         final multipartFile = http.MultipartFile(
//           'image', // Le nom du champ attendu par l'API
//           fileStream,
//           fileLength,
//           filename: fileName,
//           contentType: MediaType('image', _getImageMimeType(fileName)),
//         );
//
//         request.files.add(multipartFile);
//       }
//
//       // Envoyer la requête
//       final streamedResponse = await request.send();
//       final response = await http.Response.fromStream(streamedResponse);
//
//       if (response.statusCode == 201) {
//         // Traiter la réponse de l'API
//         final responseData = json.decode(response.body);
//
//         // Si l'API retourne directement une liste d'IDs et non pas d'objets complets
//         if (responseData.containsKey('image_ids')) {
//           // Simuler des objets SalonImage à partir des IDs reçus
//           final List<dynamic> imageIds = responseData['image_ids'];
//
//           // Créer des objets SalonImage fictifs (vous devrez ensuite rafraîchir la galerie)
//           return imageIds.map((id) => SalonImage(
//             id: id,
//             image: 'https://hairbnb.site/media/photos/salons/salon_${salonId}_image_$id.jpg'
//           )).toList();
//         }
//
//         throw Exception('Format de réponse non reconnu');
//       } else {
//         final errorData = json.decode(response.body);
//         final errorMessage = errorData.containsKey('error')
//             ? errorData['error']
//             : 'Échec du téléchargement: ${response.statusCode}';
//         throw Exception(errorMessage);
//       }
//     } catch (e) {
//       throw Exception('Erreur lors du téléchargement des images: $e');
//     }
//   }
//
//   /// Télécharge des images sur le serveur (pour le web)
//   static Future<List<SalonImage>> uploadImagesForWeb(int salonId, List<http.MultipartFile> webFiles) async {
//     try {
//       final url = Uri.parse('$baseUrl/add_images_to_salon/');
//       final request = http.MultipartRequest('POST', url);
//
//       // Ajouter l'ID du salon
//       request.fields['salon'] = salonId.toString();
//
//       // Ajouter tous les fichiers à la requête
//       request.files.addAll(webFiles);
//
//       // Envoyer la requête
//       final streamedResponse = await request.send();
//       final response = await http.Response.fromStream(streamedResponse);
//
//       if (response.statusCode == 201) {
//         // Traiter la réponse de l'API
//         final responseData = json.decode(response.body);
//
//         // Si l'API retourne directement une liste d'IDs et non pas d'objets complets
//         if (responseData.containsKey('image_ids')) {
//           // Simuler des objets SalonImage à partir des IDs reçus
//           final List<dynamic> imageIds = responseData['image_ids'];
//
//           // Créer des objets SalonImage fictifs (vous devrez ensuite rafraîchir la galerie)
//           return imageIds.map((id) => SalonImage(
//             image: 'https://hairbnb.site/media/photos/salons/salon_${salonId}_image_$id.jpg', id: id,
//           )).toList();
//         }
//
//         throw Exception('Format de réponse non reconnu');
//       } else {
//         final errorData = json.decode(response.body);
//         final errorMessage = errorData.containsKey('error')
//             ? errorData['error']
//             : 'Échec du téléchargement: ${response.statusCode}';
//         throw Exception(errorMessage);
//       }
//     } catch (e) {
//       throw Exception('Erreur lors du téléchargement des images: $e');
//     }
//   }
//
//   /// Supprime une image du salon
//   static Future<bool> deleteImage(int imageId) async {
//     try {
//       final response = await http.delete(
//         Uri.parse('$baseUrl/salon/images/$imageId/delete/'),
//       );
//
//       return response.statusCode == 204;
//     } catch (e) {
//       throw Exception('Erreur lors de la suppression de l\'image: $e');
//     }
//   }
//
//   /// Détermine le type MIME d'une image en fonction de son extension
//   static String _getImageMimeType(String fileName) {
//     final extension = fileName.split('.').last.toLowerCase();
//
//     switch (extension) {
//       case 'jpg':
//       case 'jpeg':
//         return 'jpeg';
//       case 'png':
//         return 'png';
//       case 'gif':
//         return 'gif';
//       case 'webp':
//         return 'webp';
//       default:
//         return 'jpeg';
//     }
//   }
// }
//
