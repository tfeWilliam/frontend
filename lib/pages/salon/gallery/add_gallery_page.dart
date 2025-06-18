/// *************************************************************************************************
///
/// BANNER : EXPLICATION GÉNÉRALE DE LA PAGE D'AJOUT DE GALERIE
///
/// Ce fichier définit `AddGalleryPage`, un `StatefulWidget` qui permet à une coiffeuse
/// d'ajouter des images à la galerie de son salon.
///
/// Objectif :
/// Fournir une interface simple pour sélectionner plusieurs images depuis l'appareil de
/// l'utilisateur, les prévisualiser, et les envoyer au serveur pour les associer
/// au salon de la coiffeuse connectée.
///
/// Fonctionnalités Clés :
/// 1.  Récupération de l'ID du Salon : Au chargement, la page récupère automatiquement
/// l'ID du salon de la coiffeuse connectée via un appel API. Cet ID est nécessaire
/// pour l'envoi des images.
/// 2.  Sélection d'Images Multiples : Utilise le package `file_picker` pour permettre
/// à l'utilisateur de sélectionner plusieurs images à la fois.
/// 3.  Validation Côté Client :
/// - Limite la taille des fichiers à 6MB par image.
/// - Limite le nombre total d'images à 12.
/// 4.  Prévisualisation et Gestion : Affiche les images sélectionnées dans une grille
/// et permet de supprimer des images de la sélection avant l'envoi.
/// 5.  Envoi Multi-plateforme : Gère l'envoi des images différemment pour le web
/// (`Uint8List`) et pour les plateformes natives (`File`).
/// 6.  Envoi groupé : Construit et envoie une requête HTTP `MultipartRequest` pour
/// téléverser toutes les images en un seul appel API.
/// 7.  Feedback Utilisateur : Affiche des `SnackBar` pour informer l'utilisateur des
/// succès, des erreurs ou des avertissements (ex: images trop grandes ignorées).
/// 8.  Redirection : Après un envoi réussi, redirige l'utilisateur vers la page d'accueil.
///
///*************************************************************************************************
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../../services/providers/current_user_provider.dart';
import '../../home_page.dart';

/// Classe de modèle simple pour représenter une image sélectionnée.
/// Gère à la fois les données binaires (pour le web) et les fichiers (pour mobile/desktop).
class GalleryImage {
  final Uint8List? bytes; // Données binaires de l'image pour les plateformes web.
  final File? file;      // Fichier image pour les plateformes natives (iOS, Android, etc.).
  GalleryImage({this.bytes, this.file});
}

/// Widget principal de la page d'ajout d'images à la galerie.
class AddGalleryPage extends StatefulWidget {
  const AddGalleryPage({super.key});

  @override
  State<AddGalleryPage> createState() => _AddGalleryPageState();
}

class _AddGalleryPageState extends State<AddGalleryPage> {
  // Liste pour stocker les images sélectionnées par l'utilisateur.
  List<GalleryImage> _images = [];
  // Booléen pour gérer l'état de chargement lors de l'envoi des images.
  bool _isLoading = false;
  // ID du salon de la coiffeuse, récupéré depuis l'API.
  int? salonId;

  @override
  void initState() {
    super.initState();
    // Au démarrage de la page, on récupère l'ID du salon associé à l'utilisateur.
    _fetchSalonId();
  }

  /// Récupère l'ID du salon de la coiffeuse actuellement connectée.
  Future<void> _fetchSalonId() async {
    // Accède aux informations de l'utilisateur via le Provider.
    final currentUser = Provider.of<CurrentUserProvider>(context, listen: false).currentUser;
    if (currentUser == null) return; // Si aucun utilisateur n'est connecté, on arrête.

    try {
      // Effectue un appel GET à l'API pour trouver le salon de la coiffeuse.
      final response = await http.get(
        Uri.parse('https://www.hairbnb.site/api/get_salon_by_coiffeuse/${currentUser.idTblUser}/'),
      );

      if (response.statusCode == 200) {
        // Si la requête réussit, décode la réponse et stocke l'ID du salon.
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          salonId = data['salon']['idTblSalon'];
        });
      } else {
        // En cas d'erreur de l'API, affiche un message d'erreur.
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur lors de la récupération des informations du salon.")));
      }
    } catch (e) {
      // En cas d'erreur réseau, affiche un message d'erreur.
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur réseau. Impossible de contacter le serveur.")));
    }
  }

  /// Ouvre le sélecteur de fichiers pour que l'utilisateur choisisse des images.
  Future<void> _pickImages() async {
    // Utilise file_picker pour sélectionner plusieurs images.
    final result = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.image);

    if (result != null && result.files.isNotEmpty) {
      // Filtre les images pour ne garder que celles dont la taille est inférieure à 6MB.
      final validFiles = result.files.where((f) => f.size <= 6 * 1024 * 1024);
      // Convertit les fichiers sélectionnés en objets `GalleryImage`.
      final List<GalleryImage> selectedImages = validFiles.map((f) {
        return kIsWeb
            ? GalleryImage(bytes: f.bytes) // Pour le web, on utilise les bytes.
            : GalleryImage(file: File(f.path!)); // Pour les autres plateformes, on utilise le chemin du fichier.
      }).toList();

      // Affiche un message si certaines images ont été ignorées à cause de leur taille.
      if (selectedImages.length != result.files.length) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Certaines images dépassant 6MB ont été ignorées.")));
      }

      // Met à jour l'état du widget avec les nouvelles images.
      setState(() {
        _images.addAll(selectedImages);
        // Limite le nombre total d'images à 12.
        if (_images.length > 12) {
          _images = _images.sublist(0, 12);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Maximum de 12 images atteint.")));
        }
      });
    }
  }

  /// Soumet les images sélectionnées au serveur.
  Future<void> _submitImages() async {
    // Valide qu'au moins 3 images ont été sélectionnées.
    if (_images.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez ajouter au moins 3 images.")));
      return;
    }

    if (kDebugMode) print("📦 ID du salon pour l'envoi: $salonId");

    // Valide que l'ID du salon a bien été récupéré.
    if (salonId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Impossible de trouver le salon associé. Veuillez réessayer.")));
      return;
    }

    // Active l'indicateur de chargement.
    setState(() => _isLoading = true);

    // Crée une requête multipart pour envoyer des fichiers et des champs de texte.
    final request = http.MultipartRequest('POST', Uri.parse('https://www.hairbnb.site/api/add_images_to_salon/'));
    request.fields['salon'] = salonId.toString(); // Ajoute l'ID du salon comme champ de la requête.

    // Ajoute chaque image à la requête.
    for (var image in _images) {
      if (kIsWeb && image.bytes != null) {
        // Pour le web, envoie les données binaires.
        request.files.add(http.MultipartFile.fromBytes('image', image.bytes!, filename: 'image.png'));
      } else if (!kIsWeb && image.file != null) {
        // Pour les plateformes natives, envoie le fichier depuis son chemin.
        request.files.add(await http.MultipartFile.fromPath('image', image.file!.path, filename: path.basename(image.file!.path)));
      }
    }

    try {
      // Envoie la requête et attend la réponse.
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 201) {
        // Si la création réussit (code 201), affiche un message de succès.
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Images ajoutées à la galerie avec succès !")));
        // Redirige l'utilisateur vers la page d'accueil et supprime l'historique de navigation.
        if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomePage()), (route) => false);
      } else {
        // Si l'API retourne une erreur, affiche le message d'erreur.
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur lors de l'envoi : ${response.body}")));
      }
    } catch (e) {
      // Gère les erreurs réseau.
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur réseau. Veuillez vérifier votre connexion.")));
    } finally {
      // Désactive l'indicateur de chargement, que la requête ait réussi ou échoué.
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9), // Couleur de fond claire.
      appBar: AppBar(
        title: const Text("Galerie du salon"),
        backgroundColor: const Color(0xFF7B61FF), // Couleur principale violette.
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // Supprime le bouton retour par défaut.
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Étire les enfants sur toute la largeur.
          children: [
            const Text("Ajoutez vos meilleures photos ✨", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            // Bouton pour lancer le sélecteur d'images.
            ElevatedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text("Choisir des images"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B61FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            // Grille pour afficher les images sélectionnées.
            Expanded(
              child: GridView.builder(
                itemCount: _images.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // Affiche 3 images par ligne.
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final image = _images[index];
                  // Chaque image est dans une pile pour superposer le bouton de suppression.
                  return Stack(
                    fit: StackFit.expand, // Fait en sorte que l'image remplisse la tuile.
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: kIsWeb && image.bytes != null
                            ? Image.memory(image.bytes!, fit: BoxFit.cover)
                            : Image.file(image.file!, fit: BoxFit.cover),
                      ),
                      // Bouton pour supprimer une image de la sélection.
                      Positioned(
                        top: 4, right: 4,
                        child: GestureDetector(
                          onTap: () => setState(() => _images.removeAt(index)),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(color: Color.fromRGBO(0, 0, 0, 0.6), shape: BoxShape.circle),
                            child: const Icon(Icons.close, size: 18, color: Colors.white),
                          ),
                        ),
                      )
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            // Bouton pour soumettre les images.
            SizedBox(
              width: double.infinity, // Le bouton prend toute la largeur.
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitImages, // Désactivé pendant le chargement.
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF39C12), // Couleur secondaire orange.
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : const Text("Envoyer les images", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}










// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:http/http.dart' as http;
// import 'package:path/path.dart' as path;
// import 'dart:convert';
// import 'package:provider/provider.dart';
// import '../../../services/providers/current_user_provider.dart';
// import '../../home_page.dart';
//
// class GalleryImage {
//   final Uint8List? bytes;
//   final File? file;
//   GalleryImage({this.bytes, this.file});
// }
//
// class AddGalleryPage extends StatefulWidget {
//   const AddGalleryPage({super.key});
//
//   @override
//   State<AddGalleryPage> createState() => _AddGalleryPageState();
// }
//
// class _AddGalleryPageState extends State<AddGalleryPage> {
//   List<GalleryImage> _images = [];
//   bool _isLoading = false;
//   int? salonId;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchSalonId();
//   }
//
//   Future<void> _fetchSalonId() async {
//     final currentUser = Provider.of<CurrentUserProvider>(context, listen: false).currentUser;
//     if (currentUser == null) return;
//
//     try {
//       final response = await http.get(
//         Uri.parse('https://www.hairbnb.site/api/get_salon_by_coiffeuse/${currentUser.idTblUser}/'),
//       );
//
//       if (response.statusCode == 200) {
//         final data = json.decode(utf8.decode(response.bodyBytes));
//         setState(() {
//           salonId = data['salon']['idTblSalon'];
//         });
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Erreur lors de la récupération du salon.")),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Erreur réseau lors de la récupération du salon.")),
//       );
//     }
//   }
//
//   Future<void> _pickImages() async {
//     final result = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.image);
//     if (result != null && result.files.isNotEmpty) {
//       final validFiles = result.files.where((f) => f.size <= 6 * 1024 * 1024);
//       final List<GalleryImage> selectedImages = validFiles.map((f) {
//         return kIsWeb
//             ? GalleryImage(bytes: f.bytes)
//             : GalleryImage(file: File(f.path!));
//       }).toList();
//
//       if (selectedImages.length != result.files.length) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Certaines images dépassent 6MB et ont été ignorées.")),
//         );
//       }
//
//       setState(() {
//         _images.addAll(selectedImages);
//         if (_images.length > 12) {
//           _images = _images.sublist(0, 12);
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("Maximum 12 images autorisées.")),
//           );
//         }
//       });
//     }
//   }
//
//   Future<void> _submitImages() async {
//     if (_images.length < 3) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Veuillez ajouter au moins 3 images.")),
//       );
//       return;
//     }
//
//     print("📦 Salon ID pour upload: $salonId");
//
//     if (salonId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Salon non trouvé.")),
//       );
//       return;
//     }
//
//     setState(() => _isLoading = true);
//
//     final request = http.MultipartRequest(
//       'POST',
//       Uri.parse('https://www.hairbnb.site/api/add_images_to_salon/'),
//     );
//     request.fields['salon'] = salonId.toString();
//
//     for (var image in _images) {
//       if (kIsWeb && image.bytes != null) {
//         request.files.add(http.MultipartFile.fromBytes(
//           'image',
//           image.bytes!,
//           filename: 'image.png',
//         ));
//       } else if (!kIsWeb && image.file != null) {
//         request.files.add(await http.MultipartFile.fromPath(
//           'image',
//           image.file!.path,
//           filename: path.basename(image.file!.path),
//         ));
//       }
//     }
//
//     try {
//       final streamed = await request.send();
//       final response = await http.Response.fromStream(streamed);
//       if (response.statusCode == 201) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Images téléchargées avec succès.")),
//         );
//         Navigator.pushAndRemoveUntil(
//           context,
//           MaterialPageRoute(builder: (context) => const HomePage()),
//               (route) => false,
//         );
//
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Erreur : ${response.body}")),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Erreur réseau.")),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F7F9),
//       appBar: AppBar(
//         title: const Text("Galerie du salon"),
//         backgroundColor: const Color(0xFF7B61FF),
//         foregroundColor: Colors.white,
//         elevation: 0,
//         centerTitle: true,
//         automaticallyImplyLeading: false,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text("Ajoutez vos meilleures photos ✨",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
//             const SizedBox(height: 20),
//             ElevatedButton.icon(
//               onPressed: _pickImages,
//               icon: const Icon(Icons.add_photo_alternate),
//               label: const Text("Ajouter des images"),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF7B61FF),
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//               ),
//             ),
//             const SizedBox(height: 20),
//             Expanded(
//               child: GridView.builder(
//                 itemCount: _images.length,
//                 gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                   crossAxisCount: 3,
//                   crossAxisSpacing: 10,
//                   mainAxisSpacing: 10,
//                 ),
//                 itemBuilder: (context, index) {
//                   final image = _images[index];
//                   return Stack(
//                     children: [
//                       ClipRRect(
//                         borderRadius: BorderRadius.circular(12),
//                         child: kIsWeb && image.bytes != null
//                             ? Image.memory(image.bytes!, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
//                             : Image.file(image.file!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
//                       ),
//                       Positioned(
//                         top: 4,
//                         right: 4,
//                         child: GestureDetector(
//                           onTap: () => setState(() => _images.removeAt(index)),
//                           child: Container(
//                             padding: const EdgeInsets.all(2),
//                             decoration: BoxDecoration(
//                               color: const Color.fromRGBO(0, 0, 0, 0.6),
//                               shape: BoxShape.circle,
//                             ),
//                             child: const Icon(Icons.close, size: 18, color: Colors.white),
//                           ),
//                         ),
//                       )
//                     ],
//                   );
//                 },
//               ),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _isLoading ? null : _submitImages,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF7B61FF),
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//               ),
//               child: _isLoading
//                   ? const CircularProgressIndicator(color: Colors.white)
//                   : const Text("Envoyer les images", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
