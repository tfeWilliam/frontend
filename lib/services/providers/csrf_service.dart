/// *************************************************************************************************
/// *
/// BANNIÈRE : SERVICE DE RÉCUPÉRATION DU JETON CSRF                                                  *
/// ----------------------------------------------------                                            *
/// *
/// OBJECTIF :                                                                                      *
/// Ce fichier définit la classe `CSRFService`, dont le rôle est de récupérer un jeton (token)      *
/// CSRF (Cross-Site Request Forgery) depuis le serveur. Ce jeton est essentiel pour sécuriser      *
/// l'application contre les attaques CSRF.                                                         *
/// *
/// FONCTIONNEMENT :                                                                                *
/// 1. La méthode `fetchCSRFToken` envoie une requête GET à un point de terminaison de l'API.       *
/// 2. Le serveur répond en incluant le jeton CSRF dans l'en-tête 'set-cookie'.                      *
/// 3. Le service analyse cet en-tête pour extraire la valeur du jeton.                             *
/// 4. Le jeton est ensuite stocké dans une variable statique (`csrfToken`) pour être réutilisé     *
/// dans les en-têtes des requêtes ultérieures (POST, PUT, DELETE, etc.), prouvant ainsi que la     *
/// requête provient bien de l'application cliente légitime.                                        *
/// *
///*************************************************************************************************
library;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Classe statique utilitaire pour gérer la récupération du jeton CSRF.
class CSRFService {
  /// Variable statique pour stocker le jeton CSRF une fois qu'il a été récupéré.
  /// `static` permet d'y accéder depuis n'importe où dans l'application sans instancier la classe.
  static String? csrfToken;

  /// Envoie une requête au serveur pour obtenir et stocker le jeton CSRF.
  static Future<void> fetchCSRFToken() async {
    // Envoie une requête GET à un point de terminaison de l'API.
    // N'importe quel endpoint qui définit le cookie CSRF peut être utilisé.
    final response = await http.get(Uri.parse('https://www.hairbnb.site/api/services/'));

    // Vérifie si la réponse du serveur contient l'en-tête 'set-cookie'.
    if (response.headers.containsKey('set-cookie')) {
      final cookies = response.headers['set-cookie'];
      if (cookies != null) {
        // Utilise une expression régulière pour trouver la partie "csrftoken=..." dans la chaîne de cookies.
        // - `csrftoken=` : correspond au nom du cookie.
        // - `([^;]+)` : capture tous les caractères qui ne sont pas un point-virgule.
        final match = RegExp(r'csrftoken=([^;]+)').firstMatch(cookies);

        // Si une correspondance est trouvée, extrait la valeur capturée (le jeton).
        if (match != null) {
          csrfToken = match.group(1);
          // Affiche le jeton dans la console à des fins de débogage.
          if (kDebugMode) {
            print('CSRF Token fetched: $csrfToken');
          }
        }
      }
    }
  }
}
