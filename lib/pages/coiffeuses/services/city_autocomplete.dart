////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//          WIDGET DE CHAMP DE SAISIE AVEC AUTOCOMPLÉTION POUR LES VILLES       //
//                                                                            //
//  Ce fichier définit le widget `CityAutocompleteField`, un composant        //
//  réutilisable qui fournit un champ de texte pour la saisie de villes. Il   //
//  interroge l'API Geoapify pour proposer des suggestions de villes en temps  //
//  réel à mesure que l'utilisateur tape.                                     //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Un `StatelessWidget` qui encapsule un champ de texte avec autocomplétion
/// pour les noms de villes en utilisant l'API Geoapify.
class CityAutocompleteField extends StatelessWidget {
  /// Le contrôleur pour le champ de texte, permettant de lire et de définir sa valeur.
  final TextEditingController controller;
  /// La fonction de callback à exécuter lorsqu'une ville est sélectionnée dans la liste.
  final void Function(String)? onCitySelected;
  /// La clé API nécessaire pour interroger le service Geoapify.
  final String apiKey;

  /// Constructeur pour le widget `CityAutocompleteField`.
  const CityAutocompleteField({
    super.key,
    required this.controller,
    required this.apiKey,
    this.onCitySelected,
  });

  /// Interroge l'API Geoapify pour obtenir des suggestions de villes basées sur la saisie.
  ///
  /// [query] : Le texte partiel saisi par l'utilisateur.
  ///
  /// Retourne une `Future` qui se résoudra en une liste de chaînes de caractères
  /// formatées (ex: "Paris, France") représentant les suggestions.
  Future<List<String>> fetchSuggestions(String query) async {
    // Ne lance pas de recherche si la requête est trop courte pour éviter les appels inutiles.
    if (query.length < 3) return [];

    // Construit l'URL pour l'API d'autocomplétion de Geoapify.
    final url = Uri.parse(
        'https://api.geoapify.com/v1/geocode/autocomplete?text=$query&type=city&lang=fr&limit=5&apiKey=$apiKey');

    try {
      // Effectue la requête HTTP GET.
      final response = await http.get(url);
      if (response.statusCode == 200) {
        // Si la requête réussit, décode la réponse JSON.
        final data = json.decode(response.body);
        final features = data['features'] as List<dynamic>;

        // Mappe les résultats JSON en une liste de chaînes de caractères formatées.
        return features.map<String>((feature) {
          final props = feature['properties'];
          final city = props['city'] ?? props['name'] ?? '';
          final country = props['country'] ?? '';
          return "$city, $country";
        }).toList();
      }
    } catch (e) {
      // En cas d'erreur réseau ou de parsing, affiche l'erreur dans la console.
      if (kDebugMode) {
        print("Erreur autocomplete Geoapify : $e");
      }
    }

    // Retourne une liste vide en cas d'échec.
    return [];
  }

  @override
  Widget build(BuildContext context) {
    // Utilise le widget `Autocomplete` intégré de Flutter.
    return Autocomplete<String>(
      /// `optionsBuilder` est appelé à chaque modification du champ de texte.
      /// Il est chargé de fournir la liste des suggestions.
      optionsBuilder: (TextEditingValue textEditingValue) async {
        // Ne fait rien si le texte est trop court.
        if (textEditingValue.text.length < 3) return const Iterable<String>.empty();
        // Appelle la méthode `fetchSuggestions` pour obtenir les suggestions de l'API.
        return await fetchSuggestions(textEditingValue.text);
      },

      /// `onSelected` est appelé lorsque l'utilisateur choisit une suggestion.
      onSelected: (String selection) {
        // Met à jour le contrôleur avec la sélection.
        controller.text = selection;
        // Exécute le callback fourni, s'il existe.
        if (onCitySelected != null) onCitySelected!(selection);
      },

      /// `fieldViewBuilder` définit l'apparence du champ de saisie lui-même.
      fieldViewBuilder: (context, textEditingController, focusNode, onEditingComplete) {
        return TextField(
          controller: textEditingController,
          focusNode: focusNode,
          onEditingComplete: onEditingComplete,
          decoration: const InputDecoration(
            labelText: 'Ville',
            border: OutlineInputBorder(),
          ),
        );
      },
    );
  }
}





// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
//
// class CityAutocompleteField extends StatelessWidget {
//   final TextEditingController controller;
//   final void Function(String)? onCitySelected;
//   final String apiKey;
//
//   const CityAutocompleteField({
//     super.key,
//     required this.controller,
//     required this.apiKey,
//     this.onCitySelected,
//   });
//
//   Future<List<String>> fetchSuggestions(String query) async {
//     if (query.length < 3) return [];
//
//     final url = Uri.parse(
//         'https://api.geoapify.com/v1/geocode/autocomplete?text=$query&type=city&lang=fr&limit=5&apiKey=$apiKey');
//
//     try {
//       final response = await http.get(url);
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         final features = data['features'] as List<dynamic>;
//
//         return features.map<String>((feature) {
//           final props = feature['properties'];
//           final city = props['city'] ?? props['name'] ?? '';
//           final country = props['country'] ?? '';
//           return "$city, $country";
//         }).toList();
//       }
//     } catch (e) {
//       print("❌ Erreur autocomplete Geoapify : $e");
//     }
//
//     return [];
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Autocomplete<String>(
//       optionsBuilder: (TextEditingValue textEditingValue) async {
//         if (textEditingValue.text.length < 3) return const Iterable<String>.empty();
//         return await fetchSuggestions(textEditingValue.text);
//       },
//       onSelected: (String selection) {
//         controller.text = selection;
//         if (onCitySelected != null) onCitySelected!(selection);
//       },
//       fieldViewBuilder: (context, textEditingController, focusNode, onEditingComplete) {
//         return TextField(
//           controller: textEditingController,
//           focusNode: focusNode,
//           onEditingComplete: onEditingComplete,
//           decoration: const InputDecoration(
//             labelText: 'Ville',
//             border: OutlineInputBorder(),
//           ),
//         );
//       },
//     );
//   }
// }
