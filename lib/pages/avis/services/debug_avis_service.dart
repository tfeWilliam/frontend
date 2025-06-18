// // services/debug_avis_service.dart
//
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
//
// import '../../../services/firebase_token/token_service.dart';
// import '../../../services/providers/current_user_provider.dart';
//
// class DebugAvisService {
//   static const String baseUrl = 'https://www.hairbnb.site/api';
//
//   /// 🧪 1. Vérifier les informations utilisateur actuelles
//   static Future<void> debugCurrentUser(BuildContext context) async {
//     print("\n🧪 === DEBUG UTILISATEUR ACTUEL ===");
//
//     try {
//       final userProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//       final currentUser = userProvider.currentUser;
//
//       if (currentUser != null) {
//         print("✅ Utilisateur connecté:");
//         print("   - Nom: ${currentUser.nom}");
//         print("   - Prénom: ${currentUser.prenom}");
//         print("   - UUID: ${currentUser.uuid}");
//         print("   - Email: ${currentUser.email}");
//         print("   - ID: ${currentUser.idTblUser}");
//       } else {
//         print("❌ Aucun utilisateur connecté dans CurrentUserProvider");
//       }
//     } catch (e) {
//       print("❌ Erreur lors de la récupération de l'utilisateur: $e");
//     }
//   }
//
//   /// 🧪 2. Vérifier le token Firebase
//   static Future<void> debugFirebaseToken() async {
//     print("\n🧪 === DEBUG TOKEN FIREBASE ===");
//
//     try {
//       final token = await TokenService.getAuthToken();
//
//       if (token != null) {
//         print("✅ Token Firebase récupéré:");
//         print("   - Longueur: ${token.length} caractères");
//         print("   - Début: ${token.substring(0, 30)}...");
//         print("   - Fin: ...${token.substring(token.length - 10)}");
//
//         // Décoder le payload du JWT (partie centrale)
//         try {
//           final parts = token.split('.');
//           if (parts.length == 3) {
//             // Décoder le payload (partie du milieu)
//             String payload = parts[1];
//             // Ajouter padding si nécessaire
//             while (payload.length % 4 != 0) {
//               payload += '=';
//             }
//
//             final decoded = utf8.decode(base64Url.decode(payload));
//             final payloadJson = json.decode(decoded);
//
//             print("✅ Payload du token:");
//             print("   - UID: ${payloadJson['uid'] ?? 'N/A'}");
//             print("   - Email: ${payloadJson['email'] ?? 'N/A'}");
//             print("   - Name: ${payloadJson['name'] ?? 'N/A'}");
//             print("   - Exp: ${payloadJson['exp'] ?? 'N/A'}");
//           }
//         } catch (e) {
//           print("⚠️ Impossible de décoder le payload: $e");
//         }
//       } else {
//         print("❌ Aucun token Firebase disponible");
//       }
//     } catch (e) {
//       print("❌ Erreur lors de la récupération du token: $e");
//     }
//   }
//
//   /// 🧪 3. Tester l'API sans authentification (endpoint public)
//   static Future<void> debugApiPublic() async {
//     print("\n🧪 === DEBUG API PUBLIQUE ===");
//
//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl/salon/1/avis/'),
//         headers: {'Content-Type': 'application/json'},
//       );
//
//       print("📡 Test endpoint public: GET $baseUrl/salon/1/avis/");
//       print("📡 Statut: ${response.statusCode}");
//       print("📄 Réponse: ${response.body.substring(0, 200)}...");
//
//       if (response.statusCode == 200 || response.statusCode == 404) {
//         print("✅ API accessible - pas de problème réseau");
//       } else {
//         print("❌ Problème d'accès à l'API");
//       }
//     } catch (e) {
//       print("❌ Erreur test API publique: $e");
//     }
//   }
//
//   /// 🧪 4. Tester l'endpoint problématique avec plus de détails
//   static Future<void> debugApiMesRdv() async {
//     print("\n🧪 === DEBUG API MES RDV ===");
//
//     try {
//       final token = await TokenService.getAuthToken();
//       if (token == null) {
//         print("❌ Pas de token pour le test");
//         return;
//       }
//
//       print("🔄 Test de l'endpoint mes-rdv-avis-en-attente...");
//
//       final response = await http.get(
//         Uri.parse('$baseUrl/mes-rdv-avis-en-attente/'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//       );
//
//       print("📡 Statut: ${response.statusCode}");
//       print("📄 Headers reçus: ${response.headers}");
//       print("📄 Corps complet: ${response.body}");
//
//       if (response.statusCode == 500) {
//         try {
//           final errorJson = json.decode(response.body);
//           print("🔍 Détail erreur:");
//           print("   - Success: ${errorJson['success']}");
//           print("   - Message: ${errorJson['message']}");
//         } catch (e) {
//           print("⚠️ Impossible de parser l'erreur JSON");
//         }
//       }
//     } catch (e) {
//       print("❌ Erreur test API mes RDV: $e");
//     }
//   }
//
//   /// 🧪 5. Test complet de debug
//   static Future<void> debugComplet(BuildContext context) async {
//     print("\n🚨 === DÉBUT DEBUG COMPLET ===");
//
//     await debugCurrentUser(context);
//     await debugFirebaseToken();
//     await debugApiPublic();
//     await debugApiMesRdv();
//
//     print("\n🚨 === FIN DEBUG COMPLET ===");
//   }
// }