/// *************************************************************************************************
///
/// BANNER : EXPLICATION GÉNÉRALE DU WIDGET
///
/// Ce fichier définit un widget Flutter `StatefulWidget` nommé `CommuneAutoFill`.
///
/// Objectif :
/// Fournir un champ de saisie pour un code postal qui, lorsqu'il est modifié, interroge
/// automatiquement l'API Geoapify pour trouver le nom de la commune correspondante. Le nom
/// de la commune est ensuite inséré dans un autre champ de texte.
///
/// Fonctionnement :
/// 1.  Le widget affiche un `TextField` pour que l'utilisateur entre un code postal.
/// 2.  À chaque modification du code postal, la méthode `fetchCommune` est appelée.
/// 3.  Cette méthode envoie une requête HTTP GET à l'API de géocodage de Geoapify.
/// 4.  Si la requête réussit et qu'un résultat est trouvé, elle extrait le nom de la ville
/// (commune, village, etc.).
/// 5.  Le `TextEditingController` du champ de la commune est mis à jour avec le nom trouvé.
/// 6.  Des callbacks optionnels (`onCommuneFound`, `onCommuneNotFound`) peuvent être
/// exécutés pour permettre au widget parent de réagir au résultat de la recherche.
///
/// Dépendances :
/// -   `flutter/material.dart` : pour les composants d'interface utilisateur de base.
/// -   `http/http.dart` : pour effectuer des requêtes HTTP.
/// -   `dart:convert` : pour décoder la réponse JSON de l'API.
///
///*************************************************************************************************
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Un widget qui fournit un champ pour le code postal et remplit automatiquement
/// un champ de commune en utilisant l'API Geoapify.
class CommuneAutoFill extends StatefulWidget {
  /// Le contrôleur pour le champ de texte du code postal.
  final TextEditingController codePostalController;

  /// Le contrôleur pour le champ de texte de la commune, qui sera auto-rempli.
  final TextEditingController communeController;

  /// Votre clé API personnelle pour accéder aux services Geoapify.
  final String geoapifyApiKey;

  /// Callback optionnel exécuté lorsque la commune est trouvée avec succès.
  final VoidCallback? onCommuneFound;

  /// Callback optionnel exécuté lorsque la commune n'est pas trouvée ou en cas d'erreur.
  final VoidCallback? onCommuneNotFound;

  /// Constructeur du widget `CommuneAutoFill`.
  const CommuneAutoFill({
    super.key,
    required this.codePostalController,
    required this.communeController,
    required this.geoapifyApiKey,
    this.onCommuneFound,
    this.onCommuneNotFound,
  });

  @override
  State<CommuneAutoFill> createState() => _CommuneAutoFillState();
}

/// La classe d'état pour `CommuneAutoFill`, gérant la logique de récupération des données.
class _CommuneAutoFillState extends State<CommuneAutoFill> {

  /// Méthode asynchrone pour interroger l'API Geoapify et trouver une commune.
  Future<void> fetchCommune(String codePostal) async {
    // Vérification initiale : si le code postal est invalide, on réinitialise le champ commune.
    if (codePostal.isEmpty || codePostal.length < 4) {
      // S'assure que le widget est toujours "monté" dans l'arbre des widgets avant de mettre à jour son état.
      if (mounted) {
        setState(() {
          widget.communeController.text = "";
        });
      }
      // Notifie le widget parent que la commune n'a pas été trouvée.
      widget.onCommuneNotFound?.call();
      return;
    }

    // Construit l'URL de la requête pour l'API Geoapify.
    final url = Uri.parse(
        "https://api.geoapify.com/v1/geocode/search?postcode=$codePostal&lang=fr&limit=1&apiKey=${widget.geoapifyApiKey}");

    // Affiche l'URL de la requête en mode débogage pour faciliter le suivi.
    if (kDebugMode) {
      print("Geoapify - Requête Commune URL: $url");
    }

    try {
      // Exécute la requête HTTP GET.
      final response = await http.get(url);

      // Affiche les informations de la réponse en mode débogage.
      if (kDebugMode) {
        print("Geoapify - Réponse Commune Statut: ${response.statusCode}");
        print("Geoapify - Réponse Commune Corps: ${response.body}");
      }

      // Traite la réponse si la requête a réussi (code de statut 200).
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Vérifie si la réponse contient des résultats (features).
        if (data['features'] != null && data['features'].isNotEmpty) {
          final properties = data['features'][0]['properties'];

          // Vérifie à nouveau si le widget est monté.
          if (mounted) {
            // Tente d'extraire le nom de la commune à partir de plusieurs champs possibles.
            final String communeName = properties['city'] ??
                properties['town'] ??
                properties['village'] ??
                properties['county'] ??
                "Commune introuvable";

            // Met à jour l'état du widget avec le nom de la commune.
            setState(() {
              widget.communeController.text = communeName;
            });

            // Exécute le callback approprié selon que la commune a été trouvée ou non.
            if (communeName != "Commune introuvable") {
              widget.onCommuneFound?.call();
            } else {
              widget.onCommuneNotFound?.call();
            }
          }
        } else {
          // Si aucune commune n'est trouvée dans la réponse.
          if (mounted) {
            setState(() {
              widget.communeController.text = "Commune introuvable";
            });
          }
          widget.onCommuneNotFound?.call();
        }
      } else {
        // Gère les cas où l'API retourne une erreur (code de statut autre que 200).
        debugPrint("Erreur API Geoapify (Commune - ${response.statusCode}): ${response.body}");
        if (mounted) {
          setState(() {
            widget.communeController.text = "Erreur de recherche";
          });
        }
        widget.onCommuneNotFound?.call();
      }
    } catch (e) {
      // Gère les erreurs de connectivité (ex: pas d'internet).
      debugPrint("Erreur de connexion Geoapify (Commune) : $e");
      if (mounted) {
        setState(() {
          widget.communeController.text = "Erreur réseau";
        });
      }
      widget.onCommuneNotFound?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Construit l'interface utilisateur du widget.
    return TextField(
      controller: widget.codePostalController,
      // Définit le type de clavier pour n'autoriser que les chiffres.
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: "Code Postal",
        border: OutlineInputBorder(),
      ),
      // Appelle la fonction fetchCommune à chaque fois que la valeur du champ change.
      onChanged: (value) => fetchCommune(value),
    );
  }
}





// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter/foundation.dart';
//
// class CommuneAutoFill extends StatefulWidget {
//   final TextEditingController codePostalController;
//   final TextEditingController communeController;
//   final String geoapifyApiKey;
//   final VoidCallback? onCommuneFound; // Nouveau callback si la commune est trouvée
//   final VoidCallback? onCommuneNotFound; // Nouveau callback si la commune n'est pas trouvée
//
//   const CommuneAutoFill({
//     super.key,
//     required this.codePostalController,
//     required this.communeController,
//     required this.geoapifyApiKey,
//     this.onCommuneFound,
//     this.onCommuneNotFound,
//   });
//
//   @override
//   State<CommuneAutoFill> createState() => _CommuneAutoFillState();
// }
//
// class _CommuneAutoFillState extends State<CommuneAutoFill> {
//   Future<void> fetchCommune(String codePostal) async {
//     // Si le code postal est vide ou trop court, vider la commune et signaler qu'elle n'est pas trouvée.
//     if (codePostal.isEmpty || codePostal.length < 4) {
//       if (mounted) { // Vérifier si le widget est monté avant setState
//         setState(() {
//           widget.communeController.text = "";
//         });
//       }
//       widget.onCommuneNotFound?.call(); // Appeler le callback de non-trouvé
//       return;
//     }
//
//     // Construction de l'URL pour l'API Geoapify Geocoding (recherche par code postal).
//     final url = Uri.parse(
//         "https://api.geoapify.com/v1/geocode/search?postcode=$codePostal&lang=fr&limit=1&apiKey=${widget.geoapifyApiKey}");
//
//     if (kDebugMode) {
//       print("Geoapify - Requête Commune URL: $url");
//     }
//
//     try {
//       final response = await http.get(url);
//
//       if (kDebugMode) {
//         print("Geoapify - Réponse Commune Statut: ${response.statusCode}");
//         print("Geoapify - Réponse Commune Corps: ${response.body}");
//       }
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         // Vérifier si des fonctionnalités (résultats) sont présentes.
//         if (data['features'] != null && data['features'].isNotEmpty) {
//           final properties = data['features'][0]['properties'];
//           if (mounted) { // Vérifier si le widget est monté avant setState
//             // Extraire le nom de la ville/commune en utilisant différentes propriétés comme fallback.
//             final String communeName = properties['city'] ??
//                 properties['town'] ??
//                 properties['village'] ??
//                 properties['county'] ?? // Ajout de 'county' comme fallback
//                 "Commune introuvable";
//
//             setState(() {
//               widget.communeController.text = communeName;
//             });
//             // Appeler le callback approprié en fonction du résultat.
//             if (communeName != "Commune introuvable") {
//               widget.onCommuneFound?.call();
//             } else {
//               widget.onCommuneNotFound?.call();
//             }
//           }
//         } else {
//           // Si aucune fonctionnalité n'est trouvée, signaler que la commune est introuvable.
//           if (mounted) { // Vérifier si le widget est monté avant setState
//             setState(() {
//               widget.communeController.text = "Commune introuvable";
//             });
//           }
//           widget.onCommuneNotFound?.call();
//         }
//       } else {
//         // Gérer les erreurs de l'API (codes de statut non-200).
//         debugPrint("Erreur API Geoapify (Commune - ${response.statusCode}): ${response.body}");
//         if (mounted) { // Vérifier si le widget est monté avant setState
//           setState(() {
//             widget.communeController.text = "Erreur de recherche";
//           });
//         }
//         widget.onCommuneNotFound?.call();
//       }
//     } catch (e) {
//       // Gérer les erreurs de connexion réseau.
//       debugPrint("Erreur de connexion Geoapify (Commune) : $e");
//       if (mounted) { // Vérifier si le widget est monté avant setState
//         setState(() {
//           widget.communeController.text = "Erreur réseau";
//         });
//       }
//       widget.onCommuneNotFound?.call();
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return TextField(
//       controller: widget.codePostalController,
//       keyboardType: TextInputType.number,
//       decoration: const InputDecoration(
//         labelText: "Code Postal",
//         border: OutlineInputBorder(),
//       ),
//       onChanged: (value) => fetchCommune(value),
//     );
//   }
// }
//
