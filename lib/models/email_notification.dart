////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                MODÈLE DE DONNÉES POUR L'ENVOI D'E-MAILS                      //
//                                                                            //
//  Ce fichier définit le modèle `EmailNotification`, qui structure les        //
//  informations nécessaires pour l'envoi d'un e-mail transactionnel via une  //
//  API backend. Cette classe permet de standardiser la manière dont les      //
//  demandes d'envoi d'e-mails sont construites dans l'application, en         //
//  encapsulant le destinataire, le sujet, le modèle d'e-mail à utiliser et    //
//  les données dynamiques à y insérer.                                       //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


/// Représente une notification par e-mail à envoyer.
///
/// Cette classe est utilisée pour créer un objet de requête structuré,
/// généralement converti en JSON, à envoyer à une API backend chargée
/// de l'envoi effectif des e-mails.
class EmailNotification {
  /// L'adresse e-mail du destinataire.
  final String toEmail;
  /// Le nom du destinataire, utilisé pour la personnalisation.
  final String toName;
  /// Le sujet de l'e-mail.
  final String subject;
  /// L'identifiant unique du modèle (template) d'e-mail à utiliser
  /// (ex: sur un service comme SendGrid, Mailgun, etc.).
  final String templateId;
  /// Un map contenant les données dynamiques à injecter dans le modèle.
  /// Par exemple: `{'username': 'John', 'reset_link': '...'}`.
  final Map<String, dynamic> templateData;
  /// L'identifiant optionnel d'un rendez-vous lié à cette notification,
  /// pour le suivi ou la journalisation.
  final int? rendezVousId;

  /// Constructeur pour créer une instance de `EmailNotification`.
  EmailNotification({
    required this.toEmail,
    required this.toName,
    required this.subject,
    required this.templateId,
    required this.templateData,
    this.rendezVousId,
  });

  /// Convertit l'instance de `EmailNotification` en un map JSON.
  ///
  /// Cette méthode est essentielle pour sérialiser l'objet avant de l'envoyer
  /// comme corps de requête à l'API backend.
  Map<String, dynamic> toJson() {
    return {
      'toEmail': toEmail,
      'toName': toName,
      'subject': subject,
      'templateId': templateId,
      'templateData': templateData,
      'rendezVousId': rendezVousId,
    };
  }

  /// Factory constructor pour créer une instance de `EmailNotification` à partir d'un map JSON.
  ///
  /// Bien que principalement utilisée pour la création de requêtes (toJson), cette
  /// méthode permet la désérialisation, utile pour le débogage ou si l'API
  /// retourne l'objet de la requête.
  factory EmailNotification.fromJson(Map<String, dynamic> json) {
    return EmailNotification(
      toEmail: json['toEmail'],
      toName: json['toName'],
      subject: json['subject'],
      templateId: json['templateId'],
      templateData: json['templateData'],
      rendezVousId: json['rendezVousId'],
    );
  }
}





// // Fichier: lib/models/email_notification.dart
//
// class EmailNotification {
//   final String toEmail;
//   final String toName;
//   final String subject;
//   final String templateId;
//   final Map<String, dynamic> templateData;
//   final int? rendezVousId;
//
//   EmailNotification({
//     required this.toEmail,
//     required this.toName,
//     required this.subject,
//     required this.templateId,
//     required this.templateData,
//     this.rendezVousId,
//   });
//
//   Map<String, dynamic> toJson() {
//     return {
//       'toEmail': toEmail,
//       'toName': toName,
//       'subject': subject,
//       'templateId': templateId,
//       'templateData': templateData,
//       'rendezVousId': rendezVousId,
//     };
//   }
//
//   factory EmailNotification.fromJson(Map<String, dynamic> json) {
//     return EmailNotification(
//       toEmail: json['toEmail'],
//       toName: json['toName'],
//       subject: json['subject'],
//       templateId: json['templateId'],
//       templateData: json['templateData'],
//       rendezVousId: json['rendezVousId'],
//     );
//   }
// }