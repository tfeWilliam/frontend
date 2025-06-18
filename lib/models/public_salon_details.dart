/****************************************************************************************
 *
 * MODÈLES DE DONNÉES : DÉTAILS PUBLICS D'UN SALON
 * Fichier : models/public_salon_details.dart
 *
 * OBJECTIF :
 * Ce fichier définit l'ensemble des modèles de données nécessaires pour construire la
 * page de détails publique d'un salon de coiffure. Il est structuré autour d'une
 * classe principale, `PublicSalonDetails`, qui agrège toutes les autres informations.
 *
 * STRUCTURE DES CLASSES :
 * - PublicSalonDetails : Le conteneur principal qui regroupe toutes les données.
 * - Coiffeuse : Représente la coiffeuse associée au salon.
 * - User : Le modèle de base pour un utilisateur (contient nom, prénom, etc.).
 * - SalonImage : Représente une seule image de la galerie du salon.
 * - Avis : Modélise un avis client unique (note, commentaire, etc.).
 * - ServiceSalonDetails : Définit un service offert par le salon.
 * - PromotionActive : Un sous-modèle simple pour une promotion active sur un service.
 *
 *****************************************************************************************/
import 'dart:convert';

/// Modèle principal regroupant toutes les informations publiques d'un salon.
class PublicSalonDetails {
  /// L'identifiant unique du salon dans la base de données.
  final int idTblSalon;
  /// Le nom commercial du salon.
  final String nomSalon;
  /// Le slogan ou la phrase d'accroche du salon (optionnel).
  final String? slogan;
  /// Une description textuelle du salon ("À propos") (optionnelle).
  final String? aPropos;
  /// L'URL du logo du salon (optionnel).
  final String? logoSalon;
  /// Le numéro de TVA du salon (optionnel).
  final String? numeroTva;
  /// L'objet contenant les informations sur la coiffeuse principale du salon.
  final Coiffeuse coiffeuse;
  /// L'adresse postale complète du salon (optionnelle).
  final String? adresse;
  /// Une chaîne de caractères décrivant les horaires d'ouverture (optionnelle).
  final String? horaires;
  /// La note moyenne calculée à partir de tous les avis.
  final double noteMoyenne;
  /// Le nombre total d'avis reçus.
  final int nombreAvis;
  /// La liste des images de la galerie du salon.
  final List<SalonImage> images;
  /// La liste des derniers avis laissés par les clients.
  final List<Avis> avis;
  /// La liste complète des services proposés par le salon.
  final List<ServiceSalonDetails> serviceSalonDetailsList;

  /// Constructeur pour créer une instance de PublicSalonDetails.
  PublicSalonDetails({
    required this.idTblSalon,
    required this.nomSalon,
    this.slogan,
    this.aPropos,
    this.logoSalon,
    this.numeroTva,
    required this.coiffeuse,
    this.adresse,
    this.horaires,
    required this.noteMoyenne,
    required this.nombreAvis,
    required this.images,
    required this.avis,
    required this.serviceSalonDetailsList,
  });

  /// Construit une instance de [PublicSalonDetails] à partir d'une map JSON.
  factory PublicSalonDetails.fromJson(Map<String, dynamic> json) {
    return PublicSalonDetails(
      idTblSalon: json['idTblSalon'],
      nomSalon: json['nom_salon'],
      slogan: json['slogan'],
      aPropos: json['a_propos'],
      logoSalon: json['logo_salon'],
      numeroTva: json['numero_tva']?.toString(),
      coiffeuse: Coiffeuse.fromJson(json['coiffeuse']),
      adresse: json['adresse'],
      horaires: json['horaires'],
      noteMoyenne: json['note_moyenne']?.toDouble() ?? 0.0,
      nombreAvis: json['nombre_avis'] ?? 0,
      images: (json['images'] as List)
          .map((image) => SalonImage.fromJson(image))
          .toList(),
      avis: (json['avis'] as List)
          .map((avis) => Avis.fromJson(avis))
          .toList(),
      serviceSalonDetailsList: (json['services'] as List)
          .map((serviceSalonDetails) => ServiceSalonDetails.fromJson(serviceSalonDetails))
          .toList(),
    );
  }

  /// Méthode utilitaire pour parser directement depuis une chaîne JSON brute.
  static PublicSalonDetails fromRawJson(String str) =>
      PublicSalonDetails.fromJson(json.decode(str));
}

/// Modèle représentant la coiffeuse principale du salon.
class Coiffeuse {
  /// L'objet User contenant les données personnelles de la coiffeuse.
  final User idTblUser;
  /// Le nom commercial ou la dénomination sociale de l'entreprise de la coiffeuse.
  final String? nomCommercial;
  /// La position ou le rôle de la coiffeuse dans le salon (ex: "Gérante").
  final String? position;

  /// Constructeur pour créer une instance de Coiffeuse.
  Coiffeuse({
    required this.idTblUser,
    this.nomCommercial,
    this.position,
  });

  /// Construit une instance de [Coiffeuse] à partir d'une map JSON.
  factory Coiffeuse.fromJson(Map<String, dynamic> json) {
    return Coiffeuse(
      idTblUser: User.fromJson(json['idTblUser']),
      nomCommercial: json['nom_commercial'],
      position: json['position'],
    );
  }

  /// Accesseur pour la rétrocompatibilité. L'ancien code peut utiliser
  /// `denominationSociale` qui pointe maintenant vers `nomCommercial`.
  String? get denominationSociale => nomCommercial;
}

/// Modèle de base représentant un utilisateur avec ses informations personnelles.
class User {
  /// L'identifiant unique de l'utilisateur.
  final int idTblUser;
  /// Le nom de famille de l'utilisateur.
  final String nom;
  /// Le prénom de l'utilisateur.
  final String prenom;
  /// L'URL de la photo de profil de l'utilisateur (optionnelle).
  final String? photoProfil;
  /// Le numéro de téléphone de l'utilisateur (optionnel).
  final String? numeroTelephone;

  /// Constructeur pour créer une instance de User.
  User({
    required this.idTblUser,
    required this.nom,
    required this.prenom,
    this.photoProfil,
    this.numeroTelephone,
  });

  /// Construit une instance de [User] à partir d'une map JSON.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      nom: json['nom'],
      idTblUser: json['idTblUser'],
      prenom: json['prenom'],
      photoProfil: json['photo_profil'],
      numeroTelephone: json['numero_telephone'],
    );
  }
}

/// Modèle représentant une image de la galerie du salon.
class SalonImage {
  /// L'identifiant unique de l'image.
  final int id;
  /// L'URL complète de l'image.
  final String image;

  /// Constructeur pour créer une instance de SalonImage.
  SalonImage({required this.id, required this.image});

  /// Construit une instance de [SalonImage] à partir d'une map JSON.
  /// Gère la transformation d'URL relative en URL absolue.
  factory SalonImage.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('id') || !json.containsKey('image')) {
      throw Exception('Format JSON invalide pour SalonImage : $json');
    }

    final rawUrl = json['image'];
    // Si l'URL reçue n'est pas complète, on lui ajoute le domaine du site.
    final fullUrl = rawUrl.startsWith('http') ? rawUrl : 'https://www.hairbnb.site$rawUrl';

    return SalonImage(
        id: json['id'],
        image: fullUrl
    );
  }
}

/// Modèle représentant un avis laissé par un client.
class Avis {
  /// La note attribuée (généralement sur 5).
  final int note;
  /// Le texte du commentaire.
  final String commentaire;
  /// Le nom du client qui a laissé l'avis.
  final String clientNom;
  /// La date de l'avis, formatée pour l'affichage.
  final String dateFormat;

  /// Constructeur pour créer une instance d'Avis.
  Avis({
    required this.note,
    required this.commentaire,
    required this.clientNom,
    required this.dateFormat,
  });

  /// Construit une instance de [Avis] à partir d'une map JSON.
  factory Avis.fromJson(Map<String, dynamic> json) {
    return Avis(
      note: json['note'],
      commentaire: json['commentaire'],
      clientNom: json['client_nom'],
      dateFormat: json['date_format'],
    );
  }
}

/// Modèle représentant un service spécifique offert par le salon.
class ServiceSalonDetails {
  /// L'identifiant unique du service.
  final int idTblService;
  /// Le nom du service (ex: "Coupe Homme").
  final String intituleService;
  /// La description détaillée du service.
  final String description;
  /// Le prix du service (peut être nul).
  final double? prix;
  /// La durée estimée du service en minutes (peut être nulle).
  final int? duree;
  /// Les détails d'une promotion active sur ce service (s'il y en a une).
  final PromotionActive? promotionActive;

  /// Constructeur pour créer une instance de ServiceSalonDetails.
  ServiceSalonDetails({
    required this.idTblService,
    required this.intituleService,
    required this.description,
    this.prix,
    this.duree,
    this.promotionActive,
  });

  /// Construit une instance de [ServiceSalonDetails] à partir d'une map JSON.
  factory ServiceSalonDetails.fromJson(Map<String, dynamic> json) {
    return ServiceSalonDetails(
      idTblService: json['idTblService'],
      intituleService: json['intitule_service'],
      description: json['description'],
      prix: json['prix']?.toDouble(),
      duree: json['duree'],
      promotionActive: json['promotion_active'] != null
          ? PromotionActive.fromJson(json['promotion_active'])
          : null,
    );
  }
}

/// Sous-modèle simple contenant les informations d'une promotion active.
class PromotionActive {
  /// Le pourcentage de réduction.
  final String discountPercentage;
  /// La date de début de la promotion.
  final String startDate;
  /// La date de fin de la promotion.
  final String endDate;

  /// Constructeur pour créer une instance de PromotionActive.
  PromotionActive({
    required this.discountPercentage,
    required this.startDate,
    required this.endDate,
  });

  /// Construit une instance de [PromotionActive] à partir d'une map JSON.
  factory PromotionActive.fromJson(Map<String, dynamic> json) {
    return PromotionActive(
      discountPercentage: json['discount_percentage'],
      startDate: json['start_date'],
      endDate: json['end_date'],
    );
  }
}








// // models/public_salon_details.dart
// import 'dart:convert';
//
// class PublicSalonDetails {
//   final int idTblSalon;
//   final String nomSalon;
//   final String? slogan;
//   final String? aPropos;
//   final String? logoSalon;
//   final String? numeroTva; // ✅ Ajouté - TVA maintenant dans le salon
//   final Coiffeuse coiffeuse;
//   final String? adresse;
//   final String? horaires;
//   final double noteMoyenne;
//   final int nombreAvis;
//   final List<SalonImage> images;
//   final List<Avis> avis;
//   final List<ServiceSalonDetails> serviceSalonDetailsList;
//
//   PublicSalonDetails({
//     required this.idTblSalon,
//     required this.nomSalon,
//     this.slogan,
//     this.aPropos,
//     this.logoSalon,
//     this.numeroTva,
//     required this.coiffeuse,
//     this.adresse,
//     this.horaires,
//     required this.noteMoyenne,
//     required this.nombreAvis,
//     required this.images,
//     required this.avis,
//     required this.serviceSalonDetailsList,
//   });
//
//   factory PublicSalonDetails.fromJson(Map<String, dynamic> json) {
//     return PublicSalonDetails(
//       idTblSalon: json['idTblSalon'],
//       nomSalon: json['nom_salon'],
//       slogan: json['slogan'],
//       aPropos: json['a_propos'],
//       logoSalon: json['logo_salon'],
//       numeroTva: json['numero_tva']?.toString(), // ✅ TVA du salon
//       coiffeuse: Coiffeuse.fromJson(json['coiffeuse']),
//       adresse: json['adresse'],
//       horaires: json['horaires'],
//       noteMoyenne: json['note_moyenne']?.toDouble() ?? 0.0,
//       nombreAvis: json['nombre_avis'] ?? 0,
//       images: (json['images'] as List)
//           .map((image) => SalonImage.fromJson(image))
//           .toList(),
//       avis: (json['avis'] as List)
//           .map((avis) => Avis.fromJson(avis))
//           .toList(),
//       serviceSalonDetailsList: (json['services'] as List)
//           .map((serviceSalonDetails) => ServiceSalonDetails.fromJson(serviceSalonDetails))
//           .toList(),
//     );
//   }
//
//   static PublicSalonDetails fromRawJson(String str) =>
//       PublicSalonDetails.fromJson(json.decode(str));
// }
//
// class Coiffeuse {
//   final User idTblUser;
//   final String? nomCommercial; // ✅ Changé de denominationSociale à nomCommercial
//   final String? position;
//
//   Coiffeuse({
//     required this.idTblUser,
//     this.nomCommercial,
//     this.position,
//   });
//
//   factory Coiffeuse.fromJson(Map<String, dynamic> json) {
//     return Coiffeuse(
//       idTblUser: User.fromJson(json['idTblUser']),
//       nomCommercial: json['nom_commercial'], // ✅ Mise à jour du champ
//       position: json['position'],
//     );
//   }
//
//   // ✅ Propriété pour maintenir la compatibilité avec l'ancien code
//   String? get denominationSociale => nomCommercial;
// }
//
// class User {
//   final int idTblUser;
//   final String nom;
//   final String prenom;
//   final String? photoProfil;
//   final String? numeroTelephone;
//
//   User({
//     required this.idTblUser,
//     required this.nom,
//     required this.prenom,
//     this.photoProfil,
//     this.numeroTelephone,
//   });
//
//   factory User.fromJson(Map<String, dynamic> json) {
//     return User(
//       nom: json['nom'],
//       idTblUser: json['idTblUser'],
//       prenom: json['prenom'],
//       photoProfil: json['photo_profil'],
//       numeroTelephone: json['numero_telephone'],
//     );
//   }
// }
//
// class SalonImage {
//   final int id;
//   final String image;
//
//   SalonImage({required this.id, required this.image});
//
//   factory SalonImage.fromJson(Map<String, dynamic> json) {
//     if (!json.containsKey('id') || !json.containsKey('image')) {
//       throw Exception('Format JSON invalide pour SalonImage : $json');
//     }
//
//     final rawUrl = json['image'];
//     final fullUrl = rawUrl.startsWith('http') ? rawUrl : 'https://www.hairbnb.site$rawUrl';
//
//     return SalonImage(
//         id: json['id'],
//         image: fullUrl
//     );
//   }
// }
//
// class Avis {
//   final int note;
//   final String commentaire;
//   final String clientNom;
//   final String dateFormat;
//
//   Avis({
//     required this.note,
//     required this.commentaire,
//     required this.clientNom,
//     required this.dateFormat,
//   });
//
//   factory Avis.fromJson(Map<String, dynamic> json) {
//     return Avis(
//       note: json['note'],
//       commentaire: json['commentaire'],
//       clientNom: json['client_nom'],
//       dateFormat: json['date_format'],
//     );
//   }
// }
//
// class ServiceSalonDetails {
//   final int idTblService;
//   final String intituleService;
//   final String description;
//   final double? prix;
//   final int? duree;
//   final PromotionActive? promotionActive;
//
//   ServiceSalonDetails({
//     required this.idTblService,
//     required this.intituleService,
//     required this.description,
//     this.prix,
//     this.duree,
//     this.promotionActive,
//   });
//
//   factory ServiceSalonDetails.fromJson(Map<String, dynamic> json) {
//     return ServiceSalonDetails(
//       idTblService: json['idTblService'],
//       intituleService: json['intitule_service'],
//       description: json['description'],
//       prix: json['prix']?.toDouble(),
//       duree: json['duree'],
//       promotionActive: json['promotion_active'] != null
//           ? PromotionActive.fromJson(json['promotion_active'])
//           : null,
//     );
//   }
// }
//
// class PromotionActive {
//   final String discountPercentage;
//   final String startDate;
//   final String endDate;
//
//   PromotionActive({
//     required this.discountPercentage,
//     required this.startDate,
//     required this.endDate,
//   });
//
//   factory PromotionActive.fromJson(Map<String, dynamic> json) {
//     return PromotionActive(
//       discountPercentage: json['discount_percentage'],
//       startDate: json['start_date'],
//       endDate: json['end_date'],
//     );
//   }
// }
