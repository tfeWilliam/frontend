////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                PROVIDER POUR LA GESTION DE L'ÉTAT DU CHAT AI                //
//                                                                            //
//  Ce fichier définit `AIChatProvider`, une classe `ChangeNotifier` qui       //
//  sert de gestionnaire d'état central pour toute la fonctionnalité de chat   //
//  avec l'IA. Elle orchestre la communication avec le `AIChatService`         //
//  (la couche d'accès aux données) et notifie l'interface utilisateur des     //
//  changements d'état (chargement, erreurs, nouvelles données).               //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hairbnb/models/ai_chat.dart';

import '../services/ai_chat_service.dart';

/// Un `ChangeNotifier` qui gère l'état et la logique métier du module de chat AI.
class AIChatProvider with ChangeNotifier {
  /// Instance du service qui effectue les appels API réels.
  late final AIChatService _chatService;

  //region État interne du Provider
  /// La liste de toutes les conversations de l'utilisateur.
  List<AIConversation> _conversations = [];
  /// La conversation actuellement ouverte et affichée dans l'interface de chat.
  AIConversation? _activeConversation;
  /// Un booléen pour indiquer si une opération asynchrone est en cours (ex: chargement).
  bool _isLoading = false;
  /// Une chaîne de caractères pour stocker les messages d'erreur à afficher à l'utilisateur.
  String? _error;
  //endregion

  /// Constructeur qui injecte le service de chat, suivant le principe d'injection de dépendances.
  AIChatProvider(this._chatService);

  //region Getters publics
  /// Expose la liste des conversations de manière sécurisée.
  List<AIConversation> get conversations => _conversations;
  /// Expose la conversation active.
  AIConversation? get activeConversation => _activeConversation;
  /// Expose l'état de chargement.
  bool get isLoading => _isLoading;
  /// Expose le message d'erreur actuel.
  String? get error => _error;
  //endregion

  /// Met à jour le jeton d'authentification dans le service sous-jacent.
  void updateToken(String newToken) {
    _chatService.updateToken(newToken);
    notifyListeners();
  }

  /// Charge la liste de toutes les conversations de l'utilisateur depuis le serveur.
  Future<void> loadConversations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _conversations = await _chatService.getConversations();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fonction utilitaire pour nettoyer le texte qui pourrait avoir des problèmes d'encodage.
  /// Tente de corriger les problèmes de type "Mojibake" en ré-encodant depuis latin1 vers utf8.
  String _cleanTextIfNeeded(String text) {
    try {
      // Utiliser latin1 pour encoder puis utf8 pour décoder
      return utf8.decode(latin1.encode(text), allowMalformed: true);
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors du nettoyage du texte: $e");
      }
      return text;  // Retourner le texte original en cas d'erreur
    }
  }


  /// Charge l'historique complet des messages pour une conversation spécifique.
  Future<void> loadConversationMessages(int? conversationId) async {
    // Vérifie que l'ID n'est pas nul avant de continuer.
    if (conversationId == null) {
      _error = "L'ID de conversation ne peut pas être null";
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final conversation = await _chatService.getConversationMessages(conversationId);

      // Définit la conversation chargée comme la conversation active.
      _activeConversation = conversation;

      // Met également à jour cette conversation dans la liste générale pour garder les données synchronisées.
      final index = _conversations.indexWhere((c) => c.id == conversationId);
      if (index != -1) {
        _conversations[index] = conversation;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Crée une nouvelle conversation vide sur le serveur et la définit comme active.
  Future<void> createNewConversation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _activeConversation = await _chatService.createConversation();

      // Insère la nouvelle conversation au début de la liste pour un accès rapide dans l'UI.
      _conversations.insert(0, _activeConversation!);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Supprime une conversation sur le serveur et de l'état local.
  Future<void> deleteConversation(int conversationId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Appel à la couche service pour la suppression côté backend.
      await _chatService.deleteConversation(conversationId);

      // Suppression de la conversation dans la liste locale.
      _conversations.removeWhere((conversation) => conversation.id == conversationId);

      // Si la conversation supprimée était celle qui était active, on la réinitialise pour éviter les erreurs.
      if (_activeConversation != null && _activeConversation!.id == conversationId) {
        _activeConversation = null;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Envoie un message, l'ajoute à la conversation et traite la réponse de l'IA.
  Future<void> sendMessage(String message) async {
    // Si aucune conversation n'est active, en crée une d'abord avant d'envoyer le message.
    if (_activeConversation == null && message.isNotEmpty) {
      await createNewConversation();
    }

    if (_activeConversation != null && message.isNotEmpty) {
      // Crée un message utilisateur temporaire pour une mise à jour "optimiste" de l'UI.
      final tempUserMessage = AIMessage(
        id: -1, // ID temporaire
        content: message,
        isUser: true,
        timestamp: DateTime.now(),
      );

      // Ajoute immédiatement le message de l'utilisateur à l'écran.
      // Le bloc try/catch gère les cas où la liste de messages ne serait pas modifiable.
      try {
        _activeConversation!.messages = List<AIMessage>.from(_activeConversation!.messages)
          ..add(tempUserMessage);
        notifyListeners();
      } catch (e) {
        if (kDebugMode) {
          print("Erreur lors de l'ajout du message: $e");
        }
        // Logique de secours si la première méthode d'ajout échoue.
        var newMessages = <AIMessage>[];
        newMessages.addAll(_activeConversation!.messages);
        newMessages.add(tempUserMessage);
        _activeConversation!.messages = newMessages;
        notifyListeners();
      }

      try {
        // Appelle le service pour envoyer le message et obtenir la réponse de l'IA.
        final response = await _chatService.sendMessage(
          conversationId: _activeConversation!.id,
          message: message,
        );

        // Met à jour le message utilisateur temporaire avec les vraies données du serveur (ID, tokens).
        final userMessageIndex = _activeConversation!.messages.length - 1;
        if (userMessageIndex >= 0) {
          final updatedUserMsg = AIMessage(
            id: response.userMessageId,
            content: message,
            isUser: true,
            timestamp: DateTime.now(),
            tokensIn: response.tokens['input'] ?? 0,
          );

          var updatedMessages = List<AIMessage>.from(_activeConversation!.messages);
          updatedMessages[userMessageIndex] = updatedUserMsg;
          _activeConversation!.messages = updatedMessages;
        }

        // Crée et ajoute le message de réponse de l'IA.
        final aiMessage = AIMessage(
          id: response.aiMessageId,
          content: _cleanTextIfNeeded(response.aiResponse), // Nettoie le texte si nécessaire.
          isUser: false,
          timestamp: DateTime.now(),
          tokensOut: response.tokens['output'] ?? 0,
        );

        var updatedMessages = List<AIMessage>.from(_activeConversation!.messages);
        updatedMessages.add(aiMessage);
        _activeConversation!.messages = updatedMessages;

        // Met à jour le compteur de tokens total pour la conversation.
        _activeConversation!.tokensUsed += ((response.tokens['total'] ?? 0) as num).toInt();

        notifyListeners();
      } catch (e) {
        _error = e.toString();
        notifyListeners();
      }
    }
  }

  /// Définit une conversation existante comme étant la conversation active.
  void setActiveConversation(int? conversationId) {
    if (conversationId == null) {
      _error = "L'ID de conversation ne peut pas être null";
      notifyListeners();
      return;
    }

    final conversationIndex = _conversations.indexWhere((c) => c.id == conversationId);
    if (conversationIndex != -1) {
      _activeConversation = _conversations[conversationIndex];
      // Déclenche le chargement de l'historique des messages pour cette conversation.
      loadConversationMessages(conversationId);
    } else {
      _error = "Conversation non trouvée";
      notifyListeners();
    }
  }

  /// Efface le message d'erreur actuel, ce qui peut être utilisé par l'UI pour masquer une alerte.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}








// // lib/providers/ai_chat_provider.dart
// import 'dart:convert';
//
// import 'package:flutter/foundation.dart';
// import 'package:hairbnb/models/ai_chat.dart';
//
// import '../services/ai_chat_service.dart';
//
// class AIChatProvider with ChangeNotifier {
//   late final AIChatService _chatService;
//
//   List<AIConversation> _conversations = [];
//   AIConversation? _activeConversation;
//   bool _isLoading = false;
//   String? _error;
//
//   AIChatProvider(this._chatService);
//
//   // Getters
//   List<AIConversation> get conversations => _conversations;
//   AIConversation? get activeConversation => _activeConversation;
//   bool get isLoading => _isLoading;
//   String? get error => _error;
//
//   // Mettre à jour le service API
//   void updateToken(String newToken) {
//     _chatService.updateToken(newToken);
//     notifyListeners();
//   }
//
//   // Charger toutes les conversations
//   Future<void> loadConversations() async {
//     _isLoading = true;
//     _error = null;
//     notifyListeners();
//
//     try {
//       _conversations = await _chatService.getConversations();
//       _isLoading = false;
//       notifyListeners();
//     } catch (e) {
//       _error = e.toString();
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
//
//   // Ajouter cette fonction en haut de votre classe
//   String _cleanTextIfNeeded(String text) {
//     try {
//       // Utiliser latin1 pour encoder puis utf8 pour décoder
//       return utf8.decode(latin1.encode(text), allowMalformed: true);
//     } catch (e) {
//       print("Erreur lors du nettoyage du texte: $e");
//       return text;  // Retourner le texte original en cas d'erreur
//     }
//   }
//
//
//   // Charger les messages d'une conversation
//   Future<void> loadConversationMessages(int? conversationId) async {
//     // Vérifier si l'ID est null
//     if (conversationId == null) {
//       _error = "L'ID de conversation ne peut pas être null";
//       _isLoading = false;
//       notifyListeners();
//       return;
//     }
//
//     _isLoading = true;
//     _error = null;
//     notifyListeners();
//
//     try {
//       final conversation = await _chatService.getConversationMessages(conversationId);
//
//       // Mettre à jour la conversation active
//       _activeConversation = conversation;
//
//       // Mettre à jour la conversation dans la liste des conversations
//       final index = _conversations.indexWhere((c) => c.id == conversationId);
//       if (index != -1) {
//         _conversations[index] = conversation;
//       }
//
//       _isLoading = false;
//       notifyListeners();
//     } catch (e) {
//       _error = e.toString();
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
//
//   // Créer une nouvelle conversation
//   // Créer une nouvelle conversation
//   Future<void> createNewConversation() async {
//     _isLoading = true;
//     _error = null;
//     notifyListeners();
//
//     try {
//       _activeConversation = await _chatService.createConversation();
//
//       _conversations.insert(0, _activeConversation!);
//       _isLoading = false;
//       notifyListeners();
//     } catch (e) {
//       _error = e.toString();
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
//
//   // Supprimer une conversation
//   Future<void> deleteConversation(int conversationId) async {
//     _isLoading = true;
//     _error = null;
//     notifyListeners();
//
//     try {
//       // Appeler l'API pour supprimer la conversation
//       await _chatService.deleteConversation(conversationId);
//
//       // Supprimer la conversation de la liste locale
//       _conversations.removeWhere((conversation) => conversation.id == conversationId);
//
//       // Si la conversation active a été supprimée, la réinitialiser
//       if (_activeConversation != null && _activeConversation!.id == conversationId) {
//         _activeConversation = null;
//       }
//
//       _isLoading = false;
//       notifyListeners();
//     } catch (e) {
//       _error = e.toString();
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
//   // Envoyer un message et obtenir une réponse
//   Future<void> sendMessage(String message) async {
//     if (_activeConversation == null && message.isNotEmpty) {
//       await createNewConversation();
//     }
//
//     if (_activeConversation != null && message.isNotEmpty) {
//       // Créer un message temporaire
//       final tempUserMessage = AIMessage(
//         id: -1,
//         content: message,
//         isUser: true,
//         timestamp: DateTime.now(),
//       );
//
//       // Ajouter le message à la conversation active
//       try {
//         // Créer une nouvelle liste modifiable à partir de l'existante
//         _activeConversation!.messages = List<AIMessage>.from(_activeConversation!.messages)
//           ..add(tempUserMessage);
//         notifyListeners();
//       } catch (e) {
//         print("Erreur lors de l'ajout du message: $e");
//         // Si l'erreur persiste, essayer une approche différente
//         var newMessages = <AIMessage>[];
//         newMessages.addAll(_activeConversation!.messages);
//         newMessages.add(tempUserMessage);
//         _activeConversation!.messages = newMessages;
//         notifyListeners();
//       }
//
//       try {
//         // Envoyer le message et recevoir la réponse
//         final response = await _chatService.sendMessage(
//           conversationId: _activeConversation!.id,
//           message: message,
//         );
//
//         // Utiliser la réponse pour mettre à jour les messages
//         // Mettre à jour le message utilisateur avec l'ID réel
//         final userMessageIndex = _activeConversation!.messages.length - 1;
//         if (userMessageIndex >= 0) {
//           final updatedUserMsg = AIMessage(
//             id: response.userMessageId,
//             content: message,
//             isUser: true,
//             timestamp: DateTime.now(),
//             tokensIn: response.tokens['input'] ?? 0,
//           );
//
//           // Créer une nouvelle liste pour la mise à jour
//           var updatedMessages = List<AIMessage>.from(_activeConversation!.messages);
//           updatedMessages[userMessageIndex] = updatedUserMsg;
//           _activeConversation!.messages = updatedMessages;
//         }
//
//         // Ajouter la réponse de l'IA
//         final aiMessage = AIMessage(
//           id: response.aiMessageId,
//           content: _cleanTextIfNeeded(response.aiResponse),  // Nettoyage appliqué ici
//           isUser: false,
//           timestamp: DateTime.now(),
//           tokensOut: response.tokens['output'] ?? 0,
//         );
//
//         // Créer une nouvelle liste pour l'ajout
//         var updatedMessages = List<AIMessage>.from(_activeConversation!.messages);
//         updatedMessages.add(aiMessage);
//         _activeConversation!.messages = updatedMessages;
//
//         // Mettre à jour le nombre total de tokens
//         _activeConversation!.tokensUsed += ((response.tokens['total'] ?? 0) as num).toInt();
//
//         notifyListeners();
//       } catch (e) {
//         _error = e.toString();
//         notifyListeners();
//       }
//     }
//
//   }
//
//
//   // Définir la conversation active
//   void setActiveConversation(int? conversationId) {
//     if (conversationId == null) {
//       _error = "L'ID de conversation ne peut pas être null";
//       notifyListeners();
//       return;
//     }
//
//     final conversationIndex = _conversations.indexWhere((c) => c.id == conversationId);
//     if (conversationIndex != -1) {
//       _activeConversation = _conversations[conversationIndex];
//       loadConversationMessages(conversationId);
//     } else {
//       _error = "Conversation non trouvée";
//       notifyListeners();
//     }
//   }
//
//   // Ajouter cette méthode qui était manquante
//   void clearError() {
//     _error = null;
//     notifyListeners();
//   }
// }