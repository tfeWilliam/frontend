/// *****************************************************************************
///
/// WIDGET DE STRUCTURE DE PAGE (HairbnbScaffold)
///
/// Ce fichier définit `HairbnbScaffold`, un widget `Stateless` qui sert de
/// modèle de base réutilisable pour la plupart des pages de l'application "Hairbnb".
///
/// RÔLE ET FONCTIONNEMENT :
/// 1.  **Consistance de l'UI** : Il garantit que toutes les pages utilisant ce
/// widget auront une apparence cohérente en intégrant une `CustomAppBar`
/// et un `MyDrawer` communs.
///
/// 2.  **Gestion de l'état utilisateur** : Le widget écoute les changements
/// provenant du `CurrentUserProvider`. C'est un point crucial : il ne
/// construit l'interface principale que si les informations de l'utilisateur
/// connecté sont disponibles.
///
/// 3.  **Affichage conditionnel** : Si les données de l'utilisateur ne sont pas
/// encore chargées (`currentUser` est `null`), il affiche un indicateur de
/// chargement. Cela évite les erreurs et améliore l'expérience utilisateur
/// en attendant les données asynchrones.
///
/// 4.  **Flexibilité** : Il accepte un widget `body` qui représente le contenu
/// spécifique de chaque page, ainsi que des paramètres optionnels comme
/// `bottomNavigationBar`.
///
///*****************************************************************************
library;

import 'package:flutter/material.dart';
import 'package:hairbnb/services/providers/current_user_provider.dart'; // Fournisseur d'état pour l'utilisateur courant
import 'package:hairbnb/widgets/custom_app_bar.dart'; // Widget personnalisé pour l'AppBar
import 'package:hairbnb/services/my_drawer_service/my_drawer.dart'; // Widget pour le menu latéral (drawer)
import 'package:provider/provider.dart'; // Pour la gestion d'état avec le pattern Provider

/// Un widget de structure de page (Scaffold) personnalisé et réutilisable.
/// Il intègre une AppBar et un Drawer standards et gère l'état de chargement de l'utilisateur.
class HairbnbScaffold extends StatelessWidget {
  /// Le contenu principal de la page, qui est variable.
  final Widget body;

  /// Une barre de navigation inférieure, optionnelle.
  final Widget? bottomNavigationBar;

  /// Spécifie si le `body` doit se redimensionner pour éviter le clavier. Optionnel.
  final bool? resizeToAvoidBottomInset;

  /// Constructeur du widget `HairbnbScaffold`.
  const HairbnbScaffold({
    super.key,
    required this.body,
    this.bottomNavigationBar,
    this.resizeToAvoidBottomInset,
  });

  @override
  Widget build(BuildContext context) {
    // Utilise un Consumer pour s'abonner aux changements du CurrentUserProvider.
    // Le widget se reconstruira automatiquement si `currentUser` change.
    return Consumer<CurrentUserProvider>(
        builder: (context, userProvider, _) {
          // Récupère l'objet utilisateur depuis le provider.
          final currentUser = userProvider.currentUser;

          // Condition de garde : si l'utilisateur n'est pas encore chargé (null),
          // on affiche un écran de chargement pour éviter les erreurs.
          if (currentUser == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Une fois que l'utilisateur est disponible, on construit la page complète.
          return Scaffold(
            // Barre d'application personnalisée, commune à toutes les pages.
            appBar: const CustomAppBar(),
            // Menu latéral qui reçoit les informations de l'utilisateur pour les afficher.
            drawer: MyDrawer(currentUser: currentUser),
            // Le corps de la page, fourni lors de l'instanciation de HairbnbScaffold.
            body: body,
            // La barre de navigation inférieure, si elle est fournie.
            bottomNavigationBar: bottomNavigationBar,
            // Le comportement face au clavier, s'il est spécifié.
            resizeToAvoidBottomInset: resizeToAvoidBottomInset,
          );
        }
    );
  }
}




// import 'package:flutter/material.dart';
// import 'package:hairbnb/services/providers/current_user_provider.dart';
// import 'package:hairbnb/widgets/custom_app_bar.dart';
// import 'package:hairbnb/services/my_drawer_service/my_drawer.dart';
// import 'package:provider/provider.dart';
//
// class HairbnbScaffold extends StatelessWidget {
//   final Widget body;
//   final Widget? bottomNavigationBar;
//   final bool? resizeToAvoidBottomInset;
//
//   const HairbnbScaffold({
//     super.key,
//     required this.body,
//     this.bottomNavigationBar,
//     this.resizeToAvoidBottomInset,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Consumer<CurrentUserProvider>(
//         builder: (context, userProvider, _) {
//       final currentUser = userProvider.currentUser;
//
//     if (currentUser == null) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }
//
//     return Scaffold(
//       appBar: const CustomAppBar(),
//       drawer: MyDrawer(currentUser: currentUser),
//       body: body,
//       bottomNavigationBar: bottomNavigationBar,
//       resizeToAvoidBottomInset: resizeToAvoidBottomInset,
//     );
//   }
//     );
//   }
// }