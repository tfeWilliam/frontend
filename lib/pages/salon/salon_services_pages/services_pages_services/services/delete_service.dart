////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//          FONCTION DE LOGIQUE MÉTIER POUR LA SUPPRESSION DE SERVICE           //
//                                                                            //
//  Ce fichier contient une fonction utilitaire unique, `deleteService`, qui  //
//  encapsule la logique complète pour supprimer un service.                  //
//                                                                            //
//  Cette fonction est conçue pour être appelée depuis un widget `Stateful`   //
//  et agit directement sur l'état de ce dernier en recevant la fonction      //
//  `setState` et les listes de données en tant que paramètres. Elle gère     //
//  l'appel à l'API backend, la mise à jour de l'état local et l'affichage    //
//  de notifications à l'utilisateur.                                         //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

// Importations nécessaires
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Gère la suppression d'un service en appelant l'API backend et en mettant à
/// jour l'état de l'interface utilisateur via des callbacks.
///
/// Cette fonction utilise une approche de gestion d'état par callbacks, où la
/// fonction `setState` et les listes de données du widget appelant sont passées
/// directement en paramètres pour être modifiées.
///
/// [serviceId] : L'ID du service à supprimer.
/// [context] : Le `BuildContext` pour afficher les `SnackBar`.
/// [showError] : Un callback pour afficher un message d'erreur dans le widget parent.
/// [setState] : Le callback `setState` du widget parent, utilisé pour déclencher une reconstruction de l'UI.
/// [services] : La liste complète des services (master list) de l'état parent, qui sera directement mutée.
/// [filteredServices] : La liste filtrée des services de l'état parent, qui sera aussi directement mutée.
/// [totalServices] : Le nombre total de services. NOTE : La modification de cet `int`
///   ici n'affectera pas la variable originale dans le widget parent car les types
///   primitifs comme `int` sont passés par valeur en Dart.
Future<void> deleteService(int serviceId, BuildContext context, Function(String) showError,
    Function(void Function()) setState, List services, List filteredServices, int totalServices) async {

  // Construit l'URL pour l'endpoint de suppression.
  final url = Uri.parse('https://www.hairbnb.site/api/delete_service/$serviceId/');
  try {
    // Effectue la requête HTTP DELETE.
    final response = await http.delete(url);

    // Vérifie si la suppression a réussi côté backend.
    if (response.statusCode == 200) {
      // Appelle le `setState` du widget parent pour mettre à jour l'interface.
      setState(() {
        // Supprime le service des deux listes (la liste complète et la liste filtrée).
        services.removeWhere((s) => s.id == serviceId);
        filteredServices.removeWhere((s) => s.id == serviceId);
        // NOTE : Cette décrémentation n'affectera que la copie locale de la variable.
        totalServices--;
      });

      // Affiche une notification de succès à l'utilisateur.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Service supprimé avec succès ✅"), backgroundColor: Colors.green),
      );
    } else {
      // Si l'API renvoie une erreur, utilise le callback pour l'afficher.
      showError("Erreur lors de la suppression.");
    }
  } catch (e) {
    // En cas d'erreur de connexion, utilise le callback pour l'afficher.
    showError("Erreur de connexion au serveur.");
  }
}








// // Importations nécessaires
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
//
// Future<void> deleteService(int serviceId, BuildContext context, Function(String) showError,
//     Function(void Function()) setState, List services, List filteredServices, int totalServices) async {
//   final url = Uri.parse('https://www.hairbnb.site/api/delete_service/$serviceId/');
//   try {
//     final response = await http.delete(url);
//     if (response.statusCode == 200) {
//       setState(() {
//         services.removeWhere((s) => s.id == serviceId);
//         filteredServices.removeWhere((s) => s.id == serviceId);
//         totalServices--; // mise à jour du total
//       });
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Service supprimé avec succès ✅"), backgroundColor: Colors.green),
//       );
//     } else {
//       showError("Erreur lors de la suppression.");
//     }
//   } catch (e) {
//     showError("Erreur de connexion au serveur.");
//   }
// }