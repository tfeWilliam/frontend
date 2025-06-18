////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//             WIDGET D'INITIALISATION POUR LE MODULE DE CHAT AI                //
//                                                                            //
//  Ce fichier définit le `AIChatWrapper`, un widget essentiel qui sert de     //
//  point d'entrée au module de chat AI. Son rôle principal est de gérer les   //
//  tâches d'initialisation asynchrones et l'injection de dépendances.         //
//                                                                            //
//  Fonctionnement :                                                          //
//  1. Il récupère de manière asynchrone le jeton d'authentification Firebase  //
//     de l'utilisateur actuellement connecté.                                //
//  2. Pendant le chargement du jeton, il affiche un indicateur de progression.//
//  3. Une fois le jeton obtenu, il initialise et fournit le `AIChatProvider`  //
//     à l'ensemble de l'arbre de widgets enfants, rendant ainsi le           //
//     gestionnaire d'état accessible à toutes les pages du module de chat.   //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hairbnb/models/current_user.dart';

import '../conversations_list_page.dart';
import '../providers/ai_chat_provider.dart';
import '../services/ai_chat_service.dart';

/// Un "wrapper" qui gère l'initialisation asynchrone et fournit le `AIChatProvider`.
class AIChatWrapper extends StatelessWidget {
  /// L'objet représentant l'utilisateur actuellement connecté.
  final CurrentUser currentUser;

  /// Constructeur du wrapper, nécessitant l'utilisateur actuel.
  const AIChatWrapper({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    // Utilisation d'un `FutureBuilder` pour gérer l'opération asynchrone
    // de récupération du jeton d'authentification Firebase.
    return FutureBuilder<String>(
      // La `future` à résoudre : obtenir le jeton de l'utilisateur Firebase.
      // `getIdToken(true)` force le rafraîchissement du jeton.
      // Des fallbacks sont prévus si l'utilisateur ou le jeton sont nuls.
      future: FirebaseAuth.instance.currentUser?.getIdToken(true).then((token) => token ?? '')
          ?? Future.value(''),

      // Le `builder` est appelé à différents moments du cycle de vie de la future.
      builder: (context, snapshot) {
        // Affiche un indicateur de chargement tant que le jeton n'est pas disponible.
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Une fois le jeton récupéré avec succès.
        final firebaseToken = snapshot.data!;

        // `ChangeNotifierProvider` crée une instance du provider et la rend disponible
        // à tous les widgets descendants dans l'arbre.
        return ChangeNotifierProvider(
          // La fonction `create` est appelée une seule fois pour instancier le provider.
          // On initialise ici le `AIChatService` avec le jeton Firebase récupéré.
          create: (context) => AIChatProvider(
            AIChatService(
              baseUrl: 'https://www.hairbnb.site/api',
              token: firebaseToken,
            ),
          ),
          // Le `child` du provider a accès à l'instance créée.
          child: Consumer<AIChatProvider>(
            builder: (context, provider, _) {
              // `MaterialApp` fournit un contexte de navigation et de thème
              // pour les pages du module de chat.
              return MaterialApp(
                home: ConversationsListPage(currentUser: currentUser),
                debugShowCheckedModeBanner: false,
              );
            },
          ),
        );
      },
    );
  }
}







// // lib/pages/ai_chat/ai_chat_wrapper.dart
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:hairbnb/models/current_user.dart';
//
// import '../conversations_list_page.dart';
// import '../providers/ai_chat_provider.dart';
// import '../services/ai_chat_service.dart';
//
// class AIChatWrapper extends StatelessWidget {
//   final CurrentUser currentUser;
//
//   const AIChatWrapper({super.key, required this.currentUser});
//
//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<String>(
//       future: FirebaseAuth.instance.currentUser?.getIdToken(true).then((token) => token ?? '')
//           ?? Future.value(''),
//
//       builder: (context, snapshot) {
//         if (!snapshot.hasData) {
//           return const Center(child: CircularProgressIndicator());
//         }
//
//         final firebaseToken = snapshot.data!;
//
//         // Utiliser ChangeNotifierProvider.value pour s'assurer que le provider est accessible
//         return ChangeNotifierProvider(
//           create: (context) => AIChatProvider(
//             AIChatService(
//               baseUrl: 'https://www.hairbnb.site/api',
//               token: firebaseToken,
//             ),
//           ),
//           // Assurer que le contexte est correctement transmis
//           child: Consumer<AIChatProvider>(
//             builder: (context, provider, _) {
//               return MaterialApp(
//                 home: ConversationsListPage(currentUser: currentUser),
//                 debugShowCheckedModeBanner: false,
//               );
//             },
//           ),
//         );
//       },
//     );
//   }
// }