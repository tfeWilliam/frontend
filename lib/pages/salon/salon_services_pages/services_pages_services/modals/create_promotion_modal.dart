/// *************************************************************************************************
///
/// BANNER : EXPLICATION GÉNÉRALE DU FICHIER
///
/// Ce fichier définit une unique fonction globale, `showCreatePromotionModal`.
///
/// Objectif :
/// Fournir une interface utilisateur complète et autonome, sous la forme d'une feuille
/// modale (bottom sheet), pour permettre à une coiffeuse de créer une nouvelle promotion
/// pour un service spécifique de son salon.
///
/// Fonctionnalités Clés :
/// - Interface Utilisateur Interactive : La modale est construite avec un
/// `DraggableScrollableSheet`, permettant à l'utilisateur de l'agrandir. Elle s'adapte
/// également à l'apparition du clavier grâce à `AnimatedPadding`.
/// - Validation en Temps Réel : Utilise `StatefulBuilder` pour gérer un état local
/// (valeurs des champs, erreurs, chargement) et valider les entrées de l'utilisateur
/// au fur et à mesure, affichant des messages d'erreur directement sous les champs concernés.
/// - Logique de Soumission Complète :
/// - Valide les IDs du salon et du service avant d'afficher la modale.
/// - Formate les dates pour l'API afin d'éviter les problèmes de fuseau horaire.
/// - Appelle l'API backend via une requête POST pour créer la promotion.
/// - Gère les différents cas de réponse de l'API (succès, erreur de validation,
/// ressource non trouvée, erreur serveur) et affiche un feedback approprié à
/// l'utilisateur (dialogue de succès, message d'erreur détaillé).
/// - Gestion des Callbacks : Exécute une fonction de rappel `onPromoAdded` après
/// un succès pour permettre à l'écran parent de se rafraîchir.
///
///*************************************************************************************************
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Affiche une feuille modale pour la création d'une nouvelle promotion.
///
/// [context] : Le BuildContext de la page appelante.
/// [salonId] : L'ID du salon auquel la promotion est liée.
/// [serviceId] : L'ID du service sur lequel la promotion s'applique.
/// [onPromoAdded] : Callback exécuté après la création réussie de la promotion.
void showCreatePromotionModal({
  required BuildContext context,
  required int salonId,
  required int serviceId,
  required VoidCallback onPromoAdded,
}) {

  // --- Validation initiale des IDs ---
  // Vérifie que les IDs passés en paramètres sont valides avant d'ouvrir la modale.
  if (salonId <= 0) {
    if (kDebugMode) print('❌ ERREUR: salonId invalide ($salonId)');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ID du salon invalide ($salonId)'), backgroundColor: Colors.red));
    return;
  }
  if (serviceId <= 0) {
    if (kDebugMode) print('❌ ERREUR: serviceId invalide ($serviceId)');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ID du service invalide ($serviceId)'), backgroundColor: Colors.red));
    return;
  }

  // --- État local de la modale ---
  final TextEditingController discountController = TextEditingController();
  DateTime? startDate;
  DateTime? endDate;
  bool isLoading = false;
  String? errorMessage; // Message d'erreur global (affiché dans une bannière).

  // Couleurs
  final Color primaryViolet = const Color(0xFF7B61FF);
  final Color errorRed = Colors.red;
  final Color successGreen = Colors.green;

  // Map pour stocker les messages d'erreur spécifiques à chaque champ.
  Map<String, String?> errors = {'discount': null, 'startDate': null, 'endDate': null};
  // Map pour suivre la validité de chaque champ (pourrait être utilisé pour le style).
  Map<String, bool> isValid = {'discount': false, 'startDate': false, 'endDate': false};

  /// Valide tous les champs du formulaire et met à jour l'état de la modale.
  void validateFields(StateSetter setModalState) {
    final discountText = discountController.text.trim();
    final double? discount = double.tryParse(discountText);

    setModalState(() {
      errorMessage = null; // Réinitialise le message d'erreur global.

      // Valide le pourcentage de réduction.
      if (discount == null || discount <= 0 || discount > 100) {
        errors['discount'] = "Pourcentage invalide (entre 1 et 100)";
        isValid['discount'] = false;
      } else {
        errors['discount'] = null;
        isValid['discount'] = true;
      }

      // Valide la date de début.
      if (startDate == null) {
        errors['startDate'] = "La date de début est requise";
        isValid['startDate'] = false;
      } else {
        errors['startDate'] = null;
        isValid['startDate'] = true;
      }

      // Valide la date de fin.
      if (endDate == null) {
        errors['endDate'] = "La date de fin est requise";
        isValid['endDate'] = false;
      } else if (startDate != null && endDate!.isBefore(startDate!)) {
        errors['endDate'] = "La date de fin doit être après la date de début";
        isValid['endDate'] = false;
      } else {
        errors['endDate'] = null;
        isValid['endDate'] = true;
      }
    });
  }

  /// Formate une `DateTime` en chaîne "YYYY-MM-DD" sans conversion de fuseau horaire.
  /// C'est crucial pour s'assurer que le backend interprète la date correctement.
  String formatDateForApi(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Soumet les données de la promotion à l'API.
  Future<void> submitPromotion(StateSetter setModalState, BuildContext innerContext) async {
    // Lance la validation une dernière fois avant la soumission.
    validateFields(setModalState);
    if (errors.values.any((e) => e != null)) return; // Arrête si une erreur de validation existe.

    // Prépare le corps de la requête avec les données formatées.
    final promotionData = {
      'discount_percentage': double.parse(discountController.text.trim()),
      'start_date': formatDateForApi(startDate!),
      'end_date': formatDateForApi(endDate!),
    };

    setModalState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Log de débogage pour vérifier les données envoyées.
      if (kDebugMode) {
        print('📅 Dates envoyées à l\'API:');
        print('   - Début sélectionné: ${startDate!.toLocal()}, Fin sélectionnée: ${endDate!.toLocal()}');
        print('   - Début formaté API: ${promotionData['start_date']}, Fin formatée API: ${promotionData['end_date']}');
      }

      // Construit l'URL de l'API avec les IDs du salon et du service.
      final url = 'https://www.hairbnb.site/api/salon/$salonId/service/$serviceId/promotion/';

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'}, // IMPORTANT: Spécifier le type de contenu.
        body: json.encode(promotionData),
      );

      // Traite la réponse du serveur.
      if (response.statusCode == 201) { // 201 Created : Succès
        if (kDebugMode) print('✅ Promotion créée avec succès !');
        // Affiche un dialogue de succès temporaire.
        showDialog(context: innerContext, barrierDismissible: false, builder: (context) => Dialog(backgroundColor: Colors.transparent, elevation: 0, child: Container(width: 100, height: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.check_circle, color: successGreen, size: 60), const SizedBox(height: 10), const Text("Promotion ajoutée !", style: TextStyle(fontWeight: FontWeight.bold))]))));
        // Attend un peu, puis ferme les dialogues et exécute le callback.
        Future.delayed(const Duration(milliseconds: 1500), () {
          Navigator.of(innerContext).pop(); // Ferme le dialogue de succès.
          Navigator.of(innerContext).pop(true); // Ferme la feuille modale.
          onPromoAdded(); // Notifie la page parente.
        });

      } else if (response.statusCode == 400) { // 400 Bad Request : Erreur de validation côté serveur.
        String errorText = "Impossible de créer la promotion.";
        try {
          // Tente de parser un message d'erreur détaillé depuis la réponse du backend.
          final errorData = json.decode(utf8.decode(response.bodyBytes));
          if (kDebugMode) print('❌ Erreur 400 détails: $errorData');
          if (errorData is Map) {
            errorText = errorData['error'] ?? errorData['detail'] ?? errorData['message'] ?? errorData.toString();
          }
        } catch (e) {
          if (kDebugMode) print('❌ Erreur lors du parsing de l\'erreur: $e');
          errorText = response.body;
        }
        setModalState(() { errorMessage = errorText; isLoading = false; });

      } else if (response.statusCode == 404) { // 404 Not Found
        if (kDebugMode) print('❌ Erreur 404: Ressource non trouvée');
        setModalState(() { errorMessage = "Service ou salon introuvable (404). Vérifiez les IDs."; isLoading = false; });

      } else { // Gère toutes les autres erreurs HTTP.
        if (kDebugMode) print('❌ Erreur HTTP ${response.statusCode}: ${response.body}');
        setModalState(() { errorMessage = "Erreur serveur (${response.statusCode}): ${response.reasonPhrase}"; isLoading = false; });
      }

    } catch (e, stackTrace) { // Gère les exceptions (ex: erreur réseau).
      if (kDebugMode) { print('❌ Exception lors de la création: $e\n📍 StackTrace: $stackTrace'); }
      setModalState(() { errorMessage = "Erreur de connexion: $e"; isLoading = false; });
    }
  }

  // Affiche la feuille modale.
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Permet à la modale de s'ajuster au clavier.
    backgroundColor: Colors.transparent,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) => Builder( // Utilise un Builder pour obtenir un 'innerContext' valide pour les dialogues.
        builder: (innerContext) => AnimatedPadding(
          duration: const Duration(milliseconds: 300),
          padding: MediaQuery.of(innerContext).viewInsets + const EdgeInsets.all(10), // S'adapte au clavier.
          child: DraggableScrollableSheet(
            initialChildSize: 0.75, maxChildSize: 0.95, minChildSize: 0.5, expand: false,
            builder: (context, scrollController) => Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Color(0xFFF7F7F9), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              child: ListView(
                controller: scrollController,
                children: [
                  // Poignée pour indiquer que la feuille est déplaçable.
                  Center(child: Container(width: 40, height: 5, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)))),
                  const Text("Ajouter une promotion", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),

                  // Champ pour le pourcentage de réduction.
                  TextField(
                    controller: discountController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => validateFields(setModalState), // Valide à chaque changement.
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))], // N'autorise que les chiffres.
                    decoration: InputDecoration(prefixIcon: Icon(Icons.percent, color: primaryViolet), labelText: "Pourcentage de réduction", errorText: errors['discount'], border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
                  ),
                  const SizedBox(height: 20),

                  // Sélecteur pour la date de début.
                  ListTile(
                    title: Text(startDate == null ? "Choisir une date de début" : "Début : ${formatDateForApi(startDate!)}"),
                    trailing: Icon(Icons.calendar_today, color: primaryViolet),
                    onTap: () async {
                      final picked = await showDatePicker(context: innerContext, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                      if (picked != null) { setModalState(() => startDate = picked); validateFields(setModalState); }
                    },
                    subtitle: errors['startDate'] != null ? Text(errors['startDate']!, style: TextStyle(color: errorRed, fontSize: 12)) : null,
                  ),

                  // Sélecteur pour la date de fin.
                  ListTile(
                    title: Text(endDate == null ? "Choisir une date de fin" : "Fin : ${formatDateForApi(endDate!)}"),
                    trailing: Icon(Icons.calendar_today, color: primaryViolet),
                    onTap: () async {
                      final picked = await showDatePicker(context: innerContext, initialDate: startDate ?? DateTime.now(), firstDate: startDate ?? DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 730)));
                      if (picked != null) { setModalState(() => endDate = picked); validateFields(setModalState); }
                    },
                    subtitle: errors['endDate'] != null ? Text(errors['endDate']!, style: TextStyle(color: errorRed, fontSize: 12)) : null,
                  ),
                  const SizedBox(height: 20),

                  // Affiche la bannière d'erreur globale si nécessaire.
                  if (errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: errorRed.withAlpha(25), borderRadius: BorderRadius.circular(8), border: Border.all(color: errorRed)),
                      child: Row(children: [Icon(Icons.error_outline, color: errorRed), const SizedBox(width: 10), Expanded(child: Text(errorMessage!, style: TextStyle(color: errorRed)))]),
                    ),
                  const SizedBox(height: 20),

                  // Bouton de soumission.
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () => submitPromotion(setModalState, innerContext),
                      style: ElevatedButton.styleFrom(backgroundColor: primaryViolet, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Créer la promotion", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}








// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// void showCreatePromotionModal({
//   required BuildContext context,
//   required int salonId,
//   required int serviceId,
//   required VoidCallback onPromoAdded,
// }) {
//
//   // Vérifier que les IDs sont valides
//   if (salonId <= 0) {
//     if (kDebugMode) {
//       print('❌ ERREUR: salonId invalide ($salonId)');
//     }
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Erreur: ID du salon invalide ($salonId)'),
//         backgroundColor: Colors.red,
//       ),
//     );
//     return;
//   }
//
//   if (serviceId <= 0) {
//     if (kDebugMode) {
//       print('❌ ERREUR: serviceId invalide ($serviceId)');
//     }
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Erreur: ID du service invalide ($serviceId)'),
//         backgroundColor: Colors.red,
//       ),
//     );
//     return;
//   }
//
//   final TextEditingController discountController = TextEditingController();
//   DateTime? startDate;
//   DateTime? endDate;
//   bool isLoading = false;
//   String? errorMessage;
//
//   final Color primaryViolet = const Color(0xFF7B61FF);
//   final Color errorRed = Colors.red;
//   final Color successGreen = Colors.green;
//
//   Map<String, String?> errors = {
//     'discount': null,
//     'startDate': null,
//     'endDate': null,
//   };
//
//   Map<String, bool> isValid = {
//     'discount': false,
//     'startDate': false,
//     'endDate': false,
//   };
//
//   void validateFields(StateSetter setModalState) {
//     final discountText = discountController.text.trim();
//     final double? discount = double.tryParse(discountText);
//
//     setModalState(() {
//       errorMessage = null;
//
//       if (discount == null || discount <= 0 || discount > 100) {
//         errors['discount'] = "Pourcentage invalide (1-100%)";
//         isValid['discount'] = false;
//       } else {
//         errors['discount'] = null;
//         isValid['discount'] = true;
//       }
//
//       if (startDate == null) {
//         errors['startDate'] = "Date de début requise";
//         isValid['startDate'] = false;
//       } else {
//         errors['startDate'] = null;
//         isValid['startDate'] = true;
//       }
//
//       if (endDate == null) {
//         errors['endDate'] = "Date de fin requise";
//         isValid['endDate'] = false;
//       } else if (startDate != null && endDate!.isBefore(startDate!)) {
//         errors['endDate'] = "Fin doit être après le début";
//         isValid['endDate'] = false;
//       } else {
//         errors['endDate'] = null;
//         isValid['endDate'] = true;
//       }
//     });
//   }
//
//   // 🔥 NOUVELLE FONCTION : Formatage des dates sans problème de fuseau horaire
//   String formatDateForApi(DateTime date) {
//     // Format YYYY-MM-DD sans conversion UTC
//     final year = date.year.toString();
//     final month = date.month.toString().padLeft(2, '0');
//     final day = date.day.toString().padLeft(2, '0');
//     return '$year-$month-$day';
//   }
//
//   Future<void> submitPromotion(StateSetter setModalState, BuildContext innerContext) async {
//     validateFields(setModalState);
//     if (errors.values.any((e) => e != null)) return;
//
//     // 🔥 CORRECTION : Utiliser la nouvelle fonction de formatage des dates
//     final promotionData = {
//       'discount_percentage': double.parse(discountController.text.trim()),
//       'start_date': formatDateForApi(startDate!), // 🔥 NOUVEAU : Sans problème de fuseau horaire
//       'end_date': formatDateForApi(endDate!),     // 🔥 NOUVEAU : Sans problème de fuseau horaire
//     };
//
//     setModalState(() {
//       isLoading = true;
//       errorMessage = null;
//     });
//
//     try {
//       // 🔍 DEBUG : Afficher les dates envoyées
//       if (kDebugMode) {
//         print('📅 Dates envoyées à l\'API:');
//         print('   - Date début sélectionnée: ${startDate!.toLocal()}');
//         print('   - Date fin sélectionnée: ${endDate!.toLocal()}');
//         print('   - Date début API: ${promotionData['start_date']}');
//         print('   - Date fin API: ${promotionData['end_date']}');
//       }
//
//       // Utiliser la nouvelle URL avec salon_id et service_id
//       final url = 'https://www.hairbnb.site/api/salon/$salonId/service/$serviceId/promotion/';
//
//       final response = await http.post(
//         Uri.parse(url),
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode(promotionData),
//       );
//
//       if (response.statusCode == 201) {
//         if (kDebugMode) {
//           print('✅ Promotion créée avec succès !');
//         }
//
//         showDialog(
//           context: innerContext,
//           barrierDismissible: false,
//           builder: (context) => Dialog(
//             backgroundColor: Colors.transparent,
//             elevation: 0,
//             child: Container(
//               width: 100,
//               height: 100,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.check_circle, color: successGreen, size: 60),
//                   const SizedBox(height: 10),
//                   const Text("Promotion ajoutée !", style: TextStyle(fontWeight: FontWeight.bold)),
//                 ],
//               ),
//             ),
//           ),
//         );
//
//         Future.delayed(const Duration(milliseconds: 1500), () {
//           Navigator.of(innerContext).pop();
//           Navigator.of(innerContext).pop(true);
//           onPromoAdded();
//         });
//
//       } else if (response.statusCode == 400) {
//         String errorText = "Impossible de créer la promotion.";
//         try {
//           final errorData = json.decode(utf8.decode(response.bodyBytes));
//           if (kDebugMode) {
//             print('❌ Erreur 400 détails: $errorData');
//           }
//
//           if (errorData is Map) {
//             if (errorData.containsKey('error')) {
//               errorText = errorData['error'];
//             } else if (errorData.containsKey('detail')) {
//               errorText = errorData['detail'];
//             } else if (errorData.containsKey('message')) {
//               errorText = errorData['message'];
//             } else {
//               errorText = errorData.toString();
//             }
//           }
//         } catch (e) {
//           if (kDebugMode) {
//             print('❌ Erreur lors du parsing de l\'erreur: $e');
//           }
//           errorText = response.body;
//         }
//
//         setModalState(() {
//           errorMessage = errorText;
//           isLoading = false;
//         });
//
//       } else if (response.statusCode == 404) {
//         if (kDebugMode) {
//           print('❌ Erreur 404: Ressource non trouvée');
//         }
//         setModalState(() {
//           errorMessage = "Service ou salon introuvable (404). Vérifiez les IDs.";
//           isLoading = false;
//         });
//
//       } else {
//         if (kDebugMode) {
//           print('❌ Erreur HTTP ${response.statusCode}: ${response.body}');
//         }
//         setModalState(() {
//           errorMessage = "Erreur serveur (${response.statusCode}): ${response.reasonPhrase}";
//           isLoading = false;
//         });
//       }
//
//     } catch (e, stackTrace) {
//       if (kDebugMode) {
//         print('❌ Exception lors de la création: $e');
//         print('📍 StackTrace: $stackTrace');
//       }
//
//       setModalState(() {
//         errorMessage = "Erreur de connexion: $e";
//         isLoading = false;
//       });
//     }
//   }
//
//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     backgroundColor: Colors.transparent,
//     builder: (context) => StatefulBuilder(
//       builder: (context, setModalState) => Builder(
//         builder: (innerContext) => AnimatedPadding(
//           duration: const Duration(milliseconds: 300),
//           padding: MediaQuery.of(innerContext).viewInsets + const EdgeInsets.all(10),
//           child: DraggableScrollableSheet(
//             initialChildSize: 0.75,
//             maxChildSize: 0.95,
//             minChildSize: 0.5,
//             expand: false,
//             builder: (context, scrollController) => Container(
//               padding: const EdgeInsets.all(20),
//               decoration: const BoxDecoration(
//                 color: Color(0xFFF7F7F9),
//                 borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//               ),
//               child: ListView(
//                 controller: scrollController,
//                 children: [
//                   Center(
//                     child: Container(
//                       width: 40,
//                       height: 5,
//                       margin: const EdgeInsets.only(bottom: 20),
//                       decoration: BoxDecoration(
//                         color: Colors.grey[300],
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                   ),
//
//                   const Text("Ajouter une promotion",
//                       style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
//
//                   const SizedBox(height: 20),
//
//                   TextField(
//                     controller: discountController,
//                     keyboardType: TextInputType.number,
//                     onChanged: (_) => validateFields(setModalState),
//                     inputFormatters: [
//                       FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
//                     ],
//                     decoration: InputDecoration(
//                       prefixIcon: Icon(Icons.percent, color: primaryViolet),
//                       labelText: "Pourcentage de réduction",
//                       errorText: errors['discount'],
//                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
//                     ),
//                   ),
//
//                   const SizedBox(height: 20),
//
//                   ListTile(
//                     title: Text(startDate == null
//                         ? "Choisir une date de début"
//                         : "Début : ${formatDateForApi(startDate!)}"), // 🔥 AMÉLIORATION : Affichage cohérent
//                     trailing: Icon(Icons.calendar_today, color: primaryViolet),
//                     onTap: () async {
//                       final picked = await showDatePicker(
//                         context: innerContext,
//                         initialDate: DateTime.now(),
//                         firstDate: DateTime.now(),
//                         lastDate: DateTime.now().add(const Duration(days: 365)),
//                       );
//                       if (picked != null) {
//                         setModalState(() => startDate = picked);
//                         validateFields(setModalState);
//                       }
//                     },
//                     subtitle: errors['startDate'] != null
//                         ? Text(errors['startDate']!, style: TextStyle(color: errorRed, fontSize: 12))
//                         : null,
//                   ),
//
//                   ListTile(
//                     title: Text(endDate == null
//                         ? "Choisir une date de fin"
//                         : "Fin : ${formatDateForApi(endDate!)}"), // 🔥 AMÉLIORATION : Affichage cohérent
//                     trailing: Icon(Icons.calendar_today, color: primaryViolet),
//                     onTap: () async {
//                       final picked = await showDatePicker(
//                         context: innerContext,
//                         initialDate: startDate ?? DateTime.now(),
//                         firstDate: startDate ?? DateTime.now(),
//                         lastDate: DateTime.now().add(const Duration(days: 730)),
//                       );
//                       if (picked != null) {
//                         setModalState(() => endDate = picked);
//                         validateFields(setModalState);
//                       }
//                     },
//                     subtitle: errors['endDate'] != null
//                         ? Text(errors['endDate']!, style: TextStyle(color: errorRed, fontSize: 12))
//                         : null,
//                   ),
//
//                   const SizedBox(height: 20),
//
//                   // Afficher le message d'erreur s'il y en a un
//                   if (errorMessage != null)
//                     Container(
//                       padding: const EdgeInsets.all(10),
//                       decoration: BoxDecoration(
//                         color: errorRed.withAlpha((255 * 0.1).round()),
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: errorRed),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(Icons.error_outline, color: errorRed),
//                           const SizedBox(width: 10),
//                           Expanded(
//                             child: Text(
//                               errorMessage!,
//                               style: TextStyle(color: errorRed),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//
//                   const SizedBox(height: 20),
//
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: isLoading ? null : () => submitPromotion(setModalState, innerContext),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: primaryViolet,
//                         padding: const EdgeInsets.symmetric(vertical: 16),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//                       ),
//                       child: isLoading
//                           ? const CircularProgressIndicator(color: Colors.white)
//                           : const Text("Créer la promotion", style: TextStyle(fontWeight: FontWeight.bold)),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     ),
//   );
// }
