/// **************************************************************************************
///
/// FONCTION DE SERVICE : CONNEXION PAR EMAIL
/// Fichier: authentification_services_pages/login_with_email.dart
///
/// OBJECTIF :
/// Cette fonction orchestre le workflow complet de connexion d'un utilisateur.
/// Elle ne se contente pas d'authentifier l'utilisateur auprès de Firebase, mais gère
/// également la logique métier post-authentification.
///
/// WORKFLOW DÉTAILLÉ :
/// 1. Tente de connecter l'utilisateur via Firebase Auth.
/// 2. Vérifie si l'email de l'utilisateur a été validé.
/// 3. Si l'email est validé, récupère le token d'authentification Firebase.
/// 4. Interroge le backend personnalisé (Django) pour savoir si un profil utilisateur
/// existe déjà pour cet utilisateur.
/// 5. Redirige l'utilisateur vers la page appropriée en fonction du résultat :
/// - `HomePage` : si le profil existe.
/// - `ProfileCreationPage` : si le profil n'existe pas.
/// - `EmailNotVerifiedPage` : si l'email n'est pas encore vérifié.
/// 6. Gère les erreurs de manière structurée (erreurs Firebase, erreurs réseau/serveur).
///
///***************************************************************************************
library;

// Importations nécessaires pour Flutter, Firebase, HTTP et la gestion d'état.
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:hairbnb/pages/home_page.dart';
import '../../../services/providers/current_user_provider.dart';
import '../../profil/profil_creation_page.dart';
import 'email_not_verified.dart';

/// Gère le processus complet de connexion d'un utilisateur, de l'authentification
/// Firebase à la vérification du profil sur le backend.
///
/// [context] : Le BuildContext, nécessaire pour la navigation et l'affichage de messages (SnackBar).
/// [email] : L'email de l'utilisateur pour la connexion.
/// [password] : Le mot de passe de l'utilisateur.
/// [emailController] & [passwordController] : (Optionnels) Passés pour référence, mais leur
/// gestion (ex: vider les champs) doit être effectuée par la fonction appelante.
///
/// Retourne `true` si l'authentification Firebase est réussie et que l'utilisateur est
/// redirigé soit vers la page d'accueil, soit vers la création de profil.
/// Retourne `false` en cas d'échec d'authentification ou si l'email n'est pas vérifié.
Future<bool> loginWithEmail(
    BuildContext context,
    String email,
    String password, {
      TextEditingController? emailController,
      TextEditingController? passwordController,
    }) async {
  try {
    // --- ETAPE 1: Authentification auprès de Firebase ---
    final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = userCredential.user;

    // --- ETAPE 2: Vérification de la validité du contexte et de l'objet utilisateur ---
    // Sécurité pour éviter d'exécuter du code UI si le widget a été retiré de l'arbre.
    if (!context.mounted || user == null) {
      return false;
    }

    // --- ETAPE 3: Vérification de la validation de l'email de l'utilisateur ---
    final creationTime = user.metadata.creationTime;
    // Crée une exception pour les comptes anciens qui n'avaient pas de vérification d'email.
    final allowBypass = creationTime != null && creationTime.isBefore(DateTime(2025, 4, 10));

    if (!user.emailVerified && !allowBypass) {
      // Si l'email n'est pas vérifié (et que le compte n'est pas exempté), redirige
      // vers la page invitant à vérifier l'email.
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => EmailNotVerifiedPage(email: user.email!),
          ),
        );
      }
      return false; // Interrompt le flux de connexion.
    }

    // --- ETAPE 4: Récupération du token d'authentification pour l'API backend ---
    final token = await user.getIdToken();

    // --- ETAPE 5: Vérification de l'existence du profil sur le backend personnalisé ---
    final response = await http.get(
      Uri.parse('https://www.hairbnb.site/api/get_current_user/'),
      headers: {
        'Authorization': 'Bearer $token', // Le token prouve l'identité de l'utilisateur.
        'Content-Type': 'application/json',
      },
    );

    // --- ETAPE 6: Traitement de la réponse du backend ---
    if (response.statusCode == 200) {
      // Cas 1 (Succès) : Le profil existe sur le backend.
      if (context.mounted) {
        // Met à jour les données de l'utilisateur dans l'application via le Provider.
        final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
        await currentUserProvider.fetchCurrentUser();

        // Redirige vers la page d'accueil.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
      return true;
    } else if (response.statusCode == 404) {
      // Cas 2 (Action requise) : Le profil n'existe pas sur le backend.
      if (context.mounted) {
        // Redirige vers la page de création de profil en passant les infos Firebase.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileCreationPage(
              email: user.email ?? '',
              userUuid: user.uid,
            ),
          ),
        );
      }
      return true;
    } else {
      // Cas 3 (Erreur) : Le serveur a retourné une autre erreur.
      throw Exception('Erreur du serveur (${response.statusCode})');
    }
  } on FirebaseAuthException catch (e) {
    // --- ETAPE 7: Gestion des erreurs spécifiques à Firebase Authentication ---
    // Traduit les codes d'erreur Firebase en messages clairs pour l'utilisateur.
    final message = switch (e.code) {
      'user-not-found' => "Aucun utilisateur trouvé avec cet email.",
      'wrong-password' => "Mot de passe incorrect.",
      'invalid-credential' => "Identifiants invalides. Vérifiez votre email et mot de passe.",
      _ => "Erreur d'authentification : ${e.message}",
    };

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
    return false;
  } catch (e) {
    // --- ETAPE 8: Gestion des erreurs génériques (réseau, serveur, etc.) ---
    debugPrint("Erreur inconnue dans loginWithEmail: $e");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Une erreur inattendue s'est produite : ${e.toString()}")),
      );
    }
    return false;
  }
}








// // authentification_services_pages/login_with_email.dart
//
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:http/http.dart' as http;
// import 'package:provider/provider.dart';
// import 'package:hairbnb/pages/home_page.dart'; // Page d'accueil après connexion réussie
//
// import '../../../services/providers/current_user_provider.dart'; // Fournisseur de données de l'utilisateur actuel
// import '../../profil/profil_creation_page.dart'; // Page de création de profil si l'utilisateur n'existe pas sur le backend
// import 'email_not_verified.dart'; // Page pour les utilisateurs dont l'email n'est pas vérifié
//
// /// Fonction asynchrone qui tente de connecter un utilisateur avec son email et mot de passe.
// /// Elle retourne un `Future<bool>`:
// /// - `true` si la connexion et la vérification du profil backend sont réussies (ou redirigent vers la création de profil).
// /// - `false` si l'authentification échoue, si l'email n'est pas vérifié (et qu'il n'y a pas de bypass), ou en cas d'erreur inattendue.
// ///
// /// [context] : Le BuildContext de l'interface utilisateur, nécessaire pour la navigation et l'affichage de SnackBar.
// /// [email] : L'email de l'utilisateur.
// /// [password] : Le mot de passe de l'utilisateur.
// /// [emailController] : (Optionnel) Contrôleur pour le champ email, utilisé pour le nettoyage des champs (géré ailleurs).
// /// [passwordController] : (Optionnel) Contrôleur pour le champ mot de passe, utilisé pour le nettoyage des champs (géré ailleurs).
// Future<bool> loginWithEmail(
//     BuildContext context,
//     String email,
//     String password, {
//       TextEditingController? emailController,
//       TextEditingController? passwordController,
//     }) async {
//   try {
//     // 1. Tente de se connecter à Firebase avec l'email et le mot de passe fournis.
//     // Si les identifiants sont corrects, Firebase retourne un UserCredential.
//     final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
//       email: email,
//       password: password,
//     );
//
//     // Récupère l'objet User à partir des identifiants de connexion.
//     final user = userCredential.user;
//
//     // 2. Vérification de l'état du contexte et de l'utilisateur.
//     // Il est crucial de vérifier si le widget est toujours monté (`context.mounted`)
//     // avant d'effectuer des opérations liées à l'interface utilisateur (comme la navigation),
//     // et si l'objet `user` n'est pas nul.
//     if (!context.mounted || user == null) {
//       // Si une de ces conditions n'est pas remplie, on considère que la connexion a échoué.
//       return false;
//     }
//
//     // IMPORTANT : L'effacement des champs (email et mot de passe)
//     // a été déplacé vers la fonction appelante (`_handleLogin` dans `LoginPage`).
//     // Cela garantit que les champs ne sont effacés qu'après une confirmation de succès
//     // et que la navigation a été initiée.
//     // emailController?.clear(); // Ligne supprimée d'ici
//     // passwordController?.clear(); // Ligne supprimée d'ici
//
//     // 3. Vérification de la vérification de l'email.
//     // Cette section gère si l'utilisateur a vérifié son adresse email.
//     final creationTime = user.metadata.creationTime;
//     // Une condition `allowBypass` est mise en place pour permettre aux anciens comptes
//     // (créés avant le 10 avril 2025) de contourner la vérification de l'email.
//     final allowBypass = creationTime != null && creationTime.isBefore(DateTime(2025, 4, 10));
//
//     if (!user.emailVerified && !allowBypass) {
//       // Si l'email n'est pas vérifié ET qu'il n'y a pas de bypass,
//       // l'utilisateur est redirigé vers la page de vérification d'email.
//       if (context.mounted) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (_) => EmailNotVerifiedPage(email: user.email!),
//           ),
//         );
//       }
//       // On retourne `false` car le processus de connexion normal est interrompu,
//       // l'utilisateur doit d'abord vérifier son email.
//       return false;
//     }
//
//     // 4. Récupération du token d'authentification Firebase.
//     // Ce token est nécessaire pour authentifier les requêtes auprès de votre backend Django.
//     final token = await user.getIdToken();
//
//     // 5. Vérification de l'existence du profil de l'utilisateur sur le backend Django.
//     // Une requête GET est envoyée à l'API de votre site Hairbnb pour obtenir les informations de l'utilisateur.
//     final response = await http.get(
//       Uri.parse('https://www.hairbnb.site/api/get_current_user/'),
//       headers: {
//         'Authorization': 'Bearer $token', // Le token Firebase est inclus dans les en-têtes d'autorisation.
//         'Content-Type': 'application/json',
//       },
//     );
//
//     // 6. Gestion des réponses du backend Django.
//     if (response.statusCode == 200) {
//       // ✅ Cas 1 : L'utilisateur existe déjà dans la base de données Django.
//       // Il peut être redirigé vers la page d'accueil de l'application.
//       if (context.mounted) {
//         // Met à jour les informations de l'utilisateur courant via le CurrentUserProvider.
//         final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//         await currentUserProvider.fetchCurrentUser();
//
//         // Redirige l'utilisateur vers la page d'accueil (`HomePage`).
//         // `pushReplacement` est utilisé pour empêcher l'utilisateur de revenir à la page de connexion
//         // en appuyant sur le bouton retour.
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (_) => const HomePage()),
//         );
//       }
//       // Indique une connexion réussie et une navigation vers la HomePage.
//       return true;
//     } else if (response.statusCode == 404) {
//       // ❌ Cas 2 : L'utilisateur n'a pas encore de profil créé dans Django.
//       // Il est redirigé vers la page de création de profil.
//       if (context.mounted) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (_) => ProfileCreationPage(
//               email: user.email ?? '', // Passe l'email de l'utilisateur
//               userUuid: user.uid, // Passe l'ID unique de l'utilisateur Firebase
//             ),
//           ),
//         );
//       }
//       // Indique une connexion Firebase réussie, mais l'utilisateur doit compléter son profil.
//       return true;
//     } else {
//       // Cas 3 : Toute autre erreur de statut HTTP du serveur backend.
//       // Lance une exception avec le code d'erreur du serveur.
//       throw Exception('Erreur du serveur (${response.statusCode})');
//     }
//   } on FirebaseAuthException catch (e) {
//     // 7. Gestion des erreurs spécifiques à Firebase Authentication.
//     // Le code d'erreur Firebase (`e.code`) est utilisé pour fournir des messages plus précis à l'utilisateur.
//     final message = switch (e.code) {
//       'user-not-found' => "Aucun utilisateur trouvé avec cet email.",
//       'wrong-password' => "Mot de passe incorrect.",
//       'invalid-credential' => "Identifiants invalides. Vérifiez votre email et mot de passe.", // Message plus générique pour des raisons de sécurité
//       _ => "Erreur d'authentification : ${e.message}", // Message par défaut pour les autres erreurs
//     };
//
//     // Affiche un SnackBar en bas de l'écran avec le message d'erreur.
//     if (context.mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
//     }
//     // Indique un échec d'authentification Firebase.
//     return false;
//   } catch (e) {
//     // 8. Gestion des erreurs générales ou inattendues.
//     // Cela inclut les erreurs réseau, les erreurs de parsing JSON, ou toute autre exception non gérée.
//     debugPrint("Erreur inconnue : $e"); // Affiche l'erreur dans la console de débogage.
//
//     // Affiche un SnackBar pour informer l'utilisateur qu'une erreur inattendue s'est produite.
//     if (context.mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Une erreur inattendue s'est produite : ${e.toString()}")),
//       );
//     }
//     // Indique un échec général du processus de connexion.
//     return false;
//   }
// }
//
//
//
//
//
// // // authentification_services_pages/login_with_email.dart
// // import 'package:flutter/material.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:provider/provider.dart';
// // import 'package:hairbnb/pages/home_page.dart';
// //
// // import '../../../services/providers/current_user_provider.dart';
// // import '../../profil/profil_creation_page.dart';
// // import 'email_not_verified.dart';
// //
// // Future<bool> loginWithEmail(
// //     BuildContext context,
// //     String email,
// //     String password, {
// //       TextEditingController? emailController,
// //       TextEditingController? passwordController,
// //     }) async {
// //   try {
// //     final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
// //       email: email,
// //       password: password,
// //     );
// //
// //     final user = userCredential.user;
// //     if (!context.mounted || user == null) {
// //       // Si le contexte n'est plus monté ou l'utilisateur est nul, considérer comme un échec
// //       return false;
// //     }
// //
// //     // IMPORTANT : L'effacement des champs est maintenant géré dans _handleLogin dans LoginPage.
// //     // emailController?.clear(); // Supprimé d'ici
// //     // passwordController?.clear(); // Supprimé d'ici
// //
// //     // ✅ Email vérifié ?
// //     final creationTime = user.metadata.creationTime;
// //     final allowBypass = creationTime != null && creationTime.isBefore(DateTime(2025, 4, 10));
// //
// //     if (!user.emailVerified && !allowBypass) {
// //       if (context.mounted) {
// //         Navigator.pushReplacement(
// //           context,
// //           MaterialPageRoute(
// //             builder: (_) => EmailNotVerifiedPage(email: user.email!),
// //           ),
// //         );
// //       }
// //       // Indique que le flux de connexion a été interrompu pour la vérification de l'email
// //       return false;
// //     }
// //
// //     // ✅ Récupérer le token Firebase
// //     final token = await user.getIdToken();
// //
// //     // ✅ Vérifier sur le backend si le profil existe
// //     final response = await http.get(
// //       Uri.parse('https://www.hairbnb.site/api/get_current_user/'),
// //       headers: {
// //         'Authorization': 'Bearer $token',
// //         'Content-Type': 'application/json',
// //       },
// //     );
// //
// //     if (response.statusCode == 200) {
// //       // ✅ L'utilisateur existe dans Django → Aller à la HomePage
// //       if (context.mounted) {
// //         final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
// //         await currentUserProvider.fetchCurrentUser();
// //
// //         Navigator.pushReplacement(
// //           context,
// //           MaterialPageRoute(builder: (_) => const HomePage()),
// //         );
// //       }
// //       // Indique une connexion réussie et une navigation vers la HomePage
// //       return true;
// //     } else if (response.statusCode == 404) {
// //       // ❌ L'utilisateur n'est pas encore créé dans Django → Aller à ProfileCreationPage
// //       if (context.mounted) {
// //         Navigator.pushReplacement(
// //           context,
// //           MaterialPageRoute(
// //             builder: (_) => ProfileCreationPage(
// //               email: user.email ?? '',
// //               userUuid: user.uid,
// //             ),
// //           ),
// //         );
// //       }
// //       // Indique une connexion réussie, mais l'utilisateur doit créer son profil
// //       return true;
// //     } else {
// //       // Gérer les autres erreurs de serveur
// //       throw Exception('Erreur du serveur (${response.statusCode})');
// //     }
// //   } on FirebaseAuthException catch (e) {
// //     final message = switch (e.code) {
// //       'user-not-found' => "Aucun utilisateur trouvé avec cet email.",
// //       'wrong-password' => "Mot de passe incorrect.",
// //       'invalid-credential' => "Identifiants invalides. Vérifiez votre email et mot de passe.", // Message plus générique pour la sécurité
// //       _ => "Erreur d'authentification : ${e.message}",
// //     };
// //
// //     if (context.mounted) {
// //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
// //     }
// //     // Indique un échec d'authentification
// //     return false;
// //   } catch (e) {
// //     debugPrint("Erreur inconnue : $e");
// //
// //     if (context.mounted) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text("Une erreur inattendue s'est produite : ${e.toString()}")),
// //       );
// //     }
// //     // Indique une erreur générale
// //     return false;
// //   }
// // }
//
//
//
//
//
//
//
//
//
//
//
//
//
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:provider/provider.dart';
// // import 'package:hairbnb/pages/home_page.dart';
// // import 'package:hairbnb/pages/profil/profil_creation_page.dart';
// // import '../../../services/providers/current_user_provider.dart';
// // import 'email_not_verified.dart';
// //
// // Future<void> loginWithEmail(
// //     BuildContext context,
// //     String email,
// //     String password, {
// //       TextEditingController? emailController,
// //       TextEditingController? passwordController,
// //     }) async {
// //   try {
// //     final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
// //       email: email,
// //       password: password,
// //     );
// //
// //     final user = userCredential.user;
// //     if (!context.mounted || user == null) return;
// //
// //     // Nettoyer les champs
// //     emailController?.clear();
// //     passwordController?.clear();
// //
// //     // ✅ Email vérifié ?
// //     final creationTime = user.metadata.creationTime;
// //     final allowBypass = creationTime != null && creationTime.isBefore(DateTime(2025, 4, 10));
// //
// //     if (!user.emailVerified && !allowBypass) {
// //       Navigator.pushReplacement(
// //         context,
// //         MaterialPageRoute(
// //           builder: (_) => EmailNotVerifiedPage(email: user.email!),
// //         ),
// //       );
// //       return;
// //     }
// //
// //     // ✅ Récupérer le token Firebase
// //     final token = await user.getIdToken();
// //
// //     // ✅ Vérifier sur le backend si le profil existe
// //     final response = await http.get(
// //       Uri.parse('https://www.hairbnb.site/api/get_current_user/'),
// //       headers: {
// //         'Authorization': 'Bearer $token',
// //         'Content-Type': 'application/json',
// //       },
// //     );
// //
// //     if (response.statusCode == 200) {
// //       // ✅ User existe dans Django → Aller à la HomePage
// //       final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
// //       await currentUserProvider.fetchCurrentUser();
// //
// //       Navigator.pushReplacement(
// //         context,
// //         MaterialPageRoute(builder: (_) => const HomePage()),
// //       );
// //     } else if (response.statusCode == 404) {
// //       // ❌ User pas encore créé dans Django → Aller à ProfileCreationPage
// //       Navigator.pushReplacement(
// //         context,
// //         MaterialPageRoute(
// //           builder: (_) => ProfileCreationPage(
// //             email: user.email ?? '',
// //             userUuid: user.uid,
// //           ),
// //         ),
// //       );
// //     } else {
// //       throw Exception('Erreur du serveur (${response.statusCode})');
// //     }
// //   } on FirebaseAuthException catch (e) {
// //     final message = switch (e.code) {
// //       'user-not-found' => "Aucun utilisateur trouvé avec cet email.",
// //       'wrong-password' => "Mot de passe incorrect.",
// //       _ => "Erreur : ${e.message}",
// //     };
// //
// //     if (context.mounted) {
// //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
// //     }
// //   } catch (e) {
// //     debugPrint("Erreur inconnue : $e");
// //
// //     if (context.mounted) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text("Une erreur inattendue s'est produite.")),
// //       );
// //     }
// //   }
// // }
// //
// //
// //
// //
// //
// //
// //
// //
// //
// // //-------------------------------Avant firebase auth-------------------------------
// // // import 'package:firebase_auth/firebase_auth.dart';
// // // import 'package:flutter/material.dart';
// // // import 'package:provider/provider.dart';
// // // import 'package:hairbnb/pages/home_page.dart';
// // // import 'package:hairbnb/pages/profil/profil_creation_page.dart';
// // // import '../../../services/providers/current_user_provider.dart';
// // // import 'email_not_verified.dart';
// // //
// // // Future<void> loginWithEmail(
// // //     BuildContext context,
// // //     String email,
// // //     String password, {
// // //       TextEditingController? emailController,
// // //       TextEditingController? passwordController,
// // //     }) async {
// // //   try {
// // //     final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
// // //       email: email,
// // //       password: password,
// // //     );
// // //
// // //     final user = userCredential.user;
// // //
// // //     if (!context.mounted || user == null) return;
// // //
// // //     // Nettoyer les champs si fournis
// // //     emailController?.clear();
// // //     passwordController?.clear();
// // //
// // //     // ✅ Autoriser les anciens comptes sans vérification
// // //     final creationTime = user.metadata.creationTime;
// // //     final allowBypass = creationTime != null &&
// // //         creationTime.isBefore(DateTime(2025, 4, 10));
// // //
// // //     if (!user.emailVerified && !allowBypass) {
// // //       Navigator.pushReplacement(
// // //         context,
// // //         MaterialPageRoute(
// // //           builder: (_) => EmailNotVerifiedPage(email: user.email!),
// // //         ),
// // //       );
// // //       return;
// // //     }
// // //
// // //     // ✅ Charger le profil depuis le provider
// // //     final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
// // //     await currentUserProvider.fetchCurrentUser();
// // //
// // //     final hasProfile = currentUserProvider.currentUser != null;
// // //
// // //     if (hasProfile) {
// // //       Navigator.pushReplacement(
// // //         context,
// // //         MaterialPageRoute(builder: (_) => const HomePage()),
// // //       );
// // //     } else {
// // //       Navigator.pushReplacement(
// // //         context,
// // //         MaterialPageRoute(
// // //           builder: (_) => ProfileCreationPage(
// // //             email: user.email ?? '',
// // //             userUuid: user.uid,
// // //           ),
// // //         ),
// // //       );
// // //     }
// // //   } on FirebaseAuthException catch (e) {
// // //     final message = switch (e.code) {
// // //       'user-not-found' => "Aucun utilisateur trouvé avec cet email.",
// // //       'wrong-password' => "Mot de passe incorrect.",
// // //       _ => "Erreur : ${e.message}",
// // //     };
// // //
// // //     if (context.mounted) {
// // //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
// // //     }
// // //   } catch (e) {
// // //     debugPrint("Erreur inconnue : $e");
// // //
// // //     if (context.mounted) {
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         const SnackBar(content: Text("Une erreur inattendue s'est produite.")),
// // //       );
// // //     }
// // //   }
// // // }