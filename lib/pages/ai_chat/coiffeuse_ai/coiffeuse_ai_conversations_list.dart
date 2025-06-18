import 'package:flutter/material.dart';
import 'package:hairbnb/pages/ai_chat/services/coiffeuse_ai_chat_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../services/providers/coiffeuse_ai_chat_provider.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/bottom_nav_bar.dart';
import 'coiffeuse_ai_chat.dart';

/// Widget principal (Stateful) qui initialise le [CoiffeuseAIChatProvider].
class CoiffeuseConversationsListPage extends StatefulWidget {
  /// L'objet utilisateur actuel, requis pour la page.
  final currentUser;
  /// Une instance optionnelle du service de chat, utile pour l'injection de dépendances et les tests.
  final CoiffeuseAIChatService? chatService;

  const CoiffeuseConversationsListPage({super.key, required this.currentUser, this.chatService});

  @override
  _CoiffeuseConversationsListPageState createState() => _CoiffeuseConversationsListPageState();
}

class _CoiffeuseConversationsListPageState extends State<CoiffeuseConversationsListPage> {
  @override
  Widget build(BuildContext context) {
    // Fournit une instance de CoiffeuseAIChatProvider à l'arbre de widgets.
    // Tous les widgets enfants pourront accéder à ce provider pour lire ou modifier l'état.
    return ChangeNotifierProvider<CoiffeuseAIChatProvider>(
      create: (context) => CoiffeuseAIChatProvider(
        widget.chatService ??
            CoiffeuseAIChatService(baseUrl: 'https://www.hairbnb.site/api', token: ''),
      ),
      child: _ConversationsContent(currentUser: widget.currentUser),
    );
  }
}

/// Widget interne qui gère l'affichage de l'ensemble du contenu de la page.
class _ConversationsContent extends StatefulWidget {
  final currentUser;

  const _ConversationsContent({required this.currentUser});

  @override
  _ConversationsContentState createState() => _ConversationsContentState();
}

class _ConversationsContentState extends State<_ConversationsContent> {
  // --- DÉFINITION DU THÈME VISUEL POUR LA COIFFEUSE ---
  static const Color primaryCoiffeuseColor = Color(0xFFE91E63); // Rose vibrant
  static const Color secondaryCoiffeuseColor = Color(0xFF9C27B0); // Violet
  static const Color accentCoiffeuseColor = Color(0xFFFFC107); // Doré
  static const Color lightCoiffeuseColor = Color(0xFFFCE4EC); // Rose très clair

  @override
  void initState() {
    super.initState();
    // Déclenche le chargement des conversations via le Provider après la construction du premier frame.
    // C'est la méthode recommandée pour appeler une logique asynchrone dans initState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CoiffeuseAIChatProvider>(context, listen: false).loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryCoiffeuseColor, secondaryCoiffeuseColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white, size: 40),
                  SizedBox(height: 16),
                  Text(
                    'Assistant IA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Coiffeuses Professionnelles',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.chat_bubble, color: primaryCoiffeuseColor),
              title: Text('Mes Conversations'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.analytics, color: primaryCoiffeuseColor),
              title: Text('Statistiques'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.help, color: primaryCoiffeuseColor),
              title: Text('Aide'),
              onTap: () {
                Navigator.pop(context);
                _showHelpDialog();
              },
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [lightCoiffeuseColor, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // En-tête personnalisé de la page
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryCoiffeuseColor, secondaryCoiffeuseColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.content_cut, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Mon Assistant IA Personnel',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Icon(Icons.auto_awesome, color: accentCoiffeuseColor, size: 28),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Analysez, optimisez et développez votre salon',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Le Consumer écoute les changements du [CoiffeuseAIChatProvider] et reconstruit l'UI en conséquence.
            Expanded(
              child: Consumer<CoiffeuseAIChatProvider>(
                builder: (context, chatProvider, child) {
                  // CAS 1: En cours de chargement initial des conversations.
                  if (chatProvider.isLoading && chatProvider.conversations.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(primaryCoiffeuseColor),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Chargement de vos conversations...',
                            style: TextStyle(
                              color: primaryCoiffeuseColor,
                              fontSize: 16,
                            ),
                          ),
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
                            Text(
                              'Oups ! Une erreur est survenue',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red[400]),
                            ),
                            SizedBox(height: 8),
                            Text(chatProvider.error!, style: TextStyle(color: Colors.red[600]), textAlign: TextAlign.center),
                            SizedBox(height: 20),
                            ElevatedButton.icon(
                              icon: Icon(Icons.refresh),
                              label: Text('Réessayer'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryCoiffeuseColor,
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

                  // CAS 3: Aucune conversation à afficher (liste vide).
                  if (chatProvider.conversations.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: primaryCoiffeuseColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Icon(Icons.auto_awesome, size: 80, color: primaryCoiffeuseColor),
                            ),
                            SizedBox(height: 24),
                            Text('Aucune conversation', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryCoiffeuseColor)),
                            SizedBox(height: 12),
                            Text(
                              'Commencez dès maintenant à analyser vos données avec votre assistant IA personnel !',
                              style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 32),
                            _buildFeatureCard(icon: Icons.analytics, title: 'Analysez vos statistiques', description: 'Découvrez vos performances business'),
                            SizedBox(height: 12),
                            _buildFeatureCard(icon: Icons.schedule, title: 'Gérez vos rendez-vous', description: 'Optimisez votre planning en temps réel'),
                            SizedBox(height: 12),
                            _buildFeatureCard(icon: Icons.trending_up, title: 'Boostez votre activité', description: 'Obtenez des conseils personnalisés'),
                            SizedBox(height: 32),
                            ElevatedButton.icon(
                              icon: Icon(Icons.add_circle_outline),
                              label: Text('Commencer maintenant'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryCoiffeuseColor,
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
                    color: primaryCoiffeuseColor,
                    child: ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: chatProvider.conversations.length,
                      itemBuilder: (context, index) {
                        final conversation = chatProvider.conversations[index];
                        final dateFormat = DateFormat('dd/MM/yyyy à HH:mm');
                        final formattedDate = dateFormat.format(conversation.createdAt);

                        // Widget permettant la suppression par glissement.
                        return Dismissible(
                          key: Key('conversation-${conversation.id}'),
                          direction: DismissDirection.endToStart,
                          onDismissed: (direction) {
                            chatProvider.deleteConversation(conversation.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Conversation supprimée'),
                                backgroundColor: primaryCoiffeuseColor,
                                action: SnackBarAction(
                                  label: 'Annuler',
                                  textColor: Colors.white,
                                  onPressed: () {
                                    chatProvider.loadConversations();
                                  },
                                ),
                              ),
                            );
                          },
                          confirmDismiss: (direction) async {
                            return await _showDeleteDialog(context);
                          },
                          background: Container(
                            margin: EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
                            alignment: Alignment.centerRight,
                            padding: EdgeInsets.only(right: 20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.delete, color: Colors.white, size: 24),
                                Text('Supprimer', style: TextStyle(color: Colors.white, fontSize: 12)),
                              ],
                            ),
                          ),
                          child: Container(
                            margin: EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.white, lightCoiffeuseColor.withOpacity(0.3)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(color: primaryCoiffeuseColor.withOpacity(0.1), blurRadius: 8, offset: Offset(0, 2)),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              leading: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [primaryCoiffeuseColor, secondaryCoiffeuseColor],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                              ),
                              title: Text(
                                conversation.title,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryCoiffeuseColor.withOpacity(0.8)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                                      SizedBox(width: 4),
                                      Text(formattedDate, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                                    ],
                                  ),
                                  SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(Icons.token, size: 14, color: accentCoiffeuseColor),
                                      SizedBox(width: 4),
                                      Text('${conversation.tokensUsed} tokens utilisés', style: TextStyle(fontSize: 12, color: accentCoiffeuseColor, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: primaryCoiffeuseColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                    child: Icon(Icons.arrow_forward_ios, size: 16, color: primaryCoiffeuseColor),
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startNewConversation(context),
        backgroundColor: primaryCoiffeuseColor,
        foregroundColor: Colors.white,
        icon: Icon(Icons.add_circle_outline),
        label: Text('Nouvelle conversation'),
        elevation: 6,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 4,
        onTap: (index) {},
      ),
    );
  }

  /// Construit une carte réutilisable pour présenter une fonctionnalité (utilisée dans l'état vide).
  Widget _buildFeatureCard({required IconData icon, required String title, required String description}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryCoiffeuseColor.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: primaryCoiffeuseColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: primaryCoiffeuseColor, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primaryCoiffeuseColor)),
                Text(description, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Affiche une boîte de dialogue pour confirmer la suppression d'une conversation.
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

  /// Affiche une boîte de dialogue d'aide expliquant comment utiliser l'assistant IA.
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [Icon(Icons.help, color: primaryCoiffeuseColor), SizedBox(width: 8), Text('Aide - Assistant IA')]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Comment utiliser votre Assistant IA :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 12),
            _buildHelpItem('💬', 'Créez des conversations pour poser vos questions'),
            _buildHelpItem('📊', 'Demandez des analyses de vos performances'),
            _buildHelpItem('📅', 'Consultez vos statistiques de rendez-vous'),
            _buildHelpItem('💡', 'Obtenez des conseils personnalisés'),
            _buildHelpItem('🗑️', 'Glissez vers la gauche pour supprimer une conversation'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Compris !', style: TextStyle(color: primaryCoiffeuseColor))),
        ],
      ),
    );
  }

  /// Construit un item de la liste d'aide.
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

  /// Gère la logique de création d'une nouvelle conversation et navigue vers la page de chat.
  void _startNewConversation(BuildContext context) async {
    final provider = Provider.of<CoiffeuseAIChatProvider>(context, listen: false);

    try {
      final newConversation = await provider.createNewConversation();
      if (newConversation != null) {
        // La méthode createNewConversation dans le provider définit déjà la conversation active.
        _navigateToChatPage(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la création de la conversation'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// Définit la conversation sélectionnée comme active dans le provider et navigue vers la page de chat.
  void _openConversation(BuildContext context, int conversationId) {
    final provider = Provider.of<CoiffeuseAIChatProvider>(context, listen: false);
    provider.setActiveConversation(conversationId);
    _navigateToChatPage(context);
  }

  /// Gère la navigation vers la page de chat [CoiffeuseAiChatPage].
  /// Utilise `ChangeNotifierProvider.value` pour passer l'instance existante du provider
  /// à la nouvelle route, assurant ainsi la continuité de l'état.
  void _navigateToChatPage(BuildContext context) {
    final chatProvider = Provider.of<CoiffeuseAIChatProvider>(context, listen: false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: chatProvider,
          child: CoiffeuseAiChatPage(currentUser: widget.currentUser),
        ),
      ),
    );
  }
}







// // lib/pages/ai_chat/coiffeuse/coiffeuse_conversations_list_page.dart
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:hairbnb/pages/ai_chat/services/coiffeuse_ai_chat_service.dart';
// import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';
//
// import '../../../services/providers/coiffeuse_ai_chat_provider.dart';
// import '../../../widgets/custom_app_bar.dart';
// import '../../../widgets/bottom_nav_bar.dart';
// import 'coiffeuse_ai_chat.dart';
//
// class CoiffeuseConversationsListPage extends StatefulWidget {
//   final currentUser;
//   final CoiffeuseAIChatService? chatService;
//
//   const CoiffeuseConversationsListPage({super.key, required this.currentUser, this.chatService});
//
//   @override
//   _CoiffeuseConversationsListPageState createState() => _CoiffeuseConversationsListPageState();
// }
//
// class _CoiffeuseConversationsListPageState extends State<CoiffeuseConversationsListPage> {
//   // Couleurs spécifiques aux coiffeuses
// // Rose vibrant
// // Violet
// // Doré
// // Rose très clair
//
//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider<CoiffeuseAIChatProvider>(
//       create: (context) => CoiffeuseAIChatProvider(
//         widget.chatService ??
//             CoiffeuseAIChatService(baseUrl: 'https://www.hairbnb.site/api', token: ''),
//       ),
//       child: _ConversationsContent(currentUser: widget.currentUser),
//     );
//   }
// }
//
// class _ConversationsContent extends StatefulWidget {
//   final currentUser;
//
//   const _ConversationsContent({required this.currentUser});
//
//   @override
//   _ConversationsContentState createState() => _ConversationsContentState();
// }
//
// class _ConversationsContentState extends State<_ConversationsContent> {
//   // Couleurs spécifiques aux coiffeuses
//   static const Color primaryCoiffeuseColor = Color(0xFFE91E63); // Rose vibrant
//   static const Color secondaryCoiffeuseColor = Color(0xFF9C27B0); // Violet
//   static const Color accentCoiffeuseColor = Color(0xFFFFC107); // Doré
//   static const Color lightCoiffeuseColor = Color(0xFFFCE4EC); // Rose très clair
//
//   @override
//   void initState() {
//     super.initState();
//     // ✅ Charger les conversations après que le provider soit disponible
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       Provider.of<CoiffeuseAIChatProvider>(context, listen: false).loadConversations();
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // ✅ Ajout du CustomAppBar
//       appBar: CustomAppBar(),
//
//       // ✅ Drawer pour la navigation (optionnel, déjà géré par CustomAppBar)
//       drawer: Drawer(
//         child: ListView(
//           padding: EdgeInsets.zero,
//           children: [
//             DrawerHeader(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [primaryCoiffeuseColor, secondaryCoiffeuseColor],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Icon(Icons.auto_awesome, color: Colors.white, size: 40),
//                   SizedBox(height: 16),
//                   Text(
//                     'Assistant IA',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   Text(
//                     'Coiffeuses Professionnelles',
//                     style: TextStyle(
//                       color: Colors.white70,
//                       fontSize: 14,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             ListTile(
//               leading: Icon(Icons.chat_bubble, color: primaryCoiffeuseColor),
//               title: Text('Mes Conversations'),
//               onTap: () {
//                 Navigator.pop(context);
//               },
//             ),
//             ListTile(
//               leading: Icon(Icons.analytics, color: primaryCoiffeuseColor),
//               title: Text('Statistiques'),
//               onTap: () {
//                 Navigator.pop(context);
//                 // Naviguer vers les statistiques
//               },
//             ),
//             ListTile(
//               leading: Icon(Icons.help, color: primaryCoiffeuseColor),
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
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [lightCoiffeuseColor, Colors.white],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: Column(
//           children: [
//             // ✅ Header personnalisé pour l'IA
//             Container(
//               width: double.infinity,
//               padding: EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [primaryCoiffeuseColor, secondaryCoiffeuseColor],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//                 borderRadius: BorderRadius.only(
//                   bottomLeft: Radius.circular(30),
//                   bottomRight: Radius.circular(30),
//                 ),
//               ),
//               child: Column(
//                 children: [
//                   Row(
//                     children: [
//                       Icon(Icons.content_cut, color: Colors.white, size: 28),
//                       SizedBox(width: 12),
//                       Expanded(
//                         child: Text(
//                           'Mon Assistant IA Personnel',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 22,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                       Icon(Icons.auto_awesome, color: accentCoiffeuseColor, size: 28),
//                     ],
//                   ),
//                   SizedBox(height: 8),
//                   Text(
//                     'Analysez, optimisez et développez votre salon',
//                     style: TextStyle(
//                       color: Colors.white70,
//                       fontSize: 14,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ],
//               ),
//             ),
//
//             // ✅ Contenu principal
//             Expanded(
//               child: Consumer<CoiffeuseAIChatProvider>(
//                 builder: (context, chatProvider, child) {
//                   if (chatProvider.isLoading && chatProvider.conversations.isEmpty) {
//                     return Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           CircularProgressIndicator(
//                             valueColor: AlwaysStoppedAnimation<Color>(primaryCoiffeuseColor),
//                           ),
//                           SizedBox(height: 16),
//                           Text(
//                             'Chargement de vos conversations...',
//                             style: TextStyle(
//                               color: primaryCoiffeuseColor,
//                               fontSize: 16,
//                             ),
//                           ),
//                         ],
//                       ),
//                     );
//                   }
//
//                   if (chatProvider.error != null && chatProvider.conversations.isEmpty) {
//                     return Center(
//                       child: Padding(
//                         padding: EdgeInsets.all(20),
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(
//                               Icons.error_outline,
//                               size: 64,
//                               color: Colors.red[400],
//                             ),
//                             SizedBox(height: 16),
//                             Text(
//                               'Oups ! Une erreur est survenue',
//                               style: TextStyle(
//                                 fontSize: 20,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.red[400],
//                               ),
//                             ),
//                             SizedBox(height: 8),
//                             Text(
//                               chatProvider.error!,
//                               style: TextStyle(color: Colors.red[600]),
//                               textAlign: TextAlign.center,
//                             ),
//                             SizedBox(height: 20),
//                             ElevatedButton.icon(
//                               icon: Icon(Icons.refresh),
//                               label: Text('Réessayer'),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: primaryCoiffeuseColor,
//                                 foregroundColor: Colors.white,
//                                 padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(25),
//                                 ),
//                               ),
//                               onPressed: () => chatProvider.loadConversations(),
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   }
//
//                   if (chatProvider.conversations.isEmpty) {
//                     return Center(
//                       child: Padding(
//                         padding: EdgeInsets.all(24),
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Container(
//                               padding: EdgeInsets.all(24),
//                               decoration: BoxDecoration(
//                                 color: primaryCoiffeuseColor.withOpacity(0.1),
//                                 borderRadius: BorderRadius.circular(50),
//                               ),
//                               child: Icon(
//                                 Icons.auto_awesome,
//                                 size: 80,
//                                 color: primaryCoiffeuseColor,
//                               ),
//                             ),
//                             SizedBox(height: 24),
//                             Text(
//                               'Aucune conversation',
//                               style: TextStyle(
//                                 fontSize: 24,
//                                 fontWeight: FontWeight.bold,
//                                 color: primaryCoiffeuseColor,
//                               ),
//                             ),
//                             SizedBox(height: 12),
//                             Text(
//                               'Commencez dès maintenant à analyser vos données avec votre assistant IA personnel !',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 color: Colors.grey[600],
//                                 height: 1.4,
//                               ),
//                               textAlign: TextAlign.center,
//                             ),
//                             SizedBox(height: 32),
//                             _buildFeatureCard(
//                               icon: Icons.analytics,
//                               title: 'Analysez vos statistiques',
//                               description: 'Découvrez vos performances business',
//                             ),
//                             SizedBox(height: 12),
//                             _buildFeatureCard(
//                               icon: Icons.schedule,
//                               title: 'Gérez vos rendez-vous',
//                               description: 'Optimisez votre planning en temps réel',
//                             ),
//                             SizedBox(height: 12),
//                             _buildFeatureCard(
//                               icon: Icons.trending_up,
//                               title: 'Boostez votre activité',
//                               description: 'Obtenez des conseils personnalisés',
//                             ),
//                             SizedBox(height: 32),
//                             ElevatedButton.icon(
//                               icon: Icon(Icons.add_circle_outline),
//                               label: Text('Commencer maintenant'),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: primaryCoiffeuseColor,
//                                 foregroundColor: Colors.white,
//                                 padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(30),
//                                 ),
//                                 elevation: 4,
//                               ),
//                               onPressed: () => _startNewConversation(context),
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   }
//
//                   return RefreshIndicator(
//                     onRefresh: () => chatProvider.loadConversations(),
//                     color: primaryCoiffeuseColor,
//                     child: ListView.builder(
//                       padding: EdgeInsets.all(16),
//                       itemCount: chatProvider.conversations.length,
//                       itemBuilder: (context, index) {
//                         final conversation = chatProvider.conversations[index];
//                         final dateFormat = DateFormat('dd/MM/yyyy à HH:mm');
//                         final formattedDate = dateFormat.format(conversation.createdAt);
//
//                         return Dismissible(
//                           key: Key('conversation-${conversation.id}'),
//                           direction: DismissDirection.endToStart,
//                           onDismissed: (direction) {
//                             chatProvider.deleteConversation(conversation.id);
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               SnackBar(
//                                 content: Text('Conversation supprimée'),
//                                 backgroundColor: primaryCoiffeuseColor,
//                                 action: SnackBarAction(
//                                   label: 'Annuler',
//                                   textColor: Colors.white,
//                                   onPressed: () {
//                                     chatProvider.loadConversations();
//                                   },
//                                 ),
//                               ),
//                             );
//                           },
//                           confirmDismiss: (direction) async {
//                             return await _showDeleteDialog(context);
//                           },
//                           background: Container(
//                             margin: EdgeInsets.symmetric(vertical: 4),
//                             decoration: BoxDecoration(
//                               color: Colors.red,
//                               borderRadius: BorderRadius.circular(16),
//                             ),
//                             alignment: Alignment.centerRight,
//                             padding: EdgeInsets.only(right: 20),
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Icon(Icons.delete, color: Colors.white, size: 24),
//                                 Text('Supprimer', style: TextStyle(color: Colors.white, fontSize: 12)),
//                               ],
//                             ),
//                           ),
//                           child: Container(
//                             margin: EdgeInsets.symmetric(vertical: 4),
//                             decoration: BoxDecoration(
//                               gradient: LinearGradient(
//                                 colors: [Colors.white, lightCoiffeuseColor.withOpacity(0.3)],
//                                 begin: Alignment.topLeft,
//                                 end: Alignment.bottomRight,
//                               ),
//                               borderRadius: BorderRadius.circular(16),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: primaryCoiffeuseColor.withOpacity(0.1),
//                                   blurRadius: 8,
//                                   offset: Offset(0, 2),
//                                 ),
//                               ],
//                             ),
//                             child: ListTile(
//                               contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                               leading: Container(
//                                 padding: EdgeInsets.all(12),
//                                 decoration: BoxDecoration(
//                                   gradient: LinearGradient(
//                                     colors: [primaryCoiffeuseColor, secondaryCoiffeuseColor],
//                                     begin: Alignment.topLeft,
//                                     end: Alignment.bottomRight,
//                                   ),
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 child: Icon(Icons.auto_awesome, color: Colors.white, size: 24),
//                               ),
//                               title: Text(
//                                 conversation.title,
//                                 style: TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 16,
//                                   color: primaryCoiffeuseColor.withOpacity(0.8),
//                                 ),
//                                 maxLines: 1,
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                               subtitle: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   SizedBox(height: 4),
//                                   Row(
//                                     children: [
//                                       Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
//                                       SizedBox(width: 4),
//                                       Text(
//                                         formattedDate,
//                                         style: TextStyle(
//                                           fontSize: 13,
//                                           color: Colors.grey[600],
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                   SizedBox(height: 2),
//                                   Row(
//                                     children: [
//                                       Icon(Icons.token, size: 14, color: accentCoiffeuseColor),
//                                       SizedBox(width: 4),
//                                       Text(
//                                         '${conversation.tokensUsed} tokens utilisés',
//                                         style: TextStyle(
//                                           fontSize: 12,
//                                           color: accentCoiffeuseColor,
//                                           fontWeight: FontWeight.w500,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ],
//                               ),
//                               trailing: Row(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   Container(
//                                     padding: EdgeInsets.all(8),
//                                     decoration: BoxDecoration(
//                                       color: primaryCoiffeuseColor.withOpacity(0.1),
//                                       borderRadius: BorderRadius.circular(8),
//                                     ),
//                                     child: Icon(
//                                       Icons.arrow_forward_ios,
//                                       size: 16,
//                                       color: primaryCoiffeuseColor,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               onTap: () => _openConversation(context, conversation.id),
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//
//       // ✅ Bouton flottant pour nouvelle conversation
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: () => _startNewConversation(context),
//         backgroundColor: primaryCoiffeuseColor,
//         foregroundColor: Colors.white,
//         icon: Icon(Icons.add_circle_outline),
//         label: Text('Nouvelle conversation'),
//         elevation: 6,
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
//     return Container(
//       padding: EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: primaryCoiffeuseColor.withOpacity(0.2),
//           width: 1,
//         ),
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: primaryCoiffeuseColor.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Icon(icon, color: primaryCoiffeuseColor, size: 20),
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
//                     color: primaryCoiffeuseColor,
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
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: Row(
//           children: [
//             Icon(Icons.help, color: primaryCoiffeuseColor),
//             SizedBox(width: 8),
//             Text('Aide - Assistant IA'),
//           ],
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Comment utiliser votre Assistant IA :',
//               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//             ),
//             SizedBox(height: 12),
//             _buildHelpItem('💬', 'Créez des conversations pour poser vos questions'),
//             _buildHelpItem('📊', 'Demandez des analyses de vos performances'),
//             _buildHelpItem('📅', 'Consultez vos statistiques de rendez-vous'),
//             _buildHelpItem('💡', 'Obtenez des conseils personnalisés'),
//             _buildHelpItem('🗑️', 'Glissez vers la gauche pour supprimer une conversation'),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: Text('Compris !', style: TextStyle(color: primaryCoiffeuseColor)),
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
//     final provider = Provider.of<CoiffeuseAIChatProvider>(context, listen: false);
//
//     try {
//       // Créer la nouvelle conversation
//       final newConversation = await provider.createNewConversation();
//
//       // Vérifier que la conversation a bien été créée
//       if (newConversation != null) {
//         // ✅ Attendre explicitement que le provider soit à jour
//         await Future.delayed(Duration(milliseconds: 100));
//
//         // ✅ Double vérification que activeConversation est définie
//         if (provider.activeConversation != null) {
//           if (kDebugMode) {
//             print("✅ Conversation active définie, navigation vers le chat");
//           }
//           _navigateToChatPage(context);
//         } else {
//           // ✅ Si activeConversation n'est pas définie, la définir manuellement
//           if (kDebugMode) {
//             print("⚠️ activeConversation non définie, définition manuelle");
//           }
//           provider.setActiveConversation(newConversation.id);
//
//           // Attendre que les messages soient chargés
//           await Future.delayed(Duration(milliseconds: 200));
//           _navigateToChatPage(context);
//         }
//       } else {
//         // Afficher une erreur si la création a échoué
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Erreur lors de la création de la conversation'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print("❌ Erreur dans _startNewConversation: $e");
//       }
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Erreur: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
//
//   void _openConversation(BuildContext context, int conversationId) {
//     final provider = Provider.of<CoiffeuseAIChatProvider>(context, listen: false);
//     provider.setActiveConversation(conversationId);
//     _navigateToChatPage(context);
//   }
//
//   void _navigateToChatPage(BuildContext context) {
//     // ✅ IMPORTANT: Capturer le provider AVANT la navigation, pas dans le builder
//     final chatProvider = Provider.of<CoiffeuseAIChatProvider>(context, listen: false);
//
//     if (kDebugMode) {
//       print("🚀 Navigation - Provider capturé: ${chatProvider.activeConversation?.id}");
//     }
//
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => ChangeNotifierProvider.value(
//           value: chatProvider, // ✅ Utiliser le provider capturé, pas un nouveau
//           child: CoiffeuseAiChatPage(currentUser: widget.currentUser),
//         ),
//       ),
//     );
//   }
// }
