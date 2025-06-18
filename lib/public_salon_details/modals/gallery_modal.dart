/// *************************************************************************************************
///
/// BANNER : EXPLICATION GÉNÉRALE DE LA FENÊTRE MODALE DE GALERIE
///
/// Ce fichier définit `GalleryModal`, un `StatefulWidget` qui fournit une interface
/// utilisateur pour ajouter des images à la galerie d'un salon.
///
/// Objectif :
/// Permettre à l'utilisateur (probablement le propriétaire du salon) de sélectionner
/// plusieurs images depuis son appareil, de les prévisualiser, et de les téléverser
/// vers le serveur. Le widget gère les contraintes de l'API comme le nombre d'images
/// et la taille maximale des fichiers.
///
/// Fonctionnalités Clés :
/// - Sélection de Fichiers Multi-plateformes : Utilise `file_picker` pour fonctionner
/// à la fois sur le web (en utilisant les bytes du fichier) et sur les plateformes
/// natives (en utilisant le chemin du fichier).
/// - Validation Côté Client : Vérifie le nombre d'images sélectionnées (minimum et
/// maximum) et la taille de chaque fichier avant de permettre le téléversement.
/// - Prévisualisation : Affiche une grille des images sélectionnées avec une option pour
/// retirer chaque image individuellement.
/// - Gestion des États : Gère les états de chargement (`_isUploading`) et d'erreur
/// (`_errorMessage`) pour fournir un retour visuel clair à l'utilisateur.
/// - Communication API : Délègue la logique de téléversement à une classe de service
/// dédiée (`GalleryApi`).
///
///*************************************************************************************************
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../../../models/public_salon_details.dart';
import '../api/gallery_api.dart';

/// Un widget de feuille modale pour ajouter des images à la galerie d'un salon.
class GalleryModal extends StatefulWidget {
  final int salonId;
  final int currentImagesCount;
  final Function(List<SalonImage>) onImagesAdded;

  const GalleryModal({
    super.key,
    required this.salonId,
    required this.currentImagesCount,
    required this.onImagesAdded,
  });

  @override
  State<GalleryModal> createState() => _GalleryModalState();
}

/// La classe d'état pour `GalleryModal`.
class _GalleryModalState extends State<GalleryModal> {
  // --- Variables d'état ---

  // Liste pour les fichiers sur plateformes natives (iOS, Android).
  final List<File> _selectedFiles = [];
  // Liste pour les données de fichiers sur le web.
  final List<PlatformFile> _selectedFileData = [];
  // Gère l'état de chargement pendant le téléversement.
  bool _isUploading = false;
  // Stocke le message d'erreur à afficher.
  String? _errorMessage;

  // --- Constantes de l'API ---
  final int _maxImageSize = 6 * 1024 * 1024; // 6MB en octets.
  final int _minImagesRequired = 3; // Nombre minimum d'images.
  final int _maxImagesAllowed = 12; // Nombre maximum d'images.

  // --- Getters pour simplifier la logique ---

  // Retourne le nombre total d'images sélectionnées.
  int get _selectedImagesCount => _selectedFiles.length + _selectedFileData.length;
  // Vérifie si le minimum d'images requis est atteint.
  bool get _minimumImagesReached => _selectedImagesCount >= _minImagesRequired;
  // Vérifie si le maximum d'images autorisé est dépassé.
  bool get _maximumImagesExceeded => _selectedImagesCount > _maxImagesAllowed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          if (_errorMessage != null) _buildErrorMessage(),
          Expanded(
            child: _buildImagePreview(),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  /// Construit l'en-tête de la feuille modale.
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ajouter des images',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Sélectionnez entre 3 et 12 images',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                'Taille maximale: 6MB par image',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  /// Construit la bannière d'affichage d'erreur.
  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.poppins(color: Colors.red[700]),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.red[700], size: 18),
            onPressed: () {
              setState(() {
                _errorMessage = null;
              });
            },
          ),
        ],
      ),
    );
  }

  /// Construit la zone de prévisualisation des images ou l'état vide.
  Widget _buildImagePreview() {
    final totalSelectedImages = _selectedImagesCount;

    if (totalSelectedImages == 0) {
      // Affiche un message si aucune image n'est sélectionnée.
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucune image sélectionnée',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Text(
              'Sélectionnez entre 3 et 12 images',
              style: GoogleFonts.poppins(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    // Affiche la grille des images sélectionnées.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Row(
            children: [
              Text(
                'Images sélectionnées ($totalSelectedImages)',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              if (_maximumImagesExceeded)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Maximum 12 images',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.red[700],
                    ),
                  ),
                ),
              const SizedBox(width: 16),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: totalSelectedImages,
            itemBuilder: (context, index) {
              // Gère l'affichage pour le web et les plateformes natives.
              if (kIsWeb && index < _selectedFileData.length) {
                final fileData = _selectedFileData[index];
                return _buildImagePreviewItem(
                  bytes: fileData.bytes,
                  onRemove: () => setState(() => _selectedFileData.removeAt(index)),
                );
              } else if (!kIsWeb && index < _selectedFiles.length) {
                final file = _selectedFiles[index];
                return _buildImagePreviewItem(
                  file: file,
                  onRemove: () => setState(() => _selectedFiles.removeAt(index)),
                );
              } else {
                // Cette logique gère un cas mixte (improbable mais sûr).
                if (kIsWeb) {
                  final fileIndex = index - _selectedFileData.length;
                  if (fileIndex >= 0 && fileIndex < _selectedFiles.length) {
                    final file = _selectedFiles[fileIndex];
                    return _buildImagePreviewItem(file: file, onRemove: () => setState(() => _selectedFiles.removeAt(fileIndex)));
                  }
                } else {
                  final dataIndex = index - _selectedFiles.length;
                  if (dataIndex >= 0 && dataIndex < _selectedFileData.length) {
                    final fileData = _selectedFileData[dataIndex];
                    return _buildImagePreviewItem(bytes: fileData.bytes, onRemove: () => setState(() => _selectedFileData.removeAt(dataIndex)));
                  }
                }
                return const SizedBox();
              }
            },
          ),
        ),
      ],
    );
  }

  /// Construit un élément de la grille de prévisualisation d'image.
  Widget _buildImagePreviewItem({File? file, Uint8List? bytes, required Function onRemove}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Affiche l'image.
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: bytes != null
              ? Image.memory(bytes, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
              : file != null
              ? Image.file(file, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
              : Container(color: Colors.grey[200]),
        ),
        // Bouton de suppression superposé.
        Positioned(
          top: -8,
          right: -8,
          child: GestureDetector(
            onTap: () => onRemove(),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  /// Construit le pied de page avec les boutons d'action.
  Widget _buildFooter() {
    // Les boutons sont activés ou désactivés en fonction de l'état actuel.
    final canAddMore = _selectedImagesCount < _maxImagesAllowed && !_isUploading;
    final canUpload = _minimumImagesReached && !_maximumImagesExceeded && !_isUploading;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 1, offset: const Offset(0, -1))],
      ),
      child: Column(
        children: [
          // Bouton pour sélectionner plus d'images.
          ElevatedButton.icon(
            onPressed: canAddMore ? _pickImages : null,
            icon: const Icon(Icons.photo_library),
            label: Text('Sélectionner des images', style: GoogleFonts.poppins()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),
          // Bouton pour téléverser les images.
          ElevatedButton(
            onPressed: canUpload ? _uploadImages : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isUploading ? Colors.grey : (canUpload ? Theme.of(context).primaryColor : Colors.grey[300]),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isUploading
            // Affiche un indicateur de chargement pendant le téléversement.
                ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)), const SizedBox(width: 12), Text('Téléchargement en cours...', style: GoogleFonts.poppins())])
                : Text('Ajouter à la galerie', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
          ),
          // Affiche un message d'avertissement si le minimum n'est pas atteint.
          if (!_minimumImagesReached && _selectedImagesCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Sélectionnez au moins 3 images', style: GoogleFonts.poppins(color: Colors.red[700], fontSize: 12)),
            ),
        ],
      ),
    );
  }

  /// Ouvre le sélecteur de fichiers et gère la sélection des images.
  Future<void> _pickImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true, // Important pour la compatibilité web.
      );

      if (result != null && result.files.isNotEmpty) {
        List<File> validFiles = [];
        List<PlatformFile> validFileData = [];
        List<String> errorMessages = [];

        // Itère sur chaque fichier sélectionné pour le valider.
        for (var file in result.files) {
          if (file.size > _maxImageSize) {
            errorMessages.add('${file.name} dépasse la taille limite de 6MB');
            continue;
          }

          if (kIsWeb) {
            validFileData.add(file);
          } else {
            if (file.path == null) continue;
            validFiles.add(File(file.path!));
          }

          if (_selectedFiles.length + validFiles.length + _selectedFileData.length + validFileData.length > _maxImagesAllowed) {
            errorMessages.add('Vous ne pouvez pas sélectionner plus de $_maxImagesAllowed images');
            break;
          }
        }

        setState(() {
          _selectedFiles.addAll(validFiles);
          _selectedFileData.addAll(validFileData);
          if (errorMessages.isNotEmpty) {
            _errorMessage = errorMessages.join('. ');
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la sélection des images: $e';
      });
    }
  }

  /// Gère la logique de téléversement des images vers l'API.
  Future<void> _uploadImages() async {
    if (_selectedFiles.isEmpty && _selectedFileData.isEmpty) return;

    // Double vérification des contraintes avant l'envoi.
    if (_selectedImagesCount < _minImagesRequired) {
      setState(() => _errorMessage = 'Veuillez sélectionner au moins $_minImagesRequired images.');
      return;
    }
    if (_selectedImagesCount > _maxImagesAllowed) {
      setState(() => _errorMessage = 'Vous ne pouvez pas télécharger plus de $_maxImagesAllowed images.');
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      List<SalonImage> newImages = [];

      // Gère le cas du web.
      if (kIsWeb && _selectedFileData.isNotEmpty) {
        final List<http.MultipartFile> webFiles = [];
        for (var fileData in _selectedFileData) {
          if (fileData.bytes != null) {
            webFiles.add(http.MultipartFile.fromBytes('image', fileData.bytes!, filename: fileData.name));
          }
        }
        if (webFiles.isNotEmpty) {
          final webImages = await GalleryApi.uploadImagesForWeb(widget.salonId, webFiles);
          newImages.addAll(webImages);
        }
      }

      // Gère le cas des plateformes natives.
      if (_selectedFiles.isNotEmpty) {
        final nativeImages = await GalleryApi.uploadImages(widget.salonId, _selectedFiles);
        newImages.addAll(nativeImages);
      }

      // Appelle le callback de succès et ferme la modale.
      widget.onImagesAdded(newImages);
      if(mounted) Navigator.pop(context);

    } catch (e) {
      // Gère les erreurs de l'API.
      setState(() {
        _isUploading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }
}







// // lib/public_salon_details/widgets/gallery_modal.dart
//
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
// import 'package:google_fonts/google_fonts.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:http/http.dart' as http;
// import '../../../models/public_salon_details.dart';
// import '../api/gallery_api.dart';
//
// class GalleryModal extends StatefulWidget {
//   final int salonId;
//   final int currentImagesCount;
//   final Function(List<SalonImage>) onImagesAdded;
//
//   const GalleryModal({
//     super.key,
//     required this.salonId,
//     required this.currentImagesCount,
//     required this.onImagesAdded,
//   });
//
//   @override
//   State<GalleryModal> createState() => _GalleryModalState();
// }
//
// class _GalleryModalState extends State<GalleryModal> {
//   final List<File> _selectedFiles = [];
//   final List<PlatformFile> _selectedFileData = []; // Pour le web
//   bool _isUploading = false;
//   String? _errorMessage;
//   final int _maxImageSize = 6 * 1024 * 1024; // 6MB en octets selon l'API
//   final int _minImagesRequired = 3; // Minimum requis par l'API
//   final int _maxImagesAllowed = 12; // Maximum permis par l'API
//
//   int get _selectedImagesCount => _selectedFiles.length + _selectedFileData.length;
//   bool get _minimumImagesReached => _selectedImagesCount >= _minImagesRequired;
//   bool get _maximumImagesExceeded => _selectedImagesCount > _maxImagesAllowed;
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: MediaQuery.of(context).size.height * 0.8,
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       child: Column(
//         children: [
//           _buildHeader(),
//           if (_errorMessage != null) _buildErrorMessage(),
//           Expanded(
//             child: _buildImagePreview(),
//           ),
//           _buildFooter(),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildHeader() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             spreadRadius: 1,
//             blurRadius: 1,
//             offset: const Offset(0, 1),
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Ajouter des images',
//                 style: GoogleFonts.poppins(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               Text(
//                 'Sélectionnez entre 3 et 12 images',
//                 style: GoogleFonts.poppins(
//                   fontSize: 12,
//                   color: Colors.grey[600],
//                 ),
//               ),
//               Text(
//                 'Taille maximale: 6MB par image',
//                 style: GoogleFonts.poppins(
//                   fontSize: 12,
//                   color: Colors.grey[600],
//                 ),
//               ),
//             ],
//           ),
//           IconButton(
//             icon: const Icon(Icons.close),
//             onPressed: () => Navigator.pop(context),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildErrorMessage() {
//     return Container(
//       margin: const EdgeInsets.all(16),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.red.shade50,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: Colors.red.shade200),
//       ),
//       child: Row(
//         children: [
//           Icon(Icons.error_outline, color: Colors.red[700]),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Text(
//               _errorMessage!,
//               style: GoogleFonts.poppins(color: Colors.red[700]),
//             ),
//           ),
//           IconButton(
//             icon: Icon(Icons.close, color: Colors.red[700], size: 18),
//             onPressed: () {
//               setState(() {
//                 _errorMessage = null;
//               });
//             },
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildImagePreview() {
//     // Compter le nombre total d'images sélectionnées (web + mobile)
//     final totalSelectedImages = _selectedImagesCount;
//
//     if (totalSelectedImages == 0) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.photo_library_outlined, size: 60, color: Colors.grey[400]),
//             const SizedBox(height: 16),
//             Text(
//               'Aucune image sélectionnée',
//               style: GoogleFonts.poppins(color: Colors.grey[600]),
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'Sélectionnez entre 3 et 12 images',
//               style: GoogleFonts.poppins(color: Colors.grey[500]),
//             ),
//           ],
//         ),
//       );
//     }
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
//           child: Row(
//             children: [
//               Text(
//                 'Images sélectionnées ($totalSelectedImages)',
//                 style: GoogleFonts.poppins(
//                   fontWeight: FontWeight.w600,
//                   fontSize: 16,
//                 ),
//               ),
//               const Spacer(),
//               if (_maximumImagesExceeded)
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: Colors.red.shade100,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Text(
//                     'Maximum 12 images',
//                     style: GoogleFonts.poppins(
//                       fontSize: 12,
//                       color: Colors.red[700],
//                     ),
//                   ),
//                 ),
//               const SizedBox(width: 16),
//             ],
//           ),
//         ),
//         Expanded(
//           child: GridView.builder(
//             padding: const EdgeInsets.all(16),
//             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 3,
//               childAspectRatio: 1,
//               crossAxisSpacing: 8,
//               mainAxisSpacing: 8,
//             ),
//             itemCount: totalSelectedImages,
//             itemBuilder: (context, index) {
//               // Afficher les images en fonction de la plateforme
//               if (kIsWeb && index < _selectedFileData.length) {
//                 // Affichage pour le web
//                 final fileData = _selectedFileData[index];
//                 return _buildImagePreviewItem(
//                   bytes: fileData.bytes,
//                   onRemove: () {
//                     setState(() {
//                       _selectedFileData.removeAt(index);
//                     });
//                   },
//                 );
//               } else if (!kIsWeb && index < _selectedFiles.length) {
//                 // Affichage pour mobile
//                 final file = _selectedFiles[index];
//                 return _buildImagePreviewItem(
//                   file: file,
//                   onRemove: () {
//                     setState(() {
//                       _selectedFiles.removeAt(index);
//                     });
//                   },
//                 );
//               } else {
//                 // Dans le cas où on a des images web et des images mobiles
//                 if (kIsWeb) {
//                   final fileIndex = index - _selectedFileData.length;
//                   if (fileIndex >= 0 && fileIndex < _selectedFiles.length) {
//                     final file = _selectedFiles[fileIndex];
//                     return _buildImagePreviewItem(
//                       file: file,
//                       onRemove: () {
//                         setState(() {
//                           _selectedFiles.removeAt(fileIndex);
//                         });
//                       },
//                     );
//                   }
//                 } else {
//                   final dataIndex = index - _selectedFiles.length;
//                   if (dataIndex >= 0 && dataIndex < _selectedFileData.length) {
//                     final fileData = _selectedFileData[dataIndex];
//                     return _buildImagePreviewItem(
//                       bytes: fileData.bytes,
//                       onRemove: () {
//                         setState(() {
//                           _selectedFileData.removeAt(dataIndex);
//                         });
//                       },
//                     );
//                   }
//                 }
//                 return const SizedBox(); // Fallback si nécessaire
//               }
//             },
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildImagePreviewItem({File? file, Uint8List? bytes, required Function onRemove}) {
//     return Stack(
//       clipBehavior: Clip.none,
//       children: [
//         ClipRRect(
//           borderRadius: BorderRadius.circular(8),
//           child: bytes != null
//               ? Image.memory(
//             bytes,
//             fit: BoxFit.cover,
//             width: double.infinity,
//             height: double.infinity,
//           )
//               : file != null
//               ? Image.file(
//             file,
//             fit: BoxFit.cover,
//             width: double.infinity,
//             height: double.infinity,
//           )
//               : Container(color: Colors.grey[200]),
//         ),
//         Positioned(
//           top: -8,
//           right: -8,
//           child: GestureDetector(
//             onTap: () => onRemove(),
//             child: Container(
//               padding: const EdgeInsets.all(2),
//               decoration: const BoxDecoration(
//                 color: Colors.red,
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(
//                 Icons.close,
//                 color: Colors.white,
//                 size: 16,
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildFooter() {
//     final canAddMore = _selectedImagesCount < _maxImagesAllowed && !_isUploading;
//     final canUpload = _minimumImagesReached && !_maximumImagesExceeded && !_isUploading;
//
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             spreadRadius: 1,
//             blurRadius: 1,
//             offset: const Offset(0, -1),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           ElevatedButton.icon(
//             onPressed: canAddMore ? _pickImages : null,
//             icon: const Icon(Icons.photo_library),
//             label: Text('Sélectionner des images', style: GoogleFonts.poppins()),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Theme.of(context).primaryColor,
//               foregroundColor: Colors.white,
//               minimumSize: const Size(double.infinity, 48),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//           ),
//           const SizedBox(height: 16),
//           ElevatedButton(
//             onPressed: canUpload ? _uploadImages : null,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: _isUploading
//                   ? Colors.grey
//                   : canUpload
//                   ? Theme.of(context).primaryColor
//                   : Colors.grey[300],
//               foregroundColor: Colors.white,
//               minimumSize: const Size(double.infinity, 48),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             child: _isUploading
//                 ? Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const SizedBox(
//                   width: 20,
//                   height: 20,
//                   child: CircularProgressIndicator(
//                     color: Colors.white,
//                     strokeWidth: 2,
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Text(
//                   'Téléchargement en cours...',
//                   style: GoogleFonts.poppins(),
//                 ),
//               ],
//             )
//                 : Text(
//               'Ajouter à la galerie',
//               style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
//             ),
//           ),
//           if (!_minimumImagesReached && _selectedImagesCount > 0)
//             Padding(
//               padding: const EdgeInsets.only(top: 8),
//               child: Text(
//                 'Sélectionnez au moins 3 images',
//                 style: GoogleFonts.poppins(
//                   color: Colors.red[700],
//                   fontSize: 12,
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _pickImages() async {
//     try {
//       final result = await FilePicker.platform.pickFiles(
//         type: FileType.image,
//         allowMultiple: true,
//         withData: true, // Important: récupérer les données en bytes pour la compatibilité web
//       );
//
//       if (result != null && result.files.isNotEmpty) {
//         List<File> validFiles = [];
//         List<PlatformFile> validFileData = [];
//         List<String> errorMessages = [];
//
//         for (var file in result.files) {
//           // Vérifier la taille
//           if (file.size > _maxImageSize) {
//             errorMessages.add('${file.name} dépasse la taille limite de 6MB');
//             continue;
//           }
//
//           if (kIsWeb) {
//             // Sur le web, stocker les informations de PlatformFile
//             validFileData.add(file);
//           } else {
//             // Sur mobile, utiliser le path
//             if (file.path == null) continue;
//             final fileObj = File(file.path!);
//             validFiles.add(fileObj);
//           }
//
//           // Vérifier si nous avons atteint le nombre maximal d'images
//           if (_selectedFiles.length + validFiles.length + _selectedFileData.length + validFileData.length > _maxImagesAllowed) {
//             errorMessages.add('Vous ne pouvez pas sélectionner plus de $_maxImagesAllowed images');
//             break;
//           }
//         }
//
//         setState(() {
//           _selectedFiles.addAll(validFiles);
//           _selectedFileData.addAll(validFileData);
//           if (errorMessages.isNotEmpty) {
//             _errorMessage = errorMessages.join('. ');
//           }
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Erreur lors de la sélection des images: $e';
//       });
//     }
//   }
//
//   Future<void> _uploadImages() async {
//     if (_selectedFiles.isEmpty && _selectedFileData.isEmpty) return;
//
//     // Vérifier les conditions de l'API
//     if (_selectedImagesCount < _minImagesRequired) {
//       setState(() {
//         _errorMessage = 'Veuillez sélectionner au moins $_minImagesRequired images.';
//       });
//       return;
//     }
//
//     if (_selectedImagesCount > _maxImagesAllowed) {
//       setState(() {
//         _errorMessage = 'Vous ne pouvez pas télécharger plus de $_maxImagesAllowed images.';
//       });
//       return;
//     }
//
//     setState(() {
//       _isUploading = true;
//       _errorMessage = null;
//     });
//
//     try {
//       List<SalonImage> newImages = [];
//
//       if (kIsWeb && _selectedFileData.isNotEmpty) {
//         // Pour le web, convertir les PlatformFile en MultipartFile
//         final List<http.MultipartFile> webFiles = [];
//
//         for (var fileData in _selectedFileData) {
//           if (fileData.bytes != null) {
//             webFiles.add(
//                 http.MultipartFile.fromBytes(
//                   'image',
//                   fileData.bytes!,
//                   filename: fileData.name,
//                 )
//             );
//           }
//         }
//
//         // Appel API pour le web
//         if (webFiles.isNotEmpty) {
//           final webImages = await GalleryApi.uploadImagesForWeb(
//             widget.salonId,
//             webFiles,
//           );
//           newImages.addAll(webImages);
//         }
//       }
//
//       // Pour les plateformes natives
//       if (_selectedFiles.isNotEmpty) {
//         final nativeImages = await GalleryApi.uploadImages(
//           widget.salonId,
//           _selectedFiles,
//         );
//         newImages.addAll(nativeImages);
//       }
//
//       widget.onImagesAdded(newImages);
//       Navigator.pop(context);
//
//     } catch (e) {
//       setState(() {
//         _isUploading = false;
//         _errorMessage = e.toString().replaceAll('Exception: ', '');
//       });
//     }
//   }
// }
