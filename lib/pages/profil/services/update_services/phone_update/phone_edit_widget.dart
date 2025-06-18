/// *************************************************************************************************
///
/// BANNER : EXPLICATION GÉNÉRALE DU WIDGET D'ÉDITION DE TÉLÉPHONE
///
/// Ce fichier définit l'interface utilisateur permettant à un utilisateur de modifier son
/// numéro de téléphone. Il est composé de deux parties principales :
///
/// 1. `PhoneEditWidget` (StatefulWidget) :
/// - C'est le cœur du composant, présenté sous forme d'une `AlertDialog`.
/// - Il gère un champ de texte pour le nouveau numéro de téléphone.
/// - Intègre une validation en temps réel qui se déclenche lorsque l'utilisateur tape,
/// avec un "debounce" (délai) pour ne pas surcharger le système.
/// - Fournit des retours visuels instantanés (icônes de validation/erreur, messages).
/// - Interagit avec une couche de service (`PhoneUpdateService`) pour la validation
/// et la soumission des données, séparant ainsi la logique UI de la logique métier.
///
/// 2. `showPhoneEditDialog` (Fonction) :
/// - Une fonction utilitaire qui simplifie l'affichage du `PhoneEditWidget`.
/// - Elle encapsule l'appel `showDialog`, permettant de lancer la fenêtre modale
/// depuis n'importe où dans l'application avec une seule ligne de code.
///
///*************************************************************************************************
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hairbnb/pages/profil/services/update_services/phone_update/phone_update_service.dart';
import '../../../../../models/current_user.dart';

/// Widget affichant une boîte de dialogue pour modifier le numéro de téléphone de l'utilisateur.
class PhoneEditWidget extends StatefulWidget {
  /// Les données de l'utilisateur actuellement connecté.
  final CurrentUser currentUser;
  /// La couleur principale utilisée pour les icônes et les bordures.
  final Color primaryColor;
  /// La couleur utilisée pour indiquer un succès (validation réussie).
  final Color successColor;
  /// La couleur utilisée pour indiquer une erreur (validation échouée).
  final Color errorColor;
  /// Une fonction callback pour notifier le widget parent de l'état de chargement.
  final Function(bool) setLoadingState;

  const PhoneEditWidget({
    super.key,
    required this.currentUser,
    required this.primaryColor,
    required this.successColor,
    required this.errorColor,
    required this.setLoadingState,
  });

  @override
  State<PhoneEditWidget> createState() => _PhoneEditWidgetState();
}

/// La classe d'état pour `PhoneEditWidget`, gérant la logique interne du widget.
class _PhoneEditWidgetState extends State<PhoneEditWidget> {
  // Contrôleur pour le champ de texte du numéro de téléphone.
  late TextEditingController _phoneController;
  // Booléen pour afficher un indicateur de chargement pendant la validation.
  bool _isValidating = false;
  // Stocke le résultat de la dernière validation effectuée.
  PhoneValidationResult? _validationResult;

  @override
  void initState() {
    super.initState();
    // Initialise le contrôleur avec le numéro de téléphone actuel de l'utilisateur.
    _phoneController = TextEditingController(text: widget.currentUser.numeroTelephone ?? '');
    // Ajoute un écouteur pour réagir aux changements dans le champ de texte.
    _phoneController.addListener(_onPhoneChanged);
  }

  @override
  void dispose() {
    // Nettoie le contrôleur pour éviter les fuites de mémoire.
    _phoneController.dispose();
    super.dispose();
  }

  /// Appelé à chaque modification du texte dans le champ du téléphone.
  void _onPhoneChanged() {
    if (_phoneController.text.isNotEmpty) {
      setState(() {
        _isValidating = true; // Active l'indicateur de chargement.
      });

      // Utilise un délai (debounce) pour attendre que l'utilisateur ait fini de taper
      // avant de lancer la validation, ce qui améliore les performances.
      Future.delayed(const Duration(milliseconds: 500), () {
        // Vérifie que le widget est toujours affiché avant de mettre à jour l'état.
        if (mounted) {
          final validation = PhoneUpdateService.validatePhoneNumber(_phoneController.text);
          setState(() {
            _validationResult = validation; // Met à jour le résultat de la validation.
            _isValidating = false; // Désactive l'indicateur de chargement.
          });
        }
      });
    } else {
      // Si le champ est vide, réinitialise l'état de validation.
      setState(() {
        _validationResult = null;
        _isValidating = false;
      });
    }
  }

  /// Tente de soumettre le nouveau numéro de téléphone au service de mise à jour.
  Future<void> _updatePhoneNumber() async {
    final newPhone = _phoneController.text.trim();

    // Vérification de base pour s'assurer que le champ n'est pas vide.
    if (newPhone.isEmpty) {
      _showSnackBar('Veuillez saisir un numéro de téléphone', widget.errorColor, Icons.warning);
      return;
    }

    // Vérification de la validité du format avant de soumettre.
    if (_validationResult == null || !_validationResult!.isValid) {
      _showSnackBar('Veuillez corriger le format du numéro de téléphone', widget.errorColor, Icons.error);
      return;
    }

    // Délègue la logique de mise à jour complexe au service dédié.
    final success = await PhoneUpdateService.updateUserPhoneNumber(
      context,
      widget.currentUser,
      newPhone,
      successGreen: widget.successColor,
      errorRed: widget.errorColor,
      setLoadingState: widget.setLoadingState,
    );

    // Si la mise à jour a réussi, ferme la boîte de dialogue.
    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  /// Affiche une SnackBar pour donner un retour à l'utilisateur.
  void _showSnackBar(String message, Color color, IconData icon) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Le widget est construit comme une boîte de dialogue alerte.
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.phone, color: widget.primaryColor),
          const SizedBox(width: 12),
          const Text("Modifier le téléphone", style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min, // S'assure que la colonne prend la hauteur minimale.
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Saisissez votre nouveau numéro de téléphone :",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),

          // Champ de saisie principal pour le numéro de téléphone.
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              // Autorise uniquement les caractères pertinents pour un numéro de téléphone.
              FilteringTextInputFormatter.allow(RegExp(r'[\d\s\-\(\)\+]')),
            ],
            decoration: InputDecoration(
              labelText: "Numéro de téléphone",
              hintText: "+32 123 45 67 89",
              prefixIcon: Icon(Icons.phone, color: widget.primaryColor),
              // L'icône de suffixe change dynamiquement pour afficher l'état de validation.
              suffixIcon: _isValidating
              // 1. Affiche un spinner pendant la validation.
                  ? const SizedBox(
                width: 20, height: 20,
                child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)),
              )
              // 2. Affiche une icône de succès ou d'erreur après la validation.
                  : _validationResult != null
                  ? Icon(
                _validationResult!.isValid ? Icons.check_circle : Icons.error,
                color: _validationResult!.isValid ? widget.successColor : widget.errorColor,
              )
              // 3. N'affiche rien par défaut.
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: widget.primaryColor, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: widget.errorColor, width: 2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: widget.errorColor, width: 2),
              ),
            ),
          ),

          // Affiche le message de validation (succès ou erreur) sous le champ de texte.
          if (_validationResult != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _validationResult!.isValid ? Icons.check_circle : Icons.error,
                  size: 16,
                  color: _validationResult!.isValid ? widget.successColor : widget.errorColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _validationResult!.message,
                    style: TextStyle(
                      fontSize: 12,
                      color: _validationResult!.isValid ? widget.successColor : widget.errorColor,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Boîte d'information affichant les formats de numéros acceptés.
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: widget.primaryColor),
                    const SizedBox(width: 8),
                    const Text("Formats acceptés :", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "• +32 123 45 67 89 (Belgique)\n• +33 1 23 45 67 89 (France)\n• 012 34 56 78 (National)",
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
      // Actions disponibles : Annuler ou Sauvegarder.
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: Colors.grey),
          child: const Text("Annuler"),
        ),
        ElevatedButton(
          // Le bouton de sauvegarde n'est actif que si le numéro est valide.
          onPressed: _validationResult?.isValid == true ? _updatePhoneNumber : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text("Sauvegarder"),
        ),
      ],
    );
  }
}

/// Fonction utilitaire pour afficher la boîte de dialogue d'édition du téléphone.
///
/// [context] : Le BuildContext à partir duquel afficher la boîte de dialogue.
/// [currentUser] : L'instance de l'utilisateur pour pré-remplir les données.
/// [setLoadingState] : Callback pour gérer l'état de chargement globalement.
void showPhoneEditDialog(
    BuildContext context,
    CurrentUser currentUser, {
      Color primaryColor = const Color(0xFF7B61FF),
      Color successColor = Colors.green,
      Color errorColor = Colors.red,
      required Function(bool) setLoadingState,
    }) {
  showDialog(
    context: context,
    builder: (context) => PhoneEditWidget(
      currentUser: currentUser,
      primaryColor: primaryColor,
      successColor: successColor,
      errorColor: errorColor,
      setLoadingState: setLoadingState,
    ),
  );
}






// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:hairbnb/pages/profil/services/update_services/phone_update/phone_update_service.dart';
// import '../../../../../models/current_user.dart';
//
// class PhoneEditWidget extends StatefulWidget {
//   final CurrentUser currentUser;
//   final Color primaryColor;
//   final Color successColor;
//   final Color errorColor;
//   final Function(bool) setLoadingState;
//
//   const PhoneEditWidget({
//     super.key,
//     required this.currentUser,
//     required this.primaryColor,
//     required this.successColor,
//     required this.errorColor,
//     required this.setLoadingState,
//   });
//
//   @override
//   State<PhoneEditWidget> createState() => _PhoneEditWidgetState();
// }
//
// class _PhoneEditWidgetState extends State<PhoneEditWidget> {
//   late TextEditingController _phoneController;
//   bool _isValidating = false;
//   PhoneValidationResult? _validationResult;
//
//   @override
//   void initState() {
//     super.initState();
//     _phoneController = TextEditingController(text: widget.currentUser.numeroTelephone ?? '');
//     _phoneController.addListener(_onPhoneChanged);
//   }
//
//   @override
//   void dispose() {
//     _phoneController.dispose();
//     super.dispose();
//   }
//
//   void _onPhoneChanged() {
//     if (_phoneController.text.isNotEmpty) {
//       setState(() {
//         _isValidating = true;
//       });
//
//       // Débounce la validation pour éviter trop d'appels
//       Future.delayed(const Duration(milliseconds: 500), () {
//         if (mounted) {
//           final validation = PhoneUpdateService.validatePhoneNumber(_phoneController.text);
//           setState(() {
//             _validationResult = validation;
//             _isValidating = false;
//           });
//         }
//       });
//     } else {
//       setState(() {
//         _validationResult = null;
//         _isValidating = false;
//       });
//     }
//   }
//
//   Future<void> _updatePhoneNumber() async {
//     final newPhone = _phoneController.text.trim();
//
//     if (newPhone.isEmpty) {
//       _showSnackBar('Veuillez saisir un numéro de téléphone', widget.errorColor, Icons.warning);
//       return;
//     }
//
//     // Vérifier la validation avant de continuer
//     if (_validationResult == null || !_validationResult!.isValid) {
//       _showSnackBar('Veuillez corriger le format du numéro de téléphone', widget.errorColor, Icons.error);
//       return;
//     }
//
//     final success = await PhoneUpdateService.updateUserPhoneNumber(
//       context,
//       widget.currentUser,
//       newPhone,
//       successGreen: widget.successColor,
//       errorRed: widget.errorColor,
//       setLoadingState: widget.setLoadingState,
//     );
//
//     if (success) {
//       Navigator.of(context).pop(); // Fermer le dialog
//     }
//   }
//
//   void _showSnackBar(String message, Color color, IconData icon) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             Icon(icon, color: Colors.white),
//             const SizedBox(width: 12),
//             Expanded(child: Text(message)),
//           ],
//         ),
//         backgroundColor: color,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//         margin: const EdgeInsets.all(10),
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
//           Icon(Icons.phone, color: widget.primaryColor),
//           const SizedBox(width: 12),
//           const Text(
//             "Modifier le téléphone",
//             style: TextStyle(fontWeight: FontWeight.bold),
//           ),
//         ],
//       ),
//       content: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             "Saisissez votre nouveau numéro de téléphone :",
//             style: TextStyle(fontSize: 14, color: Colors.grey),
//           ),
//           const SizedBox(height: 16),
//
//           // Champ de saisie du téléphone
//           TextField(
//             controller: _phoneController,
//             keyboardType: TextInputType.phone,
//             inputFormatters: [
//               FilteringTextInputFormatter.allow(RegExp(r'[\d\s\-\(\)\+]')),
//             ],
//             decoration: InputDecoration(
//               labelText: "Numéro de téléphone",
//               hintText: "+32 123 45 67 89",
//               prefixIcon: Icon(Icons.phone, color: widget.primaryColor),
//               suffixIcon: _isValidating
//                   ? const SizedBox(
//                 width: 20,
//                 height: 20,
//                 child: Padding(
//                   padding: EdgeInsets.all(12),
//                   child: CircularProgressIndicator(strokeWidth: 2),
//                 ),
//               )
//                   : _validationResult != null
//                   ? Icon(
//                 _validationResult!.isValid
//                     ? Icons.check_circle
//                     : Icons.error,
//                 color: _validationResult!.isValid
//                     ? widget.successColor
//                     : widget.errorColor,
//               )
//                   : null,
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(10),
//                 borderSide: BorderSide(color: widget.primaryColor, width: 2),
//               ),
//               errorBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(10),
//                 borderSide: BorderSide(color: widget.errorColor, width: 2),
//               ),
//               focusedErrorBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(10),
//                 borderSide: BorderSide(color: widget.errorColor, width: 2),
//               ),
//             ),
//           ),
//
//           // Message de validation
//           if (_validationResult != null) ...[
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 Icon(
//                   _validationResult!.isValid ? Icons.check_circle : Icons.error,
//                   size: 16,
//                   color: _validationResult!.isValid ? widget.successColor : widget.errorColor,
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     _validationResult!.message,
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: _validationResult!.isValid ? widget.successColor : widget.errorColor,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//
//           // Informations sur les formats acceptés
//           const SizedBox(height: 16),
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Colors.grey[100],
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Icon(Icons.info_outline, size: 16, color: widget.primaryColor),
//                     const SizedBox(width: 8),
//                     const Text(
//                       "Formats acceptés :",
//                       style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 8),
//                 const Text(
//                   "• +32 123 45 67 89 (Belgique)\n"
//                       "• +33 1 23 45 67 89 (France)\n"
//                       "• 012 34 56 78 (National)",
//                   style: TextStyle(fontSize: 11, color: Colors.grey),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.of(context).pop(),
//           style: TextButton.styleFrom(foregroundColor: Colors.grey),
//           child: const Text("Annuler"),
//         ),
//         ElevatedButton(
//           onPressed: _validationResult?.isValid == true ? _updatePhoneNumber : null,
//           style: ElevatedButton.styleFrom(
//             backgroundColor: widget.primaryColor,
//             foregroundColor: Colors.white,
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//           ),
//           child: const Text("Sauvegarder"),
//         ),
//       ],
//     );
//   }
// }
//
// /// Fonction utilitaire pour afficher le widget d'édition du téléphone
// void showPhoneEditDialog(
//     BuildContext context,
//     CurrentUser currentUser, {
//       Color primaryColor = const Color(0xFF7B61FF),
//       Color successColor = Colors.green,
//       Color errorColor = Colors.red,
//       required Function(bool) setLoadingState,
//     }) {
//   showDialog(
//     context: context,
//     builder: (context) => PhoneEditWidget(
//       currentUser: currentUser,
//       primaryColor: primaryColor,
//       successColor: successColor,
//       errorColor: errorColor,
//       setLoadingState: setLoadingState,
//     ),
//   );
// }