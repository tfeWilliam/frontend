/// **************************************************************************************
///
/// PAGE UI : CRÉATION D'UN AVIS
/// Fichier: screens/creer_avis_screen.dart
///
/// OBJECTIF :
/// Ce fichier définit l'interface utilisateur permettant à un client de laisser un
/// avis (une note et un commentaire) pour un rendez-vous spécifique qui est éligible
/// à une évaluation.
///
/// ARCHITECTURE ET FONCTIONNALITÉS CLÉS :
/// - Utilise un `StatefulWidget` pour gérer l'état du formulaire (note, commentaire,
/// état de soumission).
/// - La page est structurée avec un `Form` et un `GlobalKey` pour la validation.
/// - L'interface est décomposée en méthodes de construction (`_build...`) pour une
/// meilleure lisibilité et maintenance.
/// - Propose un sélecteur de note par étoiles interactif avec un retour visuel
/// (texte et couleur) qui change dynamiquement.
/// - Gère la soumission asynchrone de l'avis via `AvisService` et affiche un retour
/// à l'utilisateur (indicateur de chargement, `SnackBar` de succès ou d'erreur).
/// - Inclut une logique de confirmation pour éviter que l'utilisateur ne quitte
/// l'écran et ne perde ses modifications accidentellement.
///
///***************************************************************************************
library;
import 'package:flutter/material.dart';
import 'package:hairbnb/pages/avis/services/avis_service.dart';

import '../../models/avis.dart';

/// Un écran permettant à l'utilisateur de créer et soumettre un avis pour un rendez-vous.
class CreerAvisScreen extends StatefulWidget {
  /// Le rendez-vous éligible pour lequel l'avis est laissé.
  final RdvEligible rdv;

  const CreerAvisScreen({
    super.key,
    required this.rdv,
  });

  @override
  _CreerAvisScreenState createState() => _CreerAvisScreenState();
}

class _CreerAvisScreenState extends State<CreerAvisScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentaireController = TextEditingController();

  /// La note actuellement sélectionnée par l'utilisateur (de 1 à 5).
  int _note = 5;
  /// Booléen pour gérer l'état de chargement lors de la soumission de l'avis.
  bool _isSubmitting = false;

  @override
  void dispose() {
    // Libère les ressources du contrôleur de texte pour éviter les fuites de mémoire.
    _commentaireController.dispose();
    super.dispose();
  }

  /// Construit le widget de notation par étoiles interactif.
  Widget _buildStarRating() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Votre note', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starNumber = index + 1;
            return GestureDetector(
              onTap: () => setState(() => _note = starNumber),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  starNumber <= _note ? Icons.star : Icons.star_border,
                  size: 40,
                  color: starNumber <= _note ? Colors.amber : Colors.grey[400],
                ),
              ),
            );
          }),
        ),
        SizedBox(height: 8),
        Center(
          child: Text(
            _getTextePourNote(_note),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: _getCouleurPourNote(_note)),
          ),
        ),
      ],
    );
  }

  /// Retourne une description textuelle correspondant à une note donnée.
  String _getTextePourNote(int note) {
    switch (note) {
      case 1: return 'Très décevant';
      case 2: return 'Décevant';
      case 3: return 'Correct';
      case 4: return 'Très bien';
      case 5: return 'Excellent !';
      default: return '';
    }
  }

  /// Retourne une couleur correspondant à une note pour un retour visuel.
  Color _getCouleurPourNote(int note) {
    if (note <= 2) return Colors.red;
    if (note == 3) return Colors.orange;
    return Colors.green;
  }

  /// Construit la carte affichant les informations du rendez-vous à évaluer.
  Widget _buildRdvInfo() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Détails du rendez-vous', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            _buildInfoRow(Icons.store, 'Salon', widget.rdv.salonNom),
            SizedBox(height: 8),
            _buildInfoRow(Icons.calendar_today, 'Date', widget.rdv.dateFormatee),
            SizedBox(height: 8),
            _buildInfoRow(Icons.content_cut, 'Services', widget.rdv.servicesTexte),
            SizedBox(height: 8),
            _buildInfoRow(Icons.euro, 'Prix total', widget.rdv.prixFormate),
          ],
        ),
      ),
    );
  }

  /// Construit une ligne d'information standardisée avec une icône, un libellé et une valeur.
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        SizedBox(width: 8),
        Text('$label: ', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[700])),
        Expanded(child: Text(value, style: TextStyle(color: Colors.black87))),
      ],
    );
  }

  /// Construit le champ de saisie de texte pour le commentaire de l'avis.
  Widget _buildCommentaireField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Votre commentaire', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        TextFormField(
          controller: _commentaireController,
          maxLines: 5,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'Partagez votre expérience... (minimum 10 caractères)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.orange, width: 2)),
            contentPadding: EdgeInsets.all(12),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'Veuillez écrire un commentaire';
            if (value.trim().length < 10) return 'Le commentaire doit contenir au moins 10 caractères';
            return null;
          },
        ),
        SizedBox(height: 8),
        Text(
          'Conseil: Décrivez votre expérience, la qualité du service, l\'accueil, etc.',
          style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  /// Gère la validation du formulaire et la soumission de l'avis via l'AvisService.
  Future<void> _soumettreAvis() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final result = await AvisService.creerAvis(
        context: context,
        rdvId: widget.rdv.idRendezVous,
        note: _note,
        commentaire: _commentaireController.text.trim(),
      );

      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 8), Expanded(child: Text(result.message))]),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.pop(context, true); // Retourne à l'écran précédent avec un signal de succès.
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [Icon(Icons.error, color: Colors.white), SizedBox(width: 8), Expanded(child: Text(result.message))]),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur inattendue: $e'), backgroundColor: Colors.red, duration: Duration(seconds: 4)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// Gère l'action d'annulation, avec une confirmation si des modifications ont été apportées.
  void _annuler() {
    if (_commentaireController.text.trim().isNotEmpty || _note != 5) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Annuler la création'),
          content: Text('Êtes-vous sûr de vouloir annuler ? Vos modifications seront perdues.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Continuer la rédaction')),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text('Annuler'),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Donner mon avis'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.close), onPressed: _annuler),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section affichant les détails du RDV.
              _buildRdvInfo(),
              SizedBox(height: 24),

              // Section pour la notation par étoiles.
              _buildStarRating(),
              SizedBox(height: 24),

              // Section pour le champ de commentaire.
              _buildCommentaireField(),
              SizedBox(height: 32),

              // Section pour les boutons d'action.
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : _annuler,
                      style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 12), side: BorderSide(color: Colors.grey)),
                      child: Text('Annuler', style: TextStyle(color: Colors.grey[700])),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _soumettreAvis,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      child: _isSubmitting
                          ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)), SizedBox(width: 8), Text('Envoi...')])
                          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.send), SizedBox(width: 8), Text('Publier mon avis')]),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Note informative pour l'utilisateur.
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue[200]!)),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[600], size: 20),
                    SizedBox(width: 8),
                    Expanded(child: Text('Votre avis sera visible publiquement et aidera les autres utilisateurs.', style: TextStyle(fontSize: 12, color: Colors.blue[700]))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
