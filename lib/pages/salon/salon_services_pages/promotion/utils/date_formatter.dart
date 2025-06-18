////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//          CLASSE UTILITAIRE POUR LE FORMATAGE DES DATES ET DURÉES             //
//                                                                            //
//  Ce fichier définit `DateFormatter`, une classe contenant un ensemble de   //
//  méthodes statiques pour convertir des objets `DateTime` et des durées en  //
//  chaînes de caractères lisibles par l'homme.                               //
//                                                                            //
//  L'objectif est de centraliser toute la logique de formatage pour garantir //
//  une cohérence visuelle à travers toute l'application et de simplifier     //
//  la manipulation des dates dans les widgets.                               //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;

import 'package:intl/intl.dart';

/// Une classe utilitaire avec des méthodes statiques pour formater les dates et les durées.
///
/// Cette classe n'est pas destinée à être instanciée, elle sert de conteneur
/// pour des fonctions logiques réutilisables.
class DateFormatter {
  /// Formate une `DateTime` en une chaîne de caractères simple au format "jour/mois/année".
  ///
  /// Exemple: `formatDate(DateTime(2025, 6, 18))` retourne "18/06/2025".
  ///
  /// [date] : La `DateTime` à formater.
  static String formatDate(DateTime date) {
    // Utilise le package `intl` pour un formatage localisé et fiable.
    final DateFormat formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(date);
  }

  /// Formate une `DateTime` en une chaîne de caractères incluant la date et l'heure.
  ///
  /// Exemple: `formatDateWithTime(DateTime(2025, 6, 18, 14, 30))` retourne "18/06/2025 14:30".
  ///
  /// [date] : La `DateTime` à formater.
  static String formatDateWithTime(DateTime date) {
    final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(date);
  }

  /// Extrait et retourne uniquement la partie date d'une `DateTime` au format ISO "yyyy-MM-dd".
  ///
  /// Utile pour les comparaisons de dates sans tenir compte de l'heure.
  ///
  /// [date] : La `DateTime` dont on veut extraire la date.
  static String getDateOnly(DateTime date) {
    // Convertit en chaîne ISO 8601 (ex: "2025-06-18T14:30:00.000") et ne garde que la partie avant le 'T'.
    return date.toIso8601String().split('T')[0];
  }
}

/// Fournit une représentation textuelle relative d'une date par rapport à la date actuelle.
///
/// Retourne des termes comme "Aujourd'hui", "Demain", "Hier", "Dans X jours", etc.
/// Si la date est trop éloignée, elle retourne la date formatée standard (`dd/MM/yyyy`).
///





// // 📁 lib/utils/date_formatter.dart
// import 'package:intl/intl.dart';
//
// class DateFormatter {
//   // Formatage simple de date (jour/mois/année)
//   static String formatDate(DateTime date) {
//     final DateFormat formatter = DateFormat('dd/MM/yyyy');
//     return formatter.format(date);
//   }
//
//   // Formatage de date avec heure
//   static String formatDateWithTime(DateTime date) {
//     final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm');
//     return formatter.format(date);
//   }
//
//   // Extraction de la partie date uniquement (sans heure)
//   static String getDateOnly(DateTime date) {
//     return date.toIso8601String().split('T')[0];
//   }
//
//   // Formatage relatif (aujourd'hui, demain, dans X jours, etc.)
//   static String getRelativeDate(DateTime date) {
//     final now = DateTime.now();
//     final today = DateTime(now.year, now.month, now.day);
//     final dateOnly = DateTime(date.year, date.month, date.day);
//
//     final difference = dateOnly.difference(today).inDays;
//
//     if (difference == 0) {
//       return "Aujourd'hui";
//     } else if (difference == 1) {
//       return "Demain";
//     } else if (difference == -1) {
//       return "Hier";
//     } else if (difference > 1 && difference < 7) {
//       return "Dans $difference jours";
//     } else if (difference < 0 && difference > -7) {
//       return "Il y a ${-difference} jours";
//     } else {
//       return formatDate(date);
//     }
//   }
//
//   // Formatage pour l'affichage des durées
//   static String formatDuration(int minutes) {
//     if (minutes < 60) {
//       return "$minutes min";
//     } else {
//       final hours = minutes ~/ 60;
//       final mins = minutes % 60;
//       return mins > 0 ? "${hours}h ${mins}min" : "${hours}h";
//     }
//   }
// }