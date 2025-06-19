/// *****************************************************************************
///
/// FOURNISSEUR D'ÉTAT POUR LES DISPONIBILITÉS (DisponibilitesProvider)
///
/// Ce fichier définit la classe `DisponibilitesProvider`, un `ChangeNotifier`
/// dont le rôle est de gérer la récupération et l'état des disponibilités d'un
/// professionnel ("coiffeuse").
///
/// FONCTIONNALITÉS CLÉS :
/// 1.  **Récupération des jours disponibles** : La méthode principale, `loadDisponibilites`,
/// interroge une API jour par jour sur une période de 14 jours pour identifier
/// les dates qui ont au moins un créneau libre pour une durée de prestation donnée.
///
/// 2.  **Récupération des créneaux horaires** : La méthode `getCreneauxPourJour`
/// récupère la liste précise des créneaux horaires (ex: "09:00", "09:30")
/// pour une date spécifique sélectionnée par l'utilisateur.
///
/// 3.  **Authentification Sécurisée** : Toutes les communications avec l'API sont
/// sécurisées. Le provider récupère dynamiquement un jeton d'identification
/// Firebase et l'inclut dans les en-têtes de chaque requête HTTP.
///
/// 4.  **Gestion d'état** : Il gère les états de chargement (`isLoaded`) et
/// d'erreur (`lastError`) pour fournir un retour visuel clair à l'utilisateur
/// dans l'interface.
///
///*****************************************************************************
library;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DisponibilitesProvider with ChangeNotifier {
  // --- État interne du Provider ---

  // Liste des jours qui ont au moins un créneau disponible.
  List<DateTime> _joursDisponibles = [];
  // Indique si le chargement initial des disponibilités est terminé.
  bool _isLoaded = false;
  // Stocke le dernier message d'erreur survenu.
  String? _lastError;

  // --- Getters publics pour accéder à l'état ---

  bool get isLoaded => _isLoaded;
  String? get lastError => _lastError;
  List<DateTime> get joursDisponibles => _joursDisponibles;

  /// Méthode privée pour construire les en-têtes de requête avec le jeton d'authentification Firebase.
  Future<Map<String, String>> _getAuthHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await user.getIdToken();
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
    }
    // Retourne des en-têtes de base si l'utilisateur n'est pas connecté.
    return {
      'Content-Type': 'application/json',
    };
  }

  /// Charge les jours ayant des créneaux disponibles pour une coiffeuse et une durée données.
  ///
  /// Cette méthode itère sur les 14 prochains jours et appelle l'API pour chaque jour.
  Future<void> loadDisponibilites(String coiffeuseId, int duree) async {
    if (kDebugMode) {
      print("=== DÉBUT CHARGEMENT DISPONIBILITÉS ===");
    }
    if (kDebugMode) {
      print("CoiffeuseId: $coiffeuseId");
    }
    if (kDebugMode) {
      print("Durée: $duree minutes");
    }

    // Validation des paramètres d'entrée pour éviter des appels API inutiles.
    if (coiffeuseId.isEmpty || duree <= 0) {
      _lastError = "Paramètres invalides: coiffeuseId='$coiffeuseId', duree=$duree";
      if (kDebugMode) {
        print("$_lastError");
      }
      _isLoaded = false;
      notifyListeners();
      return;
    }

    final now = DateTime.now();
    final end = now.add(const Duration(days: 14));
    List<DateTime> joursOK = [];

    // Réinitialisation de l'état avant de commencer le chargement.
    _isLoaded = false;
    _lastError = null;
    notifyListeners();

    try {
      final headers = await _getAuthHeaders();
      if (kDebugMode) {
        print("Headers d'authentification: ${headers.keys.toList()}");
      }

      int joursAnalyses = 0;
      int joursAvecCreneaux = 0;

      // Boucle sur chaque jour de la période de 14 jours.
      for (int i = 0; i <= end.difference(now).inDays; i++) {
        final date = now.add(Duration(days: i));
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        joursAnalyses++;

        final url = Uri.parse("https://www.hairbnb.site/api/get_disponibilites_client/$coiffeuseId/?date=$dateStr&duree=$duree");
        if (kDebugMode) {
          print("API Call [$i/${end.difference(now).inDays}]: $url");
        }

        try {
          // Appel API sécurisé avec les en-têtes d'authentification.
          final response = await http.get(url, headers: headers);
          if (kDebugMode) {
            print("Response [$dateStr]: Status ${response.statusCode}");
          }

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (kDebugMode) {
              print("Response data [$dateStr]: $data");
            }

            // Vérification robuste pour s'assurer que la réponse contient une liste de disponibilités.
            if (data is Map<String, dynamic> && data.containsKey('disponibilites')) {
              final disponibilites = data['disponibilites'];
              if (disponibilites is List && disponibilites.isNotEmpty) {
                joursOK.add(date);
                joursAvecCreneaux++;
                if (kDebugMode) {
                  print("Date $dateStr: ${disponibilites.length} créneaux trouvés");
                }
              } else {
                if (kDebugMode) {
                  print("Date $dateStr: Aucun créneau disponible");
                }
              }
            } else {
              if (kDebugMode) {
                print("Date $dateStr: Structure de réponse inattendue: $data");
              }
            }
          } else if (response.statusCode == 401) {
            if (kDebugMode) {
              print("Date $dateStr: Erreur d'authentification - ${response.body}");
            }
            _lastError = "Erreur d'authentification. Veuillez vous reconnecter.";
            break; // Arrête la boucle en cas de problème d'authentification.
          } else {
            if (kDebugMode) {
              print("Date $dateStr: Erreur HTTP ${response.statusCode} - ${response.body}");
            }
          }
        } catch (apiError) {
          if (kDebugMode) {
            print("Erreur API pour $dateStr: $apiError");
          }
          // Continue avec les autres dates même si une requête échoue.
        }

        // Ajoute un court délai périodiquement pour ne pas surcharger le serveur.
        if (i % 5 == 0 && i > 0) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      // Mise à jour de l'état final après la boucle.
      _joursDisponibles = joursOK;
      _isLoaded = true;
      _lastError ??= null;

      if (kDebugMode) {
        print("=== CHARGEMENT TERMINÉ ===");
      }
      if (kDebugMode) {
        print("Jours analysés: $joursAnalyses");
      }
      if (kDebugMode) {
        print("Jours avec créneaux: $joursAvecCreneaux");
      }
      if (kDebugMode) {
        print("Jours disponibles: ${_joursDisponibles.length}");
      }

      notifyListeners();

      // Si aucun jour n'a été trouvé, met à jour l'erreur pour informer l'utilisateur.
      if (_joursDisponibles.isEmpty && _lastError == null) {
        if (kDebugMode) {
          print("AUCUN JOUR DISPONIBLE - Causes possibles:");
        }
        if (kDebugMode) {
          print("   1. La coiffeuse n'a pas configuré ses horaires");
        }
        if (kDebugMode) {
          print("   2. Tous les créneaux sont déjà réservés");
        }
        if (kDebugMode) {
          print("   3. La durée demandée ($duree min) est trop longue");
        }
        if (kDebugMode) {
          print("   4. Problème côté serveur/base de données");
        }
        _lastError = "Aucune disponibilité trouvée pour les 14 prochains jours";
      }

    } catch (e) {
      _lastError = "Erreur lors du chargement des disponibilités: $e";
      if (kDebugMode) {
        print("ERREUR GLOBALE: $_lastError");
      }
      _isLoaded = false;
      notifyListeners();
    }
  }

  /// Récupère la liste des créneaux horaires pour un jour spécifique.
  Future<List<Map<String, String>>> getCreneauxPourJour(String dateStr, String coiffeuseId, int duree) async {
    if (kDebugMode) {
      print("=== RÉCUPÉRATION CRÉNEAUX ===");
    }
    if (kDebugMode) {
      print("Date: $dateStr");
    }
    if (kDebugMode) {
      print("CoiffeuseId: $coiffeuseId");
    }
    if (kDebugMode) {
      print("Durée: $duree");
    }

    final url = Uri.parse("https://www.hairbnb.site/api/get_disponibilites_client/$coiffeuseId/?date=$dateStr&duree=$duree");
    if (kDebugMode) {
      print("URL: $url");
    }

    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(url, headers: headers);
      if (kDebugMode) {
        print("Status: ${response.statusCode}");
      }
      if (kDebugMode) {
        print("Body: ${response.body}");
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is Map<String, dynamic> && data.containsKey('disponibilites')) {
          final slots = data['disponibilites'] as List;
          final creneaux = slots.map<Map<String, String>>((slot) {
            return {
              'debut': slot['debut'].toString(),
              'fin': slot['fin'].toString(),
            };
          }).toList();

          if (kDebugMode) {
            print("${creneaux.length} créneaux récupérés:");
          }
          for (var creneau in creneaux) {
            if (kDebugMode) {
              print("   - ${creneau['debut']} → ${creneau['fin']}");
            }
          }

          return creneaux;
        } else {
          if (kDebugMode) {
            print("Structure de réponse incorrecte: $data");
          }
          return [];
        }
      } else if (response.statusCode == 401) {
        if (kDebugMode) {
          print("Erreur d'authentification: ${response.body}");
        }
        return [];
      } else {
        if (kDebugMode) {
          print("Erreur HTTP: ${response.statusCode} - ${response.body}");
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print("Erreur réseau: $e");
      }
      return [];
    }
  }

  /// Vérifie si un jour donné est présent dans la liste des jours disponibles.
  ///
  /// Utilisé pour l'affichage dans le calendrier de l'interface.
  bool isJourDispo(DateTime day) {
    bool dispo = _joursDisponibles.any((d) =>
    d.year == day.year && d.month == day.month && d.day == day.day);
    if (kDebugMode) {
      print("isJourDispo(${DateFormat('yyyy-MM-dd').format(day)}): $dispo");
    }
    return dispo;
  }

  /// Efface l'état actuel et force un rechargement complet des disponibilités.
  Future<void> reloadDisponibilites(String coiffeuseId, int duree) async {
    if (kDebugMode) {
      print("Rechargement forcé des disponibilités...");
    }
    _joursDisponibles.clear();
    _isLoaded = false;
    _lastError = null;
    notifyListeners();

    await loadDisponibilites(coiffeuseId, duree);
  }

  /// Retourne une carte d'informations de diagnostic sur l'état actuel du provider.
  Map<String, dynamic> getDiagnosticInfo() {
    return {
      'isLoaded': _isLoaded,
      'joursDisponibles': _joursDisponibles.length,
      'lastError': _lastError,
      'dates': _joursDisponibles.map((d) => DateFormat('yyyy-MM-dd').format(d)).toList(),
    };
  }
}
