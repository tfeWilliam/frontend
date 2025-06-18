////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//          FONCTIONNALITÉ DE MODIFICATION DE PROMOTION (VIA MODAL)             //
//                                                                            //
//  Ce fichier définit une seule fonction, `showEditPromotionModal`, qui      //
//  encapsule toute la logique et l'interface utilisateur nécessaires pour    //
//  modifier une promotion existante.                                         //
//                                                                            //
//  Approche :                                                                //
//  - Une unique fonction est exposée pour lancer le processus.               //
//  - L'interface est construite dans une "modal bottom sheet" qui est        //
//    redimensionnable (`DraggableScrollableSheet`).                          //
//  - L'état de la boîte de dialogue (valeurs des champs, erreurs, chargement)//
//    est géré localement à l'aide d'un `StatefulBuilder`.                    //
//  - La logique de validation, de formatage et d'appel API est contenue      //
//    dans des fonctions imbriquées, rendant le composant autonome.           //
//  - Gère l'authentification et le rafraîchissement des tokens via un        //
//    `TokenService`.                                                         //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../../../../models/promotion_full.dart';
import '../../../../../services/firebase_token/token_service.dart';

/// Affiche une feuille modale (bottom sheet) pour modifier une promotion existante.
///
/// Cette fonction gère l'état complet du formulaire, la validation, la communication
/// avec l'API pour la mise à jour, et les retours visuels à l'utilisateur.
///
/// [context] : Le `BuildContext` parent pour afficher la modal.
/// [salonId] : L'ID du salon auquel le service de la promotion appartient.
/// [serviceId] : L'ID du service auquel la promotion est appliquée.
/// [promotion] : L'objet `PromotionFull` contenant les données actuelles de la promotion.
/// [onPromoUpdated] : Une fonction de callback qui sera exécutée après une mise à jour réussie.
void showEditPromotionModal({
  required BuildContext context,
  required int salonId,
  required int serviceId,
  required PromotionFull promotion,
  required VoidCallback onPromoUpdated,
}) {
  //region Validation des paramètres d'entrée
  // Garde-fous pour s'assurer que les IDs nécessaires sont valides avant de continuer.
  if (salonId <= 0) {
    if (kDebugMode) print('ERREUR: salonId invalide ($salonId)');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ID du salon invalide ($salonId)'), backgroundColor: Colors.red));
    return;
  }
  if (serviceId <= 0) {
    if (kDebugMode) print('ERREUR: serviceId invalide ($serviceId)');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ID du service invalide ($serviceId)'), backgroundColor: Colors.red));
    return;
  }
  //endregion

  //region Initialisation de l'état local de la modal
  // Contrôleurs et variables qui maintiendront l'état du formulaire dans la modal.
  final TextEditingController discountController = TextEditingController(text: promotion.pourcentage.toStringAsFixed(0));
  DateTime? startDate = promotion.dateDebut;
  DateTime? endDate = promotion.dateFin;
  bool isLoading = false;
  String? errorMessage;

  final Color primaryViolet = const Color(0xFF7B61FF);
  final Color errorRed = Colors.red;
  final Color successGreen = Colors.green;

  // Maps pour suivre les erreurs et la validité de chaque champ.
  Map<String, String?> errors = {'discount': null, 'startDate': null, 'endDate': null};
  Map<String, bool> isValid = {'discount': true, 'startDate': true, 'endDate': true};
  //endregion

  //region Fonctions de logique métier imbriquées
  /// Valide tous les champs du formulaire et met à jour l'état des erreurs.
  void validateFields(StateSetter setModalState) {
    final discountText = discountController.text.trim();
    final double? discount = double.tryParse(discountText);

    setModalState(() {
      errorMessage = null;
      // Valide le pourcentage.
      if (discount == null || discount <= 0 || discount > 100) {
        errors['discount'] = "Pourcentage invalide (1-100%)";
        isValid['discount'] = false;
      } else {
        errors['discount'] = null;
        isValid['discount'] = true;
      }
      // Valide la date de début.
      if (startDate == null) {
        errors['startDate'] = "Date de début requise";
        isValid['startDate'] = false;
      } else {
        errors['startDate'] = null;
        isValid['startDate'] = true;
      }
      // Valide la date de fin.
      if (endDate == null) {
        errors['endDate'] = "Date de fin requise";
        isValid['endDate'] = false;
      } else if (startDate != null && endDate!.isBefore(startDate!)) {
        errors['endDate'] = "Fin doit être après le début";
        isValid['endDate'] = false;
      } else {
        errors['endDate'] = null;
        isValid['endDate'] = true;
      }
    });
  }

  /// Formate une `DateTime` en une chaîne "yyyy-MM-dd" pour l'API.
  String formatDateForApi(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  /// Orchestre la mise à jour de la promotion via un appel API.
  Future<void> updatePromotion(StateSetter setModalState, BuildContext innerContext) async {
    validateFields(setModalState);
    if (errors.values.any((e) => e != null)) return; // Arrête si des erreurs sont présentes.

    final promotionData = {
      'discount_percentage': double.parse(discountController.text.trim()),
      'start_date': formatDateForApi(startDate!),
      'end_date': formatDateForApi(endDate!),
    };

    setModalState(() { isLoading = true; errorMessage = null; });

    try {
      final token = await TokenService.getAuthToken();
      if (token == null) {
        setModalState(() { errorMessage = "Erreur d'authentification. Veuillez vous reconnecter."; isLoading = false; });
        return;
      }

      final url = 'https://www.hairbnb.site/api/salon/$salonId/service/$serviceId/promotion/${promotion.id}/';

      // Effectue la requête HTTP PUT avec le token d'authentification.
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: json.encode(promotionData),
      );

      // Gère les différents codes de réponse de l'API.
      if (response.statusCode == 200) {
        // Succès : Affiche une confirmation et ferme la modal.
        showDialog(
          context: innerContext, barrierDismissible: false,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent, elevation: 0,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.check_circle, color: successGreen, size: 60), const SizedBox(height: 10), const Text("Promotion modifiée !", style: TextStyle(fontWeight: FontWeight.bold))]),
            ),
          ),
        );
        Future.delayed(const Duration(milliseconds: 1500), () {
          Navigator.of(innerContext).pop(); // Ferme le dialogue de succès.
          Navigator.of(innerContext).pop(true); // Ferme la modal de modification.
          onPromoUpdated(); // Appelle le callback pour rafraîchir la page parente.
        });
      } else if (response.statusCode == 401) {
        // Erreur d'authentification : tente de rafraîchir le token.
        final newToken = await TokenService.getAuthToken(forceRefresh: true);
        setModalState(() {
          errorMessage = newToken != null ? "Session expirée. Veuillez réessayer." : "Authentification échouée. Veuillez vous reconnecter.";
          isLoading = false;
        });
      } else if (response.statusCode == 400 || response.statusCode == 404) {
        // Erreur de validation ou ressource non trouvée : parse et affiche le message d'erreur du backend.
        String errorText = "Impossible de modifier la promotion.";
        try {
          final errorData = json.decode(utf8.decode(response.bodyBytes));
          if (errorData is Map) errorText = errorData['error'] ?? errorData['detail'] ?? errorData['message'] ?? errorData.toString();
        } catch (e) { errorText = response.body; }
        setModalState(() { errorMessage = errorText; isLoading = false; });
      } else {
        // Autres erreurs serveur.
        setModalState(() { errorMessage = "Erreur serveur (${response.statusCode}): ${response.reasonPhrase}"; isLoading = false; });
      }
    } catch (e, stackTrace) {
      // Erreurs de connexion, etc.
      if (kDebugMode) print('Exception lors de la modification: $e\n$stackTrace');
      setModalState(() { errorMessage = "Erreur de connexion: $e"; isLoading = false; });
    }
  }
  //endregion

  // Affiche la feuille modale.
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Permet à la modal de prendre plus de place.
    backgroundColor: Colors.transparent,
    builder: (context) => StatefulBuilder(
      // `StatefulBuilder` est utilisé pour que la modal puisse gérer son propre état.
      builder: (context, setModalState) => Builder(
        builder: (innerContext) => AnimatedPadding(
          duration: const Duration(milliseconds: 300),
          // S'adapte à la hauteur du clavier.
          padding: MediaQuery.of(innerContext).viewInsets + const EdgeInsets.all(10),
          // Feuille scrollable et redimensionnable par l'utilisateur.
          child: DraggableScrollableSheet(
            initialChildSize: 0.75, maxChildSize: 0.95, minChildSize: 0.5,
            expand: false,
            builder: (context, scrollController) => Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Color(0xFFF7F7F9), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              // Le contenu du formulaire.
              child: ListView(
                controller: scrollController,
                children: [
                  // Poignée de redimensionnement.
                  Center(child: Container(width: 40, height: 5, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)))),
                  const Text("Modifier la promotion", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                  // Affiche un résumé de la promotion en cours de modification.
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 15),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: primaryViolet.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: primaryViolet.withOpacity(0.3))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('📋 Promotion actuelle:', style: TextStyle(fontWeight: FontWeight.bold, color: primaryViolet)),
                        const SizedBox(height: 8),
                        Text('• Réduction: ${promotion.pourcentage.toStringAsFixed(0)}%', style: TextStyle(color: primaryViolet.withOpacity(0.8))),
                        Text('• Période: ${formatDateForApi(promotion.dateDebut)} → ${formatDateForApi(promotion.dateFin)}', style: TextStyle(color: primaryViolet.withOpacity(0.8))),
                        Text('• Statut: ${promotion.getCurrentStatus() == 'active' ? 'Active' : promotion.getCurrentStatus() == 'future' ? 'À venir' : 'Expirée'}', style: TextStyle(color: primaryViolet.withOpacity(0.8))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Champ pour le pourcentage.
                  TextField(
                    controller: discountController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => validateFields(setModalState),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))],
                    decoration: InputDecoration(prefixIcon: Icon(Icons.percent, color: primaryViolet), labelText: "Pourcentage de réduction", errorText: errors['discount'], border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
                  ),
                  const SizedBox(height: 20),
                  // Sélecteur pour la date de début.
                  ListTile(
                    title: Text(startDate == null ? "Choisir une date de début" : "Début : ${formatDateForApi(startDate!)}"),
                    trailing: Icon(Icons.calendar_today, color: primaryViolet),
                    onTap: () async {
                      final picked = await showDatePicker(context: innerContext, initialDate: startDate ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                      if (picked != null) { setModalState(() => startDate = picked); validateFields(setModalState); }
                    },
                    subtitle: errors['startDate'] != null ? Text(errors['startDate']!, style: TextStyle(color: errorRed, fontSize: 12)) : null,
                  ),
                  // Sélecteur pour la date de fin.
                  ListTile(
                    title: Text(endDate == null ? "Choisir une date de fin" : "Fin : ${formatDateForApi(endDate!)}"),
                    trailing: Icon(Icons.calendar_today, color: primaryViolet),
                    onTap: () async {
                      final picked = await showDatePicker(context: innerContext, initialDate: endDate ?? startDate ?? DateTime.now(), firstDate: startDate ?? DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 730)));
                      if (picked != null) { setModalState(() => endDate = picked); validateFields(setModalState); }
                    },
                    subtitle: errors['endDate'] != null ? Text(errors['endDate']!, style: TextStyle(color: errorRed, fontSize: 12)) : null,
                  ),
                  const SizedBox(height: 20),
                  // Affiche le message d'erreur global s'il y en a un.
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
                      onPressed: isLoading ? null : () => updatePromotion(setModalState, innerContext),
                      style: ElevatedButton.styleFrom(backgroundColor: primaryViolet, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Modifier la promotion", style: TextStyle(fontWeight: FontWeight.bold)),
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
// import '../../../../../models/promotion_full.dart';
// import '../../../../../services/firebase_token/token_service.dart';
//
// void showEditPromotionModal({
//   required BuildContext context,
//   required int salonId,
//   required int serviceId,
//   required PromotionFull promotion,
//   required VoidCallback onPromoUpdated,
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
//   // 🔥 NOUVEAU : Pré-remplir avec les données existantes
//   final TextEditingController discountController = TextEditingController(
//       text: promotion.pourcentage.toStringAsFixed(0)
//   );
//   DateTime? startDate = promotion.dateDebut;
//   DateTime? endDate = promotion.dateFin;
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
//     'discount': true, // 🔥 NOUVEAU : Déjà valide au départ
//     'startDate': true, // 🔥 NOUVEAU : Déjà valide au départ
//     'endDate': true, // 🔥 NOUVEAU : Déjà valide au départ
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
//   // Formatage des dates sans problème de fuseau horaire
//   String formatDateForApi(DateTime date) {
//     final year = date.year.toString();
//     final month = date.month.toString().padLeft(2, '0');
//     final day = date.day.toString().padLeft(2, '0');
//     return '$year-$month-$day';
//   }
//
//   // 🔥 NOUVEAU : Fonction pour modifier la promotion
//   Future<void> updatePromotion(StateSetter setModalState, BuildContext innerContext) async {
//     validateFields(setModalState);
//     if (errors.values.any((e) => e != null)) return;
//
//     final promotionData = {
//       'discount_percentage': double.parse(discountController.text.trim()),
//       'start_date': formatDateForApi(startDate!),
//       'end_date': formatDateForApi(endDate!),
//     };
//
//     setModalState(() {
//       isLoading = true;
//       errorMessage = null;
//     });
//
//     try {
//       // 🔥 NOUVEAU : Récupérer le token d'authentification
//       final token = await TokenService.getAuthToken();
//
//       if (token == null) {
//         setModalState(() {
//           errorMessage = "Erreur d'authentification. Veuillez vous reconnecter.";
//           isLoading = false;
//         });
//         return;
//       }
//
//       if (kDebugMode) {
//         print('📝 Modification promotion:');
//         print('   - ID Promotion: ${promotion.id}');
//         print('   - Salon ID: $salonId');
//         print('   - Service ID: $serviceId');
//         print('   - Nouvelles données: $promotionData');
//         print('   - Token présent: ${token.isNotEmpty}');
//       }
//
//       final url = 'https://www.hairbnb.site/api/salon/$salonId/service/$serviceId/promotion/${promotion.id}/';
//
//       // 🔥 CORRIGÉ : Ajout du token d'authentification dans les headers
//       final response = await http.put(
//         Uri.parse(url),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token', // ✅ Token ajouté !
//         },
//         body: json.encode(promotionData),
//       );
//
//       if (response.statusCode == 200) {
//         if (kDebugMode) {
//           print('✅ Promotion modifiée avec succès !');
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
//                   const Text("Promotion modifiée !", style: TextStyle(fontWeight: FontWeight.bold)),
//                 ],
//               ),
//             ),
//           ),
//         );
//
//         Future.delayed(const Duration(milliseconds: 1500), () {
//           Navigator.of(innerContext).pop();
//           Navigator.of(innerContext).pop(true);
//           onPromoUpdated();
//         });
//
//       } else if (response.statusCode == 401) {
//         // 🔥 NOUVEAU : Gestion spécifique de l'erreur d'authentification
//         if (kDebugMode) {
//           print('❌ Erreur 401: Token invalide ou expiré');
//         }
//
//         // Essayer de rafraîchir le token
//         final newToken = await TokenService.getAuthToken(forceRefresh: true);
//
//         if (newToken != null) {
//           setModalState(() {
//             errorMessage = "Session expirée. Veuillez réessayer.";
//             isLoading = false;
//           });
//         } else {
//           setModalState(() {
//             errorMessage = "Authentification échouée. Veuillez vous reconnecter.";
//             isLoading = false;
//           });
//         }
//
//       } else if (response.statusCode == 400) {
//         String errorText = "Impossible de modifier la promotion.";
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
//           errorMessage = "Promotion, service ou salon introuvable (404).";
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
//         print('❌ Exception lors de la modification: $e');
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
//                   const Text("Modifier la promotion", // 🔥 NOUVEAU : Titre modifié
//                       style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
//
//                   // 🔥 NOUVEAU : Afficher les infos de la promotion actuelle
//                   Container(
//                     margin: const EdgeInsets.symmetric(vertical: 15),
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: primaryViolet.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(color: primaryViolet.withOpacity(0.3)),
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text('📋 Promotion actuelle:', style: TextStyle(fontWeight: FontWeight.bold, color: primaryViolet)),
//                         const SizedBox(height: 8),
//                         Text('• Réduction: ${promotion.pourcentage.toStringAsFixed(0)}%', style: TextStyle(color: primaryViolet.withOpacity(0.8))),
//                         Text('• Période: ${formatDateForApi(promotion.dateDebut)} → ${formatDateForApi(promotion.dateFin)}', style: TextStyle(color: primaryViolet.withOpacity(0.8))),
//                         Text('• Statut: ${promotion.getCurrentStatus() == 'active' ? 'Active' : promotion.getCurrentStatus() == 'future' ? 'À venir' : 'Expirée'}', style: TextStyle(color: primaryViolet.withOpacity(0.8))),
//                       ],
//                     ),
//                   ),
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
//                         : "Début : ${formatDateForApi(startDate!)}"),
//                     trailing: Icon(Icons.calendar_today, color: primaryViolet),
//                     onTap: () async {
//                       final picked = await showDatePicker(
//                         context: innerContext,
//                         initialDate: startDate ?? DateTime.now(),
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
//                         : "Fin : ${formatDateForApi(endDate!)}"),
//                     trailing: Icon(Icons.calendar_today, color: primaryViolet),
//                     onTap: () async {
//                       final picked = await showDatePicker(
//                         context: innerContext,
//                         initialDate: endDate ?? startDate ?? DateTime.now(),
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
//                       onPressed: isLoading ? null : () => updatePromotion(setModalState, innerContext),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: primaryViolet,
//                         padding: const EdgeInsets.symmetric(vertical: 16),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//                       ),
//                       child: isLoading
//                           ? const CircularProgressIndicator(color: Colors.white)
//                           : const Text("Modifier la promotion", style: TextStyle(fontWeight: FontWeight.bold)),
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