////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//          WIDGET DE CHAMP DE SAISIE AVEC AUTOCOMPLÉTION POUR LES RUES         //
//                                                                            //
//  Ce fichier définit le widget `StreetAutocomplete`, un composant           //
//  `StatefulWidget` réutilisable qui fournit un champ de texte pour la       //
//  saisie de noms de rues.                                                   //
//                                                                            //
//  Fonctionnalités Clés :                                                    //
//  - Interroge en temps réel l'API Geoapify pour proposer des suggestions de //
//    rues à mesure que l'utilisateur tape.                                   //
//  - Utilise les informations de commune et de code postal (via des          //
//    contrôleurs externes) pour affiner les résultats de recherche et les     //
//    limiter à la Belgique.                                                  //
//  - Nettoie les noms de rues retournés par l'API pour enlever les numéros.  //
//  - Fournit une interface de suggestions entièrement personnalisée.         //
//  - Utilise des callbacks pour notifier le widget parent des changements et //
//    des sélections.                                                         //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Un widget qui fournit un champ de saisie avec autocomplétion pour les rues.
class StreetAutocomplete extends StatefulWidget {
  /// Le contrôleur pour le champ de texte de la rue.
  final TextEditingController streetController;
  /// Le contrôleur pour le champ de la commune, utilisé pour filtrer les résultats.
  final TextEditingController communeController;
  /// Le contrôleur pour le champ du code postal, utilisé pour filtrer les résultats.
  final TextEditingController codePostalController;
  /// La clé API pour le service Geoapify.
  final String geoapifyApiKey;
  /// Callback optionnel exécuté lorsqu'une suggestion est sélectionnée.
  final VoidCallback? onStreetSelected;
  /// Callback optionnel exécuté à chaque modification du texte dans le champ.
  final VoidCallback? onStreetChanged;

  /// Constructeur pour le widget `StreetAutocomplete`.
  const StreetAutocomplete({
    super.key,
    required this.streetController,
    required this.communeController,
    required this.codePostalController,
    required this.geoapifyApiKey,
    this.onStreetSelected,
    this.onStreetChanged,
  });

  @override
  State<StreetAutocomplete> createState() => _StreetAutocompleteState();
}

/// La classe d'état pour `StreetAutocomplete`.
/// Gère la logique de récupération des suggestions et la construction de l'UI.
class _StreetAutocompleteState extends State<StreetAutocomplete> {

  /// Interroge l'API Geoapify pour obtenir des suggestions de rues basées sur la saisie.
  ///
  /// [query] : Le texte partiel saisi par l'utilisateur.
  ///
  /// Retourne une `Future` qui se résoudra en une `Iterable<String>` contenant
  /// les noms de rues uniques et formatés.
  Future<Iterable<String>> fetchStreetSuggestions(String query) async {
    if (query.isEmpty || query.length < 2) {
      return const Iterable<String>.empty();
    }

    // Construit une requête de recherche plus précise en ajoutant la commune et le code postal.
    String searchQuery = query;
    if (widget.communeController.text.isNotEmpty) searchQuery += ", ${widget.communeController.text}";
    if (widget.codePostalController.text.isNotEmpty) searchQuery += ", ${widget.codePostalController.text}";
    searchQuery += ", Belgium"; // Limite la recherche à la Belgique.

    // Construit l'URL finale avec les paramètres encodés.
    String urlString = "https://api.geoapify.com/v1/geocode/autocomplete"
        "?text=${Uri.encodeComponent(searchQuery)}"
        "&type=street" // Ne recherche que les rues.
        "&filter=countrycode:be" // Filtre par code pays.
        "&limit=8"
        "&lang=fr"
        "&apiKey=${widget.geoapifyApiKey}";

    final url = Uri.parse(urlString);

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['features'] != null && data['features'].isNotEmpty) {
          // Utilise un `Set` pour garantir que chaque nom de rue est unique.
          Set<String> uniqueStreets = {};

          for (var feature in data['features']) {
            final properties = feature['properties'];
            // Tente de trouver le nom de la rue dans plusieurs champs possibles.
            String? street = properties['street'] ?? properties['address_line1'] ?? properties['name'];

            if (street != null && street.isNotEmpty) {
              // Nettoie le nom de la rue pour enlever les numéros de maison.
              street = _cleanStreetName(street);
              if (street.isNotEmpty) {
                uniqueStreets.add(street);
              }
            }
          }
          return uniqueStreets;
        }
      } else {
        debugPrint("Erreur API Geoapify (Rue - ${response.statusCode}): ${response.body}");
      }
    } catch (e) {
      debugPrint("Erreur de connexion Geoapify (Rue) : $e");
    }
    return const Iterable<String>.empty();
  }

  /// Nettoie un nom de rue en supprimant les numéros de maison à l'aide d'expressions régulières.
  String _cleanStreetName(String street) {
    return street.replaceAll(RegExp(r'^\d+\s*'), '')       // Numéros au début
        .replaceAll(RegExp(r'\s*\d+$'), '')              // Numéros à la fin
        .replaceAll(RegExp(r'^\d+[a-zA-Z]?\s*'), '')    // Numéros avec lettres au début
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    // Utilise le widget `Autocomplete` intégré de Flutter pour gérer la logique.
    return Autocomplete<String>(
      /// `optionsBuilder` est appelé à chaque frappe pour fournir les suggestions.
      optionsBuilder: (TextEditingValue textEditingValue) {
        widget.onStreetChanged?.call();
        return fetchStreetSuggestions(textEditingValue.text);
      },

      /// `onSelected` est appelé quand l'utilisateur choisit une suggestion.
      onSelected: (String selection) {
        widget.streetController.text = selection;
        widget.onStreetSelected?.call();
        if (kDebugMode) print("Rue sélectionnée: $selection");
      },

      /// `fieldViewBuilder` construit le champ de texte (`TextField`).
      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
        // Il est crucial d'utiliser les contrôleurs fournis par le `fieldViewBuilder`
        // pour que l'autocomplétion fonctionne correctement.
        return TextField(
          controller: controller, // Utilise le contrôleur interne d'Autocomplete.
          focusNode: focusNode,
          onEditingComplete: onEditingComplete,
          decoration: InputDecoration(
            labelText: "Tapez le nom de votre rue",
            hintText: "Ex: Rue de la Paix, Avenue Louise...",
            prefixIcon: const Icon(Icons.search, color: Color(0xFF8E44AD)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF8E44AD), width: 2)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          /// Synchronise la valeur avec le contrôleur externe du widget parent.
          onChanged: (text) {
            widget.streetController.text = text;
            widget.onStreetChanged?.call();
          },
        );
      },

      /// `optionsViewBuilder` construit l'apparence de la liste de suggestions.
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: BoxConstraints(maxHeight: 200, maxWidth: MediaQuery.of(context).size.width - 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 1)],
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final String option = options.elementAt(index);
                  return ListTile(
                    leading: const Icon(Icons.location_on, color: Color(0xFF8E44AD), size: 20),
                    title: Text(option, style: const TextStyle(fontSize: 14)),
                    dense: true,
                    onTap: () => onSelected(option), // Sélectionne l'option au clic.
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}






// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter/foundation.dart';
//
// class StreetAutocomplete extends StatefulWidget {
//   final TextEditingController streetController;
//   final TextEditingController communeController;
//   final TextEditingController codePostalController;
//   final String geoapifyApiKey;
//   final VoidCallback? onStreetSelected; // Nouveau callback pour la sélection
//   final VoidCallback? onStreetChanged;  // Nouveau callback pour les changements de texte
//
//   const StreetAutocomplete({
//     super.key,
//     required this.streetController,
//     required this.communeController,
//     required this.codePostalController,
//     required this.geoapifyApiKey,
//     this.onStreetSelected,
//     this.onStreetChanged,
//   });
//
//   @override
//   State<StreetAutocomplete> createState() => _StreetAutocompleteState();
// }
//
// class _StreetAutocompleteState extends State<StreetAutocomplete> {
//   // La liste de suggestions est gérée par Autocomplete lui-même via Future.
//   // Plus besoin d'un setState pour les suggestions ici.
//   Future<Iterable<String>> fetchStreetSuggestions(String query) async {
//     if (query.isEmpty || query.length < 2) {
//       return const Iterable<String>.empty();
//     }
//
//     // Construire la requête pour Geoapify Autocomplete avec filtrage par commune et code postal.
//     String searchQuery = query;
//
//     // Ajouter la commune et le code postal pour améliorer la recherche.
//     if (widget.communeController.text.isNotEmpty) {
//       searchQuery += ", ${widget.communeController.text}";
//     }
//     if (widget.codePostalController.text.isNotEmpty) {
//       searchQuery += ", ${widget.codePostalController.text}";
//     }
//     searchQuery += ", Belgium"; // Limiter à la Belgique
//
//     String urlString = "https://api.geoapify.com/v1/geocode/autocomplete"
//         "?text=${Uri.encodeComponent(searchQuery)}"
//         "&type=street" // Rechercher uniquement les rues
//         "&filter=countrycode:be" // Filtrer par code de pays (Belgique)
//         "&limit=8" // Limiter le nombre de résultats
//         "&lang=fr" // Langue des résultats (français)
//         "&apiKey=${widget.geoapifyApiKey}"; // Clé API Geoapify
//
//     final url = Uri.parse(urlString);
//
//     if (kDebugMode) {
//       print("Geoapify - Requête Rue URL: $url");
//     }
//
//     try {
//       final response = await http.get(url);
//
//       if (kDebugMode) {
//         print("Geoapify - Réponse Rue Statut: ${response.statusCode}");
//         print("Geoapify - Réponse Rue Corps: ${response.body}");
//       }
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data['features'] != null && data['features'].isNotEmpty) {
//           // Extraire les noms de rues uniques
//           Set<String> uniqueStreets = {};
//
//           for (var feature in data['features']) {
//             final properties = feature['properties'];
//
//             // Essayer différents champs pour obtenir le nom de la rue (priorité à 'street', puis 'address_line1', puis 'name')
//             String? street = properties['street'] ??
//                 properties['address_line1'] ??
//                 properties['name'];
//
//             if (street != null && street.isNotEmpty) {
//               // Nettoyer le nom de la rue (enlever les numéros s'il y en a)
//               street = _cleanStreetName(street);
//               if (street.isNotEmpty) {
//                 uniqueStreets.add(street);
//               }
//             }
//           }
//           return uniqueStreets;
//         } else {
//           return const Iterable<String>.empty();
//         }
//       } else {
//         debugPrint("Erreur API Geoapify (Rue - ${response.statusCode}): ${response.body}");
//         return const Iterable<String>.empty();
//       }
//     } catch (e) {
//       debugPrint("Erreur de connexion Geoapify (Rue) : $e");
//       return const Iterable<String>.empty();
//     }
//   }
//
//   // Méthode pour nettoyer le nom de la rue (enlever les numéros de maison)
//   String _cleanStreetName(String street) {
//     // Supprimer les numéros au début ou à la fin de la chaîne, ainsi que les numéros avec lettres (ex: 12A)
//     return street.replaceAll(RegExp(r'^\d+\s*'), '') // Numéros au début
//         .replaceAll(RegExp(r'\s*\d+$'), '') // Numéros à la fin
//         .replaceAll(RegExp(r'^\d+[a-zA-Z]?\s*'), '') // Numéros avec lettres au début
//         .trim(); // Supprimer les espaces en début et fin
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Autocomplete<String>(
//       optionsBuilder: (TextEditingValue textEditingValue) {
//         // Appeler le callback lorsque le texte change (l'utilisateur tape)
//         // Note: Ce callback est appelé à chaque frappe dans Autocomplete.
//         widget.onStreetChanged?.call();
//
//         // optionsBuilder doit retourner un Future<Iterable<String>>.
//         // Appelle la fonction asynchrone fetchStreetSuggestions.
//         return fetchStreetSuggestions(textEditingValue.text);
//       },
//       onSelected: (String selection) {
//         // Cette méthode est appelée lorsqu'une suggestion est sélectionnée par l'utilisateur.
//         widget.streetController.text = selection; // Mettre à jour le contrôleur externe
//         widget.onStreetSelected?.call(); // Appeler le callback pour indiquer qu'une rue a été sélectionnée.
//
//         if (kDebugMode) {
//           print("Rue sélectionnée: $selection");
//         }
//       },
//       fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
//         // Ne PAS modifier controller.text ici. Laissez Autocomplete gérer son contrôleur interne.
//         // Utilisez simplement le 'controller' fourni par Autocomplete pour le TextField.
//
//         return TextField(
//           controller: controller, // Utilisez le contrôleur fourni par Autocomplete
//           focusNode: focusNode,
//           onEditingComplete: onEditingComplete,
//           decoration: InputDecoration(
//             labelText: "Tapez le nom de votre rue",
//             hintText: "Ex: Rue de la Paix, Avenue Louise...",
//             prefixIcon: Icon(Icons.search, color: Color(0xFF8E44AD)), // Icône de recherche
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(color: Colors.grey[300]!),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(color: Colors.grey[300]!),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(color: Color(0xFF8E44AD), width: 2),
//             ),
//             filled: true,
//             fillColor: Colors.white,
//             contentPadding: EdgeInsets.symmetric(vertical: 16),
//           ),
//           // Mettre à jour le contrôleur externe UNIQUEMENT lorsque le texte change.
//           // C'est ainsi que widget.streetController.text reste synchronisé.
//           onChanged: (text) {
//             widget.streetController.text = text;
//             widget.onStreetChanged?.call();
//           },
//         );
//       },
//       optionsViewBuilder: (context, onSelected, options) {
//         // Personnaliser l'apparence des suggestions.
//         return Align(
//           alignment: Alignment.topLeft,
//           child: Material(
//             elevation: 4, // Ombre portée
//             borderRadius: BorderRadius.circular(12),
//             child: Container(
//               constraints: BoxConstraints(
//                 maxHeight: 200, // Hauteur maximale de la liste des suggestions
//                 maxWidth: MediaQuery.of(context).size.width - 32, // Largeur basée sur l'écran
//               ),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.1),
//                     blurRadius: 10,
//                     spreadRadius: 1,
//                   ),
//                 ],
//               ),
//               child: ListView.builder(
//                 padding: EdgeInsets.zero,
//                 shrinkWrap: true,
//                 itemCount: options.length,
//                 itemBuilder: (context, index) {
//                   final String option = options.elementAt(index);
//                   return ListTile(
//                     leading: Icon(Icons.location_on, // Icône de localisation
//                         color: Color(0xFF8E44AD),
//                         size: 20),
//                     title: Text(
//                       option,
//                       style: TextStyle(fontSize: 14),
//                     ),
//                     dense: true, // Rendre la liste plus compacte
//                     onTap: () => onSelected(option), // Appeler onSelected quand un élément est tapé
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
