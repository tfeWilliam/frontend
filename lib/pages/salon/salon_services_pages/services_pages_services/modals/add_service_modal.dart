/// *************************************************************************************************
///
/// BANNER : EXPLICATION GÉNÉRALE DU FICHIER
///
/// Ce fichier définit une seule fonction complexe : `showAddServiceModal`.
///
/// Objectif :
/// Cette fonction est responsable de l'affichage d'une feuille modale (bottom sheet)
/// hautement interactive qui permet à une coiffeuse d'ajouter un service à son salon.
/// Elle est conçue pour gérer deux flux de travail distincts :
/// 1.  Ajouter un service depuis un catalogue existant : L'utilisateur sélectionne un service
/// prédéfini et ne spécifie que le prix et la durée pour son propre salon.
/// 2.  Créer un tout nouveau service : L'utilisateur définit tous les détails du service,
/// y compris son nom, sa description, sa catégorie, son prix et sa durée.
///
/// Fonctionnalités Clés :
/// - Gestion d'État Interne : Utilise `StatefulBuilder` pour gérer l'état de la modale
/// (comme le mode sélectionné, les valeurs des champs) sans nécessiter un `StatefulWidget` complet.
/// - Double Mode : Un sélecteur permet de basculer entre "Ajouter existant" et "Créer nouveau".
/// - Interaction avec des Providers :
/// - `ServicesProvider`: Charge et met en cache la liste des services existants à suggérer.
/// - `CategoriesProvider`: Charge et met en cache la liste des catégories pour la création d'un nouveau service.
/// - Logique d'API Complexe : La fonction `addService` contient la logique pour valider les
/// données et appeler le bon endpoint de l'API backend en fonction du mode choisi.
/// - Interface Utilisateur Riche : Construit des widgets personnalisés pour les champs de texte,
/// les sélecteurs (dropdowns) avec états de chargement/erreur, et un affichage adaptatif
/// qui se redimensionne avec le clavier.
///
///*************************************************************************************************
library;

import 'package:flutter/material.dart';
import 'package:hairbnb/models/categorie.dart';
import 'package:hairbnb/services/providers/service_suggestion_provider.dart';
import 'package:hairbnb/services/providers/services_categories_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../../../services/firebase_token/token_service.dart';
import '../components/show_dialog.dart';

/// Affiche une feuille modale pour ajouter un service au profil d'une coiffeuse.
///
/// [context] : Le BuildContext de la page appelante.
/// [coiffeuseId] : L'ID de la coiffeuse à qui le service sera ajouté.
/// [onSuccess] : Une fonction de rappel exécutée après un ajout réussi (pour rafraîchir l'UI parente).
/// [categoriesProvider] : L'instance du provider pour accéder aux catégories de services.
/// [servicesProvider] : L'instance du provider pour accéder aux suggestions de services existants.
Future<void> showAddServiceModal(
    BuildContext context,
    String coiffeuseId,
    VoidCallback onSuccess,
    CategoriesProvider categoriesProvider,
    ServicesProvider servicesProvider,
    ) {
  // --- Déclaration des contrôleurs et de l'état local de la modale ---
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController durationController = TextEditingController();

  // Stocke la catégorie sélectionnée lors de la création d'un nouveau service.
  Categorie? selectedCategory;

  // Gère le mode actuel de la modale. `true` pour ajouter un service existant.
  bool isAddExistingMode = true;
  // Stocke le service sélectionné depuis la liste des suggestions.
  ServiceSuggestion? selectedExistingService;

  // Gère l'état de chargement lors de la soumission du formulaire.
  bool isLoading = false;
  final Color primaryViolet = const Color(0xFF7B61FF);

  // Déclenche le chargement des suggestions de services si la liste est vide.
  if (servicesProvider.allServices.isEmpty && !servicesProvider.isLoading) {
    servicesProvider.loadAllServices();
  }

  /// Construit un champ de texte stylisé.
  Widget buildTextField(String label, TextEditingController controller, IconData icon,
      {TextInputType? keyboardType, int maxLines = 1, bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        enabled: enabled, // Le champ est désactivé lorsqu'il est pré-rempli.
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: enabled ? primaryViolet : Colors.grey),
          labelText: label,
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  /// Construit le sélecteur pour basculer entre les modes "Ajouter existant" et "Créer nouveau".
  Widget buildModeToggle(StateSetter setModalState) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
      child: Row(
        children: [
          // Bouton "Ajouter existant"
          Expanded(
            child: GestureDetector(
              onTap: () {
                // Met à jour l'état de la modale pour passer en mode "existant" et réinitialise les champs.
                setModalState(() {
                  isAddExistingMode = true;
                  selectedExistingService = null;
                  nameController.clear();
                  descriptionController.clear();
                  priceController.clear();
                  durationController.clear();
                  selectedCategory = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isAddExistingMode ? primaryViolet : Colors.transparent,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline, color: isAddExistingMode ? Colors.white : primaryViolet, size: 20),
                    const SizedBox(width: 8),
                    Text("Ajouter existant", style: TextStyle(color: isAddExistingMode ? Colors.white : primaryViolet, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
          // Bouton "Créer nouveau"
          Expanded(
            child: GestureDetector(
              onTap: () {
                // Met à jour l'état de la modale pour passer en mode "création" et réinitialise les champs.
                setModalState(() {
                  isAddExistingMode = false;
                  selectedExistingService = null;
                  nameController.clear();
                  descriptionController.clear();
                  priceController.clear();
                  durationController.clear();
                  selectedCategory = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !isAddExistingMode ? primaryViolet : Colors.transparent,
                  borderRadius: const BorderRadius.only(topRight: Radius.circular(12), bottomRight: Radius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.create, color: !isAddExistingMode ? Colors.white : primaryViolet, size: 20),
                    const SizedBox(width: 8),
                    Text("Créer nouveau", style: TextStyle(color: !isAddExistingMode ? Colors.white : primaryViolet, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construit le menu déroulant pour sélectionner un service existant.
  /// Gère les états de chargement, d'erreur et de succès des données du provider.
  Widget buildExistingServiceSelector(StateSetter setModalState) {
    if (!isAddExistingMode) return const SizedBox.shrink(); // N'affiche rien si on n'est pas en mode "existant".

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // État de chargement
          if (servicesProvider.isLoading)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: const Row(children: [Icon(Icons.design_services, color: Color(0xFF7B61FF)), SizedBox(width: 12), Text("Chargement des services..."), Spacer(), SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))]),
            )
          // État d'erreur
          else if (servicesProvider.hasError)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.red[200]!)),
              child: Row(children: [Icon(Icons.error, color: Colors.red[700]), const SizedBox(width: 12), Expanded(child: Text("Erreur: ${servicesProvider.errorMessage}", style: TextStyle(color: Colors.red[700]))), IconButton(icon: const Icon(Icons.refresh), onPressed: () { servicesProvider.loadAllServices(); setModalState(() {}); })]),
            )
          // État avec des données
          else if (servicesProvider.allServices.isNotEmpty) ...[
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: LayoutBuilder( // Utilise LayoutBuilder pour contraindre la largeur du texte dans le dropdown.
                  builder: (context, constraints) {
                    return DropdownButtonFormField<ServiceSuggestion>(
                      value: selectedExistingService,
                      isExpanded: true,
                      decoration: InputDecoration(prefixIcon: Icon(Icons.design_services, color: primaryViolet), labelText: "Service à ajouter *", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
                      hint: const Text("Sélectionner un service"),
                      items: servicesProvider.allServices.map((ServiceSuggestion service) {
                        return DropdownMenuItem<ServiceSuggestion>(
                          value: service,
                          child: SizedBox(
                            width: constraints.maxWidth - 80, // S'assure que le texte ne déborde pas.
                            child: Text("${service.intituleService}${service.categorieNom != null ? ' • ${service.categorieNom}' : ''}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        );
                      }).toList(),
                      onChanged: (ServiceSuggestion? newValue) {
                        setModalState(() {
                          selectedExistingService = newValue;
                          // Pré-remplit le nom du service (en lecture seule) mais laisse les autres champs vides.
                          if (newValue != null) {
                            nameController.text = newValue.intituleService;
                            descriptionController.clear();
                            priceController.clear();
                            durationController.clear();
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              // Affiche une boîte d'information une fois qu'un service est sélectionné.
              if (selectedExistingService != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue[200]!)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [Icon(Icons.info_outline, color: Colors.blue[700]), const SizedBox(width: 8), Text("Service sélectionné", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[700]))]),
                      const SizedBox(height: 8),
                      Text("Service: ${selectedExistingService!.intituleService}", style: TextStyle(color: Colors.blue[600], fontSize: 13)),
                      if (selectedExistingService!.categorieNom != null) ...[const SizedBox(height: 4), Text("Catégorie: ${selectedExistingService!.categorieNom}", style: TextStyle(color: Colors.blue[600], fontSize: 13))],
                      const SizedBox(height: 8),
                      Text("Veuillez définir le prix et la durée pour votre salon.", style: TextStyle(color: Colors.blue[500], fontSize: 12, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ],
            ]
            // État sans service disponible
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey[300]!)),
                child: Row(children: [Icon(Icons.info_outline, color: Colors.grey[600]), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Aucun service disponible", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700])), Text("Passez en mode 'Créer nouveau' pour ajouter un service", style: TextStyle(fontSize: 12, color: Colors.grey[600]))]))]),
              ),
        ],
      ),
    );
  }

  /// Affiche la catégorie du service sélectionné en lecture seule.
  Widget buildCategoryDisplay() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey[300]!)),
        child: Row(
          children: [
            Icon(Icons.category, color: Colors.grey[600]), const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Catégorie", style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)), const SizedBox(height: 4), Text(selectedExistingService?.categorieNom ?? "Sans catégorie", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))]),
            const Spacer(),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: primaryViolet.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text("Automatique", style: TextStyle(color: primaryViolet, fontSize: 12, fontWeight: FontWeight.w600))),
          ],
        ),
      ),
    );
  }

  /// Construit le menu déroulant pour sélectionner une catégorie lors de la création d'un nouveau service.
  Widget buildCategorySelector(StateSetter setModalState) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Builder(builder: (context) {
          if (categoriesProvider.isLoading) { /* ... Gère l'état de chargement ... */ }
          if (categoriesProvider.hasError) { /* ... Gère l'état d'erreur ... */ }
          if (categoriesProvider.categoriesSorted.isEmpty) { /* ... Gère l'état vide ... */ }
          return DropdownButtonFormField<Categorie>(
            value: selectedCategory,
            decoration: InputDecoration(prefixIcon: Icon(Icons.category, color: primaryViolet), labelText: "Catégorie *", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
            hint: const Text("Sélectionner une catégorie"),
            items: categoriesProvider.categoriesSorted.map((Categorie category) => DropdownMenuItem<Categorie>(value: category, child: Text(category.nom, style: const TextStyle(fontSize: 16)))).toList(),
            onChanged: (Categorie? newValue) => setModalState(() => selectedCategory = newValue),
          );
        }),
      ),
    );
  }

  /// Fonction principale pour valider et envoyer les données du service à l'API.
  Future<void> addService(StateSetter setModalState) async {
    // --- Validation des champs en fonction du mode ---
    if (isAddExistingMode) {
      if (selectedExistingService == null) { showErrorDialog(context, "Veuillez sélectionner un service."); return; }
      if (priceController.text.trim().isEmpty || durationController.text.trim().isEmpty) { showErrorDialog(context, "Le prix et la durée sont obligatoires."); return; }
    } else {
      if (selectedCategory == null) { showErrorDialog(context, "Veuillez sélectionner une catégorie."); return; }
      if (nameController.text.trim().isEmpty || descriptionController.text.trim().isEmpty || priceController.text.trim().isEmpty || durationController.text.trim().isEmpty) { showErrorDialog(context, "Tous les champs sont obligatoires."); return; }
    }

    final String intitule = nameController.text.trim();
    final String description = descriptionController.text.trim();
    final String prixText = priceController.text.trim();
    final String durationText = durationController.text.trim();

    // --- Validation des valeurs numériques et des contraintes métier ---
    final double? prix = double.tryParse(prixText);
    final int? temps = int.tryParse(durationText);
    if (prix == null || temps == null) { showErrorDialog(context, "Prix et durée doivent être des nombres valides."); return; }
    if (prix > 999) { showErrorDialog(context, "Le prix ne doit pas dépasser 999 €."); return; }
    if (temps > 480) { showErrorDialog(context, "La durée ne doit pas dépasser 8 heures (480 minutes)."); return; }
    if (!isAddExistingMode) {
      if (intitule.length > 100) { showErrorDialog(context, "L'intitulé ne doit pas dépasser 100 caractères."); return; }
      if (description.length > 700) { showErrorDialog(context, "La description ne doit pas dépasser 700 caractères."); return; }
    }

    setModalState(() => isLoading = true); // Active le chargement.

    try {
      // --- Préparation et envoi de la requête API ---
      final String? idToken = await TokenService.getAuthToken();
      if (idToken == null) { showErrorDialog(context, "Erreur d'authentification. Veuillez vous reconnecter."); setModalState(() => isLoading = false); return; }

      http.Response response;
      if (isAddExistingMode) {
        // Appelle l'API pour ajouter un service existant.
        response = await http.post(
          Uri.parse('https://www.hairbnb.site/api/services/add-existing/'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $idToken'},
          body: json.encode({'userId': int.parse(coiffeuseId), 'service_id': selectedExistingService!.id, 'prix': prix, 'temps_minutes': temps}),
        );
      } else {
        // Appelle l'API pour créer un nouveau service.
        response = await http.post(
          Uri.parse('https://www.hairbnb.site/api/services/create-new/'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $idToken'},
          body: json.encode({'userId': int.parse(coiffeuseId), 'intitule_service': intitule, 'description': description, 'prix': prix, 'temps_minutes': temps, 'categorie_id': selectedCategory!.id}),
        );
      }

      if (kDebugMode) { print("📊 Status code: ${response.statusCode}\n📋 Réponse: ${response.body}"); }

      // --- Traitement de la réponse ---
      if (response.statusCode == 201) {
        Navigator.pop(context, true); // Ferme la modale.
        onSuccess(); // Appelle le callback de succès.
        showSuccessDialog(context, isAddExistingMode ? "Service '$intitule' ajouté avec succès !" : "Service '$intitule' créé et ajouté avec succès !");
      } else {
        Map<String, dynamic> errorResponse = {};
        try { errorResponse = json.decode(response.body); } catch (e) { /* ignore json parse error */ }
        String errorMessage = errorResponse['message'] ?? errorResponse['detail'] ?? "Erreur lors de l'ajout du service (${response.statusCode})";
        if (response.statusCode == 401) { await TokenService.clearAuthToken(); }
        showErrorDialog(context, errorMessage);
      }
    } catch (e) {
      showErrorDialog(context, "Erreur de connexion: $e");
    } finally {
      setModalState(() => isLoading = false); // Désactive le chargement.
    }
  }

  // --- Construction de la feuille modale ---
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Permet à la modale de prendre plus de hauteur.
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(builder: (BuildContext context, StateSetter setModalState) {
        return AnimatedPadding( // S'adapte à la hauteur du clavier.
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          padding: MediaQuery.of(context).viewInsets + const EdgeInsets.all(10),
          child: DraggableScrollableSheet( // Permet à l'utilisateur de redimensionner la feuille.
            initialChildSize: 0.85, maxChildSize: 0.95, minChildSize: 0.5, expand: false,
            builder: (context, scrollController) => Container(
              decoration: const BoxDecoration(color: Color(0xFFF7F7F9), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollController,
                children: [
                  // ... (construction de l'interface utilisateur de la modale avec les widgets définis ci-dessus)
                  // Titre, toggle, champs, etc.
                  Center(child: Container(width: 40, height: 5, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)))),
                  const Text("Ajouter un service", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),
                  buildModeToggle(setModalState),
                  buildExistingServiceSelector(setModalState),
                  if (!isAddExistingMode) ...[
                    buildTextField("Nom du service *", nameController, Icons.design_services),
                    buildTextField("Description *", descriptionController, Icons.description, maxLines: 3),
                    buildCategorySelector(setModalState),
                  ] else if (selectedExistingService != null) ...[
                    buildTextField("Nom du service", nameController, Icons.design_services, enabled: false),
                    buildCategoryDisplay(),
                  ],
                  buildTextField("Prix (€) *", priceController, Icons.euro, keyboardType: TextInputType.number),
                  buildTextField("Durée (minutes) *", durationController, Icons.timer, keyboardType: TextInputType.number),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () => addService(setModalState),
                      style: ElevatedButton.styleFrom(backgroundColor: primaryViolet, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 4),
                      child: isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(isAddExistingMode ? "Ajouter au salon" : "Créer le service", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      });
    },
  );
}









// import 'package:flutter/material.dart';
// import 'package:hairbnb/models/categorie.dart';
// import 'package:hairbnb/services/providers/service_suggestion_provider.dart';
// import 'package:hairbnb/services/providers/services_categories_provider.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import '../../../../../services/firebase_token/token_service.dart';
// import '../components/show_dialog.dart';
//
// Future<void> showAddServiceModal(
//     BuildContext context,
//     String coiffeuseId,
//     VoidCallback onSuccess,
//     CategoriesProvider categoriesProvider,
//     ServicesProvider servicesProvider,
//     ) {
//   final TextEditingController nameController = TextEditingController();
//   final TextEditingController descriptionController = TextEditingController();
//   final TextEditingController priceController = TextEditingController();
//   final TextEditingController durationController = TextEditingController();
//
//   // ✅ Gestion de la catégorie sélectionnée
//   Categorie? selectedCategory;
//
//   // ✅ Gestion du mode et service sélectionné
//   bool isAddExistingMode = true; // Mode par défaut : ajouter service existant
//   ServiceSuggestion? selectedExistingService;
//
//   bool isLoading = false;
//   final Color primaryViolet = const Color(0xFF7B61FF);
//
//   // ✅ Charger les services au démarrage si pas encore fait
//   if (servicesProvider.allServices.isEmpty && !servicesProvider.isLoading) {
//     servicesProvider.loadAllServices();
//   }
//
//   Widget buildTextField(String label, TextEditingController controller, IconData icon,
//       {TextInputType? keyboardType, int maxLines = 1, bool enabled = true}) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 20),
//       child: TextField(
//         controller: controller,
//         maxLines: maxLines,
//         keyboardType: keyboardType,
//         enabled: enabled,
//         decoration: InputDecoration(
//           prefixIcon: Icon(icon, color: enabled ? primaryViolet : Colors.grey),
//           labelText: label,
//           filled: true,
//           fillColor: enabled ? Colors.white : Colors.grey[100],
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(14),
//             borderSide: BorderSide.none,
//           ),
//         ),
//       ),
//     );
//   }
//
//   // ✅ Widget pour basculer entre les modes
//   Widget buildModeToggle(StateSetter setModalState) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 24),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey[300]!),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: GestureDetector(
//               onTap: () {
//                 setModalState(() {
//                   isAddExistingMode = true;
//                   selectedExistingService = null;
//                   nameController.clear();
//                   descriptionController.clear();
//                   priceController.clear();
//                   durationController.clear();
//                   selectedCategory = null;
//                 });
//               },
//               child: Container(
//                 padding: const EdgeInsets.symmetric(vertical: 12),
//                 decoration: BoxDecoration(
//                   color: isAddExistingMode ? primaryViolet : Colors.transparent,
//                   borderRadius: const BorderRadius.only(
//                     topLeft: Radius.circular(12),
//                     bottomLeft: Radius.circular(12),
//                   ),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(
//                       Icons.add_circle_outline,
//                       color: isAddExistingMode ? Colors.white : primaryViolet,
//                       size: 20,
//                     ),
//                     const SizedBox(width: 8),
//                     Text(
//                       "Ajouter existant",
//                       style: TextStyle(
//                         color: isAddExistingMode ? Colors.white : primaryViolet,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           Expanded(
//             child: GestureDetector(
//               onTap: () {
//                 setModalState(() {
//                   isAddExistingMode = false;
//                   selectedExistingService = null;
//                   nameController.clear();
//                   descriptionController.clear();
//                   priceController.clear();
//                   durationController.clear();
//                   selectedCategory = null;
//                 });
//               },
//               child: Container(
//                 padding: const EdgeInsets.symmetric(vertical: 12),
//                 decoration: BoxDecoration(
//                   color: !isAddExistingMode ? primaryViolet : Colors.transparent,
//                   borderRadius: const BorderRadius.only(
//                     topRight: Radius.circular(12),
//                     bottomRight: Radius.circular(12),
//                   ),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(
//                       Icons.create,
//                       color: !isAddExistingMode ? Colors.white : primaryViolet,
//                       size: 20,
//                     ),
//                     const SizedBox(width: 8),
//                     Text(
//                       "Créer nouveau",
//                       style: TextStyle(
//                         color: !isAddExistingMode ? Colors.white : primaryViolet,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ✅ NOUVEAU : Dropdown pour sélectionner un service existant (mis à jour)
//   Widget buildExistingServiceSelector(StateSetter setModalState) {
//     if (!isAddExistingMode) return const SizedBox.shrink();
//
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Loading state
//           if (servicesProvider.isLoading) ...[
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(14),
//               ),
//               child: const Row(
//                 children: [
//                   Icon(Icons.design_services, color: Color(0xFF7B61FF)),
//                   SizedBox(width: 12),
//                   Text("Chargement des services..."),
//                   Spacer(),
//                   SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(strokeWidth: 2),
//                   ),
//                 ],
//               ),
//             ),
//           ]
//           // Error state
//           else if (servicesProvider.hasError) ...[
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.red[50],
//                 borderRadius: BorderRadius.circular(14),
//                 border: Border.all(color: Colors.red[200]!),
//               ),
//               child: Row(
//                 children: [
//                   Icon(Icons.error, color: Colors.red[700]),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Text(
//                       "Erreur: ${servicesProvider.errorMessage}",
//                       style: TextStyle(color: Colors.red[700]),
//                     ),
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.refresh),
//                     onPressed: () {
//                       servicesProvider.loadAllServices();
//                       setModalState(() {});
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ]
//           // Services disponibles
//           else if (servicesProvider.allServices.isNotEmpty) ...[
//               Container(
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(14),
//                 ),
//                 child: LayoutBuilder(
//                   builder: (context, constraints) {
//                     return DropdownButtonFormField<ServiceSuggestion>(
//                       value: selectedExistingService,
//                       isExpanded: true, // ✅ AJOUTÉ : Force l'expansion dans l'espace disponible
//                       decoration: InputDecoration(
//                         prefixIcon: Icon(Icons.design_services, color: primaryViolet),
//                         labelText: "Service à ajouter *",
//                         filled: true,
//                         fillColor: Colors.white,
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(14),
//                           borderSide: BorderSide.none,
//                         ),
//                       ),
//                       hint: const Text("Sélectionner un service"),
//                       items: servicesProvider.allServices.map((ServiceSuggestion service) {
//                         return DropdownMenuItem<ServiceSuggestion>(
//                           value: service,
//                           child: SizedBox(
//                             width: constraints.maxWidth - 80, // ✅ Contrainte de largeur
//                             child: Text(
//                               "${service.intituleService}${service.categorieNom != null ? ' • ${service.categorieNom}' : ''}",
//                               style: const TextStyle(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                         );
//                       }).toList(),
//                       onChanged: (ServiceSuggestion? newValue) {
//                         setModalState(() {
//                           selectedExistingService = newValue;
//                           if (newValue != null) {
//                             nameController.text = newValue.intituleService;
//                             // ✅ SUPPRIMÉ : Plus de description à pré-remplir
//                             descriptionController.clear();
//                             // ✅ SUPPRIMÉ : Plus de prix/durée suggérés
//                             priceController.clear();
//                             durationController.clear();
//                           }
//                         });
//                       },
//                     );
//                   },
//                 ),
//               ),
//
//               // ✅ NOUVEAU : Info du service sélectionné (simplifiée)
//               if (selectedExistingService != null) ...[
//                 const SizedBox(height: 16),
//                 Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Colors.blue[50],
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(color: Colors.blue[200]!),
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Icon(Icons.info_outline, color: Colors.blue[700]),
//                           const SizedBox(width: 8),
//                           Text(
//                             "Service sélectionné",
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               color: Colors.blue[700],
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         "Service: ${selectedExistingService!.intituleService}",
//                         style: TextStyle(color: Colors.blue[600], fontSize: 13),
//                       ),
//                       if (selectedExistingService!.categorieNom != null) ...[
//                         const SizedBox(height: 4),
//                         Text(
//                           "Catégorie: ${selectedExistingService!.categorieNom}",
//                           style: TextStyle(color: Colors.blue[600], fontSize: 13),
//                         ),
//                       ],
//                       const SizedBox(height: 8),
//                       Text(
//                         "Veuillez définir le prix et la durée pour votre salon.",
//                         style: TextStyle(
//                           color: Colors.blue[500],
//                           fontSize: 12,
//                           fontStyle: FontStyle.italic,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ]
//             // Aucun service disponible
//             else ...[
//                 Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Colors.grey[50],
//                     borderRadius: BorderRadius.circular(14),
//                     border: Border.all(color: Colors.grey[300]!),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(Icons.info_outline, color: Colors.grey[600]),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               "Aucun service disponible",
//                               style: TextStyle(
//                                 fontWeight: FontWeight.w600,
//                                 color: Colors.grey[700],
//                               ),
//                             ),
//                             Text(
//                               "Passez en mode 'Créer nouveau' pour ajouter un service",
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 color: Colors.grey[600],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//         ],
//       ),
//     );
//   }
//
//   // ✅ NOUVEAU : Widget pour afficher la catégorie en lecture seule
//   Widget buildCategoryDisplay() {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 20),
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.grey[100],
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(color: Colors.grey[300]!),
//         ),
//         child: Row(
//           children: [
//             Icon(Icons.category, color: Colors.grey[600]),
//             const SizedBox(width: 12),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   "Catégorie",
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Colors.grey[600],
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   selectedExistingService?.categorieNom ?? "Sans catégorie",
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ),
//             const Spacer(),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//               decoration: BoxDecoration(
//                 color: primaryViolet.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(6),
//               ),
//               child: Text(
//                 "Automatique",
//                 style: TextStyle(
//                   color: primaryViolet,
//                   fontSize: 12,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//   Widget buildCategorySelector(StateSetter setModalState) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 20),
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(14),
//         ),
//         child: Builder(
//           builder: (context) {
//             if (categoriesProvider.isLoading) {
//               return const Padding(
//                 padding: EdgeInsets.all(16),
//                 child: Row(
//                   children: [
//                     Icon(Icons.category, color: Color(0xFF7B61FF)),
//                     SizedBox(width: 12),
//                     Text("Chargement des catégories..."),
//                     Spacer(),
//                     SizedBox(
//                       width: 20,
//                       height: 20,
//                       child: CircularProgressIndicator(strokeWidth: 2),
//                     ),
//                   ],
//                 ),
//               );
//             }
//
//             if (categoriesProvider.hasError) {
//               return Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Row(
//                   children: [
//                     const Icon(Icons.error, color: Colors.red),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Text(
//                         "Erreur : ${categoriesProvider.errorMessage}",
//                         style: const TextStyle(color: Colors.red),
//                       ),
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.refresh),
//                       onPressed: () {
//                         categoriesProvider.refreshCategories();
//                         setModalState(() {});
//                       },
//                     ),
//                   ],
//                 ),
//               );
//             }
//
//             final categories = categoriesProvider.categoriesSorted;
//
//             if (categories.isEmpty) {
//               return const Padding(
//                 padding: EdgeInsets.all(16),
//                 child: Row(
//                   children: [
//                     Icon(Icons.category, color: Colors.grey),
//                     SizedBox(width: 12),
//                     Text("Aucune catégorie disponible"),
//                   ],
//                 ),
//               );
//             }
//
//             return DropdownButtonFormField<Categorie>(
//               value: selectedCategory,
//               decoration: InputDecoration(
//                 prefixIcon: Icon(Icons.category, color: primaryViolet),
//                 labelText: "Catégorie *",
//                 filled: true,
//                 fillColor: Colors.white,
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(14),
//                   borderSide: BorderSide.none,
//                 ),
//               ),
//               hint: const Text("Sélectionner une catégorie"),
//               items: categories.map((Categorie category) {
//                 return DropdownMenuItem<Categorie>(
//                   value: category,
//                   child: Text(
//                     category.nom,
//                     style: const TextStyle(fontSize: 16),
//                   ),
//                 );
//               }).toList(),
//               onChanged: (Categorie? newValue) {
//                 setModalState(() {
//                   selectedCategory = newValue;
//                 });
//               },
//             );
//           },
//         ),
//       ),
//     );
//   }
//
//   Future<void> addService(StateSetter setModalState) async {
//     // ✅ Validation selon le mode
//     if (isAddExistingMode) {
//       // Mode ajouter existant
//       if (selectedExistingService == null) {
//         showErrorDialog(context, "Veuillez sélectionner un service.");
//         return;
//       }
//       // ✅ SUPPRIMÉ : Pas besoin de vérifier selectedCategory pour service existant
//       if (priceController.text.trim().isEmpty || durationController.text.trim().isEmpty) {
//         showErrorDialog(context, "Le prix et la durée sont obligatoires.");
//         return;
//       }
//     } else {
//       // Mode créer nouveau
//       if (selectedCategory == null) {
//         showErrorDialog(context, "Veuillez sélectionner une catégorie.");
//         return;
//       }
//       if (nameController.text.trim().isEmpty ||
//           descriptionController.text.trim().isEmpty ||
//           priceController.text.trim().isEmpty ||
//           durationController.text.trim().isEmpty) {
//         showErrorDialog(context, "Tous les champs sont obligatoires.");
//         return;
//       }
//     }
//
//     final String intitule = nameController.text.trim();
//     final String description = descriptionController.text.trim();
//     final String prixText = priceController.text.trim();
//     final String durationText = durationController.text.trim();
//
//     // Validation des nombres
//     final double? prix = double.tryParse(prixText);
//     final int? temps = int.tryParse(durationText);
//
//     if (prix == null || temps == null) {
//       showErrorDialog(context, "Prix et durée doivent être des nombres valides.");
//       return;
//     }
//
//     if (prix > 999) {
//       showErrorDialog(context, "Le prix ne doit pas dépasser 999 €.");
//       return;
//     }
//
//     if (temps > 480) {
//       showErrorDialog(context, "La durée ne doit pas dépasser 8 heures (480 minutes).");
//       return;
//     }
//
//     // Validation supplémentaire pour nouveau service
//     if (!isAddExistingMode) {
//       if (intitule.length > 100) {
//         showErrorDialog(context, "L'intitulé ne doit pas dépasser 100 caractères.");
//         return;
//       }
//       if (description.length > 700) {
//         showErrorDialog(context, "La description ne doit pas dépasser 700 caractères.");
//         return;
//       }
//     }
//
//     setModalState(() => isLoading = true);
//
//     try {
//       final String? idToken = await TokenService.getAuthToken();
//
//       if (idToken == null) {
//         showErrorDialog(context, "Erreur d'authentification. Veuillez vous reconnecter.");
//         setModalState(() => isLoading = false);
//         return;
//       }
//
//       http.Response response;
//
//       if (isAddExistingMode) {
//         // ✅ API pour ajouter un service existant (sans categorie_id)
//         response = await http.post(
//           Uri.parse('https://www.hairbnb.site/api/services/add-existing/'),
//           headers: {
//             'Content-Type': 'application/json',
//             'Authorization': 'Bearer $idToken',
//           },
//           body: json.encode({
//             'userId': int.parse(coiffeuseId),
//             'service_id': selectedExistingService!.id,
//             'prix': prix,
//             'temps_minutes': temps,
//             // ✅ SUPPRIMÉ : 'categorie_id' car le service a déjà sa catégorie
//           }),
//         );
//       } else {
//         // ✅ API pour créer un nouveau service
//         response = await http.post(
//           Uri.parse('https://www.hairbnb.site/api/services/create-new/'),
//           headers: {
//             'Content-Type': 'application/json',
//             'Authorization': 'Bearer $idToken',
//           },
//           body: json.encode({
//             'userId': int.parse(coiffeuseId),
//             'intitule_service': intitule,
//             'description': description,
//             'prix': prix,
//             'temps_minutes': temps,
//             'categorie_id': selectedCategory!.id,
//           }),
//         );
//       }
//
//       if (kDebugMode) {
//         print("📊 Status code: ${response.statusCode}");
//         print("📋 Réponse: ${response.body}");
//       }
//
//       if (response.statusCode == 201) {
//         Navigator.pop(context, true);
//         onSuccess();
//
//         showSuccessDialog(
//             context,
//             isAddExistingMode
//                 ? "Service '$intitule' ajouté avec succès !"
//                 : "Service '$intitule' créé et ajouté avec succès !"
//         );
//       } else {
//         Map<String, dynamic> errorResponse = {};
//         try {
//           errorResponse = json.decode(response.body);
//         } catch (e) {
//           // Si la réponse n'est pas du JSON valide
//         }
//
//         String errorMessage = errorResponse['message'] ??
//             errorResponse['detail'] ??
//             "Erreur lors de l'ajout du service (${response.statusCode})";
//
//         if (response.statusCode == 401) {
//           await TokenService.clearAuthToken();
//         }
//
//         showErrorDialog(context, errorMessage);
//       }
//     } catch (e) {
//       showErrorDialog(context, "Erreur de connexion: $e");
//     } finally {
//       setModalState(() => isLoading = false);
//     }
//   }
//
//   return showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     backgroundColor: Colors.transparent,
//     builder: (context) {
//       return StatefulBuilder(
//         builder: (BuildContext context, StateSetter setModalState) {
//           return AnimatedPadding(
//             duration: const Duration(milliseconds: 300),
//             curve: Curves.easeOut,
//             padding: MediaQuery.of(context).viewInsets + const EdgeInsets.all(10),
//             child: DraggableScrollableSheet(
//               initialChildSize: 0.85,
//               maxChildSize: 0.95,
//               minChildSize: 0.5,
//               expand: false,
//               builder: (context, scrollController) => Container(
//                 decoration: const BoxDecoration(
//                   color: Color(0xFFF7F7F9),
//                   borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//                 ),
//                 padding: const EdgeInsets.all(20),
//                 child: ListView(
//                   controller: scrollController,
//                   children: [
//                     Center(
//                       child: Container(
//                         width: 40,
//                         height: 5,
//                         margin: const EdgeInsets.only(bottom: 20),
//                         decoration: BoxDecoration(
//                           color: Colors.grey[300],
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                     ),
//
//                     Text(
//                       "Ajouter un service",
//                       style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
//                     ),
//                     const SizedBox(height: 20),
//
//                     // ✅ Toggle entre les modes
//                     buildModeToggle(setModalState),
//
//                     // ✅ Sélecteur de service existant (mis à jour)
//                     buildExistingServiceSelector(setModalState),
//
//                     // ✅ Champs selon le mode
//                     if (!isAddExistingMode) ...[
//                       buildTextField("Nom du service *", nameController, Icons.design_services),
//                       buildTextField("Description *", descriptionController, Icons.description, maxLines: 3),
//                       // ✅ Catégorie seulement pour nouveau service
//                       buildCategorySelector(setModalState),
//                     ] else if (selectedExistingService != null) ...[
//                       buildTextField("Nom du service", nameController, Icons.design_services, enabled: false),
//                       // ✅ Affichage de la catégorie en lecture seule
//                       buildCategoryDisplay(),
//                     ],
//
//                     // ✅ Prix et durée (toujours modifiables)
//                     buildTextField("Prix (€) *", priceController, Icons.euro, keyboardType: TextInputType.number),
//                     buildTextField("Durée (minutes) *", durationController, Icons.timer, keyboardType: TextInputType.number),
//
//                     const SizedBox(height: 20),
//
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         onPressed: isLoading ? null : () => addService(setModalState),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: primaryViolet,
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//                           elevation: 4,
//                         ),
//                         child: isLoading
//                             ? const CircularProgressIndicator(color: Colors.white)
//                             : Text(
//                             isAddExistingMode ? "Ajouter au salon" : "Créer le service",
//                             style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         },
//       );
//     },
//   );
// }
//
