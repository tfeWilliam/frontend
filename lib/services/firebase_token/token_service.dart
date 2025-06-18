////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////// Service de gestion du token Firebase ////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service pour gérer le token d'authentification Firebase
/// - Lecture depuis SharedPreferences ou Firebase Auth
/// - Sauvegarde locale pour accélérer les appels futurs
class TokenService {
  // Clé utilisée pour stocker le token dans SharedPreferences
  static const String _tokenKey = 'auth_token';

  //////////////////////////////////////////////////////////////////////////////////////////////
  /// Méthode pour récupérer le token d'authentification
  /// 1. Tente d’abord de le lire dans SharedPreferences (rapide)
  /// 2. Si absent, tente de le récupérer depuis FirebaseAuth et le sauvegarde localement
  /// Retourne : le token en String, ou null en cas d’échec
  //////////////////////////////////////////////////////////////////////////////////////////////
  static Future<String?> getAuthToken({bool forceRefresh = false}) async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser != null) {
        final token = await firebaseUser.getIdToken(forceRefresh);

        // Stocker le token localement pour usage futur
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token!);

        return token;
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la récupération du token: $e');
      }
      return null;
    }
  }


  //////////////////////////////////////////////////////////////////////////////////////////////
  /// Méthode pour sauvegarder un token dans SharedPreferences
  /// Retourne : true si succès, false sinon
  //////////////////////////////////////////////////////////////////////////////////////////////
  static Future<bool> saveAuthToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_tokenKey, token);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la sauvegarde du token: $e');
      }
      return false;
    }
  }

  //////////////////////////////////////////////////////////////////////////////////////////////
  /// Méthode pour effacer le token enregistré localement
  /// Retourne : true si succès, false sinon
  //////////////////////////////////////////////////////////////////////////////////////////////
  static Future<bool> clearAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_tokenKey);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la suppression du token: $e');
      }
      return false;
    }
  }
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////