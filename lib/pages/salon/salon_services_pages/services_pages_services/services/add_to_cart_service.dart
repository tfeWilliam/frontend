////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                SERVICE D'ACTION POUR L'AJOUT AU PANIER                       //
//                                                                            //
//  Ce fichier définit une unique fonction utilitaire de haut niveau,         //
//  `addToCart`. Son but est de centraliser et de simplifier la logique pour  //
//  ajouter un service au panier d'achat.                                     //
//                                                                            //
//  En encapsulant cette action dans une fonction, on s'assure qu'elle est    //
//  exécutée de manière cohérente à travers l'application : elle met à jour   //
//  l'état via le `CartProvider` et fournit un retour visuel immédiat à       //
//  l'utilisateur via un `SnackBar`.                                          //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;

import 'package:flutter/material.dart';
import 'package:hairbnb/services/providers/cart_provider.dart';
import 'package:provider/provider.dart';

import '../../../../../models/service_with_promo.dart';

/// Fonction de haut niveau pour ajouter un service au panier.
///
/// Elle accède au `CartProvider` pour y ajouter le service spécifié,
/// puis affiche une notification de confirmation (`SnackBar`) à l'utilisateur.
///
/// [context] : Le `BuildContext` nécessaire pour accéder au `CartProvider` et au `ScaffoldMessenger`.
/// [serviceWithPromo] : L'objet service à ajouter au panier.
/// [userId] : L'identifiant de l'utilisateur pour lequel le service est ajouté.
void addToCart({
  required BuildContext context,
  required ServiceWithPromo serviceWithPromo,
  required String userId,
}) {
  // Utilise Provider.of pour obtenir une instance du CartProvider sans écouter les changements.
  // C'est la méthode appropriée pour appeler une action sur un provider.
  Provider.of<CartProvider>(context, listen: false).addToCart(serviceWithPromo, userId);

  // Affiche un message de débogage pour suivre l'action.
  debugPrint("addToCart() called for service from add_to_card_service.dart : ${serviceWithPromo.intitule}, ID: ${serviceWithPromo.id}");

  // Affiche une notification visuelle à l'utilisateur pour confirmer l'ajout.
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text("${serviceWithPromo.intitule} ajouté au panier"),
      backgroundColor: Colors.green,
    ),
  );
}







// import 'package:flutter/material.dart';
// import 'package:hairbnb/services/providers/cart_provider.dart';
// import 'package:provider/provider.dart';
//
// import '../../../../../models/service_with_promo.dart';
//
// void addToCart({
//   required BuildContext context,
//   required ServiceWithPromo serviceWithPromo,
//   required String userId,
// }) {
//   Provider.of<CartProvider>(context, listen: false).addToCart(serviceWithPromo, userId);
//   debugPrint("🛒 addToCart() called for service from add_to_card_service.dart : ${serviceWithPromo.intitule}, ID: ${serviceWithPromo.id}");
//   ScaffoldMessenger.of(context).showSnackBar(
//     SnackBar(
//       content: Text("${serviceWithPromo.intitule} ajouté au panier ✅"),
//       backgroundColor: Colors.green,
//     ),
//   );
// }
