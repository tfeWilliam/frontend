/***************************************************************************************************
 * *
 * BANNIÈRE : EXPLICATION DU WIDGET FAVORITESALONSPAGE                                             *
 * ---------------------------------------------------                                             *
 * *
 * OBJECTIF :                                                                                      *
 * Ce fichier définit le widget `FavoriteSalonsPage`, qui est une page avec état (StatefulWidget)  *
 * conçue pour afficher la liste des salons de coiffure qu'un utilisateur a ajoutés à ses          *
 * favoris.                                                                                        *
 * *
 * FONCTIONNALITÉS PRINCIPALES :                                                                   *
 * 1. RÉCUPÉRATION DE DONNÉES : Au démarrage, la page interroge une API pour obtenir la liste      *
 * des salons favoris de l'utilisateur actuellement connecté.                                   *
 * 2. AFFICHAGE DYNAMIQUE : Utilise un `FutureBuilder` pour gérer les différents états de la       *
 * récupération des données (chargement, erreur, succès, aucune donnée).                        *
 * 3. LISTE DE FAVORIS : Affiche les salons sous forme de cartes stylisées dans une liste          *
 * verticale. Chaque carte contient l'image, le nom et le slogan du salon.                      *
 * 4. NAVIGATION : Permet à l'utilisateur de cliquer sur une carte pour naviguer vers la page     *
 * de détails du salon correspondant (`SalonDetailsPage`).                                      *
 * 5. SUPPRESSION D'UN FAVORI : Chaque carte dispose d'un bouton pour supprimer le salon des       *
 * favoris. Une boîte de dialogue de confirmation s'affiche avant toute suppression.            *
 * 6. INTÉGRATION UI : Utilise un `HairbnbScaffold` personnalisé et une `BottomNavBar` pour une     *
 * intégration cohérente dans l'application.                                                    *
 * *
 ***************************************************************************************************/

// Importation des bibliothèques et des fichiers nécessaires au fonctionnement de la page.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/show_favorites.dart';
import 'show_salon_page.dart';
import '../services/my_drawer_service/hairbnb_scaffold.dart';
import '../widgets/bottom_nav_bar.dart';
import 'api/favorites_api.dart';

// Déclaration du widget `FavoriteSalonsPage`, qui est un widget avec état (Stateful).
class FavoriteSalonsPage extends StatefulWidget {
  // L'identifiant de l'utilisateur actuellement connecté, nécessaire pour récupérer ses favoris.
  final int currentUserId;

  // Constructeur du widget, qui requiert l'ID de l'utilisateur.
  const FavoriteSalonsPage({super.key, required this.currentUserId});

  @override
  State<FavoriteSalonsPage> createState() => _FavoriteSalonsPageState();
}

// Classe d'état associée au widget `FavoriteSalonsPage`.
class _FavoriteSalonsPageState extends State<FavoriteSalonsPage> {
  // Déclare un Future qui contiendra la liste des favoris une fois la requête API terminée.
  late Future<List<ShowFavorite>> _favoritesFuture;
  // URL de base du site, utilisée pour construire les URLs complètes des images.
  final url = 'https://www.hairbnb.site';
  // Index de l'onglet actif dans la barre de navigation inférieure. Ici, '4' correspond au profil.
  final int _currentIndex = 4;

  @override
  void initState() {
    super.initState();
    // Lance la récupération des favoris dès l'initialisation du widget.
    _favoritesFuture = fetchFavorites(widget.currentUserId);
  }

  // Fonction asynchrone pour récupérer les favoris de l'utilisateur depuis l'API.
  Future<List<ShowFavorite>> fetchFavorites(int userId) async {
    // Construit l'URL complète de l'API avec l'ID de l'utilisateur.
    final url = Uri.parse('https://hairbnb.site/api/get_user_favorites/?user=$userId');
    // Effectue une requête HTTP GET pour obtenir les données.
    final response = await http.get(url);

    // Vérifie si la requête a réussi (code de statut 200).
    if (response.statusCode == 200) {
      // Décode le corps de la réponse JSON en une liste dynamique.
      final List<dynamic> data = jsonDecode(response.body);
      // Transforme chaque élément JSON de la liste en un objet `ShowFavorite` et retourne la liste.
      return data.map((json) => ShowFavorite.fromJson(json)).toList();
    } else {
      // Si la requête échoue, lève une exception pour le signaler au FutureBuilder.
      throw Exception("Impossible de charger les salons favoris");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Utilise un Scaffold personnalisé pour maintenir une structure de page cohérente dans l'application.
    return HairbnbScaffold(
      // Le corps principal de la page.
      body: Container(
        color: Colors.grey[100], // Applique une couleur de fond gris clair.
        // `FutureBuilder` est utilisé pour construire l'interface en fonction de l'état du Future `_favoritesFuture`.
        child: FutureBuilder<List<ShowFavorite>>(
          future: _favoritesFuture,
          builder: (context, snapshot) {
            // Cas 1 : Les données sont en cours de chargement.
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.purple));
            }
            // Cas 2 : Une erreur s'est produite lors de la récupération des données.
            else if (snapshot.hasError) {
              return Center(child: Text('Erreur : ${snapshot.error}'));
            }
            // Cas 3 : Les données ont été récupérées, mais la liste est vide ou nulle.
            else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Aucun salon favori trouvé.'));
            }
            // Cas 4 : Les données ont été récupérées avec succès.
            else {
              final favorites = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête de la page avec le titre "Favoris".
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: const Text(
                      'Favoris',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                  ),
                  // La liste des favoris occupe l'espace restant.
                  Expanded(
                    // `ListView.builder` construit les éléments de la liste à la volée, ce qui est performant.
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: favorites.length,
                      itemBuilder: (context, index) {
                        final salon = favorites[index].salon;
                        // Widget représentant une carte de salon favori.
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          // `InkWell` rend la carte cliquable.
                          child: InkWell(
                            onTap: () {
                              // Navigue vers la page de détails du salon lors du clic.
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SalonDetailsPage(
                                    salonId: salon.idTblSalon,
                                    currentUserId: widget.currentUserId,
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Column(
                              children: [
                                // `ClipRRect` est utilisé pour arrondir les coins supérieurs de l'image.
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                  child: Image.network(
                                    url + salon.logoSalon,
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    // `errorBuilder` affiche un widget de remplacement si l'image ne peut pas être chargée.
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 120,
                                        color: Colors.grey[300],
                                        child: const Center(
                                          child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                // Section contenant les informations textuelles du salon.
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundImage: NetworkImage(url + salon.logoSalon),
                                        radius: 25,
                                      ),
                                      const SizedBox(width: 16),
                                      // `Expanded` permet à la colonne de texte de prendre toute la largeur disponible.
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              salon.nomSalon,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              salon.slogan,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Bouton pour supprimer le favori.
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () async {
                                          // Affiche une boîte de dialogue pour confirmer la suppression.
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Supprimer ce favori ?'),
                                              content: const Text('Cette action est irréversible.'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, false),
                                                  child: const Text('Annuler'),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, true),
                                                  child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                                                ),
                                              ],
                                            ),
                                          );

                                          // Si l'utilisateur a confirmé la suppression.
                                          if (confirm == true) {
                                            try {
                                              // Appelle l'API pour supprimer le favori.
                                              final success = await FavoritesApi.removeFavorite(favorites[index].idTblFavorite);
                                              if (success) {
                                                // Met à jour l'interface en supprimant l'élément de la liste locale.
                                                setState(() {
                                                  favorites.removeAt(index);
                                                });
                                                if (!mounted) return;
                                                // Affiche un message de succès.
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Favori supprimé avec succès'),
                                                    backgroundColor: Colors.green,
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              if (!mounted) return;
                                              // Affiche un message en cas d'erreur lors de la suppression.
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Erreur : $e'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
      // Ajout de la barre de navigation en bas de l'écran.
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          // La logique de navigation pour le BottomNavBar peut être gérée ici.
        },
      ),
    );
  }
}







// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import '../models/show_favorites.dart';
// import 'show_salon_page.dart';
// import '../services/my_drawer_service/hairbnb_scaffold.dart';
// import '../widgets/bottom_nav_bar.dart';
// import 'api/favorites_api.dart';
//
// class FavoriteSalonsPage extends StatefulWidget {
//   final int currentUserId;
//
//   const FavoriteSalonsPage({super.key, required this.currentUserId});
//
//   @override
//   State<FavoriteSalonsPage> createState() => _FavoriteSalonsPageState();
// }
//
// class _FavoriteSalonsPageState extends State<FavoriteSalonsPage> {
//   late Future<List<ShowFavorite>> _favoritesFuture;
//   final url = 'https://www.hairbnb.site';
//   final int _currentIndex = 4; // Index pour le profil dans la BottomNavBar
//
//   @override
//   void initState() {
//     super.initState();
//     _favoritesFuture = fetchFavorites(widget.currentUserId);
//   }
//
//   Future<List<ShowFavorite>> fetchFavorites(int userId) async {
//     final url = Uri.parse('https://hairbnb.site/api/get_user_favorites/?user=$userId');
//     final response = await http.get(url);
//
//     if (response.statusCode == 200) {
//       final List<dynamic> data = jsonDecode(response.body);
//       return data.map((json) => ShowFavorite.fromJson(json)).toList();
//     } else {
//       throw Exception("Impossible de charger les salons favoris");
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // Utilisation du HairbnbScaffold à la place du Scaffold standard
//     return HairbnbScaffold(
//       body: Container(
//         color: Colors.grey[100], // Fond gris clair comme sur l'image
//         child: FutureBuilder<List<ShowFavorite>>(
//           future: _favoritesFuture,
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Center(child: CircularProgressIndicator(color: Colors.purple));
//             } else if (snapshot.hasError) {
//               return Center(child: Text('Erreur : ${snapshot.error}'));
//             } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//               return const Center(child: Text('Aucun salon favori trouvé.'));
//             } else {
//               final favorites = snapshot.data!;
//               return Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // En-tête avec titre stylisé
//                   Container(
//                     padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
//                     child: const Text(
//                       'Favoris',
//                       style: TextStyle(
//                         fontSize: 28,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.purple,
//                       ),
//                     ),
//                   ),
//                   Expanded(
//                     child: ListView.builder(
//                       padding: const EdgeInsets.symmetric(horizontal: 16),
//                       itemCount: favorites.length,
//                       itemBuilder: (context, index) {
//                         final salon = favorites[index].salon;
//                         return Container(
//                           margin: const EdgeInsets.only(bottom: 16),
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(16),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.grey.withOpacity(0.2),
//                                 spreadRadius: 1,
//                                 blurRadius: 6,
//                                 offset: const Offset(0, 3),
//                               ),
//                             ],
//                           ),
//                           child: InkWell(
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => SalonDetailsPage(
//                                     salonId: salon.idTblSalon,
//                                     currentUserId: widget.currentUserId,
//                                   ),
//                                 ),
//                               );
//                             },
//                             borderRadius: BorderRadius.circular(16),
//                             child: Column(
//                               children: [
//                                 ClipRRect(
//                                   borderRadius: const BorderRadius.only(
//                                     topLeft: Radius.circular(16),
//                                     topRight: Radius.circular(16),
//                                   ),
//                                   child: Image.network(
//                                     url + salon.logoSalon,
//                                     height: 120,
//                                     width: double.infinity,
//                                     fit: BoxFit.cover,
//                                     errorBuilder: (context, error, stackTrace) {
//                                       return Container(
//                                         height: 120,
//                                         color: Colors.grey[300],
//                                         child: const Center(
//                                           child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
//                                         ),
//                                       );
//                                     },
//                                   ),
//                                 ),
//                                 Padding(
//                                   padding: const EdgeInsets.all(16),
//                                   child: Row(
//                                     children: [
//                                       CircleAvatar(
//                                         backgroundImage: NetworkImage(url + salon.logoSalon),
//                                         radius: 25,
//                                       ),
//                                       const SizedBox(width: 16),
//                                       Expanded(
//                                         child: Column(
//                                           crossAxisAlignment: CrossAxisAlignment.start,
//                                           children: [
//                                             Text(
//                                               salon.nomSalon,
//                                               style: const TextStyle(
//                                                 fontSize: 16,
//                                                 fontWeight: FontWeight.bold,
//                                               ),
//                                             ),
//                                             const SizedBox(height: 4),
//                                             Text(
//                                               salon.slogan,
//                                               style: TextStyle(
//                                                 fontSize: 14,
//                                                 color: Colors.grey[600],
//                                               ),
//                                               maxLines: 2,
//                                               overflow: TextOverflow.ellipsis,
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                       IconButton(
//                                         icon: const Icon(Icons.delete, color: Colors.red),
//                                         onPressed: () async {
//                                           final confirm = await showDialog<bool>(
//                                             context: context,
//                                             builder: (context) => AlertDialog(
//                                               title: const Text('Supprimer ce favori ?'),
//                                               content: const Text('Cette action est irréversible.'),
//                                               actions: [
//                                                 TextButton(
//                                                   onPressed: () => Navigator.pop(context, false),
//                                                   child: const Text('Annuler'),
//                                                 ),
//                                                 TextButton(
//                                                   onPressed: () => Navigator.pop(context, true),
//                                                   child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
//                                                 ),
//                                               ],
//                                             ),
//                                           );
//
//                                           if (confirm == true) {
//                                             try {
//                                               final success = await FavoritesApi.removeFavorite(favorites[index].idTblFavorite);
//                                               if (success) {
//                                                 setState(() {
//                                                   favorites.removeAt(index);
//                                                 });
//                                                 if (!mounted) return;
//                                                 ScaffoldMessenger.of(context).showSnackBar(
//                                                   const SnackBar(
//                                                     content: Text('Favori supprimé avec succès'),
//                                                     backgroundColor: Colors.green,
//                                                   ),
//                                                 );
//                                               }
//                                             } catch (e) {
//                                               if (!mounted) return;
//                                               ScaffoldMessenger.of(context).showSnackBar(
//                                                 SnackBar(
//                                                   content: Text('Erreur : $e'),
//                                                   backgroundColor: Colors.red,
//                                                 ),
//                                               );
//                                             }
//                                           }
//                                         },
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                 ],
//               );
//             }
//           },
//         ),
//       ),
//       bottomNavigationBar: BottomNavBar(
//         currentIndex: _currentIndex,
//         onTap: (index) {
//           // Gérer la navigation si nécessaire
//         },
//       ),
//     );
//   }
// }
