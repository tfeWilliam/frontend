/// **************************************************************************************
///
/// PAGE UI : MES AVIS EN ATTENTE
/// Fichier: screens/mes_avis_en_attente_screen.dart
///
/// OBJECTIF :
/// Ce fichier définit l'interface utilisateur qui affiche à l'utilisateur la liste
/// de ses rendez-vous passés pour lesquels il n'a pas encore laissé d'avis.
///
/// ARCHITECTURE ET FONCTIONNALITÉS CLÉS :
/// - Utilise un `StatefulWidget` pour gérer son propre cycle de vie et son état,
/// notamment le chargement des données, les erreurs et la liste des rendez-vous.
/// - Interagit avec le backend via la classe de service statique `AvisService`.
/// - Gère explicitement plusieurs états de l'interface : chargement, erreur,
/// liste vide, et affichage des données.
/// - Implémente la fonctionnalité "tirer pour rafraîchir" (`RefreshIndicator`).
/// - Gère la navigation vers l'écran de création d'avis (`CreerAvisScreen`) et
/// rafraîchit automatiquement la liste au retour si un nouvel avis a été soumis.
///
///***************************************************************************************
library;

import 'package:flutter/material.dart';

import '../../models/avis.dart';
import 'creer_avis_page.dart';
import 'services/avis_service.dart';

/// Un écran qui liste les rendez-vous d'un utilisateur en attente d'un avis.
class MesAvisEnAttenteScreen extends StatefulWidget {
  const MesAvisEnAttenteScreen({super.key});

  @override
  _MesAvisEnAttenteScreenState createState() => _MesAvisEnAttenteScreenState();
}

class _MesAvisEnAttenteScreenState extends State<MesAvisEnAttenteScreen> {
  /// Contient la réponse de l'API avec la liste des RDV éligibles.
  RdvEligiblesResponse? _rdvResponse;
  /// Gère l'affichage de l'indicateur de chargement.
  bool _isLoading = true;
  /// Stocke le message d'erreur en cas d'échec du chargement.
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _chargerRdvEligibles();
  }

  /// Méthode asynchrone pour charger les rendez-vous éligibles depuis l'API.
  /// Gère les états de chargement et d'erreur de la page.
  Future<void> _chargerRdvEligibles() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final rdvResponse = await AvisService.getRdvEligibles();

      if (mounted) {
        setState(() {
          _rdvResponse = rdvResponse;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// Gère la navigation vers l'écran de création d'avis.
  /// Attend le retour de cet écran et rafraîchit la liste si un avis a été créé.
  void _naviguerVersCreationAvis(RdvEligible rdv) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreerAvisScreen(rdv: rdv),
      ),
    ).then((avisCreated) {
      // Si `CreerAvisScreen` retourne `true`, cela signifie qu'un avis a été soumis avec succès.
      if (avisCreated == true) {
        _chargerRdvEligibles(); // Rafraîchit la liste pour retirer le RDV évalué.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 8), Text('Liste des avis mise à jour !')]),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  /// Construit la carte d'information pour un seul rendez-vous éligible.
  Widget _buildRdvCard(RdvEligible rdv) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec le logo et le nom du salon.
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[200]),
                  child: rdv.logoUrl.isNotEmpty
                      ? ClipOval(
                    child: Image.network(
                      rdv.logoUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.store, color: Colors.grey[400]),
                    ),
                  )
                      : Icon(Icons.store, color: Colors.grey[400]),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rdv.salonNom, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      if (rdv.salonAdresse != null) Text(rdv.salonAdresse!, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Section avec les détails du rendez-vous.
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: [
                  _buildInfoRow(Icons.calendar_today, 'Date & Heure', rdv.dateFormatee),
                  SizedBox(height: 8),
                  _buildInfoRow(Icons.content_cut, 'Services', rdv.servicesTexte),
                  SizedBox(height: 8),
                  _buildInfoRow(Icons.euro, 'Prix total', rdv.prixFormate),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Bouton d'action pour laisser un avis.
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _naviguerVersCreationAvis(rdv),
                icon: Icon(Icons.rate_review),
                label: Text('Donner mon avis'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit une ligne d'information standardisée avec icône, libellé et valeur.
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        SizedBox(width: 8),
        Text('$label: ', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[700])),
        Expanded(child: Text(value, style: TextStyle(color: Colors.black87))),
      ],
    );
  }

  /// Construit le widget à afficher quand il n'y a aucun avis en attente.
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_outlined, size: 80, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text('Aucun avis en attente', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[600])),
            SizedBox(height: 8),
            Text('Tous vos rendez-vous récents ont déjà reçu un avis !', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[500])),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
              child: Text('Retour à l\'accueil'),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit le widget à afficher en cas d'erreur de chargement.
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
            SizedBox(height: 16),
            Text('Erreur de chargement', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red[600])),
            SizedBox(height: 8),
            Text(_errorMessage ?? 'Une erreur est survenue', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _chargerRdvEligibles,
              icon: Icon(Icons.refresh),
              label: Text('Réessayer'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Avis en attente'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _chargerRdvEligibles,
        // Logique de construction conditionnelle basée sur l'état de la page.
        child: _isLoading
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.orange),
              SizedBox(height: 16),
              Text('Chargement des rendez-vous...', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            ],
          ),
        )
            : _errorMessage != null
            ? _buildErrorState()
            : _rdvResponse == null || !_rdvResponse!.hasAvisEnAttente
            ? _buildEmptyState()
            : ListView.builder(
          padding: EdgeInsets.symmetric(vertical: 8),
          itemCount: _rdvResponse!.rdvEligibles.length,
          itemBuilder: (context, index) {
            final rdv = _rdvResponse!.rdvEligibles[index];
            return _buildRdvCard(rdv);
          },
        ),
      ),
    );
  }
}







// import 'package:flutter/material.dart';
//
// import '../../models/avis.dart';
// import 'creer_avis_page.dart';
// import 'services/avis_service.dart';
//
// /// Un écran qui liste les rendez-vous d'un utilisateur en attente d'un avis.
// class MesAvisEnAttenteScreen extends StatefulWidget {
//   const MesAvisEnAttenteScreen({super.key});
//
//   @override
//   _MesAvisEnAttenteScreenState createState() => _MesAvisEnAttenteScreenState();
// }
//
// class _MesAvisEnAttenteScreenState extends State<MesAvisEnAttenteScreen> {
//   /// Contient la réponse de l'API avec la liste des RDV éligibles.
//   RdvEligiblesResponse? _rdvResponse;
//   /// Gère l'affichage de l'indicateur de chargement.
//   bool _isLoading = true;
//   /// Stocke le message d'erreur en cas d'échec du chargement.
//   String? _errorMessage;
//
//   @override
//   void initState() {
//     super.initState();
//     _chargerRdvEligibles();
//   }
//
//   /// Méthode asynchrone pour charger les rendez-vous éligibles depuis l'API.
//   /// Gère les états de chargement et d'erreur de la page.
//   Future<void> _chargerRdvEligibles() async {
//     try {
//       setState(() {
//         _isLoading = true;
//         _errorMessage = null;
//       });
//
//       final rdvResponse = await AvisService.getRdvEligibles();
//
//       if (mounted) {
//         setState(() {
//           _rdvResponse = rdvResponse;
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _errorMessage = e.toString();
//           _isLoading = false;
//         });
//       }
//     }
//   }
//
//   /// Gère la navigation vers l'écran de création d'avis.
//   /// Attend le retour de cet écran et rafraîchit la liste si un avis a été créé.
//   void _naviguerVersCreationAvis(RdvEligible rdv) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => CreerAvisScreen(rdv: rdv),
//       ),
//     ).then((avisCreated) {
//       // Si `CreerAvisScreen` retourne `true`, cela signifie qu'un avis a été soumis avec succès.
//       if (avisCreated == true) {
//         _chargerRdvEligibles(); // Rafraîchit la liste pour retirer le RDV évalué.
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 8), Text('Liste des avis mise à jour !')]),
//             backgroundColor: Colors.green,
//             duration: Duration(seconds: 2),
//           ),
//         );
//       }
//     });
//   }
//
//   /// Construit la carte d'information pour un seul rendez-vous éligible.
//   Widget _buildRdvCard(RdvEligible rdv) {
//     return Card(
//       margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // En-tête avec le logo et le nom du salon.
//             Row(
//               children: [
//                 Container(
//                   width: 50,
//                   height: 50,
//                   decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[200]),
//                   child: rdv.logoUrl.isNotEmpty
//                       ? ClipOval(
//                     child: Image.network(
//                       rdv.logoUrl,
//                       width: 50,
//                       height: 50,
//                       fit: BoxFit.cover,
//                       errorBuilder: (context, error, stackTrace) => Icon(Icons.store, color: Colors.grey[400]),
//                     ),
//                   )
//                       : Icon(Icons.store, color: Colors.grey[400]),
//                 ),
//                 SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(rdv.salonNom, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                       if (rdv.salonAdresse != null) Text(rdv.salonAdresse!, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 16),
//             // Section avec les détails du rendez-vous.
//             Container(
//               padding: EdgeInsets.all(12),
//               decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
//               child: Column(
//                 children: [
//                   _buildInfoRow(Icons.calendar_today, 'Date & Heure', rdv.dateFormatee),
//                   SizedBox(height: 8),
//                   _buildInfoRow(Icons.content_cut, 'Services', rdv.servicesTexte),
//                   SizedBox(height: 8),
//                   _buildInfoRow(Icons.euro, 'Prix total', rdv.prixFormate),
//                 ],
//               ),
//             ),
//             SizedBox(height: 16),
//             // Bouton d'action pour laisser un avis.
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton.icon(
//                 onPressed: () => _naviguerVersCreationAvis(rdv),
//                 icon: Icon(Icons.rate_review),
//                 label: Text('Donner mon avis'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.orange,
//                   foregroundColor: Colors.white,
//                   padding: EdgeInsets.symmetric(vertical: 12),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   /// Construit une ligne d'information standardisée avec icône, libellé et valeur.
//   Widget _buildInfoRow(IconData icon, String label, String value) {
//     return Row(
//       children: [
//         Icon(icon, size: 16, color: Colors.grey[600]),
//         SizedBox(width: 8),
//         Text('$label: ', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[700])),
//         Expanded(child: Text(value, style: TextStyle(color: Colors.black87))),
//       ],
//     );
//   }
//
//   /// Construit le widget à afficher quand il n'y a aucun avis en attente.
//   Widget _buildEmptyState() {
//     return Center(
//       child: Padding(
//         padding: EdgeInsets.all(32),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.rate_review_outlined, size: 80, color: Colors.grey[400]),
//             SizedBox(height: 16),
//             Text('Aucun avis en attente', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[600])),
//             SizedBox(height: 8),
//             Text('Tous vos rendez-vous récents ont déjà reçu un avis !', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[500])),
//             SizedBox(height: 24),
//             ElevatedButton(
//               onPressed: () => Navigator.pop(context),
//               style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
//               child: Text('Retour à l\'accueil'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   /// Construit le widget à afficher en cas d'erreur de chargement.
//   Widget _buildErrorState() {
//     return Center(
//       child: Padding(
//         padding: EdgeInsets.all(32),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
//             SizedBox(height: 16),
//             Text('Erreur de chargement', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red[600])),
//             SizedBox(height: 8),
//             Text(_errorMessage ?? 'Une erreur est survenue', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
//             SizedBox(height: 24),
//             ElevatedButton.icon(
//               onPressed: _chargerRdvEligibles,
//               icon: Icon(Icons.refresh),
//               label: Text('Réessayer'),
//               style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Avis en attente'),
//         backgroundColor: Colors.orange,
//         foregroundColor: Colors.white,
//         elevation: 0,
//       ),
//       body: RefreshIndicator(
//         onRefresh: _chargerRdvEligibles,
//         // Logique de construction conditionnelle basée sur l'état de la page.
//         child: _isLoading
//             ? Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               CircularProgressIndicator(color: Colors.orange),
//               SizedBox(height: 16),
//               Text('Chargement des rendez-vous...', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
//             ],
//           ),
//         )
//             : _errorMessage != null
//             ? _buildErrorState()
//             : _rdvResponse == null || !_rdvResponse!.hasAvisEnAttente
//             ? _buildEmptyState()
//             : ListView.builder(
//           padding: EdgeInsets.symmetric(vertical: 8),
//           itemCount: _rdvResponse!.rdvEligibles.length,
//           itemBuilder: (context, index) {
//             final rdv = _rdvResponse!.rdvEligibles[index];
//             return _buildRdvCard(rdv);
//           },
//         ),
//       ),
//     );
//   }
// }
//
//
//
//
//
//
//
//
// // // screens/mes_avis_en_attente_screen.dart
// // import 'package:flutter/foundation.dart';
// // import 'package:flutter/material.dart';
// //
// // import '../../models/avis.dart';
// // import 'creer_avis_page.dart';
// // import 'services/avis_service.dart';
// //
// // class MesAvisEnAttenteScreen extends StatefulWidget {
// //   const MesAvisEnAttenteScreen({super.key});
// //
// //   @override
// //   _MesAvisEnAttenteScreenState createState() => _MesAvisEnAttenteScreenState();
// // }
// //
// // class _MesAvisEnAttenteScreenState extends State<MesAvisEnAttenteScreen> {
// //   RdvEligiblesResponse? _rdvResponse;
// //   bool _isLoading = true;
// //   String? _errorMessage;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _chargerRdvEligibles();
// //   }
// //
// //   /// 🔄 Charger les RDV éligibles aux avis
// //   Future<void> _chargerRdvEligibles() async {
// //     try {
// //       setState(() {
// //         _isLoading = true;
// //         _errorMessage = null;
// //       });
// //
// //       final rdvResponse = await AvisService.getRdvEligibles();
// //
// //       if (mounted) {
// //         setState(() {
// //           _rdvResponse = rdvResponse;
// //           _isLoading = false;
// //         });
// //       }
// //     } catch (e) {
// //       if (kDebugMode) {
// //         print("❌ Erreur lors du chargement des RDV: $e");
// //       }
// //       if (mounted) {
// //         setState(() {
// //           _errorMessage = e.toString();
// //           _isLoading = false;
// //         });
// //       }
// //     }
// //   }
// //
// //   /// 🔔 Navigation vers création d'avis
// //   void _naviguerVersCreationAvis(RdvEligible rdv) {
// //     if (kDebugMode) {
// //       print("🔔 Navigation vers création avis pour RDV ${rdv.idRendezVous}");
// //     }
// //
// //     // 🎯 Navigation vers l'écran de création d'avis
// //     Navigator.push(
// //       context,
// //       MaterialPageRoute(
// //         builder: (context) => CreerAvisScreen(rdv: rdv),
// //       ),
// //     ).then((avisCreated) {
// //       // 🔄 Si un avis a été créé, recharger la liste
// //       if (avisCreated == true) {
// //         _chargerRdvEligibles();
// //
// //         // Message de confirmation supplémentaire
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Row(
// //               children: [
// //                 Icon(Icons.check_circle, color: Colors.white),
// //                 SizedBox(width: 8),
// //                 Text('Liste des avis mise à jour !'),
// //               ],
// //             ),
// //             backgroundColor: Colors.green,
// //             duration: Duration(seconds: 2),
// //           ),
// //         );
// //       }
// //     });
// //   }
// //
// //   /// 🎨 Construire une carte de RDV
// //   Widget _buildRdvCard(RdvEligible rdv) {
// //     return Card(
// //       margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// //       elevation: 2,
// //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// //       child: Padding(
// //         padding: EdgeInsets.all(16),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             // 🏪 En-tête salon
// //             Row(
// //               children: [
// //                 // Logo salon
// //                 Container(
// //                   width: 50,
// //                   height: 50,
// //                   decoration: BoxDecoration(
// //                     shape: BoxShape.circle,
// //                     color: Colors.grey[200],
// //                   ),
// //                   child: rdv.logoUrl.isNotEmpty
// //                       ? ClipOval(
// //                     child: Image.network(
// //                       rdv.logoUrl,
// //                       width: 50,
// //                       height: 50,
// //                       fit: BoxFit.cover,
// //                       errorBuilder: (context, error, stackTrace) {
// //                         return Icon(Icons.store, color: Colors.grey[400]);
// //                       },
// //                     ),
// //                   )
// //                       : Icon(Icons.store, color: Colors.grey[400]),
// //                 ),
// //
// //                 SizedBox(width: 12),
// //
// //                 // Infos salon
// //                 Expanded(
// //                   child: Column(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //                       Text(
// //                         rdv.salonNom,
// //                         style: TextStyle(
// //                           fontSize: 18,
// //                           fontWeight: FontWeight.bold,
// //                         ),
// //                       ),
// //                       if (rdv.salonAdresse != null)
// //                         Text(
// //                           rdv.salonAdresse!,
// //                           style: TextStyle(
// //                             fontSize: 14,
// //                             color: Colors.grey[600],
// //                           ),
// //                         ),
// //                     ],
// //                   ),
// //                 ),
// //               ],
// //             ),
// //
// //             SizedBox(height: 16),
// //
// //             // 📅 Informations du RDV
// //             Container(
// //               padding: EdgeInsets.all(12),
// //               decoration: BoxDecoration(
// //                 color: Colors.grey[50],
// //                 borderRadius: BorderRadius.circular(8),
// //               ),
// //               child: Column(
// //                 children: [
// //                   _buildInfoRow(
// //                     Icons.calendar_today,
// //                     'Date & Heure',
// //                     rdv.dateFormatee,
// //                   ),
// //                   SizedBox(height: 8),
// //                   _buildInfoRow(
// //                     Icons.content_cut,
// //                     'Services',
// //                     rdv.servicesTexte,
// //                   ),
// //                   SizedBox(height: 8),
// //                   _buildInfoRow(
// //                     Icons.euro,
// //                     'Prix total',
// //                     rdv.prixFormate,
// //                   ),
// //                 ],
// //               ),
// //             ),
// //
// //             SizedBox(height: 16),
// //
// //             // 🌟 Bouton donner avis
// //             SizedBox(
// //               width: double.infinity,
// //               child: ElevatedButton.icon(
// //                 onPressed: () => _naviguerVersCreationAvis(rdv),
// //                 icon: Icon(Icons.rate_review),
// //                 label: Text('Donner mon avis'),
// //                 style: ElevatedButton.styleFrom(
// //                   backgroundColor: Colors.orange,
// //                   foregroundColor: Colors.white,
// //                   padding: EdgeInsets.symmetric(vertical: 12),
// //                   shape: RoundedRectangleBorder(
// //                     borderRadius: BorderRadius.circular(8),
// //                   ),
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   /// 🏷️ Widget pour une ligne d'information
// //   Widget _buildInfoRow(IconData icon, String label, String value) {
// //     return Row(
// //       children: [
// //         Icon(icon, size: 16, color: Colors.grey[600]),
// //         SizedBox(width: 8),
// //         Text(
// //           '$label: ',
// //           style: TextStyle(
// //             fontWeight: FontWeight.w500,
// //             color: Colors.grey[700],
// //           ),
// //         ),
// //         Expanded(
// //           child: Text(
// //             value,
// //             style: TextStyle(
// //               color: Colors.black87,
// //             ),
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// //
// //   /// 🔄 Widget d'état vide
// //   Widget _buildEmptyState() {
// //     return Center(
// //       child: Padding(
// //         padding: EdgeInsets.all(32),
// //         child: Column(
// //           mainAxisAlignment: MainAxisAlignment.center,
// //           children: [
// //             Icon(
// //               Icons.rate_review_outlined,
// //               size: 80,
// //               color: Colors.grey[400],
// //             ),
// //             SizedBox(height: 16),
// //             Text(
// //               'Aucun avis en attente',
// //               style: TextStyle(
// //                 fontSize: 20,
// //                 fontWeight: FontWeight.bold,
// //                 color: Colors.grey[600],
// //               ),
// //             ),
// //             SizedBox(height: 8),
// //             Text(
// //               'Tous vos rendez-vous récents ont déjà reçu un avis !',
// //               textAlign: TextAlign.center,
// //               style: TextStyle(
// //                 fontSize: 16,
// //                 color: Colors.grey[500],
// //               ),
// //             ),
// //             SizedBox(height: 24),
// //             ElevatedButton(
// //               onPressed: () => Navigator.pop(context),
// //               style: ElevatedButton.styleFrom(
// //                 backgroundColor: Colors.orange,
// //                 foregroundColor: Colors.white,
// //               ),
// //               child: Text('Retour à l\'accueil'),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   /// ❌ Widget d'état d'erreur
// //   Widget _buildErrorState() {
// //     return Center(
// //       child: Padding(
// //         padding: EdgeInsets.all(32),
// //         child: Column(
// //           mainAxisAlignment: MainAxisAlignment.center,
// //           children: [
// //             Icon(
// //               Icons.error_outline,
// //               size: 80,
// //               color: Colors.red[400],
// //             ),
// //             SizedBox(height: 16),
// //             Text(
// //               'Erreur de chargement',
// //               style: TextStyle(
// //                 fontSize: 20,
// //                 fontWeight: FontWeight.bold,
// //                 color: Colors.red[600],
// //               ),
// //             ),
// //             SizedBox(height: 8),
// //             Text(
// //               _errorMessage ?? 'Une erreur est survenue',
// //               textAlign: TextAlign.center,
// //               style: TextStyle(
// //                 fontSize: 16,
// //                 color: Colors.grey[600],
// //               ),
// //             ),
// //             SizedBox(height: 24),
// //             ElevatedButton.icon(
// //               onPressed: _chargerRdvEligibles,
// //               icon: Icon(Icons.refresh),
// //               label: Text('Réessayer'),
// //               style: ElevatedButton.styleFrom(
// //                 backgroundColor: Colors.orange,
// //                 foregroundColor: Colors.white,
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text('Avis en attente'),
// //         backgroundColor: Colors.orange,
// //         foregroundColor: Colors.white,
// //         elevation: 0,
// //       ),
// //       body: RefreshIndicator(
// //         onRefresh: _chargerRdvEligibles,
// //         child: _isLoading
// //             ? Center(
// //           child: Column(
// //             mainAxisAlignment: MainAxisAlignment.center,
// //             children: [
// //               CircularProgressIndicator(color: Colors.orange),
// //               SizedBox(height: 16),
// //               Text(
// //                 'Chargement des rendez-vous...',
// //                 style: TextStyle(
// //                   fontSize: 16,
// //                   color: Colors.grey[600],
// //                 ),
// //               ),
// //             ],
// //           ),
// //         )
// //             : _errorMessage != null
// //             ? _buildErrorState()
// //             : _rdvResponse == null || !_rdvResponse!.hasAvisEnAttente
// //             ? _buildEmptyState()
// //             : ListView.builder(
// //           padding: EdgeInsets.symmetric(vertical: 8),
// //           itemCount: _rdvResponse!.rdvEligibles.length,
// //           itemBuilder: (context, index) {
// //             final rdv = _rdvResponse!.rdvEligibles[index];
// //             return _buildRdvCard(rdv);
// //           },
// //         ),
// //       ),
// //     );
// //   }
// // }
