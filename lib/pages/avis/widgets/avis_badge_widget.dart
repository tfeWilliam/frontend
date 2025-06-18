////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                WIDGETS POUR LE BADGE D'AVIS EN ATTENTE                       //
//                                                                            //
//  Ce fichier définit un composant UI réutilisable et auto-géré (`AvisBadge`) //
//  qui affiche le nombre d'avis en attente pour un utilisateur. Il gère son   //
//  propre état de chargement, d'erreur et de données en appelant le           //
//  `AvisService`.                                                            //
//                                                                            //
//  Il propose deux modes d'affichage (icône seule ou avec texte) et expose   //
//  deux widgets de convenance (`AvisBadgeIcon`, `AvisBadgeText`) pour une     //
//  utilisation simplifiée dans l'application.                                //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/avis_service.dart';

//##############################################################################
//#                   WIDGET PRINCIPAL ET ÉTAT-MAJOR (STATEFUL)                #
//##############################################################################

/// Un widget qui affiche un badge indiquant le nombre d'avis en attente.
/// Il est capable de s'afficher soit comme une icône avec un badge, soit
/// comme un conteneur avec une icône et du texte.
class AvisBadgeWidget extends StatefulWidget {
  /// La fonction à appeler lorsque l'utilisateur clique sur le widget.
  final VoidCallback? onTap;
  /// Si `true`, affiche l'icône et le texte. Si `false`, affiche uniquement l'icône avec le badge.
  final bool showText;

  /// Constructeur du widget de badge d'avis.
  const AvisBadgeWidget({
    super.key,
    this.onTap,
    this.showText = true,
  });

  @override
  _AvisBadgeWidgetState createState() => _AvisBadgeWidgetState();
}

/// La classe d'état pour `AvisBadgeWidget`.
/// Gère la récupération des données, l'état de chargement/erreur et la reconstruction de l'UI.
class _AvisBadgeWidgetState extends State<AvisBadgeWidget> {
  /// Le nombre d'avis en attente à afficher.
  int _avisCount = 0;
  /// `true` si les données sont en cours de chargement.
  bool _isLoading = true;
  /// `true` si une erreur est survenue lors du chargement.
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // Déclenche le chargement des données dès l'initialisation du widget.
    _chargerAvisEnAttente();
  }

  /// Méthode asynchrone pour récupérer le nombre d'avis en attente depuis `AvisService`.
  Future<void> _chargerAvisEnAttente() async {
    try {
      // Met à jour l'UI pour afficher l'état de chargement.
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final count = await AvisService.getCountAvisEnAttente();

      // S'assure que le widget est toujours "monté" avant de mettre à jour l'état,
      // pour éviter les erreurs si l'utilisateur quitte la page pendant le chargement.
      if (mounted) {
        setState(() {
          _avisCount = count;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors du chargement des avis: $e");
      }
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          _avisCount = 0; // Réinitialise le compteur en cas d'erreur.
        });
      }
    }
  }

  /// Construit le badge rouge contenant le nombre, superposé à un widget enfant.
  Widget _buildBadge({required Widget child}) {
    // N'affiche pas le badge si le compteur est à zéro.
    if (_avisCount == 0) {
      return child;
    }

    // `Stack` permet de superposer des widgets.
    return Stack(
      clipBehavior: Clip.none, // Permet au badge de déborder légèrement.
      children: [
        child, // Le widget principal (ex: une icône).
        // Le badge rouge positionné en haut à droite.
        Positioned(
          right: -5,
          top: -5,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            constraints: const BoxConstraints(
              minWidth: 20,
              minHeight: 20,
            ),
            child: Text(
              '$_avisCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Pendant le chargement, affiche un indicateur de progression.
    if (_isLoading) {
      return widget.showText
          ? const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 8),
          Text('Chargement...', style: TextStyle(fontSize: 14)),
        ],
      )
          : const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2));
    }

    // N'affiche rien du tout si une erreur est survenue ou s'il n'y a aucun avis.
    if (_hasError || _avisCount == 0) {
      return const SizedBox.shrink(); // Un widget vide et de taille nulle.
    }

    // Construit le widget principal à afficher.
    Widget mainWidget;
    if (widget.showText) {
      // Version avec texte (pour les menus, etc.).
      mainWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.rate_review, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            Text(
              '$_avisCount avis en attente',
              style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
      );
    } else {
      // Version avec icône seule (pour les barres d'applications, etc.).
      mainWidget = _buildBadge(
        child: const Icon(Icons.rate_review, color: Colors.orange, size: 24),
      );
    }

    // Enveloppe le widget final dans un `GestureDetector` pour le rendre cliquable.
    return GestureDetector(
      onTap: widget.onTap,
      child: mainWidget,
    );
  }

  /// Méthode publique qui peut être appelée depuis l'extérieur (via une GlobalKey)
  /// pour forcer le rechargement des données du badge.
  void refresh() {
    _chargerAvisEnAttente();
  }
}

//##############################################################################
//#                   WIDGETS DE CONVENANCE (STATELESS)                        #
//##############################################################################

/// Widget de convenance qui affiche `AvisBadgeWidget` en mode "icône seule".
class AvisBadgeIcon extends StatelessWidget {
  final VoidCallback? onTap;

  const AvisBadgeIcon({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return AvisBadgeWidget(
      onTap: onTap,
      showText: false, // Force le mode icône.
    );
  }
}

/// Widget de convenance qui affiche `AvisBadgeWidget` en mode "texte et icône".
class AvisBadgeText extends StatelessWidget {
  final VoidCallback? onTap;

  const AvisBadgeText({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return AvisBadgeWidget(
      onTap: onTap,
      showText: true, // Force le mode texte.
    );
  }
}





// // widgets/avis_badge_widget.dart
// import 'package:flutter/material.dart';
// import '../services/avis_service.dart';
//
// class AvisBadgeWidget extends StatefulWidget {
//   final VoidCallback? onTap; // Fonction appelée quand on clique sur le badge
//   final bool showText; // Afficher le texte ou juste l'icône avec badge
//
//   const AvisBadgeWidget({
//     Key? key,
//     this.onTap,
//     this.showText = true,
//   }) : super(key: key);
//
//   @override
//   _AvisBadgeWidgetState createState() => _AvisBadgeWidgetState();
// }
//
// class _AvisBadgeWidgetState extends State<AvisBadgeWidget> {
//   int _avisCount = 0;
//   bool _isLoading = true;
//   bool _hasError = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _chargerAvisEnAttente();
//   }
//
//   /// 🔄 Charger le nombre d'avis en attente
//   Future<void> _chargerAvisEnAttente() async {
//     try {
//       setState(() {
//         _isLoading = true;
//         _hasError = false;
//       });
//
//       final count = await AvisService.getCountAvisEnAttente();
//
//       if (mounted) {
//         setState(() {
//           _avisCount = count;
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       print("❌ Erreur lors du chargement des avis: $e");
//       if (mounted) {
//         setState(() {
//           _hasError = true;
//           _isLoading = false;
//           _avisCount = 0; // En cas d'erreur, on cache le badge
//         });
//       }
//     }
//   }
//
//   /// 🎨 Construire le badge avec nombre
//   Widget _buildBadge({required Widget child}) {
//     if (_avisCount == 0) {
//       return child; // Pas de badge si aucun avis
//     }
//
//     return Stack(
//       children: [
//         child,
//         Positioned(
//           right: 0,
//           top: 0,
//           child: Container(
//             padding: EdgeInsets.all(2),
//             decoration: BoxDecoration(
//               color: Colors.red,
//               borderRadius: BorderRadius.circular(10),
//             ),
//             constraints: BoxConstraints(
//               minWidth: 20,
//               minHeight: 20,
//             ),
//             child: Text(
//               '$_avisCount',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 12,
//                 fontWeight: FontWeight.bold,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // 🔄 Affichage pendant le chargement
//     if (_isLoading) {
//       return widget.showText
//           ? Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           SizedBox(
//             width: 16,
//             height: 16,
//             child: CircularProgressIndicator(strokeWidth: 2),
//           ),
//           SizedBox(width: 8),
//           Text('Chargement...', style: TextStyle(fontSize: 14)),
//         ],
//       )
//           : SizedBox(
//         width: 24,
//         height: 24,
//         child: CircularProgressIndicator(strokeWidth: 2),
//       );
//     }
//
//     // ❌ Pas d'affichage si erreur ou aucun avis
//     if (_hasError || _avisCount == 0) {
//       return SizedBox.shrink();
//     }
//
//     // 🎯 Widget principal avec badge
//     Widget mainWidget;
//
//     if (widget.showText) {
//       // Version avec texte (pour menu, drawer, etc.)
//       mainWidget = Container(
//         padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//         decoration: BoxDecoration(
//           color: Colors.orange.shade50,
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(color: Colors.orange.shade200),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               Icons.rate_review,
//               color: Colors.orange,
//               size: 20,
//             ),
//             SizedBox(width: 8),
//             Text(
//               '$_avisCount avis en attente',
//               style: TextStyle(
//                 color: Colors.orange.shade700,
//                 fontWeight: FontWeight.w600,
//                 fontSize: 14,
//               ),
//             ),
//           ],
//         ),
//       );
//     } else {
//       // Version icône seule (pour app bar, etc.)
//       mainWidget = _buildBadge(
//         child: Icon(
//           Icons.rate_review,
//           color: Colors.orange,
//           size: 24,
//         ),
//       );
//     }
//
//     // 🖱️ Ajouter la gestion du clic
//     return GestureDetector(
//       onTap: widget.onTap,
//       child: mainWidget,
//     );
//   }
//
//   /// 🔄 Méthode publique pour recharger les données
//   void refresh() {
//     _chargerAvisEnAttente();
//   }
// }
//
// /// 🎯 Widget simplifié pour une utilisation rapide dans l'AppBar
// class AvisBadgeIcon extends StatelessWidget {
//   final VoidCallback? onTap;
//
//   const AvisBadgeIcon({Key? key, this.onTap}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return AvisBadgeWidget(
//       onTap: onTap,
//       showText: false,
//     );
//   }
// }
//
// /// 🎯 Widget avec texte pour menus/drawer
// class AvisBadgeText extends StatelessWidget {
//   final VoidCallback? onTap;
//
//   const AvisBadgeText({Key? key, this.onTap}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return AvisBadgeWidget(
//       onTap: onTap,
//       showText: true,
//     );
//   }
// }