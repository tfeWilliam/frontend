////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//          MODÈLES DE DONNÉES POUR LE CHAT AI CÔTÉ COIFFEUSE                   //
//                                                                            //
//  Ce fichier définit les classes Dart nécessaires pour modéliser les        //
//  interactions avec le service de chat AI spécifiquement pour les coiffeuses.//
//  Chaque classe correspond à une structure de données précise échangée avec  //
//  l'API du backend.                                                         //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

import 'dart:convert';

//##############################################################################
//#             MODÈLE POUR UN ITEM DANS LA LISTE DES CONVERSATIONS            #
//##############################################################################

/// Représente un aperçu d'une conversation dans une liste.
/// Ce modèle est léger et conçu pour un affichage efficace.
/// Il correspond à la réponse de l'endpoint `get_coiffeuse_conversations`.
class CoiffeuseConversationItem {
  /// L'identifiant unique de la conversation.
  final int id;
  /// La date et l'heure de création de la conversation.
  final DateTime createdAt;
  /// Le nombre de jetons (tokens) utilisés dans la conversation.
  final int tokensUsed;
  /// Le titre ou le début de la conversation pour l'identifier.
  final String title;

  /// Constructeur pour créer une instance de `CoiffeuseConversationItem`.
  CoiffeuseConversationItem({
    required this.id,
    required this.createdAt,
    required this.tokensUsed,
    required this.title,
  });

  /// Factory constructor pour créer une instance à partir d'un map JSON.
  factory CoiffeuseConversationItem.fromJson(Map<String, dynamic> json) {
    return CoiffeuseConversationItem(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      tokensUsed: json['tokens_used'] ?? 0,
      title: json['title'] ?? 'Nouvelle Conversation',
    );
  }

  /// Convertit l'instance en un map JSON.
  Map<String, dynamic> toJson() => {
    'id': id,
    'created_at': createdAt.toIso8601String(),
    'tokens_used': tokensUsed,
    'title': title,
  };
}


//##############################################################################
//#              MODÈLE POUR UNE CONVERSATION DÉTAILLÉE AVEC MESSAGES          #
//##############################################################################

/// Représente une conversation complète avec l'historique de ses messages.
/// Correspond à la réponse de l'endpoint `get_coiffeuse_conversation_messages`.
class CoiffeuseConversationDetail {
  /// L'identifiant unique de la conversation.
  final int id;
  /// L'identifiant de l'utilisateur à qui appartient la conversation.
  final int userId;
  /// La date et l'heure de création de la conversation.
  final DateTime createdAt;
  /// La liste des messages de la conversation.
  List<CoiffeuseMessage> messages;

  /// Constructeur pour créer une instance de `CoiffeuseConversationDetail`.
  CoiffeuseConversationDetail({
    required this.id,
    required this.userId,
    required this.createdAt,
    this.messages = const [],
  });

  /// Factory constructor pour créer une instance à partir d'un map JSON.
  factory CoiffeuseConversationDetail.fromJson(Map<String, dynamic> json) {
    return CoiffeuseConversationDetail(
      id: json['id'],
      userId: json['user_id'],
      createdAt: DateTime.parse(json['created_at']),
      // Crée une liste de CoiffeuseMessage à partir des données JSON.
      messages: json['messages'] != null
          ? List<CoiffeuseMessage>.from(json['messages'].map((x) => CoiffeuseMessage.fromJson(x)))
          : [],
    );
  }

  /// Convertit l'instance en un map JSON, incluant la liste des messages.
  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'created_at': createdAt.toIso8601String(),
    'messages': messages.map((x) => x.toJson()).toList(),
  };
}


//##############################################################################
//#                          MODÈLE POUR UN MESSAGE INDIVIDUEL                 #
//##############################################################################

/// Représente un message unique au sein d'une conversation.
/// Correspond au `AIMessageSerializer` du backend.
class CoiffeuseMessage {
  /// L'identifiant unique du message.
  final int id;
  /// Le contenu textuel du message.
  final String content;
  /// `true` si le message vient de l'utilisateur, `false` si c'est une réponse de l'IA.
  final bool isUser;
  /// La date et l'heure de création du message.
  final DateTime timestamp;

  /// Constructeur pour créer une instance de `CoiffeuseMessage`.
  CoiffeuseMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
  });

  /// Factory constructor pour créer une instance à partir d'un map JSON.
  factory CoiffeuseMessage.fromJson(Map<String, dynamic> json) {
    return CoiffeuseMessage(
      id: json['id'],
      content: json['content'],
      isUser: json['is_user'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  /// Convertit l'instance en un map JSON.
  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'is_user': isUser,
    'timestamp': timestamp.toIso8601String(),
  };
}


//##############################################################################
//#               MODÈLE POUR LA RÉPONSE À LA CRÉATION DE CONVERSATION         #
//##############################################################################

/// Représente la réponse du serveur après la création d'une nouvelle conversation.
/// Correspond à la réponse de l'endpoint `create_coiffeuse_conversation`.
class CoiffeuseConversationCreate {
  /// L'identifiant de la nouvelle conversation créée.
  final int id;
  /// La date de création de la conversation.
  final DateTime createdAt;

  /// Constructeur pour créer une instance de `CoiffeuseConversationCreate`.
  CoiffeuseConversationCreate({
    required this.id,
    required this.createdAt,
  });

  /// Factory constructor pour créer une instance à partir d'un map JSON.
  factory CoiffeuseConversationCreate.fromJson(Map<String, dynamic> json) {
    return CoiffeuseConversationCreate(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  /// Convertit l'instance en un map JSON.
  Map<String, dynamic> toJson() => {
    'id': id,
    'created_at': createdAt.toIso8601String(),
  };
}


//##############################################################################
//#               MODÈLE POUR LA RÉPONSE À L'ENVOI D'UN MESSAGE                #
//##############################################################################

/// Représente la réponse du serveur après l'envoi d'un message à l'IA.
/// Correspond à la réponse de l'endpoint `send_coiffeuse_message`.
class CoiffeuseMessageResponse {
  /// L'ID de la conversation dans laquelle le message a été envoyé.
  final int conversationId;
  /// Le contenu textuel de la réponse de l'IA.
  final String aiResponse;
  /// Un map contenant les informations sur les jetons (tokens) utilisés.
  final Map<String, dynamic> tokens;

  /// Constructeur pour créer une instance de `CoiffeuseMessageResponse`.
  CoiffeuseMessageResponse({
    required this.conversationId,
    required this.aiResponse,
    required this.tokens,
  });

  /// Factory constructor pour créer une instance à partir d'un map JSON.
  /// Gère différents formats possibles pour la réponse de l'IA.
  factory CoiffeuseMessageResponse.fromJson(Map<String, dynamic> json) {
    String responseText;
    // La réponse de l'API peut être une chaîne de caractères directe...
    if (json['ai_response'] is String) {
      responseText = json['ai_response'];
    }
    // ...ou une liste d'octets qu'il faut décoder en UTF-8.
    else if (json['ai_response'] is List<int>) {
      responseText = utf8.decode(json['ai_response']);
    }
    // Cas de secours pour éviter les erreurs de type.
    else {
      responseText = json['ai_response'].toString();
    }

    return CoiffeuseMessageResponse(
      conversationId: json['conversation_id'],
      aiResponse: responseText,
      tokens: json['tokens'] ?? {'input': 0, 'output': 0, 'total': 0},
    );
  }

  /// Convertit l'instance en un map JSON.
  Map<String, dynamic> toJson() => {
    'conversation_id': conversationId,
    'ai_response': aiResponse,
    'tokens': tokens,
  };
}


//##############################################################################
//#               MODÈLE POUR LA REQUÊTE D'ENVOI D'UN MESSAGE                  #
//##############################################################################

/// Représente le corps de la requête à envoyer au serveur pour poster un message.
class CoiffeuseMessageRequest {
  /// L'ID de la conversation. Peut être nul s'il s'agit du premier message.
  final int? conversationId;
  /// Le contenu textuel du message à envoyer.
  final String message;

  /// Constructeur pour créer une instance de `CoiffeuseMessageRequest`.
  CoiffeuseMessageRequest({
    this.conversationId,
    required this.message,
  });

  /// Convertit l'instance en un map JSON, prêt à être envoyé comme corps de requête.
  Map<String, dynamic> toJson() => {
    'conversation_id': conversationId,
    'message': message,
  };
}






// // lib/models/coiffeuse_ai_chat.dart
// import 'dart:convert';
//
// /// Modèle pour la liste des conversations des coiffeuses
// /// Correspond à la réponse de get_coiffeuse_conversations
// class CoiffeuseConversationItem {
//   final int id;
//   final DateTime createdAt;
//   final int tokensUsed;
//   final String title;
//
//   CoiffeuseConversationItem({
//     required this.id,
//     required this.createdAt,
//     required this.tokensUsed,
//     required this.title,
//   });
//
//   factory CoiffeuseConversationItem.fromJson(Map<String, dynamic> json) {
//     return CoiffeuseConversationItem(
//       id: json['id'],
//       createdAt: DateTime.parse(json['created_at']),
//       tokensUsed: json['tokens_used'] ?? 0,
//       title: json['title'] ?? 'Nouvelle Conversation',
//     );
//   }
//
//   Map<String, dynamic> toJson() => {
//     'id': id,
//     'created_at': createdAt.toIso8601String(),
//     'tokens_used': tokensUsed,
//     'title': title,
//   };
// }
//
// /// Modèle pour une conversation complète avec ses messages
// /// Correspond à la réponse de get_coiffeuse_conversation_messages
// class CoiffeuseConversationDetail {
//   final int id;
//   final int userId;
//   final DateTime createdAt;
//   List<CoiffeuseMessage> messages;
//
//   CoiffeuseConversationDetail({
//     required this.id,
//     required this.userId,
//     required this.createdAt,
//     this.messages = const [],
//   });
//
//   factory CoiffeuseConversationDetail.fromJson(Map<String, dynamic> json) {
//     return CoiffeuseConversationDetail(
//       id: json['id'],
//       userId: json['user_id'],
//       createdAt: DateTime.parse(json['created_at']),
//       messages: json['messages'] != null
//           ? List<CoiffeuseMessage>.from(json['messages'].map((x) => CoiffeuseMessage.fromJson(x)))
//           : [],
//     );
//   }
//
//   Map<String, dynamic> toJson() => {
//     'id': id,
//     'user_id': userId,
//     'created_at': createdAt.toIso8601String(),
//     'messages': messages.map((x) => x.toJson()).toList(),
//   };
// }
//
// /// Modèle pour un message individuel
// /// Correspond au AIMessageSerializer du backend
// class CoiffeuseMessage {
//   final int id;
//   final String content;
//   final bool isUser;
//   final DateTime timestamp;
//
//   CoiffeuseMessage({
//     required this.id,
//     required this.content,
//     required this.isUser,
//     required this.timestamp,
//   });
//
//   factory CoiffeuseMessage.fromJson(Map<String, dynamic> json) {
//     return CoiffeuseMessage(
//       id: json['id'],
//       content: json['content'],
//       isUser: json['is_user'],
//       timestamp: DateTime.parse(json['timestamp']),
//     );
//   }
//
//   Map<String, dynamic> toJson() => {
//     'id': id,
//     'content': content,
//     'is_user': isUser,
//     'timestamp': timestamp.toIso8601String(),
//   };
// }
//
// /// Modèle pour la création d'une nouvelle conversation
// /// Correspond à la réponse de create_coiffeuse_conversation
// class CoiffeuseConversationCreate {
//   final int id;
//   final DateTime createdAt;
//
//   CoiffeuseConversationCreate({
//     required this.id,
//     required this.createdAt,
//   });
//
//   factory CoiffeuseConversationCreate.fromJson(Map<String, dynamic> json) {
//     return CoiffeuseConversationCreate(
//       id: json['id'],
//       createdAt: DateTime.parse(json['created_at']),
//     );
//   }
//
//   Map<String, dynamic> toJson() => {
//     'id': id,
//     'created_at': createdAt.toIso8601String(),
//   };
// }
//
// /// Modèle pour la réponse d'envoi de message
// /// Correspond à la réponse de send_coiffeuse_message
// class CoiffeuseMessageResponse {
//   final int conversationId;
//   final String aiResponse;
//   final Map<String, dynamic> tokens;
//
//   CoiffeuseMessageResponse({
//     required this.conversationId,
//     required this.aiResponse,
//     required this.tokens,
//   });
//
//   factory CoiffeuseMessageResponse.fromJson(Map<String, dynamic> json) {
//     String responseText;
//     if (json['ai_response'] is String) {
//       responseText = json['ai_response'];
//     } else if (json['ai_response'] is List<int>) {
//       responseText = utf8.decode(json['ai_response']);
//     } else {
//       responseText = json['ai_response'].toString();
//     }
//
//     return CoiffeuseMessageResponse(
//       conversationId: json['conversation_id'],
//       aiResponse: responseText,
//       tokens: json['tokens'] ?? {'input': 0, 'output': 0, 'total': 0},
//     );
//   }
//
//   Map<String, dynamic> toJson() => {
//     'conversation_id': conversationId,
//     'ai_response': aiResponse,
//     'tokens': tokens,
//   };
// }
//
// /// Modèle pour l'envoi d'un message (requête)
// class CoiffeuseMessageRequest {
//   final int? conversationId;
//   final String message;
//
//   CoiffeuseMessageRequest({
//     this.conversationId,
//     required this.message,
//   });
//
//   Map<String, dynamic> toJson() => {
//     'conversation_id': conversationId,
//     'message': message,
//   };
// }