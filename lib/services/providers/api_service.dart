/// *************************************************************************************************
/// *
/// BANNIÈRE : CLIENT API POUR LA GESTION DES SERVICES                                              *
/// ----------------------------------------------------                                            *
/// *
/// OBJECTIF :                                                                                      *
/// Ce fichier définit la classe `ServiceAPI`, qui agit comme un client HTTP pour interagir avec    *
/// les points de terminaison (endpoints) de l'API relatifs aux services proposés par les           *
/// coiffeuses.                                                                                     *
/// *
/// FONCTIONNALITÉS PRINCIPALES :                                                                   *
/// 1. RÉCUPÉRATION DES SERVICES :                                                                  *
/// La méthode `fetchServices` est chargée d'envoyer une requête à l'API pour obtenir la liste      *
/// complète des services associés à une coiffeuse spécifique, identifiée par son ID.               *
/// *
/// 2. GESTION DES DONNÉES :                                                                        *
/// Elle gère l'appel réseau, la vérification du statut de la réponse, le décodage correct du      *
/// JSON (en gérant les caractères spéciaux comme les accents grâce à l'UTF-8) et la conversion    *
/// des données brutes en une liste d'objets `Service` typés.                                       *
/// *
///*************************************************************************************************
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/services.dart';

/// Classe statique fournissant des méthodes pour communiquer avec l'API concernant les services.
class ServiceAPI {
  // L'URL de base pour toutes les requêtes de l'API, garantissant une maintenance facile.
  static const String baseUrl = "https://www.hairbnb.site/api";

  /// Récupère la liste de tous les services proposés par une coiffeuse spécifique.
  ///
  /// [coiffeuseId] : L'identifiant unique de la coiffeuse dont on veut récupérer les services.
  /// Retourne un `Future` qui se résoudra en une `List<Service>`.
  /// Lève une `Exception` si la requête HTTP échoue (code de statut autre que 200).
  static Future<List<Service>> fetchServices(String coiffeuseId) async {
    // Construit l'URL complète pour le point de terminaison spécifique.
    final response = await http.get(Uri.parse("$baseUrl/get_services/$coiffeuseId/"));

    // Vérifie si la requête a réussi.
    if (response.statusCode == 200) {
      // Décode le corps de la réponse en utilisant UTF-8 pour s'assurer
      // que les caractères spéciaux (comme les accents) sont correctement interprétés.
      final decodedBody = utf8.decode(response.bodyBytes);

      // Parse la chaîne JSON décodée et extrait la liste des services.
      final List data = json.decode(decodedBody)["salon"]["services"];

      // Transforme chaque élément JSON de la liste en un objet `Service`
      // et retourne la liste d'objets typés.
      return data.map((e) => Service.fromJson(e)).toList();
    } else {
      // Si la requête a échoué, lève une exception pour le signaler à l'appelant.
      throw Exception("Erreur lors du chargement des services");
    }
  }
}
