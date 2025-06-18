/// *************************************************************************************************
///
/// BANNER : EXPLICATION GÉNÉRALE DU WIDGET
///
/// Ce fichier définit `GalleryWidget`, un `StatefulWidget` conçu pour afficher et
/// gérer la galerie d'images d'un salon.
///
/// Objectif :
/// - Afficher les images de la galerie dans une grille paginée.
/// - Permettre aux utilisateurs de visualiser une image en plein écran.
/// - Permettre au propriétaire du salon d'ajouter ou de supprimer des images.
///
/// Fonctionnalités Clés :
/// - Vue en Grille et Agrandie : Affiche les images sous forme de grille et permet de
/// cliquer sur une image pour la voir en plus grand avec des options de navigation.
/// - Pagination : Si la galerie contient de nombreuses images, elles sont réparties
/// sur plusieurs pages pour améliorer les performances et la clarté.
/// - Actions du Propriétaire : Si l'utilisateur visionnant la galerie est le
/// propriétaire du salon (`_isOwner`), des boutons pour ajouter et supprimer des
/// images sont affichés.
/// - Rafraîchissement des Données : Utilise `RefreshIndicator` pour permettre de
/// recharger la liste des images en tirant la grille vers le bas.
/// - Gestion d'État Asynchrone : Gère les états de chargement lors du rafraîchissement
/// ou de la suppression d'images.
///
///*************************************************************************************************
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/public_salon_details.dart';
import '../api/gallery_api.dart';
import '../modals/gallery_modal.dart';

/// Un widget qui affiche une galerie d'images pour un salon.
class GalleryWidget extends StatefulWidget {
  final PublicSalonDetails salonDetails;
  final int currentUserId;
  // Callback optionnel pour notifier le widget parent qu'une mise à jour a eu lieu.
  final Function(List<SalonImage>)? onImagesUpdated;

  const GalleryWidget({
    super.key,
    required this.salonDetails,
    required this.currentUserId,
    this.onImagesUpdated,
  });

  @override
  State<GalleryWidget> createState() => _GalleryWidgetState();
}

/// La classe d'état pour `GalleryWidget`.
class _GalleryWidgetState extends State<GalleryWidget> {
  // --- Variables d'état ---

  int _currentPage = 0; // Page actuelle de la galerie.
  final int _imagesPerPage = 10; // Nombre d'images à afficher par page.
  bool _isLoading = false; // `true` si une opération est en cours.
  List<SalonImage> _images = []; // La liste des images de la galerie.
  int? _enlargedImageIndex; // L'index de l'image actuellement agrandie.

  @override
  void initState() {
    super.initState();
    // Initialise la liste d'images avec celles passées en paramètre.
    _images = List.from(widget.salonDetails.images);
    // Lance un rafraîchissement pour s'assurer que les images sont à jour.
    _refreshImages();
  }

  /// Getter pour vérifier si l'utilisateur actuel est le propriétaire du salon.
  bool get _isOwner =>
      widget.currentUserId ==
          widget.salonDetails.coiffeuse.idTblUser.idTblUser;

  /// Getter pour obtenir la liste des images à afficher sur la page courante.
  List<SalonImage> get _currentPageImages {
    final startIndex = _currentPage * _imagesPerPage;
    final endIndex = startIndex + _imagesPerPage;

    if (startIndex >= _images.length) {
      return [];
    }

    return _images.sublist(
      startIndex,
      endIndex > _images.length ? _images.length : endIndex,
    );
  }

  /// Getter pour calculer le nombre total de pages.
  int get _totalPages => (_images.length / _imagesPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    // Le `ConstrainedBox` limite la hauteur maximale du widget.
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      // `Stack` permet de superposer la vue agrandie, le FAB, et l'indicateur de chargement.
      child: Stack(
        children: [
          _enlargedImageIndex != null
              ? _buildEnlargedView() // Affiche la vue agrandie si un index est sélectionné.
              : _buildGalleryView(), // Sinon, affiche la grille de la galerie.

          // Affiche le bouton d'ajout d'image pour le propriétaire si la galerie n'est pas en plein écran.
          if (_isOwner && _enlargedImageIndex == null && _images.length < 25)
            Positioned(
              bottom: 8,
              right: 8,
              child: FloatingActionButton.small(
                onPressed: _showAddImageModal,
                backgroundColor: Theme.of(context).primaryColor,
                child: const Icon(
                    Icons.add_photo_alternate_outlined, color: Colors.white, size: 20),
              ),
            ),

          // Affiche un indicateur de chargement superposé si une opération est en cours.
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  /// Construit la vue principale de la galerie (grille + pagination).
  Widget _buildGalleryView() {
    return Column(
      children: [
        Expanded(
          // Permet de rafraîchir la liste en tirant vers le bas.
          child: RefreshIndicator(
            onRefresh: _refreshImages,
            child: _images.isEmpty
                ? _buildEmptyStateWithRefresh() // Affiche un message si la galerie est vide.
                : _buildImagesGrid(), // Affiche la grille d'images.
          ),
        ),
        if (_images.isNotEmpty)
          _buildPaginationControls(), // Affiche les contrôles de pagination si nécessaire.
      ],
    );
  }

  /// Construit le widget à afficher lorsque la galerie est vide.
  Widget _buildEmptyStateWithRefresh() {
    // `ListView` avec `AlwaysScrollableScrollPhysics` permet au `RefreshIndicator` de fonctionner même si le contenu est vide.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.4,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_library_outlined, size: 60,
                    color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Aucune image disponible',
                  style: GoogleFonts.poppins(color: Colors.grey[600]),
                ),
                // Affiche un bouton d'ajout si l'utilisateur est le propriétaire.
                if (_isOwner) ...[
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showAddImageModal,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text('Ajouter des images', style: GoogleFonts.poppins()),
                    style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Construit la grille d'images paginée.
  Widget _buildImagesGrid() {
    final screenWidth = MediaQuery.of(context).size.width;

    // Adapte le nombre de colonnes pour être responsive.
    int crossAxisCount = screenWidth < 360 ? 3 : 4;
    if (screenWidth > 600) crossAxisCount = 5;
    if (screenWidth > 900) crossAxisCount = 6;
    double aspectRatio = 0.8;
    final spacing = 4.0;

    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: aspectRatio,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: _currentPageImages.length,
      itemBuilder: (context, index) {
        final actualIndex = _currentPage * _imagesPerPage + index;
        final imageUrl = _currentPageImages[index].image;

        return GestureDetector(
          onTap: () => setState(() => _enlargedImageIndex = actualIndex),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  // Affiche un indicateur de chargement pour chaque image.
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(child: CircularProgressIndicator(value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1) : null));
                  },
                  // Affiche une icône en cas d'erreur de chargement de l'image.
                  errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200], child: Center(child: Icon(Icons.broken_image, color: Colors.grey[400]))),
                ),
              ),
              // Affiche le bouton de suppression pour le propriétaire.
              if (_isOwner)
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _confirmDeleteImage(actualIndex),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.7), shape: BoxShape.circle),
                      child: const Icon(Icons.delete_outline, color: Colors.white, size: 16),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Construit la vue plein écran pour une image agrandie.
  Widget _buildEnlargedView() {
    if (_enlargedImageIndex == null || _enlargedImageIndex! >= _images.length) return const SizedBox.shrink();

    final imageUrl = _images[_enlargedImageIndex!].image;
    final fullImageUrl = imageUrl.startsWith('http') ? imageUrl : 'https://hairbnb.site/$imageUrl';
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Fond noir cliquable pour fermer la vue.
        GestureDetector(
          onTap: () => setState(() => _enlargedImageIndex = null),
          child: Container(color: Colors.black),
        ),
        // `InteractiveViewer` permet le zoom et le déplacement de l'image.
        InteractiveViewer(
          minScale: 0.2,
          maxScale: 2.0,
          constrained: true,
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: isSmallScreen ? screenSize.width * 0.7 : screenSize.width * 0.5, maxHeight: isSmallScreen ? screenSize.height * 0.5 : screenSize.height * 0.6),
              child: Image.network(
                fullImageUrl,
                fit: BoxFit.fill,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(child: CircularProgressIndicator(value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1) : null, color: Colors.white));
                },
                errorBuilder: (context, error, stackTrace) {
                  if (kDebugMode) {
                    print("Erreur de chargement d'image: $error pour $fullImageUrl");
                  }
                  return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.broken_image, color: Colors.white, size: 48), const SizedBox(height: 16), Text('Impossible de charger l\'image', style: GoogleFonts.poppins(color: Colors.white))]));
                },
              ),
            ),
          ),
        ),
        // Superposition des contrôles (fermer, compteur, supprimer).
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.black.withOpacity(0.5),
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 4 : 8, vertical: isSmallScreen ? 8 : 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => setState(() => _enlargedImageIndex = null), iconSize: isSmallScreen ? 20 : 24, padding: isSmallScreen ? const EdgeInsets.all(4) : const EdgeInsets.all(8)),
                Text('Image ${_enlargedImageIndex! + 1}/${_images.length}', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isSmallScreen ? 12 : 14)),
                if (_isOwner) IconButton(icon: const Icon(Icons.delete_outline, color: Colors.white), onPressed: () => _confirmDeleteImage(_enlargedImageIndex!), iconSize: isSmallScreen ? 20 : 24, padding: isSmallScreen ? const EdgeInsets.all(4) : const EdgeInsets.all(8)),
              ],
            ),
          ),
        ),
        // Flèches de navigation entre les images.
        if (_images.length > 1) ...[
          if (_enlargedImageIndex! > 0)
            Positioned(
              left: isSmallScreen ? 2 : 8,
              bottom: 0,
              top: 0,
              child: Center(child: IconButton(icon: Container(padding: EdgeInsets.all(isSmallScreen ? 4 : 8), decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle), child: Icon(Icons.chevron_left, color: Colors.white, size: isSmallScreen ? 20 : 24)), onPressed: () => setState(() => _enlargedImageIndex = _enlargedImageIndex! - 1))),
            ),
          if (_enlargedImageIndex! < _images.length - 1)
            Positioned(
              right: isSmallScreen ? 2 : 8,
              bottom: 0,
              top: 0,
              child: Center(child: IconButton(icon: Container(padding: EdgeInsets.all(isSmallScreen ? 4 : 8), decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle), child: Icon(Icons.chevron_right, color: Colors.white, size: isSmallScreen ? 20 : 24)), onPressed: () => setState(() => _enlargedImageIndex = _enlargedImageIndex! + 1))),
            ),
        ],
      ],
    );
  }

  /// Construit les contrôles de pagination (précédent, compteur, suivant).
  Widget _buildPaginationControls() {
    if (_totalPages <= 1) return const SizedBox.shrink();

    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    return Container(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: _currentPage > 0 ? Theme.of(context).primaryColor : Colors.grey[400], size: isSmallScreen ? 20 : 24),
            onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
            padding: isSmallScreen ? const EdgeInsets.all(4) : const EdgeInsets.all(8),
          ),
          Text('Page ${_currentPage + 1} sur $_totalPages', style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: isSmallScreen ? 12 : 14)),
          IconButton(
            icon: Icon(Icons.chevron_right, color: _currentPage < _totalPages - 1 ? Theme.of(context).primaryColor : Colors.grey[400], size: isSmallScreen ? 20 : 24),
            onPressed: _currentPage < _totalPages - 1 ? () => setState(() => _currentPage++) : null,
            padding: isSmallScreen ? const EdgeInsets.all(4) : const EdgeInsets.all(8),
          ),
        ],
      ),
    );
  }

  /// Affiche la feuille modale pour ajouter de nouvelles images.
  void _showAddImageModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GalleryModal(
        salonId: widget.salonDetails.idTblSalon,
        currentImagesCount: _images.length,
        onImagesAdded: (List<SalonImage> newImages) {
          _refreshImages(); // Rafraîchit toute la galerie pour inclure les nouvelles images.
          widget.onImagesUpdated?.call(newImages); // Notifie le widget parent.
        },
      ),
    );
  }

  /// Recharge la liste complète des images depuis l'API.
  Future<void> _refreshImages() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final freshImages = await GalleryApi.getSalonImages(widget.salonDetails.idTblSalon);
      if (mounted) {
        setState(() {
          _images = freshImages;
          _isLoading = false;
          // Ajuste la pagination si la page actuelle n'existe plus après un rafraîchissement.
          if (_currentPage >= _totalPages && _currentPage > 0) {
            _currentPage = _totalPages - 1;
          }
          if (_enlargedImageIndex != null && _enlargedImageIndex! >= _images.length) {
            _enlargedImageIndex = null;
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors du rafraîchissement des images: $e');
      }
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Impossible de charger les images: $e'), backgroundColor: Colors.red));
      }
    }
    return;
  }

  /// Affiche une boîte de dialogue de confirmation avant de supprimer une image.
  void _confirmDeleteImage(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer l\'image', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Êtes-vous sûr de vouloir supprimer cette image ? Cette action est irréversible.', style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Annuler', style: GoogleFonts.poppins())),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteImage(index);
            },
            child: Text('Supprimer', style: GoogleFonts.poppins(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Appelle l'API pour supprimer une image et met à jour l'état local.
  Future<void> _deleteImage(int index) async {
    setState(() => _isLoading = true);
    try {
      final imageId = _images[index].id;
      final success = await GalleryApi.deleteImage(imageId);

      if (success) {
        setState(() {
          if (_enlargedImageIndex != null) {
            _enlargedImageIndex = null;
          }
          _images.removeAt(index);
          if (_currentPage >= _totalPages && _currentPage > 0) {
            _currentPage = _totalPages - 1;
          }
        });
        widget.onImagesUpdated?.call(_images);
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image supprimée avec succès'), backgroundColor: Colors.green));
      } else {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Échec de la suppression de l\'image'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de la suppression: $e'), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }
}






// // lib/public_salon_details/widgets/gallery_widget.dart
//
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../../../models/public_salon_details.dart';
// import '../api/gallery_api.dart';
// import '../modals/gallery_modal.dart';
//
// class GalleryWidget extends StatefulWidget {
//   final PublicSalonDetails salonDetails;
//   final int currentUserId;
//   final Function(List<SalonImage>)? onImagesUpdated; // Callback optionnel pour notifier le parent
//
//   const GalleryWidget({
//     super.key,
//     required this.salonDetails,
//     required this.currentUserId,
//     this.onImagesUpdated,
//   });
//
//   @override
//   State<GalleryWidget> createState() => _GalleryWidgetState();
// }
//
// class _GalleryWidgetState extends State<GalleryWidget> {
//   int _currentPage = 0;
//   final int _imagesPerPage = 10;
//   bool _isLoading = false;
//   List<SalonImage> _images = [];
//   int? _enlargedImageIndex;
//
//   @override
//   void initState() {
//     super.initState();
//     _images = List.from(widget.salonDetails.images);
//     // Charger les images depuis l'API pour s'assurer d'avoir les plus récentes
//     _refreshImages();
//   }
//
//   bool get _isOwner =>
//       widget.currentUserId ==
//           widget.salonDetails.coiffeuse.idTblUser.idTblUser;
//
//   List<SalonImage> get _currentPageImages {
//     final startIndex = _currentPage * _imagesPerPage;
//     final endIndex = startIndex + _imagesPerPage;
//
//     if (startIndex >= _images.length) {
//       return [];
//     }
//
//     return _images.sublist(
//       startIndex,
//       endIndex > _images.length ? _images.length : endIndex,
//     );
//   }
//
//   int get _totalPages => (_images.length / _imagesPerPage).ceil();
//
//   @override
//   Widget build(BuildContext context) {
//     // Définir une taille maximale pour tout le widget
//     return ConstrainedBox(
//       constraints: BoxConstraints(
//         maxHeight: MediaQuery.of(context).size.height * 0.8, // Limiter la hauteur totale
//       ),
//       child: Stack(
//         children: [
//           _enlargedImageIndex != null
//               ? _buildEnlargedView()
//               : _buildGalleryView(),
//
//           if (_isOwner && _enlargedImageIndex == null && _images.length < 25)
//             Positioned(
//               bottom: 8, // Réduire le positionnement
//               right: 8,
//               child: FloatingActionButton.small( // Utiliser small FAB sur petits écrans
//                 onPressed: _showAddImageModal,
//                 backgroundColor: Theme.of(context).primaryColor,
//                 child: const Icon(
//                     Icons.add_photo_alternate_outlined, color: Colors.white, size: 20),
//               ),
//             ),
//
//           if (_isLoading)
//             Container(
//               color: Colors.black.withOpacity(0.5),
//               child: const Center(
//                 child: CircularProgressIndicator(),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildGalleryView() {
//     return Column(
//       children: [
//         Expanded(
//           child: RefreshIndicator(
//             onRefresh: _refreshImages,
//             child: _images.isEmpty
//                 ? _buildEmptyStateWithRefresh()
//                 : _buildImagesGrid(),
//           ),
//         ),
//         if (_images.isNotEmpty)
//           _buildPaginationControls(),
//       ],
//     );
//   }
//
//   Widget _buildEmptyStateWithRefresh() {
//     return ListView(
//       physics: const AlwaysScrollableScrollPhysics(),
//       children: [
//         SizedBox(
//           height: MediaQuery.of(context).size.height * 0.4,
//           child: Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.photo_library_outlined, size: 60,
//                     color: Colors.grey[400]),
//                 const SizedBox(height: 16),
//                 Text(
//                   'Aucune image disponible',
//                   style: GoogleFonts.poppins(color: Colors.grey[600]),
//                 ),
//                 if (_isOwner) ...[
//                   const SizedBox(height: 24),
//                   ElevatedButton.icon(
//                     onPressed: _showAddImageModal,
//                     icon: const Icon(Icons.add_photo_alternate_outlined),
//                     label: Text(
//                       'Ajouter des images',
//                       style: GoogleFonts.poppins(),
//                     ),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Theme.of(context).primaryColor,
//                       foregroundColor: Colors.white,
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildImagesGrid() {
//     // Force une grille avec beaucoup plus d'images par ligne pour réduire leur taille
//     final screenWidth = MediaQuery.of(context).size.width;
//
//     // Augmenter significativement le nombre de colonnes pour forcer des images plus petites
//     int crossAxisCount = screenWidth < 360 ? 3 : 4; // 3 colonnes pour très petits écrans, 4 pour les autres
//
//     // Sur les grands écrans, augmenter encore plus le nombre de colonnes
//     if (screenWidth > 600) crossAxisCount = 5;
//     if (screenWidth > 900) crossAxisCount = 6;
//
//     // Forcer un aspect ratio qui rend les images plus rectangulaires que carrées
//     double aspectRatio = 0.8; // Rend les images plus hautes que larges
//
//     // Réduire l'espacement
//     final spacing = 4.0; // Espacement très réduit
//
//     return GridView.builder(
//       padding: const EdgeInsets.all(4), // Réduire les paddings
//       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: crossAxisCount,
//         childAspectRatio: aspectRatio,
//         crossAxisSpacing: spacing,
//         mainAxisSpacing: spacing,
//       ),
//       itemCount: _currentPageImages.length,
//       itemBuilder: (context, index) {
//         final actualIndex = _currentPage * _imagesPerPage + index;
//         final imageUrl = _currentPageImages[index].image;
//
//         return GestureDetector(
//           onTap: () {
//             setState(() {
//               _enlargedImageIndex = actualIndex;
//             });
//           },
//           child: Stack(
//             fit: StackFit.expand,
//             children: [
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(8),
//                 child: Image.network(
//                   imageUrl,
//                   fit: BoxFit.cover,
//                   loadingBuilder: (context, child, loadingProgress) {
//                     if (loadingProgress == null) return child;
//                     return Center(
//                       child: CircularProgressIndicator(
//                         value: loadingProgress.expectedTotalBytes != null
//                             ? loadingProgress.cumulativeBytesLoaded /
//                             (loadingProgress.expectedTotalBytes ?? 1)
//                             : null,
//                       ),
//                     );
//                   },
//                   errorBuilder: (context, error, stackTrace) {
//                     return Container(
//                       color: Colors.grey[200],
//                       child: Center(
//                         child: Icon(Icons.broken_image,
//                             color: Colors.grey[400]),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//               if (_isOwner)
//                 Positioned(
//                   top: 4,
//                   right: 4,
//                   child: GestureDetector(
//                     onTap: () => _confirmDeleteImage(actualIndex),
//                     child: Container(
//                       padding: const EdgeInsets.all(4),
//                       decoration: BoxDecoration(
//                         color: Colors.red.withOpacity(0.7),
//                         shape: BoxShape.circle,
//                       ),
//                       child: const Icon(
//                         Icons.delete_outline,
//                         color: Colors.white,
//                         size: 16,
//                       ),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildEnlargedView() {
//     if (_enlargedImageIndex == null || _enlargedImageIndex! >= _images.length) {
//       return const SizedBox.shrink();
//     }
//
//     // Assurer que l'URL est complète
//     final imageUrl = _images[_enlargedImageIndex!].image;
//     final fullImageUrl = imageUrl.startsWith('http')
//         ? imageUrl
//         : 'https://hairbnb.site/$imageUrl';
//
//     // Détecter la taille de l'écran
//     final screenSize = MediaQuery.of(context).size;
//     final isSmallScreen = screenSize.width < 600;
//
//     return Stack(
//       fit: StackFit.expand,
//       children: [
//         GestureDetector(
//           onTap: () {
//             // Fermer l'image agrandie en cas de tap sur le fond
//             setState(() {
//               _enlargedImageIndex = null;
//             });
//           },
//           child: Container(color: Colors.black),
//         ),
//         InteractiveViewer(
//           minScale: 0.2, // Permettre un zoom arrière plus important
//           maxScale: 2.0, // Limiter le zoom avant
//           constrained: true, // Forcer le contenu à rester dans les contraintes
//           child: Center(
//             child: Container(
//               constraints: BoxConstraints(
//                 // Réduire fortement la taille maximale pour éviter le zoom
//                 maxWidth: isSmallScreen ? screenSize.width * 0.7 : screenSize.width * 0.5,
//                 maxHeight: isSmallScreen ? screenSize.height * 0.5 : screenSize.height * 0.6,
//               ),
//               child: Image.network(
//                 fullImageUrl,
//                 fit: BoxFit.fill, // Utiliser inside au lieu de contain pour être sûr que l'image soit complètement visible
//                 loadingBuilder: (context, child, loadingProgress) {
//                   if (loadingProgress == null) return child;
//                   return Center(
//                     child: CircularProgressIndicator(
//                       value: loadingProgress.expectedTotalBytes != null
//                           ? loadingProgress.cumulativeBytesLoaded /
//                           (loadingProgress.expectedTotalBytes ?? 1)
//                           : null,
//                       color: Colors.white,
//                     ),
//                   );
//                 },
//                 errorBuilder: (context, error, stackTrace) {
//                   print(
//                       "Erreur de chargement d'image: $error pour $fullImageUrl");
//                   return Center(
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         const Icon(
//                             Icons.broken_image, color: Colors.white, size: 48),
//                         const SizedBox(height: 16),
//                         Text(
//                           'Impossible de charger l\'image',
//                           style: GoogleFonts.poppins(color: Colors.white),
//                         ),
//                       ],
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//         ),
//         // Controls overlay - adapté pour les petits écrans
//         Positioned(
//           top: 0,
//           left: 0,
//           right: 0,
//           child: Container(
//             color: Colors.black.withOpacity(0.5),
//             padding: EdgeInsets.symmetric(
//                 horizontal: isSmallScreen ? 4 : 8,
//                 vertical: isSmallScreen ? 8 : 16
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.close, color: Colors.white),
//                   onPressed: () {
//                     setState(() {
//                       _enlargedImageIndex = null;
//                     });
//                   },
//                   iconSize: isSmallScreen ? 20 : 24,
//                   padding: isSmallScreen ? EdgeInsets.all(4) : EdgeInsets.all(8),
//                 ),
//                 Text(
//                   'Image ${_enlargedImageIndex! + 1}/${_images.length}',
//                   style: GoogleFonts.poppins(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                     fontSize: isSmallScreen ? 12 : 14,
//                   ),
//                 ),
//                 if (_isOwner)
//                   IconButton(
//                     icon: const Icon(Icons.delete_outline, color: Colors.white),
//                     onPressed: () => _confirmDeleteImage(_enlargedImageIndex!),
//                     iconSize: isSmallScreen ? 20 : 24,
//                     padding: isSmallScreen ? EdgeInsets.all(4) : EdgeInsets.all(8),
//                   ),
//               ],
//             ),
//           ),
//         ),
//         // Navigation arrows adaptés aux petits écrans
//         if (_images.length > 1) ...[
//           // Previous button
//           if (_enlargedImageIndex! > 0)
//             Positioned(
//               left: isSmallScreen ? 2 : 8,
//               bottom: 0,
//               top: 0,
//               child: Center(
//                 child: IconButton(
//                   icon: Container(
//                     padding: EdgeInsets.all(isSmallScreen ? 4 : 8),
//                     decoration: BoxDecoration(
//                       color: Colors.black.withOpacity(0.5),
//                       shape: BoxShape.circle,
//                     ),
//                     child: Icon(
//                       Icons.chevron_left,
//                       color: Colors.white,
//                       size: isSmallScreen ? 20 : 24,
//                     ),
//                   ),
//                   onPressed: () {
//                     setState(() {
//                       _enlargedImageIndex = _enlargedImageIndex! - 1;
//                     });
//                   },
//                 ),
//               ),
//             ),
//           // Next button
//           if (_enlargedImageIndex! < _images.length - 1)
//             Positioned(
//               right: isSmallScreen ? 2 : 8,
//               bottom: 0,
//               top: 0,
//               child: Center(
//                 child: IconButton(
//                   icon: Container(
//                     padding: EdgeInsets.all(isSmallScreen ? 4 : 8),
//                     decoration: BoxDecoration(
//                       color: Colors.black.withOpacity(0.5),
//                       shape: BoxShape.circle,
//                     ),
//                     child: Icon(
//                       Icons.chevron_right,
//                       color: Colors.white,
//                       size: isSmallScreen ? 20 : 24,
//                     ),
//                   ),
//                   onPressed: () {
//                     setState(() {
//                       _enlargedImageIndex = _enlargedImageIndex! + 1;
//                     });
//                   },
//                 ),
//               ),
//             ),
//         ],
//       ],
//     );
//   }
//
//   Widget _buildPaginationControls() {
//     if (_totalPages <= 1) {
//       return const SizedBox.shrink();
//     }
//
//     // Adapter la taille des contrôles de pagination pour les petits écrans
//     final isSmallScreen = MediaQuery.of(context).size.width < 600;
//
//     return Container(
//       padding: EdgeInsets.symmetric(
//           vertical: isSmallScreen ? 8 : 12
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           IconButton(
//             icon: Icon(
//               Icons.chevron_left,
//               color: _currentPage > 0
//                   ? Theme.of(context).primaryColor
//                   : Colors.grey[400],
//               size: isSmallScreen ? 20 : 24,
//             ),
//             onPressed: _currentPage > 0
//                 ? () {
//               setState(() {
//                 _currentPage--;
//               });
//             }
//                 : null,
//             padding: isSmallScreen ? EdgeInsets.all(4) : EdgeInsets.all(8),
//           ),
//           Text(
//             '${_currentPage + 1} / $_totalPages',
//             style: GoogleFonts.poppins(
//               fontWeight: FontWeight.w500,
//               fontSize: isSmallScreen ? 12 : 14,
//             ),
//           ),
//           IconButton(
//             icon: Icon(
//               Icons.chevron_right,
//               color: _currentPage < _totalPages - 1
//                   ? Theme.of(context).primaryColor
//                   : Colors.grey[400],
//               size: isSmallScreen ? 20 : 24,
//             ),
//             onPressed: _currentPage < _totalPages - 1
//                 ? () {
//               setState(() {
//                 _currentPage++;
//               });
//             }
//                 : null,
//             padding: isSmallScreen ? EdgeInsets.all(4) : EdgeInsets.all(8),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // Le reste du code reste identique
//   void _showAddImageModal() {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) =>
//           GalleryModal(
//             salonId: widget.salonDetails.idTblSalon,
//             currentImagesCount: _images.length,
//             onImagesAdded: (List<SalonImage> newImages) {
//               // Actualiser toute la galerie au lieu de simplement ajouter les nouvelles images
//               _refreshImages();
//
//               // Notifier le parent si nécessaire
//               if (widget.onImagesUpdated != null) {
//                 widget.onImagesUpdated!(newImages);
//               }
//             },
//           ),
//     );
//   }
//
//   Future<void> _refreshImages() async {
//     if (mounted) {
//       setState(() {
//         _isLoading = true;
//       });
//     }
//
//     try {
//       // Récupérer les images actualisées depuis l'API
//       final freshImages = await GalleryApi.getSalonImages(
//           widget.salonDetails.idTblSalon);
//
//       if (mounted) {
//         setState(() {
//           _images = freshImages;
//           _isLoading = false;
//
//           // Réinitialiser la page si nécessaire
//           if (_currentPage >= _totalPages && _currentPage > 0) {
//             _currentPage = _totalPages - 1;
//           }
//
//           // Fermer la vue agrandie si l'image actuelle n'existe plus
//           if (_enlargedImageIndex != null &&
//               _enlargedImageIndex! >= _images.length) {
//             _enlargedImageIndex = null;
//           }
//         });
//       }
//     } catch (e) {
//       print('Erreur lors du rafraîchissement des images: $e');
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Impossible de charger les images: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//
//     return;
//   }
//
//   void _confirmDeleteImage(int index) {
//     showDialog(
//       context: context,
//       builder: (context) =>
//           AlertDialog(
//             title: Text(
//               'Supprimer l\'image',
//               style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
//             ),
//             content: Text(
//               'Êtes-vous sûr de vouloir supprimer cette image ? Cette action est irréversible.',
//               style: GoogleFonts.poppins(),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: Text(
//                   'Annuler',
//                   style: GoogleFonts.poppins(),
//                 ),
//               ),
//               TextButton(
//                 onPressed: () {
//                   Navigator.pop(context);
//                   _deleteImage(index);
//                 },
//                 child: Text(
//                   'Supprimer',
//                   style: GoogleFonts.poppins(color: Colors.red),
//                 ),
//               ),
//             ],
//           ),
//     );
//   }
//
//   Future<void> _deleteImage(int index) async {
//     setState(() {
//       _isLoading = true;
//     });
//
//     try {
//       // Récupérer l'ID de l'image à supprimer
//       final imageId = _images[index].id;
//
//       // Appeler l'API pour supprimer l'image
//       final success = await GalleryApi.deleteImage(imageId);
//
//       if (success) {
//         setState(() {
//           // Fermer la vue agrandie si elle est ouverte
//           if (_enlargedImageIndex != null) {
//             _enlargedImageIndex = null;
//           }
//
//           // Supprimer l'image de la liste locale
//           _images.removeAt(index);
//
//           // Ajuster la page courante si nécessaire
//           if (_currentPage >= _totalPages && _currentPage > 0) {
//             _currentPage = _totalPages - 1;
//           }
//         });
//
//         // Notifier le parent si nécessaire
//         if (widget.onImagesUpdated != null) {
//           widget.onImagesUpdated!(_images);
//         }
//
//         // Afficher un message de succès
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Image supprimée avec succès'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       } else {
//         // Afficher un message d'erreur si la suppression a échoué
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Échec de la suppression de l\'image'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       // Gérer les erreurs
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Erreur lors de la suppression: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       // Désactiver l'indicateur de chargement
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
// }
//
//
//
//
//
//
// // // lib/public_salon_details/widgets/gallery_widget.dart
// //
// // import 'package:flutter/material.dart';
// // import 'package:google_fonts/google_fonts.dart';
// // import '../../../models/public_salon_details.dart';
// // import '../api/gallery_api.dart';
// // import '../modals/gallery_modal.dart';
// //
// // class GalleryWidget extends StatefulWidget {
// //   final PublicSalonDetails salonDetails;
// //   final int currentUserId;
// //   final Function(List<SalonImage>)? onImagesUpdated; // Callback optionnel pour notifier le parent
// //
// //   const GalleryWidget({
// //     super.key,
// //     required this.salonDetails,
// //     required this.currentUserId,
// //     this.onImagesUpdated,
// //   });
// //
// //   @override
// //   State<GalleryWidget> createState() => _GalleryWidgetState();
// // }
// //
// // class _GalleryWidgetState extends State<GalleryWidget> {
// //   int _currentPage = 0;
// //   int _imagesPerPage = 10;
// //   bool _isLoading = false;
// //   List<SalonImage> _images = [];
// //   int? _enlargedImageIndex;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _images = List.from(widget.salonDetails.images);
// //     // Charger les images depuis l'API pour s'assurer d'avoir les plus récentes
// //     _refreshImages();
// //   }
// //
// //   bool get _isOwner =>
// //       widget.currentUserId ==
// //           widget.salonDetails.coiffeuse.idTblUser.idTblUser;
// //
// //   List<SalonImage> get _currentPageImages {
// //     final startIndex = _currentPage * _imagesPerPage;
// //     final endIndex = startIndex + _imagesPerPage;
// //
// //     if (startIndex >= _images.length) {
// //       return [];
// //     }
// //
// //     return _images.sublist(
// //       startIndex,
// //       endIndex > _images.length ? _images.length : endIndex,
// //     );
// //   }
// //
// //   int get _totalPages => (_images.length / _imagesPerPage).ceil();
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Stack(
// //       children: [
// //         _enlargedImageIndex != null
// //             ? _buildEnlargedView()
// //             : _buildGalleryView(),
// //
// //         if (_isOwner && _enlargedImageIndex == null && _images.length < 25)
// //           Positioned(
// //             bottom: 16,
// //             right: 16,
// //             child: FloatingActionButton(
// //               onPressed: _showAddImageModal,
// //               backgroundColor: Theme.of(context).primaryColor,
// //               child: const Icon(
// //                   Icons.add_photo_alternate_outlined, color: Colors.white),
// //             ),
// //           ),
// //
// //         if (_isLoading)
// //           Container(
// //             color: Colors.black.withOpacity(0.5),
// //             child: const Center(
// //               child: CircularProgressIndicator(),
// //             ),
// //           ),
// //       ],
// //     );
// //   }
// //
// //   Widget _buildGalleryView() {
// //     return Column(
// //       children: [
// //         Expanded(
// //           child: RefreshIndicator(
// //             onRefresh: _refreshImages,
// //             child: _images.isEmpty
// //                 ? _buildEmptyStateWithRefresh()
// //                 : _buildImagesGrid(),
// //           ),
// //         ),
// //         if (_images.isNotEmpty)
// //           _buildPaginationControls(),
// //       ],
// //     );
// //   }
// //
// //   Widget _buildEmptyStateWithRefresh() {
// //     return ListView(
// //       physics: const AlwaysScrollableScrollPhysics(),
// //       children: [
// //         SizedBox(
// //           height: MediaQuery.of(context).size.height * 0.4,
// //           child: Center(
// //             child: Column(
// //               mainAxisAlignment: MainAxisAlignment.center,
// //               children: [
// //                 Icon(Icons.photo_library_outlined, size: 60,
// //                     color: Colors.grey[400]),
// //                 const SizedBox(height: 16),
// //                 Text(
// //                   'Aucune image disponible',
// //                   style: GoogleFonts.poppins(color: Colors.grey[600]),
// //                 ),
// //                 if (_isOwner) ...[
// //                   const SizedBox(height: 24),
// //                   ElevatedButton.icon(
// //                     onPressed: _showAddImageModal,
// //                     icon: const Icon(Icons.add_photo_alternate_outlined),
// //                     label: Text(
// //                       'Ajouter des images',
// //                       style: GoogleFonts.poppins(),
// //                     ),
// //                     style: ElevatedButton.styleFrom(
// //                       backgroundColor: Theme.of(context).primaryColor,
// //                       foregroundColor: Colors.white,
// //                     ),
// //                   ),
// //                 ],
// //               ],
// //             ),
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// //
// //   Widget _buildImagesGrid() {
// //     // Adapter le nombre de colonnes en fonction de la taille de l'écran
// //     final screenWidth = MediaQuery.of(context).size.width;
// //     int crossAxisCount = 2; // Par défaut 2 colonnes pour les petits écrans
// //
// //     if (screenWidth > 600) crossAxisCount = 3;
// //     if (screenWidth > 900) crossAxisCount = 4;
// //
// //     // Ajuster le aspect ratio pour éviter les images trop grandes
// //     double aspectRatio = 1.0;
// //
// //     // Calculer la taille de chaque cellule en tenant compte des espacements
// //     final spacing = 12.0;
// //     final availableWidth = screenWidth - (spacing * (crossAxisCount + 1));
// //     final cellWidth = availableWidth / crossAxisCount;
// //
// //     // Limiter la hauteur maximale des cellules si nécessaire
// //     final maxCellHeight = cellWidth * 1.2; // Limite la hauteur à 120% de la largeur
// //
// //     // Ajuster le aspectRatio en conséquence
// //     aspectRatio = cellWidth / maxCellHeight;
// //
// //     return GridView.builder(
// //       padding: const EdgeInsets.all(12),
// //       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
// //         crossAxisCount: crossAxisCount,
// //         childAspectRatio: aspectRatio,
// //         crossAxisSpacing: spacing,
// //         mainAxisSpacing: spacing,
// //       ),
// //       itemCount: _currentPageImages.length,
// //       itemBuilder: (context, index) {
// //         final actualIndex = _currentPage * _imagesPerPage + index;
// //         final imageUrl = _currentPageImages[index].image;
// //
// //         return GestureDetector(
// //           onTap: () {
// //             setState(() {
// //               _enlargedImageIndex = actualIndex;
// //             });
// //           },
// //           child: Stack(
// //             fit: StackFit.expand,
// //             children: [
// //               ClipRRect(
// //                 borderRadius: BorderRadius.circular(8),
// //                 child: Image.network(
// //                   imageUrl,
// //                   fit: BoxFit.cover,
// //                   loadingBuilder: (context, child, loadingProgress) {
// //                     if (loadingProgress == null) return child;
// //                     return Center(
// //                       child: CircularProgressIndicator(
// //                         value: loadingProgress.expectedTotalBytes != null
// //                             ? loadingProgress.cumulativeBytesLoaded /
// //                             (loadingProgress.expectedTotalBytes ?? 1)
// //                             : null,
// //                       ),
// //                     );
// //                   },
// //                   errorBuilder: (context, error, stackTrace) {
// //                     return Container(
// //                       color: Colors.grey[200],
// //                       child: Center(
// //                         child: Icon(Icons.broken_image,
// //                             color: Colors.grey[400]),
// //                       ),
// //                     );
// //                   },
// //                 ),
// //               ),
// //               if (_isOwner)
// //                 Positioned(
// //                   top: 4,
// //                   right: 4,
// //                   child: GestureDetector(
// //                     onTap: () => _confirmDeleteImage(actualIndex),
// //                     child: Container(
// //                       padding: const EdgeInsets.all(4),
// //                       decoration: BoxDecoration(
// //                         color: Colors.red.withOpacity(0.7),
// //                         shape: BoxShape.circle,
// //                       ),
// //                       child: const Icon(
// //                         Icons.delete_outline,
// //                         color: Colors.white,
// //                         size: 16,
// //                       ),
// //                     ),
// //                   ),
// //                 ),
// //             ],
// //           ),
// //         );
// //       },
// //     );
// //   }
// //
// //   Widget _buildEnlargedView() {
// //     if (_enlargedImageIndex == null || _enlargedImageIndex! >= _images.length) {
// //       return const SizedBox.shrink();
// //     }
// //
// //     // Assurer que l'URL est complète
// //     final imageUrl = _images[_enlargedImageIndex!].image;
// //     final fullImageUrl = imageUrl.startsWith('http')
// //         ? imageUrl
// //         : 'https://hairbnb.site/$imageUrl';
// //
// //     // Détecter la taille de l'écran
// //     final screenSize = MediaQuery.of(context).size;
// //     final isSmallScreen = screenSize.width < 600;
// //
// //     return Stack(
// //       fit: StackFit.expand,
// //       children: [
// //         GestureDetector(
// //           onTap: () {
// //             // Fermer l'image agrandie en cas de tap sur le fond
// //             setState(() {
// //               _enlargedImageIndex = null;
// //             });
// //           },
// //           child: Container(color: Colors.black),
// //         ),
// //         InteractiveViewer(
// //           minScale: 0.5,
// //           maxScale: 3.0,
// //           child: Center(
// //             child: Container(
// //               constraints: BoxConstraints(
// //                 // Limiter la taille maximale de l'image en mode agrandi
// //                 maxWidth: isSmallScreen ? screenSize.width * 0.95 : screenSize.width * 0.8,
// //                 maxHeight: isSmallScreen ? screenSize.height * 0.7 : screenSize.height * 0.8,
// //               ),
// //               child: Image.network(
// //                 fullImageUrl,
// //                 fit: BoxFit.contain,
// //                 loadingBuilder: (context, child, loadingProgress) {
// //                   if (loadingProgress == null) return child;
// //                   return Center(
// //                     child: CircularProgressIndicator(
// //                       value: loadingProgress.expectedTotalBytes != null
// //                           ? loadingProgress.cumulativeBytesLoaded /
// //                           (loadingProgress.expectedTotalBytes ?? 1)
// //                           : null,
// //                       color: Colors.white,
// //                     ),
// //                   );
// //                 },
// //                 errorBuilder: (context, error, stackTrace) {
// //                   print(
// //                       "Erreur de chargement d'image: $error pour $fullImageUrl");
// //                   return Center(
// //                     child: Column(
// //                       mainAxisSize: MainAxisSize.min,
// //                       children: [
// //                         const Icon(
// //                             Icons.broken_image, color: Colors.white, size: 48),
// //                         const SizedBox(height: 16),
// //                         Text(
// //                           'Impossible de charger l\'image',
// //                           style: GoogleFonts.poppins(color: Colors.white),
// //                         ),
// //                       ],
// //                     ),
// //                   );
// //                 },
// //               ),
// //             ),
// //           ),
// //         ),
// //         // Controls overlay - adapté pour les petits écrans
// //         Positioned(
// //           top: 0,
// //           left: 0,
// //           right: 0,
// //           child: Container(
// //             color: Colors.black.withOpacity(0.5),
// //             padding: EdgeInsets.symmetric(
// //                 horizontal: isSmallScreen ? 4 : 8,
// //                 vertical: isSmallScreen ? 8 : 16
// //             ),
// //             child: Row(
// //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //               children: [
// //                 IconButton(
// //                   icon: const Icon(Icons.close, color: Colors.white),
// //                   onPressed: () {
// //                     setState(() {
// //                       _enlargedImageIndex = null;
// //                     });
// //                   },
// //                   iconSize: isSmallScreen ? 20 : 24,
// //                   padding: isSmallScreen ? EdgeInsets.all(4) : EdgeInsets.all(8),
// //                 ),
// //                 Text(
// //                   'Image ${_enlargedImageIndex! + 1}/${_images.length}',
// //                   style: GoogleFonts.poppins(
// //                     color: Colors.white,
// //                     fontWeight: FontWeight.bold,
// //                     fontSize: isSmallScreen ? 12 : 14,
// //                   ),
// //                 ),
// //                 if (_isOwner)
// //                   IconButton(
// //                     icon: const Icon(Icons.delete_outline, color: Colors.white),
// //                     onPressed: () => _confirmDeleteImage(_enlargedImageIndex!),
// //                     iconSize: isSmallScreen ? 20 : 24,
// //                     padding: isSmallScreen ? EdgeInsets.all(4) : EdgeInsets.all(8),
// //                   ),
// //               ],
// //             ),
// //           ),
// //         ),
// //         // Navigation arrows adaptés aux petits écrans
// //         if (_images.length > 1) ...[
// //           // Previous button
// //           if (_enlargedImageIndex! > 0)
// //             Positioned(
// //               left: isSmallScreen ? 2 : 8,
// //               bottom: 0,
// //               top: 0,
// //               child: Center(
// //                 child: IconButton(
// //                   icon: Container(
// //                     padding: EdgeInsets.all(isSmallScreen ? 4 : 8),
// //                     decoration: BoxDecoration(
// //                       color: Colors.black.withOpacity(0.5),
// //                       shape: BoxShape.circle,
// //                     ),
// //                     child: Icon(
// //                       Icons.chevron_left,
// //                       color: Colors.white,
// //                       size: isSmallScreen ? 20 : 24,
// //                     ),
// //                   ),
// //                   onPressed: () {
// //                     setState(() {
// //                       _enlargedImageIndex = _enlargedImageIndex! - 1;
// //                     });
// //                   },
// //                 ),
// //               ),
// //             ),
// //           // Next button
// //           if (_enlargedImageIndex! < _images.length - 1)
// //             Positioned(
// //               right: isSmallScreen ? 2 : 8,
// //               bottom: 0,
// //               top: 0,
// //               child: Center(
// //                 child: IconButton(
// //                   icon: Container(
// //                     padding: EdgeInsets.all(isSmallScreen ? 4 : 8),
// //                     decoration: BoxDecoration(
// //                       color: Colors.black.withOpacity(0.5),
// //                       shape: BoxShape.circle,
// //                     ),
// //                     child: Icon(
// //                       Icons.chevron_right,
// //                       color: Colors.white,
// //                       size: isSmallScreen ? 20 : 24,
// //                     ),
// //                   ),
// //                   onPressed: () {
// //                     setState(() {
// //                       _enlargedImageIndex = _enlargedImageIndex! + 1;
// //                     });
// //                   },
// //                 ),
// //               ),
// //             ),
// //         ],
// //       ],
// //     );
// //   }
// //
// //   Widget _buildPaginationControls() {
// //     if (_totalPages <= 1) {
// //       return const SizedBox.shrink();
// //     }
// //
// //     // Adapter la taille des contrôles de pagination pour les petits écrans
// //     final isSmallScreen = MediaQuery.of(context).size.width < 600;
// //
// //     return Container(
// //       padding: EdgeInsets.symmetric(
// //           vertical: isSmallScreen ? 8 : 12
// //       ),
// //       child: Row(
// //         mainAxisAlignment: MainAxisAlignment.center,
// //         children: [
// //           IconButton(
// //             icon: Icon(
// //               Icons.chevron_left,
// //               color: _currentPage > 0
// //                   ? Theme.of(context).primaryColor
// //                   : Colors.grey[400],
// //               size: isSmallScreen ? 20 : 24,
// //             ),
// //             onPressed: _currentPage > 0
// //                 ? () {
// //               setState(() {
// //                 _currentPage--;
// //               });
// //             }
// //                 : null,
// //             padding: isSmallScreen ? EdgeInsets.all(4) : EdgeInsets.all(8),
// //           ),
// //           Text(
// //             '${_currentPage + 1} / $_totalPages',
// //             style: GoogleFonts.poppins(
// //               fontWeight: FontWeight.w500,
// //               fontSize: isSmallScreen ? 12 : 14,
// //             ),
// //           ),
// //           IconButton(
// //             icon: Icon(
// //               Icons.chevron_right,
// //               color: _currentPage < _totalPages - 1
// //                   ? Theme.of(context).primaryColor
// //                   : Colors.grey[400],
// //               size: isSmallScreen ? 20 : 24,
// //             ),
// //             onPressed: _currentPage < _totalPages - 1
// //                 ? () {
// //               setState(() {
// //                 _currentPage++;
// //               });
// //             }
// //                 : null,
// //             padding: isSmallScreen ? EdgeInsets.all(4) : EdgeInsets.all(8),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   // Le reste du code reste identique
// //   void _showAddImageModal() {
// //     showModalBottomSheet(
// //       context: context,
// //       isScrollControlled: true,
// //       backgroundColor: Colors.transparent,
// //       builder: (context) =>
// //           GalleryModal(
// //             salonId: widget.salonDetails.idTblSalon,
// //             currentImagesCount: _images.length,
// //             onImagesAdded: (List<SalonImage> newImages) {
// //               // Actualiser toute la galerie au lieu de simplement ajouter les nouvelles images
// //               _refreshImages();
// //
// //               // Notifier le parent si nécessaire
// //               if (widget.onImagesUpdated != null) {
// //                 widget.onImagesUpdated!(newImages);
// //               }
// //             },
// //           ),
// //     );
// //   }
// //
// //   Future<void> _refreshImages() async {
// //     if (mounted) {
// //       setState(() {
// //         _isLoading = true;
// //       });
// //     }
// //
// //     try {
// //       // Récupérer les images actualisées depuis l'API
// //       final freshImages = await GalleryApi.getSalonImages(
// //           widget.salonDetails.idTblSalon);
// //
// //       if (mounted) {
// //         setState(() {
// //           _images = freshImages;
// //           _isLoading = false;
// //
// //           // Réinitialiser la page si nécessaire
// //           if (_currentPage >= _totalPages && _currentPage > 0) {
// //             _currentPage = _totalPages - 1;
// //           }
// //
// //           // Fermer la vue agrandie si l'image actuelle n'existe plus
// //           if (_enlargedImageIndex != null &&
// //               _enlargedImageIndex! >= _images.length) {
// //             _enlargedImageIndex = null;
// //           }
// //         });
// //       }
// //     } catch (e) {
// //       print('Erreur lors du rafraîchissement des images: $e');
// //       if (mounted) {
// //         setState(() {
// //           _isLoading = false;
// //         });
// //
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text('Impossible de charger les images: $e'),
// //             backgroundColor: Colors.red,
// //           ),
// //         );
// //       }
// //     }
// //
// //     return;
// //   }
// //
// //   void _confirmDeleteImage(int index) {
// //     showDialog(
// //       context: context,
// //       builder: (context) =>
// //           AlertDialog(
// //             title: Text(
// //               'Supprimer l\'image',
// //               style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
// //             ),
// //             content: Text(
// //               'Êtes-vous sûr de vouloir supprimer cette image ? Cette action est irréversible.',
// //               style: GoogleFonts.poppins(),
// //             ),
// //             actions: [
// //               TextButton(
// //                 onPressed: () => Navigator.pop(context),
// //                 child: Text(
// //                   'Annuler',
// //                   style: GoogleFonts.poppins(),
// //                 ),
// //               ),
// //               TextButton(
// //                 onPressed: () {
// //                   Navigator.pop(context);
// //                   _deleteImage(index);
// //                 },
// //                 child: Text(
// //                   'Supprimer',
// //                   style: GoogleFonts.poppins(color: Colors.red),
// //                 ),
// //               ),
// //             ],
// //           ),
// //     );
// //   }
// //
// //   Future<void> _deleteImage(int index) async {
// //     setState(() {
// //       _isLoading = true;
// //     });
// //
// //     try {
// //       // Récupérer l'ID de l'image à supprimer
// //       final imageId = _images[index].id;
// //
// //       // Appeler l'API pour supprimer l'image
// //       final success = await GalleryApi.deleteImage(imageId);
// //
// //       if (success) {
// //         setState(() {
// //           // Fermer la vue agrandie si elle est ouverte
// //           if (_enlargedImageIndex != null) {
// //             _enlargedImageIndex = null;
// //           }
// //
// //           // Supprimer l'image de la liste locale
// //           _images.removeAt(index);
// //
// //           // Ajuster la page courante si nécessaire
// //           if (_currentPage >= _totalPages && _currentPage > 0) {
// //             _currentPage = _totalPages - 1;
// //           }
// //         });
// //
// //         // Notifier le parent si nécessaire
// //         if (widget.onImagesUpdated != null) {
// //           widget.onImagesUpdated!(_images);
// //         }
// //
// //         // Afficher un message de succès
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text('Image supprimée avec succès'),
// //             backgroundColor: Colors.green,
// //           ),
// //         );
// //       } else {
// //         // Afficher un message d'erreur si la suppression a échoué
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text('Échec de la suppression de l\'image'),
// //             backgroundColor: Colors.red,
// //           ),
// //         );
// //       }
// //     } catch (e) {
// //       // Gérer les erreurs
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //           content: Text('Erreur lors de la suppression: $e'),
// //           backgroundColor: Colors.red,
// //         ),
// //       );
// //     } finally {
// //       // Désactiver l'indicateur de chargement
// //       setState(() {
// //         _isLoading = false;
// //       });
// //     }
// //   }
// // }
//
//
//
//
//
// // // lib/public_salon_details/widgets/gallery_widget.dart
// //
// // import 'package:flutter/material.dart';
// // import 'package:google_fonts/google_fonts.dart';
// // import '../../../models/public_salon_details.dart';
// // import '../api/gallery_api.dart';
// // import '../modals/gallery_modal.dart';
// //
// // class GalleryWidget extends StatefulWidget {
// //   final PublicSalonDetails salonDetails;
// //   final int currentUserId;
// //   final Function(List<SalonImage>)? onImagesUpdated; // Callback optionnel pour notifier le parent
// //
// //   const GalleryWidget({
// //     super.key,
// //     required this.salonDetails,
// //     required this.currentUserId,
// //     this.onImagesUpdated,
// //   });
// //
// //   @override
// //   State<GalleryWidget> createState() => _GalleryWidgetState();
// // }
// //
// // class _GalleryWidgetState extends State<GalleryWidget> {
// //   int _currentPage = 0;
// //   int _imagesPerPage = 10;
// //   bool _isLoading = false;
// //   List<SalonImage> _images = [];
// //   int? _enlargedImageIndex;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _images = List.from(widget.salonDetails.images);
// //     // Charger les images depuis l'API pour s'assurer d'avoir les plus récentes
// //     _refreshImages();
// //   }
// //
// //   bool get _isOwner =>
// //       widget.currentUserId ==
// //           widget.salonDetails.coiffeuse.idTblUser.idTblUser;
// //
// //   List<SalonImage> get _currentPageImages {
// //     final startIndex = _currentPage * _imagesPerPage;
// //     final endIndex = startIndex + _imagesPerPage;
// //
// //     if (startIndex >= _images.length) {
// //       return [];
// //     }
// //
// //     return _images.sublist(
// //       startIndex,
// //       endIndex > _images.length ? _images.length : endIndex,
// //     );
// //   }
// //
// //   int get _totalPages => (_images.length / _imagesPerPage).ceil();
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Stack(
// //       children: [
// //         _enlargedImageIndex != null
// //             ? _buildEnlargedView()
// //             : _buildGalleryView(),
// //
// //         if (_isOwner && _enlargedImageIndex == null && _images.length < 25)
// //           Positioned(
// //             bottom: 16,
// //             right: 16,
// //             child: FloatingActionButton(
// //               onPressed: _showAddImageModal,
// //               backgroundColor: Theme
// //                   .of(context)
// //                   .primaryColor,
// //               child: const Icon(
// //                   Icons.add_photo_alternate_outlined, color: Colors.white),
// //             ),
// //           ),
// //
// //         if (_isLoading)
// //           Container(
// //             color: Colors.black.withOpacity(0.5),
// //             child: const Center(
// //               child: CircularProgressIndicator(),
// //             ),
// //           ),
// //       ],
// //     );
// //   }
// //
// //   Widget _buildGalleryView() {
// //     return Column(
// //       children: [
// //         Expanded(
// //           child: RefreshIndicator(
// //             onRefresh: _refreshImages,
// //             child: _images.isEmpty
// //                 ? _buildEmptyStateWithRefresh()
// //                 : _buildImagesGrid(),
// //           ),
// //         ),
// //         if (_images.isNotEmpty)
// //           _buildPaginationControls(),
// //       ],
// //     );
// //   }
// //
// //   Widget _buildEmptyStateWithRefresh() {
// //     return ListView(
// //       physics: const AlwaysScrollableScrollPhysics(),
// //       children: [
// //         SizedBox(
// //           height: MediaQuery
// //               .of(context)
// //               .size
// //               .height * 0.4,
// //           child: Center(
// //             child: Column(
// //               mainAxisAlignment: MainAxisAlignment.center,
// //               children: [
// //                 Icon(Icons.photo_library_outlined, size: 60,
// //                     color: Colors.grey[400]),
// //                 const SizedBox(height: 16),
// //                 Text(
// //                   'Aucune image disponible',
// //                   style: GoogleFonts.poppins(color: Colors.grey[600]),
// //                 ),
// //                 if (_isOwner) ...[
// //                   const SizedBox(height: 24),
// //                   ElevatedButton.icon(
// //                     onPressed: _showAddImageModal,
// //                     icon: const Icon(Icons.add_photo_alternate_outlined),
// //                     label: Text(
// //                       'Ajouter des images',
// //                       style: GoogleFonts.poppins(),
// //                     ),
// //                     style: ElevatedButton.styleFrom(
// //                       backgroundColor: Theme
// //                           .of(context)
// //                           .primaryColor,
// //                       foregroundColor: Colors.white,
// //                     ),
// //                   ),
// //                 ],
// //               ],
// //             ),
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// //
// //   Widget _buildImagesGrid() {
// //     return GridView.builder(
// //       padding: const EdgeInsets.all(12),
// //       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
// //         crossAxisCount: MediaQuery
// //             .of(context)
// //             .size
// //             .width > 600 ? 3 : 2,
// //         childAspectRatio: 1,
// //         crossAxisSpacing: 12,
// //         mainAxisSpacing: 12,
// //       ),
// //       itemCount: _currentPageImages.length,
// //       itemBuilder: (context, index) {
// //         final actualIndex = _currentPage * _imagesPerPage + index;
// //         final imageUrl = _currentPageImages[index].image;
// //
// //         return GestureDetector(
// //           onTap: () {
// //             setState(() {
// //               _enlargedImageIndex = actualIndex;
// //             });
// //           },
// //           child: Stack(
// //             fit: StackFit.expand,
// //             children: [
// //               ClipRRect(
// //                 borderRadius: BorderRadius.circular(12),
// //                 child: Image.network(
// //                   imageUrl,
// //                   fit: BoxFit.cover,
// //                   loadingBuilder: (context, child, loadingProgress) {
// //                     if (loadingProgress == null) return child;
// //                     return Center(
// //                       child: CircularProgressIndicator(
// //                         value: loadingProgress.expectedTotalBytes != null
// //                             ? loadingProgress.cumulativeBytesLoaded /
// //                             (loadingProgress.expectedTotalBytes ?? 1)
// //                             : null,
// //                       ),
// //                     );
// //                   },
// //                   errorBuilder: (context, error, stackTrace) {
// //                     return Container(
// //                       color: Colors.grey[200],
// //                       child: Center(
// //                         child: Icon(Icons.broken_image,
// //                             color: Colors.grey[400]),
// //                       ),
// //                     );
// //                   },
// //                 ),
// //               ),
// //               if (_isOwner)
// //                 Positioned(
// //                   top: 8,
// //                   right: 8,
// //                   child: GestureDetector(
// //                     onTap: () => _confirmDeleteImage(actualIndex),
// //                     child: Container(
// //                       padding: const EdgeInsets.all(6),
// //                       decoration: BoxDecoration(
// //                         color: Colors.red.withOpacity(0.7),
// //                         shape: BoxShape.circle,
// //                       ),
// //                       child: const Icon(
// //                         Icons.delete_outline,
// //                         color: Colors.white,
// //                         size: 20,
// //                       ),
// //                     ),
// //                   ),
// //                 ),
// //             ],
// //           ),
// //         );
// //       },
// //     );
// //   }
// //
// //   Widget _buildEnlargedView() {
// //     if (_enlargedImageIndex == null || _enlargedImageIndex! >= _images.length) {
// //       return const SizedBox.shrink();
// //     }
// //
// //     // Assurer que l'URL est complète
// //     final imageUrl = _images[_enlargedImageIndex!].image;
// //     final fullImageUrl = imageUrl.startsWith('http')
// //         ? imageUrl
// //         : 'https://hairbnb.site/$imageUrl';
// //
// //     return Stack(
// //       fit: StackFit.expand,
// //       children: [
// //         InteractiveViewer(
// //           minScale: 0.5,
// //           maxScale: 3.0,
// //           child: Container(
// //             color: Colors.black,
// //             child: Center(
// //               child: Image.network(
// //                 fullImageUrl,
// //                 fit: BoxFit.contain,
// //                 loadingBuilder: (context, child, loadingProgress) {
// //                   if (loadingProgress == null) return child;
// //                   return Center(
// //                     child: CircularProgressIndicator(
// //                       value: loadingProgress.expectedTotalBytes != null
// //                           ? loadingProgress.cumulativeBytesLoaded /
// //                           (loadingProgress.expectedTotalBytes ?? 1)
// //                           : null,
// //                       color: Colors.white,
// //                     ),
// //                   );
// //                 },
// //                 errorBuilder: (context, error, stackTrace) {
// //                   print(
// //                       "Erreur de chargement d'image: $error pour $fullImageUrl");
// //                   return Center(
// //                     child: Column(
// //                       mainAxisSize: MainAxisSize.min,
// //                       children: [
// //                         const Icon(
// //                             Icons.broken_image, color: Colors.white, size: 48),
// //                         const SizedBox(height: 16),
// //                         Text(
// //                           'Impossible de charger l\'image',
// //                           style: GoogleFonts.poppins(color: Colors.white),
// //                         ),
// //                       ],
// //                     ),
// //                   );
// //                 },
// //               ),
// //             ),
// //           ),
// //         ),
// //         // Controls overlay
// //         Positioned(
// //           top: 0,
// //           left: 0,
// //           right: 0,
// //           child: Container(
// //             color: Colors.black.withOpacity(0.5),
// //             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
// //             child: Row(
// //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //               children: [
// //                 IconButton(
// //                   icon: const Icon(Icons.close, color: Colors.white),
// //                   onPressed: () {
// //                     setState(() {
// //                       _enlargedImageIndex = null;
// //                     });
// //                   },
// //                 ),
// //                 Text(
// //                   'Image ${_enlargedImageIndex! + 1}/${_images.length}',
// //                   style: GoogleFonts.poppins(
// //                     color: Colors.white,
// //                     fontWeight: FontWeight.bold,
// //                   ),
// //                 ),
// //                 if (_isOwner)
// //                   IconButton(
// //                     icon: const Icon(Icons.delete_outline, color: Colors.white),
// //                     onPressed: () => _confirmDeleteImage(_enlargedImageIndex!),
// //                   ),
// //               ],
// //             ),
// //           ),
// //         ),
// //         // Navigation arrows
// //         if (_images.length > 1) ...[
// //           // Previous button
// //           if (_enlargedImageIndex! > 0)
// //             Positioned(
// //               left: 8,
// //               bottom: 0,
// //               top: 0,
// //               child: Center(
// //                 child: IconButton(
// //                   icon: Container(
// //                     padding: const EdgeInsets.all(8),
// //                     decoration: BoxDecoration(
// //                       color: Colors.black.withOpacity(0.5),
// //                       shape: BoxShape.circle,
// //                     ),
// //                     child: const Icon(Icons.chevron_left, color: Colors.white),
// //                   ),
// //                   onPressed: () {
// //                     setState(() {
// //                       _enlargedImageIndex = _enlargedImageIndex! - 1;
// //                     });
// //                   },
// //                 ),
// //               ),
// //             ),
// //           // Next button
// //           if (_enlargedImageIndex! < _images.length - 1)
// //             Positioned(
// //               right: 8,
// //               bottom: 0,
// //               top: 0,
// //               child: Center(
// //                 child: IconButton(
// //                   icon: Container(
// //                     padding: const EdgeInsets.all(8),
// //                     decoration: BoxDecoration(
// //                       color: Colors.black.withOpacity(0.5),
// //                       shape: BoxShape.circle,
// //                     ),
// //                     child: const Icon(Icons.chevron_right, color: Colors.white),
// //                   ),
// //                   onPressed: () {
// //                     setState(() {
// //                       _enlargedImageIndex = _enlargedImageIndex! + 1;
// //                     });
// //                   },
// //                 ),
// //               ),
// //             ),
// //         ],
// //       ],
// //     );
// //   }
// //
// //   Widget _buildPaginationControls() {
// //     if (_totalPages <= 1) {
// //       return const SizedBox.shrink();
// //     }
// //
// //     return Container(
// //       padding: const EdgeInsets.symmetric(vertical: 12),
// //       child: Row(
// //         mainAxisAlignment: MainAxisAlignment.center,
// //         children: [
// //           IconButton(
// //             icon: Icon(
// //               Icons.chevron_left,
// //               color: _currentPage > 0
// //                   ? Theme
// //                   .of(context)
// //                   .primaryColor
// //                   : Colors.grey[400],
// //             ),
// //             onPressed: _currentPage > 0
// //                 ? () {
// //               setState(() {
// //                 _currentPage--;
// //               });
// //             }
// //                 : null,
// //           ),
// //           Text(
// //             '${_currentPage + 1} / $_totalPages',
// //             style: GoogleFonts.poppins(
// //               fontWeight: FontWeight.w500,
// //             ),
// //           ),
// //           IconButton(
// //             icon: Icon(
// //               Icons.chevron_right,
// //               color: _currentPage < _totalPages - 1
// //                   ? Theme
// //                   .of(context)
// //                   .primaryColor
// //                   : Colors.grey[400],
// //             ),
// //             onPressed: _currentPage < _totalPages - 1
// //                 ? () {
// //               setState(() {
// //                 _currentPage++;
// //               });
// //             }
// //                 : null,
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   void _showAddImageModal() {
// //     showModalBottomSheet(
// //       context: context,
// //       isScrollControlled: true,
// //       backgroundColor: Colors.transparent,
// //       builder: (context) =>
// //           GalleryModal(
// //             salonId: widget.salonDetails.idTblSalon,
// //             currentImagesCount: _images.length,
// //             onImagesAdded: (List<SalonImage> newImages) {
// //               // Actualiser toute la galerie au lieu de simplement ajouter les nouvelles images
// //               _refreshImages();
// //
// //               // Notifier le parent si nécessaire
// //               if (widget.onImagesUpdated != null) {
// //                 widget.onImagesUpdated!(newImages);
// //               }
// //             },
// //           ),
// //     );
// //   }
// //
// //   Future<void> _refreshImages() async {
// //     if (mounted) {
// //       setState(() {
// //         _isLoading = true;
// //       });
// //     }
// //
// //     try {
// //       // Récupérer les images actualisées depuis l'API
// //       final freshImages = await GalleryApi.getSalonImages(
// //           widget.salonDetails.idTblSalon);
// //
// //       if (mounted) {
// //         setState(() {
// //           _images = freshImages;
// //           _isLoading = false;
// //
// //           // Réinitialiser la page si nécessaire
// //           if (_currentPage >= _totalPages && _currentPage > 0) {
// //             _currentPage = _totalPages - 1;
// //           }
// //
// //           // Fermer la vue agrandie si l'image actuelle n'existe plus
// //           if (_enlargedImageIndex != null &&
// //               _enlargedImageIndex! >= _images.length) {
// //             _enlargedImageIndex = null;
// //           }
// //         });
// //       }
// //     } catch (e) {
// //       print('Erreur lors du rafraîchissement des images: $e');
// //       if (mounted) {
// //         setState(() {
// //           _isLoading = false;
// //         });
// //
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text('Impossible de charger les images: $e'),
// //             backgroundColor: Colors.red,
// //           ),
// //         );
// //       }
// //     }
// //
// //     return;
// //   }
// //
// //   void _confirmDeleteImage(int index) {
// //     showDialog(
// //       context: context,
// //       builder: (context) =>
// //           AlertDialog(
// //             title: Text(
// //               'Supprimer l\'image',
// //               style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
// //             ),
// //             content: Text(
// //               'Êtes-vous sûr de vouloir supprimer cette image ? Cette action est irréversible.',
// //               style: GoogleFonts.poppins(),
// //             ),
// //             actions: [
// //               TextButton(
// //                 onPressed: () => Navigator.pop(context),
// //                 child: Text(
// //                   'Annuler',
// //                   style: GoogleFonts.poppins(),
// //                 ),
// //               ),
// //               TextButton(
// //                 onPressed: () {
// //                   Navigator.pop(context);
// //                   _deleteImage(index);
// //                 },
// //                 child: Text(
// //                   'Supprimer',
// //                   style: GoogleFonts.poppins(color: Colors.red),
// //                 ),
// //               ),
// //             ],
// //           ),
// //     );
// //   }
// //
// //   Future<void> _deleteImage(int index) async {
// //     setState(() {
// //       _isLoading = true;
// //     });
// //
// //     try {
// //       // Récupérer l'ID de l'image à supprimer
// //       final imageId = _images[index].id;
// //
// //       // Appeler l'API pour supprimer l'image
// //       final success = await GalleryApi.deleteImage(imageId);
// //
// //       if (success) {
// //         setState(() {
// //           // Fermer la vue agrandie si elle est ouverte
// //           if (_enlargedImageIndex != null) {
// //             _enlargedImageIndex = null;
// //           }
// //
// //           // Supprimer l'image de la liste locale
// //           _images.removeAt(index);
// //
// //           // Ajuster la page courante si nécessaire
// //           if (_currentPage >= _totalPages && _currentPage > 0) {
// //             _currentPage = _totalPages - 1;
// //           }
// //         });
// //
// //         // Notifier le parent si nécessaire
// //         if (widget.onImagesUpdated != null) {
// //           widget.onImagesUpdated!(_images);
// //         }
// //
// //         // Afficher un message de succès
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text('Image supprimée avec succès'),
// //             backgroundColor: Colors.green,
// //           ),
// //         );
// //       } else {
// //         // Afficher un message d'erreur si la suppression a échoué
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text('Échec de la suppression de l\'image'),
// //             backgroundColor: Colors.red,
// //           ),
// //         );
// //       }
// //     } catch (e) {
// //       // Gérer les erreurs
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //           content: Text('Erreur lors de la suppression: $e'),
// //           backgroundColor: Colors.red,
// //         ),
// //       );
// //     } finally {
// //       // Désactiver l'indicateur de chargement
// //       setState(() {
// //         _isLoading = false;
// //       });
// //     }
// //   }
// // }
//
// //   Future<void> _deleteImage(int index) async {
// //     setState(() {
// //       _isLoading = true;
// //     });
// //
// //     try {
// //       // Récupérer l'ID de l'image à supprimer
// //       // Dans un cas réel, vous devriez implémenter cela
// //       // final imageId = _images[index].id;
// //       // await GalleryApi.deleteImage(imageId);
// //
// //       // Pour l'instant, on simule la suppression
// //       await Future.delayed(const Duration(milliseconds: 500));
// //
// //       setState(() {
// //         if (_enlargedImageIndex != null) {
// //           _enlargedImageIndex = null;
// //         }
// //
// //         _images.removeAt(index);
// //
// //         // Ajuster la page courante si nécessaire
// //         if (_currentPage >= _totalPages && _currentPage > 0) {
// //           _currentPage = _totalPages - 1;
// //         }
// //       });
// //
// //       // Notifier le parent si nécessaire
// //       if (widget.onImagesUpdated != null) {
// //         widget.onImagesUpdated!(_images);
// //       }
// //
// //     } catch (e) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //           content: Text('Erreur lors de la suppression: $e'),
// //           backgroundColor: Colors.red,
// //         ),
// //       );
// //     } finally {
// //       setState(() {
// //         _isLoading = false;
// //       });
// //     }
// //   }
// // }
//
//
//
// // // lib/public_salon_details/widgets/gallery_widget.dart
// //
// // import 'package:flutter/material.dart';
// // import 'package:google_fonts/google_fonts.dart';
// // import '../../../models/public_salon_details.dart';
// // import '../modals/gallery_modal.dart';
// // class GalleryWidget extends StatefulWidget {
// //   final PublicSalonDetails salonDetails;
// //   final int currentUserId;
// //
// //   const GalleryWidget({
// //     super.key,
// //     required this.salonDetails,
// //     required this.currentUserId,
// //   });
// //
// //   @override
// //   State<GalleryWidget> createState() => _GalleryWidgetState();
// // }
// //
// // class _GalleryWidgetState extends State<GalleryWidget> {
// //   int _currentPage = 0;
// //   int _imagesPerPage = 10;
// //   bool _isLoading = false;
// //   List<SalonImage> _images = [];
// //   int? _enlargedImageIndex;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _images = List.from(widget.salonDetails.images);
// //   }
// //
// //   bool get _isOwner => widget.currentUserId ==
// //       widget.salonDetails.coiffeuse.idTblUser.idTblUser;
// //
// //   List<SalonImage> get _currentPageImages {
// //     final startIndex = _currentPage * _imagesPerPage;
// //     final endIndex = startIndex + _imagesPerPage;
// //
// //     if (startIndex >= _images.length) {
// //       return [];
// //     }
// //
// //     return _images.sublist(
// //       startIndex,
// //       endIndex > _images.length ? _images.length : endIndex,
// //     );
// //   }
// //
// //   int get _totalPages => (_images.length / _imagesPerPage).ceil();
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Stack(
// //       children: [
// //         _enlargedImageIndex != null
// //             ? _buildEnlargedView()
// //             : _buildGalleryView(),
// //
// //         if (_isOwner && _enlargedImageIndex == null && _images.length < 25)
// //           Positioned(
// //             bottom: 16,
// //             right: 16,
// //             child: FloatingActionButton(
// //               onPressed: _showAddImageModal,
// //               backgroundColor: Theme.of(context).primaryColor,
// //               child: const Icon(Icons.add_photo_alternate_outlined, color: Colors.white),
// //             ),
// //           ),
// //
// //         if (_isLoading)
// //           Container(
// //             color: Colors.black.withOpacity(0.5),
// //             child: const Center(
// //               child: CircularProgressIndicator(),
// //             ),
// //           ),
// //       ],
// //     );
// //   }
// //
// //   Widget _buildGalleryView() {
// //     return Column(
// //       children: [
// //         Expanded(
// //           child: _images.isEmpty
// //               ? _buildEmptyState()
// //               : _buildImagesGrid(),
// //         ),
// //         if (_images.isNotEmpty)
// //           _buildPaginationControls(),
// //       ],
// //     );
// //   }
// //
// //   Widget _buildEmptyState() {
// //     return Center(
// //       child: Column(
// //         mainAxisAlignment: MainAxisAlignment.center,
// //         children: [
// //           Icon(Icons.photo_library_outlined, size: 60, color: Colors.grey[400]),
// //           const SizedBox(height: 16),
// //           Text(
// //             'Aucune image disponible',
// //             style: GoogleFonts.poppins(color: Colors.grey[600]),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Widget _buildImagesGrid() {
// //     return GridView.builder(
// //       padding: const EdgeInsets.all(12),
// //       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
// //         crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
// //         childAspectRatio: 1,
// //         crossAxisSpacing: 12,
// //         mainAxisSpacing: 12,
// //       ),
// //       itemCount: _currentPageImages.length,
// //       itemBuilder: (context, index) {
// //         final actualIndex = _currentPage * _imagesPerPage + index;
// //         final imageUrl = _currentPageImages[index].image;
// //
// //         return GestureDetector(
// //           onTap: () {
// //             setState(() {
// //               _enlargedImageIndex = actualIndex;
// //             });
// //           },
// //           child: Stack(
// //             fit: StackFit.expand,
// //             children: [
// //               ClipRRect(
// //                 borderRadius: BorderRadius.circular(12),
// //                 child: Image.network(
// //                   imageUrl,
// //                   fit: BoxFit.cover,
// //                   loadingBuilder: (context, child, loadingProgress) {
// //                     if (loadingProgress == null) return child;
// //                     return Center(
// //                       child: CircularProgressIndicator(
// //                         value: loadingProgress.expectedTotalBytes != null
// //                             ? loadingProgress.cumulativeBytesLoaded /
// //                             (loadingProgress.expectedTotalBytes ?? 1)
// //                             : null,
// //                       ),
// //                     );
// //                   },
// //                   errorBuilder: (context, error, stackTrace) {
// //                     return Container(
// //                       color: Colors.grey[200],
// //                       child: Center(
// //                         child: Icon(Icons.broken_image, color: Colors.grey[400]),
// //                       ),
// //                     );
// //                   },
// //                 ),
// //               ),
// //               if (_isOwner)
// //                 Positioned(
// //                   top: 8,
// //                   right: 8,
// //                   child: GestureDetector(
// //                     onTap: () => _confirmDeleteImage(actualIndex),
// //                     child: Container(
// //                       padding: const EdgeInsets.all(6),
// //                       decoration: BoxDecoration(
// //                         color: Colors.red.withOpacity(0.7),
// //                         shape: BoxShape.circle,
// //                       ),
// //                       child: const Icon(
// //                         Icons.delete_outline,
// //                         color: Colors.white,
// //                         size: 20,
// //                       ),
// //                     ),
// //                   ),
// //                 ),
// //             ],
// //           ),
// //         );
// //       },
// //     );
// //   }
// //
// //   Widget _buildEnlargedView() {
// //     if (_enlargedImageIndex == null || _enlargedImageIndex! >= _images.length) {
// //       return const SizedBox.shrink();
// //     }
// //     final imageUrl = 'https://hairbnb.site/${_images[_enlargedImageIndex!].image}';
// //
// //     return Stack(
// //       fit: StackFit.expand,
// //       children: [
// //         InteractiveViewer(
// //           minScale: 0.5,
// //           maxScale: 3.0,
// //           child: Container(
// //             color: Colors.black,
// //             child: Center(
// //               child: Image.network(
// //                 imageUrl,
// //                 fit: BoxFit.contain,
// //                 loadingBuilder: (context, child, loadingProgress) {
// //                   if (loadingProgress == null) return child;
// //                   return Center(
// //                     child: CircularProgressIndicator(
// //                       value: loadingProgress.expectedTotalBytes != null
// //                           ? loadingProgress.cumulativeBytesLoaded /
// //                           (loadingProgress.expectedTotalBytes ?? 1)
// //                           : null,
// //                       color: Colors.white,
// //                     ),
// //                   );
// //                 },
// //               ),
// //             ),
// //           ),
// //         ),
// //         // Controls overlay
// //         Positioned(
// //           top: 0,
// //           left: 0,
// //           right: 0,
// //           child: Container(
// //             color: Colors.black.withOpacity(0.5),
// //             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
// //             child: Row(
// //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //               children: [
// //                 IconButton(
// //                   icon: const Icon(Icons.close, color: Colors.white),
// //                   onPressed: () {
// //                     setState(() {
// //                       _enlargedImageIndex = null;
// //                     });
// //                   },
// //                 ),
// //                 Text(
// //                   'Image ${_enlargedImageIndex! + 1}/${_images.length}',
// //                   style: GoogleFonts.poppins(
// //                     color: Colors.white,
// //                     fontWeight: FontWeight.bold,
// //                   ),
// //                 ),
// //                 if (_isOwner)
// //                   IconButton(
// //                     icon: const Icon(Icons.delete_outline, color: Colors.white),
// //                     onPressed: () => _confirmDeleteImage(_enlargedImageIndex!),
// //                   ),
// //               ],
// //             ),
// //           ),
// //         ),
// //         // Navigation arrows
// //         if (_images.length > 1) ...[
// //           // Previous button
// //           if (_enlargedImageIndex! > 0)
// //             Positioned(
// //               left: 8,
// //               bottom: 0,
// //               top: 0,
// //               child: Center(
// //                 child: IconButton(
// //                   icon: Container(
// //                     padding: const EdgeInsets.all(8),
// //                     decoration: BoxDecoration(
// //                       color: Colors.black.withOpacity(0.5),
// //                       shape: BoxShape.circle,
// //                     ),
// //                     child: const Icon(Icons.chevron_left, color: Colors.white),
// //                   ),
// //                   onPressed: () {
// //                     setState(() {
// //                       _enlargedImageIndex = _enlargedImageIndex! - 1;
// //                     });
// //                   },
// //                 ),
// //               ),
// //             ),
// //           // Next button
// //           if (_enlargedImageIndex! < _images.length - 1)
// //             Positioned(
// //               right: 8,
// //               bottom: 0,
// //               top: 0,
// //               child: Center(
// //                 child: IconButton(
// //                   icon: Container(
// //                     padding: const EdgeInsets.all(8),
// //                     decoration: BoxDecoration(
// //                       color: Colors.black.withOpacity(0.5),
// //                       shape: BoxShape.circle,
// //                     ),
// //                     child: const Icon(Icons.chevron_right, color: Colors.white),
// //                   ),
// //                   onPressed: () {
// //                     setState(() {
// //                       _enlargedImageIndex = _enlargedImageIndex! + 1;
// //                     });
// //                   },
// //                 ),
// //               ),
// //             ),
// //         ],
// //       ],
// //     );
// //   }
// //
// //   Widget _buildPaginationControls() {
// //     if (_totalPages <= 1) {
// //       return const SizedBox.shrink();
// //     }
// //
// //     return Container(
// //       padding: const EdgeInsets.symmetric(vertical: 12),
// //       child: Row(
// //         mainAxisAlignment: MainAxisAlignment.center,
// //         children: [
// //           IconButton(
// //             icon: Icon(
// //               Icons.chevron_left,
// //               color: _currentPage > 0
// //                   ? Theme.of(context).primaryColor
// //                   : Colors.grey[400],
// //             ),
// //             onPressed: _currentPage > 0
// //                 ? () {
// //               setState(() {
// //                 _currentPage--;
// //               });
// //             }
// //                 : null,
// //           ),
// //           Text(
// //             '${_currentPage + 1} / $_totalPages',
// //             style: GoogleFonts.poppins(
// //               fontWeight: FontWeight.w500,
// //             ),
// //           ),
// //           IconButton(
// //             icon: Icon(
// //               Icons.chevron_right,
// //               color: _currentPage < _totalPages - 1
// //                   ? Theme.of(context).primaryColor
// //                   : Colors.grey[400],
// //             ),
// //             onPressed: _currentPage < _totalPages - 1
// //                 ? () {
// //               setState(() {
// //                 _currentPage++;
// //               });
// //             }
// //                 : null,
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   void _showAddImageModal() {
// //     showModalBottomSheet(
// //       context: context,
// //       isScrollControlled: true,
// //       backgroundColor: Colors.transparent,
// //       builder: (context) => GalleryModal(
// //         salonId: widget.salonDetails.idTblSalon,
// //         currentImagesCount: _images.length,
// //         onImagesAdded: (List<SalonImage> newImages) {
// //           setState(() {
// //             _images.addAll(newImages);
// //           });
// //         },
// //       ),
// //     );
// //   }
// //
// //   void _confirmDeleteImage(int index) {
// //     showDialog(
// //       context: context,
// //       builder: (context) => AlertDialog(
// //         title: Text(
// //           'Supprimer l\'image',
// //           style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
// //         ),
// //         content: Text(
// //           'Êtes-vous sûr de vouloir supprimer cette image ? Cette action est irréversible.',
// //           style: GoogleFonts.poppins(),
// //         ),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Navigator.pop(context),
// //             child: Text(
// //               'Annuler',
// //               style: GoogleFonts.poppins(),
// //             ),
// //           ),
// //           TextButton(
// //             onPressed: () {
// //               Navigator.pop(context);
// //               _deleteImage(index);
// //             },
// //             child: Text(
// //               'Supprimer',
// //               style: GoogleFonts.poppins(color: Colors.red),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Future<void> _deleteImage(int index) async {
// //     setState(() {
// //       _isLoading = true;
// //     });
// //
// //     try {
// //       // Nous avons besoin d'un ID pour l'image
// //       // Dans certains cas, l'image pourrait ne pas avoir d'ID
// //       // Une solution alternative serait de gérer cela côté serveur
// //
// //       // Simulation de suppression pour l'instant
// //       await Future.delayed(const Duration(milliseconds: 500));
// //
// //       setState(() {
// //         if (_enlargedImageIndex != null) {
// //           _enlargedImageIndex = null;
// //         }
// //
// //         _images.removeAt(index);
// //
// //         // Ajuster la page courante si nécessaire
// //         if (_currentPage >= _totalPages && _currentPage > 0) {
// //           _currentPage = _totalPages - 1;
// //         }
// //       });
// //
// //       // Pour le cas où vous implémenteriez un véritable appel API :
// //       // final imageToDelete = _images[index];
// //       // await GalleryApi.deleteImage(imageId);
// //
// //     } catch (e) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //           content: Text('Erreur lors de la suppression: $e'),
// //           backgroundColor: Colors.red,
// //         ),
// //       );
// //     } finally {
// //       setState(() {
// //         _isLoading = false;
// //       });
// //     }
// //   }
// // }
//
//
//
//
//
//
//
// // // lib/public_salon_details/widgets/gallery_widget.dart
// //
// // import 'dart:io';
// // import 'package:flutter/material.dart';
// // import 'package:google_fonts/google_fonts.dart';
// // import 'package:image_picker/image_picker.dart';
// // import '../../../models/public_salon_details.dart';
// // import '../modals/gallery_modal.dart';
// //
// // class GalleryWidget extends StatefulWidget {
// //   final PublicSalonDetails salonDetails;
// //   final int currentUserId;
// //
// //   const GalleryWidget({
// //     super.key,
// //     required this.salonDetails,
// //     required this.currentUserId,
// //   });
// //
// //   @override
// //   State<GalleryWidget> createState() => _GalleryWidgetState();
// // }
// //
// // class _GalleryWidgetState extends State<GalleryWidget> {
// //   int _currentPage = 0;
// //   int _imagesPerPage = 10;
// //   bool _isLoading = false;
// //   List<SalonImage> _images = [];
// //   int? _enlargedImageIndex;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _images = List.from(widget.salonDetails.images);
// //   }
// //
// //   bool get _isOwner => widget.currentUserId ==
// //       widget.salonDetails.coiffeuse.idTblUser.idTblUser;
// //
// //   List<SalonImage> get _currentPageImages {
// //     final startIndex = _currentPage * _imagesPerPage;
// //     final endIndex = startIndex + _imagesPerPage;
// //
// //     if (startIndex >= _images.length) {
// //       return [];
// //     }
// //
// //     return _images.sublist(
// //       startIndex,
// //       endIndex > _images.length ? _images.length : endIndex,
// //     );
// //   }
// //
// //   int get _totalPages => (_images.length / _imagesPerPage).ceil();
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Stack(
// //       children: [
// //         _enlargedImageIndex != null
// //             ? _buildEnlargedView()
// //             : _buildGalleryView(),
// //
// //         if (_isOwner && _enlargedImageIndex == null && _images.length < 25)
// //           Positioned(
// //             bottom: 16,
// //             right: 16,
// //             child: FloatingActionButton(
// //               onPressed: _showAddImageModal,
// //               backgroundColor: Theme.of(context).primaryColor,
// //               child: const Icon(Icons.add_photo_alternate_outlined, color: Colors.white),
// //             ),
// //           ),
// //
// //         if (_isLoading)
// //           Container(
// //             color: Colors.black.withOpacity(0.5),
// //             child: const Center(
// //               child: CircularProgressIndicator(),
// //             ),
// //           ),
// //       ],
// //     );
// //   }
// //
// //   Widget _buildGalleryView() {
// //     return Column(
// //       children: [
// //         Expanded(
// //           child: _images.isEmpty
// //               ? _buildEmptyState()
// //               : _buildImagesGrid(),
// //         ),
// //         if (_images.isNotEmpty)
// //           _buildPaginationControls(),
// //       ],
// //     );
// //   }
// //
// //   Widget _buildEmptyState() {
// //     return Center(
// //       child: Column(
// //         mainAxisAlignment: MainAxisAlignment.center,
// //         children: [
// //           Icon(Icons.photo_library_outlined, size: 60, color: Colors.grey[400]),
// //           const SizedBox(height: 16),
// //           Text(
// //             'Aucune image disponible',
// //             style: GoogleFonts.poppins(color: Colors.grey[600]),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Widget _buildImagesGrid() {
// //     return GridView.builder(
// //       padding: const EdgeInsets.all(12),
// //       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
// //         crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
// //         childAspectRatio: 1,
// //         crossAxisSpacing: 12,
// //         mainAxisSpacing: 12,
// //       ),
// //       itemCount: _currentPageImages.length,
// //       itemBuilder: (context, index) {
// //         final actualIndex = _currentPage * _imagesPerPage + index;
// //         final imageUrl = _currentPageImages[index].image;
// //
// //         return GestureDetector(
// //           onTap: () {
// //             setState(() {
// //               _enlargedImageIndex = actualIndex;
// //             });
// //           },
// //           child: Stack(
// //             fit: StackFit.expand,
// //             children: [
// //               ClipRRect(
// //                 borderRadius: BorderRadius.circular(12),
// //                 child: Image.network(
// //                   imageUrl,
// //                   fit: BoxFit.cover,
// //                   loadingBuilder: (context, child, loadingProgress) {
// //                     if (loadingProgress == null) return child;
// //                     return Center(
// //                       child: CircularProgressIndicator(
// //                         value: loadingProgress.expectedTotalBytes != null
// //                             ? loadingProgress.cumulativeBytesLoaded /
// //                             (loadingProgress.expectedTotalBytes ?? 1)
// //                             : null,
// //                       ),
// //                     );
// //                   },
// //                   errorBuilder: (context, error, stackTrace) {
// //                     return Container(
// //                       color: Colors.grey[200],
// //                       child: Center(
// //                         child: Icon(Icons.broken_image, color: Colors.grey[400]),
// //                       ),
// //                     );
// //                   },
// //                 ),
// //               ),
// //               if (_isOwner)
// //                 Positioned(
// //                   top: 8,
// //                   right: 8,
// //                   child: GestureDetector(
// //                     onTap: () => _confirmDeleteImage(actualIndex),
// //                     child: Container(
// //                       padding: const EdgeInsets.all(6),
// //                       decoration: BoxDecoration(
// //                         color: Colors.red.withOpacity(0.7),
// //                         shape: BoxShape.circle,
// //                       ),
// //                       child: const Icon(
// //                         Icons.delete_outline,
// //                         color: Colors.white,
// //                         size: 20,
// //                       ),
// //                     ),
// //                   ),
// //                 ),
// //             ],
// //           ),
// //         );
// //       },
// //     );
// //   }
// //
// //   Widget _buildEnlargedView() {
// //     if (_enlargedImageIndex == null || _enlargedImageIndex! >= _images.length) {
// //       return const SizedBox.shrink();
// //     }
// //
// //     final imageUrl = _images[_enlargedImageIndex!].image;
// //
// //     return Stack(
// //       fit: StackFit.expand,
// //       children: [
// //         InteractiveViewer(
// //           minScale: 0.5,
// //           maxScale: 3.0,
// //           child: Container(
// //             color: Colors.black,
// //             child: Center(
// //               child: Image.network(
// //                 imageUrl,
// //                 fit: BoxFit.contain,
// //                 loadingBuilder: (context, child, loadingProgress) {
// //                   if (loadingProgress == null) return child;
// //                   return Center(
// //                     child: CircularProgressIndicator(
// //                       value: loadingProgress.expectedTotalBytes != null
// //                           ? loadingProgress.cumulativeBytesLoaded /
// //                           (loadingProgress.expectedTotalBytes ?? 1)
// //                           : null,
// //                       color: Colors.white,
// //                     ),
// //                   );
// //                 },
// //               ),
// //             ),
// //           ),
// //         ),
// //         // Controls overlay
// //         Positioned(
// //           top: 0,
// //           left: 0,
// //           right: 0,
// //           child: Container(
// //             color: Colors.black.withOpacity(0.5),
// //             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
// //             child: Row(
// //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //               children: [
// //                 IconButton(
// //                   icon: const Icon(Icons.close, color: Colors.white),
// //                   onPressed: () {
// //                     setState(() {
// //                       _enlargedImageIndex = null;
// //                     });
// //                   },
// //                 ),
// //                 Text(
// //                   'Image ${_enlargedImageIndex! + 1}/${_images.length}',
// //                   style: GoogleFonts.poppins(
// //                     color: Colors.white,
// //                     fontWeight: FontWeight.bold,
// //                   ),
// //                 ),
// //                 if (_isOwner)
// //                   IconButton(
// //                     icon: const Icon(Icons.delete_outline, color: Colors.white),
// //                     onPressed: () => _confirmDeleteImage(_enlargedImageIndex!),
// //                   ),
// //               ],
// //             ),
// //           ),
// //         ),
// //         // Navigation arrows
// //         if (_images.length > 1) ...[
// //           // Previous button
// //           if (_enlargedImageIndex! > 0)
// //             Positioned(
// //               left: 8,
// //               bottom: 0,
// //               top: 0,
// //               child: Center(
// //                 child: IconButton(
// //                   icon: Container(
// //                     padding: const EdgeInsets.all(8),
// //                     decoration: BoxDecoration(
// //                       color: Colors.black.withOpacity(0.5),
// //                       shape: BoxShape.circle,
// //                     ),
// //                     child: const Icon(Icons.chevron_left, color: Colors.white),
// //                   ),
// //                   onPressed: () {
// //                     setState(() {
// //                       _enlargedImageIndex = _enlargedImageIndex! - 1;
// //                     });
// //                   },
// //                 ),
// //               ),
// //             ),
// //           // Next button
// //           if (_enlargedImageIndex! < _images.length - 1)
// //             Positioned(
// //               right: 8,
// //               bottom: 0,
// //               top: 0,
// //               child: Center(
// //                 child: IconButton(
// //                   icon: Container(
// //                     padding: const EdgeInsets.all(8),
// //                     decoration: BoxDecoration(
// //                       color: Colors.black.withOpacity(0.5),
// //                       shape: BoxShape.circle,
// //                     ),
// //                     child: const Icon(Icons.chevron_right, color: Colors.white),
// //                   ),
// //                   onPressed: () {
// //                     setState(() {
// //                       _enlargedImageIndex = _enlargedImageIndex! + 1;
// //                     });
// //                   },
// //                 ),
// //               ),
// //             ),
// //         ],
// //       ],
// //     );
// //   }
// //
// //   Widget _buildPaginationControls() {
// //     if (_totalPages <= 1) {
// //       return const SizedBox.shrink();
// //     }
// //
// //     return Container(
// //       padding: const EdgeInsets.symmetric(vertical: 12),
// //       child: Row(
// //         mainAxisAlignment: MainAxisAlignment.center,
// //         children: [
// //           IconButton(
// //             icon: Icon(
// //               Icons.chevron_left,
// //               color: _currentPage > 0
// //                   ? Theme.of(context).primaryColor
// //                   : Colors.grey[400],
// //             ),
// //             onPressed: _currentPage > 0
// //                 ? () {
// //               setState(() {
// //                 _currentPage--;
// //               });
// //             }
// //                 : null,
// //           ),
// //           Text(
// //             '${_currentPage + 1} / $_totalPages',
// //             style: GoogleFonts.poppins(
// //               fontWeight: FontWeight.w500,
// //             ),
// //           ),
// //           IconButton(
// //             icon: Icon(
// //               Icons.chevron_right,
// //               color: _currentPage < _totalPages - 1
// //                   ? Theme.of(context).primaryColor
// //                   : Colors.grey[400],
// //             ),
// //             onPressed: _currentPage < _totalPages - 1
// //                 ? () {
// //               setState(() {
// //                 _currentPage++;
// //               });
// //             }
// //                 : null,
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   void _showAddImageModal() {
// //     showModalBottomSheet(
// //       context: context,
// //       isScrollControlled: true,
// //       backgroundColor: Colors.transparent,
// //       builder: (context) => GalleryModal(
// //         salonId: widget.salonDetails.idTblSalon,
// //         currentImagesCount: _images.length,
// //         onImagesAdded: (List<SalonImage> newImages) {
// //           setState(() {
// //             _images.addAll(newImages);
// //           });
// //         },
// //       ),
// //     );
// //   }
// //
// //   void _confirmDeleteImage(int index) {
// //     showDialog(
// //       context: context,
// //       builder: (context) => AlertDialog(
// //         title: Text(
// //           'Supprimer l\'image',
// //           style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
// //         ),
// //         content: Text(
// //           'Êtes-vous sûr de vouloir supprimer cette image ? Cette action est irréversible.',
// //           style: GoogleFonts.poppins(),
// //         ),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Navigator.pop(context),
// //             child: Text(
// //               'Annuler',
// //               style: GoogleFonts.poppins(),
// //             ),
// //           ),
// //           TextButton(
// //             onPressed: () {
// //               Navigator.pop(context);
// //               _deleteImage(index);
// //             },
// //             child: Text(
// //               'Supprimer',
// //               style: GoogleFonts.poppins(color: Colors.red),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Future<void> _deleteImage(int index) async {
// //     setState(() {
// //       _isLoading = true;
// //     });
// //
// //     try {
// //       // Nous avons besoin d'un ID pour l'image
// //       // Dans certains cas, l'image pourrait ne pas avoir d'ID
// //       // Une solution alternative serait de gérer cela côté serveur
// //
// //       // Simulation de suppression pour l'instant
// //       await Future.delayed(const Duration(milliseconds: 500));
// //
// //       setState(() {
// //         if (_enlargedImageIndex != null) {
// //           _enlargedImageIndex = null;
// //         }
// //
// //         _images.removeAt(index);
// //
// //         // Ajuster la page courante si nécessaire
// //         if (_currentPage >= _totalPages && _currentPage > 0) {
// //           _currentPage = _totalPages - 1;
// //         }
// //       });
// //
// //       // Pour le cas où vous implémenteriez un véritable appel API :
// //       // final imageToDelete = _images[index];
// //       // await GalleryApi.deleteImage(imageId);
// //
// //     } catch (e) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //           content: Text('Erreur lors de la suppression: $e'),
// //           backgroundColor: Colors.red,
// //         ),
// //       );
// //     } finally {
// //       setState(() {
// //         _isLoading = false;
// //       });
// //     }
// //   }
// // }
//
//
//
//
//
//
// // // lib/public_salon_details/widgets/gallery_widget.dart
// //
// // import 'dart:io';
// //
// // import 'package:file_picker/file_picker.dart';
// // import 'package:flutter/material.dart';
// // import 'package:google_fonts/google_fonts.dart';
// // import 'package:image_picker/image_picker.dart';
// // import '../../../models/public_salon_details.dart';
// //
// // class GalleryWidget extends StatelessWidget {
// //   final List<SalonImage> images;
// //   final bool showAddButton;
// //
// //   const GalleryWidget({
// //     super.key,
// //     required this.images,
// //     this.showAddButton = false,
// //   });
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Stack(
// //       children: [
// //         images.isEmpty
// //             ? Center(
// //           child: Column(
// //             mainAxisAlignment: MainAxisAlignment.center,
// //             children: [
// //               Icon(Icons.photo_library_outlined,
// //                   size: 60, color: Colors.grey[400]),
// //               const SizedBox(height: 16),
// //               Text(
// //                 'Aucune image disponible',
// //                 style: GoogleFonts.poppins(color: Colors.grey[600]),
// //               ),
// //             ],
// //           ),
// //         )
// //             : GridView.builder(
// //           padding: const EdgeInsets.all(12),
// //           gridDelegate:
// //           const SliverGridDelegateWithFixedCrossAxisCount(
// //             crossAxisCount: 2,
// //             childAspectRatio: 1,
// //             crossAxisSpacing: 12,
// //             mainAxisSpacing: 12,
// //           ),
// //           itemCount: images.length,
// //           itemBuilder: (context, index) {
// //             final image = images[index].image;
// //             return ClipRRect(
// //               borderRadius: BorderRadius.circular(12),
// //               child: Image.network(image, fit: BoxFit.cover),
// //             );
// //           },
// //         ),
// //         if (showAddButton)
// //           Positioned(
// //             bottom: 16,
// //             right: 16,
// //             child: FloatingActionButton(
// //               onPressed: () {
// //                 _showAddImageModal(context);
// //               },
// //               backgroundColor: Colors.white,
// //               child: const Icon(Icons.add_photo_alternate_outlined),
// //             ),
// //           ),
// //       ],
// //     );
// //   }
// //
// //   void _showAddImageModal(BuildContext context) {
// //     showModalBottomSheet(
// //       context: context,
// //       shape: const RoundedRectangleBorder(
// //         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
// //       ),
// //       builder: (_) => Padding(
// //         padding: const EdgeInsets.all(20),
// //         child: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             Text('Ajouter une image à la galerie',
// //                 style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
// //             const SizedBox(height: 20),
// //             ElevatedButton.icon(
// //               onPressed: () async {
// //                 FilePickerResult? result = await FilePicker.platform.pickFiles(
// //                   type: FileType.image,
// //                 );
// //                 if (result != null && result.files.isNotEmpty) {
// //                   final fileBytes = result.files.first.bytes;
// //                   final fileName = result.files.first.name;
// //                   print("Nom : $fileName");
// //                   // 👇 ici tu peux envoyer l’image à ton backend
// //                 }
// //               },
// //               icon: const Icon(Icons.upload_file),
// //               label: const Text('Choisir une image'),
// //               style: ElevatedButton.styleFrom(
// //                 backgroundColor: Colors.white,
// //                 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
// //                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
//
//
//   // void _showAddImageModal(BuildContext context) {
//   //   showModalBottomSheet(
//   //     context: context,
//   //     shape: const RoundedRectangleBorder(
//   //         borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
//   //     builder: (_) => Padding(
//   //       padding: const EdgeInsets.all(20),
//   //       child: Column(
//   //         mainAxisSize: MainAxisSize.min,
//   //         children: [
//   //           Text('Ajouter une image à la galerie',
//   //               style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
//   //           const SizedBox(height: 20),
//   //           ElevatedButton.icon(
//   //             onPressed: () {
//   //               _pickImage(context);
//   //             },
//   //             icon: const Icon(Icons.upload_file),
//   //             label: const Text('Choisir depuis la galerie'),
//   //             style: ElevatedButton.styleFrom(
//   //               backgroundColor: Colors.deepPurple,
//   //               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//   //               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//   //             ),
//   //           ),
//   //         ],
//   //       ),
//   //     ),
//   //   );
//   // }
//
// //   Future<void> _pickImage(BuildContext context) async {
// //     final picker = ImagePicker();
// //     final pickedFile = await picker.pickImage(source: ImageSource.gallery);
// //
// //     if (pickedFile != null) {
// //       final File image = File(pickedFile.path);
// //
// //       // 👉 Ici, appelle ton API pour uploader l’image sur le serveur
// //       // et rafraîchis la galerie si nécessaire
// //       print('Image sélectionnée : ${image.path}');
// //       Navigator.pop(context); // Fermer le modal après sélection
// //     } else {
// //       print('Aucune image sélectionnée.');
// //     }
// //   }
// //
// // }
//
//
//
//
//
// // // lib/public_salon_details/widgets/gallery_widget.dart
// // import 'package:flutter/material.dart';
// // import 'package:google_fonts/google_fonts.dart';
// // import '../../../models/public_salon_details.dart';
// //
// // class GalleryWidget extends StatelessWidget {
// //   final List<SalonImage> images;
// //
// //   const GalleryWidget({super.key, required this.images});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     if (images.isEmpty) {
// //       return Center(
// //         child: Column(
// //           mainAxisAlignment: MainAxisAlignment.center,
// //           children: [
// //             Icon(Icons.photo_library_outlined, size: 60, color: Colors.grey[400]),
// //             const SizedBox(height: 16),
// //             Text('Aucune image disponible',
// //                 style: GoogleFonts.poppins(color: Colors.grey[600])),
// //           ],
// //         ),
// //       );
// //     }
// //
// //     return GridView.builder(
// //       padding: const EdgeInsets.all(12),
// //       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
// //         crossAxisCount: 2,
// //         childAspectRatio: 1,
// //         crossAxisSpacing: 12,
// //         mainAxisSpacing: 12,
// //       ),
// //       itemCount: images.length,
// //       itemBuilder: (context, index) {
// //         final image = images[index].image;
// //         return ClipRRect(
// //           borderRadius: BorderRadius.circular(12),
// //           child: Image.network(image, fit: BoxFit.cover),
// //         );
// //       },
// //     );
// //   }
// // }
