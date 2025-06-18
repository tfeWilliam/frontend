////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                 MODÈLE DE DONNÉES POUR UN ARTICLE DU PANIER                  //
//                                                                            //
//  Ce fichier définit le modèle `CartItem`, qui représente un service unique  //
//  ajouté au panier d'achat de l'utilisateur. Chaque `CartItem` encapsule un  //
//  objet `Service` ainsi qu'une quantité, permettant de gérer l'ajout         //
//  multiple d'un même service.                                               //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

import 'services.dart';

//##############################################################################
//#                   MODÈLE POUR UN ARTICLE DANS LE PANIER                      #
//##############################################################################

/// Représente un article dans le panier d'achat.
///
/// Cette classe lie un [Service] à une [quantity] pour permettre à un utilisateur
/// de sélectionner un ou plusieurs services avant de finaliser une réservation.
class CartItem {
  /// Le service qui a été ajouté au panier.
  final Service service;

  /// Le nombre de fois que ce service a été ajouté.
  /// Ce champ est mutable pour permettre d'incrémenter ou de décrémenter
  /// facilement la quantité directement dans le panier.
  int quantity;

  /// Constructeur pour créer une instance de `CartItem`.
  ///
  /// Par défaut, la quantité est initialisée à 1.
  CartItem({
    required this.service,
    this.quantity = 1,
  });

  /// Calcule le prix total pour cet article spécifique dans le panier.
  ///
  /// Le calcul prend en compte le prix du service (avec une éventuelle réduction)
  /// multiplié par la quantité de cet article.
  ///
  /// Retourne un [double] représentant le prix total.
  double getPrixTotal() {
    return service.getPrixAvecReduction() * quantity;
  }

  /// Factory constructor pour créer une instance de `CartItem` à partir d'un map JSON.
  ///
  /// Utilisé pour la désérialisation, par exemple lors du chargement d'un panier
  /// sauvegardé depuis la mémoire locale.
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      service: Service.fromJson(json['service']),
      quantity: json['quantity'],
    );
  }

  /// Convertit l'instance de `CartItem` en un map JSON.
  ///
  /// Utilisé pour la sérialisation, par exemple pour sauvegarder le panier
  /// dans la mémoire locale de l'appareil.
  Map<String, dynamic> toJson() {
    return {
      "service": service.toJson(),
      "quantity": quantity,
    };
  }
}




// import 'services.dart';
//
// class CartItem {
//   final Service service;
//   int quantity; // Permet d'ajouter plusieurs fois le même service
//
//   CartItem({
//     required this.service,
//     this.quantity = 1,
//   });
//
//   // Calcul du prix total pour cet élément dans le panier
//   double getPrixTotal() {
//     return service.getPrixAvecReduction() * quantity;
//   }
//
//   // Convertir JSON vers CartItemModel
//   factory CartItem.fromJson(Map<String, dynamic> json) {
//     return CartItem(
//       service: Service.fromJson(json['service']),
//       quantity: json['quantity'],
//     );
//   }
//
//   // Convertir CartItemModel vers JSON
//   Map<String, dynamic> toJson() {
//     return {
//       "service": service.toJson(),
//       "quantity": quantity,
//     };
//   }
// }
