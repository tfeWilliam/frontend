/// *************************************************************************************************
/// *
/// BANNIÈRE : PROVIDER POUR LA GESTION DE L'ÉTAT DE L'UTILISATEUR COURANT                           *
/// --------------------------------------------------------------------------                      *
/// *
/// OBJECTIF :                                                                                      *
/// Ce fichier définit la classe `CurrentUserProvider`, un `ChangeNotifier` qui sert de source      *
/// de vérité unique pour les informations de l'utilisateur actuellement connecté. Il fait le pont *
/// entre l'authentification Firebase et la base de données du backend (Django).                    *
/// *
/// FONCTIONNALITÉS PRINCIPALES :                                                                   *
/// 1. RÉCUPÉRATION DE L'UTILISATEUR :                                                                *
/// La méthode `fetchCurrentUser` utilise le token d'ID de l'utilisateur Firebase pour s'authentifier *
/// de manière sécurisée auprès du backend et récupérer le profil complet de l'utilisateur.        *
/// *
/// 2. GESTION D'ÉTAT CENTRALISÉE :                                                                 *
/// - Stocke les données de l'utilisateur dans la propriété `_currentUser`.                       *
/// - Notifie les widgets écouteurs (`notifyListeners`) de tout changement pour mettre l'UI à jour. *
/// *
/// 3. CYCLE DE VIE DE LA SESSION :                                                                 *
/// - `clearUser` : Réinitialise l'état de l'utilisateur, typiquement appelée lors de la déconnexion.*
/// - `refreshCurrentUser` : Permet de forcer le rechargement des données de l'utilisateur depuis   *
/// le serveur, utile après une mise à jour du profil par exemple.                                  *
/// *
///*************************************************************************************************
library;

import 'package:flutter/foundation.dart';
import 'package:hairbnb/models/current_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Un `ChangeNotifier` pour gérer et fournir les données de l'utilisateur courant dans l'application.
class CurrentUserProvider with ChangeNotifier {
  // Instance privée de l'utilisateur courant. L'accès se fait via le getter public.
  CurrentUser? _currentUser;
  // Instance du service d'authentification Firebase.
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // URL de base du backend.
  final String baseUrl = "https://www.hairbnb.site";

  /// Getter public pour accéder aux données de l'utilisateur courant.
  CurrentUser? get currentUser => _currentUser;

  /// Récupère les informations de l'utilisateur depuis le backend Django.
  /// Cette méthode est généralement appelée une seule fois au démarrage de l'application.
  Future<void> fetchCurrentUser() async {
    // Si l'utilisateur est déjà chargé, on ne fait rien pour éviter des appels inutiles.
    if (_currentUser != null) return;

    // Récupère l'utilisateur actuellement authentifié via Firebase.
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return;

    try {
      // Obtient le token d'ID Firebase. Ce token sert de preuve d'identité sécurisée.
      final token = await firebaseUser.getIdToken();

      // Effectue un appel GET authentifié au backend.
      final response = await http.get(
        Uri.parse('$baseUrl/api/get_current_user/'),
        headers: {
          'Authorization': 'Bearer $token', // Le token est passé dans l'en-tête 'Authorization'.
          'Content-Type': 'application/json',
        },
      );

      // Si la requête réussit, on traite les données.
      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = json.decode(decodedBody);
        _currentUser = CurrentUser.fromJson(data['user']);
        // Notifie tous les widgets qui écoutent ce provider qu'un changement a eu lieu.
        notifyListeners();
      } else {
        if (kDebugMode) {
          print("Utilisateur non trouvé ou non autorisé (${response.statusCode})");
        }
      }
    } catch (error) {
      if (kDebugMode) {
        print("Erreur lors du chargement du current user : $error");
      }
    }
  }

  /// Réinitialise l'état de l'utilisateur, généralement après une déconnexion.
  void clearUser() {
    _currentUser = null;
    // Notifie les widgets pour qu'ils se reconstruisent (ex: redirection vers la page de login).
    notifyListeners();
  }

  /// Force le rechargement des données de l'utilisateur depuis le backend.
  /// Utile après une modification du profil pour avoir des données à jour.
  Future<void> refreshCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return;

    try {
      final token = await firebaseUser.getIdToken();

      final response = await http.get(
        Uri.parse('$baseUrl/api/get_current_user/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = json.decode(decodedBody);
        _currentUser = CurrentUser.fromJson(data['user']);
        notifyListeners();
        if (kDebugMode) {
          print("Utilisateur rechargé avec succès");
        }
      } else {
        if (kDebugMode) {
          print("Erreur rechargement utilisateur (${response.statusCode})");
        }
      }
    } catch (error) {
      if (kDebugMode) {
        print("Erreur lors du rechargement : $error");
      }
    }
  }
}
