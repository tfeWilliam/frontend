/// *****************************************************************************
///
/// FOURNISSEUR D'ÉTAT POUR LE CHAT IA (CoiffeuseAIChatProvider)
///
/// Ce fichier définit la classe `CoiffeuseAIChatProvider`, qui sert de gestionnaire
/// d'état central pour la fonctionnalité de chat avec une intelligence artificielle
/// côté "coiffeuse".
///
/// RÔLE ET RESPONSABILITÉS :
/// 1.  **Gestion d'état complète** : Il maintient l'état complet du chat, incluant
/// la liste de toutes les conversations, la conversation actuellement active
/// avec ses messages, les indicateurs de chargement (`isLoading`, `isSendingMessage`)
/// et les éventuels messages d'erreur.
///
/// 2.  **Orchestration des services** : Il agit comme un intermédiaire entre l'UI
/// et le `CoiffeuseAIChatService`. Il utilise ce service (injecté en dépendance)
/// pour effectuer les appels API nécessaires (charger, créer, supprimer, envoyer).
///
/// 3.  **Logique métier** : Il implémente la logique métier du chat, comme la mise
/// à jour optimiste de l'UI lors de l'envoi d'un message pour une meilleure
/// réactivité, et la gestion des cas d'erreur.
///
/// 4.  **Notification de l'UI** : En tant que `ChangeNotifier`, il notifie tous
/// les widgets qui l'écoutent dès qu'une modification de son état interne
/// se produit, assurant ainsi la mise à jour de l'interface utilisateur.
///
///*****************************************************************************
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/ai_chat_coiffeuse.dart';
import '../../pages/ai_chat/services/coiffeuse_ai_chat_service.dart';

class CoiffeuseAIChatProvider with ChangeNotifier {
  // Le service qui gère les appels directs à l'API de chat.
  late final CoiffeuseAIChatService _chatService;

  // État interne du provider
  List<CoiffeuseConversationItem> _conversations = [];
  CoiffeuseConversationDetail? _activeConversation;
  bool _isLoading = false;
  bool _isSendingMessage = false;
  String? _error;

  /// Constructeur qui requiert une instance du service de chat.
  CoiffeuseAIChatProvider(this._chatService);

  // Getters publics pour accéder à l'état de manière sécurisée (lecture seule).
  List<CoiffeuseConversationItem> get conversations => _conversations;
  CoiffeuseConversationDetail? get activeConversation => _activeConversation;
  bool get isLoading => _isLoading;
  bool get isSendingMessage => _isSendingMessage;
  String? get error => _error;

  /// Met à jour le jeton d'authentification dans le service sous-jacent.
  void updateToken(String newToken) {
    _chatService.updateToken(newToken);
    notifyListeners();
  }

  /// Charge la liste de toutes les conversations associées à la coiffeuse.
  Future<void> loadConversations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _conversations = await _chatService.getConversations();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charge les messages d'une conversation spécifique et la définit comme active.
  Future<void> loadConversationMessages(int? conversationId) async {
    if (conversationId == null) {
      _error = "L'ID de conversation ne peut pas être null";
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _activeConversation = await _chatService.getConversationMessages(conversationId);

      // Met à jour l'aperçu de la conversation dans la liste principale.
      final index = _conversations.indexWhere((c) => c.id == conversationId);
      if (index != -1) {
        // Met à jour le titre avec le début du premier message pour un aperçu.
        _conversations[index] = CoiffeuseConversationItem(
          id: _activeConversation!.id,
          createdAt: _activeConversation!.createdAt,
          tokensUsed: _conversations[index].tokensUsed,
          title: _activeConversation!.messages.isNotEmpty
              ? _activeConversation!.messages.first.content.length > 50
              ? '${_activeConversation!.messages.first.content.substring(0, 50)}...'
              : _activeConversation!.messages.first.content
              : 'Nouvelle Conversation',
        );
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Crée une nouvelle conversation vide sur le serveur et dans l'état local.
  Future<CoiffeuseConversationDetail?> createNewConversation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (kDebugMode) {
        print("Début création nouvelle conversation");
      }
      final newConversation = await _chatService.createConversation();
      if (kDebugMode) {
        print("Conversation créée côté serveur - ID: ${newConversation.id}");
      }

      // Prépare une conversation détaillée vide pour l'UI.
      _activeConversation = CoiffeuseConversationDetail(
        id: newConversation.id,
        userId: 0,
        createdAt: newConversation.createdAt,
        messages: [],
      );
      if (kDebugMode) {
        print("_activeConversation définie avec ID: ${_activeConversation!.id}");
      }

      // Crée un item pour la liste des conversations.
      final conversationItem = CoiffeuseConversationItem(
        id: newConversation.id,
        createdAt: newConversation.createdAt,
        tokensUsed: 0,
        title: 'Nouvelle Conversation',
      );

      // Ajoute la nouvelle conversation au début de la liste pour un accès rapide.
      _conversations.insert(0, conversationItem);
      if (kDebugMode) {
        print("Conversation ajoutée à la liste");
      }

      _isLoading = false;
      notifyListeners();

      return _activeConversation;
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors de la création de conversation: $e");
      }
      _error = e.toString();
      _isLoading = false;
      _activeConversation = null;
      notifyListeners();
      return null;
    }
  }

  /// Méthode de commodité qui crée une conversation puis navigue vers son écran.
  Future<void> createNewConversationAndNavigate(BuildContext context) async {
    final newConversation = await createNewConversation();
    if (newConversation != null) {
      Navigator.pushNamed(
          context,
          '/coiffeuse/ai/chat/${newConversation.id}'
      );
    }
  }

  /// Supprime une conversation sur le serveur et de l'état local.
  Future<void> deleteConversation(int conversationId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _chatService.deleteConversation(conversationId);
      _conversations.removeWhere((conversation) => conversation.id == conversationId);

      // Si la conversation supprimée était active, on la désactive localement.
      if (_activeConversation != null && _activeConversation!.id == conversationId) {
        _activeConversation = null;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Envoie un message dans la conversation active.
  /// Gère la création de conversation si aucune n'est active.
  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Si aucune conversation n'est active, en crée une nouvelle d'abord.
    if (_activeConversation == null) {
      await createNewConversation();
      if (_activeConversation == null) return; // Échoue si la création a échoué.
    }

    _isSendingMessage = true;
    _error = null;
    notifyListeners();

    // 1. Mise à jour optimiste : ajoute le message de l'utilisateur à l'UI instantanément.
    final tempUserMessage = CoiffeuseMessage(
      id: -1, // ID temporaire pour l'identifier.
      content: message,
      isUser: true,
      timestamp: DateTime.now(),
    );
    _activeConversation!.messages.add(tempUserMessage);
    notifyListeners();


    try {
      // 2. Appel au service pour envoyer le message et obtenir la réponse de l'IA.
      await _chatService.sendMessage(
        conversationId: _activeConversation!.id,
        message: message,
      );

      // 3. Recharge la conversation pour obtenir les messages finaux (avec les bons ID et la réponse de l'IA).
      await loadConversationMessages(_activeConversation!.id);
    } catch (e) {
      _error = e.toString();
      // En cas d'erreur, supprime le message temporaire de l'UI.
      if (_activeConversation != null && _activeConversation!.messages.isNotEmpty) {
        _activeConversation!.messages.removeWhere((msg) => msg.id == -1);
      }
    } finally {
      _isSendingMessage = false;
      notifyListeners();
    }
  }

  /// Définit une conversation comme étant l'active.
  void setActiveConversation(int? conversationId) {
    if (conversationId == null) {
      _error = "L'ID de conversation ne peut pas être null";
      notifyListeners();
      return;
    }

    final conversationIndex = _conversations.indexWhere((c) => c.id == conversationId);
    if (conversationIndex != -1) {
      // Réinitialise d'abord la conversation active avant d'en charger une nouvelle.
      _activeConversation = null;
      notifyListeners();
      loadConversationMessages(conversationId);
    } else {
      _error = "Conversation non trouvée";
      notifyListeners();
    }
  }

  /// Efface le message d'erreur actuel.
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Réinitialise la conversation active, utile en quittant un écran de chat.
  void clearActiveConversation() {
    _activeConversation = null;
    notifyListeners();
  }

  /// Recherche et retourne une conversation par son ID depuis la liste locale.
  CoiffeuseConversationItem? getConversationById(int id) {
    try {
      return _conversations.firstWhere((conv) => conv.id == id);
    } catch (e) {
      return null;
    }
  }

  // Getters de commodité pour vérifier l'état.
  bool get hasConversations => _conversations.isNotEmpty;
  bool get hasActiveConversation => _activeConversation != null;
  int get activeConversationMessageCount => _activeConversation?.messages.length ?? 0;
}
