////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                SERVICE CENTRALISÉ POUR LES OPÉRATIONS FIREBASE               //
//                                                                            //
//  Ce fichier définit `FirebaseService`, une classe qui sert de point d'accès//
//  unique et centralisé pour toutes les interactions avec Firebase, en       //
//  particulier Firebase Authentication.                                      //
//                                                                            //
//  Principales caractéristiques :                                            //
//  - Implémente le pattern Singleton pour garantir une seule instance dans   //
//    toute l'application.                                                    //
//  - Gère de manière robuste l'initialisation asynchrone de Firebase, qui    //
//    est un cas de figure important pour les plateformes web.                //
//  - Agit comme une façade (wrapper) autour de `FirebaseAuth`, simplifiant   //
//    les appels et masquant la complexité de l'initialisation.               //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Une classe de service qui centralise et gère les interactions avec Firebase.
class FirebaseService {
  //region Implémentation du Singleton
  // L'instance unique et privée de la classe.
  static final FirebaseService _instance = FirebaseService._internal();

  // Le factory constructor retourne toujours la même instance `_instance`.
  factory FirebaseService() => _instance;

  // Le constructeur interne privé, utilisé une seule fois pour créer l'instance.
  FirebaseService._internal();
  //endregion

  //region Gestion de l'état d'initialisation
  /// Un booléen privé pour suivre l'état d'initialisation de Firebase.
  /// Sur mobile (`!kIsWeb`), on considère Firebase comme initialisé immédiatement.
  /// Sur le web, l'initialisation est asynchrone et doit être confirmée.
  bool _isInitialized = !kIsWeb;

  /// Getter public pour vérifier si Firebase est initialisé.
  bool get isInitialized => _isInitialized;

  /// Méthode pour attendre l'initialisation de Firebase, cruciale pour le web.
  ///
  /// Sur mobile, cette méthode retourne immédiatement `true`. Sur le web, elle
  /// attend que le flag `_isInitialized` devienne `true`, avec un timeout
  /// pour éviter une attente infinie.
  Future<bool> waitForInitialization() async {
    // Retourne immédiatement si ce n'est pas le web ou si c'est déjà initialisé.
    if (!kIsWeb || _isInitialized) {
      return true;
    }

    // Boucle d'attente pour la plateforme web.
    int attempts = 0;
    while (!_isInitialized && attempts < 50) { // Timeout après ~5 secondes
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    return _isInitialized;
  }

  /// Méthode à appeler depuis l'extérieur (ex: `main.dart`) une fois que
  /// l'initialisation de Firebase est terminée.
  void setInitialized() {
    _isInitialized = true;
  }
  //endregion

  //region Méthodes Wrapper pour Firebase Auth

  /// Connecte un utilisateur avec son e-mail et son mot de passe.
  ///
  /// Attend que Firebase soit initialisé avant de tenter la connexion.
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    // S'assure que Firebase est prêt avant de faire l'appel.
    await waitForInitialization();
    // Délègue l'appel à l'instance de FirebaseAuth.
    return FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Récupère l'objet de l'utilisateur actuellement connecté.
  ///
  /// Attend que Firebase soit initialisé avant de faire l'appel.
  Future<User?> getCurrentUser() async {
    await waitForInitialization();
    return FirebaseAuth.instance.currentUser;
  }

  /// Déconnecte l'utilisateur actuellement authentifié.
  ///
  /// Attend que Firebase soit initialisé avant de faire l'appel.
  Future<void> signOut() async {
    await waitForInitialization();
    return FirebaseAuth.instance.signOut();
  }
//endregion
}









// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/foundation.dart';
//
// class FirebaseService {
//   // Singleton pattern
//   static final FirebaseService _instance = FirebaseService._internal();
//   factory FirebaseService() => _instance;
//   FirebaseService._internal();
//
//   // État de l'initialisation
//   bool get isInitialized => _isInitialized;
//   bool _isInitialized = !kIsWeb; // Déjà initialisé pour mobile
//
//   // Méthode pour vérifier si Firebase est initialisé (pour le web)
//   Future<bool> waitForInitialization() async {
//     // Si on est sur mobile ou si Firebase est déjà initialisé, on retourne immédiatement
//     if (!kIsWeb || _isInitialized) {
//       return true;
//     }
//
//     // Sur le web, on attend au maximum 5 secondes pour l'initialisation
//     int attempts = 0;
//     while (!_isInitialized && attempts < 50) {
//       await Future.delayed(const Duration(milliseconds: 100));
//       attempts++;
//     }
//
//     return _isInitialized;
//   }
//
//   // Méthode appelée quand Firebase est initialisé
//   void setInitialized() {
//     _isInitialized = true;
//   }
//
//   // Méthode pour se connecter qui vérifie d'abord l'initialisation
//   Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
//     await waitForInitialization();
//     return FirebaseAuth.instance.signInWithEmailAndPassword(
//       email: email,
//       password: password,
//     );
//   }
//
//   // Autres méthodes Firebase qui nécessitent l'initialisation
//   Future<User?> getCurrentUser() async {
//     await waitForInitialization();
//     return FirebaseAuth.instance.currentUser;
//   }
//
//   Future<void> signOut() async {
//     await waitForInitialization();
//     return FirebaseAuth.instance.signOut();
//   }
//
// }