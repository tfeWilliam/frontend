/// **************************************************************************************
///
/// PAGE UI : AFFICHAGE DU REÇU DE PAIEMENT
///
/// OBJECTIF :
/// Ce fichier définit un widget `ReceiptPage` qui sert d'écran de transition. Son
/// rôle principal n'est pas d'afficher du contenu directement, mais de lancer
/// automatiquement une URL externe (le reçu de paiement) dans le navigateur par
/// défaut de l'utilisateur ou une autre application capable de gérer les URL.
///
/// ARCHITECTURE ET FONCTIONNALITÉS CLÉS :
/// - C'est un `StatelessWidget` qui reçoit une URL en paramètre.
/// - Utilise le package `url_launcher` pour ouvrir le lien dans une application externe.
/// - L'ouverture de l'URL est déclenchée automatiquement dès que la page est
/// affichée, grâce à `WidgetsBinding.instance.addPostFrameCallback`.
/// - Fournit une interface utilisateur de secours simple, informant l'utilisateur de
/// l'action en cours et lui offrant des options pour relancer l'URL ou revenir
/// à l'écran précédent.
///
///***************************************************************************************
library;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Un écran qui sert de pont pour ouvrir une URL de reçu externe.
class ReceiptPage extends StatelessWidget {
  /// L'URL du reçu de paiement à ouvrir.
  final String receiptUrl;
  const ReceiptPage({super.key, required this.receiptUrl});

  /// Tente de lancer l'URL du reçu dans une application externe (ex: un navigateur web).
  /// Gère les erreurs potentielles si l'URL ne peut pas être ouverte.
  Future<void> _launchUrl() async {
    final Uri url = Uri.parse(receiptUrl);
    try {
      // Tente de lancer l'URL en mode "externalApplication" pour quitter l'application
      // et utiliser le navigateur par défaut de l'appareil.
      if (!await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      )) {
        throw 'Impossible d\'ouvrir le reçu';
      }
    } catch (e) {
      // Gère les exceptions si le lancement échoue.
    }
  }

  @override
  Widget build(BuildContext context) {
    // Le `WidgetsBinding` est utilisé pour déclencher l'ouverture de l'URL
    // automatiquement juste après le premier rendu de la page.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _launchUrl();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reçu de paiement'),
        backgroundColor: Colors.purple.shade100,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      // Le corps de la page sert d'interface de secours, informant l'utilisateur
      // de l'action en cours et offrant des options alternatives.
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.receipt_long,
              size: 80,
              color: Colors.purple,
            ),
            const SizedBox(height: 20),
            const Text(
              'Ouverture du reçu dans le navigateur...',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            // Bouton pour permettre à l'utilisateur de tenter à nouveau d'ouvrir le reçu.
            ElevatedButton.icon(
              onPressed: _launchUrl,
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Ouvrir à nouveau'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            const SizedBox(height: 30),
            // Bouton pour revenir à l'écran précédent.
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Retour'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade600,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}






// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';
//
// class ReceiptPage extends StatelessWidget {
//   final String receiptUrl;
//   const ReceiptPage({super.key, required this.receiptUrl});
//
//   Future<void> _launchUrl() async {
//     final Uri url = Uri.parse(receiptUrl);
//     try {
//       if (!await launchUrl(
//         url,
//         mode: LaunchMode.externalApplication,
//       )) {
//         throw 'Impossible d\'ouvrir le reçu';
//       }
//     } catch (e) {
//       print('Erreur lors de l\'ouverture de l\'URL: $e');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // Lancer automatiquement l'URL lors de l'affichage de cette page
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _launchUrl();
//     });
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Reçu de paiement'),
//         backgroundColor: Colors.purple.shade100,
//         // Ajout d'un bouton de retour explicite si nécessaire
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.of(context).pop(),
//         ),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(
//               Icons.receipt_long,
//               size: 80,
//               color: Colors.purple,
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               'Ouverture du reçu dans le navigateur...',
//               style: TextStyle(fontSize: 18),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 30),
//             // Bouton pour ouvrir à nouveau le reçu
//             ElevatedButton.icon(
//               onPressed: _launchUrl,
//               icon: const Icon(Icons.open_in_browser),
//               label: const Text('Ouvrir à nouveau'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.purple,
//                 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//               ),
//             ),
//             const SizedBox(height: 30),
//             // Bouton pour revenir à la page précédente
//             ElevatedButton.icon(
//               onPressed: () => Navigator.of(context).pop(),
//               icon: const Icon(Icons.arrow_back),
//               label: const Text('Retour'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.grey.shade600,
//                 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
