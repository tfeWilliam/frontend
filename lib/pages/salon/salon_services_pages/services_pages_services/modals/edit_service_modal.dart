////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//          FONCTIONNALITÉ DE MODIFICATION DE SERVICE (VIA MODAL)               //
//                                                                            //
//  Ce fichier définit une unique fonction, `showEditServiceModal`, qui       //
//  encapsule toute la logique et l'interface utilisateur nécessaires pour    //
//  modifier les détails d'un service existant (principalement son prix et    //
//  sa durée).                                                                //
//                                                                            //
//  Approche :                                                                //
//  - Une seule fonction est exposée pour lancer le processus.                //
//  - L'interface est construite dans une "modal bottom sheet" qui est        //
//    redimensionnable (`DraggableScrollableSheet`).                          //
//  - L'état de la boîte de dialogue (valeurs, erreurs, chargement) est géré  //
//    localement à l'aide d'un `StatefulBuilder`.                             //
//  - La logique de validation et de soumission à l'API est contenue dans des //
//    fonctions imbriquées, rendant le composant autonome.                    //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../../../models/service_with_promo.dart';
import '../../../../../services/firebase_token/token_service.dart';
import '../../../../../services/providers/current_user_provider.dart';

/// Affiche une feuille modale (bottom sheet) pour modifier les détails
/// (prix, durée) d'un service existant.
///
/// Cette fonction gère l'état complet du formulaire, la validation en temps réel,
/// la communication avec l'API pour la mise à jour, et les retours visuels à l'utilisateur.
///
/// [context] : Le `BuildContext` parent pour afficher la modal.
/// [serviceWithPromo] : L'objet service contenant les données actuelles à modifier.
/// [onSuccess] : Une fonction de callback exécutée après une mise à jour réussie.
void showEditServiceModal(BuildContext context, ServiceWithPromo serviceWithPromo, VoidCallback onSuccess) {
  /// Contrôleurs pour les champs de texte du formulaire, pré-remplis avec les données existantes.
  final TextEditingController nameController = TextEditingController(text: serviceWithPromo.intitule);
  final TextEditingController descriptionController = TextEditingController(text: serviceWithPromo.description);
  final TextEditingController priceController = TextEditingController(text: serviceWithPromo.prix.toString());
  final TextEditingController durationController = TextEditingController(text: serviceWithPromo.temps.toString());

  /// État de chargement pour désactiver le bouton de soumission pendant un appel API.
  bool isLoading = false;
  /// Couleurs thématiques pour l'UI.
  final Color primaryViolet = const Color(0xFF7B61FF);
  final Color errorRed = Colors.red;
  final Color successGreen = Colors.green;

  /// Maps pour suivre les erreurs de validation et la validité de chaque champ.
  Map<String, String?> errors = {'price': null, 'duration': null};
  Map<String, bool> isValid = {'price': true, 'duration': true};

  /// Vérifie si un nombre a au plus deux décimales.
  bool hasAtMostTwoDecimalPlaces(double value) {
    return ((value * 100).roundToDouble() == (value * 100));
  }

  /// Affiche une animation de succès simple et temporaire.
  void showSuccessAnimation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 60),
              SizedBox(height: 10),
              Text("Modifié !", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

  /// Valide la valeur d'un champ spécifique et met à jour l'état des erreurs.
  void validateField(String key, String value, StateSetter setModalState) {
    // La logique de validation est appliquée ici.
    switch (key) {
      case 'price':
        final parsed = double.tryParse(value);
        if (value.isEmpty) { errors[key] = "Prix requis"; isValid[key] = false; }
        else if (parsed == null) { errors[key] = "Nombre invalide"; isValid[key] = false; }
        else if (parsed <= 0) { errors[key] = "Prix doit être positif"; isValid[key] = false; }
        else if (parsed > 999) { errors[key] = "Maximum 999€"; isValid[key] = false; }
        else if (!hasAtMostTwoDecimalPlaces(parsed)) { errors[key] = "Max 2 décimales"; isValid[key] = false; }
        else { errors[key] = null; isValid[key] = true; }
        break;
      case 'duration':
        final parsed = int.tryParse(value);
        if (value.isEmpty) { errors[key] = "Durée requise"; isValid[key] = false; }
        else if (parsed == null || parsed <= 0) { errors[key] = "Durée invalide"; isValid[key] = false; }
        else if (parsed > 480) { errors[key] = "Max 480 minutes"; isValid[key] = false; }
        else { errors[key] = null; isValid[key] = true; }
        break;
    }
    // Met à jour l'état de la modal pour refléter les erreurs de validation.
    setModalState(() {});
  }

  /// Construit un widget `TextField` personnalisé avec une validation visuelle dynamique.
  Widget buildTextField(String label, TextEditingController controller, IconData icon, String fieldKey, StateSetter setModalState, {TextInputType? keyboardType, int maxLines = 1, bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            readOnly: readOnly,
            onChanged: readOnly ? null : (val) => validateField(fieldKey, val, setModalState),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: primaryViolet),
              suffixIcon: readOnly ? null : errors[fieldKey] != null ? Icon(Icons.close, color: errorRed) : (isValid[fieldKey]! ? Icon(Icons.check_circle, color: successGreen) : null),
              labelText: label,
              filled: true,
              fillColor: readOnly ? Colors.grey[200] : Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: readOnly ? BorderSide.none : errors[fieldKey] != null ? BorderSide(color: errorRed) : (isValid[fieldKey]! ? BorderSide(color: successGreen) : BorderSide.none)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: primaryViolet, width: 2)),
            ),
          ),
          if (!readOnly && errors[fieldKey] != null)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 4),
              child: Row(children: [Icon(Icons.error_outline, color: errorRed, size: 16), const SizedBox(width: 4), Expanded(child: Text(errors[fieldKey]!, style: TextStyle(color: errorRed, fontSize: 12)))]),
            ),
        ],
      ),
    );
  }

  /// Gère la soumission du formulaire, l'appel API pour la mise à jour et la gestion des réponses.
  Future<void> updateService(StateSetter setModalState) async {
    final prixText = priceController.text.trim();
    final durationText = durationController.text.trim();

    validateField('price', prixText, setModalState);
    validateField('duration', durationText, setModalState);

    if (errors['price'] != null || errors['duration'] != null) return;

    setModalState(() => isLoading = true);

    try {
      final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
      final currentUser = currentUserProvider.currentUser;
      if (currentUser == null) throw Exception("Utilisateur non connecté");

      final authToken = await TokenService.getAuthToken();
      if (authToken == null) throw Exception("Token d'authentification non trouvé");

      // Effectue l'appel API `PUT` pour mettre à jour le service.
      final response = await http.put(
        Uri.parse('https://www.hairbnb.site/api/update_service/${serviceWithPromo.id}/'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $authToken'},
        body: json.encode({'userId': currentUser.idTblUser, 'prix': double.parse(prixText), 'temps_minutes': int.parse(durationText)}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          showSuccessAnimation(context);
          Future.delayed(const Duration(milliseconds: 1500), () {
            Navigator.of(context).pop();
            Navigator.of(context).pop(true);
            onSuccess();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: ${responseData['message'] ?? 'Erreur inconnue'}"), backgroundColor: Colors.red));
        }
      } else {
        // Gère les erreurs HTTP, en essayant de parser le message d'erreur du backend.
        String errorMessage = "Erreur inconnue";
        try {
          final errorData = json.decode(response.body);
          if (errorData.containsKey('errors')) {
            final errors = errorData['errors'];
            if (errors is Map) {
              final firstError = errors.values.first;
              if (firstError is List && firstError.isNotEmpty) {
                errorMessage = firstError.first.toString();
              } else {
                errorMessage = firstError.toString();
              }
            }
          } else if (errorData.containsKey('message')) {
            errorMessage = errorData['message'];
          }
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $errorMessage"), backgroundColor: Colors.red));
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur ${response.statusCode}: ${response.body}"), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur de connexion: $e"), backgroundColor: Colors.red));
    } finally {
      setModalState(() => isLoading = false);
    }
  }

  // Affiche la feuille modale (bottom sheet) avec le formulaire.
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) => AnimatedPadding(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: MediaQuery.of(context).viewInsets + const EdgeInsets.all(10),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) => Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFF7F7F9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ListView(
              controller: scrollController,
              children: [
                // Poignée de la modal.
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                // Titre.
                const Text("Modifier le service", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                const SizedBox(height: 30),
                // Champs du formulaire.
                buildTextField("Nom du service", nameController, Icons.design_services, 'name', setModalState, readOnly: true),
                buildTextField("Description", descriptionController, Icons.description, 'description', setModalState, maxLines: 3, readOnly: true),
                buildTextField("Prix (€)", priceController, Icons.euro, 'price', setModalState, keyboardType: TextInputType.number),
                buildTextField("Durée (minutes)", durationController, Icons.timer, 'duration', setModalState, keyboardType: TextInputType.number),
                const SizedBox(height: 20),
                // Bouton de soumission.
                ElevatedButton(
                  onPressed: isLoading ? null : () => updateService(setModalState),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryViolet,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Enregistrer les modifications", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}






// import 'package:flutter/material.dart';
// import 'package:hairbnb/services/firebase_token/token_service.dart';
// import 'package:hairbnb/services/providers/current_user_provider.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:provider/provider.dart';
// import '../../../../../models/service_with_promo.dart';
//
// Future<void> showEditServiceModal(BuildContext context, ServiceWithPromo serviceWithPromo, VoidCallback onSuccess) {
//   final TextEditingController nameController = TextEditingController(text: serviceWithPromo.intitule);
//   final TextEditingController descriptionController = TextEditingController(text: serviceWithPromo.description);
//   final TextEditingController priceController = TextEditingController(text: serviceWithPromo.prix.toString());
//   final TextEditingController durationController = TextEditingController(text: serviceWithPromo.temps.toString());
//
//   bool isLoading = false;
//   final Color primaryViolet = const Color(0xFF7B61FF);
//   final Color errorRed = Colors.red;
//   final Color successGreen = Colors.green;
//
//   Map<String, String?> errors = {'price': null, 'duration': null};
//   Map<String, bool> isValid = {'price': true, 'duration': true};
//
//   bool hasAtMostTwoDecimalPlaces(double value) {
//     return ((value * 100).roundToDouble() == (value * 100));
//   }
//
//   void showSuccessAnimation(BuildContext context) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => Dialog(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         child: Container(
//           width: 100,
//           height: 100,
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: const Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.check_circle, color: Colors.green, size: 60),
//               SizedBox(height: 10),
//               Text("Modifié !", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   void validateField(String key, String value, StateSetter setModalState) {
//     switch (key) {
//       case 'price':
//         final parsed = double.tryParse(value);
//         if (value.isEmpty) {
//           errors[key] = "Prix requis";
//           isValid[key] = false;
//         } else if (parsed == null) {
//           errors[key] = "Nombre invalide";
//           isValid[key] = false;
//         } else if (parsed <= 0) {
//           errors[key] = "Prix doit être positif";
//           isValid[key] = false;
//         } else if (parsed > 999) {
//           errors[key] = "Maximum 999€";
//           isValid[key] = false;
//         } else if (!hasAtMostTwoDecimalPlaces(parsed)) {
//           errors[key] = "Max 2 décimales";
//           isValid[key] = false;
//         } else {
//           errors[key] = null;
//           isValid[key] = true;
//         }
//         break;
//
//       case 'duration':
//         final parsed = int.tryParse(value);
//         if (value.isEmpty) {
//           errors[key] = "Durée requise";
//           isValid[key] = false;
//         } else if (parsed == null || parsed <= 0) {
//           errors[key] = "Durée invalide";
//           isValid[key] = false;
//         } else if (parsed > 480) {
//           errors[key] = "Max 480 minutes";
//           isValid[key] = false;
//         } else {
//           errors[key] = null;
//           isValid[key] = true;
//         }
//         break;
//     }
//
//     setModalState(() {});
//   }
//
//   Widget buildTextField(
//       String label,
//       TextEditingController controller,
//       IconData icon,
//       String fieldKey,
//       StateSetter setModalState, {
//         TextInputType? keyboardType,
//         int maxLines = 1,
//         bool readOnly = false,
//       }) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           TextField(
//             controller: controller,
//             maxLines: maxLines,
//             keyboardType: keyboardType,
//             readOnly: readOnly,
//             onChanged: readOnly ? null : (val) => validateField(fieldKey, val, setModalState),
//             decoration: InputDecoration(
//               prefixIcon: Icon(icon, color: primaryViolet),
//               suffixIcon: readOnly
//                   ? null
//                   : errors[fieldKey] != null
//                   ? Icon(Icons.close, color: errorRed)
//                   : (isValid[fieldKey]! ? Icon(Icons.check_circle, color: successGreen) : null),
//               labelText: label,
//               filled: true,
//               fillColor: readOnly ? Colors.grey[200] : Colors.white,
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(14),
//                 borderSide: BorderSide.none,
//               ),
//               enabledBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(14),
//                 borderSide: readOnly
//                     ? BorderSide.none
//                     : errors[fieldKey] != null
//                     ? BorderSide(color: errorRed)
//                     : (isValid[fieldKey]! ? BorderSide(color: successGreen) : BorderSide.none),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(14),
//                 borderSide: BorderSide(color: primaryViolet, width: 2),
//               ),
//             ),
//           ),
//           if (!readOnly && errors[fieldKey] != null)
//             Padding(
//               padding: const EdgeInsets.only(left: 12, top: 4),
//               child: Row(
//                 children: [
//                   Icon(Icons.error_outline, color: errorRed, size: 16),
//                   const SizedBox(width: 4),
//                   Expanded(
//                     child: Text(errors[fieldKey]!, style: TextStyle(color: errorRed, fontSize: 12)),
//                   ),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> updateService(StateSetter setModalState) async {
//     final prixText = priceController.text.trim();
//     final durationText = durationController.text.trim();
//
//     // Validation uniquement pour prix et durée
//     validateField('price', prixText, setModalState);
//     validateField('duration', durationText, setModalState);
//
//     // Vérifie les erreurs uniquement pour les champs modifiables
//     if (errors['price'] != null || errors['duration'] != null) return;
//
//     setModalState(() => isLoading = true);
//
//     try {
//       // Récupération de l'utilisateur connecté
//       final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//       final currentUser = currentUserProvider.currentUser;
//
//       if (currentUser == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//               content: Text("Erreur: Utilisateur non connecté"),
//               backgroundColor: Colors.red
//           ),
//         );
//         return;
//       }
//
//       // Récupération du token d'authentification
//       final authToken = await TokenService.getAuthToken();
//
//       if (authToken == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//               content: Text("Erreur: Token d'authentification non trouvé"),
//               backgroundColor: Colors.red
//           ),
//         );
//         return;
//       }
//
//       final response = await http.put(
//         Uri.parse('https://www.hairbnb.site/api/update_service/${serviceWithPromo.id}/'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $authToken',
//         },
//         body: json.encode({
//           'userId': currentUser.idTblUser,
//           'prix': double.parse(prixText),
//           'temps_minutes': int.parse(durationText),
//         }),
//       );
//
//       if (response.statusCode == 200) {
//         final responseData = json.decode(response.body);
//         if (responseData['status'] == 'success') {
//           showSuccessAnimation(context);
//           Future.delayed(const Duration(milliseconds: 1500), () {
//             Navigator.of(context).pop(); // success modal
//             Navigator.of(context).pop(true); // bottom sheet
//             onSuccess();
//           });
//         } else {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//                 content: Text("Erreur: ${responseData['message'] ?? 'Erreur inconnue'}"),
//                 backgroundColor: Colors.red
//             ),
//           );
//         }
//       } else {
//         // Gestion des erreurs de validation du backend
//         try {
//           final errorData = json.decode(response.body);
//           String errorMessage = "Erreur inconnue";
//
//           if (errorData.containsKey('errors')) {
//             final errors = errorData['errors'];
//             if (errors is Map) {
//               final firstError = errors.values.first;
//               if (firstError is List && firstError.isNotEmpty) {
//                 errorMessage = firstError.first.toString();
//               } else {
//                 errorMessage = firstError.toString();
//               }
//             }
//           } else if (errorData.containsKey('message')) {
//             errorMessage = errorData['message'];
//           }
//
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//                 content: Text("Erreur: $errorMessage"),
//                 backgroundColor: Colors.red
//             ),
//           );
//         } catch (e) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//                 content: Text("Erreur ${response.statusCode}: ${response.body}"),
//                 backgroundColor: Colors.red
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//             content: Text("Erreur de connexion: $e"),
//             backgroundColor: Colors.red
//         ),
//       );
//     } finally {
//       setModalState(() => isLoading = false);
//     }
//   }
//
//   return showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     backgroundColor: Colors.transparent,
//     builder: (context) => StatefulBuilder(
//       builder: (context, setModalState) => AnimatedPadding(
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeOut,
//         padding: MediaQuery.of(context).viewInsets + const EdgeInsets.all(10),
//         child: DraggableScrollableSheet(
//           expand: false,
//           initialChildSize: 0.85,
//           maxChildSize: 0.95,
//           minChildSize: 0.5,
//           builder: (context, scrollController) => Container(
//             padding: const EdgeInsets.all(20),
//             decoration: const BoxDecoration(
//               color: Color(0xFFF7F7F9),
//               borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//             ),
//             child: ListView(
//               controller: scrollController,
//               children: [
//                 Center(
//                   child: Container(
//                     width: 40,
//                     height: 5,
//                     margin: const EdgeInsets.only(bottom: 20),
//                     decoration: BoxDecoration(
//                       color: Colors.grey[300],
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                 ),
//                 const Text("Modifier le service", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
//                 const SizedBox(height: 30),
//                 buildTextField("Nom du service", nameController, Icons.design_services, 'name', setModalState, readOnly: true),
//                 buildTextField("Description", descriptionController, Icons.description, 'description', setModalState, maxLines: 3, readOnly: true),
//                 buildTextField("Prix (€)", priceController, Icons.euro, 'price', setModalState, keyboardType: TextInputType.number),
//                 buildTextField("Durée (minutes)", durationController, Icons.timer, 'duration', setModalState, keyboardType: TextInputType.number),
//                 const SizedBox(height: 20),
//                 ElevatedButton(
//                   onPressed: isLoading ? null : () => updateService(setModalState),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: primaryViolet,
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//                     elevation: 4,
//                   ),
//                   child: isLoading
//                       ? const CircularProgressIndicator(color: Colors.white)
//                       : const Text("Enregistrer les modifications", style: TextStyle(fontWeight: FontWeight.bold)),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     ),
//   );
// }
//
