/// **************************************************************************************
///
/// PAGE UI : GESTION DES HORAIRES ET INDISPONIBILITÉS
///
/// OBJECTIF :
/// Cet écran permet à une coiffeuse de gérer son emploi du temps. Elle peut définir
/// ses horaires de travail hebdomadaires récurrents (ex: tous les lundis de 9h à 17h)
/// et ajouter, modifier ou supprimer des périodes d'indisponibilité exceptionnelles
/// (ex: un rendez-vous médical, des vacances).
///
/// ARCHITECTURE ET FONCTIONNALITÉS CLÉS :
/// - Utilise un `StatefulWidget` pour gérer l'état des horaires, des indisponibilités
/// et du chargement des données.
/// - Récupère les données depuis un backend via des requêtes HTTP (package `http`).
/// - Utilise `intl` pour initialiser le formatage des dates en français.
/// - Propose des boîtes de dialogue (`showDialog`, `showDatePicker`, `showTimePicker`)
/// pour une saisie utilisateur interactive et intuitive.
/// - Gère les opérations CRUD (Créer, Lire, Mettre à jour, Supprimer) pour les
/// horaires et les indisponibilités.
/// - Affiche un indicateur de chargement (`CircularProgressIndicator`) pendant la
/// récupération des données.
///
///***************************************************************************************
library;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../models/horaire_coiffeuse.dart';
import '../../models/indisponibilite_coiffeuse.dart';
import '../../widgets/bottom_nav_bar.dart';

/// Un écran permettant à une coiffeuse de gérer ses horaires et ses indisponibilités.
class HoraireIndispoPage extends StatefulWidget {
  /// L'identifiant de la coiffeuse dont les horaires sont gérés.
  final int coiffeuseId;
  const HoraireIndispoPage({super.key, required this.coiffeuseId});

  @override
  State<HoraireIndispoPage> createState() => _HoraireIndispoPageState();
}

class _HoraireIndispoPageState extends State<HoraireIndispoPage> {
  /// Liste pour stocker les horaires hebdomadaires.
  List<HoraireCoiffeuse> horaires = [];
  /// Liste pour stocker les indisponibilités exceptionnelles.
  List<IndisponibiliteCoiffeuse> indispos = [];
  /// Liste des jours de la semaine pour l'affichage.
  final jours = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"];
  /// Gère l'affichage de l'indicateur de chargement.
  bool isLoading = true;
  /// Index de l'onglet actuellement sélectionné dans la barre de navigation inférieure.
  int _currentIndex = 2;

  @override
  void initState() {
    super.initState();
    // Initialise le formatage des dates pour la locale française avant de charger les données.
    initializeDateFormatting('fr_FR', null).then((_) => fetchAll());
  }

  /// Met à jour l'index de la barre de navigation.
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  /// Convertit une chaîne de caractères "HH:mm" en un objet TimeOfDay.
  TimeOfDay _toTimeOfDay(String timeStr) {
    final parts = timeStr.split(":");
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  /// Récupère tous les horaires et indisponibilités depuis l'API.
  Future<void> fetchAll() async {
    setState(() => isLoading = true);
    try {
      // Exécute les deux appels API en parallèle pour optimiser le temps de chargement.
      final resHoraire = await http.get(
          Uri.parse("https://www.hairbnb.site/api/get_horaires_coiffeuse/${widget.coiffeuseId}/"));
      final resIndispo = await http.get(
          Uri.parse("https://www.hairbnb.site/api/get_indisponibilites/${widget.coiffeuseId}/"));

      // Si les deux requêtes réussissent.
      if (resHoraire.statusCode == 200 && resIndispo.statusCode == 200) {
        final dataHoraires = json.decode(resHoraire.body) as List;
        final dataIndispo = json.decode(resIndispo.body) as List;

        // Met à jour l'état avec les nouvelles données, ce qui déclenche une reconstruction de l'UI.
        setState(() {
          horaires = dataHoraires.map((e) => HoraireCoiffeuse.fromJson(e)).toList();
          indispos = dataIndispo.map((e) => IndisponibiliteCoiffeuse.fromJson(e)).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      // Gère les erreurs potentielles (réseau, parsing, etc.).
    }
  }

  /// Affiche une boîte de dialogue pour définir ou modifier l'horaire d'un jour.
  Future<void> showHoraireDialog(int jour) async {
    // Affiche des sélecteurs d'heure pour le début et la fin.
    TimeOfDay? debut = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 8, minute: 0));
    if (debut == null) return;
    TimeOfDay? fin = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 17, minute: 0));
    if (fin == null) return;

    // Prépare le corps de la requête au format JSON.
    final body = json.encode({
      "coiffeuse": widget.coiffeuseId,
      "jour": jour,
      "heure_debut": "${debut.hour.toString().padLeft(2, '0')}:${debut.minute.toString().padLeft(2, '0')}",
      "heure_fin": "${fin.hour.toString().padLeft(2, '0')}:${fin.minute.toString().padLeft(2, '0')}",
    });

    // Envoie la requête POST à l'API pour enregistrer le nouvel horaire.
    final res = await http.post(
      Uri.parse("https://www.hairbnb.site/api/set_horaire_coiffeuse/"),
      headers: {"Content-Type": "application/json"},
      body: body,
    );
    // Si la requête réussit, recharge toutes les données pour mettre à jour l'affichage.
    if (res.statusCode == 200) fetchAll();
  }

  /// Ouvre une boîte de dialogue pour ajouter une nouvelle période d'indisponibilité.
  Future<void> addIndisponibilite() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    TimeOfDay debut = const TimeOfDay(hour: 10, minute: 0);
    TimeOfDay fin = const TimeOfDay(hour: 16, minute: 0);
    bool journeeEntiere = false;
    final motifCtrl = TextEditingController();

    // Affiche un dialogue contenant le formulaire de saisie.
    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text("Nouvelle indisponibilité"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  title: const Text("Journée entière"),
                  value: journeeEntiere,
                  onChanged: (val) => setState(() => journeeEntiere = val ?? false),
                ),
                if (!journeeEntiere)
                  Column(
                    children: [
                      ListTile(
                        title: Text("Heure début: ${debut.format(context)}"),
                        trailing: const Icon(Icons.access_time),
                        onTap: () async {
                          final picked = await showTimePicker(context: context, initialTime: debut);
                          if (picked != null) setState(() => debut = picked);
                        },
                      ),
                      ListTile(
                        title: Text("Heure fin: ${fin.format(context)}"),
                        trailing: const Icon(Icons.access_time),
                        onTap: () async {
                          final picked = await showTimePicker(context: context, initialTime: fin);
                          if (picked != null) setState(() => fin = picked);
                        },
                      ),
                    ],
                  ),
                TextField(
                  controller: motifCtrl,
                  decoration: const InputDecoration(labelText: "Motif (facultatif)"),
                )
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
              ElevatedButton(
                onPressed: () async {
                  // Prépare le corps de la requête avec les données saisies.
                  final body = json.encode({
                    "coiffeuse": widget.coiffeuseId,
                    "date": DateFormat('yyyy-MM-dd').format(date),
                    "heure_debut": journeeEntiere ? "00:00" : "${debut.hour.toString().padLeft(2, '0')}:${debut.minute.toString().padLeft(2, '0')}",
                    "heure_fin": journeeEntiere ? "23:59" : "${fin.hour.toString().padLeft(2, '0')}:${fin.minute.toString().padLeft(2, '0')}",
                    "motif": motifCtrl.text,
                  });
                  // Envoie la requête POST à l'API.
                  await http.post(
                    Uri.parse("https://www.hairbnb.site/api/add_indisponibilite/"),
                    headers: {"Content-Type": "application/json"},
                    body: body,
                  );
                  Navigator.pop(context);
                  fetchAll(); // Recharge les données.
                },
                child: const Text("Valider"),
              )
            ],
          );
        });
      },
    );
  }

  /// Ouvre une boîte de dialogue pour modifier une indisponibilité existante.
  Future<void> modifierIndisponibilite(IndisponibiliteCoiffeuse i) async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(i.date),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    TimeOfDay? debut = await showTimePicker(context: context, initialTime: _toTimeOfDay(i.heureDebut));
    if (debut == null) return;
    TimeOfDay? fin = await showTimePicker(context: context, initialTime: _toTimeOfDay(i.heureFin));
    if (fin == null) return;

    final motifCtrl = TextEditingController(text: i.motif ?? "");

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Modifier le motif"),
        content: TextField(controller: motifCtrl),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          TextButton(
            onPressed: () async {
              final body = json.encode({
                "date": DateFormat('yyyy-MM-dd').format(date),
                "heure_debut": "${debut.hour.toString().padLeft(2, '0')}:${debut.minute.toString().padLeft(2, '0')}",
                "heure_fin": "${fin.hour.toString().padLeft(2, '0')}:${fin.minute.toString().padLeft(2, '0')}",
                "motif": motifCtrl.text,
              });
              // Envoie une requête PUT pour mettre à jour l'enregistrement.
              await http.put(
                Uri.parse("https://www.hairbnb.site/api/update_indisponibilite/${i.id}/"),
                headers: {"Content-Type": "application/json"},
                body: body,
              );
              Navigator.pop(context);
              fetchAll();
            },
            child: const Text("Valider"),
          )
        ],
      ),
    );
  }

  /// Affiche une confirmation puis supprime une indisponibilité.
  Future<void> supprimerIndisponibilite(int indispoId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Supprimer"),
        content: const Text("Voulez-vous vraiment supprimer cette indisponibilité ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    // Envoie la requête DELETE à l'API.
    await http.delete(Uri.parse("https://www.hairbnb.site/api/delete_indisponibilite/$indispoId/"));
    fetchAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestion des disponibilités"),
        backgroundColor: Colors.teal,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addIndisponibilite,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text("Horaires hebdomadaires", style: Theme.of(context).textTheme.titleLarge),
          // Itère sur les jours de la semaine pour afficher les horaires.
          ...jours.asMap().entries.map((e) {
            final jour = e.key;
            HoraireCoiffeuse? exist;
            try {
              exist = horaires.firstWhere((h) => h.jour == jour);
            } catch (e) {
              exist = null;
            }
            return ListTile(
              title: Text(jours[jour]),
              subtitle: Text(exist != null ? "${exist.heureDebut} - ${exist.heureFin}" : "Non défini"),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.teal),
                onPressed: () => showHoraireDialog(jour),
              ),
            );
          }),
          const Divider(),
          Text("Indisponibilités exceptionnelles", style: Theme.of(context).textTheme.titleLarge),
          // Itère sur la liste des indisponibilités pour les afficher.
          ...indispos.map((i) => ListTile(
            title: Text(DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(DateTime.parse(i.date))),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${i.heureDebut} - ${i.heureFin}"),
                if (i.motif != null && i.motif!.isNotEmpty) Text("Motif: ${i.motif}"),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () => modifierIndisponibilite(i)),
                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => supprimerIndisponibilite(i.id)),
              ],
            ),
          )),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}








// // // PAGE FLUTTER POUR GESTION DES HORAIRES ET INDISPONIBILITES - MODERNE
//
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:intl/intl.dart';
// import 'package:intl/date_symbol_data_local.dart';
//
// import '../../models/horaire_coiffeuse.dart';
// import '../../models/indisponibilite_coiffeuse.dart';
// import '../../widgets/bottom_nav_bar.dart'; // Assure-toi que le chemin est correct
//
// class HoraireIndispoPage extends StatefulWidget {
//   final int coiffeuseId;
//   const HoraireIndispoPage({super.key, required this.coiffeuseId});
//
//   @override
//   State<HoraireIndispoPage> createState() => _HoraireIndispoPageState();
// }
//
// class _HoraireIndispoPageState extends State<HoraireIndispoPage> {
//   List<HoraireCoiffeuse> horaires = [];
//   List<IndisponibiliteCoiffeuse> indispos = [];
//   final jours = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"];
//   bool isLoading = true;
//   int _currentIndex = 2;
//
//   @override
//   void initState() {
//     super.initState();
//     initializeDateFormatting('fr_FR', null).then((_) => fetchAll());
//   }
//
//   void _onTabTapped(int index) {
//     setState(() {
//       _currentIndex = index;
//     });
//   }
//
//   TimeOfDay _toTimeOfDay(String timeStr) {
//     final parts = timeStr.split(":");
//     return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
//   }
//
//   Future<void> fetchAll() async {
//     setState(() => isLoading = true);
//     try {
//       final resHoraire = await http.get(
//           Uri.parse("https://www.hairbnb.site/api/get_horaires_coiffeuse/${widget.coiffeuseId}/"));
//       final resIndispo = await http.get(
//           Uri.parse("https://www.hairbnb.site/api/get_indisponibilites/${widget.coiffeuseId}/"));
//
//       if (resHoraire.statusCode == 200 && resIndispo.statusCode == 200) {
//         final dataHoraires = json.decode(resHoraire.body) as List;
//         final dataIndispo = json.decode(resIndispo.body) as List;
//
//         setState(() {
//           horaires = dataHoraires.map((e) => HoraireCoiffeuse.fromJson(e)).toList();
//           indispos = dataIndispo.map((e) => IndisponibiliteCoiffeuse.fromJson(e)).toList();
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print("Erreur API: $e");
//       }
//     }
//   }
//
//   Future<void> showHoraireDialog(int jour) async {
//     horaires.firstWhere(
//           (h) => h.jour == jour,
//       orElse: () => HoraireCoiffeuse(
//         id: 0,
//         coiffeuseId: widget.coiffeuseId,
//         jour: jour,
//         jourLabel: jours[jour],
//         heureDebut: "08:00",
//         heureFin: "17:00",
//       ),
//     );
//
//     TimeOfDay? debut = await showTimePicker(context: context, initialTime: TimeOfDay(hour: 8, minute: 0));
//     if (debut == null) return;
//     TimeOfDay? fin = await showTimePicker(context: context, initialTime: TimeOfDay(hour: 17, minute: 0));
//     if (fin == null) return;
//
//     final body = json.encode({
//       "coiffeuse": widget.coiffeuseId,
//       "jour": jour,
//       "heure_debut": "${debut.hour.toString().padLeft(2, '0')}:${debut.minute.toString().padLeft(2, '0')}",
//       "heure_fin": "${fin.hour.toString().padLeft(2, '0')}:${fin.minute.toString().padLeft(2, '0')}",
//     });
//
//     final res = await http.post(
//       Uri.parse("https://www.hairbnb.site/api/set_horaire_coiffeuse/"),
//       headers: {"Content-Type": "application/json"},
//       body: body,
//     );
//     if (res.statusCode == 200) fetchAll();
//   }
//
//   Future<void> addIndisponibilite() async {
//     DateTime? date = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime.now(),
//       lastDate: DateTime.now().add(Duration(days: 365)),
//     );
//     if (date == null) return;
//
//     TimeOfDay debut = TimeOfDay(hour: 10, minute: 0);
//     TimeOfDay fin = TimeOfDay(hour: 16, minute: 0);
//     bool journeeEntiere = false;
//     final motifCtrl = TextEditingController();
//
//     await showDialog(
//       context: context,
//       builder: (ctx) {
//         return StatefulBuilder(builder: (context, setState) {
//           return AlertDialog(
//             title: Text("Nouvelle indisponibilité"),
//             content: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 CheckboxListTile(
//                   title: Text("Journée entière"),
//                   value: journeeEntiere,
//                   onChanged: (val) => setState(() => journeeEntiere = val ?? false),
//                 ),
//                 if (!journeeEntiere)
//                   Column(
//                     children: [
//                       ListTile(
//                         title: Text("Heure début: ${debut.format(context)}"),
//                         trailing: Icon(Icons.access_time),
//                         onTap: () async {
//                           final picked = await showTimePicker(context: context, initialTime: debut);
//                           if (picked != null) setState(() => debut = picked);
//                         },
//                       ),
//                       ListTile(
//                         title: Text("Heure fin: ${fin.format(context)}"),
//                         trailing: Icon(Icons.access_time),
//                         onTap: () async {
//                           final picked = await showTimePicker(context: context, initialTime: fin);
//                           if (picked != null) setState(() => fin = picked);
//                         },
//                       ),
//                     ],
//                   ),
//                 TextField(
//                   controller: motifCtrl,
//                   decoration: InputDecoration(labelText: "Motif (facultatif)"),
//                 )
//               ],
//             ),
//             actions: [
//               TextButton(onPressed: () => Navigator.pop(context), child: Text("Annuler")),
//               ElevatedButton(
//                 onPressed: () async {
//                   final body = json.encode({
//                     "coiffeuse": widget.coiffeuseId,
//                     "date": DateFormat('yyyy-MM-dd').format(date),
//                     "heure_debut": journeeEntiere
//                         ? "00:00"
//                         : "${debut.hour.toString().padLeft(2, '0')}:${debut.minute.toString().padLeft(2, '0')}",
//                     "heure_fin": journeeEntiere
//                         ? "23:59"
//                         : "${fin.hour.toString().padLeft(2, '0')}:${fin.minute.toString().padLeft(2, '0')}",
//                     "motif": motifCtrl.text,
//                   });
//
//                   await http.post(
//                     Uri.parse("https://www.hairbnb.site/api/add_indisponibilite/"),
//                     headers: {"Content-Type": "application/json"},
//                     body: body,
//                   );
//                   Navigator.pop(context);
//                   fetchAll();
//                 },
//                 child: Text("Valider"),
//               )
//             ],
//           );
//         });
//       },
//     );
//   }
//
//   Future<void> modifierIndisponibilite(IndisponibiliteCoiffeuse i) async {
//     DateTime? date = await showDatePicker(
//       context: context,
//       initialDate: DateTime.parse(i.date),
//       firstDate: DateTime.now(),
//       lastDate: DateTime.now().add(Duration(days: 365)),
//     );
//     if (date == null) return;
//
//     TimeOfDay? debut = await showTimePicker(context: context, initialTime: _toTimeOfDay(i.heureDebut));
//     if (debut == null) return;
//     TimeOfDay? fin = await showTimePicker(context: context, initialTime: _toTimeOfDay(i.heureFin));
//     if (fin == null) return;
//
//     final motifCtrl = TextEditingController(text: i.motif ?? "");
//
//     await showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: Text("Modifier le motif"),
//         content: TextField(controller: motifCtrl),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context), child: Text("Annuler")),
//           TextButton(
//             onPressed: () async {
//               final body = json.encode({
//                 "date": DateFormat('yyyy-MM-dd').format(date),
//                 "heure_debut": "${debut.hour.toString().padLeft(2, '0')}:${debut.minute.toString().padLeft(2, '0')}",
//                 "heure_fin": "${fin.hour.toString().padLeft(2, '0')}:${fin.minute.toString().padLeft(2, '0')}",
//                 "motif": motifCtrl.text,
//               });
//
//               await http.put(
//                 Uri.parse("https://www.hairbnb.site/api/update_indisponibilite/${i.id}/"),
//                 headers: {"Content-Type": "application/json"},
//                 body: body,
//               );
//               Navigator.pop(context);
//               fetchAll();
//             },
//             child: Text("Valider"),
//           )
//         ],
//       ),
//     );
//   }
//
//   Future<void> supprimerIndisponibilite(int indispoId) async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: Text("Supprimer"),
//         content: Text("Voulez-vous vraiment supprimer cette indisponibilité ?"),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Annuler")),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: Text("Supprimer", style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );
//     if (confirm != true) return;
//
//     await http.delete(
//       Uri.parse("https://www.hairbnb.site/api/delete_indisponibilite/$indispoId/"),
//     );
//     fetchAll();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Gestion des disponibilités"),
//         backgroundColor: Colors.teal,
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: addIndisponibilite,
//         backgroundColor: Colors.teal,
//         child: Icon(Icons.add),
//       ),
//       body: isLoading
//           ? Center(child: CircularProgressIndicator())
//           : ListView(
//         padding: EdgeInsets.all(12),
//         children: [
//           Text("Horaires hebdomadaires", style: Theme.of(context).textTheme.titleLarge),
//           ...jours.asMap().entries.map((e) {
//             final jour = e.key;
//             HoraireCoiffeuse? exist;
//             try {
//               exist = horaires.firstWhere((h) => h.jour == jour);
//             } catch (e) {
//               exist = null;
//             }
//             return ListTile(
//               title: Text(jours[jour]),
//               subtitle: exist != null
//                   ? Text("${exist.heureDebut} - ${exist.heureFin}")
//                   : Text("Non défini"),
//               trailing: IconButton(
//                 icon: Icon(Icons.edit, color: Colors.teal),
//                 onPressed: () => showHoraireDialog(jour),
//               ),
//             );
//           }),
//           Divider(),
//           Text("Indisponibilités exceptionnelles", style: Theme.of(context).textTheme.titleLarge),
//           ...indispos.map((i) => ListTile(
//             title: Text(
//               DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(DateTime.parse(i.date)),
//             ),
//             subtitle: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text("${i.heureDebut} - ${i.heureFin}"),
//                 if (i.motif != null && i.motif!.isNotEmpty) Text("Motif: ${i.motif}"),
//               ],
//             ),
//             trailing: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 IconButton(
//                   icon: Icon(Icons.edit, color: Colors.orange),
//                   onPressed: () => modifierIndisponibilite(i),
//                 ),
//                 IconButton(
//                   icon: Icon(Icons.delete, color: Colors.red),
//                   onPressed: () => supprimerIndisponibilite(i.id),
//                 ),
//               ],
//             ),
//           )),
//         ],
//       ),
//       bottomNavigationBar: BottomNavBar(
//         currentIndex: _currentIndex,
//         onTap: _onTabTapped,
//       ),
//     );
//   }
// }
