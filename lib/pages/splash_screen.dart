/// *************************************************************************************************
///
/// BANNER : EXPLICATION GÉNÉRALE DE L'ÉCRAN DE DÉMARRAGE (SPLASH SCREEN)
///
/// Ce fichier définit `SplashScreen`, un `StatefulWidget` qui est le premier écran
/// affiché au lancement de l'application.
///
/// Objectif :
/// - Fournir une première impression visuelle agréable avec une animation de fondu.
/// - Pendant ce temps, vérifier l'état d'authentification de l'utilisateur via Firebase Auth.
/// - Rediriger l'utilisateur vers la page appropriée :
/// - `LoginPage` si l'utilisateur n'est pas connecté.
/// - `HomePage` si l'utilisateur est déjà connecté.
/// - Gérer le chargement initial des données de l'utilisateur connecté via un Provider.
///
/// Fonctionnement :
/// 1.  `initState` lance une animation et une temporisation.
/// 2.  Après une courte temporisation, il s'abonne aux changements d'état d'authentification
/// de Firebase (`authStateChanges`).
/// 3.  En fonction de la présence d'un utilisateur, il déclenche la navigation.
/// 4.  Si un utilisateur est trouvé, il tente de charger son profil complet avant de
/// naviguer vers la page d'accueil. En cas d'échec, il déconnecte l'utilisateur
/// pour éviter un état incohérent.
/// 5.  `dispose` nettoie les ressources (écouteur d'authentification, contrôleur d'animation)
/// pour éviter les fuites de mémoire.
///
///*************************************************************************************************
library;

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hairbnb/pages/home_page.dart';
import 'package:hairbnb/pages/authentification/login_page.dart';
import 'package:hairbnb/services/providers/current_user_provider.dart';
import 'package:provider/provider.dart';

/// Un widget qui sert d'écran de démarrage pour l'application.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

/// La classe d'état pour `SplashScreen`.
/// Le `SingleTickerProviderStateMixin` est nécessaire pour le `AnimationController`.
class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  // Abonnement au flux d'authentification de Firebase pour être notifié des changements.
  StreamSubscription<User?>? _authSubscription;
  // Contrôleur pour gérer la durée et l'état de l'animation.
  late AnimationController _animationController;
  // Animation de fondu (opacité) contrôlée par `_animationController`.
  late Animation<double> _fadeAnimation;


  @override
  void initState() {
    super.initState();

    // Initialise et démarre l'animation.
    _setupAnimation();
    // Lance la logique de navigation après une courte temporisation.
    _navigateAfterDelay();
  }

  /// Configure et démarre l'animation de fondu.
  void _setupAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.forward(); // Lance l'animation.
  }

  /// Gère la redirection de l'utilisateur après un délai.
  Future<void> _navigateAfterDelay() async {
    // Attend 2 secondes, le temps que l'animation de fondu se termine.
    await Future.delayed(const Duration(seconds: 2));

    // S'abonne aux changements d'état d'authentification.
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      // S'assure que le widget est toujours "monté" (affiché) avant de naviguer.
      if (!mounted) return;

      if (user == null) {
        // Si aucun utilisateur n'est connecté, redirige vers la page de connexion.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } else {
        // Si un utilisateur est connecté, tente de charger ses données complètes.
        final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
        try {
          // Appelle le provider pour récupérer les informations de l'utilisateur depuis le backend.
          await currentUserProvider.fetchCurrentUser();

          // Une fois les données chargées, redirige vers la page d'accueil.
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } catch (e) {
          // En cas d'erreur (ex: profil non trouvé dans la base de données), on gère le cas.
          debugPrint("Erreur lors de fetchCurrentUser: $e");
          if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Erreur de chargement de votre profil.")),
            );
          }
          // Déconnecte l'utilisateur de Firebase pour éviter de rester dans un état invalide.
          FirebaseAuth.instance.signOut();
        }
      }
    });
  }

  @override
  void dispose() {
    // Annule l'abonnement au flux d'authentification pour éviter les fuites de mémoire.
    _authSubscription?.cancel();
    // Libère les ressources du contrôleur d'animation.
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        // Utilise FadeTransition pour appliquer l'animation de fondu à son enfant.
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Interface simple de l'écran de démarrage.
              const Icon(Icons.cut, size: 80),
              const SizedBox(height: 20),
              const Text(
                "Hairbnb",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const CircularProgressIndicator(), // Indicateur de chargement.
            ],
          ),
        ),
      ),
    );
  }
}








// // lib/pages/splash_screen.dart
//
// import 'dart:async';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:hairbnb/pages/home_page.dart';
// import 'package:hairbnb/pages/authentification/login_page.dart';
// import 'package:hairbnb/services/providers/current_user_provider.dart';
// import 'package:provider/provider.dart';
//
// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});
//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
//   StreamSubscription<User?>? _authSubscription;
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
//
//
//   @override
//   void initState() {
//     super.initState();
//
//     _setupAnimation();
//     _navigateAfterDelay();
//   }
//
//   void _setupAnimation() {
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 2),
//     );
//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
//     _animationController.forward(); // Démarre l'animation dès le début
//   }
//
//   Future<void> _navigateAfterDelay() async {
//     await Future.delayed(const Duration(seconds: 2)); // Laisse l'animation jouer
//     _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) async {
//       if (!mounted) return;
//       if (user == null) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => const LoginPage()),
//         );
//       } else {
//         final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//         try {
//           await currentUserProvider.fetchCurrentUser();
//
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (context) => const HomePage()),
//           );
//         } catch (e) {
//           debugPrint("Erreur lors de fetchCurrentUser: $e");
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("Erreur de chargement de l'utilisateur")),
//           );
//           FirebaseAuth.instance.signOut();
//         }
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     _authSubscription?.cancel();
//     _animationController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: FadeTransition(
//           opacity: _fadeAnimation,
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(Icons.cut, size: 80),
//               const SizedBox(height: 20),
//               const Text(
//                 "Hairbnb",
//                 style: TextStyle(
//                   fontSize: 28,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 10),
//               const CircularProgressIndicator(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
