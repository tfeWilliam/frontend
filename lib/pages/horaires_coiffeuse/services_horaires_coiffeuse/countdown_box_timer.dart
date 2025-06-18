/// **************************************************************************************
///
/// WIDGET UI : COMPTE À REBOURS VISUEL
///
/// OBJECTIF :
/// Ce fichier définit un widget réutilisable, `CountdownBoxTimer`, qui affiche un
/// compte à rebours visuel jusqu'à une date et heure spécifiées.
///
/// ARCHITECTURE ET FONCTIONNALITÉS CLÉS :
/// - Utilise un `StatefulWidget` pour gérer l'état du temps restant, qui est mis
/// à jour chaque seconde.
/// - Emploie un `Timer.periodic` pour déclencher les mises à jour de l'état.
/// - Gère correctement le cycle de vie du widget en annulant le timer dans la
/// méthode `dispose` pour éviter les fuites de mémoire.
/// - L'interface est décomposée en "boîtes" stylisées pour les jours, heures,
/// minutes et secondes.
/// - Utilise `FittedBox` pour s'assurer que le widget s'adapte à l'espace
/// qui lui est alloué sans causer d'erreurs de débordement (overflow).
///
///***************************************************************************************
library;
import 'dart:async';
import 'package:flutter/material.dart';

/// Un widget qui affiche un compte à rebours visuel jusqu'à une date et heure cibles.
class CountdownBoxTimer extends StatefulWidget {
  /// La date et l'heure futures vers lesquelles le compte à rebours doit converger.
  final DateTime targetTime;

  const CountdownBoxTimer({super.key, required this.targetTime});

  @override
  State<CountdownBoxTimer> createState() => _CountdownBoxTimerState();
}

class _CountdownBoxTimerState extends State<CountdownBoxTimer> {
  /// La durée restante jusqu'à l'heure cible. Mise à jour chaque seconde.
  late Duration remaining;
  /// Le timer qui déclenche la mise à jour de l'état chaque seconde.
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Initialise la durée restante une première fois.
    _updateTime();
    // Démarre un timer qui appellera _updateTime toutes les secondes.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  @override
  void dispose() {
    // Annule le timer lorsque le widget est retiré de l'arbre pour éviter les fuites de mémoire.
    _timer?.cancel();
    super.dispose();
  }

  /// Calcule la durée restante et déclenche une reconstruction du widget via `setState`.
  void _updateTime() {
    final now = DateTime.now();
    // Assure que la durée ne devient pas négative après la fin du compte à rebours.
    setState(() {
      remaining = widget.targetTime.difference(now).isNegative
          ? Duration.zero
          : widget.targetTime.difference(now);
    });
  }

  /// Construit une boîte stylisée unique pour afficher une unité de temps (ex: jours, heures).
  ///
  /// [value] : La valeur numérique à afficher (ex: "08").
  /// [label] : L'étiquette sous la valeur (ex: "Heures").
  Widget buildTimeBox(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.purple.shade400, Colors.deepPurple.shade600]),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              // Assure que les chiffres ont une largeur fixe pour éviter les sauts de layout.
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Décompose la durée restante en jours, heures, minutes et secondes.
    final days = remaining.inDays;
    final hours = remaining.inHours.remainder(24);
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);

    return SizedBox(
      width: 200,
      height: 70,
      // Utilise FittedBox pour s'assurer que le widget s'adapte à l'espace disponible sans déborder.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildTimeBox(days.toString().padLeft(2, '0'), "Jours"),
            const SizedBox(width: 6),
            buildTimeBox(hours.toString().padLeft(2, '0'), "Heures"),
            const SizedBox(width: 6),
            buildTimeBox(minutes.toString().padLeft(2, '0'), "Min"),
            const SizedBox(width: 6),
            buildTimeBox(seconds.toString().padLeft(2, '0'), "Sec"),
          ],
        ),
      ),
    );
  }
}






// import 'dart:async';
// // pour FontFeature
// import 'package:flutter/material.dart';
//
// class CountdownBoxTimer extends StatefulWidget {
//   final DateTime targetTime;
//
//   const CountdownBoxTimer({super.key, required this.targetTime});
//
//   @override
//   State<CountdownBoxTimer> createState() => _CountdownBoxTimerState();
// }
//
// class _CountdownBoxTimerState extends State<CountdownBoxTimer> {
//   late Duration remaining;
//   Timer? _timer;
//
//   @override
//   void initState() {
//     super.initState();
//     _updateTime();
//     _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
//   }
//
//   void _updateTime() {
//     final now = DateTime.now();
//     setState(() {
//       remaining = widget.targetTime.difference(now).isNegative
//           ? Duration.zero
//           : widget.targetTime.difference(now);
//     });
//   }
//
//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }
//
//   Widget buildTimeBox(String value, String label) {
//     return Column(
//       children: [
//         Container(
//           padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
//           decoration: BoxDecoration(
//             gradient: LinearGradient(colors: [Colors.purple.shade400, Colors.deepPurple.shade600]),
//             borderRadius: BorderRadius.circular(6),
//           ),
//           child: Text(
//             value,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               fontFeatures: [FontFeature.tabularFigures()],
//             ),
//           ),
//         ),
//         const SizedBox(height: 2),
//         Text(
//           label,
//           style: const TextStyle(fontSize: 10, color: Colors.grey),
//         ),
//       ],
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final days = remaining.inDays;
//     final hours = remaining.inHours.remainder(24);
//     final minutes = remaining.inMinutes.remainder(60);
//     final seconds = remaining.inSeconds.remainder(60);
//
//     return SizedBox(
//       width: 200,
//       height: 70,
//       child: FittedBox(
//         fit: BoxFit.scaleDown,
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             buildTimeBox(days.toString().padLeft(2, '0'), "Jours"),
//             const SizedBox(width: 6),
//             buildTimeBox(hours.toString().padLeft(2, '0'), "Heures"),
//             const SizedBox(width: 6),
//             buildTimeBox(minutes.toString().padLeft(2, '0'), "Min"),
//             const SizedBox(width: 6),
//             buildTimeBox(seconds.toString().padLeft(2, '0'), "Sec"),
//           ],
//         ),
//       ),
//     );
//   }
// }
