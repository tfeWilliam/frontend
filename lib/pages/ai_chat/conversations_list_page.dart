/// **************************************************************************************
///
/// PAGE UI : LISTE DES CONVERSATIONS AVEC L'ASSISTANT IA (GÉNÉRAL)
/// Fichier: lib/screens/ai_chat/conversations_list_page.dart
///
/// OBJECTIF :
/// Ce fichier définit l'interface utilisateur pour afficher la liste des conversations
/// qu'un utilisateur général (potentiellement un administrateur) a eues avec
/// l'assistant IA de l'application.
///
/// ARCHITECTURE ET GESTION D'ÉTAT :
/// - Utilise un `StatefulWidget` pour gérer son cycle de vie, notamment le chargement
/// initial des données dans `initState`.
/// - S'appuie sur le package `provider` (`Consumer<AIChatProvider>`) pour écouter les
/// changements d'état et reconstruire l'interface de manière réactive.
///
/// FONCTIONNALITÉS CLÉS :
/// - Affiche une liste de conversations avec un aperçu du dernier message.
/// - Gère les états de chargement, d'erreur, et le cas où la liste est vide.
/// - Permet de supprimer des conversations (par glissement ou via un bouton).
/// - Inclut une fonctionnalité "tirer pour rafraîchir" (`RefreshIndicator`).
/// - Permet de naviguer vers une conversation existante ou d'en créer une nouvelle.
///
///***************************************************************************************
library;
import 'package:flutter/material.dart';
import 'package:hairbnb/pages/ai_chat/providers/ai_chat_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../widgets/custom_app_bar.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'chat_page.dart';

/// Widget principal (Stateful) qui affiche la liste des conversations pour l'utilisateur général.
class ConversationsListPage extends StatefulWidget {
  final dynamic currentUser;

  const ConversationsListPage({super.key, required this.currentUser});

  @override
  _ConversationsListPageState createState() => _ConversationsListPageState();
}

class _ConversationsListPageState extends State<ConversationsListPage> {
  @override
  void initState() {
    super.initState();
    // Utilise `Future.microtask` pour déclencher le chargement des conversations de manière asynchrone
    // dès que possible après la construction du widget, sans bloquer le rendu initial.
    Future.microtask(() =>
        Provider.of<AIChatProvider>(context, listen: false).loadConversations()
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: CustomAppBar(),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [primaryColor, primaryColor.withOpacity(0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.assistant, color: Colors.white, size: 40),
                  SizedBox(height: 16),
                  Text('Assistant Hairbnb', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  Text('Gestion Générale', style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.chat_bubble, color: primaryColor),
              title: Text('Mes Conversations'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.analytics, color: primaryColor),
              title: Text('Statistiques'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.help, color: primaryColor),
              title: Text('Aide'),
              onTap: () {
                Navigator.pop(context);
                _showHelpDialog();
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // En-tête personnalisé pour la page.
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [primaryColor, primaryColor.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.assistant, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Expanded(child: Text('Assistant Hairbnb', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))),
                    Icon(Icons.support_agent, color: Colors.orange, size: 28),
                  ],
                ),
                SizedBox(height: 8),
                Text('Gestion complète de votre application', style: TextStyle(color: Colors.white70, fontSize: 14), textAlign: TextAlign.center),
              ],
            ),
          ),
          // Contenu principal qui s'adapte à l'état du provider.
          Expanded(
            child: Consumer<AIChatProvider>(
              builder: (context, chatProvider, child) {
                // CAS 1: En cours de chargement initial.
                if (chatProvider.isLoading && chatProvider.conversations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryColor)),
                        SizedBox(height: 16),
                        Text('Chargement de vos conversations...', style: TextStyle(color: primaryColor, fontSize: 16)),
                      ],
                    ),
                  );
                }

                // CAS 2: Une erreur est survenue lors du chargement.
                if (chatProvider.error != null && chatProvider.conversations.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                          SizedBox(height: 16),
                          Text('Oups ! Une erreur est survenue', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red[400])),
                          SizedBox(height: 8),
                          Text(chatProvider.error!, style: TextStyle(color: Colors.red[600]), textAlign: TextAlign.center),
                          SizedBox(height: 20),
                          ElevatedButton.icon(
                            icon: Icon(Icons.refresh),
                            label: Text('Réessayer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                            ),
                            onPressed: () => chatProvider.loadConversations(),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // CAS 3: Aucune conversation à afficher.
                if (chatProvider.conversations.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(24),
                            decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(50)),
                            child: Icon(Icons.assistant, size: 80, color: primaryColor),
                          ),
                          SizedBox(height: 24),
                          Text('Aucune conversation', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor)),
                          SizedBox(height: 12),
                          Text('Commencez une nouvelle conversation avec l\'assistant Hairbnb pour gérer votre application !', style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4), textAlign: TextAlign.center),
                          SizedBox(height: 32),
                          _buildFeatureCard(icon: Icons.analytics, title: 'Analyses avancées', description: 'Obtenez des statistiques détaillées'),
                          SizedBox(height: 12),
                          _buildFeatureCard(icon: Icons.support_agent, title: 'Support technique', description: 'Assistance pour tous vos besoins'),
                          SizedBox(height: 12),
                          _buildFeatureCard(icon: Icons.trending_up, title: 'Optimisation business', description: 'Conseils pour développer votre activité'),
                          SizedBox(height: 32),
                          ElevatedButton.icon(
                            icon: Icon(Icons.add_circle_outline),
                            label: Text('Commencer maintenant'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              elevation: 4,
                            ),
                            onPressed: () => _startNewConversation(context),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // CAS 4: Affichage de la liste des conversations.
                return RefreshIndicator(
                  onRefresh: () => chatProvider.loadConversations(),
                  color: primaryColor,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: chatProvider.conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = chatProvider.conversations[index];
                      final dateFormat = DateFormat('dd/MM/yyyy à HH:mm');
                      final formattedDate = dateFormat.format(conversation.createdAt);

                      // Détermine le texte d'aperçu à afficher pour la conversation.
                      final previewText = conversation.lastMessage ?? (conversation.messages.isNotEmpty ? conversation.messages.last.content : "Nouvelle conversation");

                      return Dismissible(
                        key: Key('conversation-${conversation.id}'),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          chatProvider.deleteConversation(conversation.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Conversation supprimée'),
                              backgroundColor: primaryColor,
                              action: SnackBarAction(label: 'Annuler', textColor: Colors.white, onPressed: () => chatProvider.loadConversations()),
                            ),
                          );
                        },
                        confirmDismiss: (direction) async => await _showDeleteDialog(context),
                        background: Container(
                          margin: EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.only(right: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [Icon(Icons.delete, color: Colors.white, size: 24), Text('Supprimer', style: TextStyle(color: Colors.white, fontSize: 12))],
                          ),
                        ),
                        child: Container(
                          margin: EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [Colors.white, primaryColor.withOpacity(0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.1), blurRadius: 8, offset: Offset(0, 2))],
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            leading: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [primaryColor, primaryColor.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.assistant, color: Colors.white, size: 24),
                            ),
                            title: Text('Conversation du $formattedDate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor.withOpacity(0.8))),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 4),
                                Text(previewText, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14)),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.token, size: 14, color: Colors.orange),
                                    SizedBox(width: 4),
                                    Text('${conversation.tokensUsed} tokens utilisés', style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red, size: 20),
                                  onPressed: () async {
                                    final confirmed = await _showDeleteDialog(context);
                                    if (confirmed == true) {
                                      chatProvider.deleteConversation(conversation.id);
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Conversation supprimée'), backgroundColor: primaryColor));
                                    }
                                  },
                                ),
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                  child: Icon(Icons.arrow_forward_ios, size: 16, color: primaryColor),
                                ),
                              ],
                            ),
                            onTap: () => _openConversation(context, conversation.id),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startNewConversation(context),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        icon: Icon(Icons.add_circle_outline),
        label: Text('Nouvelle conversation'),
        elevation: 6,
        tooltip: 'Nouvelle conversation',
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 4,
        onTap: (index) {},
      ),
    );
  }

  /// Construit une carte réutilisable pour présenter une fonctionnalité (utilisée dans l'état vide).
  Widget _buildFeatureCard({required IconData icon, required String title, required String description}) {
    final Color primaryColor = Theme.of(context).primaryColor;
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: primaryColor, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primaryColor)),
                Text(description, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Affiche une boîte de dialogue modale pour confirmer la suppression d'une conversation.
  Future<bool?> _showDeleteDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [Icon(Icons.warning, color: Colors.orange), SizedBox(width: 8), Text('Confirmation')]),
          content: Text('Voulez-vous vraiment supprimer cette conversation ? Cette action est irréversible.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Annuler', style: TextStyle(color: Colors.grey[600]))),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  /// Affiche une boîte de dialogue d'aide informative.
  void _showHelpDialog() {
    final Color primaryColor = Theme.of(context).primaryColor;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [Icon(Icons.help, color: primaryColor), SizedBox(width: 8), Text('Aide - Assistant Hairbnb')]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Comment utiliser votre Assistant Hairbnb :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 12),
            _buildHelpItem('💬', 'Créez des conversations pour poser vos questions'),
            _buildHelpItem('📊', 'Demandez des analyses de votre application'),
            _buildHelpItem('📈', 'Consultez vos statistiques business'),
            _buildHelpItem('💡', 'Obtenez des conseils personnalisés'),
            _buildHelpItem('🗑️', 'Glissez vers la gauche pour supprimer une conversation'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Compris !', style: TextStyle(color: primaryColor))),
        ],
      ),
    );
  }

  /// Construit un item dans la liste d'aide de la boîte de dialogue.
  Widget _buildHelpItem(String emoji, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: 16)),
          SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  /// Gère la création d'une nouvelle conversation via le provider et navigue vers la page de chat.
  void _startNewConversation(BuildContext context) async {
    final provider = Provider.of<AIChatProvider>(context, listen: false);
    await provider.createNewConversation();
    if (provider.activeConversation != null) {
      _navigateToChatPage(context);
    }
  }

  /// Définit la conversation sélectionnée comme active dans le provider et navigue vers la page de chat.
  void _openConversation(BuildContext context, int conversationId) {
    final provider = Provider.of<AIChatProvider>(context, listen: false);
    provider.setActiveConversation(conversationId);
    _navigateToChatPage(context);
  }

  /// Gère la navigation vers [AiChatPage], en passant l'instance existante du provider
  /// pour assurer la continuité de l'état.
  void _navigateToChatPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: Provider.of<AIChatProvider>(context, listen: false),
          child: AiChatPage(currentUser: widget.currentUser),
        ),
      ),
    );
  }
}






// // lib/screens/ai_chat/conversations_list_page.dart
// import 'package:flutter/material.dart';
// import 'package:hairbnb/pages/ai_chat/providers/ai_chat_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';
//
// import '../../widgets/custom_app_bar.dart';
// import '../../widgets/bottom_nav_bar.dart';
// import 'chat_page.dart';
//
// class ConversationsListPage extends StatefulWidget {
//   final dynamic currentUser;
//
//   const ConversationsListPage({super.key, required this.currentUser});
//
//   @override
//   _ConversationsListPageState createState() => _ConversationsListPageState();
// }
//
// class _ConversationsListPageState extends State<ConversationsListPage> {
//   @override
//   void initState() {
//     super.initState();
//     // Charger les conversations au démarrage
//     Future.microtask(() =>
//         Provider.of<AIChatProvider>(context, listen: false).loadConversations()
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final Color primaryColor = Theme.of(context).primaryColor;
//
//     return Scaffold(
//       // ✅ Ajout du CustomAppBar
//       appBar: CustomAppBar(),
//
//       // ✅ Drawer pour la navigation
//       drawer: Drawer(
//         child: ListView(
//           padding: EdgeInsets.zero,
//           children: [
//             DrawerHeader(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [primaryColor, primaryColor.withOpacity(0.7)],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Icon(Icons.assistant, color: Colors.white, size: 40),
//                   SizedBox(height: 16),
//                   Text(
//                     'Assistant Hairbnb',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   Text(
//                     'Gestion Générale',
//                     style: TextStyle(
//                       color: Colors.white70,
//                       fontSize: 14,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             ListTile(
//               leading: Icon(Icons.chat_bubble, color: primaryColor),
//               title: Text('Mes Conversations'),
//               onTap: () {
//                 Navigator.pop(context);
//               },
//             ),
//             ListTile(
//               leading: Icon(Icons.analytics, color: primaryColor),
//               title: Text('Statistiques'),
//               onTap: () {
//                 Navigator.pop(context);
//                 // Naviguer vers les statistiques
//               },
//             ),
//             ListTile(
//               leading: Icon(Icons.help, color: primaryColor),
//               title: Text('Aide'),
//               onTap: () {
//                 Navigator.pop(context);
//                 _showHelpDialog();
//               },
//             ),
//           ],
//         ),
//       ),
//
//       body: Column(
//         children: [
//           // ✅ Header personnalisé pour l'assistant général
//           Container(
//             width: double.infinity,
//             padding: EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [primaryColor, primaryColor.withOpacity(0.8)],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               borderRadius: BorderRadius.only(
//                 bottomLeft: Radius.circular(30),
//                 bottomRight: Radius.circular(30),
//               ),
//             ),
//             child: Column(
//               children: [
//                 Row(
//                   children: [
//                     Icon(Icons.assistant, color: Colors.white, size: 28),
//                     SizedBox(width: 12),
//                     Expanded(
//                       child: Text(
//                         'Assistant Hairbnb',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 22,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                     Icon(Icons.support_agent, color: Colors.orange, size: 28),
//                   ],
//                 ),
//                 SizedBox(height: 8),
//                 Text(
//                   'Gestion complète de votre application',
//                   style: TextStyle(
//                     color: Colors.white70,
//                     fontSize: 14,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//               ],
//             ),
//           ),
//
//           // ✅ Contenu principal
//           Expanded(
//             child: Consumer<AIChatProvider>(
//               builder: (context, chatProvider, child) {
//                 if (chatProvider.isLoading && chatProvider.conversations.isEmpty) {
//                   return Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         CircularProgressIndicator(
//                           valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
//                         ),
//                         SizedBox(height: 16),
//                         Text(
//                           'Chargement de vos conversations...',
//                           style: TextStyle(
//                             color: primaryColor,
//                             fontSize: 16,
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 }
//
//                 if (chatProvider.error != null && chatProvider.conversations.isEmpty) {
//                   return Center(
//                     child: Padding(
//                       padding: EdgeInsets.all(20),
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(
//                             Icons.error_outline,
//                             size: 64,
//                             color: Colors.red[400],
//                           ),
//                           SizedBox(height: 16),
//                           Text(
//                             'Oups ! Une erreur est survenue',
//                             style: TextStyle(
//                               fontSize: 20,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.red[400],
//                             ),
//                           ),
//                           SizedBox(height: 8),
//                           Text(
//                             chatProvider.error!,
//                             style: TextStyle(color: Colors.red[600]),
//                             textAlign: TextAlign.center,
//                           ),
//                           SizedBox(height: 20),
//                           ElevatedButton.icon(
//                             icon: Icon(Icons.refresh),
//                             label: Text('Réessayer'),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: primaryColor,
//                               foregroundColor: Colors.white,
//                               padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(25),
//                               ),
//                             ),
//                             onPressed: () => chatProvider.loadConversations(),
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 }
//
//                 if (chatProvider.conversations.isEmpty) {
//                   return Center(
//                     child: Padding(
//                       padding: EdgeInsets.all(24),
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Container(
//                             padding: EdgeInsets.all(24),
//                             decoration: BoxDecoration(
//                               color: primaryColor.withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(50),
//                             ),
//                             child: Icon(
//                               Icons.assistant,
//                               size: 80,
//                               color: primaryColor,
//                             ),
//                           ),
//                           SizedBox(height: 24),
//                           Text(
//                             'Aucune conversation',
//                             style: TextStyle(
//                               fontSize: 24,
//                               fontWeight: FontWeight.bold,
//                               color: primaryColor,
//                             ),
//                           ),
//                           SizedBox(height: 12),
//                           Text(
//                             'Commencez une nouvelle conversation avec l\'assistant Hairbnb pour gérer votre application !',
//                             style: TextStyle(
//                               fontSize: 16,
//                               color: Colors.grey[600],
//                               height: 1.4,
//                             ),
//                             textAlign: TextAlign.center,
//                           ),
//                           SizedBox(height: 32),
//                           _buildFeatureCard(
//                             icon: Icons.analytics,
//                             title: 'Analyses avancées',
//                             description: 'Obtenez des statistiques détaillées',
//                           ),
//                           SizedBox(height: 12),
//                           _buildFeatureCard(
//                             icon: Icons.support_agent,
//                             title: 'Support technique',
//                             description: 'Assistance pour tous vos besoins',
//                           ),
//                           SizedBox(height: 12),
//                           _buildFeatureCard(
//                             icon: Icons.trending_up,
//                             title: 'Optimisation business',
//                             description: 'Conseils pour développer votre activité',
//                           ),
//                           SizedBox(height: 32),
//                           ElevatedButton.icon(
//                             icon: Icon(Icons.add_circle_outline),
//                             label: Text('Commencer maintenant'),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: primaryColor,
//                               foregroundColor: Colors.white,
//                               padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(30),
//                               ),
//                               elevation: 4,
//                             ),
//                             onPressed: () => _startNewConversation(context),
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 }
//
//                 return RefreshIndicator(
//                   onRefresh: () => chatProvider.loadConversations(),
//                   color: primaryColor,
//                   child: ListView.builder(
//                     padding: EdgeInsets.all(16),
//                     itemCount: chatProvider.conversations.length,
//                     itemBuilder: (context, index) {
//                       final conversation = chatProvider.conversations[index];
//                       final dateFormat = DateFormat('dd/MM/yyyy à HH:mm');
//                       final formattedDate = dateFormat.format(conversation.createdAt);
//
//                       // Texte à afficher comme aperçu de la conversation
//                       final previewText = conversation.lastMessage ??
//                           (conversation.messages.isNotEmpty ?
//                           conversation.messages.last.content :
//                           "Nouvelle conversation");
//
//                       return Dismissible(
//                         key: Key('conversation-${conversation.id}'),
//                         direction: DismissDirection.endToStart,
//                         onDismissed: (direction) {
//                           chatProvider.deleteConversation(conversation.id);
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                               content: Text('Conversation supprimée'),
//                               backgroundColor: primaryColor,
//                               action: SnackBarAction(
//                                 label: 'Annuler',
//                                 textColor: Colors.white,
//                                 onPressed: () {
//                                   chatProvider.loadConversations();
//                                 },
//                               ),
//                             ),
//                           );
//                         },
//                         confirmDismiss: (direction) async {
//                           return await _showDeleteDialog(context);
//                         },
//                         background: Container(
//                           margin: EdgeInsets.symmetric(vertical: 4),
//                           decoration: BoxDecoration(
//                             color: Colors.red,
//                             borderRadius: BorderRadius.circular(16),
//                           ),
//                           alignment: Alignment.centerRight,
//                           padding: EdgeInsets.only(right: 20),
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Icon(Icons.delete, color: Colors.white, size: 24),
//                               Text('Supprimer', style: TextStyle(color: Colors.white, fontSize: 12)),
//                             ],
//                           ),
//                         ),
//                         child: Container(
//                           margin: EdgeInsets.symmetric(vertical: 4),
//                           decoration: BoxDecoration(
//                             gradient: LinearGradient(
//                               colors: [Colors.white, primaryColor.withOpacity(0.05)],
//                               begin: Alignment.topLeft,
//                               end: Alignment.bottomRight,
//                             ),
//                             borderRadius: BorderRadius.circular(16),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: primaryColor.withOpacity(0.1),
//                                 blurRadius: 8,
//                                 offset: Offset(0, 2),
//                               ),
//                             ],
//                           ),
//                           child: ListTile(
//                             contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                             leading: Container(
//                               padding: EdgeInsets.all(12),
//                               decoration: BoxDecoration(
//                                 gradient: LinearGradient(
//                                   colors: [primaryColor, primaryColor.withOpacity(0.8)],
//                                   begin: Alignment.topLeft,
//                                   end: Alignment.bottomRight,
//                                 ),
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               child: Icon(Icons.assistant, color: Colors.white, size: 24),
//                             ),
//                             title: Text(
//                               'Conversation du $formattedDate',
//                               style: TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 16,
//                                 color: primaryColor.withOpacity(0.8),
//                               ),
//                             ),
//                             subtitle: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 SizedBox(height: 4),
//                                 Text(
//                                   previewText,
//                                   maxLines: 2,
//                                   overflow: TextOverflow.ellipsis,
//                                   style: TextStyle(fontSize: 14),
//                                 ),
//                                 SizedBox(height: 4),
//                                 Row(
//                                   children: [
//                                     Icon(Icons.token, size: 14, color: Colors.orange),
//                                     SizedBox(width: 4),
//                                     Text(
//                                       '${conversation.tokensUsed} tokens utilisés',
//                                       style: TextStyle(
//                                         fontSize: 12,
//                                         color: Colors.orange,
//                                         fontWeight: FontWeight.w500,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                             trailing: Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 IconButton(
//                                   icon: Icon(Icons.delete, color: Colors.red, size: 20),
//                                   onPressed: () async {
//                                     final confirmed = await _showDeleteDialog(context);
//                                     if (confirmed == true) {
//                                       chatProvider.deleteConversation(conversation.id);
//                                       ScaffoldMessenger.of(context).showSnackBar(
//                                         SnackBar(
//                                           content: Text('Conversation supprimée'),
//                                           backgroundColor: primaryColor,
//                                         ),
//                                       );
//                                     }
//                                   },
//                                 ),
//                                 Container(
//                                   padding: EdgeInsets.all(8),
//                                   decoration: BoxDecoration(
//                                     color: primaryColor.withOpacity(0.1),
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                   child: Icon(
//                                     Icons.arrow_forward_ios,
//                                     size: 16,
//                                     color: primaryColor,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             onTap: () => _openConversation(context, conversation.id),
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//
//       // ✅ Bouton flottant pour nouvelle conversation
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: () => _startNewConversation(context),
//         backgroundColor: primaryColor,
//         foregroundColor: Colors.white,
//         icon: Icon(Icons.add_circle_outline),
//         label: Text('Nouvelle conversation'),
//         elevation: 6,
//         tooltip: 'Nouvelle conversation',
//       ),
//
//       // ✅ Ajout du BottomNavBar
//       bottomNavigationBar: BottomNavBar(
//         currentIndex: 4, // Index pour "Profil" ou selon votre logique
//         onTap: (index) {
//           // La gestion est faite dans BottomNavBar lui-même
//         },
//       ),
//     );
//   }
//
//   Widget _buildFeatureCard({
//     required IconData icon,
//     required String title,
//     required String description,
//   }) {
//     final Color primaryColor = Theme.of(context).primaryColor;
//
//     return Container(
//       padding: EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: primaryColor.withOpacity(0.2),
//           width: 1,
//         ),
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: primaryColor.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Icon(icon, color: primaryColor, size: 20),
//           ),
//           SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 14,
//                     color: primaryColor,
//                   ),
//                 ),
//                 Text(
//                   description,
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<bool?> _showDeleteDialog(BuildContext context) {
//     return showDialog<bool>(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//           title: Row(
//             children: [
//               Icon(Icons.warning, color: Colors.orange),
//               SizedBox(width: 8),
//               Text('Confirmation'),
//             ],
//           ),
//           content: Text('Voulez-vous vraiment supprimer cette conversation ? Cette action est irréversible.'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(false),
//               child: Text('Annuler', style: TextStyle(color: Colors.grey[600])),
//             ),
//             ElevatedButton(
//               onPressed: () => Navigator.of(context).pop(true),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.red,
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//               ),
//               child: Text('Supprimer'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   void _showHelpDialog() {
//     final Color primaryColor = Theme.of(context).primaryColor;
//
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: Row(
//           children: [
//             Icon(Icons.help, color: primaryColor),
//             SizedBox(width: 8),
//             Text('Aide - Assistant Hairbnb'),
//           ],
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Comment utiliser votre Assistant Hairbnb :',
//               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//             ),
//             SizedBox(height: 12),
//             _buildHelpItem('💬', 'Créez des conversations pour poser vos questions'),
//             _buildHelpItem('📊', 'Demandez des analyses de votre application'),
//             _buildHelpItem('📈', 'Consultez vos statistiques business'),
//             _buildHelpItem('💡', 'Obtenez des conseils personnalisés'),
//             _buildHelpItem('🗑️', 'Glissez vers la gauche pour supprimer une conversation'),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: Text('Compris !', style: TextStyle(color: primaryColor)),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildHelpItem(String emoji, String text) {
//     return Padding(
//       padding: EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         children: [
//           Text(emoji, style: TextStyle(fontSize: 16)),
//           SizedBox(width: 12),
//           Expanded(
//             child: Text(text, style: TextStyle(fontSize: 14)),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _startNewConversation(BuildContext context) async {
//     final provider = Provider.of<AIChatProvider>(context, listen: false);
//     await provider.createNewConversation();
//     if (provider.activeConversation != null) {
//       _navigateToChatPage(context);
//     }
//   }
//
//   void _openConversation(BuildContext context, int conversationId) {
//     final provider = Provider.of<AIChatProvider>(context, listen: false);
//     provider.setActiveConversation(conversationId);
//     _navigateToChatPage(context);
//   }
//
//   void _navigateToChatPage(BuildContext context) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => ChangeNotifierProvider.value(
//           value: Provider.of<AIChatProvider>(context, listen: false),
//           child: AiChatPage(currentUser: widget.currentUser),
//         ),
//       ),
//     );
//   }
// }