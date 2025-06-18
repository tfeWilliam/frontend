/// *****************************************************************************
///
/// FONCTION UTILITAIRE D'AFFICHAGE D'ERREUR
///
/// Ce fichier contient une fonction d'aide globale (`showError`) réutilisable
/// dans l'ensemble de l'application.
///
/// Son objectif est de standardiser la manière dont les messages d'erreur sont
/// présentés à l'utilisateur. Elle affiche une SnackBar (une notification en
/// bas de l'écran) avec un style distinctif et clair : un fond rouge et un
/// texte blanc, pour une reconnaissance immédiate de l'erreur.
///
///*****************************************************************************
library;

import 'package:flutter/material.dart';

/// Affiche une SnackBar d'erreur standardisée en bas de l'écran.
///
/// [message] : Le message d'erreur textuel à afficher dans la SnackBar.
/// [context] : Le BuildContext de l'interface, nécessaire pour localiser
///             le `ScaffoldMessenger` et pouvoir afficher la SnackBar.
void showError(String message, BuildContext context) {
  // Recherche le ScaffoldMessenger le plus proche dans l'arbre des widgets
  // et lui demande d'afficher une SnackBar.
  ScaffoldMessenger.of(context).showSnackBar(
    // Crée le widget SnackBar qui servira de notification.
    SnackBar(
      // Définit le contenu principal de la SnackBar, ici le message d'erreur.
      content: Text(
        message,
        // Applique un style au texte pour garantir sa lisibilité sur le fond rouge.
        style: const TextStyle(color: Colors.white),
      ),
      // Définit la couleur de fond de la SnackBar pour indiquer une erreur.
      backgroundColor: Colors.red,
    ),
  );
}






// import 'package:flutter/material.dart';
//
// void showError(String message, BuildContext context) {
//   ScaffoldMessenger.of(context).showSnackBar(
//     SnackBar(
//       content: Text(
//         message,
//         style: const TextStyle(color: Colors.white),
//       ),
//       backgroundColor: Colors.red,
//     ),
//   );
// }