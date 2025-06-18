/****************************************************************************************
 *
 * FONCTION DE SERVICE : CONNEXION AVEC GOOGLE
 *
 * OBJECTIF :
 * Cette fonction orchestre le processus complet de connexion et d'inscription d'un
 * utilisateur via son compte Google. Elle gère le dialogue natif de Google,
 * l'authentification auprès de Firebase, et la vérification du profil sur le
 * backend personnalisé de l'application.
 *
 * WORKFLOW DÉTAILLÉ :
 * 1. Déclenche le flux de connexion Google pour obtenir les jetons d'authentification.
 * 2. Utilise ces jetons pour créer un "credential" et authentifier l'utilisateur
 * auprès de Firebase.
 * 3. Récupère le token d'identification Firebase de l'utilisateur nouvellement connecté.
 * 4. Interroge le backend personnalisé pour vérifier si un profil utilisateur existe.
 * 5. Redirige l'utilisateur vers la `HomePage` si le profil existe, ou vers la
 * `ProfileCreationPage` si ce n'est pas le cas.
 * 6. Gère les cas d'annulation par l'utilisateur et les erreurs potentielles à chaque étape.
 *
 *****************************************************************************************/
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hairbnb/pages/profil/profil_creation_page.dart';
import 'package:hairbnb/pages/home_page.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../services/providers/current_user_provider.dart';

/// Gère le processus de connexion complet via un compte Google.
///
/// [context] : Le BuildContext, nécessaire pour la navigation et l'affichage de messages.
/// Retourne un `Future<User?>` contenant l'objet utilisateur Firebase en cas de succès,
/// ou `null` en cas d'annulation ou d'erreur.
Future<User?> loginWithGoogle(BuildContext context) async {
  try {
    // --- ETAPE 1: Initialisation de Google Sign-In ---
    final GoogleSignIn googleSignIn = GoogleSignIn(
      // Le clientId est nécessaire pour l'authentification web.
      clientId: "523426514457-f6gveh52ou52p0glo5g0tjqs3hvegat2.apps.googleusercontent.com",
    );

    // Déconnexion préalable pour garantir une nouvelle authentification fraîche et éviter
    // les problèmes de comptes mis en cache.
    await googleSignIn.signOut();

    // --- ETAPE 2: Lancement de la fenêtre de connexion Google ---
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    // Si googleUser est nul, cela signifie que l'utilisateur a fermé la fenêtre de
    // connexion sans choisir de compte.
    if (googleUser == null) {
      debugPrint("Connexion Google annulée par l'utilisateur.");
      return null;
    }

    // --- ETAPE 3: Création d'un "credential" Firebase à partir des tokens Google ---
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // --- ETAPE 4: Connexion à Firebase avec le "credential" Google ---
    final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    final User? user = userCredential.user;

    // --- ETAPE 5: Vérification de sécurité et récupération du token Firebase ---
    if (user == null || !context.mounted) return null;
    final token = await user.getIdToken();

    // --- ETAPE 6: Vérification de l'existence du profil sur le backend personnalisé ---
    final response = await http.get(
      Uri.parse('https://www.hairbnb.site/api/get_current_user/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    // --- ETAPE 7: Traitement de la réponse du backend et navigation ---
    if (response.statusCode == 200) {
      // Le profil utilisateur existe déjà sur le backend.
      final userProvider = Provider.of<CurrentUserProvider>(context, listen: false);
      await userProvider.fetchCurrentUser(); // Met à jour les données de l'utilisateur dans l'app.

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else if (response.statusCode == 404) {
      // L'utilisateur est authentifié sur Firebase mais n'a pas encore de profil backend.
      // Redirection vers la page de création de profil.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileCreationPage(
            email: user.email ?? '',
            userUuid: user.uid,
          ),
        ),
      );
    } else {
      // Gère les autres codes d'erreur du backend.
      throw Exception("Erreur backend : ${response.statusCode}");
    }

    // Retourne l'objet utilisateur Firebase en cas de succès complet.
    return user;
  } catch (e) {
    // --- ETAPE 8: Gestion des erreurs globales ---
    // Attrape toute exception survenue durant le processus (Google, Firebase, HTTP, etc.).
    debugPrint("Erreur lors de la connexion avec Google : $e");

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de la connexion avec Google.")),
      );
    }

    // Retourne null pour indiquer un échec.
    return null;
  }
}





// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:hairbnb/pages/profil/profil_creation_page.dart';
// import 'package:hairbnb/pages/home_page.dart';
// import 'package:http/http.dart' as http;
// import 'package:provider/provider.dart';
//
// import '../../../services/providers/current_user_provider.dart';
//
// Future<User?> loginWithGoogle(BuildContext context) async {
//   try {
//     final GoogleSignIn googleSignIn = GoogleSignIn(
//       clientId: "523426514457-f6gveh52ou52p0glo5g0tjqs3hvegat2.apps.googleusercontent.com",
//     );
//
//     await googleSignIn.signOut(); // 🧼 déconnexion précédente
//     final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
//
//     if (googleUser == null) {
//       debugPrint("Connexion Google annulée.");
//       return null;
//     }
//
//     final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
//     final credential = GoogleAuthProvider.credential(
//       accessToken: googleAuth.accessToken,
//       idToken: googleAuth.idToken,
//     );
//
//     final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
//     final User? user = userCredential.user;
//
//     if (user == null || !context.mounted) return null;
//
//     final token = await user.getIdToken(); // ✅ token Firebase
//
//     // 🔄 Appel backend sécurisé
//     final response = await http.get(
//       Uri.parse('https://www.hairbnb.site/api/get_current_user/'),
//       headers: {
//         'Authorization': 'Bearer $token',
//         'Content-Type': 'application/json',
//       },
//     );
//
//     if (response.statusCode == 200) {
//       final userProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//       await userProvider.fetchCurrentUser(); // Met à jour le provider
//
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const HomePage()),
//       );
//     } else if (response.statusCode == 404) {
//       // 🔁 User existe pas → aller à la page de création de profil
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (_) => ProfileCreationPage(
//             email: user.email ?? '',
//             userUuid: user.uid,
//           ),
//         ),
//       );
//     } else {
//       throw Exception("Erreur backend : ${response.statusCode}");
//     }
//
//     return user;
//   } catch (e) {
//     debugPrint("❌ Erreur Google Sign-In : $e");
//
//     if (context.mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Erreur lors de la connexion avec Google.")),
//       );
//     }
//
//     return null;
//   }
// }
