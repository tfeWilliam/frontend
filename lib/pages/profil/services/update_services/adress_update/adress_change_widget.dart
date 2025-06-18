////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                WIDGET POUR LA MODIFICATION D'UNE ADRESSE                     //
//                                                                            //
//  Ce fichier définit `AddressChangeWidget`, un composant `StatefulWidget`   //
//  conçu pour être affiché, probablement dans une boîte de dialogue, afin de //
//  permettre à un utilisateur de modifier son adresse.                       //
//                                                                            //
//  Fonctionnalités Clés :                                                    //
//  - Formulaire complet pour la saisie de l'adresse (numéro, rue, etc.).     //
//  - Intégration de widgets d'autocomplétion pour la rue et la commune/code  //
//    postal, améliorant l'expérience utilisateur.                            //
//  - Processus en deux étapes : d'abord la validation de l'adresse via un    //
//    service externe, puis la sauvegarde des nouvelles informations.         //
//  - Gestion d'état interne pour la validation et les indicateurs de         //
//    chargement.                                                             //
//  - Utilisation d'alias pour les imports de modèles afin d'éviter les       //
//    conflits de noms.                                                       //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;

import 'package:flutter/material.dart';
// Utilisation d'alias pour les modèles afin d'éviter les ambiguïtés de noms.
import 'package:hairbnb/models/current_user.dart' as UserModel;
import 'package:hairbnb/models/adresse.dart' as AdresseModel;
import 'package:hairbnb/pages/profil/services/update_services/adress_update/adress_update_service.dart';
import 'package:hairbnb/pages/profil/services/update_services/adress_update/adress_validation.dart';

import '../../../profil_widgets/auto_complete_widget.dart';
import '../../../profil_widgets/commune_autofill_widget.dart';

/// Un widget `Stateful` qui encapsule le formulaire et la logique
/// pour modifier l'adresse d'un utilisateur.
class AddressChangeWidget extends StatefulWidget {
  /// L'objet de l'utilisateur actuellement connecté.
  final UserModel.CurrentUser currentUser;
  /// L'adresse actuelle de l'utilisateur, peut être nulle.
  final UserModel.Adresse? currentAddress;
  /// Une fonction de callback pour contrôler l'état de chargement dans le widget parent.
  final Function(bool) setLoadingState;
  /// Les couleurs thématiques passées depuis le parent pour une UI cohérente.
  final Color primaryColor;
  final Color successColor;
  final Color errorColor;

  /// Constructeur du widget de modification d'adresse.
  const AddressChangeWidget({
    super.key,
    required this.currentUser,
    this.currentAddress,
    required this.setLoadingState,
    required this.primaryColor,
    required this.successColor,
    required this.errorColor,
  });

  @override
  State<AddressChangeWidget> createState() => _AddressChangeWidgetState();
}

/// La classe d'état pour `AddressChangeWidget`.
/// Gère les contrôleurs de texte, l'état de validation et la logique métier.
class _AddressChangeWidgetState extends State<AddressChangeWidget> {
  //region Déclaration des variables d'état et contrôleurs
  /// Clé globale pour identifier et valider le formulaire.
  final _formKey = GlobalKey<FormState>();

  /// Contrôleurs pour chaque champ du formulaire.
  late TextEditingController _numeroController;
  late TextEditingController _rueController;
  late TextEditingController _communeController;
  late TextEditingController _codePostalController;

  /// `true` si la validation de l'adresse via l'API est en cours.
  bool _isValidating = false;
  /// `true` si l'adresse a été validée avec succès par l'API.
  bool _isAddressValid = false;
  /// Le message de retour de la validation à afficher à l'utilisateur.
  String? _validationMessage;
  /// Les coordonnées GPS obtenues après une validation réussie.
  double? _validatedLatitude;
  double? _validatedLongitude;
  //endregion

  @override
  void initState() {
    super.initState();

    // Initialise les contrôleurs avec les valeurs de l'adresse actuelle, si elle existe.
    _numeroController = TextEditingController(text: widget.currentAddress?.numero?.toString() ?? '');
    _rueController = TextEditingController(text: widget.currentAddress?.rue?.nomRue ?? '');
    _communeController = TextEditingController(text: widget.currentAddress?.rue?.localite?.commune ?? '');
    _codePostalController = TextEditingController(text: widget.currentAddress?.rue?.localite?.codePostal ?? '');

    // Ajoute des listeners pour réinitialiser l'état de validation dès que l'utilisateur
    // modifie l'un des champs, améliorant l'expérience utilisateur.
    _numeroController.addListener(_resetValidation);
    _rueController.addListener(_resetValidation);
    _communeController.addListener(_resetValidation);
    _codePostalController.addListener(_resetValidation);
  }

  @override
  void dispose() {
    // Nettoie tous les contrôleurs pour éviter les fuites de mémoire.
    _numeroController.dispose();
    _rueController.dispose();
    _communeController.dispose();
    _codePostalController.dispose();
    super.dispose();
  }

  //region Logique Métier (Validation et Sauvegarde)
  /// Réinitialise l'état de validation à son état initial.
  /// Appelé lorsque l'utilisateur commence à modifier l'adresse.
  void _resetValidation() {
    if (_isAddressValid) {
      if(mounted) {
        setState(() {
          _isAddressValid = false;
          _validationMessage = null;
          _validatedLatitude = null;
          _validatedLongitude = null;
        });
      }
    }
  }

  /// Valide l'adresse saisie en appelant le `AddressValidationService`.
  Future<void> _validateAddress() async {
    // Vérifie d'abord la validation locale du formulaire (champs requis, etc.).
    if (!_formKey.currentState!.validate()) return;

    if(mounted) {
      setState(() {
        _isValidating = true;
        _validationMessage = null;
      });
    }

    // Crée un objet AdresseModel pour le service de validation.
    final adresse = AdresseModel.Adresse(
      numero: int.tryParse(_numeroController.text),
      rue: AdresseModel.Rue(
        nomRue: _rueController.text,
        localite: AdresseModel.Localite(
          commune: _communeController.text,
          codePostal: _codePostalController.text,
        ),
      ),
    );

    try {
      // Appelle le service externe pour valider l'adresse.
      final result = await AddressValidationService.validateAddress(adresse);

      if(mounted) {
        setState(() {
          _isValidating = false;
          _isAddressValid = result.isValid;

          if (result.isValid) {
            // Si la validation réussit, stocke les coordonnées GPS.
            _validatedLatitude = result.latitude;
            _validatedLongitude = result.longitude;
            _validationMessage = "✅ Adresse validée avec succès";
          } else {
            _validationMessage = "❌ ${result.errorMessage}";
          }
        });
      }
    } catch (e) {
      if(mounted) {
        setState(() {
          _isValidating = false;
          _isAddressValid = false;
          _validationMessage = "❌ Erreur: $e";
        });
      }
    }
  }

  /// Sauvegarde la nouvelle adresse validée en appelant le `AddressUpdateService`.
  Future<void> _saveAddress() async {
    // Ne permet pas la sauvegarde si l'adresse n'a pas été validée au préalable.
    if (!_isAddressValid) {
      _showSnackBar("Veuillez d'abord valider l'adresse", widget.errorColor);
      return;
    }

    // Prépare les données à envoyer à l'API.
    Map<String, dynamic> addressData = {
      'numero': int.tryParse(_numeroController.text),
      'rue': {
        'nomRue': _rueController.text,
        'localite': {'commune': _communeController.text, 'codePostal': _codePostalController.text}
      },
      'latitude': _validatedLatitude, 'longitude': _validatedLongitude,
      'is_validated': true, 'validation_date': DateTime.now().toIso8601String(),
    };

    try {
      widget.setLoadingState(true); // Informe le widget parent que le chargement commence.

      // Appelle le service pour mettre à jour l'adresse.
      await AddressUpdateService.updateUserAddress(
        context,
        widget.currentUser,
        addressData,
        successGreen: widget.successColor,
        errorRed: widget.errorColor,
        setLoadingState: widget.setLoadingState,
      );

      // Ferme la boîte de dialogue et retourne `true` pour indiquer le succès.
      Navigator.of(context).pop(true);
      _showSnackBar("✅ Adresse mise à jour avec succès", widget.successColor);
    } catch (e) {
      _showSnackBar("❌ Erreur: $e", widget.errorColor);
    } finally {
      widget.setLoadingState(false); // S'assure de désactiver le chargement dans tous les cas.
    }
  }

  /// Affiche un message à l'utilisateur via un `SnackBar`.
  void _showSnackBar(String message, Color color) {
    if(mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
  //endregion

  @override
  Widget build(BuildContext context) {
    // Ce widget est conçu pour être affiché dans une `AlertDialog`.
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.location_on, color: widget.primaryColor),
          const SizedBox(width: 8),
          Text("Modifier l'adresse", style: TextStyle(color: widget.primaryColor, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Champ pour le numéro de rue.
              TextFormField(
                controller: _numeroController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Numéro",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: widget.primaryColor, width: 2)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Le numéro est requis';
                  if (int.tryParse(value) == null) return 'Numéro invalide';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Champ pour la rue avec autocomplétion.
              StreetAutocomplete(
                streetController: _rueController,
                communeController: _communeController,
                codePostalController: _codePostalController,
                geoapifyApiKey: 'b097f188b11f46d2a02eb55021d168c1',
                onStreetSelected: _resetValidation,
                onStreetChanged: _resetValidation,
              ),
              const SizedBox(height: 16),

              // Champ pour le code postal avec autocomplétion de la commune.
              CommuneAutoFill(
                codePostalController: _codePostalController,
                communeController: _communeController,
                geoapifyApiKey: 'b097f188b11f46d2a02eb55021d168c1',
                onCommuneFound: _resetValidation,
                onCommuneNotFound: _resetValidation,
              ),
              const SizedBox(height: 16),

              // Champ pour la commune (non modifiable directement, rempli par l'autocomplétion).
              TextFormField(
                controller: _communeController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Commune",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true, fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 20),

              // Bouton pour lancer la validation de l'adresse.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isValidating ? null : _validateAddress,
                  icon: _isValidating ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_circle),
                  label: Text(_isValidating ? "Validation..." : "Valider l'adresse"),
                  style: ElevatedButton.styleFrom(backgroundColor: widget.primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              ),

              // Affiche le message de résultat de la validation.
              if (_validationMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isAddressValid ? widget.successColor.withOpacity(0.1) : widget.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _isAddressValid ? widget.successColor : widget.errorColor),
                  ),
                  child: Text(_validationMessage!, style: TextStyle(color: _isAddressValid ? widget.successColor : widget.errorColor, fontWeight: FontWeight.w500)),
                ),
              ],

              // Affiche les coordonnées GPS si l'adresse a été validée avec succès.
              if (_isAddressValid && _validatedLatitude != null && _validatedLongitude != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("📍 Coordonnées GPS :", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue[800])),
                      const SizedBox(height: 4),
                      Text("Lat: ${_validatedLatitude!.toStringAsFixed(6)}", style: TextStyle(fontSize: 12, color: Colors.blue[700])),
                      Text("Lng: ${_validatedLongitude!.toStringAsFixed(6)}", style: TextStyle(fontSize: 12, color: Colors.blue[700])),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      // Boutons d'action de la boîte de dialogue.
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), style: TextButton.styleFrom(foregroundColor: Colors.grey), child: const Text("Annuler")),
        // Le bouton "Sauvegarder" n'est activé que si l'adresse a été validée.
        TextButton(
          onPressed: _isAddressValid ? _saveAddress : null,
          style: TextButton.styleFrom(foregroundColor: _isAddressValid ? widget.primaryColor : Colors.grey),
          child: const Text("Sauvegarder"),
        ),
      ],
    );
  }
}





// // lib/pages/profil/widgets/address_change_widget.dart
// // Remplacer complètement le contenu de votre fichier par ceci
//
// import 'package:flutter/material.dart';
// // Imports avec alias pour éviter les conflits
// import 'package:hairbnb/models/current_user.dart' as UserModel;
// import 'package:hairbnb/models/adresse.dart' as AdresseModel;
// import 'package:hairbnb/pages/profil/services/update_services/adress_update/adress_update_service.dart';
// import 'package:hairbnb/pages/profil/services/update_services/adress_update/adress_validation.dart';
//
// import '../../../profil_widgets/auto_complete_widget.dart';
// import '../../../profil_widgets/commune_autofill_widget.dart';
//
// class AddressChangeWidget extends StatefulWidget {
//   final UserModel.CurrentUser currentUser;
//   final UserModel.Adresse? currentAddress; // Utiliser le modèle CurrentUser
//   final Function(bool) setLoadingState;
//   final Color primaryColor;
//   final Color successColor;
//   final Color errorColor;
//
//   const AddressChangeWidget({
//     super.key,
//     required this.currentUser,
//     this.currentAddress,
//     required this.setLoadingState,
//     required this.primaryColor,
//     required this.successColor,
//     required this.errorColor,
//   });
//
//   @override
//   State<AddressChangeWidget> createState() => _AddressChangeWidgetState();
// }
//
// class _AddressChangeWidgetState extends State<AddressChangeWidget> {
//   final _formKey = GlobalKey<FormState>();
//
//   // Contrôleurs
//   late TextEditingController _numeroController;
//   late TextEditingController _rueController;
//   late TextEditingController _communeController;
//   late TextEditingController _codePostalController;
//
//   // État de validation
//   bool _isValidating = false;
//   bool _isAddressValid = false;
//   String? _validationMessage;
//   double? _validatedLatitude;
//   double? _validatedLongitude;
//
//   @override
//   void initState() {
//     super.initState();
//
//     // Initialiser les contrôleurs avec conversion explicite
//     _numeroController = TextEditingController(
//         text: widget.currentAddress?.numero != null
//             ? widget.currentAddress!.numero.toString()
//             : ''
//     );
//     _rueController = TextEditingController(
//         text: widget.currentAddress?.rue?.nomRue ?? ''
//     );
//     _communeController = TextEditingController(
//         text: widget.currentAddress?.rue?.localite?.commune ?? ''
//     );
//     _codePostalController = TextEditingController(
//         text: widget.currentAddress?.rue?.localite?.codePostal ?? ''
//     );
//
//     // Reset validation quand l'utilisateur modifie
//     _numeroController.addListener(_resetValidation);
//     _rueController.addListener(_resetValidation);
//     _communeController.addListener(_resetValidation);
//     _codePostalController.addListener(_resetValidation);
//   }
//
//   @override
//   void dispose() {
//     _numeroController.dispose();
//     _rueController.dispose();
//     _communeController.dispose();
//     _codePostalController.dispose();
//     super.dispose();
//   }
//
//   void _resetValidation() {
//     if (_isAddressValid) {
//       setState(() {
//         _isAddressValid = false;
//         _validationMessage = null;
//         _validatedLatitude = null;
//         _validatedLongitude = null;
//       });
//     }
//   }
//
//   Future<void> _validateAddress() async {
//     if (!_formKey.currentState!.validate()) return;
//
//     setState(() {
//       _isValidating = true;
//       _validationMessage = null;
//     });
//
//     // Créer l'adresse pour validation avec le modèle AdresseModel
//     final adresse = AdresseModel.Adresse(
//       numero: int.tryParse(_numeroController.text),
//       rue: AdresseModel.Rue(
//         nomRue: _rueController.text,
//         localite: AdresseModel.Localite(
//           commune: _communeController.text,
//           codePostal: _codePostalController.text,
//         ),
//       ),
//     );
//
//     try {
//       final result = await AddressValidationService.validateAddress(adresse);
//
//       setState(() {
//         _isValidating = false;
//         _isAddressValid = result.isValid;
//
//         if (result.isValid) {
//           _validatedLatitude = result.latitude;
//           _validatedLongitude = result.longitude;
//           _validationMessage = "✅ Adresse validée avec succès";
//         } else {
//           _validationMessage = "❌ ${result.errorMessage}";
//         }
//       });
//     } catch (e) {
//       setState(() {
//         _isValidating = false;
//         _isAddressValid = false;
//         _validationMessage = "❌ Erreur: $e";
//       });
//     }
//   }
//
//   Future<void> _saveAddress() async {
//     if (!_isAddressValid) {
//       _showSnackBar("Veuillez d'abord valider l'adresse", widget.errorColor);
//       return;
//     }
//
//     // Préparer les données
//     Map<String, dynamic> addressData = {
//       'numero': int.tryParse(_numeroController.text),
//       'rue': {
//         'nomRue': _rueController.text,
//         'localite': {
//           'commune': _communeController.text,
//           'codePostal': _codePostalController.text
//         }
//       },
//       'latitude': _validatedLatitude,
//       'longitude': _validatedLongitude,
//       'is_validated': true,
//       'validation_date': DateTime.now().toIso8601String(),
//     };
//
//     try {
//       widget.setLoadingState(true);
//
//       await AddressUpdateService.updateUserAddress(
//         context,
//         widget.currentUser,
//         addressData,
//         successGreen: widget.successColor,
//         errorRed: widget.errorColor,
//         setLoadingState: widget.setLoadingState,
//       );
//
//       Navigator.of(context).pop(true);
//       _showSnackBar("✅ Adresse mise à jour avec succès", widget.successColor);
//
//     } catch (e) {
//       _showSnackBar("❌ Erreur: $e", widget.errorColor);
//     } finally {
//       widget.setLoadingState(false);
//     }
//   }
//
//   void _showSnackBar(String message, Color color) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: color,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       title: Row(
//         children: [
//           Icon(Icons.location_on, color: widget.primaryColor),
//           SizedBox(width: 8),
//           Text(
//             "Modifier l'adresse",
//             style: TextStyle(
//               color: widget.primaryColor,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//       content: SingleChildScrollView(
//         child: Form(
//           key: _formKey,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // Numéro
//               TextFormField(
//                 controller: _numeroController,
//                 keyboardType: TextInputType.number,
//                 decoration: InputDecoration(
//                   labelText: "Numéro",
//                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(10),
//                     borderSide: BorderSide(color: widget.primaryColor, width: 2),
//                   ),
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Le numéro est requis';
//                   }
//                   if (int.tryParse(value) == null) {
//                     return 'Numéro invalide';
//                   }
//                   return null;
//                 },
//               ),
//               SizedBox(height: 16),
//
//               // Rue avec autocomplétion
//               StreetAutocomplete(
//                 streetController: _rueController,
//                 communeController: _communeController,
//                 codePostalController: _codePostalController,
//                 geoapifyApiKey: 'b097f188b11f46d2a02eb55021d168c1',
//                 onStreetSelected: _resetValidation,
//                 onStreetChanged: _resetValidation,
//               ),
//               SizedBox(height: 16),
//
//               // Code postal avec autocomplétion commune
//               CommuneAutoFill(
//                 codePostalController: _codePostalController,
//                 communeController: _communeController,
//                 geoapifyApiKey: 'b097f188b11f46d2a02eb55021d168c1',
//                 onCommuneFound: _resetValidation,
//                 onCommuneNotFound: _resetValidation,
//               ),
//               SizedBox(height: 16),
//
//               // Commune (lecture seule)
//               TextFormField(
//                 controller: _communeController,
//                 readOnly: true,
//                 decoration: InputDecoration(
//                   labelText: "Commune",
//                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//                   filled: true,
//                   fillColor: Colors.grey[100],
//                 ),
//               ),
//               SizedBox(height: 20),
//
//               // Bouton de validation
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton.icon(
//                   onPressed: _isValidating ? null : _validateAddress,
//                   icon: _isValidating
//                       ? SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
//                   )
//                       : Icon(Icons.check_circle),
//                   label: Text(_isValidating ? "Validation..." : "Valider l'adresse"),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: widget.primaryColor,
//                     foregroundColor: Colors.white,
//                     padding: EdgeInsets.symmetric(vertical: 12),
//                   ),
//                 ),
//               ),
//
//               // Message de validation
//               if (_validationMessage != null) ...[
//                 SizedBox(height: 12),
//                 Container(
//                   width: double.infinity,
//                   padding: EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: _isAddressValid
//                         ? widget.successColor.withOpacity(0.1)
//                         : widget.errorColor.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(
//                       color: _isAddressValid ? widget.successColor : widget.errorColor,
//                     ),
//                   ),
//                   child: Text(
//                     _validationMessage!,
//                     style: TextStyle(
//                       color: _isAddressValid ? widget.successColor : widget.errorColor,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),
//               ],
//
//               // Coordonnées GPS
//               if (_isAddressValid && _validatedLatitude != null && _validatedLongitude != null) ...[
//                 SizedBox(height: 12),
//                 Container(
//                   width: double.infinity,
//                   padding: EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.blue.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         "📍 Coordonnées GPS :",
//                         style: TextStyle(
//                           fontWeight: FontWeight.w600,
//                           color: Colors.blue[800],
//                         ),
//                       ),
//                       SizedBox(height: 4),
//                       Text(
//                         "Lat: ${_validatedLatitude!.toStringAsFixed(6)}",
//                         style: TextStyle(fontSize: 12, color: Colors.blue[700]),
//                       ),
//                       Text(
//                         "Lng: ${_validatedLongitude!.toStringAsFixed(6)}",
//                         style: TextStyle(fontSize: 12, color: Colors.blue[700]),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.of(context).pop(),
//           style: TextButton.styleFrom(foregroundColor: Colors.grey),
//           child: Text("Annuler"),
//         ),
//         TextButton(
//           onPressed: _isAddressValid ? _saveAddress : null,
//           style: TextButton.styleFrom(
//             foregroundColor: _isAddressValid ? widget.primaryColor : Colors.grey,
//           ),
//           child: Text("Sauvegarder"),
//         ),
//       ],
//     );
//   }
// }