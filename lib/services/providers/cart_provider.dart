/// *****************************************************************************
///
/// FOURNISSEUR D'ÉTAT POUR LE PANIER (CartProvider)
///
/// Ce fichier définit la classe `CartProvider`, qui utilise le pattern `ChangeNotifier`
/// pour gérer l'état du panier d'achat de l'utilisateur dans l'application.
///
/// RESPONSABILITÉS PRINCIPALES :
/// 1.  **Gestion de l'état** : Conserve la liste des services (`_cartItems`)
/// et l'identifiant du professionnel associé (`_coiffeuseId`).
///
/// 2.  **Communication API** : Gère toutes les interactions avec le backend pour
/// les opérations liées au panier (charger, ajouter, supprimer, vider).
///
/// 3.  **Sécurité** : Assure que chaque requête vers l'API est authentifiée en
/// utilisant un token d'identification Firebase, garantissant que seul
/// l'utilisateur connecté peut modifier son propre panier.
///
/// 4.  **Calculs dérivés** : Fournit des getters pour calculer dynamiquement le
/// prix total (`totalPrice`) et la durée totale (`totalDuration`) des
/// services dans le panier.
///
/// 5.  **Finalisation de commande** : Contient la logique pour envoyer la
/// réservation finale au serveur (`envoyerReservation`).
///
/// 6.  **Notification de l'UI** : Appelle `notifyListeners()` après chaque
/// modification de l'état pour que l'interface utilisateur se mette à jour
/// automatiquement.
///
///*****************************************************************************
library;

import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/service_with_promo.dart';

class CartProvider extends ChangeNotifier {
  // Liste privée des services actuellement dans le panier.
  List<ServiceWithPromo> _cartItems = [];
  // Identifiant du professionnel de coiffure associé au panier actuel.
  int? _coiffeuseId;

  // Getter public pour accéder à la liste des articles du panier.
  List<ServiceWithPromo> get cartItems => _cartItems;
  // Getter public pour accéder à l'ID du professionnel.
  int? get coiffeuseId => _coiffeuseId;

  /// Récupère le contenu du panier de l'utilisateur depuis l'API.
  ///
  /// La requête est sécurisée par le token d'authentification Firebase de l'utilisateur.
  Future<void> fetchCartFromApi(String userId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken();

      if (token == null) throw Exception("Token Firebase manquant");

      final response = await http.get(
        Uri.parse('https://www.hairbnb.site/api/get_cart/$userId/'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (kDebugMode) {
          print("Réponse API panier: $responseData");
        }
        setCartFromApi(responseData);
      } else {
        if (kDebugMode) {
          print("Erreur HTTP ${response.statusCode} : ${response.body}");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Erreur de connexion au serveur : $e");
      }
    }
  }

  /// Met à jour l'état local du panier à partir des données brutes de l'API.
  ///
  /// Cette méthode est appelée après une récupération réussie depuis le serveur.
  void setCartFromApi(Map<String, dynamic> cartData) {
    if (kDebugMode) {
      print("Traitement des données du panier...");
    }

    _cartItems = (cartData['items'] as List)
        .map((item) {
      if (kDebugMode) {
        print("Item panier: $item");
      }
      return ServiceWithPromo.fromJson(item['service']);
    })
        .toList();

    _coiffeuseId = cartData['coiffeuse_id'];

    if (kDebugMode) {
      print("Panier chargé - ${_cartItems.length} services:");
    }
    for (var service in _cartItems) {
      if (kDebugMode) {
        print("   - ${service.intitule}: ${service.temps} minutes");
      }
    }
    if (kDebugMode) {
      print("Durée totale calculée: $totalDuration minutes");
    }
    if (kDebugMode) {
      print("ID Coiffeuse: $_coiffeuseId");
    }

    notifyListeners();
  }

  /// Crée un rendez-vous en envoyant les informations du panier au serveur.
  ///
  /// Retourne les données de la réponse en cas de succès, sinon null.
  Future<Map<String, dynamic>?> envoyerReservation({
    required String userId,
    required DateTime dateHeure,
    required String methodePaiement,
  }) async {
    if (coiffeuseId == null || cartItems.isEmpty) return null;

    final url = Uri.parse('https://www.hairbnb.site/api/create_rendez_vous/');

    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken();
    if (token == null) {
      if (kDebugMode) {
        print("Token Firebase manquant");
      }
      return null;
    }

    final body = json.encode({
      "user_id": userId,
      "coiffeuse_id": coiffeuseId,
      "date_heure": dateHeure.toIso8601String(),
      "services": cartItems.map((s) => s.id).toList(),
      "methode_paiement": methodePaiement,
      "total_price": totalPrice,
      "total_duration": totalDuration,
    });

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: body,
      );

      if (response.statusCode == 201) {
        clearCart(); // Vide le panier localement après la réservation.

        final Map<String, dynamic> responseData =
        json.decode(response.body) is Map
            ? json.decode(response.body)
            : {'success': true};

        return responseData;
      } else {
        if (kDebugMode) {
          print("Erreur serveur : ${response.body}");
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print("Erreur réseau : $e");
      }
      return null;
    }
  }

  /// Ajoute un service au panier via une requête API sécurisée.
  ///
  /// Après l'ajout, le panier est rechargé depuis le serveur pour assurer la synchronisation.
  Future<void> addToCart(ServiceWithPromo serviceWithPromo, String userId) async {
    final url = Uri.parse('https://www.hairbnb.site/api/add_to_cart/');

    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken();

      if (token == null) throw Exception("Token Firebase manquant");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode({
          "user_id": userId,
          "service_id": serviceWithPromo.id,
        }),
      );

      if (response.statusCode == 200) {
        fetchCartFromApi(userId); // Recharger le panier pour refléter l'ajout.
      } else {
        if (kDebugMode) {
          print("Erreur HTTP ${response.statusCode} : ${response.body}");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors de l'ajout au panier : $e");
      }
    }
  }

  /// Supprime un service du panier via une requête API sécurisée.
  ///
  /// Après la suppression, le panier est rechargé depuis le serveur.
  Future<void> removeFromCart(ServiceWithPromo serviceWithPromo, String userId) async {
    final url = Uri.parse('https://www.hairbnb.site/api/remove_from_cart/');

    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken();

      if (token == null) {
        if (kDebugMode) {
          print("Token Firebase manquant");
        }
        return;
      }

      final response = await http.delete(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode({
          "user_id": userId,
          "service_id": serviceWithPromo.id,
        }),
      );

      if (response.statusCode == 200) {
        fetchCartFromApi(userId); // Recharger le panier pour refléter la suppression.
      } else {
        final body = response.body;
        if (kDebugMode) {
          print("Erreur lors de la suppression du service (${response.statusCode}) : $body");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Erreur de connexion lors de la suppression : $e");
      }
    }
  }

  /// Vide le panier localement et notifie l'interface.
  ///
  /// N'interagit pas avec le serveur.
  void clearCart() {
    _cartItems.clear();
    _coiffeuseId = null;
    notifyListeners();
  }

  /// Calcule et retourne le prix total des services dans le panier.
  ///
  /// Le calcul se base sur le `prix_final` qui inclut déjà les promotions.
  double get totalPrice {
    return _cartItems.fold(0.0, (total, serviceWithPromo) {
      return total + serviceWithPromo.prix_final;
    });
  }

  /// Calcule et retourne la durée totale en minutes des services dans le panier.
  ///
  /// Inclut une protection pour retourner une durée par défaut si le total est zéro.
  int get totalDuration {
    if (kDebugMode) {
      print("Calcul totalDuration - cartItems.length: ${_cartItems.length}");
    }
    int total = _cartItems.fold(0, (total, service) {
      if (kDebugMode) {
        print("   Service: ${service.intitule}, temps: ${service.temps}");
      }
      return total + service.temps;
    });
    if (kDebugMode) {
      print("totalDuration final: $total");
    }

    // Protection : si la durée totale est de 0 alors que le panier n'est pas vide,
    // une valeur par défaut est appliquée pour éviter les erreurs.
    if (total <= 0 && _cartItems.isNotEmpty) {
      if (kDebugMode) {
        print("totalDuration était 0, utilisation de 30 min par service par défaut");
      }
      total = _cartItems.length * 30; // 30 minutes par service par défaut.
    }

    return total;
  }

  /// Vide complètement le panier sur le serveur et met à jour l'état local.
  ///
  /// Retourne `true` en cas de succès, `false` sinon.
  Future<bool> clearCartFromServer(String userId) async {
    final url = Uri.parse('https://www.hairbnb.site/api/clear_cart/');

    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken();

      if (token == null) throw Exception("Token Firebase manquant");

      final response = http.Request("DELETE", url)
        ..headers["Content-Type"] = "application/json"
        ..headers["Authorization"] = "Bearer $token"
        ..body = json.encode({"user_id": userId});

      final streamed = await http.Client().send(response);

      if (streamed.statusCode == 200) {
        _cartItems.clear();
        _coiffeuseId = null;
        notifyListeners();
        return true;
      } else {
        final body = await streamed.stream.bytesToString();
        if (kDebugMode) {
          print("Erreur HTTP ${streamed.statusCode} : $body");
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors du clearCartFromServer : $e");
      }
      return false;
    }
  }
}
