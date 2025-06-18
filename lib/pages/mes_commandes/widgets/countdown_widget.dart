////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                WIDGET D'AFFICHAGE D'UN COMPTE À REBOURS                      //
//                                                                            //
//  Ce fichier définit `CountdownWidget`, un composant UI réutilisable et     //
//  purement visuel, conçu pour afficher un compte à rebours jusqu'à une      //
//  date et heure spécifiques.                                                //
//                                                                            //
//  NOTE IMPORTANTE : Ce widget est `Stateless`. Il ne contient pas de        //
//  `Timer` interne. Pour que le compte à rebours s'actualise visuellement,   //
//  il doit être reconstruit périodiquement par son widget parent (qui lui,   //
//  gère le `Timer` et l'état de la durée restante).                          //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;

import 'package:flutter/material.dart';

/// Un widget qui affiche un compte à rebours stylisé.
class CountdownWidget extends StatelessWidget {
  /// La date et l'heure cibles pour le compte à rebours.
  final DateTime dateHeure;
  /// Le statut de l'entité associée (ex: commande, rendez-vous).
  final String statut;
  /// La durée restante, fournie par le widget parent.
  final Duration timeLeft;
  /// Un booléen indiquant si le temps est écoulé, fourni par le parent.
  final bool isExpired;

  /// Constructeur pour le widget de compte à rebours.
  const CountdownWidget({
    super.key,
    required this.dateHeure,
    required this.statut,
    required this.timeLeft,
    required this.isExpired,
  });

  /// Méthode privée pour construire la boîte stylisée d'une unité de temps (jour, heure, etc.).
  ///
  /// [value] : La valeur numérique (ex: "08").
  /// [unit] : L'unité de temps (ex: "h").
  Widget _buildTimeUnit(String value, String unit) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.purple[600],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          Text(
            unit,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ne rien afficher si le rendez-vous est passé ET qu'il a un statut final.
    if (isExpired && ["annulé", "terminé"].contains(statut.toLowerCase())) {
      return const SizedBox.shrink(); // Retourne un widget vide de taille nulle.
    }

    // Le conteneur principal du widget.
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        // La couleur de fond et de bordure change si le temps est écoulé.
        color: isExpired ? Colors.orange[50] : Colors.purple[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isExpired ? Colors.orange[200]! : Colors.purple[100]!),
      ),
      child: Column(
        children: [
          // Ligne de titre ("Temps restant" ou "Rendez-vous commencé").
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isExpired ? Icons.timer_off : Icons.timer,
                size: 16,
                color: isExpired ? Colors.orange : Colors.purple,
              ),
              const SizedBox(width: 6),
              Text(
                isExpired ? "Rendez-vous commencé" : "Temps restant",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isExpired ? Colors.orange : Colors.purple,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          // Affiche le compte à rebours numérique seulement si le temps n'est pas écoulé.
          if (!isExpired) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Affiche les jours seulement s'il en reste.
                if (timeLeft.inDays > 0)
                  _buildTimeUnit("${timeLeft.inDays}", "j"),

                // Affiche les heures, formatées sur deux chiffres (ex: 08).
                _buildTimeUnit((timeLeft.inHours % 24).toString().padLeft(2, '0'), "h"),

                // Affiche les minutes, formatées sur deux chiffres.
                _buildTimeUnit((timeLeft.inMinutes % 60).toString().padLeft(2, '0'), "m"),

                // Affiche les secondes, formatées sur deux chiffres.
                _buildTimeUnit((timeLeft.inSeconds % 60).toString().padLeft(2, '0'), "s"),
              ],
            ),
          ],
        ],
      ),
    );
  }
}






// import 'package:flutter/material.dart';
//
// class CountdownWidget extends StatelessWidget {
//   final DateTime dateHeure;
//   final String statut;
//   final Duration timeLeft;
//   final bool isExpired;
//
//   const CountdownWidget({
//     super.key,
//     required this.dateHeure,
//     required this.statut,
//     required this.timeLeft,
//     required this.isExpired,
//   });
//
//   // Widget pour afficher une unité de temps (jours, heures, minutes, secondes)
//   Widget _buildTimeUnit(String value, String unit) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 2),
//       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
//       decoration: BoxDecoration(
//         color: Colors.purple[600],
//         borderRadius: BorderRadius.circular(4),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(
//             value,
//             style: const TextStyle(
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//               fontSize: 14,
//             ),
//           ),
//           Text(
//             unit,
//             style: const TextStyle(
//               color: Colors.white70,
//               fontSize: 10,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (isExpired && ["annulé", "terminé"].contains(statut.toLowerCase())) {
//       return const SizedBox.shrink(); // Ne pas afficher de compte à rebours pour les commandes terminées ou annulées
//     }
//
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       padding: const EdgeInsets.all(8),
//       decoration: BoxDecoration(
//         color: isExpired ? Colors.orange[50] : Colors.purple[50],
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: isExpired ? Colors.orange[200]! : Colors.purple[100]!),
//       ),
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 isExpired ? Icons.timer_off : Icons.timer,
//                 size: 16,
//                 color: isExpired ? Colors.orange : Colors.purple,
//               ),
//               const SizedBox(width: 6),
//               Text(
//                 isExpired ? "Rendez-vous commencé" : "Temps restant",
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   color: isExpired ? Colors.orange : Colors.purple,
//                   fontSize: 14,
//                 ),
//               ),
//             ],
//           ),
//           if (!isExpired) ...[
//             const SizedBox(height: 6),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 if (timeLeft.inDays > 0)
//                   _buildTimeUnit("${timeLeft.inDays}", "j"),
//
//                 _buildTimeUnit("${(timeLeft.inHours % 24).toString().padLeft(2, '0')}", "h"),
//
//                 _buildTimeUnit("${(timeLeft.inMinutes % 60).toString().padLeft(2, '0')}", "m"),
//
//                 _buildTimeUnit("${(timeLeft.inSeconds % 60).toString().padLeft(2, '0')}", "s"),
//               ],
//             ),
//           ],
//         ],
//       ),
//     );
//   }
// }