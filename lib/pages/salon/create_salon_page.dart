/// *************************************************************************************************
///
/// BANNER : EXPLICATION GÉNÉRALE DE LA PAGE DE CRÉATION DE SALON
///
/// Ce fichier définit `CreateSalonPage`, un `StatefulWidget` qui constitue l'écran
/// où une coiffeuse peut enregistrer les informations de son salon. C'est une étape
/// cruciale du processus d'onboarding pour les professionnels.
///
/// Objectif :
/// Fournir un formulaire unique et complet pour collecter tous les détails nécessaires
/// à la création d'un profil de salon, y compris les informations textuelles, l'adresse
/// et le logo.
///
/// Fonctionnalités Clés :
/// - Formulaire Complet : Rassemble tous les champs nécessaires en une seule vue,
/// du nom du salon au numéro de TVA.
/// - Widgets d'Autocomplétion d'Adresse : Utilise des widgets personnalisés
/// (`StreetAutocomplete`, `CommuneAutoFill`) pour aider l'utilisateur à saisir une
/// adresse précise et valide, en s'appuyant sur l'API Geoapify.
/// - Géocodage Automatique : Calcule automatiquement les coordonnées GPS (latitude,
/// longitude) à partir de l'adresse saisie avant de soumettre les données.
/// - Sélection de Fichier (Logo) : Permet à l'utilisateur de choisir une image depuis
/// son appareil pour l'utiliser comme logo. Gère les cas pour le web (`Uint8List`)
/// et les plateformes natives (`File`).
/// - Logique de Soumission Robuste :
/// - Valide que tous les champs obligatoires sont remplis avant l'envoi.
/// - Construit une requête HTTP `MultipartRequest` pour envoyer à la fois les données
/// textuelles et le fichier image du logo.
/// - Intègre l'authentification Firebase en ajoutant le token de l'utilisateur
/// dans les en-têtes de la requête.
/// - Gère les réponses de succès et d'erreur de l'API.
/// - Navigation Post-Création : En cas de succès, redirige automatiquement la coiffeuse
/// vers la page suivante du processus d'onboarding, `SelectServicesPage`.
///
///*************************************************************************************************
library;

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hairbnb/pages/salon/salon_services_pages/services_pages_services/select_services/select_services_page.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/current_user.dart';
import '../../models/salon_create.dart';
import '../../services/providers/current_user_provider.dart';
import '../profil/profil_widgets/auto_complete_widget.dart';
import '../profil/profil_widgets/commune_autofill_widget.dart';

/// Page de formulaire pour la création d'un nouveau salon par une coiffeuse.
class CreateSalonPage extends StatefulWidget {
  final CurrentUser currentUser;

  const CreateSalonPage({required this.currentUser, super.key});

  @override
  State<CreateSalonPage> createState() => _CreateSalonPageState();
}

class _CreateSalonPageState extends State<CreateSalonPage> {
  // --- Contrôleurs pour les champs de texte ---
  final TextEditingController nomSalonController = TextEditingController();
  final TextEditingController sloganController = TextEditingController();
  final TextEditingController aProposController = TextEditingController();
  final TextEditingController numeroTvaController = TextEditingController();

  // Contrôleurs spécifiques pour les widgets d'adresse.
  final TextEditingController numeroController = TextEditingController();
  final TextEditingController rueController = TextEditingController();
  final TextEditingController codePostalController = TextEditingController();
  final TextEditingController communeController = TextEditingController();

  // --- Variables d'état ---
  Uint8List? logoBytes; // Pour le logo sur le web.
  File? logoFile;      // Pour le logo sur les plateformes natives.
  bool isLoading = false; // Gère l'état de chargement lors de la soumission.
  String? calculatedPosition; // Stocke la position GPS calculée (latitude,longitude).
  int? selectedAdresseId;  // Stocke l'ID de l'adresse après sa création/récupération.

  // Clé API pour le service de géocodage.
  final String geoapifyApiKey = "b097f188b11f46d2a02eb55021d168c1";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        title: const Text("Créer un salon"),
        backgroundColor: const Color(0xFF7B61FF),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false, // Supprime le bouton retour.
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Utilise SingleChildScrollView pour permettre le défilement sur les petits écrans.
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600), // Limite la largeur sur les grands écrans.
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Détails du salon", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF333333))),
                    const SizedBox(height: 30),

                    // Section pour les informations de base du salon.
                    _buildTextField("Nom du salon", nomSalonController, Icons.storefront),
                    const SizedBox(height: 20),
                    _buildTextField("Slogan du salon", sloganController, Icons.short_text),
                    const SizedBox(height: 20),
                    _buildTextField("À propos du salon", aProposController, Icons.info_outline, maxLines: 3),
                    const SizedBox(height: 20),
                    _buildTextField("Numéro de TVA", numeroTvaController, Icons.badge),
                    const SizedBox(height: 30),

                    // Section pour l'adresse du salon.
                    const Text("Adresse du salon", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
                    const SizedBox(height: 20),
                    _buildTextField("Numéro", numeroController, Icons.pin_drop),
                    const SizedBox(height: 20),
                    StreetAutocomplete(streetController: rueController, communeController: communeController, codePostalController: codePostalController, geoapifyApiKey: geoapifyApiKey),
                    const SizedBox(height: 20),
                    CommuneAutoFill(codePostalController: codePostalController, communeController: communeController, geoapifyApiKey: geoapifyApiKey),
                    const SizedBox(height: 20),
                    // Champ "Commune" en lecture seule, rempli automatiquement.
                    TextField(controller: communeController, readOnly: true, decoration: const InputDecoration(labelText: "Commune", border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_city))),
                    const SizedBox(height: 20),

                    // Affichage de la position GPS calculée (utile pour le débogage).
                    if (calculatedPosition != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.shade200)),
                        child: Row(children: [Icon(Icons.check_circle, color: Colors.green.shade600), const SizedBox(width: 8), Expanded(child: Text("Position calculée : $calculatedPosition", style: TextStyle(color: Colors.green.shade700)))]),
                      ),
                    const SizedBox(height: 30),

                    // Section pour le sélecteur de logo.
                    _buildLogoPicker(),
                    const SizedBox(height: 40),

                    // Bouton de soumission du formulaire.
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _saveSalon,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7B61FF),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 4,
                              shadowColor: const Color(0x887B61FF),
                            ).copyWith(overlayColor: WidgetStateProperty.all(const Color(0xFF674ED1))),
                            child: isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text("Créer le salon", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Construit un champ de texte stylisé réutilisable.
  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF7B61FF)),
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF555555)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    );
  }

  /// Construit l'interface pour la sélection et la prévisualisation du logo.
  Widget _buildLogoPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Logo du salon", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _pickLogo,
              icon: const Icon(Icons.image_outlined),
              label: const Text("Choisir une image"),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF3F4F6), foregroundColor: const Color(0xFF7B61FF), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            ),
            const SizedBox(width: 20),
            // Conteneur de prévisualisation de l'image.
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(12)),
              child: logoBytes != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(logoBytes!, fit: BoxFit.cover))
                  : logoFile != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(logoFile!, fit: BoxFit.cover))
                  : const Center(child: Text("Aucune image", style: TextStyle(fontSize: 12))),
            ),
          ],
        ),
      ],
    );
  }

  /// Ouvre le sélecteur de fichiers et met à jour l'état avec l'image sélectionnée.
  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() {
        if (kIsWeb) {
          // Sur le web, on stocke les bytes de l'image.
          logoBytes = result.files.first.bytes;
          logoFile = null;
        } else {
          // Sur les plateformes natives, on stocke le fichier.
          logoFile = File(result.files.first.path!);
          logoBytes = null;
        }
      });
    }
  }

  /// Calcule les coordonnées GPS à partir de l'adresse saisie en utilisant l'API Geoapify.
  Future<void> _calculatePosition() async {
    if (numeroController.text.isEmpty || rueController.text.isEmpty || codePostalController.text.isEmpty || communeController.text.isEmpty) return;

    final fullAddress = "${numeroController.text} ${rueController.text}, ${codePostalController.text} ${communeController.text}, Belgique";
    final url = Uri.parse("https://api.geoapify.com/v1/geocode/search?text=${Uri.encodeComponent(fullAddress)}&lang=fr&limit=1&apiKey=$geoapifyApiKey");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['features'] != null && data['features'].isNotEmpty) {
          final coordinates = data['features'][0]['geometry']['coordinates'];
          setState(() {
            calculatedPosition = "${coordinates[1]},${coordinates[0]}"; // latitude,longitude
          });
          if (kDebugMode) print("Position calculée : $calculatedPosition pour l'adresse : $fullAddress");
        }
      }
    } catch (e) {
      debugPrint("Erreur lors du calcul de la position : $e");
    }
  }

  /// Récupère ou crée un enregistrement d'adresse dans la base de données et retourne son ID.
  Future<int?> _getOrCreateAdresseId() async {
    if (numeroController.text.isEmpty || rueController.text.isEmpty || codePostalController.text.isEmpty || communeController.text.isEmpty) return null;
    // NOTE: Cette fonction est un placeholder. Une implémentation réelle devrait faire un appel API
    // pour vérifier si une adresse existe, la créer si nécessaire, et retourner son ID.
    return 1; // ID fictif pour permettre au flux de continuer.
  }

  /// Valide les champs, construit le modèle de données et envoie le tout à l'API.
  Future<void> _saveSalon() async {
    final utilisateurActuelle = Provider.of<CurrentUserProvider>(context, listen: false).currentUser;

    // --- Validation des champs ---
    List<String> champsManquants = [];
    if (nomSalonController.text.isEmpty) champsManquants.add("Nom du salon");
    if (sloganController.text.isEmpty) champsManquants.add("Slogan");
    if (aProposController.text.isEmpty) champsManquants.add("À propos");
    if (numeroTvaController.text.isEmpty) champsManquants.add("Numéro de TVA");
    if (numeroController.text.isEmpty) champsManquants.add("Numéro");
    if (rueController.text.isEmpty) champsManquants.add("Rue");
    if (codePostalController.text.isEmpty) champsManquants.add("Code postal");
    if (communeController.text.isEmpty) champsManquants.add("Commune");
    if (logoFile == null && logoBytes == null) champsManquants.add("Logo");

    if (champsManquants.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Veuillez renseigner : ${champsManquants.join(", ")}"), backgroundColor: Colors.redAccent));
      return;
    }

    setState(() => isLoading = true);

    try {
      // --- Préparation des données ---
      await _calculatePosition();
      final adresseId = await _getOrCreateAdresseId();

      if (adresseId == null) throw Exception("Impossible de créer l'adresse");
      if (calculatedPosition == null) throw Exception("Impossible de calculer la position géographique");

      // Crée l'objet modèle avec les données du formulaire.
      final salon = SalonCreateModel(
        idTblUser: utilisateurActuelle!.idTblUser,
        nomSalon: nomSalonController.text,
        slogan: sloganController.text,
        logo: kIsWeb ? logoBytes : logoFile,
        aPropos: aProposController.text,
        numeroTva: numeroTvaController.text,
        position: calculatedPosition!,
        adresse: adresseId,
      );

      // --- Envoi de la requête à l'API ---
      final url = Uri.parse("https://www.hairbnb.site/api/ajout_salon/");
      final request = http.MultipartRequest('POST', url);

      // Ajoute le token d'authentification Firebase à la requête.
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final firebaseToken = await user.getIdToken();
        request.headers['Authorization'] = 'Bearer $firebaseToken';
      } else {
        throw Exception("Utilisateur non authentifié");
      }

      // Ajoute les champs textuels à la requête multipart.
      request.fields.addAll(salon.toFields());

      // Ajoute le fichier du logo à la requête multipart.
      if (kIsWeb && salon.logo is Uint8List) {
        request.files.add(http.MultipartFile.fromBytes('logo_salon', salon.logo as Uint8List, filename: 'logo.png', contentType: MediaType('image', 'png')));
      } else if (salon.logo is File) {
        request.files.add(await http.MultipartFile.fromPath('logo_salon', (salon.logo as File).path, contentType: MediaType('image', 'png')));
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      // --- Traitement de la réponse ---
      if (response.statusCode == 201) {
        if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Salon créé avec succès!")));
        // Redirige vers la page de sélection des services.
        if(context.mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => SelectServicesPage(currentUser: utilisateurActuelle)));
      } else {
        debugPrint("Erreur backend : $responseBody");
        // Tente de parser et d'afficher une erreur de validation détaillée du backend.
        try {
          final errorData = jsonDecode(responseBody);
          if (errorData['errors'] != null) {
            String errorMessage = "Erreurs de validation :\n";
            errorData['errors'].forEach((key, value) {
              errorMessage += "- $key : ${value.join(', ')}\n";
            });
            if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage.trim()), backgroundColor: Colors.redAccent, duration: const Duration(seconds: 5)));
          } else {
            throw Exception(errorData['message'] ?? 'Erreur inconnue');
          }
        } catch (e) {
          if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur lors de la création : $responseBody")));
        }
      }
    } catch (e) {
      debugPrint("Erreur lors de la création du salon : $e");
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur : ${e.toString()}"), backgroundColor: Colors.redAccent));
    } finally {
      setState(() => isLoading = false);
    }
  }
}







// // hairbnb/lib/pages/salon/create_salon_page.dart
//
// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:hairbnb/pages/salon/salon_services_pages/services_pages_services/select_services/select_services_page.dart';
// import 'package:http/http.dart' as http;
// import 'package:http_parser/http_parser.dart';
// import 'package:provider/provider.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import '../../models/current_user.dart';
// import '../../models/salon_create.dart';
// import '../../services/providers/current_user_provider.dart';
// import '../profil/profil_widgets/auto_complete_widget.dart';
// import '../profil/profil_widgets/commune_autofill_widget.dart';
//
// class CreateSalonPage extends StatefulWidget {
//   final CurrentUser currentUser;
//
//   const CreateSalonPage({required this.currentUser, super.key});
//
//   @override
//   State<CreateSalonPage> createState() => _CreateSalonPageState();
// }
//
// class _CreateSalonPageState extends State<CreateSalonPage> {
//   // Contrôleurs pour les champs de base
//   final TextEditingController nomSalonController = TextEditingController();
//   final TextEditingController sloganController = TextEditingController();
//   final TextEditingController aProposController = TextEditingController();
//   final TextEditingController numeroTvaController = TextEditingController();
//
//   // Contrôleurs pour l'adresse (nécessaires pour les widgets d'autocomplétion)
//   final TextEditingController numeroController = TextEditingController();
//   final TextEditingController rueController = TextEditingController();
//   final TextEditingController codePostalController = TextEditingController();
//   final TextEditingController communeController = TextEditingController();
//
//   // Variables pour le logo et géolocalisation
//   Uint8List? logoBytes;
//   File? logoFile;
//   bool isLoading = false;
//   String? calculatedPosition; // Position calculée automatiquement
//   int? selectedAdresseId; // ID de l'adresse sélectionnée
//
//   // Clé API Geoapify - À remplacer par votre vraie clé
//   final String geoapifyApiKey = "b097f188b11f46d2a02eb55021d168c1";
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F7F9),
//       appBar: AppBar(
//         title: const Text("Créer un salon"),
//         backgroundColor: const Color(0xFF7B61FF),
//         foregroundColor: Colors.white,
//         centerTitle: true,
//         elevation: 0,
//         automaticallyImplyLeading: false,
//       ),
//       body: LayoutBuilder(
//         builder: (context, constraints) {
//           return SingleChildScrollView(
//             padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
//             child: Center(
//               child: ConstrainedBox(
//                 constraints: const BoxConstraints(maxWidth: 600),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       "Détails du salon",
//                       style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF333333)),
//                     ),
//                     const SizedBox(height: 30),
//
//                     // Informations de base du salon
//                     _buildTextField("Nom du salon", nomSalonController, Icons.storefront),
//                     const SizedBox(height: 20),
//                     _buildTextField("Slogan du salon", sloganController, Icons.short_text),
//                     const SizedBox(height: 20),
//                     _buildTextField("À propos du salon", aProposController, Icons.info_outline, maxLines: 3),
//                     const SizedBox(height: 20),
//                     _buildTextField("Numéro de TVA", numeroTvaController, Icons.badge),
//                     const SizedBox(height: 30),
//
//                     // Section Adresse
//                     const Text(
//                       "Adresse du salon",
//                       style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
//                     ),
//                     const SizedBox(height: 20),
//
//                     // Numéro de rue
//                     _buildTextField("Numéro", numeroController, Icons.pin_drop),
//                     const SizedBox(height: 20),
//
//                     // Autocomplétion des rues
//                     StreetAutocomplete(
//                       streetController: rueController,
//                       communeController: communeController,
//                       codePostalController: codePostalController,
//                       geoapifyApiKey: geoapifyApiKey,
//                     ),
//                     const SizedBox(height: 20),
//
//                     // Autocomplétion code postal -> commune
//                     CommuneAutoFill(
//                       codePostalController: codePostalController,
//                       communeController: communeController,
//                       geoapifyApiKey: geoapifyApiKey,
//                     ),
//                     const SizedBox(height: 20),
//
//                     // Affichage de la commune (en lecture seule)
//                     TextField(
//                       controller: communeController,
//                       readOnly: true,
//                       decoration: const InputDecoration(
//                         labelText: "Commune",
//                         border: OutlineInputBorder(),
//                         prefixIcon: Icon(Icons.location_city),
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//
//                     // Affichage de la position calculée (optionnel, pour debug)
//                     if (calculatedPosition != null)
//                       Container(
//                         padding: const EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           color: Colors.green.shade50,
//                           borderRadius: BorderRadius.circular(8),
//                           border: Border.all(color: Colors.green.shade200),
//                         ),
//                         child: Row(
//                           children: [
//                             Icon(Icons.check_circle, color: Colors.green.shade600),
//                             const SizedBox(width: 8),
//                             Expanded(
//                               child: Text(
//                                 "Position calculée : $calculatedPosition",
//                                 style: TextStyle(color: Colors.green.shade700),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     const SizedBox(height: 30),
//
//                     // Section Logo
//                     _buildLogoPicker(),
//                     const SizedBox(height: 40),
//
//                     // Bouton de création
//                     MouseRegion(
//                       cursor: SystemMouseCursors.click,
//                       child: AnimatedContainer(
//                         duration: const Duration(milliseconds: 200),
//                         curve: Curves.easeInOut,
//                         child: SizedBox(
//                           width: double.infinity,
//                           child: ElevatedButton(
//                             onPressed: isLoading ? null : _saveSalon,
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: const Color(0xFF7B61FF),
//                               padding: const EdgeInsets.symmetric(vertical: 16),
//                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//                               elevation: 4,
//                               shadowColor: const Color(0x887B61FF),
//                             ).copyWith(
//                               overlayColor: WidgetStateProperty.all(const Color(0xFF674ED1)),
//                             ),
//                             child: isLoading
//                                 ? const CircularProgressIndicator(color: Colors.white)
//                                 : const Text("Créer le salon", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
//     return TextField(
//       controller: controller,
//       maxLines: maxLines,
//       decoration: InputDecoration(
//         prefixIcon: Icon(icon, color: const Color(0xFF7B61FF)),
//         labelText: label,
//         labelStyle: const TextStyle(color: Color(0xFF555555)),
//         filled: true,
//         fillColor: Colors.white,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: BorderSide.none,
//         ),
//       ),
//     );
//   }
//
//   Widget _buildLogoPicker() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text("Logo du salon", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
//         const SizedBox(height: 10),
//         Row(
//           children: [
//             ElevatedButton.icon(
//               onPressed: _pickLogo,
//               icon: const Icon(Icons.image_outlined),
//               label: const Text("Choisir une image"),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFFF3F4F6),
//                 foregroundColor: const Color(0xFF7B61FF),
//                 elevation: 0,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//               ),
//             ),
//             const SizedBox(width: 20),
//             Container(
//               width: 100,
//               height: 100,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 border: Border.all(color: const Color(0xFFE5E7EB)),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: logoBytes != null
//                   ? ClipRRect(
//                 borderRadius: BorderRadius.circular(12),
//                 child: Image.memory(logoBytes!, fit: BoxFit.cover),
//               )
//                   : logoFile != null
//                   ? ClipRRect(
//                 borderRadius: BorderRadius.circular(12),
//                 child: Image.file(logoFile!, fit: BoxFit.cover),
//               )
//                   : const Center(child: Text("Aucune image", style: TextStyle(fontSize: 12))),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
//
//   Future<void> _pickLogo() async {
//     final result = await FilePicker.platform.pickFiles(type: FileType.image);
//     if (result != null) {
//       setState(() {
//         if (kIsWeb) {
//           logoBytes = result.files.first.bytes;
//           logoFile = null;
//         } else {
//           logoFile = File(result.files.first.path!);
//           logoBytes = null;
//         }
//       });
//     }
//   }
//
//   /// Calcule automatiquement la position géographique en fonction de l'adresse
//   Future<void> _calculatePosition() async {
//     if (numeroController.text.isEmpty ||
//         rueController.text.isEmpty ||
//         codePostalController.text.isEmpty ||
//         communeController.text.isEmpty) {
//       return;
//     }
//
//     // Construire l'adresse complète
//     final fullAddress = "${numeroController.text} ${rueController.text}, ${codePostalController.text} ${communeController.text}, Belgique";
//
//     // Appel à l'API Geoapify pour obtenir les coordonnées
//     final url = Uri.parse(
//         "https://api.geoapify.com/v1/geocode/search?text=${Uri.encodeComponent(fullAddress)}&lang=fr&limit=1&apiKey=$geoapifyApiKey"
//     );
//
//     try {
//       final response = await http.get(url);
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//
//         if (data['features'] != null && data['features'].isNotEmpty) {
//           final coordinates = data['features'][0]['geometry']['coordinates'];
//           final longitude = coordinates[0];
//           final latitude = coordinates[1];
//
//           setState(() {
//             calculatedPosition = "$latitude,$longitude";
//           });
//
//           if (kDebugMode) {
//             print("Position calculée : $calculatedPosition pour l'adresse : $fullAddress");
//           }
//         }
//       }
//     } catch (e) {
//       debugPrint("Erreur lors du calcul de la position : $e");
//     }
//   }
//
//   /// Récupère ou crée l'ID de l'adresse dans la base de données
//   Future<int?> _getOrCreateAdresseId() async {
//     if (numeroController.text.isEmpty ||
//         rueController.text.isEmpty ||
//         codePostalController.text.isEmpty ||
//         communeController.text.isEmpty) {
//       return null;
//     }
//
//     // TODO: Implémenter l'appel API pour créer/récupérer l'adresse
//     // Cette fonction devrait :
//     // 1. Vérifier si l'adresse existe déjà
//     // 2. Si non, créer la localité, la rue et l'adresse
//     // 3. Retourner l'ID de l'adresse
//
//     // Pour l'instant, retournons un ID fictif
//     // Vous devrez remplacer ceci par un vrai appel API
//     return 1; // ID fictif temporaire
//   }
//
//   Future<void> _saveSalon() async {
//     final utilisateurActuelle = Provider.of<CurrentUserProvider>(context, listen: false).currentUser;
//
//     // Vérification des champs obligatoires
//     List<String> champsManquants = [];
//     if (nomSalonController.text.isEmpty) champsManquants.add("Nom du salon");
//     if (sloganController.text.isEmpty) champsManquants.add("Slogan du salon");
//     if (aProposController.text.isEmpty) champsManquants.add("À propos du salon");
//     if (numeroTvaController.text.isEmpty) champsManquants.add("Numéro de TVA");
//     if (numeroController.text.isEmpty) champsManquants.add("Numéro de rue");
//     if (rueController.text.isEmpty) champsManquants.add("Rue");
//     if (codePostalController.text.isEmpty) champsManquants.add("Code postal");
//     if (communeController.text.isEmpty) champsManquants.add("Commune");
//     if (logoFile == null && logoBytes == null) champsManquants.add("Logo du salon");
//
//     if (champsManquants.isNotEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Veuillez renseigner : ${champsManquants.join(", ")}"),
//           backgroundColor: Colors.redAccent,
//         ),
//       );
//       return;
//     }
//
//     setState(() => isLoading = true);
//
//     try {
//       // Calcul automatique de la position
//       await _calculatePosition();
//
//       // Récupération de l'ID de l'adresse
//       final adresseId = await _getOrCreateAdresseId();
//
//       if (adresseId == null) {
//         throw Exception("Impossible de créer l'adresse");
//       }
//
//       if (calculatedPosition == null) {
//         throw Exception("Impossible de calculer la position géographique");
//       }
//
//       // Création du modèle avec tous les champs obligatoires
//       final salon = SalonCreateModel(
//         idTblUser: utilisateurActuelle!.idTblUser,
//         nomSalon: nomSalonController.text,
//         slogan: sloganController.text,
//         logo: kIsWeb ? logoBytes : logoFile,
//         aPropos: aProposController.text,
//         numeroTva: numeroTvaController.text,
//         position: calculatedPosition!,
//         adresse: adresseId,
//       );
//
//       // Envoi vers l'API avec authentification Firebase
//       final url = Uri.parse("https://www.hairbnb.site/api/ajout_salon/");
//       final request = http.MultipartRequest('POST', url);
//
//       // ✅ Ajout du token d'authentification Firebase
//       final user = FirebaseAuth.instance.currentUser;
//       if (user != null) {
//         final firebaseToken = await user.getIdToken();
//         request.headers['Authorization'] = 'Bearer $firebaseToken';
//       } else {
//         throw Exception("Utilisateur non authentifié");
//       }
//
//       // Ajout des champs du formulaire
//       request.fields.addAll(salon.toFields());
//
//       // Ajout du fichier logo
//       if (kIsWeb && salon.logo is Uint8List) {
//         request.files.add(http.MultipartFile.fromBytes(
//           'logo_salon',
//           salon.logo as Uint8List,
//           filename: 'logo.png',
//           contentType: MediaType('image', 'png'),
//         ));
//       } else if (salon.logo is File) {
//         request.files.add(await http.MultipartFile.fromPath(
//           'logo_salon',
//           (salon.logo as File).path,
//           contentType: MediaType('image', 'png'),
//         ));
//       }
//
//       final response = await request.send();
//       final responseBody = await response.stream.bytesToString();
//
//       if (response.statusCode == 201) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Salon créé avec succès!")),
//         );
//
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => SelectServicesPage(
//               //coiffeuseId: utilisateurActuelle.idTblUser.toString(),
//               currentUser: utilisateurActuelle,
//             ),
//           ),
//         );
//       } else {
//         debugPrint("Erreur backend : $responseBody");
//
//         // Gestion des erreurs de validation du backend
//         try {
//           final errorData = jsonDecode(responseBody);
//           if (errorData['errors'] != null) {
//             String errorMessage = "Erreurs de validation :\n";
//             errorData['errors'].forEach((key, value) {
//               errorMessage += "• $key : ${value.join(', ')}\n";
//             });
//
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text(errorMessage.trim()),
//                 backgroundColor: Colors.redAccent,
//                 duration: const Duration(seconds: 5),
//               ),
//             );
//           } else {
//             throw Exception(errorData['message'] ?? 'Erreur inconnue');
//           }
//         } catch (e) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text("Erreur lors de la création : $responseBody")),
//           );
//         }
//       }
//     } catch (e) {
//       debugPrint("Erreur lors de la création du salon : $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Erreur : ${e.toString()}"),
//           backgroundColor: Colors.redAccent,
//         ),
//       );
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }
// }