////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                PAGE D'ACCUEIL PRINCIPALE DE L'APPLICATION                  //
//                                                                            //
//  Ce fichier définit la `HomePage`, qui sert d'écran principal à            //
//  l'utilisateur après sa connexion. C'est le hub central de l'application.  //
//                                                                            //
//  Fonctionnalités :                                                         //
//  - Affiche un message de bienvenue personnalisé.                            //
//  - Intègre un `AvisBadgeWidget` de manière proéminente pour inciter        //
//    l'utilisateur à laisser des avis en attente.                            //
//  - Utilise un `HairbnbScaffold` pour une structure de page cohérente        //
//    (probablement avec un `AppBar` et un `Drawer` configurés).              //
//  - Gère la navigation via un `BottomNavBar`.                               //
//  - Récupère les informations de l'utilisateur via le `CurrentUserProvider`.//
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hairbnb/widgets/bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import '../services/my_drawer_service/hairbnb_scaffold.dart';
import '../services/providers/current_user_provider.dart';
import 'avis/mes_avis_en_attente_page.dart';
import 'avis/widgets/avis_badge_widget.dart';

/// Widget principal de la page d'accueil.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

/// Classe d'état pour `HomePage`.
/// Gère l'état de l'interface, notamment l'index de la barre de navigation.
class _HomePageState extends State<HomePage> {
  /// L'index de l'onglet actuellement sélectionné dans le `BottomNavBar`.
  int _currentIndex = 0;

  /// Gère la navigation vers la page des avis en attente.
  ///
  /// Cette méthode est appelée lors du clic sur le badge ou le bouton.
  /// Elle utilise `Navigator.push` et attend un résultat potentiel
  /// au retour de la page pour rafraîchir l'état si nécessaire.
  void _navigateToAvisEnAttente() {
    if (kDebugMode) {
      print("Navigation vers avis en attente");
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MesAvisEnAttenteScreen(),
      ),
    ).then((result) {
      // Si la page `MesAvisEnAttenteScreen` retourne `true` (par exemple,
      // après qu'un avis a été laissé), on déclenche une reconstruction
      // de la page d'accueil pour potentiellement rafraîchir ses widgets.
      if (result == true) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Récupère les informations de l'utilisateur connecté via le Provider.
    final currentUser = Provider.of<CurrentUserProvider>(context).currentUser;

    // Utilise un Scaffold personnalisé pour une mise en page cohérente.
    return HairbnbScaffold(
      body: Column(
        children: [
          // Widget affichant le badge des avis en attente.
          // C'est un composant autonome qui gère sa propre logique d'affichage.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: AvisBadgeText(
              onTap: _navigateToAvisEnAttente,
            ),
          ),

          // Contenu principal de la page.
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Message de bienvenue personnalisé.
                  Text(
                    "Bienvenue, ${currentUser?.prenom ?? ''} ${currentUser?.nom ?? ''}",
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 20),

                  // Bouton de test ou d'action principal.
                  ElevatedButton.icon(
                    onPressed: _navigateToAvisEnAttente,
                    icon: const Icon(Icons.rate_review),
                    label: const Text("Voir mes avis en attente"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      // Barre de navigation inférieure.
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          // Met à jour l'état de l'index lors du clic sur un onglet.
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}







// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:hairbnb/widgets/bottom_nav_bar.dart';
// import 'package:provider/provider.dart';
// import '../services/my_drawer_service/hairbnb_scaffold.dart';
// import '../services/providers/current_user_provider.dart';
// import 'avis/mes_avis_en_attente_page.dart';
// import 'avis/widgets/avis_badge_widget.dart';
//
// class HomePage extends StatefulWidget {
//   const HomePage({super.key});
//
//   @override
//   _HomePageState createState() => _HomePageState();
// }
//
// class _HomePageState extends State<HomePage> {
//   int _currentIndex = 0;
//
//   /// 🔔 Fonction appelée quand on clique sur le badge d'avis
//   void _navigateToAvisEnAttente() {
//     if (kDebugMode) {
//       print("🔔 Navigation vers avis en attente");
//     }
//
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => MesAvisEnAttenteScreen(),
//       ),
//     ).then((result) {
//       if (result == true) {
//         setState(() {});
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final currentUser = Provider.of<CurrentUserProvider>(context).currentUser;
//
//     return HairbnbScaffold(
//       body: Column(
//         children: [
//           // 🎯 BADGE EN HAUT (s'affiche seulement s'il y a des avis)
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.all(16),
//             child: AvisBadgeText(
//               onTap: _navigateToAvisEnAttente,
//             ),
//           ),
//
//           // 🎯 CONTENU PRINCIPAL (centré)
//           Expanded(
//             child: Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(
//                     "Bienvenue, ${currentUser?.nom ?? ''} ${currentUser?.prenom ?? ''}",
//                     style: const TextStyle(fontSize: 20),
//                   ),
//                   const SizedBox(height: 20),
//
//                   const SizedBox(height: 20),
//
//                   // Bouton normal pour tester
//                   ElevatedButton.icon(
//                     onPressed: _navigateToAvisEnAttente,
//                     icon: Icon(Icons.rate_review),
//                     label: Text("Voir mes avis en attente"),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.orange,
//                       foregroundColor: Colors.white,
//                       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//       bottomNavigationBar: BottomNavBar(
//         currentIndex: _currentIndex,
//         onTap: (index) {
//           setState(() {
//             _currentIndex = index;
//           });
//         },
//       ),
//     );
//   }
// }
//
