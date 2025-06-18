/****************************************************************************************
 *
 * SERVICE API : GESTION DU CHAT AVEC L'IA
 * Fichier: lib/services/ai_chat_service.dart
 *
 * OBJECTIF :
 * Cette classe est une couche de service dédiée à la communication avec l'API backend
 * pour toutes les fonctionnalités liées au chat avec l'intelligence artificielle.
 * Elle abstrait la logique des appels HTTP (GET, POST, DELETE) et la gestion des
 * données (sérialisation/désérialisation JSON) du reste de l'application.
 *
 * FONCTIONNALITÉS CLÉS :
 * - Gère l'authentification via un Bearer Token qui peut être mis à jour.
 * - Fournit des méthodes pour les opérations CRUD sur les conversations (créer, lire, supprimer).
 * - Gère l'envoi de messages et la réception des réponses de l'IA.
 * - Inclut une gestion robuste des erreurs et du décodage des caractères (UTF-8).
 *
 *****************************************************************************************/
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hairbnb/models/ai_chat.dart';

/// Classe de service pour interagir avec l'API du chat IA.
class AIChatService {
  /// L'URL de base de l'API.
  final String baseUrl;
  /// Le token d'authentification pour les requêtes.
  String token;

  /// Constructeur du service.
  AIChatService({
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

  /// Récupère la liste de toutes les conversations de l'utilisateur.
  ///
  /// Retourne un `Future<List<AIConversation>>`.
  /// Lance une [Exception] en cas d'échec de la requête.
  Future<List<AIConversation>> getConversations() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/conversations/'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        // Décode la réponse en utilisant UTF-8 pour gérer les caractères spéciaux.
        final String decodedResponse = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> jsonData = json.decode(decodedResponse);
        final conversationsList = ConversationsList.fromJson(jsonData);
        return conversationsList.conversations;
      } else {
        throw Exception('Erreur lors de la récupération des conversations: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération des conversations: $e');
    }
  }

  /// Récupère tous les messages d'une conversation spécifique.
  ///
  /// [conversationId] : L'ID de la conversation à récupérer.
  /// Retourne un `Future<AIConversation>` contenant les détails et les messages.
  /// Lance une [Exception] si [conversationId] est nul ou si la requête échoue.
  Future<AIConversation> getConversationMessages(int? conversationId) async {
    if (conversationId == null) {
      throw Exception('L\'ID de conversation ne peut pas être null');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/conversations/$conversationId/messages/'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final String decodedResponse = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> jsonData = json.decode(decodedResponse);

        // Mesure corrective : si l'API ne retourne pas l'ID dans la réponse,
        // on l'ajoute manuellement pour assurer un parsing correct de l'objet.
        if (!jsonData.containsKey('id')) {
          jsonData['id'] = conversationId;
        }
        return AIConversation.fromJson(jsonData);
      } else {
        throw Exception('Erreur lors de la récupération des messages: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération des messages: $e');
    }
  }

  /// Crée une nouvelle conversation vide sur le serveur.
  ///
  /// Retourne un `Future<AIConversation>` représentant la conversation nouvellement créée.
  Future<AIConversation> createConversation() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/conversations/create/'),
        headers: _headers,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final String decodedResponse = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> jsonData = json.decode(decodedResponse);

        if (jsonData['conversation_id'] == null) {
          throw Exception('ID de conversation manquant dans la réponse');
        }
        // Construit manuellement l'objet AIConversation avec les données essentielles de la réponse.
        return AIConversation(
          id: jsonData['conversation_id'],
          createdAt: DateTime.parse(jsonData['created_at'] ?? DateTime.now().toIso8601String()),
        );
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
  /// [message] : Le contenu du message de l'utilisateur.
  /// Retourne un `Future<SendMessageResponse>` contenant la réponse de l'IA.
  Future<SendMessageResponse> sendMessage({
    int? conversationId,
    required String message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/messages/send/'),
        headers: _headers,
        body: json.encode({
          'conversation_id': conversationId,
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> jsonData = json.decode(responseBody);
        return SendMessageResponse.fromJson(jsonData);
      } else {
        throw Exception('Erreur lors de l\'envoi du message: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi du message: $e');
    }
  }

  /// Supprime une conversation sur le serveur.
  ///
  /// [conversationId] : L'ID de la conversation à supprimer.
  /// Ne retourne rien en cas de succès, mais lance une [Exception] en cas d'échec.
  Future<void> deleteConversation(int conversationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/delconversations/$conversationId/'),
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







// // lib/services/ai_chat_service.dart
// import 'dart:convert';
// import 'package:http/http.dart' as http;
//
// // Changez l'import pour utiliser un chemin absolu
// import 'package:hairbnb/models/ai_chat.dart';
//
// class AIChatService {
//   final String baseUrl;
//   String token;
//
//   AIChatService({
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
//
//     'Content-Type': 'application/json',
//     'Authorization': 'Bearer $token',
//   };
//
//   /// Récupérer toutes les conversations
//   Future<List<AIConversation>> getConversations() async {
//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl/conversations/'),
//         headers: _headers,
//       );
//
//       if (response.statusCode == 200) {
//         // final Map<String, dynamic> jsonData = json.decode(response.body);
//         // final conversationsList = ConversationsList.fromJson(jsonData);
//
//         final String decodedResponse = utf8.decode(response.bodyBytes);
//         final Map<String, dynamic> jsonData = json.decode(decodedResponse);
//         final conversationsList = ConversationsList.fromJson(jsonData);
//
//         return conversationsList.conversations;
//       } else {
//         throw Exception('Erreur lors de la récupération des conversations: ${response.body}');
//       }
//     } catch (e) {
//       print("Erreur dans getConversations: $e");
//       throw Exception('Erreur lors de la récupération des conversations: $e');
//     }
//   }
//
//   Future<AIConversation> getConversationMessages(int? conversationId) async {
//
//     // Ajouter plus de logs pour déboguer
//     print("getConversationMessages appelé avec id: $conversationId");
//
//     // Vérification de la valeur null
//     if (conversationId == null) {
//       print("ERREUR: conversationId est null dans getConversationMessages");
//       throw Exception('L\'ID de conversation ne peut pas être null');
//     }
//
//     try {
//       print("Tentative de récupération des messages pour conversation $conversationId");
//       final response = await http.get(
//         Uri.parse('$baseUrl/conversations/$conversationId/messages/'),
//         headers: _headers,
//       );
//
//       if (response.statusCode == 200) {
//         // final Map<String, dynamic> jsonData = json.decode(response.body);
//
//         final String decodedResponse = utf8.decode(response.bodyBytes);
//         final Map<String, dynamic> jsonData = json.decode(decodedResponse);
//
//         // Vérifier si l'ID est présent dans la réponse
//         if (!jsonData.containsKey('id')) {
//           print("ATTENTION: La réponse JSON ne contient pas de champ 'id'");
//           jsonData['id'] = conversationId; // Ajouter l'ID manuellement
//         }
//         return AIConversation.fromJson(jsonData);
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
//   Future<AIConversation> createConversation() async {
//     try {
//       final response = await http.post(
//         Uri.parse('$baseUrl/conversations/create/'),
//         headers: _headers,
//       );
//
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         //final Map<String, dynamic> jsonData = json.decode(response.body);
//
//         final String decodedResponse = utf8.decode(response.bodyBytes);
//         final Map<String, dynamic> jsonData = json.decode(decodedResponse);
//
//         // Ajouter une vérification pour le champ 'conversation_id'
//         if (jsonData['conversation_id'] == null) {
//           print("ERREUR: La réponse de création de conversation ne contient pas d'ID");
//           throw Exception('ID de conversation manquant dans la réponse');
//         }
//         return AIConversation(
//           id: jsonData['conversation_id'],
//           createdAt: DateTime.parse(jsonData['created_at'] ?? DateTime.now().toIso8601String()),
//         );
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
//   /// Envoyer un message et obtenir une réponse
//   Future<SendMessageResponse> sendMessage({
//     int? conversationId,
//     required String message,
//   }) async {
//     try {
//       final response = await http.post(
//         Uri.parse('$baseUrl/messages/send/'),
//         headers: _headers,
//         body: json.encode({
//           'conversation_id': conversationId,
//           'message': message,
//         }),
//       );
//
//       if (response.statusCode == 200) {
//         // Utiliser bodyBytes avec utf8.decode pour un décodage correct
//         final String responseBody = utf8.decode(response.bodyBytes);
//
//         // Décodage du JSON avec la réponse correctement décodée
//         final Map<String, dynamic> jsonData = json.decode(responseBody);
//
//         return SendMessageResponse.fromJson(jsonData);
//       } else {
//         throw Exception('Erreur lors de l\'envoi du message: ${response.body}');
//       }
//     } catch (e) {
//       print("Erreur dans sendMessage: $e");
//       throw Exception('Erreur lors de l\'envoi du message: $e');
//     }
//   }
//
//
//   /// Supprimer une conversation
//   Future<void> deleteConversation(int conversationId) async {
//     try {
//       final response = await http.delete(
//         Uri.parse('$baseUrl/delconversations/$conversationId/'),
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