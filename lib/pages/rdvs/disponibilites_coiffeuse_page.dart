////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//          PAGE D'AFFICHAGE DES DISPONIBILITÉS D'UNE COIFFEUSE                 //
//                                                                            //
//  Ce fichier définit l'écran `DisponibilitesCoiffeusePage`, qui permet à un //
//  utilisateur de consulter les créneaux horaires disponibles pour une       //
//  coiffeuse en fonction d'une date et d'une durée de service spécifiques.   //
//                                                                            //
//  Fonctionnalités :                                                         //
//  - Permet de sélectionner une date via un `DatePicker`.                    //
//  - Permet de choisir une durée de service via un `DropdownButton`.         //
//  - Interroge une API backend pour récupérer les disponibilités en fonction //
//    des filtres sélectionnés.                                               //
//  - Affiche les créneaux disponibles dans une liste interactive.            //
//  - Gère les états de chargement, d'erreur, et le cas où aucune             //
//    disponibilité n'est trouvée.                                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/my_drawer_service/hairbnb_scaffold.dart';
import '../../services/providers/current_user_provider.dart';
import 'package:hairbnb/widgets/bottom_nav_bar.dart';

/// Widget principal de la page d'affichage des disponibilités.
class DisponibilitesCoiffeusePage extends StatefulWidget {
  const DisponibilitesCoiffeusePage({super.key});

  @override
  _DisponibilitesCoiffeusePageState createState() => _DisponibilitesCoiffeusePageState();
}

/// Classe d'état pour `DisponibilitesCoiffeusePage`.
/// Gère la sélection des filtres, les appels API et l'affichage des résultats.
class _DisponibilitesCoiffeusePageState extends State<DisponibilitesCoiffeusePage> {
  //region Déclaration des variables d'état
  /// La liste des créneaux de disponibilité reçus de l'API.
  List<dynamic> disponibilites = [];
  /// `true` si les données sont en cours de chargement.
  bool isLoading = false;
  /// `true` si une erreur est survenue lors du chargement.
  bool hasError = false;
  /// L'ID de la coiffeuse dont on consulte les disponibilités.
  String? coiffeuseId;
  /// L'index actuel pour la barre de navigation inférieure.
  int _currentIndex = 2;

  /// La date actuellement sélectionnée par l'utilisateur.
  DateTime selectedDate = DateTime.now();
  /// La durée de service actuellement sélectionnée par l'utilisateur (en minutes).
  int selectedDuree = 30;
  /// La liste des durées possibles que l'utilisateur peut sélectionner.
  final List<int> dureesDisponibles = [30, 45, 60];
  //endregion

  @override
  void initState() {
    super.initState();
    // Récupère l'ID de la coiffeuse (dans ce cas, l'utilisateur courant)
    // et lance le premier chargement des disponibilités.
    _fetchCurrentUser();
  }

  //region Logique de récupération des données
  /// Récupère l'ID de l'utilisateur courant depuis le provider.
  void _fetchCurrentUser() {
    final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
    coiffeuseId = currentUserProvider.currentUser?.idTblUser.toString();
    // Si l'ID est bien récupéré, on charge les disponibilités.
    if (coiffeuseId != null) {
      _fetchDisponibilites();
    }
  }

  /// Interroge l'API pour obtenir les créneaux disponibles en fonction
  /// de la date et de la durée sélectionnées.
  Future<void> _fetchDisponibilites() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    final String date = DateFormat('yyyy-MM-dd').format(selectedDate);

    try {
      final response = await http.get(
        Uri.parse('https://www.hairbnb.site/api/get_disponibilites_client/$coiffeuseId/?date=$date&duree=$selectedDuree'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          disponibilites = data['disponibilites'];
          isLoading = false;
        });
      } else {
        throw Exception("Erreur de chargement");
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  /// Affiche un calendrier et permet à l'utilisateur de choisir une nouvelle date.
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 14)), // Limite la sélection à 2 semaines.
      builder: (context, child) {
        // Applique un thème personnalisé au calendrier.
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.orange,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    // Si une nouvelle date est choisie, met à jour l'état et recharge les disponibilités.
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      _fetchDisponibilites();
    }
  }
  //endregion

  /// Affiche une boîte de dialogue pour confirmer la sélection d'un créneau.
  /// NOTE: La logique de réservation finale n'est pas implémentée ici.
  void _confirmerReservation(String debut, String fin) {
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    final datetime = "${dateStr}T$debut:00";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmer ce créneau ?", style: TextStyle(color: Colors.orange)),
        content: Text("⏰ $debut - $fin le $dateStr\nDurée : $selectedDuree min"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              Navigator.pop(ctx);
              // Placeholder pour l'action de réservation.
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Créneau sélectionné : $datetime"), backgroundColor: Colors.orange));
            },
            child: const Text("Réserver", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Formatte la date pour un affichage lisible en français.
    final formattedDate = DateFormat('EEEE d MMMM', 'fr_FR').format(selectedDate);
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 400;

    return HairbnbScaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF3E0), Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre de la page.
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text("📆 Choisir un créneau", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange)),
              ),

              // Sélecteurs de date et durée, avec une disposition responsive.
              isSmallScreen
                  ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildDureeSelector(), const SizedBox(height: 12), _buildDateSelector(formattedDate)])
                  : Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_buildDureeSelector(), _buildDateSelector(formattedDate)]),

              const SizedBox(height: 20),

              // Affichage conditionnel du contenu principal.
              if (isLoading)
                const Center(child: CircularProgressIndicator(color: Colors.orange))
              else if (hasError)
                Center(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                    onPressed: _fetchDisponibilites,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text("Réessayer", style: TextStyle(color: Colors.white)),
                  ),
                )
              else if (disponibilites.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text("Aucune disponibilité trouvée pour cette date.", style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic), textAlign: TextAlign.center),
                    ),
                  )
                else
                // Liste des créneaux disponibles.
                  Expanded(
                    child: ListView.builder(
                      itemCount: disponibilites.length,
                      itemBuilder: (context, index) {
                        final slot = disponibilites[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.access_time, color: Colors.orange),
                            ),
                            title: Text("🕒 ${slot['debut']} - ${slot['fin']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("Durée: $selectedDuree min"),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.orange),
                            onTap: () => _confirmerReservation(slot['debut'], slot['fin']),
                          ),
                        );
                      },
                    ),
                  ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() { _currentIndex = index; }),
      ),
    );
  }

  //region Méthodes de construction de l'UI (Widgets)
  /// Construit le sélecteur de durée de service.
  Widget _buildDureeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 1, blurRadius: 3, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Durée :", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: selectedDuree,
            underline: Container(), // Masque la ligne de soulignement par défaut.
            icon: const Icon(Icons.arrow_drop_down, color: Colors.orange),
            items: dureesDisponibles.map((duree) => DropdownMenuItem(value: duree, child: Text("$duree min", style: const TextStyle(fontWeight: FontWeight.w500)))).toList(),
            onChanged: (val) {
              setState(() => selectedDuree = val!);
              _fetchDisponibilites(); // Recharge les disponibilités avec la nouvelle durée.
            },
          ),
        ],
      ),
    );
  }

  /// Construit le bouton de sélection de date.
  Widget _buildDateSelector(String formattedDate) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: _selectDate,
      icon: const Icon(Icons.calendar_today, color: Colors.orange, size: 18),
      label: Text(formattedDate, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
    );
  }
//endregion
}







// import 'dart:convert';
//
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import '../../services/my_drawer_service/hairbnb_scaffold.dart';
// import '../../services/providers/current_user_provider.dart';
// import 'package:hairbnb/widgets/bottom_nav_bar.dart';
//
// class DisponibilitesCoiffeusePage extends StatefulWidget {
//   const DisponibilitesCoiffeusePage({super.key});
//
//   @override
//   _DisponibilitesCoiffeusePageState createState() => _DisponibilitesCoiffeusePageState();
// }
//
// class _DisponibilitesCoiffeusePageState extends State<DisponibilitesCoiffeusePage> {
//   List<dynamic> disponibilites = [];
//   bool isLoading = false;
//   bool hasError = false;
//   String? coiffeuseId;
//   int _currentIndex = 2; // Index pour la bottom navigation bar (calendrier)
//
//   DateTime selectedDate = DateTime.now();
//   int selectedDuree = 30;
//   final List<int> dureesDisponibles = [30, 45, 60];
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchCurrentUser();
//   }
//
//   void _fetchCurrentUser() {
//     final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//     coiffeuseId = currentUserProvider.currentUser?.idTblUser.toString();
//     if (coiffeuseId != null) {
//       _fetchDisponibilites();
//     }
//   }
//
//   Future<void> _fetchDisponibilites() async {
//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });
//
//     final String date = DateFormat('yyyy-MM-dd').format(selectedDate);
//
//     try {
//       final response = await http.get(
//         Uri.parse('https://www.hairbnb.site/api/get_disponibilites_client/$coiffeuseId/?date=$date&duree=$selectedDuree'),
//       );
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         setState(() {
//           disponibilites = data['disponibilites'];
//           isLoading = false;
//         });
//       } else {
//         throw Exception("Erreur de chargement");
//       }
//     } catch (e) {
//       setState(() {
//         hasError = true;
//         isLoading = false;
//       });
//     }
//   }
//
//   Future<void> _selectDate() async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: selectedDate,
//       firstDate: DateTime.now(),
//       lastDate: DateTime.now().add(Duration(days: 14)),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: const ColorScheme.light(
//               primary: Colors.orange, // Couleur principale
//               onPrimary: Colors.white, // Texte sur la couleur principale
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );
//
//     if (picked != null && picked != selectedDate) {
//       setState(() {
//         selectedDate = picked;
//       });
//       _fetchDisponibilites();
//     }
//   }
//
//   void _confirmerReservation(String debut, String fin) {
//     final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
//     final datetime = "${dateStr}T$debut:00"; // Format: 2025-03-26T08:00:00
//
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text("Confirmer ce créneau ?", style: TextStyle(color: Colors.orange)),
//         content: Text("⏰ $debut - $fin le $dateStr\nDurée : $selectedDuree min"),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx),
//             child: const Text("Annuler", style: TextStyle(color: Colors.grey)),
//           ),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.orange,
//             ),
//             onPressed: () {
//               Navigator.pop(ctx);
//               // 🔥 Tu peux maintenant faire un appel POST pour réserver ici
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Text("Créneau sélectionné : $datetime"),
//                   backgroundColor: Colors.orange,
//                 ),
//               );
//             },
//             child: const Text("Réserver", style: TextStyle(color: Colors.white)),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final formattedDate = DateFormat('EEEE d MMMM', 'fr_FR').format(selectedDate);
//     final screenWidth = MediaQuery.of(context).size.width;
//     final bool isSmallScreen = screenWidth < 400;
//
//     return HairbnbScaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Color(0xFFFFF3E0), Colors.white],
//           ),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Titre de la page
//               const Padding(
//                 padding: EdgeInsets.only(bottom: 20),
//                 child: Text(
//                   "📆 Choisir un créneau",
//                   style: TextStyle(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.orange,
//                   ),
//                 ),
//               ),
//
//               // Sélecteur date et durée
//               isSmallScreen
//                   ? Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   _buildDureeSelector(),
//                   const SizedBox(height: 12),
//                   _buildDateSelector(formattedDate),
//                 ],
//               )
//                   : Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   _buildDureeSelector(),
//                   _buildDateSelector(formattedDate),
//                 ],
//               ),
//
//               const SizedBox(height: 20),
//
//               if (isLoading)
//                 const Center(child: CircularProgressIndicator(color: Colors.orange))
//               else if (hasError)
//                 Center(
//                   child: ElevatedButton.icon(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.orange,
//                       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                     ),
//                     onPressed: _fetchDisponibilites,
//                     icon: const Icon(Icons.refresh, color: Colors.white),
//                     label: const Text("Réessayer", style: TextStyle(color: Colors.white)),
//                   ),
//                 )
//               else if (disponibilites.isEmpty)
//                   const Center(
//                     child: Padding(
//                       padding: EdgeInsets.all(20),
//                       child: Text(
//                         "Aucune disponibilité trouvée pour cette date.",
//                         style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
//                         textAlign: TextAlign.center,
//                       ),
//                     ),
//                   )
//                 else
//                   Expanded(
//                     child: ListView.builder(
//                       itemCount: disponibilites.length,
//                       itemBuilder: (context, index) {
//                         final slot = disponibilites[index];
//                         final debut = slot['debut'];
//                         final fin = slot['fin'];
//
//                         return Card(
//                           margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
//                           elevation: 3,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: ListTile(
//                             leading: Container(
//                               padding: const EdgeInsets.all(8),
//                               decoration: BoxDecoration(
//                                 color: Colors.orange.withOpacity(0.2),
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: const Icon(Icons.access_time, color: Colors.orange),
//                             ),
//                             title: Text(
//                               "🕒 $debut - $fin",
//                               style: const TextStyle(fontWeight: FontWeight.bold),
//                             ),
//                             subtitle: Text("Durée: $selectedDuree min"),
//                             trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.orange),
//                             onTap: () => _confirmerReservation(debut, fin),
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//             ],
//           ),
//         ),
//       ),
//       bottomNavigationBar: BottomNavBar(
//         currentIndex: _currentIndex,
//         onTap: (index) {
//           setState(() {
//             _currentIndex = index;
//           });
//           // Navigation à implémenter selon votre logique d'application
//         },
//       ),
//     );
//   }
//
//   Widget _buildDureeSelector() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.2),
//             spreadRadius: 1,
//             blurRadius: 3,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const Text(
//             "Durée :",
//             style: TextStyle(fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(width: 8),
//           DropdownButton<int>(
//             value: selectedDuree,
//             underline: Container(),
//             icon: const Icon(Icons.arrow_drop_down, color: Colors.orange),
//             items: dureesDisponibles
//                 .map((duree) => DropdownMenuItem(
//                 value: duree,
//                 child: Text(
//                   "$duree min",
//                   style: const TextStyle(fontWeight: FontWeight.w500),
//                 )))
//                 .toList(),
//             onChanged: (val) {
//               setState(() => selectedDuree = val!);
//               _fetchDisponibilites();
//             },
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildDateSelector(String formattedDate) {
//     return TextButton.icon(
//       style: TextButton.styleFrom(
//         backgroundColor: Colors.white,
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//       ),
//       onPressed: _selectDate,
//       icon: const Icon(Icons.calendar_today, color: Colors.orange, size: 18),
//       label: Text(
//         formattedDate,
//         style: const TextStyle(
//           color: Colors.black87,
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//     );
//   }
// }
//
//
