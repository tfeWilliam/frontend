////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//          MODAL DE CRÉATION D'UN NOUVEAU SERVICE GLOBAL                       //
//                                                                            //
//  Ce fichier définit `CreateServicesModal`, un widget `StatefulWidget` qui  //
//  est affiché comme un dialogue en plein écran. Il fournit une interface    //
//  complète pour créer un nouveau service qui sera ajouté au catalogue       //
//  global de l'application, disponible pour tous les salons.                 //
//                                                                            //
//  Fonctionnalités Clés :                                                    //
//  - Recherche en temps réel de services similaires pendant la saisie pour  //
//    éviter la création de doublons.                                         //
//  - Gestion des conflits : si un service similaire est trouvé par le        //
//    backend, une boîte de dialogue propose à l'utilisateur de l'utiliser.   //
//  - Validation de formulaire côté client et gestion des erreurs côté        //
//    serveur.                                                                //
//  - Dialogues de succès personnalisés avec plusieurs options de navigation. //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;

import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hairbnb/models/current_user.dart';
import 'package:http/http.dart' as http;
import '../../../../../../models/service_creation.dart';
import '../models/existing_service_model.dart';
import '../select_services_page.dart';

/// Un `StatefulWidget` qui représente la modal de création de service.
class CreateServicesModal extends StatefulWidget {
  /// L'utilisateur actuellement connecté qui crée le service.
  final CurrentUser currentUser;
  /// L'ID de la catégorie sous laquelle le service sera créé.
  final int? selectedCategoryId;

  /// Constructeur de la modal.
  const CreateServicesModal({
    super.key,
    required this.currentUser,
    this.selectedCategoryId,
  });

  @override
  State<CreateServicesModal> createState() => _CreateServicesModalState();
}

/// La classe d'état pour `CreateServicesModal`.
/// Gère les contrôleurs, les états de chargement/recherche, et toute la logique métier.
class _CreateServicesModalState extends State<CreateServicesModal> {
  //region Déclaration des variables d'état et contrôleurs
  /// Clé globale pour identifier et valider le formulaire.
  final _formKey = GlobalKey<FormState>();
  /// Contrôleurs pour les champs de texte du formulaire.
  final _nomController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _prixController = TextEditingController();
  final _dureeController = TextEditingController();

  /// `true` si une soumission à l'API est en cours.
  bool isSubmitting = false;
  /// `true` si une recherche de services similaires est en cours.
  bool isSearching = false;
  /// La liste des services similaires trouvés par l'API.
  List<ExistingService> similarServices = [];
  /// `true` pour afficher le bloc de suggestions de services.
  bool showSuggestions = false;
  //endregion

  @override
  void dispose() {
    // Nettoie tous les contrôleurs pour éviter les fuites de mémoire.
    _nomController.dispose();
    _descriptionController.dispose();
    _prixController.dispose();
    _dureeController.dispose();
    super.dispose();
  }

  //region Logique de recherche et de création
  /// Déclenché à chaque modification du champ "Nom du service" pour rechercher des services similaires.
  void _onServiceNameChanged(String value) {
    if (value.length >= 2) {
      _searchSimilarServices(value);
    } else {
      if(mounted) {
        setState(() {
          similarServices.clear();
          showSuggestions = false;
        });
      }
    }
  }

  /// Interroge l'API pour trouver des services dont le nom est similaire au terme de recherche.
  Future<void> _searchSimilarServices(String searchTerm) async {
    if (isSearching) return;
    if(mounted) setState(() => isSearching = true);

    try {
      final response = await http.get(
        Uri.parse('https://www.hairbnb.site/api/services/search/?q=${Uri.encodeComponent(searchTerm)}&limit=5'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final servicesJson = data['services'] as List;
          if(mounted) {
            setState(() {
              similarServices = servicesJson.map((json) => ExistingService.fromJson(json)).toList();
              showSuggestions = similarServices.isNotEmpty;
            });
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('Erreur recherche: $e');
    } finally {
      if(mounted) setState(() => isSearching = false);
    }
  }

  /// Gère la soumission du formulaire pour créer un nouveau service.
  Future<void> _createNewService() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.selectedCategoryId == null) {
      _showError("Aucune catégorie sélectionnée");
      return;
    }
    if(mounted) setState(() => isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final firebaseToken = user != null ? await user.getIdToken() : null;
      Map<String, String> headers = {'Content-Type': 'application/json'};
      if (firebaseToken != null) headers['Authorization'] = 'Bearer $firebaseToken';

      // Crée un modèle de données pour la création et le valide.
      final newService = ServiceCreation(
        userId: int.parse(widget.currentUser.idTblUser.toString()),
        intituleService: _nomController.text.trim(),
        description: _descriptionController.text.trim(),
        prix: double.parse(_prixController.text),
        tempsMinutes: int.parse(_dureeController.text),
        categorieId: widget.selectedCategoryId!,
      );
      final validationError = newService.validate();
      if (validationError != null) {
        _showError(validationError);
        if(mounted) setState(() => isSubmitting = false);
        return;
      }

      // Envoie la requête de création à l'API.
      final response = await http.post(
        Uri.parse('https://www.hairbnb.site/api/services/create-new/'),
        headers: headers,
        body: json.encode(newService.toJson()),
      );
      final responseData = json.decode(response.body);

      // Gère les différents codes de réponse.
      if (response.statusCode == 201) {
        _afficherDialogueSucces();
      } else if (response.statusCode == 409) { // 409 Conflict
        _showConflictDialog(responseData);
      } else {
        _showError(responseData['message'] ?? 'Erreur lors de la création du service');
      }
    } catch (e) {
      _showError('Erreur lors de la création du service: $e');
    } finally {
      if(mounted) setState(() => isSubmitting = false);
    }
  }
  //endregion

  //region Dialogues et Navigation
  /// Affiche un dialogue de succès après la création, proposant plusieurs actions.
  void _afficherDialogueSucces() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.green.shade100, shape: BoxShape.circle), child: Icon(Icons.check_circle, color: Colors.green.shade600, size: 24)), const SizedBox(width: 12), const Expanded(child: Text("Service créé !", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)))]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Le service '${_nomController.text}' a été créé et ajouté à votre salon avec succès.", style: const TextStyle(fontSize: 16)), const SizedBox(height: 16), const Text("Que souhaitez-vous faire maintenant ?", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey))]),
        actions: [
          TextButton.icon(onPressed: () { Navigator.of(context).pop(); _retournerVersServices(); }, icon: const Icon(Icons.arrow_back), label: const Text("Retour aux services")),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              // Réinitialise le formulaire pour permettre la création d'un autre service.
              setState(() {
                _nomController.clear(); _descriptionController.clear(); _prixController.clear(); _dureeController.clear();
                similarServices.clear(); showSuggestions = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vous pouvez maintenant créer un autre service"), backgroundColor: Colors.blue, duration: Duration(seconds: 2)));
            },
            icon: const Icon(Icons.add_circle_outline),
            label: const Text("Créer un autre"),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B61FF), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ],
      ),
    );
  }

  /// Affiche un dialogue lorsqu'un service similaire est détecté par le backend.
  void _showConflictDialog(Map<String, dynamic> responseData) {
    final existingService = ExistingService.fromJson(responseData['existing_service']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Service similaire trouvé'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(responseData['message'] ?? 'Un service similaire existe déjà'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.shade200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(existingService.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(existingService.description, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  // ... Autres détails du service existant ...
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Créer quand même')),
          ElevatedButton(onPressed: () { Navigator.of(context).pop(); _useExistingService(existingService); }, child: const Text('Utiliser ce service')),
        ],
      ),
    );
  }

  /// Navigue vers la page de sélection de services (action après conflit).
  void _useExistingService(ExistingService service) {
    Navigator.of(context).pop();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SelectServicesPage(currentUser: widget.currentUser)));
  }

  /// Navigue en arrière vers la page de sélection de services.
  void _retournerVersServices() {
    Navigator.of(context).pop();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SelectServicesPage(currentUser: widget.currentUser)));
  }

  /// Affiche un message d'erreur dans un SnackBar.
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
  }
  //endregion

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F9),
        appBar: AppBar(
          title: const Text("Créer un nouveau service"),
          centerTitle: true,
          backgroundColor: const Color(0xFF7B61FF),
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.close), onPressed: _retournerVersServices),
          actions: [TextButton(onPressed: _retournerVersServices, child: const Text("Annuler", style: TextStyle(color: Colors.white)))],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête de la page.
                    const Text("Créer un nouveau service", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF333333))),
                    const SizedBox(height: 8),
                    Text("Ce service sera disponible pour tous les salons sur Hairbnb${widget.selectedCategoryId != null ? ' dans la catégorie sélectionnée' : ''}", style: const TextStyle(fontSize: 16, color: Color(0xFF666666))),
                    const SizedBox(height: 30),

                    // Champ pour le nom du service avec suggestions.
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Nom du service *", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nomController,
                          decoration: InputDecoration(
                            hintText: "Ex: Coupe femme, Balayage, Brushing...",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 2)),
                            suffixIcon: isSearching ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
                          ),
                          validator: (value) { /* ... validation ... */ return null; },
                          onChanged: _onServiceNameChanged,
                        ),
                        // Affiche les suggestions de services similaires si elles existent.
                        if (showSuggestions && similarServices.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade200)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [Icon(Icons.warning_amber, color: Colors.orange.shade600, size: 20), const SizedBox(width: 8), const Text("Services similaires trouvés", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange))]),
                                const SizedBox(height: 12),
                                ...similarServices.take(3).map((service) => _buildSuggestionCard(service)),
                                const SizedBox(height: 8),
                                TextButton(onPressed: () => setState(() => showSuggestions = false), child: const Text("Créer un nouveau service quand même")),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Champ pour la description.
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [ /* ... */ ],
                    ),
                    const SizedBox(height: 24),
                    // Champs pour le prix et la durée.
                    Row(
                      children: [ /* ... */ ],
                    ),
                    const SizedBox(height: 30),
                    // Boîte d'information.
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade200)),
                      child: const Row(children: [Icon(Icons.info_outline, color: Color.fromARGB(255, 27, 109, 175)), SizedBox(width: 12), Expanded(child: Text("Ce service sera créé globalement et pourra être utilisé par d'autres salons avec leurs propres prix et durées.", style: TextStyle(fontSize: 14, color: Colors.blue)))]),
                    ),
                    const SizedBox(height: 30),
                    // Boutons d'action.
                    Row(
                      children: [
                        Expanded(child: OutlinedButton(onPressed: isSubmitting ? null : _retournerVersServices, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: const BorderSide(color: Color(0xFF7B61FF))), child: const Text("Annuler", style: TextStyle(color: Color(0xFF7B61FF))))),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: isSubmitting ? null : _createNewService,
                            icon: isSubmitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))) : const Icon(Icons.add),
                            label: Text(isSubmitting ? "Création en cours..." : "Créer le service"),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B61FF), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Construit la carte pour une suggestion de service existant.
  Widget _buildSuggestionCard(ExistingService service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.nom, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(service.description, style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
                Text("Utilisé par ${service.nbSalonsUtilisant} salon(s)", style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _useExistingService(service),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
            child: const Text("Utiliser", style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}






// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:hairbnb/models/current_user.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:hairbnb/models/service_creation.dart';
//
// import '../models/existing_service_model.dart';
// import '../select_services_page.dart';
//
// class CreateServicesModal extends StatefulWidget {
//   final CurrentUser currentUser;
//   final int? selectedCategoryId;
//
//   const CreateServicesModal({
//     super.key,
//     required this.currentUser,
//     this.selectedCategoryId,
//   });
//
//   @override
//   State<CreateServicesModal> createState() => _CreateServicesModalState();
// }
//
// class _CreateServicesModalState extends State<CreateServicesModal> {
//   final _formKey = GlobalKey<FormState>();
//   final _nomController = TextEditingController();
//   final _descriptionController = TextEditingController();
//   final _prixController = TextEditingController();
//   final _dureeController = TextEditingController();
//
//   bool isSubmitting = false;
//   bool isSearching = false;
//   List<ExistingService> similarServices = [];
//   bool showSuggestions = false;
//
//   @override
//   void dispose() {
//     _nomController.dispose();
//     _descriptionController.dispose();
//     _prixController.dispose();
//     _dureeController.dispose();
//     super.dispose();
//   }
//
//   // Recherche de services similaires pendant que l'utilisateur tape
//   void _onServiceNameChanged(String value) {
//     if (value.length >= 2) {
//       _searchSimilarServices(value);
//     } else {
//       setState(() {
//         similarServices.clear();
//         showSuggestions = false;
//       });
//     }
//   }
//
//   Future<void> _searchSimilarServices(String searchTerm) async {
//     if (isSearching) return;
//
//     setState(() => isSearching = true);
//
//     try {
//       final response = await http.get(
//         Uri.parse('https://www.hairbnb.site/api/services/search/?q=${Uri.encodeComponent(searchTerm)}&limit=5'),
//         headers: {'Content-Type': 'application/json'},
//       );
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data['status'] == 'success') {
//           final servicesJson = data['services'] as List;
//
//           setState(() {
//             similarServices = servicesJson
//                 .map((json) => ExistingService.fromJson(json))
//                 .toList();
//             showSuggestions = similarServices.isNotEmpty;
//           });
//         }
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('Erreur recherche: $e');
//       }
//     } finally {
//       setState(() => isSearching = false);
//     }
//   }
//
//   Future<void> _createNewService() async {
//     if (!_formKey.currentState!.validate()) return;
//
//     // Vérifier qu'une catégorie est sélectionnée
//     if (widget.selectedCategoryId == null) {
//       _showError("Aucune catégorie sélectionnée");
//       return;
//     }
//
//     setState(() => isSubmitting = true);
//
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       final firebaseToken = user != null ? await user.getIdToken() : null;
//
//       Map<String, String> headers = {'Content-Type': 'application/json'};
//       if (firebaseToken != null) {
//         headers['Authorization'] = 'Bearer $firebaseToken';
//       }
//
//       final newService = ServiceCreation(
//         userId: int.parse(widget.currentUser.idTblUser.toString()),
//         intituleService: _nomController.text.trim(),
//         description: _descriptionController.text.trim(),
//         prix: double.parse(_prixController.text),
//         tempsMinutes: int.parse(_dureeController.text),
//         categorieId: widget.selectedCategoryId!, // Utilise la catégorie passée en paramètre
//       );
//
//       final validationError = newService.validate();
//       if (validationError != null) {
//         _showError(validationError);
//         setState(() => isSubmitting = false);
//         return;
//       }
//
//       final response = await http.post(
//         Uri.parse('https://www.hairbnb.site/api/services/create-new/'),
//         headers: headers,
//         body: json.encode(newService.toJson()),
//       );
//
//       final responseData = json.decode(response.body);
//
//       if (response.statusCode == 201) {
//         _afficherDialogueSucces();
//       } else if (response.statusCode == 409) {
//         _showConflictDialog(responseData);
//       } else {
//         _showError(responseData['message'] ?? 'Erreur lors de la création du service');
//       }
//
//     } catch (e) {
//       _showError('Erreur lors de la création du service: $e');
//     } finally {
//       setState(() => isSubmitting = false);
//     }
//   }
//
//   void _afficherDialogueSucces() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//           title: Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: Colors.green.shade100,
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(
//                   Icons.check_circle,
//                   color: Colors.green.shade600,
//                   size: 24,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               const Expanded(
//                 child: Text(
//                   "Service créé !",
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 "Le service '${_nomController.text}' a été créé et ajouté à votre salon avec succès.",
//                 style: const TextStyle(fontSize: 16),
//               ),
//               const SizedBox(height: 16),
//               const Text(
//                 "Que souhaitez-vous faire maintenant ?",
//                 style: TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w500,
//                   color: Colors.grey,
//                 ),
//               ),
//             ],
//           ),
//           actions: [
//             TextButton.icon(
//               onPressed: () {
//                 Navigator.of(context).pop(); // Fermer le dialogue de succès
//                 Navigator.of(context).pop(); // Fermer le modal
//
//                 // Rediriger vers SelectServicesPage
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => SelectServicesPage(
//                       currentUser: widget.currentUser,
//                     ),
//                   ),
//                 );
//               },
//               icon: const Icon(Icons.arrow_back),
//               label: const Text("Retour aux services"),
//             ),
//             ElevatedButton.icon(
//               onPressed: () {
//                 Navigator.of(context).pop(); // Fermer le dialogue
//
//                 // Réinitialiser les champs pour créer un autre service
//                 setState(() {
//                   _nomController.clear();
//                   _descriptionController.clear();
//                   _prixController.clear();
//                   _dureeController.clear();
//                   similarServices.clear();
//                   showSuggestions = false;
//                 });
//
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(
//                     content: Text("Vous pouvez maintenant créer un autre service"),
//                     backgroundColor: Colors.blue,
//                     duration: Duration(seconds: 2),
//                   ),
//                 );
//               },
//               icon: const Icon(Icons.add_circle_outline),
//               label: const Text("Créer un autre"),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF7B61FF),
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   void _showConflictDialog(Map<String, dynamic> responseData) {
//     final existingService = ExistingService.fromJson(responseData['existing_service']);
//
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Service similaire trouvé'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(responseData['message'] ?? 'Un service similaire existe déjà'),
//             const SizedBox(height: 16),
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.blue.shade50,
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: Colors.blue.shade200),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     existingService.nom,
//                     style: const TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     existingService.description,
//                     style: const TextStyle(fontSize: 14, color: Colors.grey),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     'Utilisé par ${existingService.nbSalonsUtilisant} salon(s)',
//                     style: const TextStyle(fontSize: 12, color: Colors.grey),
//                   ),
//                   if (existingService.prixPopulaires.isNotEmpty)
//                     Text(
//                       'Prix fréquents: ${existingService.prixPopulaires.join(', ')}€',
//                       style: const TextStyle(fontSize: 12, color: Colors.grey),
//                     ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('Créer quand même'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.of(context).pop();
//               _useExistingService(existingService);
//             },
//             child: const Text('Utiliser ce service'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _useExistingService(ExistingService service) {
//     Navigator.of(context).pop(); // Fermer le modal
//
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(
//         builder: (context) => SelectServicesPage(
//           currentUser: widget.currentUser,
//         ),
//       ),
//     );
//   }
//
//   void _retournerVersServices() {
//     Navigator.of(context).pop(); // Fermer le modal
//
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(
//         builder: (context) => SelectServicesPage(
//           currentUser: widget.currentUser,
//         ),
//       ),
//     );
//   }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Dialog.fullscreen(
//       child: Scaffold(
//         backgroundColor: const Color(0xFFF7F7F9),
//         appBar: AppBar(
//           title: const Text("Créer un nouveau service"),
//           centerTitle: true,
//           backgroundColor: const Color(0xFF7B61FF),
//           foregroundColor: Colors.white,
//           elevation: 0,
//           leading: IconButton(
//             icon: const Icon(Icons.close),
//             onPressed: _retournerVersServices,
//           ),
//           actions: [
//             TextButton(
//               onPressed: _retournerVersServices,
//               child: const Text(
//                 "Annuler",
//                 style: TextStyle(color: Colors.white),
//               ),
//             ),
//           ],
//         ),
//         body: SingleChildScrollView(
//           padding: const EdgeInsets.all(24.0),
//           child: Center(
//             child: ConstrainedBox(
//               constraints: const BoxConstraints(maxWidth: 600),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       "Créer un nouveau service",
//                       style: TextStyle(
//                         fontSize: 26,
//                         fontWeight: FontWeight.w700,
//                         color: Color(0xFF333333),
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       "Ce service sera disponible pour tous les salons sur Hairbnb${widget.selectedCategoryId != null ? ' dans la catégorie sélectionnée' : ''}",
//                       style: const TextStyle(
//                         fontSize: 16,
//                         color: Color(0xFF666666),
//                       ),
//                     ),
//                     const SizedBox(height: 30),
//
//                     // Champ nom du service
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text(
//                           "Nom du service *",
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                             color: Color(0xFF333333),
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         TextFormField(
//                           controller: _nomController,
//                           decoration: InputDecoration(
//                             hintText: "Ex: Coupe femme, Balayage, Brushing...",
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: BorderSide(color: Colors.grey.shade300),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 2),
//                             ),
//                             suffixIcon: isSearching
//                                 ? const SizedBox(
//                               width: 20,
//                               height: 20,
//                               child: CircularProgressIndicator(strokeWidth: 2),
//                             )
//                                 : null,
//                           ),
//                           validator: (value) {
//                             if (value == null || value.trim().isEmpty) {
//                               return 'Le nom du service est obligatoire';
//                             }
//                             if (value.trim().length < 2) {
//                               return 'Le nom doit contenir au moins 2 caractères';
//                             }
//                             return null;
//                           },
//                           onChanged: _onServiceNameChanged,
//                         ),
//
//                         // Suggestions de services similaires
//                         if (showSuggestions && similarServices.isNotEmpty) ...[
//                           const SizedBox(height: 12),
//                           Container(
//                             padding: const EdgeInsets.all(16),
//                             decoration: BoxDecoration(
//                               color: Colors.orange.shade50,
//                               borderRadius: BorderRadius.circular(12),
//                               border: Border.all(color: Colors.orange.shade200),
//                             ),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Row(
//                                   children: [
//                                     Icon(Icons.warning_amber,
//                                         color: Colors.orange.shade600,
//                                         size: 20),
//                                     const SizedBox(width: 8),
//                                     const Text(
//                                       "Services similaires trouvés",
//                                       style: TextStyle(
//                                         fontWeight: FontWeight.bold,
//                                         color: Colors.orange,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 const SizedBox(height: 12),
//                                 ...similarServices.take(3).map((service) =>
//                                     _buildSuggestionCard(service)
//                                 ),
//                                 const SizedBox(height: 8),
//                                 TextButton(
//                                   onPressed: () {
//                                     setState(() {
//                                       showSuggestions = false;
//                                     });
//                                   },
//                                   child: const Text("Créer un nouveau service quand même"),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ],
//                     ),
//
//                     const SizedBox(height: 24),
//
//                     // Champ description
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text(
//                           "Description *",
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                             color: Color(0xFF333333),
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         TextFormField(
//                           controller: _descriptionController,
//                           maxLines: 3,
//                           decoration: InputDecoration(
//                             hintText: "Décrivez le service en détail...",
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: BorderSide(color: Colors.grey.shade300),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 2),
//                             ),
//                           ),
//                           validator: (value) {
//                             if (value == null || value.trim().isEmpty) {
//                               return 'La description est obligatoire';
//                             }
//                             return null;
//                           },
//                         ),
//                       ],
//                     ),
//
//                     const SizedBox(height: 24),
//
//                     // Prix et durée
//                     Row(
//                       children: [
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               const Text(
//                                 "Prix (€) *",
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w600,
//                                   color: Color(0xFF333333),
//                                 ),
//                               ),
//                               const SizedBox(height: 8),
//                               TextFormField(
//                                 controller: _prixController,
//                                 keyboardType: const TextInputType.numberWithOptions(decimal: true),
//                                 decoration: InputDecoration(
//                                   hintText: "25.00",
//                                   prefixIcon: const Icon(Icons.euro),
//                                   border: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(12),
//                                     borderSide: BorderSide(color: Colors.grey.shade300),
//                                   ),
//                                   focusedBorder: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(12),
//                                     borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 2),
//                                   ),
//                                 ),
//                                 validator: (value) {
//                                   if (value == null || value.isEmpty) {
//                                     return 'Prix requis';
//                                   }
//                                   final prix = double.tryParse(value);
//                                   if (prix == null || prix <= 0) {
//                                     return 'Prix invalide';
//                                   }
//                                   return null;
//                                 },
//                               ),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(width: 16),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               const Text(
//                                 "Durée (min) *",
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w600,
//                                   color: Color(0xFF333333),
//                                 ),
//                               ),
//                               const SizedBox(height: 8),
//                               TextFormField(
//                                 controller: _dureeController,
//                                 keyboardType: TextInputType.number,
//                                 decoration: InputDecoration(
//                                   hintText: "30",
//                                   prefixIcon: const Icon(Icons.timer),
//                                   border: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(12),
//                                     borderSide: BorderSide(color: Colors.grey.shade300),
//                                   ),
//                                   focusedBorder: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(12),
//                                     borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 2),
//                                   ),
//                                 ),
//                                 validator: (value) {
//                                   if (value == null || value.isEmpty) {
//                                     return 'Durée requise';
//                                   }
//                                   final duree = int.tryParse(value);
//                                   if (duree == null || duree <= 0) {
//                                     return 'Durée invalide';
//                                   }
//                                   return null;
//                                 },
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//
//                     const SizedBox(height: 30),
//
//                     // Info box
//                     Container(
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: Colors.blue.shade50,
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(color: Colors.blue.shade200),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(Icons.info_outline, color: Colors.blue.shade600),
//                           const SizedBox(width: 12),
//                           const Expanded(
//                             child: Text(
//                               "Ce service sera créé globalement et pourra être utilisé par d'autres salons avec leurs propres prix et durées.",
//                               style: TextStyle(fontSize: 14, color: Colors.blue),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//
//                     const SizedBox(height: 30),
//
//                     // Boutons d'action
//                     Row(
//                       children: [
//                         Expanded(
//                           child: OutlinedButton(
//                             onPressed: isSubmitting ? null : _retournerVersServices,
//                             style: OutlinedButton.styleFrom(
//                               padding: const EdgeInsets.symmetric(vertical: 16),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               side: const BorderSide(color: Color(0xFF7B61FF)),
//                             ),
//                             child: const Text(
//                               "Annuler",
//                               style: TextStyle(color: Color(0xFF7B61FF)),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 16),
//                         Expanded(
//                           flex: 2,
//                           child: ElevatedButton.icon(
//                             onPressed: isSubmitting ? null : _createNewService,
//                             icon: isSubmitting
//                                 ? const SizedBox(
//                               width: 16,
//                               height: 16,
//                               child: CircularProgressIndicator(
//                                 strokeWidth: 2,
//                                 valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                               ),
//                             )
//                                 : const Icon(Icons.add),
//                             label: Text(isSubmitting
//                                 ? "Création en cours..."
//                                 : "Créer le service"),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: const Color(0xFF7B61FF),
//                               foregroundColor: Colors.white,
//                               padding: const EdgeInsets.symmetric(vertical: 16),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//
//                     const SizedBox(height: 50), // Espace en bas pour éviter le débordement
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSuggestionCard(ExistingService service) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 8),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: Colors.grey.shade300),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   service.nom,
//                   style: const TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 14,
//                   ),
//                 ),
//                 Text(
//                   service.description,
//                   style: const TextStyle(
//                     fontSize: 12,
//                     color: Colors.grey,
//                   ),
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 Text(
//                   "Utilisé par ${service.nbSalonsUtilisant} salon(s)",
//                   style: const TextStyle(
//                     fontSize: 11,
//                     color: Colors.grey,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           ElevatedButton(
//             onPressed: () => _useExistingService(service),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.orange,
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(6),
//               ),
//             ),
//             child: const Text("Utiliser", style: TextStyle(fontSize: 12)),
//           ),
//         ],
//       ),
//     );
//   }
// }