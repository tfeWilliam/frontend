// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
//
// class OSMTestPage extends StatefulWidget {
//   const OSMTestPage({super.key});
//
//   @override
//   State<OSMTestPage> createState() => _OSMTestPageState();
// }
//
// class _OSMTestPageState extends State<OSMTestPage> {
//   final TextEditingController postalCodeController = TextEditingController();
//   String result = "Résultat ici";
//
//   /// Fonction pour appeler l'API Nominatim
//   Future<void> fetchCommune(String postalCode) async {
//     if (postalCode.isEmpty) return;
//
//     // URL de l'API Nominatim avec le code postal
//     final url = Uri.parse(
//         "https://nominatim.openstreetmap.org/search?postalcode=$postalCode&country=Belgium&format=json");
//
//     try {
//       final response = await http.get(url, headers: {
//         'User-Agent': 'FlutterApp/1.0' // Obligatoire pour Nominatim
//       });
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body) as List;
//
//         // Vérifier si des résultats existent
//         if (data.isNotEmpty) {
//           setState(() {
//             result = "Commune trouvée : ${data[0]['display_name']}";
//           });
//         } else {
//           setState(() {
//             result = "Aucune commune trouvée pour ce code postal.";
//           });
//         }
//       } else {
//         setState(() {
//           result = "Erreur API : ${response.statusCode}";
//         });
//       }
//     } catch (e) {
//       setState(() {
//         result = "Erreur de connexion : $e";
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Test OpenStreetMap"),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text("Entrez un code postal belge :"),
//             const SizedBox(height: 10),
//             TextField(
//               controller: postalCodeController,
//               keyboardType: TextInputType.number,
//               decoration: const InputDecoration(
//                 labelText: "Code Postal",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () => fetchCommune(postalCodeController.text),
//               child: const Text("Rechercher la commune"),
//             ),
//             const SizedBox(height: 20),
//             Text(result),
//           ],
//         ),
//       ),
//     );
//   }
// }
