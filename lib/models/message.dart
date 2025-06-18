/****************************************************************************************
 *
 * MODÈLE DE DONNÉES : Message
 *
 * OBJECTIF :
 * Cette classe définit la structure d'un message unique pour un système de chat
 * utilisant Firebase Realtime Database comme backend. Elle contient toutes les
 * informations essentielles d'un message : l'expéditeur, le destinataire, le
 * contenu textuel, l'horodatage et le statut de lecture.
 *
 * INTÉGRATION FIREBASE :
 * La classe est spécifiquement conçue pour interagir avec Firebase :
 * - `toJson()`: Convertit l'objet Message en une map JSON, en stockant le
 * timestamp sous forme d'entier (millisecondsSinceEpoch) pour des
 * requêtes et un tri efficaces dans Firebase.
 * - `fromJson()` et `fromSnapshot()`: Des méthodes factory pour créer facilement
 * des objets Message à partir des données reçues de Firebase (Map ou DataSnapshot).
 * - `_parseTimestamp()`: Une fonction robuste pour gérer différents formats de
 * timestamp pouvant provenir de la base de données.
 *
 *****************************************************************************************/
import 'package:firebase_database/firebase_database.dart';

class Message {
  // L'identifiant unique de l'utilisateur qui a envoyé le message.
  final String senderId;
  // L'identifiant unique de l'utilisateur qui doit recevoir le message.
  final String receiverId;
  // Le contenu textuel du message.
  final String text;
  // La date et l'heure précises de l'envoi du message.
  final DateTime timestamp;
  // Un booléen qui indique si le message a été lu par le destinataire.
  final bool isRead;

  // Constructeur pour créer un nouvel objet Message.
  // Par défaut, un message est initialisé comme non lu (`isRead = false`).
  Message({
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
  });

  /// Convertit l'objet Message en une map au format JSON.
  /// C'est utile pour envoyer des données vers Firebase Realtime Database.
  Map<String, dynamic> toJson() {
    return {
      "senderId": senderId,
      "receiverId": receiverId,
      "text": text,
      // Le timestamp est converti en entier (millisecondes depuis l'époque Unix)
      // pour un stockage et un tri optimisés dans Firebase.
      "timestamp": timestamp.millisecondsSinceEpoch,
      "isRead": isRead,
    };
  }

  /// Crée une instance de Message à partir d'une map JSON (généralement issue de Firebase).
  /// C'est l'opération de "désérialisation".
  factory Message.fromJson(Map<dynamic, dynamic> json) {
    return Message(
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      text: json['text'],
      // Utilise une fonction d'aide pour parser le timestamp de manière robuste.
      timestamp: _parseTimestamp(json['timestamp']),
      // Assure une valeur par défaut `false` si `isRead` est nul dans les données.
      isRead: json['isRead'] ?? false,
    );
  }

  /// Crée une instance de Message directement à partir d'un `DataSnapshot` de Firebase.
  /// C'est une méthode de commodité pour simplifier la lecture des données.
  factory Message.fromSnapshot(DataSnapshot snapshot) {
    final data = snapshot.value as Map<dynamic, dynamic>;
    return Message.fromJson(data);
  }

  /// Fonction d'aide privée pour convertir une valeur de timestamp (String ou int) en DateTime.
  /// Rend le modèle résistant à d'éventuelles variations de format de données.
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is String) {
      // Gère le cas où le timestamp est une chaîne de caractères au format ISO 8601.
      return DateTime.parse(timestamp).toUtc();
    } else if (timestamp is int) {
      // Gère le cas où le timestamp est un entier (millisecondes depuis l'époque Unix).
      return DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true);
    }
    // Fournit une valeur par défaut sécurisée (l'heure actuelle) si le format est inconnu.
    return DateTime.now().toUtc();
  }
}






// import 'package:firebase_database/firebase_database.dart';
//
// class Message {
//   final String senderId;
//   final String receiverId;
//   final String text;
//   final DateTime timestamp;
//   final bool isRead;
//
//   Message({
//     required this.senderId,
//     required this.receiverId,
//     required this.text,
//     required this.timestamp,
//     this.isRead = false,
//   });
//
//   /// ✅ Convertir un objet `Message` en JSON pour Firebase
//   Map<String, dynamic> toJson() {
//     return {
//       "senderId": senderId,
//       "receiverId": receiverId,
//       "text": text,
//       "timestamp": timestamp.millisecondsSinceEpoch, // ✅ Stockage en int pour Firebase
//       "isRead": isRead,
//     };
//   }
//
//   /// ✅ Convertir un JSON Firebase en `Message`
//   factory Message.fromJson(Map<dynamic, dynamic> json) {
//     return Message(
//       senderId: json['senderId'],
//       receiverId: json['receiverId'],
//       text: json['text'],
//       timestamp: _parseTimestamp(json['timestamp']), // ✅ Utilisation de la nouvelle fonction
//       isRead: json['isRead'] ?? false,
//     );
//   }
//
//   /// ✅ Convertir un `DataSnapshot` Firebase en `Message`
//   factory Message.fromSnapshot(DataSnapshot snapshot) {
//     final data = snapshot.value as Map<dynamic, dynamic>;
//     return Message.fromJson(data);
//   }
//
//   /// ✅ Fonction pour convertir le `timestamp` (String ou int) en `DateTime`
//   static DateTime _parseTimestamp(dynamic timestamp) {
//     if (timestamp is String) {
//       return DateTime.parse(timestamp).toUtc(); // ✅ Cas d'une String ISO
//     } else if (timestamp is int) {
//       return DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true); // ✅ Cas d'un int Unix
//     }
//     return DateTime.now().toUtc(); // ✅ Valeur par défaut (sécurité)
//   }
// }
