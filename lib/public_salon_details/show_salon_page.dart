/// *************************************************************************************************
/// *
/// BANNIÈRE : EXPLICATION DU WIDGET SALONDETAILSPAGE                                                 *
/// ---------------------------------------------------                                             *
/// *
/// OBJECTIF :                                                                                      *
/// Ce fichier définit le widget `SalonDetailsPage`, une page complète et dynamique conçue pour     *
/// afficher toutes les informations relatives à un salon de coiffure spécifique.                   *
/// *
/// FONCTIONNALITÉS PRINCIPALES :                                                                   *
/// 1. RÉCUPÉRATION DE DONNÉES : La page charge de manière asynchrone les détails du salon (nom,     *
/// images, services, etc.) depuis une API en utilisant l'ID du salon fourni.                       *
/// 2. GESTION DES FAVORIS : Vérifie si le salon est dans les favoris de l'utilisateur connecté.     *
/// Permet à l'utilisateur d'ajouter ou de retirer le salon de ses favoris via un bouton dédié.     *
/// 3. INTERFACE UTILISATEUR AVANCÉE :                                                              *
/// - Utilise un `NestedScrollView` avec une `SliverAppBar` pour créer un effet de barre         *
/// d'en-tête qui se réduit lors du défilement, affichant l'image du salon.                     *
/// - Organise les informations en plusieurs onglets (`TabBar` / `TabBarView`) : "Services",      *
/// "Équipements", "Spécialiste", et "Galerie".                                                 *
/// 4. GESTION D'ÉTAT ROBUSTE : Emploie un `FutureBuilder` pour gérer l'affichage pendant le         *
/// chargement, en cas d'erreur (avec une option pour réessayer), ou lorsque les données sont       *
/// chargées avec succès.                                                                           *
/// 5. NAVIGATION : Intègre une barre d'application et une barre de navigation inférieure          *
/// personnalisées (`CustomAppBar`, `BottomNavBar`) et gère la navigation (retour en arrière).      *
/// 6. AFFICHAGE MODAL : Affiche les horaires d'ouverture du salon dans une fenêtre modale.          *
/// *
///*************************************************************************************************
library;

// Importation des bibliothèques et des fichiers nécessaires au fonctionnement de la page.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/public_salon_details.dart';
import 'api/PublicSalonDetailsApi.dart';
import 'modals/show_horaires_modal.dart';
import 'services/favorites_services.dart';
import 'widgets/gallery_widget.dart';
import 'widgets/service_price_widget.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/bottom_nav_bar.dart';

// Déclaration du widget avec état pour la page de détails du salon.
class SalonDetailsPage extends StatefulWidget {
  // Identifiant unique du salon à afficher.
  final int salonId;
  // Identifiant de l'utilisateur actuellement connecté.
  final int currentUserId;

  // Constructeur du widget, requérant l'ID du salon et l'ID de l'utilisateur.
  const SalonDetailsPage({super.key, required this.salonId, required this.currentUserId});

  @override
  _SalonDetailsPageState createState() => _SalonDetailsPageState();
}

// Classe d'état pour SalonDetailsPage.
class _SalonDetailsPageState extends State<SalonDetailsPage> with SingleTickerProviderStateMixin {
  // Future pour stocker et gérer le chargement des détails du salon.
  late Future<PublicSalonDetails> _salonFuture;
  // Contrôleur pour gérer les onglets de l'interface.
  late TabController _tabController;
  // Booléen pour suivre si le salon est actuellement un favori.
  bool _isFavorite = false;
  // Booléen pour gérer l'état de chargement du statut de favori.
  bool _isLoadingFavorite = true;

  @override
  void initState() {
    super.initState();
    // Lance l'appel API pour obtenir les détails du salon.
    _salonFuture = PublicSalonDetailsApi.getSalonDetails(widget.salonId);
    // Initialise le contrôleur d'onglets avec 4 onglets.
    _tabController = TabController(length: 4, vsync: this);
    // Vérifie le statut de favori du salon pour l'utilisateur courant.
    _checkFavoriteStatus();
  }

  // Méthode asynchrone pour vérifier si le salon est dans les favoris de l'utilisateur.
  Future<void> _checkFavoriteStatus() async {
    // Si l'utilisateur n'est pas connecté (ID invalide), on arrête le processus.
    if (widget.currentUserId <= 0) {
      setState(() {
        _isFavorite = false;
        _isLoadingFavorite = false;
      });
      return;
    }

    // Indique le début du chargement.
    setState(() => _isLoadingFavorite = true);

    try {
      // Appelle le service pour obtenir les informations de favori.
      final favorite = await FavoritesService.getFavoriteForSalon(
          widget.currentUserId,
          widget.salonId
      );

      // Met à jour l'état de l'interface si le widget est toujours monté.
      if (mounted) {
        setState(() {
          _isFavorite = favorite != null;
          _isLoadingFavorite = false;
        });
      }
    } catch (e) {
      // En cas d'erreur, arrête le chargement et affiche un message d'erreur.
      if (mounted) {
        setState(() => _isLoadingFavorite = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la vérification des favoris: $e')),
        );
      }
    }
  }

  // Gère l'action d'ajouter ou de retirer un salon des favoris.
  Future<void> _toggleFavorite() async {
    // Empêche l'action si l'utilisateur n'est pas connecté.
    if (widget.currentUserId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous devez être connecté pour ajouter des favoris')),
      );
      return;
    }

    // Indique le début de l'opération.
    setState(() => _isLoadingFavorite = true);

    try {
      // Appelle le service qui gère l'ajout/suppression du favori.
      final newFavoriteStatus = await FavoritesService.toggleFavorite(
          widget.currentUserId,
          widget.salonId
      );

      // Met à jour l'interface avec le nouveau statut.
      if (mounted) {
        setState(() {
          _isFavorite = newFavoriteStatus;
          _isLoadingFavorite = false;
        });

        // Affiche une confirmation à l'utilisateur.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFavorite
                ? 'Salon ajouté aux favoris'
                : 'Salon retiré des favoris'
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      // Gère les erreurs potentielles lors de l'opération.
      if (mounted) {
        setState(() => _isLoadingFavorite = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    // Libère les ressources du contrôleur d'onglets pour éviter les fuites de mémoire.
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Le widget principal de la page.
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: const CustomAppBar(),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1,
        onTap: (index) {},
      ),
      // Le corps de la page est protégé par un SafeArea.
      body: SafeArea(
        // FutureBuilder gère l'état de la récupération des données du salon.
        child: FutureBuilder<PublicSalonDetails>(
          future: _salonFuture,
          builder: (context, snapshot) {
            // État de chargement : affiche un indicateur de progression.
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.deepPurple),
              );
            }
            // État d'erreur : affiche un message d'erreur et un bouton pour réessayer.
            else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 60),
                    const SizedBox(height: 16),
                    Text('Erreur: ${snapshot.error}', style: GoogleFonts.poppins(fontSize: 16)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _salonFuture = PublicSalonDetailsApi.getSalonDetails(widget.salonId);
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              );
            }
            // État où il n'y a pas de données.
            else if (!snapshot.hasData) {
              return const Center(child: Text('Aucune information disponible'));
            }

            // Les données sont chargées avec succès.
            final salonDetails = snapshot.data!;

            // `NestedScrollView` permet de combiner des vues scrollables, comme une SliverAppBar et un TabBarView.
            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                // La barre d'application qui se réduit au défilement.
                SliverAppBar(
                  expandedHeight: 220,
                  pinned: true,
                  backgroundColor: Colors.deepPurple,
                  // L'espace flexible qui contient l'image du salon.
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Affiche l'image du salon ou une image de la galerie, avec un conteneur de secours.
                        salonDetails.logoSalon != null && salonDetails.logoSalon!.isNotEmpty
                            ? Image.network(salonDetails.logoSalon!, fit: BoxFit.cover)
                            : salonDetails.images.isNotEmpty
                            ? Image.network(salonDetails.images.first.image, fit: BoxFit.cover)
                            : Container(color: Colors.grey[300]),
                        // Ajoute un dégradé pour améliorer la lisibilité du texte sur l'image.
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Bouton de retour en arrière.
                  leading: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  // Actions de la barre d'application, ici le bouton de favori.
                  actions: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        // Affiche un indicateur de chargement ou le bouton de favori.
                        child: _isLoadingFavorite
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                          ),
                        )
                            : IconButton(
                          icon: Icon(
                            _isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: _isFavorite ? Colors.red : Colors.grey,
                          ),
                          onPressed: _toggleFavorite,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              // Le corps principal de la vue scrollable.
              body: Column(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        // Conteneur pour les informations principales du salon.
                        Container(
                          padding: const EdgeInsets.all(20),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, -4),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Affiche le nom du salon et sa note moyenne.
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      salonDetails.nomSalon,
                                      style: GoogleFonts.poppins(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade600,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.star, size: 16, color: Colors.white),
                                        const SizedBox(width: 4),
                                        Text(
                                          salonDetails.noteMoyenne.toString(),
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Affiche l'adresse du salon.
                              Row(
                                children: [
                                  _infoIcon(Icons.location_on),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      salonDetails.adresse ?? 'Adresse non disponible',
                                      style: GoogleFonts.poppins(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // Affiche un lien cliquable pour voir les horaires.
                              Row(
                                children: [
                                  _infoIcon(Icons.access_time),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                        onTap: () => showHorairesModal(context, salonDetails.horaires ?? ''),
                                        child: Row(
                                          children: [
                                            Text(
                                              'Voir les horaires',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: Colors.deepPurple,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.deepPurple),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Contenu des onglets.
                        Expanded(
                          child: DefaultTabController(
                            length: 4,
                            child: Column(
                              children: [
                                const SizedBox(height: 12),
                                // Barre d'onglets pour la navigation entre les sections.
                                TabBar(
                                  controller: _tabController,
                                  indicatorColor: Colors.deepPurple,
                                  labelColor: Colors.deepPurple,
                                  unselectedLabelColor: Colors.grey,
                                  labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                  tabs: const [
                                    Tab(text: 'Services'),
                                    Tab(text: 'Équipements'),
                                    Tab(text: 'Spécialiste'),
                                    Tab(text: 'Galerie'),
                                  ],
                                ),
                                // Vue contenant le contenu de chaque onglet.
                                Expanded(
                                  child: TabBarView(
                                    controller: _tabController,
                                    children: [
                                      _buildServicesTab(salonDetails),
                                      _buildEquipmentsTab(),
                                      _buildSpecialisteTab(salonDetails),
                                      GalleryWidget(
                                          salonDetails: salonDetails,
                                          currentUserId: widget.currentUserId
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Widget helper pour créer une icône d'information stylisée.
  Widget _infoIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: Colors.deepPurple, size: 20),
    );
  }

  // Construit le contenu de l'onglet "Services".
  Widget _buildServicesTab(PublicSalonDetails salon) {
    final services = salon.serviceSalonDetailsList;

    // Affiche un message si la liste des services est vide.
    if (services.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.healing_outlined, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucun service disponible',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Affiche une liste de cartes, chacune représentant un service.
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Affiche l'intitulé du service et une éventuelle promotion.
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        service.intituleService,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ),
                    if (service.promotionActive != null)
                      Container(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '-${service.promotionActive!.discountPercentage}%',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                // Affiche la description du service.
                Text(
                  service.description,
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: Colors.grey[700]),
                ),
                const SizedBox(height: 10),
                // Affiche le prix du service (normal et promotionnel si applicable).
                ServicePriceWidget(serviceSalonDetails: service),
              ],
            ),
          ),
        );
      },
    );
  }

  // Construit le contenu de l'onglet "Équipements".
  Widget _buildEquipmentsTab() {
    // Utilise une liste statique de données pour les équipements.
    final equipments = [
      {'icon': Icons.wifi, 'label': 'WIFI'},
      {'icon': Icons.local_parking, 'label': 'Parking'},
      {'icon': Icons.tv, 'label': 'TV'},
      {'icon': Icons.music_note, 'label': 'Musique'},
      {'icon': Icons.coffee, 'label': 'Café'},
    ];

    // Affiche une liste d'équipements.
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: equipments.length,
      itemBuilder: (context, index) {
        final equipment = equipments[index];
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.deepPurple.withOpacity(0.1),
              child: Icon(equipment['icon'] as IconData, color: Colors.deepPurple),
            ),
            title: Text(equipment['label'] as String,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
          ),
        );
      },
    );
  }

  // Construit le contenu de l'onglet "Spécialiste".
  Widget _buildSpecialisteTab(PublicSalonDetails salon) {
    final user = salon.coiffeuse.idTblUser;
    // Utilise un SingleChildScrollView pour s'assurer que le contenu est scrollable.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Affiche la photo de profil du/de la spécialiste.
          CircleAvatar(
            radius: 50,
            backgroundImage: user.photoProfil != null ? NetworkImage(user.photoProfil!) : null,
            backgroundColor: Colors.grey[200],
            child: user.photoProfil == null ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
          ),
          const SizedBox(height: 16),
          // Affiche le nom et le poste.
          Text('${user.prenom} ${user.nom}',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(salon.coiffeuse.position ?? 'Coiffeuse professionnelle',
              style: GoogleFonts.poppins(color: Colors.grey[600])),
          const SizedBox(height: 20),
          // Affiche les informations de contact et professionnelles dans une carte.
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.phone, color: Colors.deepPurple),
                  title: Text('Téléphone', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                  subtitle: Text(user.numeroTelephone ?? 'Non disponible'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.business, color: Colors.deepPurple),
                  title: Text('Dénomination', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                  subtitle: Text(salon.coiffeuse.denominationSociale ?? 'Non disponible'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}







// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../models/favorites.dart';
// import '../models/public_salon_details.dart';
// import 'api/PublicSalonDetailsApi.dart';
// import 'modals/show_horaires_modal.dart';
// import 'services/favorites_services.dart';
// import 'widgets/gallery_widget.dart';
// import 'widgets/service_price_widget.dart';
// import '../widgets/custom_app_bar.dart';
// import '../widgets/bottom_nav_bar.dart';
//
// class SalonDetailsPage extends StatefulWidget {
//   final int salonId;
//   final int currentUserId;
//
//   const SalonDetailsPage({super.key, required this.salonId, required this.currentUserId});
//
//   @override
//   _SalonDetailsPageState createState() => _SalonDetailsPageState();
// }
//
// class _SalonDetailsPageState extends State<SalonDetailsPage> with SingleTickerProviderStateMixin {
//   late Future<PublicSalonDetails> _salonFuture;
//   late TabController _tabController;
//   bool _isFavorite = false;
//   bool _isLoadingFavorite = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _salonFuture = PublicSalonDetailsApi.getSalonDetails(widget.salonId);
//     _tabController = TabController(length: 4, vsync: this);
//     _checkFavoriteStatus();
//   }
//
//   // Vérifier si le salon est déjà dans les favoris
//   Future<void> _checkFavoriteStatus() async {
//     if (widget.currentUserId <= 0) {
//       // L'utilisateur n'est pas connecté
//       setState(() {
//         _isFavorite = false;
//         _isLoadingFavorite = false;
//       });
//       return;
//     }
//
//     setState(() => _isLoadingFavorite = true);
//
//     try {
//       final favorite = await FavoritesService.getFavoriteForSalon(
//           widget.currentUserId,
//           widget.salonId
//       );
//
//       if (mounted) {
//         setState(() {
//           _isFavorite = favorite != null;
//           _isLoadingFavorite = false;
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() => _isLoadingFavorite = false);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Erreur lors de la vérification des favoris: $e')),
//         );
//       }
//     }
//   }
//
//   // Gérer l'ajout/suppression des favoris
//   Future<void> _toggleFavorite() async {
//     if (widget.currentUserId <= 0) {
//       // L'utilisateur n'est pas connecté
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Vous devez être connecté pour ajouter des favoris')),
//       );
//       return;
//     }
//
//     setState(() => _isLoadingFavorite = true);
//
//     try {
//       // Utiliser toggleFavorite au lieu d'une logique personnalisée
//       final newFavoriteStatus = await FavoritesService.toggleFavorite(
//           widget.currentUserId,
//           widget.salonId
//       );
//
//       if (mounted) {
//         setState(() {
//           _isFavorite = newFavoriteStatus;
//           _isLoadingFavorite = false;
//         });
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(_isFavorite
//                 ? 'Salon ajouté aux favoris'
//                 : 'Salon retiré des favoris'
//             ),
//             duration: const Duration(seconds: 1),
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() => _isLoadingFavorite = false);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Erreur: $e')),
//         );
//       }
//     }
//   }
//
//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF9F9FB),
//       appBar: const CustomAppBar(),
//       bottomNavigationBar: BottomNavBar(
//         currentIndex: 1,
//         onTap: (index) {
//           // facultatif : à gérer si besoin
//         },
//       ),
//       body: SafeArea(
//         child: FutureBuilder<PublicSalonDetails>(
//           future: _salonFuture,
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Center(
//                 child: CircularProgressIndicator(color: Colors.deepPurple),
//               );
//             } else if (snapshot.hasError) {
//               return Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Icon(Icons.error_outline, color: Colors.red, size: 60),
//                     const SizedBox(height: 16),
//                     Text('Erreur: ${snapshot.error}', style: GoogleFonts.poppins(fontSize: 16)),
//                     const SizedBox(height: 20),
//                     ElevatedButton(
//                       onPressed: () {
//                         setState(() {
//                           _salonFuture = PublicSalonDetailsApi.getSalonDetails(widget.salonId);
//                         });
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.deepPurple,
//                         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                       ),
//                       child: const Text('Réessayer'),
//                     ),
//                   ],
//                 ),
//               );
//             } else if (!snapshot.hasData) {
//               return const Center(child: Text('Aucune information disponible'));
//             }
//
//             final salonDetails = snapshot.data!;
//
//             return NestedScrollView(
//               headerSliverBuilder: (context, innerBoxIsScrolled) => [
//                 SliverAppBar(
//                   expandedHeight: 220,
//                   pinned: true,
//                   backgroundColor: Colors.deepPurple,
//                   flexibleSpace: FlexibleSpaceBar(
//                     background: Stack(
//                       fit: StackFit.expand,
//                       children: [
//                         salonDetails.logoSalon != null && salonDetails.logoSalon!.isNotEmpty
//                             ? Image.network(salonDetails.logoSalon!, fit: BoxFit.cover)
//                             : salonDetails.images.isNotEmpty
//                             ? Image.network(salonDetails.images.first.image, fit: BoxFit.cover)
//                             : Container(color: Colors.grey[300]),
//                         Container(
//                           decoration: BoxDecoration(
//                             gradient: LinearGradient(
//                               colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
//                               begin: Alignment.topCenter,
//                               end: Alignment.bottomCenter,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   leading: Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: CircleAvatar(
//                       backgroundColor: Colors.white,
//                       child: IconButton(
//                         icon: const Icon(Icons.arrow_back, color: Colors.black),
//                         onPressed: () => Navigator.pop(context),
//                       ),
//                     ),
//                   ),
//                   actions: [
//                     Padding(
//                       padding: const EdgeInsets.all(8.0),
//                       child: CircleAvatar(
//                         backgroundColor: Colors.white,
//                         child: _isLoadingFavorite
//                             ? const SizedBox(
//                           width: 20,
//                           height: 20,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
//                           ),
//                         )
//                             : IconButton(
//                           icon: Icon(
//                             _isFavorite ? Icons.favorite : Icons.favorite_border,
//                             color: _isFavorite ? Colors.red : Colors.grey,
//                           ),
//                           onPressed: _toggleFavorite,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//               body: Column(
//                 children: [
//                   Expanded(
//                     child: Column(
//                       children: [
//                         Container(
//                           padding: const EdgeInsets.all(20),
//                           width: double.infinity,
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: const BorderRadius.only(
//                               topLeft: Radius.circular(24),
//                               topRight: Radius.circular(24),
//                             ),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(0.05),
//                                 blurRadius: 10,
//                                 offset: const Offset(0, -4),
//                               )
//                             ],
//                           ),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Row(
//                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   Expanded(
//                                     child: Text(
//                                       salonDetails.nomSalon,
//                                       style: GoogleFonts.poppins(
//                                         fontSize: 22,
//                                         fontWeight: FontWeight.w700,
//                                         color: Colors.black87,
//                                       ),
//                                     ),
//                                   ),
//                                   Container(
//                                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//                                     decoration: BoxDecoration(
//                                       color: Colors.orange.shade600,
//                                       borderRadius: BorderRadius.circular(12),
//                                     ),
//                                     child: Row(
//                                       children: [
//                                         const Icon(Icons.star, size: 16, color: Colors.white),
//                                         const SizedBox(width: 4),
//                                         Text(
//                                           salonDetails.noteMoyenne.toString(),
//                                           style: GoogleFonts.poppins(
//                                             fontSize: 13,
//                                             fontWeight: FontWeight.bold,
//                                             color: Colors.white,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 12),
//                               Row(
//                                 children: [
//                                   _infoIcon(Icons.location_on),
//                                   const SizedBox(width: 8),
//                                   Expanded(
//                                     child: Text(
//                                       salonDetails.adresse ?? 'Adresse non disponible',
//                                       style: GoogleFonts.poppins(fontSize: 14),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 10),
//                               Row(
//                                 children: [
//                                   _infoIcon(Icons.access_time),
//                                   const SizedBox(width: 8),
//                                   Expanded(
//                                     child: MouseRegion(
//                                       cursor: SystemMouseCursors.click,
//                                       child: GestureDetector(
//                                         onTap: () => showHorairesModal(context, salonDetails.horaires ?? ''),
//                                         child: Row(
//                                           children: [
//                                             Text(
//                                               'Voir les horaires',
//                                               style: GoogleFonts.poppins(
//                                                 fontSize: 14,
//                                                 color: Colors.deepPurple,
//                                                 fontWeight: FontWeight.w500,
//                                               ),
//                                             ),
//                                             const SizedBox(width: 6),
//                                             const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.deepPurple),
//                                           ],
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
//                         Expanded(
//                           child: DefaultTabController(
//                             length: 4,
//                             child: Column(
//                               children: [
//                                 const SizedBox(height: 12),
//                                 TabBar(
//                                   controller: _tabController,
//                                   indicatorColor: Colors.deepPurple,
//                                   labelColor: Colors.deepPurple,
//                                   unselectedLabelColor: Colors.grey,
//                                   labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
//                                   tabs: const [
//                                     Tab(text: 'Services'),
//                                     Tab(text: 'Équipements'),
//                                     Tab(text: 'Spécialiste'),
//                                     Tab(text: 'Galerie'),
//                                   ],
//                                 ),
//                                 Expanded(
//                                   child: TabBarView(
//                                     controller: _tabController,
//                                     children: [
//                                       _buildServicesTab(salonDetails),
//                                       _buildEquipmentsTab(),
//                                       _buildSpecialisteTab(salonDetails),
//                                       GalleryWidget(
//                                           salonDetails: salonDetails,
//                                           currentUserId: widget.currentUserId
//                                       ),
//                                     ],
//                                   ),
//                                 )
//                               ],
//                             ),
//                           ),
//                         )
//                       ],
//                     ),
//                   )
//                 ],
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
//
//   Widget _infoIcon(IconData icon) {
//     return Container(
//       padding: const EdgeInsets.all(6),
//       decoration: BoxDecoration(
//         color: Colors.deepPurple.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Icon(icon, color: Colors.deepPurple, size: 20),
//     );
//   }
//
//
//   Widget _buildServicesTab(PublicSalonDetails salon) {
//     final services = salon.serviceSalonDetailsList;
//
//     if (services.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.healing_outlined, size: 60, color: Colors.grey[400]),
//             const SizedBox(height: 16),
//             Text(
//               'Aucun service disponible',
//               style: GoogleFonts.poppins(color: Colors.grey[600]),
//             ),
//           ],
//         ),
//       );
//     }
//
//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: services.length,
//       itemBuilder: (context, index) {
//         final service = services[index];
//         return Card(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//           elevation: 2,
//           margin: const EdgeInsets.only(bottom: 16),
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Text(
//                         service.intituleService,
//                         style: GoogleFonts.poppins(
//                             fontWeight: FontWeight.w600, fontSize: 16),
//                       ),
//                     ),
//                     if (service.promotionActive != null)
//                       Container(
//                         padding:
//                         const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                         decoration: BoxDecoration(
//                           color: Colors.red.shade100,
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Text(
//                           '-${service.promotionActive!.discountPercentage}%',
//                           style: GoogleFonts.poppins(
//                             fontSize: 12,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.red.shade800,
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//                 const SizedBox(height: 6),
//                 Text(
//                   service.description,
//                   style: GoogleFonts.poppins(
//                       fontSize: 14, color: Colors.grey[700]),
//                 ),
//                 const SizedBox(height: 10),
//                 ServicePriceWidget(serviceSalonDetails: service),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//
//   Widget _buildEquipmentsTab() {
//     final equipments = [
//       {'icon': Icons.wifi, 'label': 'WIFI'},
//       {'icon': Icons.local_parking, 'label': 'Parking'},
//       {'icon': Icons.tv, 'label': 'TV'},
//       {'icon': Icons.music_note, 'label': 'Musique'},
//       {'icon': Icons.coffee, 'label': 'Café'},
//     ];
//
//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: equipments.length,
//       itemBuilder: (context, index) {
//         final equipment = equipments[index];
//         return Card(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//           elevation: 1,
//           margin: const EdgeInsets.only(bottom: 12),
//           child: ListTile(
//             leading: CircleAvatar(
//               backgroundColor: Colors.deepPurple.withOpacity(0.1),
//               child: Icon(equipment['icon'] as IconData, color: Colors.deepPurple),
//             ),
//             title: Text(equipment['label'] as String,
//                 style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildSpecialisteTab(PublicSalonDetails salon) {
//     final user = salon.coiffeuse.idTblUser;
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         children: [
//           CircleAvatar(
//             radius: 50,
//             backgroundImage: user.photoProfil != null ? NetworkImage(user.photoProfil!) : null,
//             backgroundColor: Colors.grey[200],
//             child: user.photoProfil == null ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
//           ),
//           const SizedBox(height: 16),
//           Text('${user.prenom} ${user.nom}',
//               style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
//           const SizedBox(height: 8),
//           Text(salon.coiffeuse.position ?? 'Coiffeuse professionnelle',
//               style: GoogleFonts.poppins(color: Colors.grey[600])),
//           const SizedBox(height: 20),
//           Card(
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//             child: Column(
//               children: [
//                 ListTile(
//                   leading: const Icon(Icons.phone, color: Colors.deepPurple),
//                   title: Text('Téléphone', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
//                   subtitle: Text(user.numeroTelephone ?? 'Non disponible'),
//                 ),
//                 const Divider(),
//                 ListTile(
//                   leading: const Icon(Icons.business, color: Colors.deepPurple),
//                   title: Text('Dénomination', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
//                   subtitle: Text(salon.coiffeuse.denominationSociale ?? 'Non disponible'),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }