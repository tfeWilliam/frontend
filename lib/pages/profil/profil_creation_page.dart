/// *************************************************************************************************
///
/// BANNER : EXPLICATION GÉNÉRALE DE LA PAGE DE CRÉATION DE PROFIL
///
/// Ce fichier définit `ProfileCreationPage`, un `StatefulWidget` qui constitue l'écran
/// de création de profil pour les nouveaux utilisateurs de l'application.
///
/// Objectif :
/// Guider l'utilisateur à travers un formulaire en plusieurs étapes pour collecter toutes
/// les informations nécessaires à la création de son compte (personnelles, adresse,
/// et professionnelles si applicable).
///
/// Fonctionnalités Clés :
/// 1.  Formulaire Multi-étapes : Le processus est divisé en 2 ou 3 étapes (selon le rôle)
/// pour une expérience utilisateur plus claire et moins intimidante.
/// 2.  Sélection de Rôle : L'utilisateur peut choisir entre un profil "Client" ou "Coiffeuse",
/// ce qui adapte dynamiquement le nombre d'étapes et les champs du formulaire.
/// 3.  Validation en Temps Réel : Les champs sont validés au fur et à mesure que l'utilisateur
/// tape, avec un retour visuel immédiat (une icône de coche verte) pour indiquer
/// que les données sont correctement formatées.
/// 4.  Widgets d'Autocomplétion : Utilise des widgets personnalisés pour l'adresse
/// (`CommuneAutoFill`, `StreetAutocomplete`) qui interrogent une API (Geoapify)
/// pour garantir la précision des données.
/// 5.  Gestion de l'État :
/// - Utilise `setState` pour la gestion de l'état local de la page (données des champs,
/// étape actuelle, états de validation).
/// - Interagit avec `Provider` (`CurrentUserProvider`) pour mettre à jour l'état global de
/// l'application après la création réussie du profil.
/// 6.  Communication API :
/// - Délègue les appels réseau à un service dédié (`ProfileApiService`).
/// - Gère l'authentification en récupérant un token via `TokenService`.
/// - Gère les réponses de succès et d'erreur de l'API, en fournissant des retours
/// appropriés à l'utilisateur (dialogue de succès, `SnackBar` d'erreur).
/// 7.  Redirection Post-Création : Redirige l'utilisateur vers la page appropriée
/// (création de salon pour une coiffeuse, page d'accueil pour un client) après la
/// création du profil.
///
///*************************************************************************************************
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hairbnb/pages/profil/services/profile_creation_api.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../services/firebase_token/token_service.dart';
import '../../services/providers/current_user_provider.dart';
import '../home_page.dart';
import '../salon/create_salon_page.dart';
import '../../models/user_creation.dart';
import 'profil_widgets/auto_complete_widget.dart';
import 'profil_widgets/commune_autofill_widget.dart';

class ProfileCreationPage extends StatefulWidget {
  final String userUuid;
  final String email;

  const ProfileCreationPage({
    required this.userUuid,
    required this.email,
    super.key,
  });

  @override
  State<ProfileCreationPage> createState() => _ProfileCreationPageState();
}

class _ProfileCreationPageState extends State<ProfileCreationPage> {
  // Définition des couleurs du thème de la page.
  final Color primaryColor = const Color(0xFF8E44AD);
  final Color secondaryColor = const Color(0xFFF39C12);

  // Clé API pour le service de géolocalisation Geoapify.
  static const String geoapifyApiKey = 'b097f188b11f46d2a02eb55021d168c1';

  // Variables d'état pour le formulaire.
  String? selectedGender;
  final List<String> genderOptions = ["Homme", "Femme"];
  Uint8List? profilePhotoBytes;
  File? profilePhoto;
  bool isCoiffeuse = false;
  late String userEmail;
  late String userUuid;
  int _currentStep = 0; // Gère l'étape actuelle du formulaire (0, 1, ou 2).

  // Variables d'état spécifiques pour la validation de l'adresse.
  bool _isStreetSelected = false;
  bool _isCommuneValid = false;

  // Map pour suivre l'état de validation de chaque champ et afficher une icône de succès.
  final Map<String, bool> _fieldValidationStatus = {
    'name': false,
    'surname': false,
    'gender': false,
    'birthDate': false,
    'phone': false,
    'codePostal': false,
    'commune': false,
    'street': false,
    'streetNumber': false,
    'postalBox': true,
    'socialName': false,
  };

  // Contrôleurs pour les champs de texte du formulaire.
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController codePostalController = TextEditingController();
  final TextEditingController communeController = TextEditingController();
  final TextEditingController streetController = TextEditingController();
  final TextEditingController streetNumberController = TextEditingController();
  final TextEditingController postalBoxController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController socialNameController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();

  // Clé globale pour identifier et valider le formulaire.
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    userEmail = widget.email;
    userUuid = widget.userUuid;

    // Ajoute des écouteurs aux contrôleurs pour la validation en temps réel.
    nameController.addListener(() => _validateField('name', nameController.text));
    surnameController.addListener(() => _validateField('surname', surnameController.text));
    phoneController.addListener(() => _validateField('phone', phoneController.text));
    birthDateController.addListener(() => _validateField('birthDate', birthDateController.text));
    codePostalController.addListener(() => _validateField('codePostal', codePostalController.text));
    streetNumberController.addListener(() => _validateField('streetNumber', streetNumberController.text));
    postalBoxController.addListener(() => _validateField('postalBox', postalBoxController.text));
    socialNameController.addListener(() => _validateField('socialName', socialNameController.text));

    // Synchronise l'état de validation initial.
    if (selectedGender != null && selectedGender!.isNotEmpty) {
      _fieldValidationStatus['gender'] = true;
    }
    _fieldValidationStatus['street'] = _isStreetSelected;
    _fieldValidationStatus['commune'] = _isCommuneValid;
  }

  @override
  void dispose() {
    // Retire les écouteurs pour éviter les fuites de mémoire.
    nameController.removeListener(() {});
    surnameController.removeListener(() {});
    phoneController.removeListener(() {});
    birthDateController.removeListener(() {});
    codePostalController.removeListener(() {});
    streetNumberController.removeListener(() {});
    postalBoxController.removeListener(() {});
    socialNameController.removeListener(() {});

    // Libère les ressources des contrôleurs.
    nameController.dispose();
    surnameController.dispose();
    codePostalController.dispose();
    communeController.dispose();
    streetController.dispose();
    streetNumberController.dispose();
    postalBoxController.dispose();
    phoneController.dispose();
    socialNameController.dispose();
    birthDateController.dispose();
    super.dispose();
  }

  // Méthode centrale pour mettre à jour l'état de validation d'un champ.
  void _validateField(String fieldName, String? value) {
    String? error;
    switch (fieldName) {
      case 'name':
        error = _validateNameSurname(value, 'nom');
        break;
      case 'surname':
        error = _validateNameSurname(value, 'prénom');
        break;
      case 'phone':
        error = _validatePhone(value);
        break;
      case 'birthDate':
        error = _validateBirthDate(value);
        break;
      case 'codePostal':
        error = (value == null || value.isEmpty || value.length < 4) ? 'Code postal requis' : null;
        break;
      case 'streetNumber':
        error = _validateStreetNumber(value);
        break;
      case 'postalBox':
        error = _validatePostalBox(value);
        break;
      case 'socialName':
        error = (value == null || value.isEmpty) ? 'Nom commercial requis' : null;
        break;
    }
    setState(() {
      _fieldValidationStatus[fieldName] = error == null;
    });
  }

  // Fonctions de validation spécifiques pour chaque type de champ.
  String? _validateNameSurname(String? value, String fieldLabel) {
    if (value == null || value.isEmpty) return 'Veuillez entrer votre $fieldLabel';
    if (!RegExp(r"^[a-zA-Zà-öø-ÿ' -]+$").hasMatch(value)) return 'Caractères non autorisés.';
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Veuillez entrer votre numéro de téléphone';
    if (!RegExp(r"^0\d{1,}(\s*\d{2}){3}\s*\d{2}$|^0\d{8}$|^0\d{9}$").hasMatch(value.replaceAll(RegExp(r'[ .\-]'), ''))) {
      return 'Format de numéro belge invalide.';
    }
    return null;
  }

  String? _validateBirthDate(String? value) {
    if (value == null || value.isEmpty) return 'Veuillez entrer votre date de naissance';
    if (!_isValidDateLogic(value)) return 'Format invalide (JJ-MM-AAAA) ou âge incorrect (16+).';
    return null;
  }

  String? _validateStreetNumber(String? value) {
    if (value == null || value.isEmpty) return 'Obligatoire';
    if (!RegExp(r"^[0-9]+[a-zA-Z]?$").hasMatch(value)) return 'Format invalide (ex: 12, 12A).';
    return null;
  }

  String? _validatePostalBox(String? value) {
    if (value != null && value.isNotEmpty && !RegExp(r"^[a-zA-Z0-9]+$").hasMatch(value)) {
      return 'Format invalide (ex: B, 10).';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildProfilePhoto(),
                      const SizedBox(height: 16),
                      if (_currentStep == 0) ...[
                        _buildRoleSelector(),
                        const SizedBox(height: 24),
                      ],
                      _buildStepIndicator(),
                      const SizedBox(height: 20),
                      _buildCurrentStep(),
                      const SizedBox(height: 20),
                      _buildNavigationButtons(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Construit l'en-tête (AppBar) de la page.
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text("Créer votre profil", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [primaryColor, primaryColor.withOpacity(0.7)],
            ),
          ),
        ),
      ),
    );
  }

  // Construit le widget d'affichage et de sélection de la photo de profil.
  Widget _buildProfilePhoto() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _pickPhoto,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 1)]),
                  child: ClipOval(
                    child: profilePhotoBytes != null
                        ? Image.memory(profilePhotoBytes!, fit: BoxFit.cover)
                        : profilePhoto != null
                        ? Image.file(profilePhoto!, fit: BoxFit.cover)
                        : Icon(Icons.person, size: 70, color: Colors.grey[400]),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: secondaryColor, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text("Photo de profil", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        ],
      ),
    );
  }

  // Construit le sélecteur de rôle (Client / Coiffeuse).
  Widget _buildRoleSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 1)]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Je suis :", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Row(
            children: [
              Text("Client", style: TextStyle(color: !isCoiffeuse ? primaryColor : Colors.grey, fontWeight: !isCoiffeuse ? FontWeight.bold : FontWeight.normal)),
              Switch(
                value: isCoiffeuse,
                onChanged: (value) => setState(() => isCoiffeuse = value),
                activeColor: secondaryColor,
                activeTrackColor: secondaryColor.withOpacity(0.5),
              ),
              Text("Coiffeuse", style: TextStyle(color: isCoiffeuse ? primaryColor : Colors.grey, fontWeight: isCoiffeuse ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        ],
      ),
    );
  }

  // Construit l'indicateur de progression des étapes du formulaire.
  Widget _buildStepIndicator() {
    final int totalSteps = isCoiffeuse ? 3 : 2;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(totalSteps, (index) {
          return Expanded(
            child: Container(
              height: 4, margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(color: index <= _currentStep ? primaryColor : Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
          );
        }),
      ),
    );
  }

  // Affiche le contenu de l'étape actuelle du formulaire.
  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0: return _buildPersonalInfoStep();
      case 1: return _buildAddressStep();
      case 2: return isCoiffeuse ? _buildProfessionalInfoStep() : _buildPersonalInfoStep();
      default: return _buildPersonalInfoStep();
    }
  }

  // Étape 0 : Informations personnelles.
  Widget _buildPersonalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Informations personnelles", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor)),
        const SizedBox(height: 20),
        _buildInputField(label: "Nom", controller: nameController, icon: Icons.person_outline, fieldName: 'name', validator: (value) => _validateNameSurname(value, 'nom')),
        const SizedBox(height: 16),
        _buildInputField(label: "Prénom", controller: surnameController, icon: Icons.person_outline, fieldName: 'surname', validator: (value) => _validateNameSurname(value, 'prénom')),
        const SizedBox(height: 16),
        _buildGenderDropdown(),
        const SizedBox(height: 16),
        _buildDatePicker(),
        const SizedBox(height: 16),
        _buildInputField(label: "Téléphone", controller: phoneController, icon: Icons.phone, keyboardType: TextInputType.phone, fieldName: 'phone', validator: _validatePhone),
      ],
    );
  }

  // Étape 1 : Adresse.
  Widget _buildAddressStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Adresse", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor)),
        const SizedBox(height: 20),
        Stack(
          alignment: Alignment.centerRight,
          children: [
            CommuneAutoFill(
              codePostalController: codePostalController,
              communeController: communeController,
              geoapifyApiKey: geoapifyApiKey,
              onCommuneFound: () => setState(() { _isCommuneValid = true; _fieldValidationStatus['commune'] = true; _fieldValidationStatus['codePostal'] = true; }),
              onCommuneNotFound: () => setState(() { _isCommuneValid = false; _fieldValidationStatus['commune'] = false; _fieldValidationStatus['codePostal'] = false; }),
            ),
            if (_fieldValidationStatus['codePostal'] == true && _isCommuneValid)
              Padding(padding: const EdgeInsets.only(right: 12.0), child: Icon(Icons.check_circle, color: Colors.green[700], size: 24)),
          ],
        ),
        const SizedBox(height: 16),
        _buildInputField(
          label: "Commune", controller: communeController, icon: Icons.location_city, readOnly: true, fieldName: 'commune',
          validator: (value) => (value == null || value.isEmpty || value.contains("introuvable") || value.contains("Erreur")) ? 'Code postal invalide.' : null,
        ),
        const SizedBox(height: 16),
        Stack(
          alignment: Alignment.centerRight,
          children: [
            StreetAutocomplete(
              streetController: streetController,
              communeController: communeController,
              codePostalController: codePostalController,
              geoapifyApiKey: geoapifyApiKey,
              onStreetSelected: () => setState(() { _isStreetSelected = true; _fieldValidationStatus['street'] = true; }),
              onStreetChanged: () => setState(() { _isStreetSelected = false; _fieldValidationStatus['street'] = false; }),
            ),
            if (_fieldValidationStatus['street'] == true)
              Padding(padding: const EdgeInsets.only(right: 12.0), child: Icon(Icons.check_circle, color: Colors.green[700], size: 24)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildInputField(label: "Numéro", controller: streetNumberController, icon: Icons.home, fieldName: 'streetNumber', validator: _validateStreetNumber)),
            const SizedBox(width: 16),
            Expanded(child: _buildInputField(label: "Boîte", controller: postalBoxController, icon: Icons.inbox, fieldName: 'postalBox', validator: _validatePostalBox)),
          ],
        ),
      ],
    );
  }

  // Étape 2 : Informations professionnelles (pour les coiffeuses).
  Widget _buildProfessionalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Informations professionnelles", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor)),
        const SizedBox(height: 20),
        _buildInputField(
          label: "Nom Commercial", controller: socialNameController, icon: Icons.business, fieldName: 'socialName',
          validator: (value) => (value == null || value.isEmpty) ? 'Veuillez entrer votre nom commercial' : null,
        ),
      ],
    );
  }

  // Widget générique et stylisé pour un champ de formulaire.
  Widget _buildInputField({
    required String label, required TextEditingController controller, required IconData icon,
    bool readOnly = false, TextInputType keyboardType = TextInputType.text,
    Function(String)? onChanged, String? Function(String?)? validator, required String fieldName,
  }) {
    bool isValid = _fieldValidationStatus[fieldName] ?? false;
    return TextFormField(
      controller: controller, readOnly: readOnly, keyboardType: keyboardType,
      onChanged: (text) {
        onChanged?.call(text);
        _validateField(fieldName, text);
      },
      validator: (value) {
        final error = validator?.call(value);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _fieldValidationStatus[fieldName] = error == null);
        });
        return error;
      },
      decoration: InputDecoration(
        labelText: label, prefixIcon: Icon(icon, color: primaryColor),
        suffixIcon: isValid && controller.text.isNotEmpty && !readOnly ? Icon(Icons.check_circle, color: Colors.green[700], size: 24) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 2)),
        filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  // Construit le menu déroulant pour la sélection du sexe.
  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedGender,
      decoration: InputDecoration(
        labelText: "Sexe", prefixIcon: Icon(Icons.person, color: primaryColor),
        suffixIcon: (_fieldValidationStatus['gender'] ?? false) ? Icon(Icons.check_circle, color: Colors.green[700], size: 24) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 2)),
        filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
      items: genderOptions.map((gender) => DropdownMenuItem(value: gender, child: Text(gender))).toList(),
      onChanged: (value) => setState(() { selectedGender = value; _fieldValidationStatus['gender'] = (value != null && value.isNotEmpty); }),
      validator: (value) {
        final error = (value == null || value.isEmpty) ? 'Veuillez sélectionner votre genre' : null;
        WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) setState(() => _fieldValidationStatus['gender'] = error == null); });
        return error;
      },
    );
  }

  // Construit le sélecteur de date pour la date de naissance.
  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context, initialDate: DateTime.now().subtract(const Duration(days: 365 * 16)),
          firstDate: DateTime(1900), lastDate: DateTime.now(),
          builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: primaryColor, onPrimary: Colors.white, onSurface: Colors.black)), child: child!),
        );
        if (selectedDate != null) {
          setState(() {
            birthDateController.text = "${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year}";
            _validateField('birthDate', birthDateController.text);
          });
        }
      },
      child: AbsorbPointer(
        child: TextFormField(
          controller: birthDateController,
          decoration: InputDecoration(
            labelText: "Date de naissance", prefixIcon: Icon(Icons.calendar_today, color: primaryColor),
            suffixIcon: (_fieldValidationStatus['birthDate'] ?? false) ? Icon(Icons.check_circle, color: Colors.green[700], size: 24) : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 2)),
            filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          validator: (value) {
            final error = _validateBirthDate(value);
            WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) setState(() => _fieldValidationStatus['birthDate'] = error == null); });
            return error;
          },
        ),
      ),
    );
  }

  // Construit les boutons de navigation (Précédent / Suivant / Enregistrer).
  Widget _buildNavigationButtons() {
    final int totalSteps = isCoiffeuse ? 3 : 2;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _currentStep > 0
            ? ElevatedButton.icon(icon: const Icon(Icons.arrow_back), label: const Text("Précédent"), onPressed: () => setState(() => _currentStep--), style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200], foregroundColor: Colors.black87, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))
            : const SizedBox(width: 120),
        _currentStep < totalSteps - 1
            ? ElevatedButton.icon(
          icon: const Icon(Icons.arrow_forward), label: const Text("Suivant"),
          onPressed: () {
            if (_formKey.currentState?.validate() == true) {
              if (_currentStep == 1) {
                if (!_isStreetSelected) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez sélectionner une rue de la liste."))); return; }
                if (!_isCommuneValid) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez entrer un code postal valide."))); return; }
              }
              setState(() => _currentStep++);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        )
            : ElevatedButton.icon(
          icon: const Icon(Icons.check), label: const Text("Enregistrer"),
          onPressed: () {
            if (_formKey.currentState?.validate() == true) {
              if (_currentStep == 1) {
                if (!_isStreetSelected) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez sélectionner une rue de la liste."))); return; }
                if (!_isCommuneValid) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez entrer un code postal valide."))); return; }
              }
              _saveProfile();
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: secondaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ],
    );
  }

  // Ouvre le sélecteur de fichiers pour choisir une photo de profil.
  Future<void> _pickPhoto() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false);
      if (result != null) {
        setState(() {
          if (kIsWeb) { profilePhotoBytes = result.files.first.bytes; profilePhoto = null; }
          else { profilePhoto = File(result.files.first.path!); profilePhotoBytes = null; }
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur de sélection: $e"), backgroundColor: Colors.red));
    }
  }

  // Logique de validation pour le format de date et l'âge minimum de 16 ans.
  bool _isValidDateLogic(String date) {
    if (!RegExp(r'^\d{2}-\d{2}-\d{4}$').hasMatch(date)) return false;
    try {
      final parts = date.split('-');
      final parsedDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      if (parsedDate.year != int.parse(parts[2]) || parsedDate.month != int.parse(parts[1]) || parsedDate.day != int.parse(parts[0])) return false;
      return !parsedDate.isAfter(DateTime.now().subtract(const Duration(days: 365 * 16)));
    } catch (e) { return false; }
  }

  // Crée le modèle de données utilisateur à partir des informations du formulaire.
  UserCreationModel _createUserModel() {
    String formattedStreetNumber = streetNumberController.text;
    if (postalBoxController.text.isNotEmpty) formattedStreetNumber += "/${postalBoxController.text}";
    return UserCreationModel.fromForm(
      userUuid: userUuid, email: userEmail, isCoiffeuse: isCoiffeuse,
      nom: nameController.text, prenom: surnameController.text, sexe: selectedGender ?? "",
      telephone: phoneController.text, dateNaissance: birthDateController.text,
      codePostal: codePostalController.text, commune: communeController.text,
      rue: streetController.text, numero: formattedStreetNumber, boitePostale: null,
      nomCommercial: isCoiffeuse ? socialNameController.text : null,
      photoProfilFile: profilePhoto, photoProfilBytes: profilePhotoBytes, photoProfilName: 'profile_photo.png',
    );
  }

  // Gère la soumission du profil à l'API.
  void _saveProfile() async {
    showDialog(context: context, barrierDismissible: false, builder: (context) => Center(child: CircularProgressIndicator(color: primaryColor)));
    try {
      final userModel = _createUserModel();
      final firebaseToken = await TokenService.getAuthToken();
      final response = await ProfileApiService.createUserProfile(userModel: userModel, firebaseToken: firebaseToken);
      if (mounted) Navigator.of(context).pop();
      if (!mounted) return;
      if (response.success) {
        _showSuccessDialog();
        final userProvider = Provider.of<CurrentUserProvider>(context, listen: false);
        await userProvider.fetchCurrentUser();
        if (!mounted) return;
        if (isCoiffeuse) {
          if (userProvider.currentUser != null) Navigator.push(context, MaterialPageRoute(builder: (context) => CreateSalonPage(currentUser: userProvider.currentUser!)));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
        }
      } else {
        String errorMessage = response.message;
        if (response.isAuthError) { errorMessage = "Erreur d'authentification. Veuillez vous reconnecter."; await TokenService.clearAuthToken(); }
        else if (response.isValidationError && response.validationErrors != null) { errorMessage = response.validationErrors!.values.join('\n'); }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: Colors.red, duration: const Duration(seconds: 4)));
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur inattendue: $e"), backgroundColor: Colors.red));
      }
    }
  }

  // Affiche une boîte de dialogue de succès après la création du profil.
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [Icon(Icons.check_circle, color: Colors.green, size: 30), SizedBox(width: 10), Text("Profil créé !")]),
        content: const Text("Votre profil a été créé avec succès.", textAlign: TextAlign.center),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("Continuer", style: TextStyle(color: primaryColor)))],
      ),
    );
  }
}














// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:hairbnb/pages/profil/services/profile_creation_api.dart';
// import 'package:http/http.dart' as http;
// import 'package:file_picker/file_picker.dart';
// import 'package:provider/provider.dart';
// import '../../services/firebase_token/token_service.dart';
// import '../../services/providers/current_user_provider.dart';
// import '../home_page.dart';
// import '../salon/create_salon_page.dart';
// import '../../models/user_creation.dart';
// import 'profil_widgets/auto_complete_widget.dart';
// import 'profil_widgets/commune_autofill_widget.dart';
//
//
// class ProfileCreationPage extends StatefulWidget {
//   final String userUuid;
//   final String email;
//
//   const ProfileCreationPage({
//     required this.userUuid,
//     required this.email,
//     super.key,
//   });
//
//   @override
//   State<ProfileCreationPage> createState() => _ProfileCreationPageState();
// }
//
// class _ProfileCreationPageState extends State<ProfileCreationPage> {
//   // Variables pour le thème
//   final Color primaryColor = const Color(0xFF8E44AD); // Couleur violette principale
//   final Color secondaryColor = const Color(0xFFF39C12); // Couleur orange secondaire
//
//   // Clé API pour Geoapify (à garder sécurisée en production)
//   static const String geoapifyApiKey = 'b097f188b11f46d2a02eb55021d168c1';
//
//   // Variables d'état pour les données du profil et le flux de l'interface utilisateur
//   String? selectedGender; // Sexe sélectionné (Homme/Femme)
//   final List<String> genderOptions = ["Homme", "Femme"]; // Options de sexe
//   Uint8List? profilePhotoBytes; // Données binaires de la photo pour le web
//   File? profilePhoto; // Objet fichier pour la photo (mobile/desktop)
//   bool isCoiffeuse = false; // Vrai si le rôle est "Coiffeuse", Faux pour "Client"
//   late String userEmail; // Email de l'utilisateur
//   late String userUuid; // UUID de l'utilisateur Firebase
//   int _currentStep = 0; // Étape actuelle du formulaire (0, 1, 2)
//
//   // Variables d'état pour la validation visuelle des champs d'adresse
//   bool _isStreetSelected = false; // Vrai si une rue a été sélectionnée depuis l'autocomplétion
//   bool _isCommuneValid = false; // Vrai si la commune a été trouvée pour le code postal
//
//   // Map pour suivre l'état de validation de chaque champ (pour l'affichage de l'icône verte)
//   final Map<String, bool> _fieldValidationStatus = {
//     'name': false,
//     'surname': false,
//     'gender': false,
//     'birthDate': false,
//     'phone': false,
//     'codePostal': false,
//     'commune': false, // Géré par _isCommuneValid
//     'street': false,  // Géré par _isStreetSelected
//     'streetNumber': false,
//     'postalBox': true, // Champ optionnel, supposé valide par défaut sauf si invalide
//     'socialName': false, // Pour le profil coiffeuse
//   };
//
//   // Contrôleurs de texte pour les champs du formulaire
//   final TextEditingController nameController = TextEditingController();
//   final TextEditingController surnameController = TextEditingController();
//   final TextEditingController codePostalController = TextEditingController();
//   final TextEditingController communeController = TextEditingController();
//   final TextEditingController streetController = TextEditingController();
//   final TextEditingController streetNumberController = TextEditingController();
//   final TextEditingController postalBoxController = TextEditingController();
//   final TextEditingController phoneController = TextEditingController();
//   final TextEditingController socialNameController = TextEditingController();
//   final TextEditingController birthDateController = TextEditingController();
//
//   // Clé globale pour le formulaire, utilisée pour la validation
//   final _formKey = GlobalKey<FormState>();
//
//   @override
//   void initState() {
//     super.initState();
//     userEmail = widget.email;
//     userUuid = widget.userUuid;
//
//     // Ajouter des écouteurs aux contrôleurs de texte pour mettre à jour l'état de validation en temps réel
//     nameController.addListener(() => _validateField('name', nameController.text));
//     surnameController.addListener(() => _validateField('surname', surnameController.text));
//     phoneController.addListener(() => _validateField('phone', phoneController.text));
//     birthDateController.addListener(() => _validateField('birthDate', birthDateController.text));
//     codePostalController.addListener(() => _validateField('codePostal', codePostalController.text));
//     streetNumberController.addListener(() => _validateField('streetNumber', streetNumberController.text));
//     postalBoxController.addListener(() => _validateField('postalBox', postalBoxController.text));
//     socialNameController.addListener(() => _validateField('socialName', socialNameController.text));
//
//     // Initialiser l'état de validation du sexe et de la rue
//     if (selectedGender != null && selectedGender!.isNotEmpty) {
//       _fieldValidationStatus['gender'] = true;
//     }
//     _fieldValidationStatus['street'] = _isStreetSelected; // Synchroniser avec la sélection de rue
//     _fieldValidationStatus['commune'] = _isCommuneValid; // Synchroniser avec la validation de commune
//   }
//
//   @override
//   void dispose() {
//     // Retirer les écouteurs pour éviter les fuites de mémoire
//     nameController.removeListener(() => _validateField('name', nameController.text));
//     surnameController.removeListener(() => _validateField('surname', surnameController.text));
//     phoneController.removeListener(() => _validateField('phone', phoneController.text));
//     birthDateController.removeListener(() => _validateField('birthDate', birthDateController.text));
//     codePostalController.removeListener(() => _validateField('codePostal', codePostalController.text));
//     streetNumberController.removeListener(() => _validateField('streetNumber', streetNumberController.text));
//     postalBoxController.removeListener(() => _validateField('postalBox', postalBoxController.text));
//     socialNameController.removeListener(() => _validateField('socialName', socialNameController.text));
//
//     // Libérer les contrôleurs
//     nameController.dispose();
//     surnameController.dispose();
//     codePostalController.dispose();
//     communeController.dispose();
//     streetController.dispose();
//     streetNumberController.dispose();
//     postalBoxController.dispose();
//     phoneController.dispose();
//     socialNameController.dispose();
//     birthDateController.dispose();
//     super.dispose();
//   }
//
//   // Méthode générique pour mettre à jour l'état de validation et déclencher un rafraîchissement de l'UI
//   void _validateField(String fieldName, String? value) {
//     String? error; // Variable pour stocker le message d'erreur
//     switch (fieldName) {
//       case 'name':
//         error = _validateNameSurname(value, 'nom');
//         break;
//       case 'surname':
//         error = _validateNameSurname(value, 'prénom');
//         break;
//       case 'phone':
//         error = _validatePhone(value);
//         break;
//       case 'birthDate':
//         error = _validateBirthDate(value);
//         break;
//       case 'codePostal':
//       // La validation visuelle du code postal est liée à celle de la commune.
//       // Le validateur du champ TextForm_Field s'occupera d'afficher le message si on appuie sur Suivant.
//         error = (value == null || value.isEmpty || value.length < 4) ? 'Code postal requis' : null;
//         break;
//       case 'streetNumber':
//         error = _validateStreetNumber(value);
//         break;
//       case 'postalBox':
//         error = _validatePostalBox(value);
//         break;
//       case 'socialName':
//         error = (value == null || value.isEmpty) ? 'Nom commercial requis' : null;
//         break;
//     }
//     // Mettre à jour l'état de validation dans la map et forcer un rafraîchissement de l'UI.
//     setState(() {
//       _fieldValidationStatus[fieldName] = error == null;
//     });
//   }
//
//   // --- Méthodes de validation individuelles (retournent un message d'erreur ou null) ---
//
//   String? _validateNameSurname(String? value, String fieldLabel) {
//     if (value == null || value.isEmpty) {
//       return 'Veuillez entrer votre $fieldLabel';
//     }
//     // Regex pour autoriser uniquement les lettres, apostrophes, tirets et espaces.
//     if (!RegExp(r"^[a-zA-Zà-öø-ÿ' -]+$").hasMatch(value)) {
//       return 'Le $fieldLabel ne peut contenir que des lettres, apostrophes, tirets et espaces.';
//     }
//     return null; // Pas d'erreur
//   }
//
//   String? _validatePhone(String? value) {
//     if (value == null || value.isEmpty) {
//       return 'Veuillez entrer votre numéro de téléphone';
//     }
//     // Regex pour les numéros de téléphone belges : commence par 0, suivi de 8 ou 9 chiffres.
//     // Accepte les espaces, points ou tirets comme séparateurs.
//     // Exemples: 0471 23 45 67, 02.123.45.67, 0471-234567, 0471234567
//     if (!RegExp(r"^0\d{1,}(\s*\d{2}){3}\s*\d{2}$|^0\d{8}$|^0\d{9}$").hasMatch(value.replaceAll(RegExp(r'[ .\-]'), ''))) {
//       return 'Numéro de téléphone belge invalide (doit commencer par 0 et avoir 9 ou 10 chiffres)';
//     }
//     return null; // Pas d'erreur
//   }
//
//   String? _validateBirthDate(String? value) {
//     if (value == null || value.isEmpty) {
//       return 'Veuillez entrer votre date de naissance';
//     }
//     if (!_isValidDateLogic(value)) {
//       return 'Format invalide (JJ-MM-AAAA) ou vous devez avoir au moins 16 ans.';
//     }
//     return null; // Pas d'erreur
//   }
//
//   String? _validateStreetNumber(String? value) {
//     if (value == null || value.isEmpty) {
//       return 'Obligatoire';
//     }
//     // Autoriser les chiffres et optionnellement une lettre (ex: "12", "12A")
//     if (!RegExp(r"^[0-9]+[a-zA-Z]?$").hasMatch(value)) {
//       return 'Numéro invalide (ex: 12, 12A)';
//     }
//     return null; // Pas d'erreur
//   }
//
//   String? _validatePostalBox(String? value) {
//     // Ce champ est optionnel, donc on ne valide que s'il n'est pas vide.
//     if (value != null && value.isNotEmpty) {
//       // Autoriser les chiffres et les lettres pour la boîte postale (ex: "B", "10")
//       if (!RegExp(r"^[a-zA-Z0-9]+$").hasMatch(value)) {
//         return 'Boîte invalide (ex: B, 10)';
//       }
//     }
//     return null; // Pas d'erreur
//   }
//
//   // --- Fin des méthodes de validation ---
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: CustomScrollView(
//           slivers: [
//             _buildAppBar(), // En-tête de l'application
//             SliverToBoxAdapter(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                 child: Form(
//                   key: _formKey, // Clé du formulaire pour la validation
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.stretch,
//                     children: [
//                       _buildProfilePhoto(), // Widget de sélection de photo de profil
//                       const SizedBox(height: 16),
//                       // Afficher le sélecteur de rôle SEULEMENT à l'étape 0
//                       if (_currentStep == 0) ...[
//                         _buildRoleSelector(), // Sélecteur de rôle (Client/Coiffeuse)
//                         const SizedBox(height: 24),
//                       ],
//                       _buildStepIndicator(), // Indicateur de progression des étapes
//                       const SizedBox(height: 20),
//                       _buildCurrentStep(), // Contenu de l'étape actuelle
//                       const SizedBox(height: 20),
//                       _buildNavigationButtons(), // Boutons de navigation (Précédent/Suivant/Enregistrer)
//                       const SizedBox(height: 40),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // En-tête de l'application avec une apparence moderne
//   Widget _buildAppBar() {
//     return SliverAppBar(
//       expandedHeight: 120,
//       floating: true,
//       pinned: true,
//       flexibleSpace: FlexibleSpaceBar(
//         title: const Text(
//           "Créer votre profil",
//           style: TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         background: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [primaryColor, primaryColor.withOpacity(0.7)],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   // Widget pour l'affichage et la sélection de la photo de profil
//   Widget _buildProfilePhoto() {
//     return Center(
//       child: Column(
//         children: [
//           const SizedBox(height: 20),
//           GestureDetector(
//             onTap: _pickPhoto, // Appeler la fonction de sélection de photo au tap
//             child: Stack(
//               alignment: Alignment.bottomRight,
//               children: [
//                 Container(
//                   width: 120,
//                   height: 120,
//                   decoration: BoxDecoration(
//                     color: Colors.grey[200],
//                     shape: BoxShape.circle,
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.1),
//                         blurRadius: 10,
//                         spreadRadius: 1,
//                       ),
//                     ],
//                   ),
//                   child: ClipOval( // Pour arrondir l'image
//                     child: profilePhotoBytes != null
//                         ? Image.memory(
//                       profilePhotoBytes!, // Afficher l'image à partir des bytes (pour le web)
//                       fit: BoxFit.cover,
//                     )
//                         : profilePhoto != null
//                         ? Image.file(
//                       profilePhoto!, // Afficher l'image à partir du fichier (pour mobile/desktop)
//                       fit: BoxFit.cover,
//                     )
//                         : Icon(
//                       Icons.person, // Icône par défaut si pas de photo
//                       size: 70,
//                       color: Colors.grey[400],
//                     ),
//                   ),
//                 ),
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: secondaryColor,
//                     shape: BoxShape.circle,
//                   ),
//                   child: const Icon(
//                     Icons.camera_alt, // Icône de caméra
//                     color: Colors.white,
//                     size: 20,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             "Photo de profil",
//             style: TextStyle(
//               color: Colors.grey[600],
//               fontSize: 14,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // Sélecteur de rôle (Client/Coiffeuse) avec design moderne
//   Widget _buildRoleSelector() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             spreadRadius: 1,
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           const Text(
//             "Je suis :",
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               fontSize: 16,
//             ),
//           ),
//           Row(
//             children: [
//               Text(
//                 "Client",
//                 style: TextStyle(
//                   color: !isCoiffeuse ? primaryColor : Colors.grey,
//                   fontWeight: !isCoiffeuse ? FontWeight.bold : FontWeight.normal,
//                 ),
//               ),
//               Switch(
//                 value: isCoiffeuse,
//                 onChanged: (value) {
//                   setState(() {
//                     isCoiffeuse = value; // Basculer le rôle
//                   });
//                 },
//                 activeColor: secondaryColor,
//                 activeTrackColor: secondaryColor.withOpacity(0.5),
//               ),
//               Text(
//                 "Coiffeuse",
//                 style: TextStyle(
//                   color: isCoiffeuse ? primaryColor : Colors.grey,
//                   fontWeight: isCoiffeuse ? FontWeight.bold : FontWeight.normal,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   // Indicateur de progression des étapes
//   Widget _buildStepIndicator() {
//     final int totalSteps = isCoiffeuse ? 3 : 2; // 3 étapes pour coiffeuse, 2 pour client
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: Row(
//         children: List.generate(totalSteps, (index) {
//           return Expanded(
//             child: Container(
//               height: 4,
//               margin: const EdgeInsets.symmetric(horizontal: 4),
//               decoration: BoxDecoration(
//                 color: index <= _currentStep ? primaryColor : Colors.grey[300], // Couleur de la progression
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//           );
//         }),
//       ),
//     );
//   }
//
//   // Affiche l'étape actuelle du formulaire
//   Widget _buildCurrentStep() {
//     switch (_currentStep) {
//       case 0:
//         return _buildPersonalInfoStep(); // Étape Informations personnelles
//       case 1:
//         return _buildAddressStep(); // Étape Adresse
//       case 2:
//         return isCoiffeuse ? _buildProfessionalInfoStep() : _buildPersonalInfoStep(); // Étape Pro ou retour aux infos perso
//       default:
//         return _buildPersonalInfoStep();
//     }
//   }
//
//   // Étape 1 : Informations personnelles
//   Widget _buildPersonalInfoStep() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           "Informations personnelles",
//           style: TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//             color: primaryColor,
//           ),
//         ),
//         const SizedBox(height: 20),
//         _buildInputField(
//           label: "Nom",
//           controller: nameController,
//           icon: Icons.person_outline,
//           fieldName: 'name', // Identifiant unique pour le champ
//           validator: (value) => _validateNameSurname(value, 'nom'), // Utiliser la méthode de validation dédiée
//         ),
//         const SizedBox(height: 16),
//         _buildInputField(
//           label: "Prénom",
//           controller: surnameController,
//           icon: Icons.person_outline,
//           fieldName: 'surname', // Identifiant unique pour le champ
//           validator: (value) => _validateNameSurname(value, 'prénom'), // Utiliser la méthode de validation dédiée
//         ),
//         const SizedBox(height: 16),
//         _buildGenderDropdown(), // Champ de sélection du sexe
//         const SizedBox(height: 16),
//         _buildDatePicker(), // Champ de sélection de la date de naissance
//         const SizedBox(height: 16),
//         _buildInputField(
//           label: "Téléphone",
//           controller: phoneController,
//           icon: Icons.phone,
//           keyboardType: TextInputType.phone,
//           fieldName: 'phone', // Identifiant unique pour le champ
//           validator: _validatePhone, // Utiliser la méthode de validation dédiée
//         ),
//       ],
//     );
//   }
//
//   // Étape 2 : Adresse
//   Widget _buildAddressStep() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           "Adresse",
//           style: TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//             color: primaryColor,
//           ),
//         ),
//         const SizedBox(height: 20),
//         // Champ Code Postal avec CommuneAutoFill et icône de validation
//         Stack(
//           alignment: Alignment.centerRight,
//           children: [
//             CommuneAutoFill(
//               codePostalController: codePostalController,
//               communeController: communeController,
//               geoapifyApiKey: geoapifyApiKey,
//               onCommuneFound: () {
//                 setState(() {
//                   _isCommuneValid = true;
//                   _fieldValidationStatus['commune'] = true; // Mettre à jour l'état de validation de la commune
//                   _fieldValidationStatus['codePostal'] = true; // Mettre à jour l'état de validation du code postal
//                 });
//               },
//               onCommuneNotFound: () {
//                 setState(() {
//                   _isCommuneValid = false;
//                   _fieldValidationStatus['commune'] = false; // Mettre à jour l'état de validation de la commune
//                   _fieldValidationStatus['codePostal'] = false; // Mettre à jour l'état de validation du code postal
//                 });
//               },
//             ),
//             // Afficher l'icône verte si le code postal est valide et la commune trouvée
//             if (_fieldValidationStatus['codePostal'] == true && _isCommuneValid)
//               Padding(
//                 padding: const EdgeInsets.only(right: 12.0),
//                 child: Icon(Icons.check_circle, color: Colors.green[700], size: 24),
//               ),
//           ],
//         ),
//         const SizedBox(height: 16),
//         // Champ Commune (lecture seule, rempli par CommuneAutoFill)
//         _buildInputField(
//           label: "Commune",
//           controller: communeController,
//           icon: Icons.location_city,
//           readOnly: true,
//           fieldName: 'commune', // Identifiant unique pour le champ
//           validator: (value) {
//             // Le validateur s'assure que la commune est valide si l'utilisateur appuie sur "Suivant"
//             if (value == null || value.isEmpty || value == "Commune introuvable" || value == "Erreur de recherche" || value == "Erreur réseau") {
//               return 'Veuillez entrer un code postal valide pour obtenir la commune.';
//             }
//             return null;
//           },
//         ),
//         const SizedBox(height: 16),
//         // Champ Rue avec StreetAutocomplete et icône de validation
//         Stack(
//           alignment: Alignment.centerRight,
//           children: [
//             StreetAutocomplete(
//               streetController: streetController,
//               communeController: communeController,
//               codePostalController: codePostalController,
//               geoapifyApiKey: geoapifyApiKey,
//               onStreetSelected: () {
//                 setState(() {
//                   _isStreetSelected = true; // Marquer la rue comme sélectionnée
//                   _fieldValidationStatus['street'] = true; // Mettre à jour l'état de validation de la rue
//                 });
//               },
//               onStreetChanged: () {
//                 setState(() {
//                   _isStreetSelected = false; // Réinitialiser si l'utilisateur tape manuellement
//                   _fieldValidationStatus['street'] = false; // Réinitialiser l'état de validation de la rue
//                 });
//               },
//             ),
//             // Afficher l'icône verte si une rue a été sélectionnée depuis l'autocomplétion
//             if (_fieldValidationStatus['street'] == true)
//               Padding(
//                 padding: const EdgeInsets.only(right: 12.0),
//                 child: Icon(Icons.check_circle, color: Colors.green[700], size: 24),
//               ),
//           ],
//         ),
//         const SizedBox(height: 16),
//         // Champs Numéro et Boîte sur la même ligne
//         Row(
//           children: [
//             Expanded(
//               child: _buildInputField(
//                 label: "Numéro",
//                 controller: streetNumberController,
//                 icon: Icons.home,
//                 fieldName: 'streetNumber', // Identifiant unique pour le champ
//                 validator: _validateStreetNumber, // Utiliser la méthode de validation dédiée
//               ),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: _buildInputField(
//                 label: "Boîte",
//                 controller: postalBoxController,
//                 icon: Icons.inbox,
//                 fieldName: 'postalBox', // Identifiant unique pour le champ
//                 validator: _validatePostalBox, // Utiliser la méthode de validation dédiée
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
//
//   // Étape 3 : Informations professionnelles (pour les coiffeuses)
//   Widget _buildProfessionalInfoStep() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           "Informations professionnelles",
//           style: TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//             color: primaryColor,
//           ),
//         ),
//         const SizedBox(height: 20),
//         _buildInputField(
//           label: "Nom Commercial",
//           controller: socialNameController,
//           icon: Icons.business,
//           fieldName: 'socialName', // Identifiant unique pour le champ
//           validator: (value) {
//             if (value == null || value.isEmpty) {
//               return 'Veuillez entrer votre nom commercial';
//             }
//             return null;
//           },
//         ),
//       ],
//     );
//   }
//
//   // Champ de saisie stylisé avec validation et affichage d'icône de validation
//   Widget _buildInputField({
//     required String label,
//     required TextEditingController controller,
//     required IconData icon,
//     bool readOnly = false,
//     TextInputType keyboardType = TextInputType.text,
//     Function(String)? onChanged,
//     String? Function(String?)? validator,
//     required String fieldName, // Identifiant unique pour le champ (ex: 'name', 'phone')
//   }) {
//     // Déterminer si le champ est actuellement valide pour afficher l'icône verte
//     bool isValid = _fieldValidationStatus[fieldName] ?? false;
//
//     return TextFormField(
//       controller: controller,
//       readOnly: readOnly,
//       keyboardType: keyboardType,
//       onChanged: (text) {
//         onChanged?.call(text); // Appeler le callback onChanged fourni s'il existe
//         _validateField(fieldName, text); // Déclencher la mise à jour de l'état de validation pour l'icône
//       },
//       validator: (value) {
//         // Ce validateur est appelé par Form.validate().
//         // Il retourne le message d'erreur. Les messages d'erreur ne sont visibles qu'après Form.validate().
//         final error = validator?.call(value);
//         // Mettre à jour l'état interne pour l'icône, mais sans afficher le texte d'erreur ici.
//         // Utiliser addPostFrameCallback pour éviter les changements d'état pendant la construction du widget.
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           if (mounted) {
//             setState(() {
//               _fieldValidationStatus[fieldName] = error == null;
//             });
//           }
//         });
//         return error; // Retourner l'erreur pour que Form.validate() fonctionne comme prévu
//       },
//       decoration: InputDecoration(
//         labelText: label,
//         prefixIcon: Icon(icon, color: primaryColor),
//         // Afficher l'icône de succès si le champ est valide, non vide et non en lecture seule
//         suffixIcon: isValid && controller.text.isNotEmpty && !readOnly
//             ? Icon(Icons.check_circle, color: Colors.green[700], size: 24)
//             : null,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: Colors.grey[300]!),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: Colors.grey[300]!),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: primaryColor, width: 2),
//         ),
//         filled: true,
//         fillColor: Colors.white,
//         contentPadding: const EdgeInsets.symmetric(vertical: 16),
//       ),
//     );
//   }
//
//   // Menu déroulant stylisé pour le genre avec icône de validation
//   Widget _buildGenderDropdown() {
//     return DropdownButtonFormField<String>(
//       value: selectedGender,
//       decoration: InputDecoration(
//         labelText: "Sexe",
//         prefixIcon: Icon(Icons.person, color: primaryColor),
//         // Afficher l'icône de succès si le genre est sélectionné et valide
//         suffixIcon: (_fieldValidationStatus['gender'] ?? false)
//             ? Icon(Icons.check_circle, color: Colors.green[700], size: 24)
//             : null,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: Colors.grey[300]!),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: Colors.grey[300]!),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: primaryColor, width: 2),
//         ),
//         filled: true,
//         fillColor: Colors.white,
//         contentPadding: const EdgeInsets.symmetric(vertical: 16),
//       ),
//       items: genderOptions
//           .map((gender) => DropdownMenuItem(
//         value: gender,
//         child: Text(gender),
//       ))
//           .toList(),
//       onChanged: (value) {
//         setState(() {
//           selectedGender = value;
//           // Mettre à jour l'état de validation du genre
//           _fieldValidationStatus['gender'] = (value != null && value.isNotEmpty);
//         });
//       },
//       validator: (value) {
//         final error = (value == null || value.isEmpty) ? 'Veuillez sélectionner votre genre' : null;
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           if (mounted) {
//             setState(() {
//               _fieldValidationStatus['gender'] = error == null;
//             });
//           }
//         });
//         return error;
//       },
//     );
//   }
//
//   // Sélecteur de date stylisé avec icône de validation
//   Widget _buildDatePicker() {
//     return GestureDetector(
//       onTap: () async {
//         final selectedDate = await showDatePicker(
//           context: context,
//           initialDate: DateTime.now().subtract(const Duration(days: 365 * 16)), // Date initiale pour 16 ans
//           firstDate: DateTime(1900), // Date la plus ancienne
//           lastDate: DateTime.now(), // Date la plus récente
//           builder: (context, child) {
//             return Theme(
//               data: Theme.of(context).copyWith(
//                 colorScheme: ColorScheme.light(
//                   primary: primaryColor,
//                   onPrimary: Colors.white,
//                   onSurface: Colors.black,
//                 ),
//               ),
//               child: child!,
//             );
//           },
//         );
//         if (selectedDate != null) {
//           setState(() {
//             birthDateController.text =
//             "${selectedDate.day.toString().padLeft(2, '0')}-"
//                 "${selectedDate.month.toString().padLeft(2, '0')}-"
//                 "${selectedDate.year}";
//             _validateField('birthDate', birthDateController.text); // Déclencher la validation pour l'icône
//           });
//         }
//       },
//       child: AbsorbPointer( // Empêcher l'édition manuelle du champ
//         child: TextFormField(
//           controller: birthDateController,
//           decoration: InputDecoration(
//             labelText: "Date de naissance",
//             prefixIcon: Icon(Icons.calendar_today, color: primaryColor),
//             // Afficher l'icône de succès si la date de naissance est valide
//             suffixIcon: (_fieldValidationStatus['birthDate'] ?? false)
//                 ? Icon(Icons.check_circle, color: Colors.green[700], size: 24)
//                 : null,
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
//               borderSide: BorderSide(color: primaryColor, width: 2),
//             ),
//             filled: true,
//             fillColor: Colors.white,
//             contentPadding: const EdgeInsets.symmetric(vertical: 16),
//           ),
//           validator: (value) {
//             final error = _validateBirthDate(value);
//             WidgetsBinding.instance.addPostFrameCallback((_) {
//               if (mounted) {
//                 setState(() {
//                   _fieldValidationStatus['birthDate'] = error == null;
//                 });
//               }
//             });
//             return error;
//           },
//         ),
//       ),
//     );
//   }
//
//   // Boutons de navigation (Précédent, Suivant, Enregistrer)
//   Widget _buildNavigationButtons() {
//     final int totalSteps = isCoiffeuse ? 3 : 2; // Nombre total d'étapes
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         _currentStep > 0
//             ? ElevatedButton.icon(
//           icon: const Icon(Icons.arrow_back),
//           label: const Text("Précédent"),
//           onPressed: () {
//             setState(() {
//               _currentStep--; // Revenir à l'étape précédente
//             });
//           },
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.grey[200],
//             foregroundColor: Colors.black87,
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//           ),
//         )
//             : const SizedBox(width: 120), // Espace vide si c'est la première étape
//         _currentStep < totalSteps - 1
//             ? ElevatedButton.icon(
//           icon: const Icon(Icons.arrow_forward),
//           label: const Text("Suivant"),
//           onPressed: () {
//             // Déclencher la validation complète du formulaire de l'étape actuelle
//             if (_formKey.currentState?.validate() == true) {
//               // Vérifications manuelles pour les widgets qui n'utilisent pas TextFormField directement
//               if (_currentStep == 1) { // Si on est à l'étape d'adresse
//                 if (!_isStreetSelected) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text("Veuillez sélectionner une rue de la liste des suggestions.")),
//                   );
//                   return; // Arrêter si la rue n'est pas sélectionnée
//                 }
//                 if (!_isCommuneValid) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text("Veuillez entrer un code postal valide pour obtenir la commune.")),
//                   );
//                   return; // Arrêter si la commune n'est pas valide
//                 }
//               }
//
//               setState(() {
//                 _currentStep++; // Passer à l'étape suivante
//               });
//             }
//           },
//           style: ElevatedButton.styleFrom(
//             backgroundColor: primaryColor,
//             foregroundColor: Colors.white,
//             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//           ),
//         )
//             : ElevatedButton.icon(
//           icon: const Icon(Icons.check),
//           label: const Text("Enregistrer"),
//           onPressed: () {
//             // Déclencher la validation complète du formulaire
//             if (_formKey.currentState?.validate() == true) {
//               // Vérifications manuelles pour les widgets qui n'utilisent pas TextFormField directement
//               if (_currentStep == 1) { // Si on est à l'étape d'adresse
//                 if (!_isStreetSelected) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text("Veuillez sélectionner une rue de la liste des suggestions.")),
//                   );
//                   return;
//                 }
//                 if (!_isCommuneValid) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text("Veuillez entrer un code postal valide pour obtenir la commune.")),
//                   );
//                   return;
//                 }
//               }
//               _saveProfile(); // Appeler la fonction de sauvegarde du profil
//             }
//           },
//           style: ElevatedButton.styleFrom(
//             backgroundColor: secondaryColor,
//             foregroundColor: Colors.white,
//             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   // Méthode pour sélectionner une photo de profil
//   Future<void> _pickPhoto() async {
//     try {
//       final result = await FilePicker.platform.pickFiles(
//         type: FileType.image, // Autoriser uniquement les fichiers image
//         allowMultiple: false, // Ne pas autoriser la sélection multiple
//       );
//
//       if (result != null) {
//         setState(() {
//           if (kIsWeb) {
//             profilePhotoBytes = result.files.first.bytes; // Pour le web, utiliser les bytes
//             profilePhoto = null;
//           } else {
//             profilePhoto = File(result.files.first.path!); // Pour mobile/desktop, utiliser le chemin du fichier
//             profilePhotoBytes = null;
//           }
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Erreur lors de la sélection de la photo: $e"),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }
//
//   // Logique de validation de la date de naissance et de l'âge (minimum 16 ans)
//   bool _isValidDateLogic(String date) {
//     final regex = RegExp(r'^\d{2}-\d{2}-\d{4}$'); // Regex pour le format JJ-MM-AAAA
//     if (!regex.hasMatch(date)) return false; // Si le format ne correspond pas, c'est invalide
//
//     try {
//       final parts = date.split('-');
//       final day = int.parse(parts[0]);
//       final month = int.parse(parts[1]);
//       final year = int.parse(parts[2]);
//       final parsedDate = DateTime(year, month, day);
//
//       // Vérifier si la date parsée est une date de calendrier valide (ex: pas 31 février)
//       if (parsedDate.year != year || parsedDate.month != month || parsedDate.day != day) {
//         return false;
//       }
//
//       // Vérifier si la personne a au moins 16 ans
//       final sixteenYearsAgo = DateTime.now().subtract(const Duration(days: 365 * 16));
//       return parsedDate.isBefore(sixteenYearsAgo) || parsedDate.isAtSameMomentAs(sixteenYearsAgo);
//     } catch (e) {
//       return false; // En cas d'erreur de parsing ou autre
//     }
//   }
//
//   // Créer le modèle utilisateur à partir des données du formulaire
//   UserCreationModel _createUserModel() {
//     String formattedStreetNumber = streetNumberController.text;
//     // Si la boîte postale est présente, l'ajouter au numéro de rue
//     if (postalBoxController.text.isNotEmpty) {
//       formattedStreetNumber += "/${postalBoxController.text}";
//     }
//
//     return UserCreationModel.fromForm(
//       userUuid: userUuid,
//       email: userEmail,
//       isCoiffeuse: isCoiffeuse,
//       nom: nameController.text,
//       prenom: surnameController.text,
//       sexe: selectedGender ?? "", // Passer la valeur exacte (ex: "Homme")
//       telephone: phoneController.text,
//       dateNaissance: birthDateController.text,
//       codePostal: codePostalController.text,
//       commune: communeController.text,
//       rue: streetController.text,
//       numero: formattedStreetNumber, // Utiliser le numéro de rue formaté (incluant la boîte si nécessaire)
//       boitePostale: null, // Ce champ est maintenant intégré dans 'numero'
//       nomCommercial: isCoiffeuse ? socialNameController.text : null, // Nom commercial si coiffeuse
//       photoProfilFile: profilePhoto,
//       photoProfilBytes: profilePhotoBytes,
//       photoProfilName: 'profile_photo.png',
//     );
//   }
//
//   // Sauvegarde du profil via l'API
//   void _saveProfile() async {
//     // Afficher un indicateur de chargement
//     showDialog(
//       context: context,
//       barrierDismissible: false, // Empêcher de fermer la boîte de dialogue en tapant à l'extérieur
//       builder: (context) => Center(
//         child: CircularProgressIndicator(
//           color: primaryColor,
//         ),
//       ),
//     );
//
//     try {
//       // Créer le modèle utilisateur avec les données du formulaire
//       final userModel = _createUserModel();
//
//       // --- DÉBUT DES LOGS DÉTAILLÉS (pour le débogage) ---
//       if (kDebugMode) {
//         print("--- Données du UserCreationModel avant envoi ---");
//         print("userUuid: ${userModel.userUuid}");
//         print("email: ${userModel.email}");
//         print("type: ${userModel.type}");
//         print("nom: ${userModel.nom}");
//         print("prenom: ${userModel.prenom}");
//         print("sexe: ${userModel.sexe}");
//         print("telephone: ${userModel.telephone}");
//         print("dateNaissance: ${userModel.dateNaissance}");
//         print("codePostal: ${userModel.codePostal}");
//         print("commune: ${userModel.commune}");
//         print("rue: ${userModel.rue}");
//         print("numero: ${userModel.numero}");
//         print("boitePostale: ${userModel.boitePostale}");
//         print("nomCommercial: ${userModel.nomCommercial}");
//         print("photoProfilFile present: ${userModel.photoProfilFile != null}");
//         print("photoProfilBytes present: ${userModel.photoProfilBytes != null}");
//         print("photoProfilName: ${userModel.photoProfilName}");
//         print("--- Fin des données du UserCreationModel ---");
//
//         print("--- Champs envoyés à l'API (via toApiFields()) ---");
//         userModel.toApiFields().forEach((key, value) {
//           print("$key: $value");
//         });
//         print("--- Fin des champs envoyés ---");
//
//         final String requestUrl = "${ProfileApiService.baseUrl}/create-profile/";
//         print("URL de la requête POST: $requestUrl");
//       }
//       // --- FIN DES LOGS DÉTAILLÉS ---
//
//       // Récupérer le token Firebase via TokenService pour l'authentification API
//       String? firebaseToken;
//       try {
//         firebaseToken = await TokenService.getAuthToken();
//         if (kDebugMode) {
//           print("🔍 Token Firebase récupéré: ${firebaseToken != null ? 'Oui' : 'Non'}");
//         }
//       } catch (e) {
//         if (kDebugMode) {
//           print("❌ Erreur récupération token Firebase: $e");
//         }
//       }
//
//       // Appeler l'API via le service ProfileApiService
//       final response = await ProfileApiService.createUserProfile(
//         userModel: userModel,
//         firebaseToken: firebaseToken,
//       );
//
//       // Fermer la boîte de dialogue de chargement
//       if (mounted) Navigator.of(context).pop();
//
//       if (!mounted) return; // S'assurer que le widget est toujours monté avant de continuer
//
//       if (response.success) {
//         // Afficher l'animation de succès
//         _showSuccessDialog();
//
//         // Mettre à jour les informations de l'utilisateur courant via le fournisseur
//         final userProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//         await userProvider.fetchCurrentUser();
//
//         if (!mounted) return;
//
//         // Redirection en fonction du rôle de l'utilisateur
//         if (isCoiffeuse) {
//           // Rediriger vers la création de salon pour les coiffeuses
//           if (userProvider.currentUser != null) {
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (context) => CreateSalonPage(currentUser: userProvider.currentUser!)),
//             );
//           }
//         } else {
//           // Rediriger vers la page d'accueil pour les clients
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (_) => const HomePage()),
//           );
//         }
//       } else {
//         // Gestion des erreurs de l'API
//         String errorMessage = response.message;
//
//         if (response.isAuthError) {
//           errorMessage = "Erreur d'authentification. Veuillez vous reconnecter.";
//           await TokenService.clearAuthToken(); // Nettoyer le token en cas d'erreur d'auth
//         } else if (response.isValidationError && response.validationErrors != null) {
//           // Afficher les erreurs de validation spécifiques du backend
//           errorMessage = response.validationErrors!.values.join('\n');
//         }
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(errorMessage),
//             backgroundColor: Colors.red,
//             duration: const Duration(seconds: 4),
//           ),
//         );
//       }
//     } catch (e) {
//       // Gérer les erreurs inattendues (ex: problèmes réseau)
//       if (mounted) {
//         // Fermer la boîte de dialogue de chargement
//         Navigator.of(context).pop();
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Erreur inattendue: $e"),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }
//
//   // Boîte de dialogue de succès après la création du profil
//   void _showSuccessDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(20),
//         ),
//         title: Row(
//           children: [
//             Icon(Icons.check_circle, color: Colors.green, size: 30), // Icône de succès
//             const SizedBox(width: 10),
//             const Text("Profil créé !"),
//           ],
//         ),
//         content: const Text(
//           "Votre profil a été créé avec succès.",
//           textAlign: TextAlign.center,
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context), // Fermer la boîte de dialogue
//             child: Text(
//               "Continuer",
//               style: TextStyle(color: primaryColor),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
