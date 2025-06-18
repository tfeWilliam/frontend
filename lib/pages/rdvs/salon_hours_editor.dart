////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                PAGE DE GESTION DES HORAIRES D'OUVERTURE DU SALON             //
//                                                                            //
//  Ce fichier définit l'écran `HoraireSalonPage`, qui fournit une interface  //
//  à la coiffeuse pour gérer les horaires d'ouverture hebdomadaires de son    //
//  salon.                                                                    //
//                                                                            //
//  Fonctionnalités :                                                         //
//  - Récupère d'abord l'ID du salon associé à la coiffeuse.                  //
//  - Affiche les horaires pour chaque jour de la semaine.                    //
//  - Permet d'ajouter, de modifier ou de supprimer les plages horaires pour  //
//    chaque jour via des boîtes de dialogue.                                 //
//  - Communique avec une API backend pour persister les changements.         //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Un `StatefulWidget` qui permet à une coiffeuse de gérer les horaires de son salon.
class HoraireSalonPage extends StatefulWidget {
  /// L'identifiant de la coiffeuse, utilisé pour retrouver le salon associé.
  final int coiffeuseId;

  /// Constructeur de la page de gestion des horaires.
  const HoraireSalonPage({super.key, required this.coiffeuseId});

  @override
  _HoraireSalonPageState createState() => _HoraireSalonPageState();
}

/// La classe d'état pour `HoraireSalonPage`.
/// Gère les appels API, l'état de chargement et les données des horaires.
class _HoraireSalonPageState extends State<HoraireSalonPage> {
  //region Déclaration des variables d'état
  /// L'identifiant du salon, récupéré au démarrage.
  int? salonId;
  /// `true` si les données sont en cours de chargement.
  bool isLoading = true;
  /// Un map pour stocker les horaires, avec le jour (0-6) comme clé.
  Map<int, Map<String, String>> horaires = {};
  /// La liste des jours de la semaine pour l'affichage.
  final jours = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"];
  //endregion

  @override
  void initState() {
    super.initState();
    // Lance le processus de récupération des données à l'initialisation.
    fetchSalonEtHoraires();
  }

  //region Logique de récupération des données
  /// Récupère d'abord l'ID du salon, puis les horaires associés.
  /// C'est un processus en deux étapes car l'ID du salon est requis pour les autres appels.
  Future<void> fetchSalonEtHoraires() async {
    final salonResponse = await http.get(
      Uri.parse('https://www.hairbnb.site/api/get_salon_by_coiffeuse/${widget.coiffeuseId}/'),
    );

    if (salonResponse.statusCode == 200) {
      final data = json.decode(salonResponse.body);
      salonId = data['idSalon'];
      // Une fois l'ID du salon obtenu, on charge les horaires.
      await fetchHoraires();
    } else {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur : Salon introuvable ❌")),
        );
      }
    }
  }

  /// Récupère les horaires existants pour le salon depuis l'API.
  Future<void> fetchHoraires() async {
    final url = Uri.parse('https://www.hairbnb.site/api/get_horaires_salon/${widget.coiffeuseId}/');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      if (mounted) {
        setState(() {
          // Transforme la liste de réponses en un map pour un accès facile par jour.
          horaires = {
            for (var h in data)
              h['jour']: {'heure_debut': h['heure_debut'], 'heure_fin': h['heure_fin'], 'id': h['id'].toString()}
          };
          isLoading = false;
        });
      }
    }
  }
  //endregion

  //region Logique de modification des données
  /// Affiche une boîte de dialogue pour ajouter ou modifier l'horaire d'un jour.
  Future<void> showEditDialog(int jour) async {
    // Pré-remplit les contrôleurs avec les horaires existants s'ils existent.
    final debutController = TextEditingController(text: horaires[jour]?['heure_debut'] ?? "08:00");
    final finController = TextEditingController(text: horaires[jour]?['heure_fin'] ?? "18:00");
    final isEditing = horaires.containsKey(jour);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("${jours[jour]} - ${isEditing ? "Modifier" : "Ajouter"}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: debutController, decoration: const InputDecoration(labelText: "Heure de début (HH:mm)")),
            TextField(controller: finController, decoration: const InputDecoration(labelText: "Heure de fin (HH:mm)")),
          ],
        ),
        actions: [
          TextButton(child: const Text("Annuler"), onPressed: () => Navigator.pop(context)),
          ElevatedButton(
            child: const Text("Enregistrer"),
            onPressed: () async {
              if (salonId == null) return;
              final payload = {
                "salon": salonId, "jour": jour,
                "heure_debut": debutController.text, "heure_fin": finController.text,
              };
              // Envoie les nouvelles données à l'API via une requête POST.
              final response = await http.post(
                Uri.parse("https://www.hairbnb.site/api/set_horaire_jour/"),
                headers: {"Content-Type": "application/json"},
                body: json.encode(payload),
              );
              if (response.statusCode == 200 && mounted) {
                Navigator.pop(context);
                fetchHoraires(); // Recharge les horaires pour afficher la mise à jour.
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Horaire enregistré ✅")));
              }
            },
          ),
        ],
      ),
    );
  }

  /// Gère la suppression de l'horaire d'un jour, avec une boîte de dialogue de confirmation.
  Future<void> deleteHoraire(int jour) async {
    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Supprimer l'horaire"),
        content: Text("Supprimer l'horaire de ${jours[jour]} ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Supprimer")),
        ],
      ),
    );

    // Si la confirmation est `true`, envoie la requête DELETE à l'API.
    if (confirm == true && salonId != null) {
      final response = await http.delete(Uri.parse("https://www.hairbnb.site/api/delete_horaire_jour/$salonId/$jour"));
      if (response.statusCode == 200 && mounted) {
        fetchHoraires(); // Recharge les horaires pour refléter la suppression.
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Horaire supprimé ✅")));
      }
    }
  }
  //endregion

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🕒 Horaires du salon"), backgroundColor: Colors.orange),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
      // Construit une liste de 7 éléments, un pour chaque jour de la semaine.
          : ListView.builder(
        itemCount: 7,
        itemBuilder: (context, index) {
          // Récupère l'horaire pour le jour `index` s'il existe dans le map.
          final horaire = horaires[index];
          return ListTile(
            title: Text(jours[index]),
            // Affiche l'horaire ou un message par défaut.
            subtitle: horaire != null
                ? Text("${horaire['heure_debut']} - ${horaire['heure_fin']}")
                : const Text("Aucun horaire défini"),
            // Affiche les boutons d'action (Ajouter/Modifier et Supprimer).
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(horaire != null ? Icons.edit : Icons.add, color: Colors.blue),
                  onPressed: () => showEditDialog(index),
                ),
                // Le bouton de suppression n'apparaît que si un horaire existe.
                if (horaire != null)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => deleteHoraire(index),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}








// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// class HoraireSalonPage extends StatefulWidget {
//   final int coiffeuseId; // 🔥 On ne passe plus salonId, mais coiffeuseId
//
//   const HoraireSalonPage({super.key, required this.coiffeuseId});
//
//   @override
//   _HoraireSalonPageState createState() => _HoraireSalonPageState();
// }
//
// class _HoraireSalonPageState extends State<HoraireSalonPage> {
//   int? salonId;
//   bool isLoading = true;
//   Map<int, Map<String, String>> horaires = {}; // jour : {heure_debut, heure_fin}
//   final jours = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"];
//
//   @override
//   void initState() {
//     super.initState();
//     fetchSalonEtHoraires();
//   }
//
//   Future<void> fetchSalonEtHoraires() async {
//     final salonResponse = await http.get(
//       Uri.parse('https://www.hairbnb.site/api/get_salon_by_coiffeuse/${widget.coiffeuseId}/'),
//     );
//
//     if (salonResponse.statusCode == 200) {
//       final data = json.decode(salonResponse.body);
//       salonId = data['idSalon'];
//       await fetchHoraires(); // 🔁 Ensuite on charge les horaires
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Erreur : Salon introuvable ❌")),
//       );
//     }
//   }
//
//   Future<void> fetchHoraires() async {
//     final url = Uri.parse('https://www.hairbnb.site/api/get_horaires_salon/${widget.coiffeuseId}/');
//     final response = await http.get(url);
//
//     if (response.statusCode == 200) {
//       final List data = json.decode(response.body);
//       setState(() {
//         horaires = {
//           for (var h in data)
//             h['jour']: {
//               'heure_debut': h['heure_debut'],
//               'heure_fin': h['heure_fin'],
//               'id': h['id'].toString()
//             }
//         };
//         isLoading = false;
//       });
//     }
//   }
//
//   Future<void> showEditDialog(int jour) async {
//     final debutController = TextEditingController(
//         text: horaires[jour]?['heure_debut'] ?? "08:00");
//     final finController = TextEditingController(
//         text: horaires[jour]?['heure_fin'] ?? "18:00");
//
//     final isEditing = horaires.containsKey(jour);
//
//     await showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: Text("${jours[jour]} - ${isEditing ? "Modifier" : "Ajouter"}"),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             TextField(
//               controller: debutController,
//               decoration: const InputDecoration(labelText: "Heure de début (HH:mm)"),
//             ),
//             TextField(
//               controller: finController,
//               decoration: const InputDecoration(labelText: "Heure de fin (HH:mm)"),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             child: const Text("Annuler"),
//             onPressed: () => Navigator.pop(context),
//           ),
//           ElevatedButton(
//             child: const Text("Enregistrer"),
//             onPressed: () async {
//               if (salonId == null) return;
//
//               final payload = {
//                 "salon": salonId,
//                 "jour": jour,
//                 "heure_debut": debutController.text,
//                 "heure_fin": finController.text,
//               };
//
//               final response = await http.post(
//                 Uri.parse("https://www.hairbnb.site/api/set_horaire_jour/"),
//                 headers: {"Content-Type": "application/json"},
//                 body: json.encode(payload),
//               );
//
//               if (response.statusCode == 200) {
//                 Navigator.pop(context);
//                 fetchHoraires();
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text("Horaire enregistré ✅")),
//                 );
//               }
//             },
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> deleteHoraire(int jour) async {
//     final confirm = await showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text("Supprimer l'horaire"),
//         content: Text("Supprimer l'horaire de ${jours[jour]} ?"),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
//           ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Supprimer")),
//         ],
//       ),
//     );
//
//     if (confirm == true && salonId != null) {
//       final response = await http.delete(
//         Uri.parse("https://www.hairbnb.site/api/delete_horaire_jour/$salonId/$jour"),
//       );
//
//       if (response.statusCode == 200) {
//         fetchHoraires();
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Horaire supprimé ✅")),
//         );
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("🕒 Horaires du salon"), backgroundColor: Colors.orange),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : ListView.builder(
//         itemCount: 7,
//         itemBuilder: (context, index) {
//           final horaire = horaires[index];
//           return ListTile(
//             title: Text(jours[index]),
//             subtitle: horaire != null
//                 ? Text("${horaire['heure_debut']} - ${horaire['heure_fin']}")
//                 : const Text("Aucun horaire défini"),
//             trailing: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 IconButton(
//                   icon: Icon(horaire != null ? Icons.edit : Icons.add, color: Colors.blue),
//                   onPressed: () => showEditDialog(index),
//                 ),
//                 if (horaire != null)
//                   IconButton(
//                     icon: const Icon(Icons.delete, color: Colors.red),
//                     onPressed: () => deleteHoraire(index),
//                   ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
