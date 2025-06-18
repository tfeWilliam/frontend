/// **************************************************************************************
///
/// SERVICE API : GESTION DU CHAT IA POUR COIFFEUSE
/// Fichier: lib/pages/ai_chat/services/coiffeuse_ai_chat_service.dart
///
/// OBJECTIF :
/// Cette classe est une couche de service dédiée à la communication avec les points de
/// terminaison (endpoints) de l'API spécifiques à l'assistant IA pour les coiffeuses.
/// Elle gère la construction des requêtes HTTP, l'authentification, et la
/// sérialisation/désérialisation des données JSON vers les modèles Dart correspondants.
///
/// FONCTIONNALITÉS CLÉS :
/// - Gère les opérations CRUD complètes pour les conversations (Créer, Lire, Supprimer).
/// - Gère l'envoi de messages et la réception des réponses de l'IA.
/// - Gère l'authentification via un Bearer Token qui peut être mis à jour.
/// - Utilise des modèles de données spécifiques au contexte "Coiffeuse"
/// (ex: `CoiffeuseConversationItem`).
///
///***************************************************************************************
library;
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../models/ai_chat_coiffeuse.dart';

/// Classe de service pour interagir avec l'API du chat IA, spécifique à la coiffeuse.
class CoiffeuseAIChatService {
  /// L'URL de base de l'API.
  final String baseUrl;
  /// Le token d'authentification pour les requêtes.
  String token;

  /// Constructeur du service.
  CoiffeuseAIChatService({
    required this.baseUrl,
    required this.token,
  });

  /// Met à jour le token d'authentification utilisé pour les requêtes.
  void updateToken(String newToken) {
    token = newToken;
  }

  /// Getter privé qui construit les en-têtes HTTP requis pour chaque requête authentifiée.
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  /// Récupère la liste de toutes les conversations de la coiffeuse.
  ///
  /// Retourne un `Future<List<CoiffeuseConversationItem>>`.
  /// Lance une [Exception] en cas d'échec de la requête.
  Future<List<CoiffeuseConversationItem>> getConversations() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/coiffeuse/ai/conversations/'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        // Décode la réponse en utilisant UTF-8 pour gérer les caractères spéciaux.
        final String decodedResponse = utf8.decode(response.bodyBytes);
        final List<dynamic> jsonData = json.decode(decodedResponse);

        // L'API retourne directement une liste, on la mappe à nos objets Dart.
        return jsonData.map((item) => CoiffeuseConversationItem.fromJson(item)).toList();
      } else {
        throw Exception('Erreur lors de la récupération des conversations: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération des conversations: $e');
    }
  }

  /// Récupère tous les messages d'une conversation spécifique de la coiffeuse.
  ///
  /// [conversationId] : L'ID de la conversation à récupérer.
  /// Retourne un `Future<CoiffeuseConversationDetail>`.
  /// Lance une [Exception] si [conversationId] est nul ou si la requête échoue.
  Future<CoiffeuseConversationDetail> getConversationMessages(int? conversationId) async {
    if (conversationId == null) {
      throw Exception('L\'ID de conversation ne peut pas être null');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/coiffeuse/ai/conversations/$conversationId/messages/'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final String decodedResponse = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> jsonData = json.decode(decodedResponse);
        return CoiffeuseConversationDetail.fromJson(jsonData);
      } else {
        throw Exception('Erreur lors de la récupération des messages: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération des messages: $e');
    }
  }

  /// Crée une nouvelle conversation vide sur le serveur pour la coiffeuse.
  ///
  /// Retourne un `Future<CoiffeuseConversationCreate>` avec les détails de la conversation créée.
  Future<CoiffeuseConversationCreate> createConversation() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/coiffeuse/ai/conversations/create/'),
        headers: _headers,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final String decodedResponse = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> jsonData = json.decode(decodedResponse);
        return CoiffeuseConversationCreate.fromJson(jsonData);
      } else {
        throw Exception('Erreur lors de la création de la conversation: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la création de la conversation: $e');
    }
  }

  /// Envoie un message à une conversation et récupère la réponse de l'IA.
  ///
  /// [conversationId] : L'ID de la conversation où envoyer le message.
  /// [message] : Le contenu du message de la coiffeuse.
  /// Retourne un `Future<CoiffeuseMessageResponse>` contenant la réponse de l'IA.
  Future<CoiffeuseMessageResponse> sendMessage({
    int? conversationId,
    required String message,
  }) async {
    try {
      final request = CoiffeuseMessageRequest(
        conversationId: conversationId,
        message: message,
      );

      final response = await http.post(
        Uri.parse('$baseUrl/coiffeuse/ai/messages/send/'),
        headers: _headers,
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> jsonData = json.decode(responseBody);
        return CoiffeuseMessageResponse.fromJson(jsonData);
      } else {
        throw Exception('Erreur lors de l\'envoi du message: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi du message: $e');
    }
  }

  /// Supprime une conversation de la coiffeuse sur le serveur.
  ///
  /// [conversationId] : L'ID de la conversation à supprimer.
  /// Ne retourne rien en cas de succès, mais lance une [Exception] en cas d'échec.
  Future<void> deleteConversation(int conversationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/coiffeuse/ai/conversations/$conversationId/delete/'),
        headers: _headers,
      );

      // Une suppression réussie peut retourner 200 OK ou 204 No Content.
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Erreur lors de la suppression de la conversation: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la conversation: $e');
    }
  }
}






// // lib/pages/ai_chat/services/coiffeuse_ai_chat_service.dart
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../../../models/ai_chat_coiffeuse.dart';
//
// class CoiffeuseAIChatService {
//   final String baseUrl;
//   String token;
//
//   CoiffeuseAIChatService({
//     required this.baseUrl,
//     required this.token,
//   });
//
//   // Mettre à jour le token si nécessaire
//   void updateToken(String newToken) {
//     token = newToken;
//   }
//
//   // Headers pour les requêtes
//   Map<String, String> get _headers => {
//     'Content-Type': 'application/json',
//     'Authorization': 'Bearer $token',
//   };
//
//   /// Récupérer toutes les conversations de la coiffeuse
//   Future<List<CoiffeuseConversationItem>> getConversations() async {
//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl/coiffeuse/ai/conversations/'),
//         headers: _headers,
//       );
//
//       if (response.statusCode == 200) {
//         final String decodedResponse = utf8.decode(response.bodyBytes);
//         final List<dynamic> jsonData = json.decode(decodedResponse);
//
//         // Le backend retourne directement une liste de conversations
//         return jsonData.map((item) => CoiffeuseConversationItem.fromJson(item)).toList();
//       } else {
//         throw Exception('Erreur lors de la récupération des conversations: ${response.body}');
//       }
//     } catch (e) {
//       print("Erreur dans getConversations: $e");
//       throw Exception('Erreur lors de la récupération des conversations: $e');
//     }
//   }
//
//   /// Récupérer les messages d'une conversation spécifique
//   Future<CoiffeuseConversationDetail> getConversationMessages(int? conversationId) async {
//     print("getConversationMessages appelé avec id: $conversationId");
//
//     if (conversationId == null) {
//       print("ERREUR: conversationId est null dans getConversationMessages");
//       throw Exception('L\'ID de conversation ne peut pas être null');
//     }
//
//     try {
//       print("Tentative de récupération des messages pour conversation $conversationId");
//       final response = await http.get(
//         Uri.parse('$baseUrl/coiffeuse/ai/conversations/$conversationId/messages/'),
//         headers: _headers,
//       );
//
//       if (response.statusCode == 200) {
//         final String decodedResponse = utf8.decode(response.bodyBytes);
//         final Map<String, dynamic> jsonData = json.decode(decodedResponse);
//
//         return CoiffeuseConversationDetail.fromJson(jsonData);
//       } else {
//         print("Erreur HTTP ${response.statusCode}: ${response.body}");
//         throw Exception('Erreur lors de la récupération des messages: ${response.body}');
//       }
//     } catch (e) {
//       print("Exception dans getConversationMessages: $e");
//       throw Exception('Erreur lors de la récupération des messages: $e');
//     }
//   }
//
//   /// Créer une nouvelle conversation
//   Future<CoiffeuseConversationCreate> createConversation() async {
//     try {
//       final response = await http.post(
//         Uri.parse('$baseUrl/coiffeuse/ai/conversations/create/'),
//         headers: _headers,
//       );
//
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         final String decodedResponse = utf8.decode(response.bodyBytes);
//         final Map<String, dynamic> jsonData = json.decode(decodedResponse);
//
//         return CoiffeuseConversationCreate.fromJson(jsonData);
//       } else {
//         print("Erreur HTTP ${response.statusCode} lors de la création de conversation: ${response.body}");
//         throw Exception('Erreur lors de la création de la conversation: ${response.body}');
//       }
//     } catch (e) {
//       print("Exception dans createConversation: $e");
//       throw Exception('Erreur lors de la création de la conversation: $e');
//     }
//   }
//
//   /// Envoyer un message et obtenir une réponse de l'IA
//   Future<CoiffeuseMessageResponse> sendMessage({
//     int? conversationId,
//     required String message,
//   }) async {
//     try {
//       final request = CoiffeuseMessageRequest(
//         conversationId: conversationId,
//         message: message,
//       );
//
//       final response = await http.post(
//         Uri.parse('$baseUrl/coiffeuse/ai/messages/send/'),
//         headers: _headers,
//         body: json.encode(request.toJson()),
//       );
//
//       if (response.statusCode == 200) {
//         final String responseBody = utf8.decode(response.bodyBytes);
//         final Map<String, dynamic> jsonData = json.decode(responseBody);
//
//         return CoiffeuseMessageResponse.fromJson(jsonData);
//       } else {
//         throw Exception('Erreur lors de l\'envoi du message: ${response.body}');
//       }
//     } catch (e) {
//       print("Erreur dans sendMessage: $e");
//       throw Exception('Erreur lors de l\'envoi du message: $e');
//     }
//   }
//
//   /// Supprimer une conversation
//   Future<void> deleteConversation(int conversationId) async {
//     try {
//       final response = await http.delete(
//         Uri.parse('$baseUrl/coiffeuse/ai/conversations/$conversationId/delete/'),
//         headers: _headers,
//       );
//
//       if (response.statusCode != 200 && response.statusCode != 204) {
//         throw Exception('Erreur lors de la suppression de la conversation: ${response.body}');
//       }
//     } catch (e) {
//       print("Erreur dans deleteConversation: $e");
//       throw Exception('Erreur lors de la suppression de la conversation: $e');
//     }
//   }
// }