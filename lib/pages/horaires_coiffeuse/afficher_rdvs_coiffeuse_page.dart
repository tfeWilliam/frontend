/// **************************************************************************************
///
/// PAGE UI : GESTION DES RENDEZ-VOUS (POUR LA COIFFEUSE)
///
/// OBJECTIF :
/// Cet écran permet à une coiffeuse de consulter la liste de ses rendez-vous,
/// organisés en deux catégories : "Actifs" et "Archivés".
///
/// ARCHITECTURE ET FONCTIONNALITÉS CLÉS :
/// - Utilise un `StatefulWidget` avec un `TabController` pour la navigation entre
/// les onglets "Actifs" et "Archivés".
/// - Les données sont chargées de manière asynchrone au démarrage via la méthode
/// `_loadData`, qui fait appel au `RdvService`.
/// - Gère un état de chargement (`isLoading`) pour afficher un indicateur de
/// progression pendant la récupération des données.
/// - Chaque rendez-vous est affiché dans une carte (`Card`) stylisée, incluant les
/// informations du client, les détails du RDV, et un compte à rebours visuel
/// (`CountdownBoxTimer`).
///
///***************************************************************************************
library;
import 'package:flutter/material.dart';
import 'package:hairbnb/pages/horaires_coiffeuse/services_horaires_coiffeuse/countdown_box_timer.dart';
import 'package:intl/intl.dart';
import '../../models/reservation_light.dart';
import '../../pages/horaires_coiffeuse/services_horaires_coiffeuse/rdv_service.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/custom_app_bar.dart';

/// Un écran qui affiche les rendez-vous actifs et archivés pour une coiffeuse donnée.
class RendezVousPage extends StatefulWidget {
  /// L'identifiant de la coiffeuse dont les rendez-vous doivent être affichés.
  final int coiffeuseId;

  const RendezVousPage({super.key, required this.coiffeuseId});

  @override
  State<RendezVousPage> createState() => _RendezVousPageState();
}

class _RendezVousPageState extends State<RendezVousPage> with TickerProviderStateMixin {
  /// Contrôleur pour la barre d'onglets (TabBar).
  late TabController _tabController;
  /// Gère l'affichage de l'indicateur de chargement.
  bool isLoading = true;
  /// Index de l'onglet actuellement sélectionné dans la barre de navigation inférieure.
  int currentIndex = 2;

  /// Liste des rendez-vous actifs.
  List<ReservationLight> actifs = [];
  /// Liste des rendez-vous archivés.
  List<ReservationLight> archives = [];

  @override
  void initState() {
    super.initState();
    // Initialise le TabController avec 2 onglets.
    _tabController = TabController(length: 2, vsync: this);
    // Déclenche le chargement initial des données.
    _loadData();
  }

  /// Charge les données des rendez-vous (actifs et archivés) depuis le service.
  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      // Appelle le service pour récupérer les deux listes en parallèle.
      actifs = await RdvService().fetchRendezVous(
        coiffeuseId: widget.coiffeuseId,
        archived: false,
      );
      archives = await RdvService().fetchRendezVous(
        coiffeuseId: widget.coiffeuseId,
        archived: true,
      );
    } catch (e) {
      // Gère les erreurs potentielles lors de l'appel au service.
    }
    // Met à jour l'état pour cacher l'indicateur de chargement et afficher les données.
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: Column(
        children: [
          // Barre d'onglets pour basculer entre les listes "Actifs" et "Archivés".
          Container(
            color: Colors.orange.shade50,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.orange,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.orange,
              tabs: const [
                Tab(text: "🟢 Actifs"),
                Tab(text: "📂 Archivés"),
              ],
            ),
          ),
          // Affiche le contenu de l'onglet sélectionné.
          Expanded(
            child: isLoading
            // Affiche un indicateur de chargement pendant la récupération des données.
                ? const Center(child: CircularProgressIndicator())
            // Une fois chargé, affiche la vue des onglets.
                : TabBarView(
              controller: _tabController,
              children: [
                _buildRdvList(actifs),
                _buildRdvList(archives),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
      ),
    );
  }

  /// Construit la liste visuelle pour un ensemble de rendez-vous donné.
  Widget _buildRdvList(List<ReservationLight> rdvs) {
    // Affiche un message si la liste est vide.
    if (rdvs.isEmpty) {
      return const Center(child: Text("Aucun rendez-vous."));
    }

    // Construit la liste en utilisant ListView.builder pour des performances optimales.
    return ListView.builder(
      itemCount: rdvs.length,
      itemBuilder: (context, index) {
        // Inverse l'ordre pour afficher les rendez-vous les plus récents en premier.
        final rdv = rdvs[rdvs.length - 1 - index];
        // Formatte les dates et heures pour un affichage lisible.
        final dateFormatted = DateFormat("dd MMM yyyy", "fr_FR").format(rdv.dateHeure);
        final heureDebut = DateFormat("HH:mm").format(rdv.dateHeure);
        final heureFin = DateFormat("HH:mm").format(
          rdv.dateHeure.add(Duration(minutes: rdv.dureeTotale)),
        );

        // Chaque rendez-vous est affiché dans une Card stylisée.
        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: CircleAvatar(
              // Affiche la photo de profil du client ou une image par défaut.
              backgroundImage: rdv.photoProfil != null
                  ? NetworkImage("https://www.hairbnb.site${rdv.photoProfil}")
                  : const AssetImage("assets/images/avatar_placeholder.png") as ImageProvider,
              radius: 26,
            ),
            title: Text(
              "${rdv.clientPrenom} ${rdv.clientNom}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  "$dateFormatted • 🕒 $heureDebut - $heureFin",
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  "💶 ${rdv.totalPrix.toStringAsFixed(2)} € • ⏱ ${rdv.dureeTotale} min",
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 6),
                // Affiche un badge de statut coloré.
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: rdv.statut == "confirmé"
                        ? Colors.green.withOpacity(0.2)
                        : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    rdv.statut.toUpperCase(),
                    style: TextStyle(
                      color: rdv.statut == "confirmé" ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Boutons d'action pour modifier ou archiver.
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      tooltip: "Modifier le rendez-vous",
                      onPressed: () {
                        // Logique de modification à implémenter.
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.archive_outlined, color: Colors.grey),
                      tooltip: "Archiver ce rendez-vous",
                      onPressed: () {
                        // Logique d'archivage à implémenter.
                      },
                    ),
                  ],
                )
              ],
            ),
            // Affiche le compte à rebours jusqu'à la date du rendez-vous.
            trailing: CountdownBoxTimer(targetTime: rdv.dateHeure),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}







// import 'package:flutter/material.dart';
// import 'package:hairbnb/pages/horaires_coiffeuse/services_horaires_coiffeuse/countdown_box_timer.dart';
// import 'package:intl/intl.dart';
// import '../../models/reservation_light.dart';
// import '../../pages/horaires_coiffeuse/services_horaires_coiffeuse/rdv_service.dart';
// import '../../widgets/bottom_nav_bar.dart';
// import '../../widgets/custom_app_bar.dart';
//
// class RendezVousPage extends StatefulWidget {
//   final int coiffeuseId;
//
//   const RendezVousPage({super.key, required this.coiffeuseId});
//
//   @override
//   State<RendezVousPage> createState() => _RendezVousPageState();
// }
//
// class _RendezVousPageState extends State<RendezVousPage> with TickerProviderStateMixin {
//   late TabController _tabController;
//   bool isLoading = true;
//   int currentIndex = 2;
//
//   List<ReservationLight> actifs = [];
//   List<ReservationLight> archives = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//     _loadData();
//   }
//
//   Future<void> _loadData() async {
//     setState(() => isLoading = true);
//     try {
//       actifs = await RdvService().fetchRendezVous(
//         coiffeuseId: widget.coiffeuseId,
//         archived: false,
//       );
//
//       archives = await RdvService().fetchRendezVous(
//         coiffeuseId: widget.coiffeuseId,
//         archived: true,
//       );
//     } catch (e) {
//       print("Erreur: $e");
//     }
//     setState(() => isLoading = false);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: const CustomAppBar(),
//       body: Column(
//         children: [
//           Container(
//             color: Colors.orange.shade50,
//             child: TabBar(
//               controller: _tabController,
//               labelColor: Colors.orange,
//               unselectedLabelColor: Colors.grey,
//               indicatorColor: Colors.orange,
//               tabs: const [
//                 Tab(text: "🟢 Actifs"),
//                 Tab(text: "📂 Archivés"),
//               ],
//             ),
//           ),
//           Expanded(
//             child: isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : TabBarView(
//               controller: _tabController,
//               children: [
//                 _buildRdvList(actifs),
//                 _buildRdvList(archives),
//               ],
//             ),
//           ),
//         ],
//       ),
//       bottomNavigationBar: BottomNavBar(
//         currentIndex: currentIndex,
//         onTap: (index) {
//           setState(() {
//             currentIndex = index;
//           });
//         },
//       ),
//     );
//   }
//
//   Widget _buildRdvList(List<ReservationLight> rdvs) {
//     if (rdvs.isEmpty) {
//       return const Center(child: Text("Aucun rendez-vous."));
//     }
//
//     return ListView.builder(
//       itemCount: rdvs.length,
//       itemBuilder: (context, index) {
//         final rdv = rdvs[rdvs.length - 1 - index];
//         final dateFormatted = DateFormat("dd MMM yyyy").format(rdv.dateHeure);
//         final heureDebut = DateFormat("HH:mm").format(rdv.dateHeure);
//         final heureFin = DateFormat("HH:mm").format(
//           rdv.dateHeure.add(Duration(minutes: rdv.dureeTotale)),
//         );
//
//         return Card(
//           elevation: 3,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//           child: ListTile(
//             contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             leading: CircleAvatar(
//               backgroundImage: rdv.photoProfil != null
//                   ? NetworkImage("https://www.hairbnb.site${rdv.photoProfil}")
//                   : const AssetImage("assets/images/avatar_placeholder.png") as ImageProvider,
//               radius: 26,
//             ),
//             title: Text(
//               "${rdv.clientPrenom} ${rdv.clientNom}",
//               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//             ),
//             subtitle: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const SizedBox(height: 4),
//                 Text(
//                   "$dateFormatted • 🕒 $heureDebut - $heureFin",
//                   style: const TextStyle(fontSize: 13, color: Colors.grey),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   "💶 ${rdv.totalPrix.toStringAsFixed(2)} € • ⏱ ${rdv.dureeTotale} min",
//                   style: const TextStyle(fontSize: 13),
//                 ),
//                 const SizedBox(height: 6),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: rdv.statut == "confirmé"
//                         ? Colors.green.withOpacity(0.2)
//                         : Colors.orange.withOpacity(0.2),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Text(
//                     rdv.statut.toUpperCase(),
//                     style: TextStyle(
//                       color: rdv.statut == "confirmé" ? Colors.green : Colors.orange,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     IconButton(
//                       icon: const Icon(Icons.edit, color: Colors.blue),
//                       tooltip: "Modifier le rendez-vous",
//                       onPressed: () {
//                         // 👉 Navigue vers la page de modification ici
//                         print("Modifier ${rdv.idRendezVous}");
//                       },
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.archive_outlined, color: Colors.grey),
//                       tooltip: "Archiver ce rendez-vous",
//                       onPressed: () {
//                         // 👉 Appelle une méthode pour archiver ici
//                         print("Archiver ${rdv.idRendezVous}");
//                       },
//                     ),
//                   ],
//                 )
//               ],
//             ),
//
//             trailing: CountdownBoxTimer(targetTime: rdv.dateHeure),
//
//             isThreeLine: true,
//           ),
//         );
//       },
//     );
//   }
// }
