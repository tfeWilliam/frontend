////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//             CLASSE UTILITAIRE POUR LA GESTION DES URL D'IMAGES               //
//                                                                            //
//  Ce fichier définit `ImageUtil`, une classe de service contenant des       //
//  méthodes statiques pour manipuler les chemins d'accès des images. Le but  //
//  principal est de centraliser la logique de construction des URL absolues  //
//  afin de s'assurer que les images sont toujours chargées correctement,     //
//  quelle que soit la forme du chemin retourné par l'API (relatif ou absolu).//
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;

class ImageUtil {
  /// L'URL de base du serveur où sont hébergées les images.
  static const String baseUrl = "https://www.hairbnb.site";

  /// Construit une URL d'image complète et absolue à partir d'un chemin potentiellement relatif.
  ///
  /// Cette méthode garantit que l'URL retournée est toujours valide pour l'affichage
  /// dans un widget `Image.network`. Elle gère les cas suivants :
  /// - Le chemin est nul ou vide : retourne une chaîne vide.
  /// - Le chemin est déjà une URL absolue (commence par "http://" ou "https://") : le retourne tel quel.
  /// - Le chemin est relatif (ex: "/media/images/mon_image.jpg") : le préfixe avec `baseUrl`.
  ///
  /// [relativePath] : Le chemin d'accès à l'image, qui peut être relatif ou absolu.
  ///
  /// Retourne une `String` représentant l'URL complète, ou une chaîne vide si le chemin est invalide.
  static String getFullImageUrl(String? relativePath) {
    // Si le chemin est invalide (null ou vide), retourne une chaîne vide pour éviter les erreurs.
    if (relativePath == null || relativePath.isEmpty) {
      return "";
    }

    // Si le chemin est déjà une URL complète, il n'y a rien à faire.
    if (relativePath.startsWith('http://') || relativePath.startsWith('https://')) {
      return relativePath;
    }

    // Si le chemin est relatif, on le combine avec l'URL de base pour créer une URL absolue.
    return baseUrl + relativePath;
  }
}




// class ImageUtil {
//   static const String baseUrl = "https://www.hairbnb.site";
//
//   // Méthode pour construire une URL complète à partir d'un chemin relatif
//   static String getFullImageUrl(String? relativePath) {
//     if (relativePath == null || relativePath.isEmpty) {
//       return "";
//     }
//
//     // Si le chemin commence déjà par http ou https, c'est déjà une URL complète
//     if (relativePath.startsWith('http://') || relativePath.startsWith('https://')) {
//       return relativePath;
//     }
//
//     // Sinon, concaténer avec l'URL de base
//     return baseUrl + relativePath;
//   }
// }