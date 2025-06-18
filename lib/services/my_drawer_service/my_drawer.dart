/// *************************************************************************************************
/// *
/// BANNIÈRE : WIDGET DE MENU LATÉRAL (DRAWER) PERSONNALISÉ                                           *
/// ---------------------------------------------------------                                       *
/// *
/// OBJECTIF :                                                                                      *
/// Ce fichier définit `MyDrawer`, un widget de menu latéral (Drawer) avec état qui fournit la      *
/// navigation principale de l'application. Il est personnalisé en fonction de l'utilisateur        *
/// actuellement connecté (`currentUser`).                                                          *
/// *
/// FONCTIONNALITÉS PRINCIPALES :                                                                   *
/// 1. AFFICHAGE DES INFORMATIONS UTILISATEUR :                                                     *
/// - Récupère et affiche le profil de l'utilisateur (photo, nom, email) dans l'en-tête du menu. *
/// - Gère un état de chargement pendant la récupération des données.                             *
/// *
/// 2. NAVIGATION CONDITIONNELLE :                                                                  *
/// - Affiche un ensemble de liens de navigation communs à tous les utilisateurs (Accueil, Profil). *
/// - Affiche un menu contextuel "MENU COIFFEUSE" avec des options supplémentaires (Services,      *
/// Promotions, Mon salon, etc.) uniquement si l'utilisateur est de type "coiffeuse".          *
/// *
/// 3. ADAPTABILITÉ (RESPONSIVE DESIGN) :                                                           *
/// - Ajuste la taille et la densité des éléments du menu pour s'adapter aux écrans de             *
/// différentes tailles, améliorant l'expérience sur les petits appareils.                      *
/// *
/// 4. GESTION DES ACTIONS :                                                                        *
/// - Gère la navigation vers différentes pages de l'application lors du clic sur les éléments.     *
/// - Effectue des appels API nécessaires (par exemple, pour trouver l'ID d'un salon) avant de    *
/// naviguer.                                                                                   *
/// - Intègre le service de déconnexion (`LogoutService`) pour une fermeture de session propre.     *
/// - Affiche des messages de feedback à l'utilisateur (chargement, erreur) via des `SnackBar` et *
/// des `Dialog`.                                                                                 *
/// *
///*************************************************************************************************
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hairbnb/models/current_user.dart';
import 'package:hairbnb/public_salon_details/show_salon_page.dart';
import 'package:hairbnb/pages/horaires_coiffeuse/disponibilite_coiffeuse_page.dart';
import 'package:hairbnb/pages/salon/salon_services_pages/show_services_list_page.dart';
import 'package:hairbnb/pages/salon/salon_services_pages/promotion/promotions_management_page.dart';
import 'package:hairbnb/services/auth_services/logout_service.dart';
import 'package:hairbnb/services/providers/get_user_type_service.dart';
import 'package:http/http.dart' as http;
import 'package:hairbnb/public_salon_details/favorites_salons_page.dart';
import 'package:hairbnb/pages/salon/salon_services_pages/api/salon_by_coiffeuse_api.dart';

/// Widget `Stateful` représentant le menu latéral de l'application.
class MyDrawer extends StatefulWidget {
  // L'objet contenant les informations de l'utilisateur actuellement connecté.
  final CurrentUser currentUser;

  const MyDrawer({super.key, required this.currentUser});

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

/// Classe d'état pour le widget `MyDrawer`.
class _MyDrawerState extends State<MyDrawer> {
  // Stocke les données supplémentaires du profil de l'utilisateur.
  Map<String, dynamic>? userData;
  // Gère l'état de chargement des données du profil.
  bool isLoading = true;

  // Définition centralisée des couleurs de l'application pour la cohérence.
  final Color primaryViolet = const Color(0xFF7B61FF);
  final Color lightBackground = const Color(0xFFF7F7F9);
  final Color successGreen = Colors.green;
  final Color errorRed = Colors.red;

  @override
  void initState() {
    super.initState();
    // Lance la récupération des données du profil dès l'initialisation du widget.
    fetchUserProfile();
  }

  /// Récupère les informations détaillées du profil utilisateur depuis l'API.
  Future<void> fetchUserProfile() async {
    final baseUrl = 'https://www.hairbnb.site/api/get_user_profile/${widget.currentUser.uuid}/';

    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Met à jour l'état avec les données reçues et désactive l'indicateur de chargement.
        setState(() {
          userData = data['data'];
          isLoading = false;
        });
      } else {
        // En cas d'échec de la requête, désactive simplement l'indicateur de chargement.
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      // En cas d'exception (ex: pas de réseau), désactive également le chargement.
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Fonction utilitaire pour mettre en majuscule la première lettre d'une chaîne.
  String capitalize(String s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1).toLowerCase() : "";

  @override
  Widget build(BuildContext context) {
    // Récupère les dimensions de l'écran pour un design adaptatif.
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    // Détermine si l'écran est considéré comme petit pour ajuster l'interface.
    final isSmallScreen = screenWidth < 360 || screenHeight < 600;

    return Drawer(
      // La largeur du Drawer est ajustée pour les petits écrans.
      width: isSmallScreen ? screenWidth * 0.85 : null,
      // Affiche un indicateur de chargement ou le contenu du menu.
      child: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryViolet))
          : ListView(
        padding: EdgeInsets.zero,
        children: [
          // En-tête du menu affichant les informations de l'utilisateur.
          DrawerHeader(
            decoration: BoxDecoration(color: primaryViolet),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: isSmallScreen ? 30 : 40,
                    backgroundImage: widget.currentUser.photoProfil != null &&
                        widget.currentUser.photoProfil!.isNotEmpty
                        ? NetworkImage('https://www.hairbnb.site${widget.currentUser.photoProfil}')
                        : const AssetImage('assets/default_avatar.png') as ImageProvider,
                  ),
                  SizedBox(height: isSmallScreen ? 6 : 10),
                  Text(
                    "${capitalize(widget.currentUser.prenom)} ${capitalize(widget.currentUser.nom)}",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.currentUser.email,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: isSmallScreen ? 12 : 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),

          // Élément de menu pour la page d'accueil.
          ListTile(
            dense: isSmallScreen,
            contentPadding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12.0 : 16.0, vertical: isSmallScreen ? 0.0 : 4.0),
            leading: Icon(Icons.home, color: primaryViolet, size: isSmallScreen ? 20 : 24),
            title: Text("Accueil", style: TextStyle(fontSize: isSmallScreen ? 14 : 16)),
            onTap: () {
              Navigator.pushNamed(context, "/home");
            },
          ),
          // Élément de menu pour la page de profil.
          ListTile(
            dense: isSmallScreen,
            contentPadding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12.0 : 16.0, vertical: isSmallScreen ? 0.0 : 4.0),
            leading: Icon(Icons.person, color: primaryViolet, size: isSmallScreen ? 20 : 24),
            title: Text("Profil", style: TextStyle(fontSize: isSmallScreen ? 14 : 16)),
            onTap: () {
              Navigator.pushNamed(context, "/profil");
            },
          ),

          // Section conditionnelle : affichée uniquement si l'utilisateur est une coiffeuse.
          if (widget.currentUser.type == 'coiffeuse') ...[
            const Divider(height: 1),
            Padding(
              padding: EdgeInsets.only(left: isSmallScreen ? 12.0 : 16.0, top: isSmallScreen ? 6.0 : 8.0, bottom: isSmallScreen ? 2.0 : 4.0),
              child: Text(
                "MENU COIFFEUSE",
                style: TextStyle(color: primaryViolet, fontSize: isSmallScreen ? 10 : 12, fontWeight: FontWeight.bold),
              ),
            ),
            // Élément pour accéder à la gestion des services.
            ListTile(
              dense: isSmallScreen,
              contentPadding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12.0 : 16.0, vertical: isSmallScreen ? 0.0 : 2.0),
              leading: Icon(Icons.build, color: primaryViolet, size: isSmallScreen ? 20 : 24),
              title: Text("Services", style: TextStyle(fontSize: isSmallScreen ? 14 : 16)),
              onTap: () async {
                // Récupère l'ID de l'utilisateur avant de naviguer.
                final userDetails = await getIdAndTypeFromUuid(userData?['uuid'] ?? widget.currentUser.uuid);
                if (userDetails != null) {
                  final idTblUser = userDetails['idTblUser'];
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ServicesListPage(coiffeuseId: idTblUser.toString())));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Erreur lors de la récupération des services."), backgroundColor: errorRed));
                }
              },
            ),
            // Élément pour accéder à la gestion des promotions.
            ListTile(
              dense: isSmallScreen,
              contentPadding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12.0 : 16.0, vertical: isSmallScreen ? 0.0 : 2.0),
              leading: Icon(Icons.local_offer, color: Colors.orange, size: isSmallScreen ? 20 : 24),
              title: Text("Promotions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: isSmallScreen ? 14 : 16)),
              tileColor: Colors.orange.withOpacity(0.05),
              onTap: () async {
                final userDetails = await getIdAndTypeFromUuid(userData?['uuid'] ?? widget.currentUser.uuid);
                if (userDetails != null) {
                  final idTblUser = userDetails['idTblUser'];
                  Navigator.push(context, MaterialPageRoute(builder: (context) => PromotionsManagementPage(coiffeuseId: idTblUser.toString())));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Erreur lors de la récupération des promotions."), backgroundColor: errorRed));
                }
              },
            ),
            // Élément pour voir la page publique du salon de la coiffeuse.
            ListTile(
              dense: isSmallScreen,
              contentPadding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12.0 : 16.0, vertical: isSmallScreen ? 0.0 : 2.0),
              leading: Icon(Icons.store, color: primaryViolet, size: isSmallScreen ? 20 : 24),
              title: Text("Mon salon", style: TextStyle(fontSize: isSmallScreen ? 14 : 16)),
              onTap: () async {
                final userDetails = await getIdAndTypeFromUuid(userData?['uuid'] ?? widget.currentUser.uuid);
                if (userDetails != null) {
                  final coiffeuseId = userDetails['idTblUser'];

                  // Affiche un indicateur de chargement pendant l'appel API.
                  showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));

                  try {
                    final salon = await SalonByCoiffeuseApi.getSalonByCoiffeuseId(coiffeuseId);
                    final currentUserId = widget.currentUser.idTblUser;

                    Navigator.pop(context); // Ferme l'indicateur de chargement.

                    if (salon != null) {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => SalonDetailsPage(salonId: salon.idSalon, currentUserId: currentUserId)));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Vous n'avez pas encore de salon."), backgroundColor: Colors.orange));
                    }
                  } catch (e) {
                    Navigator.pop(context); // Ferme l'indicateur en cas d'erreur.
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur lors du chargement du salon: $e"), backgroundColor: errorRed));
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Impossible de charger les données du salon."), backgroundColor: errorRed));
                }
              },
            ),
            // Élément pour accéder à la page des favoris.
            ListTile(
              dense: isSmallScreen,
              contentPadding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12.0 : 16.0, vertical: isSmallScreen ? 0.0 : 2.0),
              leading: Icon(Icons.favorite, color: Colors.pink, size: isSmallScreen ? 20 : 24),
              title: Text("Mes favoris", style: TextStyle(fontSize: isSmallScreen ? 14 : 16)),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => FavoriteSalonsPage(currentUserId: widget.currentUser.idTblUser)));
              },
            ),
            // Élément pour accéder à la gestion des disponibilités.
            ListTile(
              dense: isSmallScreen,
              contentPadding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12.0 : 16.0, vertical: isSmallScreen ? 0.0 : 2.0),
              leading: Icon(Icons.calendar_today, color: primaryViolet, size: isSmallScreen ? 20 : 24),
              title: Text("Mes disponibilités", style: TextStyle(fontSize: isSmallScreen ? 14 : 16)),
              onTap: () async {
                final userDetails = await getIdAndTypeFromUuid(widget.currentUser.uuid);
                if (userDetails != null) {
                  final coiffeuseId = userDetails['idTblUser'];
                  Navigator.push(context, MaterialPageRoute(builder: (context) => HoraireIndispoPage(coiffeuseId: coiffeuseId)));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Impossible de charger vos horaires."), backgroundColor: errorRed));
                }
              },
            ),
          ],

          const Divider(),
          // Élément de menu pour la déconnexion.
          ListTile(
            dense: isSmallScreen,
            contentPadding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12.0 : 16.0, vertical: isSmallScreen ? 0.0 : 2.0),
            leading: Icon(Icons.logout, color: Colors.red, size: isSmallScreen ? 20 : 24),
            title: Text("Déconnexion", style: TextStyle(color: Colors.red, fontSize: isSmallScreen ? 14 : 16)),
            onTap: () async {
              // Appelle le service de déconnexion qui gère la confirmation et la logique.
              await LogoutService.confirmLogout(context);
            },
          ),
        ],
      ),
    );
  }
}









// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:hairbnb/models/current_user.dart';
// import 'package:hairbnb/public_salon_details/show_salon_page.dart';
// import 'package:hairbnb/pages/horaires_coiffeuse/disponibilite_coiffeuse_page.dart';
// import 'package:hairbnb/pages/salon/salon_services_pages/show_services_list_page.dart';
// import 'package:hairbnb/pages/salon/salon_services_pages/promotion/promotions_management_page.dart';
// import 'package:hairbnb/services/auth_services/logout_service.dart';
// import 'package:hairbnb/services/providers/get_user_type_service.dart';
// import 'package:http/http.dart' as http;
// import 'package:hairbnb/public_salon_details/favorites_salons_page.dart';
// import 'package:hairbnb/pages/salon/salon_services_pages/api/salon_by_coiffeuse_api.dart';
//
// class MyDrawer extends StatefulWidget {
//   final CurrentUser currentUser;
//
//   const MyDrawer({super.key, required this.currentUser});
//
//   @override
//   State<MyDrawer> createState() => _MyDrawerState();
// }
//
// class _MyDrawerState extends State<MyDrawer> {
//   Map<String, dynamic>? userData;
//   bool isLoading = true;
//
//   // Couleurs de l'application
//   final Color primaryViolet = const Color(0xFF7B61FF);
//   final Color lightBackground = const Color(0xFFF7F7F9);
//   final Color successGreen = Colors.green;
//   final Color errorRed = Colors.red;
//
//   @override
//   void initState() {
//     super.initState();
//     fetchUserProfile();
//   }
//
//   Future<void> fetchUserProfile() async {
//     final baseUrl = 'https://www.hairbnb.site/api/get_user_profile/${widget.currentUser.uuid}/';
//
//     try {
//       final response = await http.get(Uri.parse(baseUrl));
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         setState(() {
//           userData = data['data'];
//           isLoading = false;
//         });
//       } else {
//         setState(() {
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   String capitalize(String s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1).toLowerCase() : "";
//
//   @override
//   Widget build(BuildContext context) {
//     // Obtenir les dimensions de l'écran
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
//     final isSmallScreen = screenWidth < 360 || screenHeight < 600;
//
//     return Drawer(
//       width: isSmallScreen ? screenWidth * 0.85 : null, // Adapter la largeur pour les petits écrans
//       child: isLoading
//           ? Center(child: CircularProgressIndicator(color: primaryViolet))
//           : ListView(
//         padding: EdgeInsets.zero,
//         children: [
//           DrawerHeader(
//             decoration: BoxDecoration(color: primaryViolet),
//             child: SingleChildScrollView(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   CircleAvatar(
//                     radius: isSmallScreen ? 30 : 40,
//                     backgroundImage: widget.currentUser.photoProfil != null &&
//                         widget.currentUser.photoProfil!.isNotEmpty
//                         ? NetworkImage('https://www.hairbnb.site${widget.currentUser.photoProfil}')
//                         : const AssetImage('assets/default_avatar.png') as ImageProvider,
//                   ),
//                   SizedBox(height: isSmallScreen ? 6 : 10),
//                   Text(
//                     "${capitalize(widget.currentUser.prenom)} ${capitalize(widget.currentUser.nom)}",
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: isSmallScreen ? 16 : 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   Text(
//                     widget.currentUser.email,
//                     style: TextStyle(
//                       color: Colors.white70,
//                       fontSize: isSmallScreen ? 12 : 14,
//                     ),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//
//           ListTile(
//             dense: isSmallScreen, // Plus compact sur petit écran
//             contentPadding: EdgeInsets.symmetric(
//               horizontal: isSmallScreen ? 12.0 : 16.0,
//               vertical: isSmallScreen ? 0.0 : 4.0,
//             ),
//             leading: Icon(Icons.home, color: primaryViolet, size: isSmallScreen ? 20 : 24),
//             title: Text(
//               "Accueil",
//               style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
//             ),
//             onTap: () {
//               Navigator.pushNamed(context, "/home");
//             },
//           ),
//           ListTile(
//             dense: isSmallScreen, // Plus compact sur petit écran
//             contentPadding: EdgeInsets.symmetric(
//               horizontal: isSmallScreen ? 12.0 : 16.0,
//               vertical: isSmallScreen ? 0.0 : 4.0,
//             ),
//             leading: Icon(Icons.person, color: primaryViolet, size: isSmallScreen ? 20 : 24),
//             title: Text(
//               "Profil",
//               style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
//             ),
//             onTap: () {
//               Navigator.pushNamed(context, "/profil");
//             },
//           ),
//
//           // Menu spécifique pour les coiffeuses
//           if (widget.currentUser.type == 'coiffeuse') ...[
//             const Divider(height: 1),
//             Padding(
//               padding: EdgeInsets.only(
//                 left: isSmallScreen ? 12.0 : 16.0,
//                 top: isSmallScreen ? 6.0 : 8.0,
//                 bottom: isSmallScreen ? 2.0 : 4.0,
//               ),
//               child: Text(
//                 "MENU COIFFEUSE",
//                 style: TextStyle(
//                   color: primaryViolet,
//                   fontSize: isSmallScreen ? 10 : 12,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             ListTile(
//               dense: isSmallScreen,
//               contentPadding: EdgeInsets.symmetric(
//                 horizontal: isSmallScreen ? 12.0 : 16.0,
//                 vertical: isSmallScreen ? 0.0 : 2.0,
//               ),
//               leading: Icon(Icons.build, color: primaryViolet, size: isSmallScreen ? 20 : 24),
//               title: Text(
//                 "Services",
//                 style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
//               ),
//               onTap: () async {
//                 final userDetails = await getIdAndTypeFromUuid(userData?['uuid'] ?? widget.currentUser.uuid);
//                 if (userDetails != null) {
//                   final idTblUser = userDetails['idTblUser'];
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => ServicesListPage(coiffeuseId: idTblUser.toString()),
//                     ),
//                   );
//                 } else {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: const Text("Erreur lors de la récupération des services."),
//                       backgroundColor: errorRed,
//                     ),
//                   );
//                 }
//               },
//             ),
//             ListTile(
//               dense: isSmallScreen,
//               contentPadding: EdgeInsets.symmetric(
//                 horizontal: isSmallScreen ? 12.0 : 16.0,
//                 vertical: isSmallScreen ? 0.0 : 2.0,
//               ),
//               leading: Icon(Icons.local_offer, color: Colors.orange, size: isSmallScreen ? 20 : 24),
//               title: Text(
//                 "Promotions",
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: isSmallScreen ? 14 : 16,
//                 ),
//               ),
//               tileColor: Colors.orange.withOpacity(0.05),
//               onTap: () async {
//                 final userDetails = await getIdAndTypeFromUuid(userData?['uuid'] ?? widget.currentUser.uuid);
//                 if (userDetails != null) {
//                   final idTblUser = userDetails['idTblUser'];
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => PromotionsManagementPage(coiffeuseId: idTblUser.toString()),
//                     ),
//                   );
//                 } else {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: const Text("Erreur lors de la récupération des promotions."),
//                       backgroundColor: errorRed,
//                     ),
//                   );
//                 }
//               },
//             ),
//             ListTile(
//               dense: isSmallScreen,
//               contentPadding: EdgeInsets.symmetric(
//                 horizontal: isSmallScreen ? 12.0 : 16.0,
//                 vertical: isSmallScreen ? 0.0 : 2.0,
//               ),
//               leading: Icon(Icons.store, color: primaryViolet, size: isSmallScreen ? 20 : 24),
//               title: Text(
//                 "Mon salon",
//                 style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
//               ),
//               onTap: () async {
//                 final userDetails = await getIdAndTypeFromUuid(userData?['uuid'] ?? widget.currentUser.uuid);
//                 if (userDetails != null) {
//                   final coiffeuseId = userDetails['idTblUser'];
//
//                   // Afficher un indicateur de chargement
//                   showDialog(
//                     context: context,
//                     barrierDismissible: false,
//                     builder: (context) => const Center(
//                       child: CircularProgressIndicator(),
//                     ),
//                   );
//
//                   try {
//                     // Appel au service pour récupérer le salon
//                     final salon = await SalonByCoiffeuseApi.getSalonByCoiffeuseId(coiffeuseId);
//                     final currentUserId = widget.currentUser.idTblUser;
//
//                     // Fermer l'indicateur de chargement
//                     Navigator.pop(context);
//
//                     if (salon != null) {
//                       // Naviguer vers la page de détails du salon
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => SalonDetailsPage(
//                             salonId: salon.idSalon,
//                             currentUserId: currentUserId,
//                           ),
//                         ),
//                       );
//                     } else {
//                       // Si aucun salon n'est trouvé
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(
//                           content: const Text("Vous n'avez pas encore de salon."),
//                           backgroundColor: Colors.orange,
//                         ),
//                       );
//                     }
//                   } catch (e) {
//                     // Fermer l'indicateur de chargement en cas d'erreur
//                     Navigator.pop(context);
//
//                     // Afficher un message d'erreur
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(
//                         content: Text("Erreur lors du chargement du salon: $e"),
//                         backgroundColor: errorRed,
//                       ),
//                     );
//                   }
//                 } else {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: const Text("Impossible de charger les données du salon."),
//                       backgroundColor: errorRed,
//                     ),
//                   );
//                 }
//               },
//             ),
//             // Nouveau bouton "Mes favoris"
//             ListTile(
//               dense: isSmallScreen,
//               contentPadding: EdgeInsets.symmetric(
//                 horizontal: isSmallScreen ? 12.0 : 16.0,
//                 vertical: isSmallScreen ? 0.0 : 2.0,
//               ),
//               leading: Icon(Icons.favorite, color: Colors.pink, size: isSmallScreen ? 20 : 24),
//               title: Text(
//                 "Mes favoris",
//                 style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
//               ),
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => FavoriteSalonsPage(
//                       currentUserId: widget.currentUser.idTblUser,
//                     ),
//                   ),
//                 );
//               },
//             ),
//             ListTile(
//               dense: isSmallScreen,
//               contentPadding: EdgeInsets.symmetric(
//                 horizontal: isSmallScreen ? 12.0 : 16.0,
//                 vertical: isSmallScreen ? 0.0 : 2.0,
//               ),
//               leading: Icon(Icons.calendar_today, color: primaryViolet, size: isSmallScreen ? 20 : 24),
//               title: Text(
//                 "Mes disponibilités",
//                 style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
//               ),
//               onTap: () async {
//                 final userDetails = await getIdAndTypeFromUuid(widget.currentUser.uuid);
//                 if (userDetails != null) {
//                   final coiffeuseId = userDetails['idTblUser'];
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => HoraireIndispoPage(coiffeuseId: coiffeuseId),
//                     ),
//                   );
//                 } else {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: const Text("Impossible de charger vos horaires."),
//                       backgroundColor: errorRed,
//                     ),
//                   );
//                 }
//               },
//             ),
//           ],
//
//           const Divider(),
//           ListTile(
//             dense: isSmallScreen,
//             contentPadding: EdgeInsets.symmetric(
//               horizontal: isSmallScreen ? 12.0 : 16.0,
//               vertical: isSmallScreen ? 0.0 : 2.0,
//             ),
//             leading: Icon(Icons.logout, color: Colors.red, size: isSmallScreen ? 20 : 24),
//             title: Text(
//               "Déconnexion",
//               style: TextStyle(
//                 color: Colors.red,
//                 fontSize: isSmallScreen ? 14 : 16,
//               ),
//             ),
//             onTap: () async {
//               await LogoutService.confirmLogout(context);
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }