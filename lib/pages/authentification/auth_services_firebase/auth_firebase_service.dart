/// **************************************************************************************
///
/// SERVICE D'AUTHENTIFICATION : FIREBASE AUTH
///
/// OBJECTIF :
/// Cette classe est une couche de service qui encapsule et centralise toutes les
/// interactions avec le service Firebase Authentication. Elle fournit une interface
/// simple et réutilisable pour gérer le cycle de vie de l'authentification de
/// l'utilisateur au sein de l'application.
///
/// FONCTIONNALITÉS CLÉS :
/// - Gère l'inscription de nouveaux utilisateurs avec email et mot de passe.
/// - Gère la connexion des utilisateurs existants.
/// - Fournit une méthode de déconnexion.
/// - Permet de récupérer le jeton d'identification (ID Token) de l'utilisateur
/// actuellement connecté, utile pour authentifier des appels vers un backend.
///
///***************************************************************************************
library;
import 'package:firebase_auth/firebase_auth.dart';

/// Classe de service qui centralise la logique d'authentification avec Firebase.
class AuthService {
  /// Instance privée de FirebaseAuth pour interagir avec le service Firebase.
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Inscrit un nouvel utilisateur avec une adresse email et un mot de passe.
  ///
  /// [email] : L'email du nouvel utilisateur.
  /// [password] : Le mot de passe du nouvel utilisateur.
  /// Retourne un `Future<UserCredential>` en cas de succès.
  /// Lance une [Exception] si l'inscription échoue (ex: email déjà utilisé, mot de passe faible).
  Future<UserCredential> registerWithEmail(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Erreur lors de l’inscription : $e');
    }
  }

  /// Connecte un utilisateur existant avec son email et son mot de passe.
  ///
  /// [email] : L'email de l'utilisateur.
  /// [password] : Le mot de passe de l'utilisateur.
  /// Retourne un `Future<UserCredential>` en cas de succès.
  /// Lance une [Exception] si la connexion échoue (ex: mauvais mot de passe, utilisateur non trouvé).
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Erreur lors de la connexion : $e');
    }
  }

  /// Déconnecte l'utilisateur actuellement authentifié sur l'appareil.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Récupère le jeton d'identification (ID token) Firebase de l'utilisateur actuel.
  /// Ce token est généralement utilisé pour authentifier les requêtes auprès d'un backend personnalisé.
  ///
  /// Retourne un `Future<String?>` contenant le token, ou `null` si aucun utilisateur n'est connecté.
  Future<String?> getIdToken() async {
    final user = _auth.currentUser;
    return user != null ? await user.getIdToken() : null;
  }
}







// import 'package:firebase_auth/firebase_auth.dart';
//
// class AuthService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//
//   // Inscription
//   Future<UserCredential> registerWithEmail(String email, String password) async {
//     try {
//       return await _auth.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//     } catch (e) {
//       throw Exception('Erreur lors de l’inscription : $e');
//     }
//   }
//
//   // Connexion
//   Future<UserCredential> signInWithEmail(String email, String password) async {
//     try {
//       return await _auth.signInWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//     } catch (e) {
//       throw Exception('Erreur lors de la connexion : $e');
//     }
//   }
//
//   // Déconnexion
//   Future<void> signOut() async {
//     await _auth.signOut();
//   }
//
//   // Obtenir le token Firebase
//   Future<String?> getIdToken() async {
//     final user = _auth.currentUser;
//     return user != null ? await user.getIdToken() : null;
//   }
// }
