////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                PAGE D'INTERFACE UTILISATEUR POUR "MES AVIS"                  //
//                                                                            //
//  Ce fichier définit l'écran `MesAvisPage`, qui permet à un utilisateur de  //
//  consulter, modifier et supprimer tous les avis qu'il a précédemment       //
//  laissés sur des salons.                                                   //
//                                                                            //
//  Fonctionnalités :                                                         //
//  - Récupération et affichage d'une liste des avis de l'utilisateur.        //
//  - Gestion des états UI : chargement, erreur, et liste vide.               //
//  - Possibilité de rafraîchir la liste via `RefreshIndicator`.              //
//  - Boîte de dialogue pour la modification d'un avis (`_ModifierAvisDialog`).//
//  - Boîte de dialogue de confirmation pour la suppression d'un avis.        //
//  - Interaction avec `AvisService` pour toutes les opérations de données.   //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/avis.dart';
import 'services/avis_service.dart';

/// Widget principal de la page "Mes avis".
class MesAvisPage extends StatefulWidget {
  const MesAvisPage({super.key});

  @override
  _MesAvisPageState createState() => _MesAvisPageState();
}

/// Classe d'état pour `MesAvisPage`.
/// Gère la liste des avis, l'état de chargement/erreur, et les interactions utilisateur.
class _MesAvisPageState extends State<MesAvisPage> {
  /// La liste des avis de l'utilisateur.
  List<Avis> _mesAvis = [];
  /// `true` si les données sont en cours de chargement.
  bool _isLoading = true;
  /// Stocke un message d'erreur en cas d'échec du chargement.
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Déclenche le chargement des données dès l'initialisation de la page.
    _chargerMesAvis();
  }

  //region Logique Métier (Chargement, Modification, Suppression)

  /// Récupère la liste des avis de l'utilisateur depuis le service.
  Future<void> _chargerMesAvis() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final avisList = await AvisService.getMesAvis(context: context);

      // Vérifie que le widget est toujours "monté" avant de mettre à jour l'état.
      if (mounted) {
        setState(() {
          _mesAvis = avisList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors du chargement des avis: $e");
      }
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// Ouvre une boîte de dialogue pour modifier un avis existant.
  void _modifierAvis(Avis avis) {
    showDialog(
      context: context,
      builder: (context) => _ModifierAvisDialog(
        avis: avis,
        // Le callback `onAvisModifie` est appelé pour rafraîchir la liste après une modification réussie.
        onAvisModifie: () {
          _chargerMesAvis();
        },
      ),
    );
  }

  /// Ouvre une boîte de dialogue pour confirmer la suppression d'un avis.
  void _supprimerAvis(Avis avis) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [Icon(Icons.warning, color: Colors.red), SizedBox(width: 8), Text('Supprimer l\'avis')],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Êtes-vous sûr de vouloir supprimer cet avis ?'),
            const SizedBox(height: 12),
            // Affiche un aperçu de l'avis à supprimer.
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(avis.salonNom ?? 'Salon inconnu', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(children: [
                    ...List.generate(5, (i) => Icon(Icons.star, size: 16, color: i < avis.note ? Colors.amber : Colors.grey[300])),
                    const SizedBox(width: 8),
                    Text('${avis.note}/5'),
                  ]),
                  const SizedBox(height: 4),
                  Text(avis.commentaire, style: TextStyle(fontSize: 12, color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text('Cette action est irréversible.', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Ferme la confirmation avant de lancer la suppression.
              await _confirmerSuppressionAvis(avis);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  /// Gère l'appel au service de suppression et affiche les retours à l'utilisateur.
  Future<void> _confirmerSuppressionAvis(Avis avis) async {
    try {
      // Affiche un indicateur de chargement pendant la suppression.
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(color: Colors.red),
            SizedBox(height: 16),
            Text('Suppression en cours...'),
          ]),
        ),
      );

      final result = await AvisService.supprimerAvis(context: context, avisId: avis.id!);

      if (mounted) Navigator.pop(context); // Ferme le loader.

      if (result.success) {
        // Affiche un message de succès.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 8), Expanded(child: Text("Avis supprimé avec succès"))]),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        _chargerMesAvis(); // Recharge la liste.
      } else {
        // Affiche un message d'erreur.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [const Icon(Icons.error, color: Colors.white), const SizedBox(width: 8), Expanded(child: Text(result.message))]),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // S'assure de fermer le loader même en cas d'erreur.
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de la suppression: $e'), backgroundColor: Colors.red));
    }
  }

  //endregion

  //region Méthodes de construction de l'UI (Widgets)

  /// Construit la carte stylisée pour afficher un avis individuel.
  Widget _buildAvisCard(Avis avis) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec logo, nom du salon et menu d'actions.
            Row(
              children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[200]),
                  child: avis.logoUrl.isNotEmpty
                      ? ClipOval(child: Image.network(avis.logoUrl, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c, o, s) => Icon(Icons.store, color: Colors.grey[400])))
                      : Icon(Icons.store, color: Colors.grey[400]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(avis.salonNom ?? 'Salon inconnu', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                      if (avis.dateFormatee.isNotEmpty) Text('Avis donné le ${avis.dateFormatee}', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    ],
                  ),
                ),
                // Menu "pop-up" pour les actions Modifier/Supprimer.
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                  onSelected: (value) {
                    if (value == 'modifier') _modifierAvis(avis);
                    if (value == 'supprimer') _supprimerAvis(avis);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'modifier', child: Row(children: [Icon(Icons.edit, color: Colors.blue, size: 20), SizedBox(width: 8), Text('Modifier')])),
                    const PopupMenuItem(value: 'supprimer', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 20), SizedBox(width: 8), Text('Supprimer')])),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Affichage de la note en étoiles avec un badge de texte.
            Row(
              children: [
                ...List.generate(5, (i) => Icon(Icons.star, size: 24, color: i < avis.note ? Colors.amber : Colors.grey[300])),
                const SizedBox(width: 8),
                Text('${avis.note}/5', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: _getCouleurNote(avis.note), borderRadius: BorderRadius.circular(12)),
                  child: Text(_getTexteNote(avis.note), style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Affichage du commentaire de l'utilisateur.
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[200]!)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [Icon(Icons.format_quote, color: Colors.grey[500], size: 16), const SizedBox(width: 4), Text('Mon commentaire', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600]))]),
                  const SizedBox(height: 8),
                  Text(avis.commentaire, style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Retourne une couleur en fonction de la note pour le badge de texte.
  Color _getCouleurNote(int note) {
    if (note <= 2) return Colors.red;
    if (note == 3) return Colors.orange;
    if (note == 4) return Colors.blue;
    return Colors.green;
  }

  /// Retourne un texte descriptif en fonction de la note.
  String _getTexteNote(int note) {
    switch (note) {
      case 1: return 'Très décevant';
      case 2: return 'Décevant';
      case 3: return 'Correct';
      case 4: return 'Très bien';
      case 5: return 'Excellent';
      default: return '';
    }
  }

  /// Construit le widget à afficher lorsque la liste d'avis est vide.
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Aucun avis donné', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[600])),
            const SizedBox(height: 8),
            const Text('Vous n\'avez pas encore donné d\'avis sur vos rendez-vous.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Retour'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text('Erreur de chargement', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red[600])),
            const SizedBox(height: 8),
            Text(_errorMessage ?? 'Une erreur est survenue', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _chargerMesAvis,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
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
        title: const Text('Mes avis'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_mesAvis.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(15)),
                  child: Text('${_mesAvis.length} avis', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
        ],
      ),
      // Le `RefreshIndicator` permet de recharger la liste en glissant vers le bas.
      body: RefreshIndicator(
        onRefresh: _chargerMesAvis,
        // La logique conditionnelle principale pour afficher le bon état de l'UI.
        child: _isLoading
            ? _buildLoadingIndicator()
            : _errorMessage != null
            ? _buildErrorState()
            : _mesAvis.isEmpty
            ? _buildEmptyState()
            : _buildPopulatedList(),
      ),
    );
  }

  /// Construit le widget de chargement principal.
  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.orange),
          const SizedBox(height: 16),
          Text('Chargement de vos avis...', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        ],
      ),
    );
  }

  /// Construit la vue principale lorsque la liste des avis est chargée.
  Widget _buildPopulatedList() {
    return Column(
      children: [
        // En-tête avec les statistiques (nombre d'avis et note moyenne).
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Colors.orange, Colors.deepOrange], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text('${_mesAvis.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    const Text('Avis donnés', style: TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white30),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      (_mesAvis.map((a) => a.note).reduce((a, b) => a + b) / _mesAvis.length).toStringAsFixed(1),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const Text('Note moyenne', style: TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
        ),
        // La liste des avis, qui prend l'espace restant.
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: _mesAvis.length,
            itemBuilder: (context, index) {
              final avis = _mesAvis[index];
              return _buildAvisCard(avis);
            },
          ),
        ),
      ],
    );
  }

//endregion
}

//##############################################################################
//#                   DIALOGUE DE MODIFICATION D'UN AVIS                       #
//##############################################################################

/// Un `StatefulWidget` privé qui représente la boîte de dialogue pour modifier un avis.
class _ModifierAvisDialog extends StatefulWidget {
  /// L'avis original à modifier.
  final Avis avis;
  /// Le callback à exécuter après une modification réussie pour rafraîchir la liste.
  final VoidCallback onAvisModifie;

  const _ModifierAvisDialog({required this.avis, required this.onAvisModifie});

  @override
  _ModifierAvisDialogState createState() => _ModifierAvisDialogState();
}

/// La classe d'état pour la boîte de dialogue de modification.
class _ModifierAvisDialogState extends State<_ModifierAvisDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _commentaireController;
  late int _note;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Pré-remplit les champs avec les données de l'avis existant.
    _commentaireController = TextEditingController(text: widget.avis.commentaire);
    _note = widget.avis.note;
  }

  @override
  void dispose() {
    _commentaireController.dispose();
    super.dispose();
  }

  /// Construit le sélecteur d'étoiles interactif.
  Widget _buildStarRating() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nouvelle note', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starNumber = index + 1;
            return GestureDetector(
              onTap: () => setState(() => _note = starNumber),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  starNumber <= _note ? Icons.star : Icons.star_border,
                  size: 35,
                  color: starNumber <= _note ? Colors.amber : Colors.grey[400],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  /// Gère la soumission du formulaire de modification.
  Future<void> _soumettreModification() async {
    // Valide le formulaire avant de continuer.
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final result = await AvisService.modifierAvis(
        context: context,
        avisId: widget.avis.id!,
        note: _note,
        commentaire: _commentaireController.text.trim(),
      );

      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Avis modifié avec succès"), backgroundColor: Colors.green));
          Navigator.pop(context); // Ferme la boîte de dialogue.
          widget.onAvisModifie(); // Appelle le callback pour rafraîchir la liste.
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur inattendue: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête de la boîte de dialogue.
              Row(
                children: [
                  const Icon(Icons.edit, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Modifier mon avis', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold))),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 16),
              // Rappel du salon concerné.
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                child: Row(children: [const Icon(Icons.store), const SizedBox(width: 8), Expanded(child: Text(widget.avis.salonNom ?? 'Salon inconnu', style: const TextStyle(fontWeight: FontWeight.w600)))]),
              ),
              const SizedBox(height: 20),
              // Sélecteur de note.
              _buildStarRating(),
              const SizedBox(height: 20),
              // Champ de saisie pour le commentaire.
              const Text('Nouveau commentaire', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: TextFormField(
                  controller: _commentaireController,
                  maxLines: null, expands: true, maxLength: 500,
                  decoration: const InputDecoration(
                    hintText: 'Modifiez votre commentaire... (minimum 10 caractères)',
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.orange, width: 2)),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 10) {
                      return 'Le commentaire doit contenir au moins 10 caractères';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 20),
              // Boutons d'action (Annuler, Modifier).
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: _isSubmitting ? null : () => Navigator.pop(context), child: const Text('Annuler'))),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _soumettreModification,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                      child: _isSubmitting
                          ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)), SizedBox(width: 8), Text('Modification...')])
                          : const Text('Modifier'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}









// // pages/avis/mes_avis_page.dart
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
//
// import '../../models/avis.dart';
// import 'services/avis_service.dart';
//
// class MesAvisPage extends StatefulWidget {
//   const MesAvisPage({super.key});
//
//   @override
//   _MesAvisPageState createState() => _MesAvisPageState();
// }
//
// class _MesAvisPageState extends State<MesAvisPage> {
//   List<Avis> _mesAvis = [];
//   bool _isLoading = true;
//   String? _errorMessage;
//
//   @override
//   void initState() {
//     super.initState();
//     _chargerMesAvis();
//   }
//
//   /// 🔄 Charger tous mes avis
//   Future<void> _chargerMesAvis() async {
//     try {
//       setState(() {
//         _isLoading = true;
//         _errorMessage = null;
//       });
//
//       final avisList = await AvisService.getMesAvis(context: context);
//
//       if (mounted) {
//         setState(() {
//           _mesAvis = avisList;
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print("❌ Erreur lors du chargement des avis: $e");
//       }
//       if (mounted) {
//         setState(() {
//           _errorMessage = e.toString();
//           _isLoading = false;
//         });
//       }
//     }
//   }
//
//   /// ✏️ Modifier un avis
//   void _modifierAvis(Avis avis) {
//     showDialog(
//       context: context,
//       builder: (context) => _ModifierAvisDialog(
//         avis: avis,
//         onAvisModifie: () {
//           _chargerMesAvis(); // Recharger la liste
//         },
//       ),
//     );
//   }
//
//   /// 🗑️ Supprimer un avis
//   void _supprimerAvis(Avis avis) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Row(
//           children: [
//             Icon(Icons.warning, color: Colors.red),
//             SizedBox(width: 8),
//             Text('Supprimer l\'avis'),
//           ],
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Êtes-vous sûr de vouloir supprimer cet avis ?'),
//             SizedBox(height: 12),
//             Container(
//               padding: EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.grey[100],
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     avis.salonNom ?? 'Salon inconnu',
//                     style: TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   SizedBox(height: 4),
//                   Row(
//                     children: [
//                       ...List.generate(5, (i) => Icon(
//                         Icons.star,
//                         size: 16,
//                         color: i < avis.note ? Colors.amber : Colors.grey[300],
//                       )),
//                       SizedBox(width: 8),
//                       Text('${avis.note}/5'),
//                     ],
//                   ),
//                   SizedBox(height: 4),
//                   Text(
//                     avis.commentaire,
//                     style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: 12),
//             Text(
//               '⚠️ Cette action est irréversible.',
//               style: TextStyle(
//                 color: Colors.red,
//                 fontSize: 12,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Annuler'),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               Navigator.pop(context);
//               await _confirmerSuppressionAvis(avis);
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red,
//               foregroundColor: Colors.white,
//             ),
//             child: Text('Supprimer'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   /// 🗑️ Confirmer la suppression
//   Future<void> _confirmerSuppressionAvis(Avis avis) async {
//     try {
//       // Afficher le loader
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) => Center(
//           child: Container(
//             padding: EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 CircularProgressIndicator(color: Colors.red),
//                 SizedBox(height: 16),
//                 Text('Suppression en cours...'),
//               ],
//             ),
//           ),
//         ),
//       );
//
//       final result = await AvisService.supprimerAvis(
//         context: context,
//         avisId: avis.id!,
//       );
//
//       // Fermer le loader
//       if (mounted) Navigator.pop(context);
//
//       if (result.success) {
//         // ✅ Succès
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Row(
//               children: [
//                 Icon(Icons.check_circle, color: Colors.white),
//                 SizedBox(width: 8),
//                 Expanded(child: Text(result.message)),
//               ],
//             ),
//             backgroundColor: Colors.green,
//             duration: Duration(seconds: 3),
//           ),
//         );
//
//         // Recharger la liste
//         _chargerMesAvis();
//       } else {
//         // ❌ Erreur
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Row(
//               children: [
//                 Icon(Icons.error, color: Colors.white),
//                 SizedBox(width: 8),
//                 Expanded(child: Text(result.message)),
//               ],
//             ),
//             backgroundColor: Colors.red,
//             duration: Duration(seconds: 4),
//           ),
//         );
//       }
//     } catch (e) {
//       // Fermer le loader si encore ouvert
//       if (mounted) Navigator.pop(context);
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Erreur lors de la suppression: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
//
//   /// 🎨 Construire une carte d'avis
//   Widget _buildAvisCard(Avis avis) {
//     return Card(
//       margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // 🏪 En-tête salon
//             Row(
//               children: [
//                 // Logo salon
//                 Container(
//                   width: 50,
//                   height: 50,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: Colors.grey[200],
//                   ),
//                   child: avis.logoUrl.isNotEmpty
//                       ? ClipOval(
//                     child: Image.network(
//                       avis.logoUrl,
//                       width: 50,
//                       height: 50,
//                       fit: BoxFit.cover,
//                       errorBuilder: (context, error, stackTrace) {
//                         return Icon(Icons.store, color: Colors.grey[400]);
//                       },
//                     ),
//                   )
//                       : Icon(Icons.store, color: Colors.grey[400]),
//                 ),
//
//                 SizedBox(width: 12),
//
//                 // Infos salon
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         avis.salonNom ?? 'Salon inconnu',
//                         style: GoogleFonts.poppins(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       if (avis.dateFormatee.isNotEmpty)
//                         Text(
//                           'Avis donné le ${avis.dateFormatee}',
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//
//                 // Menu actions
//                 PopupMenuButton<String>(
//                   icon: Icon(Icons.more_vert, color: Colors.grey[600]),
//                   onSelected: (value) {
//                     switch (value) {
//                       case 'modifier':
//                         _modifierAvis(avis);
//                         break;
//                       case 'supprimer':
//                         _supprimerAvis(avis);
//                         break;
//                     }
//                   },
//                   itemBuilder: (context) => [
//                     PopupMenuItem(
//                       value: 'modifier',
//                       child: Row(
//                         children: [
//                           Icon(Icons.edit, color: Colors.blue, size: 20),
//                           SizedBox(width: 8),
//                           Text('Modifier'),
//                         ],
//                       ),
//                     ),
//                     PopupMenuItem(
//                       value: 'supprimer',
//                       child: Row(
//                         children: [
//                           Icon(Icons.delete, color: Colors.red, size: 20),
//                           SizedBox(width: 8),
//                           Text('Supprimer'),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//
//             SizedBox(height: 16),
//
//             // ⭐ Note donnée
//             Row(
//               children: [
//                 ...List.generate(5, (i) => Icon(
//                   Icons.star,
//                   size: 24,
//                   color: i < avis.note ? Colors.amber : Colors.grey[300],
//                 )),
//                 SizedBox(width: 8),
//                 Text(
//                   '${avis.note}/5',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.grey[700],
//                   ),
//                 ),
//                 Spacer(),
//                 Container(
//                   padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: _getCouleurNote(avis.note),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Text(
//                     _getTexteNote(avis.note),
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: Colors.white,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//
//             SizedBox(height: 12),
//
//             // 💬 Commentaire
//             Container(
//               padding: EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.grey[50],
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: Colors.grey[200]!),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Icon(Icons.format_quote, color: Colors.grey[500], size: 16),
//                       SizedBox(width: 4),
//                       Text(
//                         'Mon commentaire',
//                         style: TextStyle(
//                           fontSize: 12,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 8),
//                   Text(
//                     avis.commentaire,
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Colors.grey[800],
//                       height: 1.4,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   /// 🎨 Couleur selon la note
//   Color _getCouleurNote(int note) {
//     if (note <= 2) return Colors.red;
//     if (note == 3) return Colors.orange;
//     if (note == 4) return Colors.blue;
//     return Colors.green;
//   }
//
//   /// 📝 Texte selon la note
//   String _getTexteNote(int note) {
//     switch (note) {
//       case 1:
//         return 'Très décevant';
//       case 2:
//         return 'Décevant';
//       case 3:
//         return 'Correct';
//       case 4:
//         return 'Très bien';
//       case 5:
//         return 'Excellent';
//       default:
//         return '';
//     }
//   }
//
//   /// 🔄 Widget d'état vide
//   Widget _buildEmptyState() {
//     return Center(
//       child: Padding(
//         padding: EdgeInsets.all(32),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.rate_review_outlined,
//               size: 80,
//               color: Colors.grey[400],
//             ),
//             SizedBox(height: 16),
//             Text(
//               'Aucun avis donné',
//               style: GoogleFonts.poppins(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey[600],
//               ),
//             ),
//             SizedBox(height: 8),
//             Text(
//               'Vous n\'avez pas encore donné d\'avis sur vos rendez-vous.',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 16,
//                 color: Colors.grey[500],
//               ),
//             ),
//             SizedBox(height: 24),
//             ElevatedButton.icon(
//               onPressed: () => Navigator.pop(context),
//               icon: Icon(Icons.arrow_back),
//               label: Text('Retour'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.orange,
//                 foregroundColor: Colors.white,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   /// ❌ Widget d'état d'erreur
//   Widget _buildErrorState() {
//     return Center(
//       child: Padding(
//         padding: EdgeInsets.all(32),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.error_outline,
//               size: 80,
//               color: Colors.red[400],
//             ),
//             SizedBox(height: 16),
//             Text(
//               'Erreur de chargement',
//               style: GoogleFonts.poppins(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.red[600],
//               ),
//             ),
//             SizedBox(height: 8),
//             Text(
//               _errorMessage ?? 'Une erreur est survenue',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 16,
//                 color: Colors.grey[600],
//               ),
//             ),
//             SizedBox(height: 24),
//             ElevatedButton.icon(
//               onPressed: _chargerMesAvis,
//               icon: Icon(Icons.refresh),
//               label: Text('Réessayer'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.orange,
//                 foregroundColor: Colors.white,
//               ),
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
//         title: Text('Mes avis'),
//         backgroundColor: Colors.orange,
//         foregroundColor: Colors.white,
//         elevation: 0,
//         actions: [
//           if (_mesAvis.isNotEmpty)
//             Padding(
//               padding: EdgeInsets.only(right: 16),
//               child: Center(
//                 child: Container(
//                   padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                   decoration: BoxDecoration(
//                     color: Colors.white.withOpacity(0.2),
//                     borderRadius: BorderRadius.circular(15),
//                   ),
//                   child: Text(
//                     '${_mesAvis.length} avis',
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//       body: RefreshIndicator(
//         onRefresh: _chargerMesAvis,
//         child: _isLoading
//             ? Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               CircularProgressIndicator(color: Colors.orange),
//               SizedBox(height: 16),
//               Text(
//                 'Chargement de vos avis...',
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: Colors.grey[600],
//                 ),
//               ),
//             ],
//           ),
//         )
//             : _errorMessage != null
//             ? _buildErrorState()
//             : _mesAvis.isEmpty
//             ? _buildEmptyState()
//             : Column(
//           children: [
//             // 📊 En-tête statistiques
//             Container(
//               margin: EdgeInsets.all(16),
//               padding: EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [Colors.orange, Colors.deepOrange],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Column(
//                       children: [
//                         Text(
//                           '${_mesAvis.length}',
//                           style: TextStyle(
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                           ),
//                         ),
//                         Text(
//                           'Avis donnés',
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.white70,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   Container(
//                     width: 1,
//                     height: 40,
//                     color: Colors.white30,
//                   ),
//                   Expanded(
//                     child: Column(
//                       children: [
//                         Text(
//                           '${(_mesAvis.map((a) => a.note).reduce((a, b) => a + b) / _mesAvis.length).toStringAsFixed(1)}',
//                           style: TextStyle(
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                           ),
//                         ),
//                         Text(
//                           'Note moyenne',
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.white70,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//             // 📋 Liste des avis
//             Expanded(
//               child: ListView.builder(
//                 padding: EdgeInsets.only(bottom: 16),
//                 itemCount: _mesAvis.length,
//                 itemBuilder: (context, index) {
//                   final avis = _mesAvis[index];
//                   return _buildAvisCard(avis);
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// /// 📝 Dialog pour modifier un avis
// class _ModifierAvisDialog extends StatefulWidget {
//   final Avis avis;
//   final VoidCallback onAvisModifie;
//
//   const _ModifierAvisDialog({
//     required this.avis,
//     required this.onAvisModifie,
//   });
//
//   @override
//   _ModifierAvisDialogState createState() => _ModifierAvisDialogState();
// }
//
// class _ModifierAvisDialogState extends State<_ModifierAvisDialog> {
//   final _formKey = GlobalKey<FormState>();
//   late final TextEditingController _commentaireController;
//   late int _note;
//   bool _isSubmitting = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _commentaireController = TextEditingController(text: widget.avis.commentaire);
//     _note = widget.avis.note;
//   }
//
//   @override
//   void dispose() {
//     _commentaireController.dispose();
//     super.dispose();
//   }
//
//   /// ⭐ Construire le sélecteur d'étoiles
//   Widget _buildStarRating() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Nouvelle note',
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         SizedBox(height: 12),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: List.generate(5, (index) {
//             final starNumber = index + 1;
//             return GestureDetector(
//               onTap: () {
//                 setState(() {
//                   _note = starNumber;
//                 });
//               },
//               child: Container(
//                 padding: EdgeInsets.symmetric(horizontal: 4),
//                 child: Icon(
//                   starNumber <= _note ? Icons.star : Icons.star_border,
//                   size: 35,
//                   color: starNumber <= _note ? Colors.amber : Colors.grey[400],
//                 ),
//               ),
//             );
//           }),
//         ),
//       ],
//     );
//   }
//
//   /// 📤 Soumettre la modification
//   Future<void> _soumettreModification() async {
//     if (!_formKey.currentState!.validate()) {
//       return;
//     }
//
//     setState(() {
//       _isSubmitting = true;
//     });
//
//     try {
//       final result = await AvisService.modifierAvis(
//         context: context,
//         avisId: widget.avis.id!,
//         note: _note,
//         commentaire: _commentaireController.text.trim(),
//       );
//
//       if (mounted) {
//         if (result.success) {
//           // ✅ Succès
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Row(
//                 children: [
//                   Icon(Icons.check_circle, color: Colors.white),
//                   SizedBox(width: 8),
//                   Expanded(child: Text(result.message)),
//                 ],
//               ),
//               backgroundColor: Colors.green,
//               duration: Duration(seconds: 3),
//             ),
//           );
//
//           Navigator.pop(context);
//           widget.onAvisModifie();
//         } else {
//           // ❌ Erreur
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Row(
//                 children: [
//                   Icon(Icons.error, color: Colors.white),
//                   SizedBox(width: 8),
//                   Expanded(child: Text(result.message)),
//                 ],
//               ),
//               backgroundColor: Colors.red,
//               duration: Duration(seconds: 4),
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Erreur inattendue: $e'),
//             backgroundColor: Colors.red,
//             duration: Duration(seconds: 4),
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isSubmitting = false;
//         });
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Container(
//         constraints: BoxConstraints(maxWidth: 500, maxHeight: 600),
//         padding: EdgeInsets.all(20),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Titre
//               Row(
//                 children: [
//                   Icon(Icons.edit, color: Colors.orange),
//                   SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       'Modifier mon avis',
//                       style: GoogleFonts.poppins(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                   IconButton(
//                     onPressed: () => Navigator.pop(context),
//                     icon: Icon(Icons.close),
//                   ),
//                 ],
//               ),
//
//               SizedBox(height: 16),
//
//               // Info salon
//               Container(
//                 padding: EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.grey[100],
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(Icons.store, color: Colors.grey[600]),
//                     SizedBox(width: 8),
//                     Expanded(
//                       child: Text(
//                         widget.avis.salonNom ?? 'Salon inconnu',
//                         style: TextStyle(
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//
//               SizedBox(height: 20),
//
//               // Sélecteur d'étoiles
//               _buildStarRating(),
//
//               SizedBox(height: 20),
//
//               // Champ commentaire
//               Text(
//                 'Nouveau commentaire',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               SizedBox(height: 8),
//               Expanded(
//                 child: TextFormField(
//                   controller: _commentaireController,
//                   maxLines: null,
//                   expands: true,
//                   maxLength: 500,
//                   decoration: InputDecoration(
//                     hintText: 'Modifiez votre commentaire... (minimum 10 caractères)',
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8),
//                       borderSide: BorderSide(color: Colors.orange, width: 2),
//                     ),
//                     contentPadding: EdgeInsets.all(12),
//                   ),
//                   validator: (value) {
//                     if (value == null || value.trim().isEmpty) {
//                       return 'Veuillez écrire un commentaire';
//                     }
//                     if (value.trim().length < 10) {
//                       return 'Le commentaire doit contenir au moins 10 caractères';
//                     }
//                     return null;
//                   },
//                 ),
//               ),
//
//               SizedBox(height: 20),
//
//               // Boutons d'action
//               Row(
//                 children: [
//                   Expanded(
//                     child: OutlinedButton(
//                       onPressed: _isSubmitting ? null : () => Navigator.pop(context),
//                       child: Text('Annuler'),
//                     ),
//                   ),
//                   SizedBox(width: 12),
//                   Expanded(
//                     flex: 2,
//                     child: ElevatedButton(
//                       onPressed: _isSubmitting ? null : _soumettreModification,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.orange,
//                         foregroundColor: Colors.white,
//                       ),
//                       child: _isSubmitting
//                           ? Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           SizedBox(
//                             width: 16,
//                             height: 16,
//                             child: CircularProgressIndicator(
//                               color: Colors.white,
//                               strokeWidth: 2,
//                             ),
//                           ),
//                           SizedBox(width: 8),
//                           Text('Modification...'),
//                         ],
//                       )
//                           : Text('Modifier'),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
