////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//        SERVICE (CLIENT API) POUR L'ENVOI DE NOTIFICATIONS PAR E-MAIL         //
//                                                                            //
//  Ce fichier définit la classe `EmailNotificationService`, qui agit comme   //
//  une interface (client API) pour communiquer avec un backend chargé de     //
//  l'envoi d'e-mails transactionnels (par exemple, via SendGrid, Mailgun, etc.)//
//                                                                            //
//  Responsabilités :                                                         //
//  - Fournir une méthode générique pour envoyer n'importe quel e-mail        //
//    structuré via un objet `EmailNotification`.                             //
//  - Proposer des méthodes de convenance (helpers) pour les cas d'usage      //
//    courants, comme la notification d'un changement de statut ou de date    //
//    d'un rendez-vous, simplifiant ainsi l'appel depuis d'autres services.   //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../models/email_notification.dart';

/// Une classe de service qui encapsule la logique d'envoi d'e-mails
/// en communiquant avec une API backend.
class EmailNotificationService {
  /// L'URL de base de l'API backend.
  final String baseUrl;
  /// Le jeton d'authentification (JWT) pour sécuriser les requêtes.
  final String token;

  /// Constructeur qui initialise le service avec l'URL de base et le token.
  EmailNotificationService({required this.baseUrl, required this.token});

  /// Getter privé pour obtenir les en-têtes HTTP standards pour les requêtes authentifiées.
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  /// Méthode générique pour envoyer une notification par e-mail.
  ///
  /// Prend un objet `EmailNotification` complet, le convertit en JSON et
  /// l'envoie via une requête POST à l'API.
  ///
  /// [notification] : L'objet contenant toutes les données de l'e-mail à envoyer.
  ///
  /// Retourne `true` si la requête à l'API a réussi (status 200 ou 201),
  /// `false` sinon.
  Future<bool> sendEmailNotification(EmailNotification notification) async {
    try {
      // Effectue une requête POST vers l'endpoint de notifications par e-mail.
      final response = await http.post(
        Uri.parse('$baseUrl/email-notifications/'),
        headers: _headers,
        body: json.encode(notification.toJson()),
      );

      // Vérifie si l'API a accepté la requête avec succès.
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          print('Email envoyé avec succès');
        }
        return true;
      } else {
        // En cas d'échec, enregistre les détails de l'erreur.
        if (kDebugMode) {
          print('Erreur lors de l\'envoi de l\'email: ${response.statusCode}');
        }
        if (kDebugMode) {
          print('Message: ${response.body}');
        }
        return false;
      }
    } catch (e) {
      // Gère les exceptions réseau ou autres erreurs inattendues.
      if (kDebugMode) {
        print('Exception lors de l\'envoi de l\'email: $e');
      }
      return false;
    }
  }

  /// Méthode de convenance pour envoyer un e-mail de mise à jour de statut.
  ///
  /// Simplifie l'envoi en choisissant automatiquement le bon modèle d'e-mail
  /// et le sujet en fonction du nouveau statut du rendez-vous.
  Future<bool> sendStatusUpdateNotification({
    required String email,
    required String prenomClient,
    required String nomClient,
    required int rendezVousId,
    required String dateHeure,
    required String nouveauStatut,
    required String nomSalon,
    List<Map<String, dynamic>>? services,
    double? totalPrix,
    int? dureeTotale,
  }) async {
    String templateId;
    String subject;

    // Détermine le template et le sujet à utiliser en fonction du statut.
    switch (nouveauStatut) {
      case 'confirmé':
        templateId = 'confirmation_rdv';
        subject = 'Confirmation de votre rendez-vous chez $nomSalon';
        break;
      case 'annulé':
        templateId = 'annulation_rdv';
        subject = 'Annulation de votre rendez-vous chez $nomSalon';
        break;
      case 'terminé':
      // Pour le statut "terminé", aucune notification n'est envoyée par cette méthode.
      // Une autre logique (ex: demande d'avis) pourrait être déclenchée ailleurs.
        return true;
      default:
      // Cas par défaut pour tout autre statut (ex: "reporté").
        templateId = 'modification_rdv';
        subject = 'Modification de votre rendez-vous chez $nomSalon';
    }

    // Construit l'objet `EmailNotification` avec les données formatées.
    final notification = EmailNotification(
      toEmail: email,
      toName: '$prenomClient $nomClient',
      subject: subject,
      templateId: templateId,
      rendezVousId: rendezVousId,
      templateData: {
        'prenom': prenomClient,
        'nom': nomClient,
        'date_heure': dateHeure,
        'salon_nom': nomSalon,
        'statut': nouveauStatut,
        // Ajoute les données optionnelles seulement si elles sont fournies.
        if (services != null) 'services': services,
        if (totalPrix != null) 'total_prix': totalPrix,
        if (dureeTotale != null) 'duree_totale': dureeTotale,
      },
    );

    // Délègue l'envoi à la méthode générique.
    return await sendEmailNotification(notification);
  }

  /// Méthode de convenance pour envoyer un e-mail de mise à jour de date/heure.
  Future<bool> sendDateUpdateNotification({
    required String email,
    required String prenomClient,
    required String nomClient,
    required int rendezVousId,
    required String ancienneDateHeure,
    required String nouvelleDateHeure,
    required String nomSalon,
  }) async {
    // Construit l'objet `EmailNotification` spécifique à cette action.
    final notification = EmailNotification(
      toEmail: email,
      toName: '$prenomClient $nomClient',
      subject: 'Modification de la date de votre rendez-vous chez $nomSalon',
      templateId: 'modification_rdv', // Utilise un template de modification générique.
      rendezVousId: rendezVousId,
      templateData: {
        'prenom': prenomClient,
        'nom': nomClient,
        'date_heure': nouvelleDateHeure,
        'ancienne_date_heure': ancienneDateHeure,
        'salon_nom': nomSalon,
      },
    );

    // Délègue l'envoi à la méthode générique.
    return await sendEmailNotification(notification);
  }
}






// // Fichier: lib/services/email_notification_service.dart
//
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../../../models/email_notification.dart';
//
// class EmailNotificationService {
//   final String baseUrl;
//   final String token;
//
//   EmailNotificationService({required this.baseUrl, required this.token});
//
//   // En-têtes HTTP courants
//   Map<String, String> get _headers => {
//     'Content-Type': 'application/json',
//     'Authorization': 'Bearer $token',
//   };
//
//   /// Envoie une notification par email
//   Future<bool> sendEmailNotification(EmailNotification notification) async {
//     try {
//       final response = await http.post(
//         Uri.parse('$baseUrl/email-notifications/'),
//         headers: _headers,
//         body: json.encode(notification.toJson()),
//       );
//
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         print('Email envoyé avec succès');
//         return true;
//       } else {
//         print('Erreur lors de l\'envoi de l\'email: ${response.statusCode}');
//         print('Message: ${response.body}');
//         return false;
//       }
//     } catch (e) {
//       print('Exception lors de l\'envoi de l\'email: $e');
//       return false;
//     }
//   }
//
//   /// Envoie une notification après modification du statut d'un rendez-vous
//   Future<bool> sendStatusUpdateNotification({
//     required String email,
//     required String prenomClient,
//     required String nomClient,
//     required int rendezVousId,
//     required String dateHeure,
//     required String nouveauStatut,
//     required String nomSalon,
//     List<Map<String, dynamic>>? services,
//     double? totalPrix,
//     int? dureeTotale,
//   }) async {
//     // Déterminer le type d'email en fonction du statut
//     String templateId;
//     String subject;
//
//     switch (nouveauStatut) {
//       case 'confirmé':
//         templateId = 'confirmation_rdv';
//         subject = 'Confirmation de votre rendez-vous chez $nomSalon';
//         break;
//       case 'annulé':
//         templateId = 'annulation_rdv';
//         subject = 'Annulation de votre rendez-vous chez $nomSalon';
//         break;
//       case 'terminé':
//         return true; // Pas de notification pour le statut "terminé"
//       default:
//         templateId = 'modification_rdv';
//         subject = 'Modification de votre rendez-vous chez $nomSalon';
//     }
//
//     final notification = EmailNotification(
//       toEmail: email,
//       toName: '$prenomClient $nomClient',
//       subject: subject,
//       templateId: templateId,
//       rendezVousId: rendezVousId,
//       templateData: {
//         'prenom': prenomClient,
//         'nom': nomClient,
//         'date_heure': dateHeure,
//         'salon_nom': nomSalon,
//         'statut': nouveauStatut,
//         if (services != null) 'services': services,
//         if (totalPrix != null) 'total_prix': totalPrix,
//         if (dureeTotale != null) 'duree_totale': dureeTotale,
//       },
//     );
//
//     return await sendEmailNotification(notification);
//   }
//
//   /// Envoie une notification après modification de la date d'un rendez-vous
//   Future<bool> sendDateUpdateNotification({
//     required String email,
//     required String prenomClient,
//     required String nomClient,
//     required int rendezVousId,
//     required String ancienneDateHeure,
//     required String nouvelleDateHeure,
//     required String nomSalon,
//   }) async {
//     final notification = EmailNotification(
//       toEmail: email,
//       toName: '$prenomClient $nomClient',
//       subject: 'Modification de la date de votre rendez-vous chez $nomSalon',
//       templateId: 'modification_rdv',
//       rendezVousId: rendezVousId,
//       templateData: {
//         'prenom': prenomClient,
//         'nom': nomClient,
//         'date_heure': nouvelleDateHeure,
//         'ancienne_date_heure': ancienneDateHeure,
//         'salon_nom': nomSalon,
//       },
//     );
//
//     return await sendEmailNotification(notification);
//   }
// }