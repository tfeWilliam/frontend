// ////////////////////////////////////////////////////////////////////////////////
// //                                                                            //
// //                ÉCRAN DE DÉBOGAGE POUR LE SYSTÈME D'AVIS                     //
// //                                                                            //
// //  Ce fichier définit l'interface utilisateur `DebugAvisScreen`, un outil    //
// //  destiné exclusivement aux développeurs pour diagnostiquer des problèmes,   //
// //  en particulier ceux liés à la récupération des rendez-vous et à la        //
// //  logique des avis.                                                         //
// //                                                                            //
// //  Cet écran fournit une série de boutons pour lancer des tests spécifiques  //
// //  (définis dans `DebugAvisService`) et affiche les résultats ou les erreurs  //
// //  dans une console intégrée à l'interface.                                  //
// //                                                                            //
// ////////////////////////////////////////////////////////////////////////////////
// library;
//
// import 'package:flutter/material.dart';
//
// import 'debug_avis_service.dart';
//
// /// Un `StatefulWidget` qui constitue la page de débogage pour les avis.
// class DebugAvisScreen extends StatefulWidget {
//   const DebugAvisScreen({super.key});
//
//   @override
//   _DebugAvisScreenState createState() => _DebugAvisScreenState();
// }
//
// /// La classe d'état pour `DebugAvisScreen`.
// /// Gère l'état de l'interface, comme le texte affiché dans la console
// /// de débogage et l'indicateur de chargement.
// class _DebugAvisScreenState extends State<DebugAvisScreen> {
//   /// La chaîne de caractères affichée dans la zone de console.
//   String _debugOutput = "Appuyez sur un bouton pour commencer le debug...";
//   /// Un booléen pour suivre si un test est actuellement en cours d'exécution.
//   bool _isLoading = false;
//
//   /// Une fonction wrapper qui exécute une fonction de test asynchrone.
//   ///
//   /// Elle gère la mise à jour de l'état de chargement (`_isLoading`) et
//   /// affiche les résultats ou les erreurs dans la console de l'interface.
//   ///
//   /// [testName] : Le nom du test, affiché dans la console.
//   /// [test] : La fonction de test asynchrone à exécuter.
//   void _runDebugTest(String testName, Future<void> Function() test) async {
//     // Met à jour l'UI pour indiquer le début du test.
//     setState(() {
//       _isLoading = true;
//       _debugOutput = "🔄 Exécution du test: $testName...\n";
//     });
//
//     try {
//       // Exécute la fonction de test fournie.
//       await test();
//       // Met à jour l'UI en cas de succès.
//       setState(() {
//         _debugOutput += "\n✅ Test terminé avec succès !";
//         _isLoading = false;
//       });
//     } catch (e) {
//       // Met à jour l'UI en cas d'erreur.
//       setState(() {
//         _debugOutput += "\n❌ Erreur pendant le test: $e";
//         _isLoading = false;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // Barre d'application thématique pour l'écran de débogage.
//       appBar: AppBar(
//         title: const Text('🧪 Debug Avis'),
//         backgroundColor: Colors.red,
//         foregroundColor: Colors.white,
//       ),
//       body: Column(
//         children: [
//           // --- Section des boutons de test ---
//           Container(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               children: [
//                 Text(
//                   'Debug du problème "No TblClient matches"',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.red[700],
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 20),
//
//                 // Bouton pour lancer la suite complète de tests.
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton.icon(
//                     onPressed: _isLoading ? null : () {
//                       _runDebugTest("Debug Complet", () => DebugAvisService.debugComplet(context));
//                     },
//                     icon: const Icon(Icons.bug_report),
//                     label: const Text('DEBUG COMPLET'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.red,
//                       foregroundColor: Colors.white,
//                       padding: const EdgeInsets.symmetric(vertical: 12),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//
//                 // Grille de boutons pour les tests individuels.
//                 Row(
//                   children: [
//                     Expanded(
//                       child: ElevatedButton(
//                         onPressed: _isLoading ? null : () => _runDebugTest("Utilisateur", () => DebugAvisService.debugCurrentUser(context)),
//                         style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
//                         child: const Text('👤 User'),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: ElevatedButton(
//                         onPressed: _isLoading ? null : () => _runDebugTest("Token", DebugAvisService.debugFirebaseToken),
//                         style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
//                         child: const Text('🔑 Token'),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 8),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: ElevatedButton(
//                         onPressed: _isLoading ? null : () => _runDebugTest("API Publique", DebugAvisService.debugApiPublic),
//                         style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
//                         child: const Text('🌐 API'),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: ElevatedButton(
//                         onPressed: _isLoading ? null : () => _runDebugTest("Mes RDV", DebugAvisService.debugApiMesRdv),
//                         style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
//                         child: const Text('📅 RDV'),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//
//           // --- Section de la console d'affichage des résultats ---
//           Expanded(
//             child: Container(
//               margin: const EdgeInsets.all(16),
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.grey[100],
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: Colors.grey[300]!),
//               ),
//               child: SingleChildScrollView(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Icon(Icons.terminal, color: Colors.grey[600]),
//                         const SizedBox(width: 8),
//                         const Text('Console Debug', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//                         const Spacer(),
//                         // Affiche un indicateur de progression si un test est en cours.
//                         if (_isLoading)
//                           const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
//                       ],
//                     ),
//                     const SizedBox(height: 12),
//                     // Affiche la sortie du test.
//                     Text(
//                       _debugOutput,
//                       style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.black87),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//
//           // --- Section d'instructions pour le développeur ---
//           Container(
//             padding: const EdgeInsets.all(16),
//             color: Colors.amber[50],
//             child: Text(
//               '💡 Instructions:\n'
//                   '1. Cliquez sur "DEBUG COMPLET" pour analyser le problème\n'
//                   '2. Regardez la console Flutter pour les détails\n'
//                   '3. Partagez les résultats pour qu\'on puisse corriger',
//               style: TextStyle(fontSize: 14, color: Colors.amber[800]),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
//
//
//
//
//
//
//
// // // screens/debug_avis_screen.dart
// //
// // import 'package:flutter/material.dart';
// //
// // import 'debug_avis_service.dart';
// //
// // class DebugAvisScreen extends StatefulWidget {
// //   const DebugAvisScreen({Key? key}) : super(key: key);
// //
// //   @override
// //   _DebugAvisScreenState createState() => _DebugAvisScreenState();
// // }
// //
// // class _DebugAvisScreenState extends State<DebugAvisScreen> {
// //   String _debugOutput = "Appuyez sur un bouton pour commencer le debug...";
// //   bool _isLoading = false;
// //
// //   void _runDebugTest(String testName, Future<void> Function() test) async {
// //     setState(() {
// //       _isLoading = true;
// //       _debugOutput = "🔄 Exécution du test: $testName...\n";
// //     });
// //
// //     try {
// //       await test();
// //       setState(() {
// //         _debugOutput += "\n✅ Test terminé avec succès !";
// //         _isLoading = false;
// //       });
// //     } catch (e) {
// //       setState(() {
// //         _debugOutput += "\n❌ Erreur pendant le test: $e";
// //         _isLoading = false;
// //       });
// //     }
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text('🧪 Debug Avis'),
// //         backgroundColor: Colors.red,
// //         foregroundColor: Colors.white,
// //       ),
// //       body: Column(
// //         children: [
// //           // Boutons de test
// //           Container(
// //             padding: EdgeInsets.all(16),
// //             child: Column(
// //               children: [
// //                 Text(
// //                   '🚨 Debug du problème "No TblClient matches"',
// //                   style: TextStyle(
// //                     fontSize: 16,
// //                     fontWeight: FontWeight.bold,
// //                     color: Colors.red[700],
// //                   ),
// //                   textAlign: TextAlign.center,
// //                 ),
// //
// //                 SizedBox(height: 20),
// //
// //                 // Bouton debug complet
// //                 SizedBox(
// //                   width: double.infinity,
// //                   child: ElevatedButton.icon(
// //                     onPressed: _isLoading ? null : () {
// //                       _runDebugTest(
// //                         "Debug Complet",
// //                             () => DebugAvisService.debugComplet(context),
// //                       );
// //                     },
// //                     icon: Icon(Icons.bug_report),
// //                     label: Text('🚨 DEBUG COMPLET'),
// //                     style: ElevatedButton.styleFrom(
// //                       backgroundColor: Colors.red,
// //                       foregroundColor: Colors.white,
// //                       padding: EdgeInsets.symmetric(vertical: 12),
// //                     ),
// //                   ),
// //                 ),
// //
// //                 SizedBox(height: 12),
// //
// //                 // Tests individuels
// //                 Row(
// //                   children: [
// //                     Expanded(
// //                       child: ElevatedButton(
// //                         onPressed: _isLoading ? null : () {
// //                           _runDebugTest(
// //                             "Utilisateur",
// //                                 () => DebugAvisService.debugCurrentUser(context),
// //                           );
// //                         },
// //                         child: Text('👤 User'),
// //                         style: ElevatedButton.styleFrom(
// //                           backgroundColor: Colors.blue,
// //                           foregroundColor: Colors.white,
// //                         ),
// //                       ),
// //                     ),
// //                     SizedBox(width: 8),
// //                     Expanded(
// //                       child: ElevatedButton(
// //                         onPressed: _isLoading ? null : () {
// //                           _runDebugTest(
// //                             "Token",
// //                                 () => DebugAvisService.debugFirebaseToken(),
// //                           );
// //                         },
// //                         child: Text('🔑 Token'),
// //                         style: ElevatedButton.styleFrom(
// //                           backgroundColor: Colors.green,
// //                           foregroundColor: Colors.white,
// //                         ),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //
// //                 SizedBox(height: 8),
// //
// //                 Row(
// //                   children: [
// //                     Expanded(
// //                       child: ElevatedButton(
// //                         onPressed: _isLoading ? null : () {
// //                           _runDebugTest(
// //                             "API Publique",
// //                                 () => DebugAvisService.debugApiPublic(),
// //                           );
// //                         },
// //                         child: Text('🌐 API'),
// //                         style: ElevatedButton.styleFrom(
// //                           backgroundColor: Colors.purple,
// //                           foregroundColor: Colors.white,
// //                         ),
// //                       ),
// //                     ),
// //                     SizedBox(width: 8),
// //                     Expanded(
// //                       child: ElevatedButton(
// //                         onPressed: _isLoading ? null : () {
// //                           _runDebugTest(
// //                             "Mes RDV",
// //                                 () => DebugAvisService.debugApiMesRdv(),
// //                           );
// //                         },
// //                         child: Text('📅 RDV'),
// //                         style: ElevatedButton.styleFrom(
// //                           backgroundColor: Colors.orange,
// //                           foregroundColor: Colors.white,
// //                         ),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ],
// //             ),
// //           ),
// //
// //           // Zone d'affichage des résultats
// //           Expanded(
// //             child: Container(
// //               margin: EdgeInsets.all(16),
// //               padding: EdgeInsets.all(16),
// //               decoration: BoxDecoration(
// //                 color: Colors.grey[100],
// //                 borderRadius: BorderRadius.circular(8),
// //                 border: Border.all(color: Colors.grey[300]!),
// //               ),
// //               child: SingleChildScrollView(
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     Row(
// //                       children: [
// //                         Icon(Icons.terminal, color: Colors.grey[600]),
// //                         SizedBox(width: 8),
// //                         Text(
// //                           'Console Debug',
// //                           style: TextStyle(
// //                             fontWeight: FontWeight.bold,
// //                             fontSize: 16,
// //                           ),
// //                         ),
// //                         Spacer(),
// //                         if (_isLoading)
// //                           SizedBox(
// //                             width: 20,
// //                             height: 20,
// //                             child: CircularProgressIndicator(strokeWidth: 2),
// //                           ),
// //                       ],
// //                     ),
// //
// //                     SizedBox(height: 12),
// //
// //                     Text(
// //                       _debugOutput,
// //                       style: TextStyle(
// //                         fontFamily: 'monospace',
// //                         fontSize: 12,
// //                         color: Colors.black87,
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           ),
// //
// //           // Instructions
// //           Container(
// //             padding: EdgeInsets.all(16),
// //             color: Colors.amber[50],
// //             child: Text(
// //               '💡 Instructions:\n'
// //                   '1. Cliquez sur "DEBUG COMPLET" pour analyser le problème\n'
// //                   '2. Regardez la console Flutter pour les détails\n'
// //                   '3. Partagez les résultats pour qu\'on puisse corriger',
// //               style: TextStyle(
// //                 fontSize: 14,
// //                 color: Colors.amber[800],
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }