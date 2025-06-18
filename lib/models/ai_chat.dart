////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//             MODÈLES DE DONNÉES POUR LE CHAT AVEC L'INTELLIGENCE ARTIFICIELLE //
//                                                                            //
//  Ce fichier définit les classes Dart nécessaires pour modéliser les        //
//  interactions avec le service de chat AI. Il contient les modèles pour :   //
//                                                                            //
//  - AIConversation : Représente une conversation complète avec ses messages.//
//  - AIMessage : Représente un message unique (de l'utilisateur ou de l'IA). //
//  - SendMessageResponse : Modélise la réponse du serveur après l'envoi      //
//    d'un message.                                                           //
//  - ConversationsList : Un conteneur pour une liste de conversations.       //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

import 'dart:convert'; // Nécessaire pour le décodage utf8 dans SendMessageResponse.

//##############################################################################
//#                        MODÈLE POUR UNE CONVERSATION AI                       #
//##############################################################################

/// Représente une conversation complète avec l'IA.
class AIConversation {
  /// L'identifiant unique de la conversation en base de données.
  final int id;
  /// La date et l'heure de création de la conversation.
  final DateTime createdAt;
  /// Le nombre total de jetons (tokens) utilisés dans cette conversation.
  /// Mutable pour pouvoir être mis à jour au fil des messages.
  int tokensUsed;
  /// Le contenu du dernier message pour un aperçu rapide.
  final String? lastMessage;
  /// La liste des messages composant la conversation.
  List<AIMessage> messages;

  /// Constructeur principal pour créer une instance d'AIConversation.
  AIConversation({
    required this.id,
    required this.createdAt,
    this.tokensUsed = 0,
    this.lastMessage,
    this.messages = const [],
  });

  /// Factory constructor pour créer une instance d'AIConversation à partir d'un map JSON.
  /// Utilisé pour la désérialisation des données venant de l'API.
  factory AIConversation.fromJson(Map<String, dynamic> json) {
    return AIConversation(
      // Utilisation de valeurs par défaut pour la robustesse en cas de données nulles.
      id: json['id'] ?? -1,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      tokensUsed: json['tokens_used'] ?? 0,
      lastMessage: json['last_message'],
      // Crée une liste de AIMessage si le champ 'messages' existe, sinon une liste vide.
      messages: json['messages'] != null
          ? List<AIMessage>.from(json['messages'].map((x) => AIMessage.fromJson(x)))
          : [],
    );
  }

  /// Convertit l'instance d'AIConversation en un map JSON.
  /// Note : cette méthode ne sérialise pas la liste des messages, elle est donc
  /// probablement utilisée pour des mises à jour de métadonnées de la conversation.
  Map<String, dynamic> toJson() => {
    'id': id,
    'created_at': createdAt.toIso8601String(),
    'tokens_used': tokensUsed,
    'last_message': lastMessage,
  };
}


//##############################################################################
//#                          MODÈLE POUR UN MESSAGE AI                         #
//##############################################################################

/// Représente un message unique au sein d'une conversation.
class AIMessage {
  /// L'identifiant unique du message en base de données.
  final int id;
  /// Le contenu textuel du message.
  final String content;
  /// Un booléen indiquant si le message provient de l'utilisateur (`true`) ou de l'IA (`false`).
  final bool isUser;
  /// La date et l'heure auxquelles le message a été créé.
  final DateTime timestamp;
  /// Le nombre de jetons (tokens) utilisés en entrée pour générer ce message.
  final int tokensIn;
  /// Le nombre de jetons (tokens) utilisés en sortie (réponse de l'IA).
  final int tokensOut;

  /// Constructeur principal pour créer une instance d'AIMessage.
  AIMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.tokensIn = 0,
    this.tokensOut = 0,
  });

  /// Factory constructor pour créer une instance d'AIMessage à partir d'un map JSON.
  factory AIMessage.fromJson(Map<String, dynamic> json) {
    return AIMessage(
      id: json['id'],
      content: json['content'],
      isUser: json['is_user'],
      timestamp: DateTime.parse(json['timestamp']),
      // Gestion robuste des types pour les tokens (peut être int ou double dans le JSON).
      tokensIn: (json['tokens_in'] ?? 0) is int ? json['tokens_in'] : (json['tokens_in'] ?? 0).toInt(),
      tokensOut: (json['tokens_out'] ?? 0) is int ? json['tokens_out'] : (json['tokens_out'] ?? 0).toInt(),
    );
  }

  /// Convertit l'instance d'AIMessage en un map JSON.
  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'is_user': isUser,
    'timestamp': timestamp.toIso8601String(),
    'tokens_in': tokensIn,
    'tokens_out': tokensOut,
  };
}


//##############################################################################
//#                   MODÈLE POUR LA RÉPONSE DE L'ENVOI DE MESSAGE             #
//##############################################################################

/// Modélise la réponse du serveur après l'envoi d'un message par l'utilisateur.
class SendMessageResponse {
  /// L'ID de la conversation concernée.
  final int conversationId;
  /// L'ID du message de l'utilisateur qui vient d'être créé.
  final int userMessageId;
  /// L'ID du message de réponse de l'IA qui vient d'être créé.
  final int aiMessageId;
  /// Le contenu textuel de la réponse de l'IA.
  final String aiResponse;
  /// Un map contenant les détails des jetons (tokens) utilisés pour cette interaction.
  final Map<String, dynamic> tokens;

  SendMessageResponse({
    required this.conversationId,
    required this.userMessageId,
    required this.aiMessageId,
    required this.aiResponse,
    required this.tokens,
  });

  /// Factory constructor pour créer une instance de SendMessageResponse à partir d'un map JSON.
  /// Inclut une logique pour décoder correctement la réponse de l'IA.
  factory SendMessageResponse.fromJson(Map<String, dynamic> json) {
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

    return SendMessageResponse(
      conversationId: json['conversation_id'],
      userMessageId: json['user_message_id'],
      aiMessageId: json['ai_message_id'],
      aiResponse: responseText,
      // Fournit une valeur par défaut pour les tokens si le champ est manquant.
      tokens: json['tokens'] ?? {'input': 0, 'output': 0, 'total': 0},
    );
  }
}


//##############################################################################
//#                 MODÈLE POUR UNE LISTE DE CONVERSATIONS                     #
//##############################################################################

/// Représente une liste de conversations, typiquement reçue d'un endpoint
/// qui liste toutes les conversations passées d'un utilisateur.
class ConversationsList {
  /// La liste des objets AIConversation.
  final List<AIConversation> conversations;

  ConversationsList({required this.conversations});

  /// Factory constructor pour créer une instance de ConversationsList à partir d'un map JSON.
  factory ConversationsList.fromJson(Map<String, dynamic> json) {
    return ConversationsList(
      // Itère sur la liste 'conversations' du JSON et la convertit en une liste d'objets AIConversation.
      conversations: List<AIConversation>.from(
          json['conversations'].map((x) => AIConversation.fromJson(x))
      ),
    );
  }
}


// // lib/models/ai_chat/ai_conversation.dart
// // lib/models/ai_chat/ai_conversation.dart
// import 'dart:convert';
//
// class AIConversation {
//   final int id;
//   final DateTime createdAt;
//   int tokensUsed;    // Non final pour permettre la modification
//   final String? lastMessage;
//   List<AIMessage> messages;
//
//   AIConversation({
//     required this.id,
//     required this.createdAt,
//     this.tokensUsed = 0,
//     this.lastMessage,
//     this.messages = const [],
//   });
//
//   factory AIConversation.fromJson(Map<String, dynamic> json) {
//     return AIConversation(
//       id: json['id'] ?? -1, // Ajouter une valeur par défaut au cas où id est null
//       createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
//       tokensUsed: json['tokens_used'] ?? 0,
//       lastMessage: json['last_message'],
//       messages: json['messages'] != null
//           ? List<AIMessage>.from(json['messages'].map((x) => AIMessage.fromJson(x)))
//           : [],
//     );
//   }
//
//   Map<String, dynamic> toJson() => {
//     'id': id,
//     'created_at': createdAt.toIso8601String(),
//     'tokens_used': tokensUsed,
//     'last_message': lastMessage,
//   };
// }
//
// // lib/models/ai_chat/ai_message.dart
// class AIMessage {
//   final int id;
//   final String content;
//   final bool isUser;
//   final DateTime timestamp;
//   final int tokensIn;    // Gardons int ici
//   final int tokensOut;   // Gardons int ici
//
//   AIMessage({
//     required this.id,
//     required this.content,
//     required this.isUser,
//     required this.timestamp,
//     this.tokensIn = 0,
//     this.tokensOut = 0,
//   });
//
//   factory AIMessage.fromJson(Map<String, dynamic> json) {
//     return AIMessage(
//       id: json['id'],
//       content: json['content'],
//       isUser: json['is_user'],
//       timestamp: DateTime.parse(json['timestamp']),
//       tokensIn: (json['tokens_in'] ?? 0) is int ? json['tokens_in'] : (json['tokens_in'] ?? 0).toInt(),
//       tokensOut: (json['tokens_out'] ?? 0) is int ? json['tokens_out'] : (json['tokens_out'] ?? 0).toInt(),
//     );
//   }
//
//   Map<String, dynamic> toJson() => {
//     'id': id,
//     'content': content,
//     'is_user': isUser,
//     'timestamp': timestamp.toIso8601String(),
//     'tokens_in': tokensIn,
//     'tokens_out': tokensOut,
//   };
// }
//
// // lib/models/ai_chat/ai_response.dart
// class SendMessageResponse {
//   final int conversationId;
//   final int userMessageId;
//   final int aiMessageId;
//   final String aiResponse;
//   final Map<String, dynamic> tokens;  // Nous garderons le type dynamic ici
//
//   SendMessageResponse({
//     required this.conversationId,
//     required this.userMessageId,
//     required this.aiMessageId,
//     required this.aiResponse,
//     required this.tokens,
//   });
//
//   factory SendMessageResponse.fromJson(Map<String, dynamic> json) {
//     String responseText;
//     if (json['ai_response'] is String) {
//       // La réponse est déjà une chaîne, pas besoin de décodage
//       responseText = json['ai_response'];
//     } else if (json['ai_response'] is List<int>) {
//       // La réponse est une liste d'octets, il faut la décoder
//       responseText = utf8.decode(json['ai_response']);
//     } else {
//       // Cas improbable mais géré par sécurité
//       responseText = json['ai_response'].toString();
//     }
//
//     return SendMessageResponse(
//       conversationId: json['conversation_id'],
//       userMessageId: json['user_message_id'],
//       aiMessageId: json['ai_message_id'],
//       aiResponse: responseText,
//       tokens: json['tokens'] ?? {'input': 0, 'output': 0, 'total': 0},
//     );
//   }
//
//
//   // factory SendMessageResponse.fromJson(Map<String, dynamic> json) {
//   //   return SendMessageResponse(
//   //     conversationId: json['conversation_id'],
//   //     userMessageId: json['user_message_id'],
//   //     aiMessageId: json['ai_message_id'],
//   //     aiResponse: json['ai_response'],
//   //     tokens: json['tokens'] ?? {'input': 0, 'output': 0, 'total': 0},
//   //   );
//   // }
// }
//
// // lib/models/ai_chat/conversations_list.dart
// class ConversationsList {
//   final List<AIConversation> conversations;
//
//   ConversationsList({required this.conversations});
//
//   factory ConversationsList.fromJson(Map<String, dynamic> json) {
//     return ConversationsList(
//       conversations: List<AIConversation>.from(
//           json['conversations'].map((x) => AIConversation.fromJson(x))
//       ),
//     );
//   }
// }