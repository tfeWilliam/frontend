/// *************************************************************************************************
///
/// BANNER : EXPLICATION GÉNÉRALE DE L'ÉCRAN DE PROFIL
///
/// Ce fichier définit `ProfileScreen`, un `StatefulWidget` qui sert de tableau de bord central
/// pour l'utilisateur connecté.
///
/// Objectif :
/// - Afficher les informations détaillées du profil de l'utilisateur.
/// - Offrir un point d'accès centralisé à toutes les fonctionnalités pertinentes pour
/// l'utilisateur, en adaptant les options disponibles en fonction de son rôle
/// (Client, Coiffeuse, Admin).
/// - Permettre la modification des informations personnelles (téléphone, adresse, etc.).
/// - Gérer les actions critiques du compte comme la déconnexion et la suppression.
///
/// Fonctionnalités Clés :
/// 1.  Affichage Dynamique : Le contenu de l'écran (informations, actions) est rendu
/// conditionnellement en fonction du type et du rôle de l'utilisateur.
/// 2.  Gestion de l'État :
/// - Récupère et écoute les données de l'utilisateur via un `Provider` (`CurrentUserProvider`)
/// pour garantir que les informations affichées sont toujours à jour.
/// - Utilise un état local (`isLoading`, `errorMessage`) pour gérer les retours visuels
/// lors des opérations asynchrones.
/// 3.  Animation : Intègre une animation de fondu (`FadeTransition`) pour une apparition
/// fluide du contenu de la page.
/// 4.  Architecture Modulaire :
/// - Délègue les actions complexes (déconnexion, suppression de compte, mise à jour
/// de l'adresse/téléphone) à des services spécialisés et des widgets dédiés.
/// - Sert de hub de navigation vers de nombreuses autres pages de l'application.
/// 5.  Interface Utilisateur Structurée : Le layout est divisé en sections claires
/// (informations générales, professionnelles, actions) à l'aide de composants
/// réutilisables (`_buildSectionHeader`, `_infoTile`, `_actionTile`).
///
///*************************************************************************************************
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hairbnb/pages/profil/services/image_util.dart';
import 'package:hairbnb/pages/profil/services/update_services/adress_update/adress_change_widget.dart';
import 'package:provider/provider.dart';
import '../../models/current_user.dart';
import '../../services/auth_services/logout_service.dart';
import '../../services/providers/current_user_provider.dart';
import '../../services/firebase_token/token_service.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../ai_chat/coiffeuse_ai/coiffeuse_ai_conversations_list.dart';
import '../ai_chat/widgets/ai_chat_wrapper.dart';
import '../ai_chat/services/coiffeuse_ai_chat_service.dart';
import '../commandes/coiffeuse_commande_page.dart';
import '../horaires_coiffeuse/disponibilite_coiffeuse_page.dart';
import '../mes_commandes/mes_commandes_page.dart';
import '../salon/salon_services_pages/api/salon_by_coiffeuse_api.dart';
import '../salon/salon_services_pages/promotion/promotions_management_page.dart';
import '../salon/salon_services_pages/show_services_list_page.dart';
import '../../public_salon_details/show_salon_page.dart';
import 'services/delete_account/delete_account_service.dart';
import 'services/update_services/phone_update/phone_edit_widget.dart';

class ProfileScreen extends StatefulWidget {
  final CurrentUser currentUser;

  const ProfileScreen({super.key, required this.currentUser});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  // Variables d'état pour la gestion de l'UI
  bool isLoading = false;
  String errorMessage = "";
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Palette de couleurs pour la page
  final Color primaryViolet = const Color(0xFF7B61FF);
  final Color lightBackground = const Color(0xFFF7F7F9);
  final Color successGreen = Colors.green;
  final Color errorRed = Colors.red;

  @override
  void initState() {
    super.initState();

    // Initialise le contrôleur d'animation pour l'effet de fondu.
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut)
    );

    // Démarre l'animation.
    _animationController.forward();
  }

  @override
  void dispose() {
    // Libère les ressources du contrôleur d'animation.
    _animationController.dispose();
    super.dispose();
  }

  // Met la première lettre d'une chaîne en majuscule.
  String capitalize(String s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1).toLowerCase() : "";

  // Vérifie si l'utilisateur est une coiffeuse qui possède un salon.
  bool _isCoiffeuseProprietaire(CurrentUser user) {
    bool isCoiffeuse = user.isCoiffeuseUser() || user.type?.toLowerCase() == 'coiffeuse' || (user.coiffeuse != null);
    if (!isCoiffeuse) return false;
    return user.coiffeuse?.salon != null;
  }

  // Vérifie si l'utilisateur a un rôle d'administrateur.
  bool _isAdmin(CurrentUser user) {
    return user.role?.toLowerCase() == 'admin' || user.role?.toLowerCase() == 'administrateur';
  }

  // Affiche une boîte de dialogue pour modifier un champ du profil.
  void _editField(String fieldName, String currentValue) {
    // Cas spécial : utilise un widget dédié pour la modification du téléphone.
    if (fieldName == "Téléphone") {
      showPhoneEditDialog(
        context,
        widget.currentUser,
        primaryColor: primaryViolet, successColor: successGreen, errorColor: errorRed,
        setLoadingState: (bool value) => setState(() => isLoading = value),
      );
      return;
    }

    // Pour les autres champs, utilise une boîte de dialogue générique.
    final TextEditingController fieldController = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Modifier $fieldName", style: TextStyle(color: primaryViolet, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: fieldController,
            decoration: InputDecoration(
              hintText: "Nouvelle valeur pour $fieldName",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: primaryViolet, width: 2)),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), style: TextButton.styleFrom(foregroundColor: Colors.grey), child: const Text("Annuler")),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                if (fieldController.text.isNotEmpty && fieldController.text != currentValue) {
                  await _updateUserProfileField(widget.currentUser.uuid, {fieldName: fieldController.text});
                }
              },
              style: TextButton.styleFrom(foregroundColor: primaryViolet),
              child: const Text("Sauvegarder"),
            ),
          ],
        );
      },
    );
  }

  // Logique pour mettre à jour un champ du profil utilisateur.
  Future<void> _updateUserProfileField(String userUuid, Map<String, dynamic> updatedData) async {
    // NOTE: La logique de mise à jour via API doit être implémentée ici.
    // Cette fonction est actuellement un placeholder.
    setState(() => isLoading = true);
    // Simule une opération réseau.
    await Future.delayed(const Duration(seconds: 1));
    setState(() => isLoading = false);
  }

  // Affiche le widget dédié à la modification de l'adresse.
  void _editAddress(Adresse adresse) {
    showDialog(
      context: context,
      builder: (context) => AddressChangeWidget(
        currentUser: widget.currentUser,
        currentAddress: adresse,
        setLoadingState: (bool value) => setState(() => isLoading = value),
        primaryColor: primaryViolet, successColor: successGreen, errorColor: errorRed,
      ),
    );
  }

  // Gère la navigation vers l'assistant IA pour les coiffeuses.
  Future<void> _navigateToCoiffeuseAI(CurrentUser user) async {
    showDialog(context: context, barrierDismissible: false, builder: (context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(color: primaryViolet), const SizedBox(height: 16), const Text('Initialisation de votre assistant IA...', style: TextStyle(color: Colors.white))])));
    try {
      final token = await TokenService.getAuthToken();
      if (token == null) {
        if (mounted) Navigator.pop(context);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Erreur d\'authentification'), backgroundColor: errorRed));
        return;
      }
      final chatService = CoiffeuseAIChatService(baseUrl: 'https://www.hairbnb.site/api', token: token);
      if (mounted) Navigator.pop(context);
      if (mounted) Navigator.push(context, MaterialPageRoute(builder: (context) => CoiffeuseConversationsListPage(currentUser: user, chatService: chatService)));
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de l\'initialisation : $e'), backgroundColor: errorRed));
    }
  }

  @override
  Widget build(BuildContext context) {
    // S'assure d'utiliser la version la plus à jour de l'utilisateur depuis le Provider.
    final CurrentUser user = Provider.of<CurrentUserProvider>(context).currentUser ?? widget.currentUser;

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        backgroundColor: primaryViolet, elevation: 0,
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, color: Colors.white)),
        title: const Text("Profil", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: isLoading
      // Affiche un indicateur de chargement si une opération est en cours.
          ? Center(child: CircularProgressIndicator(color: primaryViolet))
      // Affiche un message d'erreur s'il y en a un.
          : errorMessage.isNotEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.error_outline, color: errorRed, size: 60), const SizedBox(height: 16), Text(errorMessage, style: TextStyle(color: errorRed, fontSize: 16), textAlign: TextAlign.center)]))
      // Affiche le contenu principal avec une animation de fondu.
          : FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Section d'en-tête avec photo, nom et type de profil.
              Hero(
                tag: 'userAvatar',
                child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: primaryViolet, width: 3), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), spreadRadius: 1, blurRadius: 8, offset: const Offset(0, 3))]),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: user.photoProfil != null && user.photoProfil!.isNotEmpty ? NetworkImage(ImageUtil.getFullImageUrl(user.photoProfil!)) : const AssetImage('assets/default_avatar.png') as ImageProvider,
                      onBackgroundImageError: (exception, stackTrace) { if (kDebugMode) print("Erreur de chargement de l'image : $exception"); },
                    )
                ),
              ),
              const SizedBox(height: 16),
              Text("${capitalize(user.prenom)} ${capitalize(user.nom)}", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: primaryViolet.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text("Type : ${capitalize(user.type ?? 'Indéfini')}", style: TextStyle(fontSize: 16, color: primaryViolet, fontWeight: FontWeight.w500)),
              ),
              const SizedBox(height: 24),

              // Section des informations générales.
              _buildSectionHeader("Informations générales", Icons.person),
              Card(
                elevation: 4, shadowColor: Colors.black26, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      _infoTile(Icons.email, "Email", user.email),
                      _infoTile(Icons.phone, "Téléphone", user.numeroTelephone),
                      if (user.adresse != null) Consumer<CurrentUserProvider>(builder: (context, userProvider, child) {
                        final currentAddr = userProvider.currentUser?.adresse ?? user.adresse;
                        return currentAddr != null ? _addressCompactTile(currentAddr) : const SizedBox.shrink();
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Section des informations professionnelles (coiffeuses uniquement).
              if (user.isCoiffeuseUser() && user.coiffeuse != null) ...[
                _buildSectionHeader("Informations professionnelles", Icons.business_center),
                Card(
                  elevation: 4, shadowColor: Colors.black26, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        _infoTile(Icons.business, "Dénomination Sociale", user.coiffeuse!.denominationSociale ?? ''),
                        if (user.coiffeuse!.salon != null) _infoTile(Icons.store, "Nom du salon", user.coiffeuse!.salon!.nomSalon ?? ''),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Section des actions.
              _buildSectionHeader("Actions", Icons.settings),
              Card(
                elevation: 4, shadowColor: Colors.black26, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      // Actions spécifiques aux coiffeuses.
                      if (user.isCoiffeuseUser()) ...[
                        _actionTile(Icons.build, "Services", () => Navigator.push(context, MaterialPageRoute(builder: (context) => ServicesListPage(coiffeuseId: user.idTblUser.toString())))),
                        _actionTile(Icons.local_offer, "Promotions", () => Navigator.push(context, MaterialPageRoute(builder: (context) => PromotionsManagementPage(coiffeuseId: user.idTblUser.toString()))), isHighlighted: true),
                        _actionTile(Icons.store, "Mon salon", () async {
                          showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));
                          try {
                            if (user.coiffeuse?.salon != null) {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (context) => SalonDetailsPage(salonId: user.coiffeuse!.salon!.idTblSalon, currentUserId: user.idTblUser)));
                            } else {
                              final salon = await SalonByCoiffeuseApi.getSalonByCoiffeuseId(user.idTblUser);
                              Navigator.pop(context);
                              if (salon != null) {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => SalonDetailsPage(salonId: salon.idSalon, currentUserId: user.idTblUser)));
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vous n'avez pas encore de salon."), backgroundColor: Colors.orange));
                              }
                            }
                          } catch (e) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur lors du chargement du salon: $e"), backgroundColor: errorRed));
                          }
                        }),
                        _actionTile(Icons.calendar_today, "Mes disponibilités", () => Navigator.push(context, MaterialPageRoute(builder: (context) => HoraireIndispoPage(coiffeuseId: user.idTblUser)))),
                        _actionTile(Icons.assignment, "Commandes Reçues", () => Navigator.push(context, MaterialPageRoute(builder: (context) => CoiffeuseCommandesPage(currentUser: user)))),
                      ],
                      // Action pour l'assistant IA des coiffeuses propriétaires.
                      if (_isCoiffeuseProprietaire(user)) _actionTile(Icons.auto_awesome, "🤖 Mon Assistant IA Personnel", () => _navigateToCoiffeuseAI(user), isHighlighted: true),
                      // Action pour l'assistant IA des admins.
                      if (_isAdmin(user)) _actionTile(Icons.chat_bubble, "🔧 Assistant IA Admin", () => Navigator.push(context, MaterialPageRoute(builder: (context) => AIChatWrapper(currentUser: user))), isHighlighted: true),
                      // Action commune à tous les utilisateurs.
                      _actionTile(Icons.shopping_bag, "Mes Commandes", () => Navigator.push(context, MaterialPageRoute(builder: (context) => MesCommandesPage(currentUser: user))), isHighlighted: true),
                      // Actions de gestion de compte (destructives).
                      _actionTile(Icons.delete_forever, "Supprimer mon compte", () async => await DeleteAccountService.deleteUserAccount(context: context, currentUser: user, successGreen: successGreen, errorRed: errorRed, setLoadingState: (bool value) => setState(() => isLoading = value)), isDestructive: true),
                      _actionTile(Icons.logout, "Déconnexion", () async => await LogoutService.confirmLogout(context), isDestructive: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 4, onTap: (index) {}),
    );
  }

  // Construit un en-tête de section stylisé.
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: primaryViolet, size: 24),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryViolet)),
        ],
      ),
    );
  }

  // Construit une tuile d'information avec une icône, un libellé, une valeur et un bouton d'édition.
  Widget _infoTile(IconData icon, String label, String? value) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: primaryViolet.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: primaryViolet)),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey)),
      subtitle: Text(value != null && value.isNotEmpty ? value : "Non spécifié", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      trailing: IconButton(
        icon: const Icon(Icons.edit), color: primaryViolet,
        onPressed: () {
          if (label == "Téléphone") {
            showPhoneEditDialog(context, widget.currentUser, primaryColor: primaryViolet, successColor: successGreen, errorColor: errorRed, setLoadingState: (bool value) => setState(() => isLoading = value));
          } else {
            _editField(label, value ?? "");
          }
        },
      ),
    );
  }

  // Construit une tuile compacte pour afficher une adresse complète.
  Widget _addressCompactTile(Adresse adresse) {
    String addressLine1 = '${adresse.numero ?? ''} ${adresse.rue?.nomRue ?? ''}'.trim();
    String addressLine2 = '${adresse.rue?.localite?.codePostal ?? ''} ${adresse.rue?.localite?.commune ?? ''}'.trim();
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: primaryViolet.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.location_on, color: primaryViolet)),
      title: const Text('Adresse', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (addressLine1.isNotEmpty) Text(addressLine1, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          if (addressLine2.isNotEmpty) Text(addressLine2, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
      trailing: IconButton(icon: const Icon(Icons.edit), color: primaryViolet, onPressed: () => _editAddress(adresse)),
    );
  }

  // Construit une tuile d'action cliquable avec des styles conditionnels.
  Widget _actionTile(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false, bool isHighlighted = false}) {
    final Color color = isDestructive ? Colors.red : (isHighlighted ? Colors.orange : primaryViolet);
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(isHighlighted ? 0.2 : 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color)),
      title: Text(label, style: TextStyle(fontSize: 16, fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500, color: isDestructive ? Colors.red : (isHighlighted ? Colors.orange : Colors.black87))),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: isDestructive ? Colors.red : (isHighlighted ? Colors.orange : Colors.grey)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      tileColor: isHighlighted ? Colors.orange.withOpacity(0.05) : null,
    );
  }
}







// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:hairbnb/pages/profil/services/image_util.dart';
// import 'package:hairbnb/pages/profil/services/update_services/adress_update/adress_change_widget.dart';
// import 'package:provider/provider.dart';
// import '../../models/current_user.dart';
// import '../../services/auth_services/logout_service.dart';
// import '../../services/providers/current_user_provider.dart';
// import '../../services/firebase_token/token_service.dart';
// import '../../widgets/bottom_nav_bar.dart';
// import '../ai_chat/coiffeuse_ai/coiffeuse_ai_conversations_list.dart';
// import '../ai_chat/widgets/ai_chat_wrapper.dart';
// import '../ai_chat/services/coiffeuse_ai_chat_service.dart';
// import '../commandes/coiffeuse_commande_page.dart';
// import '../horaires_coiffeuse/disponibilite_coiffeuse_page.dart';
// import '../mes_commandes/mes_commandes_page.dart';
// import '../salon/salon_services_pages/api/salon_by_coiffeuse_api.dart';
// import '../salon/salon_services_pages/promotion/promotions_management_page.dart';
// import '../salon/salon_services_pages/show_services_list_page.dart';
// import '../../public_salon_details/show_salon_page.dart';
// import 'services/delete_account/delete_account_service.dart';
// import 'services/update_services/phone_update/phone_edit_widget.dart';
//
// class ProfileScreen extends StatefulWidget {
//   final CurrentUser currentUser;
//
//   const ProfileScreen({super.key, required this.currentUser});
//
//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }
//
// class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
//   bool isLoading = false;
//   String errorMessage = "";
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
//
//   // Couleurs de l'application
//   final Color primaryViolet = const Color(0xFF7B61FF);
//   final Color lightBackground = const Color(0xFFF7F7F9);
//   final Color successGreen = Colors.green;
//   final Color errorRed = Colors.red;
//
//   @override
//   void initState() {
//     super.initState();
//
//     // Initialisation de l'animation
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 800),
//     );
//
//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//         CurvedAnimation(
//           parent: _animationController,
//           curve: Curves.easeInOut,
//         )
//     );
//
//     // Démarrer l'animation directement car pas besoin d'attendre fetchUserProfile
//     _animationController.forward();
//   }
//
//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }
//
//   String capitalize(String s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1).toLowerCase() : "";
//
//   /// Vérifie si l'utilisateur est une coiffeuse propriétaire
//   bool _isCoiffeuseProprietaire(CurrentUser user) {
//     // Vérifier que c'est une coiffeuse (via type ou isCoiffeuseUser())
//     bool isCoiffeuse = user.isCoiffeuseUser() ||
//         user.type?.toLowerCase() == 'coiffeuse' ||
//         (user.coiffeuse != null);
//
//     if (!isCoiffeuse) {
//       return false;
//     }
//
//     if (user.coiffeuse?.salon != null) {
//       return true;
//     }
//
//     return false;
//   }
//
//   /// Vérifie si l'utilisateur est admin
//   bool _isAdmin(CurrentUser user) {
//     return user.role?.toLowerCase() == 'admin' ||
//         user.role?.toLowerCase() == 'administrateur';
//
//   }
//
//   void _editField(String fieldName, String currentValue) {
//     // Pour le numéro de téléphone, utiliser le nouveau widget dédié
//     if (fieldName == "Téléphone") {
//       showPhoneEditDialog(
//         context,
//         widget.currentUser,
//         primaryColor: primaryViolet,
//         successColor: successGreen,
//         errorColor: errorRed,
//         setLoadingState: (bool value) {
//           setState(() {
//             isLoading = value;
//           });
//         },
//       );
//       return;
//     }
//
//     final TextEditingController fieldController = TextEditingController(text: currentValue);
//
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//           title: Text("Modifier $fieldName", style: TextStyle(color: primaryViolet, fontWeight: FontWeight.bold)),
//           content: TextField(
//             controller: fieldController,
//             decoration: InputDecoration(
//               hintText: "Nouvelle valeur pour $fieldName",
//               border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(10),
//                 borderSide: BorderSide(color: primaryViolet, width: 2),
//               ),
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               style: TextButton.styleFrom(foregroundColor: Colors.grey),
//               child: const Text("Annuler"),
//             ),
//             TextButton(
//               onPressed: () async {
//                 Navigator.pop(context);
//
//                 // Vérifier que le champ a changé et n'est pas vide
//                 if (fieldController.text.isNotEmpty && fieldController.text != currentValue) {
//                   await _updateUserProfileField(widget.currentUser.uuid, {fieldName: fieldController.text});
//                 }
//               },
//               style: TextButton.styleFrom(foregroundColor: primaryViolet),
//               child: const Text("Sauvegarder"),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   Future<void> _updateUserProfileField(String userUuid, Map<String, dynamic> updatedData) async {
//     setState(() {
//       isLoading = true;
//     });
//
//     setState(() {
//       isLoading = false;
//     });
//   }
//
//   void _editAddress(Adresse adresse) {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AddressChangeWidget(
//           currentUser: widget.currentUser,
//           currentAddress: adresse,
//           setLoadingState: (bool value) {
//             setState(() {
//               isLoading = value;
//             });
//           },
//           primaryColor: primaryViolet,
//           successColor: successGreen,
//           errorColor: errorRed,
//         );
//       },
//     );
//   }
//
//   /// Navigation vers l'Assistant IA Coiffeuses
//   Future<void> _navigateToCoiffeuseAI(CurrentUser user) async {
//     // Afficher un indicateur de chargement
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             CircularProgressIndicator(color: primaryViolet),
//             SizedBox(height: 16),
//             Text(
//               'Initialisation de votre assistant IA...',
//               style: TextStyle(color: Colors.white),
//             ),
//           ],
//         ),
//       ),
//     );
//
//     try {
//       // Récupérer le token Firebase
//       final token = await TokenService.getAuthToken();
//
//       if (token == null) {
//         Navigator.pop(context); // Fermer le loading
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Erreur d\'authentification'),
//             backgroundColor: errorRed,
//           ),
//         );
//         return;
//       }
//
//       // Initialiser le service avec votre URL backend
//       final chatService = CoiffeuseAIChatService(
//         baseUrl: 'https://www.hairbnb.site/api',
//         token: token,
//       );
//
//       Navigator.pop(context); // Fermer le loading
//
//       // ✅ NOUVELLE APPROCHE - Passer le service directement
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => CoiffeuseConversationsListPage(
//             currentUser: user,
//             chatService: chatService,
//           ),
//         ),
//       );
//     } catch (e) {
//       Navigator.pop(context); // Fermer le loading
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Erreur lors de l\'initialisation : $e'),
//           backgroundColor: errorRed,
//         ),
//       );
//     }
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     final CurrentUser user = Provider.of<CurrentUserProvider>(context).currentUser ?? widget.currentUser;
//
//     // DEBUG TEMPORAIRE - à retirer après test
//     if (kDebugMode) {
//       print("=== DEBUG PROFIL ===");
//       print("user.type: ${user.type}");
//       print("user.role: ${user.role}");
//       print("user.isCoiffeuseUser(): ${user.isCoiffeuseUser()}");
//       print("user.coiffeuse: ${user.coiffeuse}");
//       print("user.coiffeuse?.salon: ${user.coiffeuse?.salon}");
//       print("_isAdmin(user): ${_isAdmin(user)}");
//       print("_isCoiffeuseProprietaire(user): ${_isCoiffeuseProprietaire(user)}");
//       print("===================");
//     }
//
//     return Scaffold(
//       backgroundColor: lightBackground,
//       appBar: AppBar(
//         backgroundColor: primaryViolet,
//         elevation: 0,
//         leading: IconButton(
//           onPressed: () => Navigator.pop(context),
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//         ),
//         title: const Text(
//           "Profil",
//           style: TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//       ),
//       body: isLoading
//           ? Center(child: CircularProgressIndicator(color: primaryViolet))
//           : errorMessage.isNotEmpty
//           ? Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.error_outline, color: errorRed, size: 60),
//             const SizedBox(height: 16),
//             Text(
//               errorMessage,
//               style: TextStyle(color: errorRed, fontSize: 16),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       )
//           : FadeTransition(
//         opacity: _fadeAnimation,
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             children: [
//               // Section d'en-tête avec photo et nom
//               Hero(
//                 tag: 'userAvatar',
//                 child: Container(
//                     padding: const EdgeInsets.all(4),
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       border: Border.all(color: primaryViolet, width: 3),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.1),
//                           spreadRadius: 1,
//                           blurRadius: 8,
//                           offset: const Offset(0, 3),
//                         ),
//                       ],
//                     ),
//                     child: CircleAvatar(
//                       radius: 60,
//                       backgroundImage: user.photoProfil != null &&
//                           user.photoProfil!.isNotEmpty
//                           ? NetworkImage(ImageUtil.getFullImageUrl(user.photoProfil!))
//                           : const AssetImage('assets/default_avatar.png') as ImageProvider,
//                       onBackgroundImageError: (exception, stackTrace) {
//                         if (kDebugMode) {
//                           print("Erreur de chargement de l'image : $exception");
//                         }
//                       },
//                     )
//                 ),
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 "${capitalize(user.prenom)} ${capitalize(user.nom)}",
//                 style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 8),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                 decoration: BoxDecoration(
//                   color: primaryViolet.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Text(
//                   "Type : ${capitalize(user.type ?? 'Indéfini')}",
//                   style: TextStyle(fontSize: 16, color: primaryViolet, fontWeight: FontWeight.w500),
//                 ),
//               ),
//               const SizedBox(height: 24),
//
//               // Section d'informations générales
//               _buildSectionHeader("Informations générales", Icons.person),
//               Card(
//                 elevation: 4,
//                 shadowColor: Colors.black26,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 8),
//                   child: Column(
//                     children: [
//                       _infoTile(Icons.email, "Email", user.email),
//                       _infoTile(Icons.phone, "Téléphone", user.numeroTelephone),
//                       if (user.adresse != null) ...[
//                         Consumer<CurrentUserProvider>(
//                           builder: (context, userProvider, child) {
//                             final currentAddr = userProvider.currentUser?.adresse ?? user.adresse;
//                             if (currentAddr != null) {
//                               return _addressCompactTile(currentAddr);
//                             }
//                             return SizedBox.shrink();
//                           },
//                         ),
//                       ],
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//
//               // Section d'informations professionnelles (pour les coiffeuses)
//               if (user.isCoiffeuseUser() && user.coiffeuse != null) ...[
//                 _buildSectionHeader("Informations professionnelles", Icons.business_center),
//                 Card(
//                   elevation: 4,
//                   shadowColor: Colors.black26,
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(vertical: 8),
//                     child: Column(
//                       children: [
//                         _infoTile(Icons.business, "Dénomination Sociale", user.coiffeuse!.denominationSociale ?? ''),
//                         // _infoTile(Icons.money, "TVA", user.coiffeuse!.tva ?? ''),
//                         // _infoTile(Icons.map, "Position", user.coiffeuse!.position ?? ''),
//                         if (user.coiffeuse!.salon != null)
//                           _infoTile(Icons.store, "Nom du salon", user.coiffeuse!.salon!.nomSalon ?? ''),
//                       ],
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//               ],
//
//               // Section des actions
//               _buildSectionHeader("Actions", Icons.settings),
//               Card(
//                 elevation: 4,
//                 shadowColor: Colors.black26,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 8),
//                   child: Column(
//                     children: [
//                       if (user.isCoiffeuseUser()) ...[
//                         _actionTile(
//                             Icons.build,
//                             "Services",
//                                 () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => ServicesListPage(coiffeuseId: user.idTblUser.toString()),
//                                 ),
//                               );
//                             }
//                         ),
//
//                         // Promotions
//                         _actionTile(
//                           Icons.local_offer,
//                           "Promotions",
//                               () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => PromotionsManagementPage(coiffeuseId: user.idTblUser.toString()),
//                               ),
//                             );
//                           },
//                           isHighlighted: true,
//                         ),
//
//                         // Mon salon
//                         _actionTile(
//                             Icons.store,
//                             "Mon salon",
//                                 () async {
//                               // Afficher un indicateur de chargement
//                               showDialog(
//                                 context: context,
//                                 barrierDismissible: false,
//                                 builder: (context) => const Center(
//                                   child: CircularProgressIndicator(),
//                                 ),
//                               );
//
//                               try {
//                                 // Récupérer le salon directement à partir de l'utilisateur s'il existe
//                                 if (user.coiffeuse?.salon != null) {
//                                   // Fermer l'indicateur de chargement
//                                   Navigator.pop(context);
//
//                                   // Naviguer vers la page de détails du salon
//                                   Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                       builder: (context) => SalonDetailsPage(
//                                         salonId: user.coiffeuse!.salon!.idTblSalon,
//                                         currentUserId: user.idTblUser,
//                                       ),
//                                     ),
//                                   );
//                                 } else {
//                                   // Appel au service pour récupérer le salon
//                                   final salon = await SalonByCoiffeuseApi.getSalonByCoiffeuseId(user.idTblUser);
//
//                                   // Fermer l'indicateur de chargement
//                                   Navigator.pop(context);
//
//                                   if (salon != null) {
//                                     // Naviguer vers la page de détails du salon
//                                     Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder: (context) => SalonDetailsPage(
//                                           salonId: salon.idSalon,
//                                           currentUserId: user.idTblUser,
//                                         ),
//                                       ),
//                                     );
//                                   } else {
//                                     // Si aucun salon n'est trouvé
//                                     ScaffoldMessenger.of(context).showSnackBar(
//                                       SnackBar(
//                                         content: const Text("Vous n'avez pas encore de salon."),
//                                         backgroundColor: Colors.orange,
//                                       ),
//                                     );
//                                   }
//                                 }
//                               } catch (e) {
//                                 // Fermer l'indicateur de chargement en cas d'erreur
//                                 Navigator.pop(context);
//
//                                 // Afficher un message d'erreur
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   SnackBar(
//                                     content: Text("Erreur lors du chargement du salon: $e"),
//                                     backgroundColor: errorRed,
//                                   ),
//                                 );
//                               }
//                             }
//                         ),
//
//                         // Disponibilités
//                         _actionTile(
//                             Icons.calendar_today,
//                             "Mes disponibilités",
//                                 () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => HoraireIndispoPage(coiffeuseId: user.idTblUser),
//                                 ),
//                               );
//                             }
//                         ),
//
//                         // Commandes reçues
//                         _actionTile(
//                           Icons.assignment,
//                           "Commandes Reçues",
//                               () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => CoiffeuseCommandesPage(
//                                   currentUser: user,
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                       ],
//
//                       // Assistant IA pour Coiffeuses Propriétaires
//                       if (_isCoiffeuseProprietaire(user))
//                         _actionTile(
//                           Icons.auto_awesome,
//                           "🤖 Mon Assistant IA Personnel",
//                               () => _navigateToCoiffeuseAI(user),
//                           isHighlighted: true,
//                         ),
//
//                       // Assistant IA pour Admins
//                       if (_isAdmin(user))
//                         _actionTile(
//                           Icons.chat_bubble,
//                           "🔧 Assistant IA Admin",
//                               () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => AIChatWrapper(currentUser: user),
//                               ),
//                             );
//                           },
//                           isHighlighted: true,
//                         ),
//
//                       // Mes commandes (pour tous)
//                       _actionTile(
//                         Icons.shopping_bag,
//                         "Mes Commandes",
//                             () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => MesCommandesPage(currentUser: user),
//                             ),
//                           );
//                         },
//                         isHighlighted: true,
//                       ),
//
//                       // Suppression du compte
//                       _actionTile(
//                         Icons.delete_forever,
//                         "Supprimer mon compte",
//                             () async {
//                           await DeleteAccountService.deleteUserAccount(
//                             context: context,
//                             currentUser: user,
//                             successGreen: successGreen,
//                             errorRed: errorRed,
//                             setLoadingState: (bool value) {
//                               setState(() {
//                                 isLoading = value;
//                               });
//                             },
//                           );
//                         },
//                         isDestructive: true,
//                       ),
//
//                       // Déconnexion
//                       _actionTile(
//                         Icons.logout,
//                         "Déconnexion",
//                             () async {
//                           await LogoutService.confirmLogout(context);
//                         },
//                         isDestructive: true,
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 40),
//             ],
//           ),
//         ),
//       ),
//       bottomNavigationBar: BottomNavBar(
//         currentIndex: 4, // Correspond à l'onglet "Profil"
//         onTap: (index) {
//           // L'action est gérée dans le widget de la navbar lui-même
//         },
//       ),
//     );
//   }
//
//   Widget _buildSectionHeader(String title, IconData icon) {
//     return Padding(
//       padding: const EdgeInsets.only(left: 4, bottom: 12),
//       child: Row(
//         children: [
//           Icon(icon, color: primaryViolet, size: 24),
//           const SizedBox(width: 10),
//           Text(
//             title,
//             style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: primaryViolet
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _infoTile(IconData icon, String label, String? value) {
//     return ListTile(
//       leading: Container(
//         padding: const EdgeInsets.all(8),
//         decoration: BoxDecoration(
//           color: primaryViolet.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Icon(icon, color: primaryViolet),
//       ),
//       title: Text(
//         label,
//         style: const TextStyle(
//           fontSize: 14,
//           fontWeight: FontWeight.w500,
//           color: Colors.grey,
//         ),
//       ),
//       subtitle: Text(
//         value != null && value.isNotEmpty ? value : "Non spécifié",
//         style: const TextStyle(
//           fontSize: 16,
//           fontWeight: FontWeight.w600,
//         ),
//       ),
//       trailing: IconButton(
//         icon: const Icon(Icons.edit),
//         color: primaryViolet,
//         onPressed: () {
//           // Utilisation spéciale pour le téléphone
//           if (label == "Téléphone") {
//             showPhoneEditDialog(
//               context,
//               widget.currentUser,
//               primaryColor: primaryViolet,
//               successColor: successGreen,
//               errorColor: errorRed,
//               setLoadingState: (bool value) {
//                 setState(() {
//                   isLoading = value;
//                 });
//               },
//             );
//           } else {
//             _editField(label, value ?? "");
//           }
//         },
//       ),
//     );
//   }
//
//   // Nouvelle méthode pour afficher l'adresse de manière compacte
//   Widget _addressCompactTile(Adresse adresse) {
//     // Construire l'adresse complète en un seul texte
//     String addressLine1 = '';
//     String addressLine2 = '';
//
//     // Ligne 1: Numéro + rue
//     if (adresse.numero != null && adresse.numero!.isNotEmpty) {
//       addressLine1 += adresse.numero!;
//     }
//
//     // Ajouter le nom de la rue
//     if (adresse.rue != null && adresse.rue!.nomRue != null && adresse.rue!.nomRue!.isNotEmpty) {
//       if (addressLine1.isNotEmpty) addressLine1 += ' ';
//       addressLine1 += adresse.rue!.nomRue!;
//     }
//
//     // Ligne 2: Code postal + Commune
//     if (adresse.rue?.localite != null) {
//       if (adresse.rue!.localite!.codePostal != null && adresse.rue!.localite!.codePostal!.isNotEmpty) {
//         addressLine2 += adresse.rue!.localite!.codePostal!;
//       }
//
//       if (adresse.rue!.localite!.commune != null && adresse.rue!.localite!.commune!.isNotEmpty) {
//         if (addressLine2.isNotEmpty) addressLine2 += ' ';
//         addressLine2 += adresse.rue!.localite!.commune!;
//       }
//     }
//
//     return ListTile(
//       leading: Container(
//         padding: const EdgeInsets.all(8),
//         decoration: BoxDecoration(
//           color: primaryViolet.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Icon(Icons.location_on, color: primaryViolet),
//       ),
//       title: Text(
//         'Adresse',
//         style: const TextStyle(
//           fontSize: 14,
//           fontWeight: FontWeight.w500,
//           color: Colors.grey,
//         ),
//       ),
//       subtitle: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           if (addressLine1.isNotEmpty)
//             Text(
//               addressLine1,
//               style: const TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           if (addressLine2.isNotEmpty)
//             Text(
//               addressLine2,
//               style: const TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//         ],
//       ),
//       trailing: IconButton(
//         icon: const Icon(Icons.edit),
//         color: primaryViolet,
//         onPressed: () => _editAddress(adresse),
//       ),
//     );
//   }
//
//   Widget _actionTile(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false, bool isHighlighted = false}) {
//     return ListTile(
//       leading: Container(
//         padding: const EdgeInsets.all(8),
//         decoration: BoxDecoration(
//           color: isDestructive
//               ? Colors.red.withOpacity(0.1)
//               : isHighlighted
//               ? Colors.orange.withOpacity(0.2)
//               : primaryViolet.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Icon(
//           icon,
//           color: isDestructive
//               ? Colors.red
//               : isHighlighted
//               ? Colors.orange
//               : primaryViolet,
//         ),
//       ),
//       title: Text(
//         label,
//         style: TextStyle(
//           fontSize: 16,
//           fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
//           color: isDestructive
//               ? Colors.red
//               : isHighlighted
//               ? Colors.orange
//               : Colors.black87,
//         ),
//       ),
//       trailing: Icon(
//         Icons.arrow_forward_ios,
//         size: 16,
//         color: isDestructive
//             ? Colors.red
//             : isHighlighted
//             ? Colors.orange
//             : Colors.grey,
//       ),
//       onTap: onTap,
//       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(8),
//       ),
//       tileColor: isHighlighted ? Colors.orange.withOpacity(0.05) : null,
//     );
//   }
// }