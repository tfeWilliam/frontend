/// **************************************************************************************
///
/// PAGE UI : INTERFACE DE CHAT AVEC L'ASSISTANT IA
/// Fichier: lib/screens/ai_chat/chat_page.dart
///
/// OBJECTIF :
/// Ce fichier définit l'interface utilisateur principale pour une conversation en temps
/// réel entre un utilisateur et un assistant IA. Il gère l'affichage des messages,
/// la saisie de l'utilisateur et les différents états de la conversation.
///
/// ARCHITECTURE ET GESTION D'ÉTAT :
/// - Utilise un `StatefulWidget` pour gérer l'état local de l'UI (contrôleurs de
/// texte et de défilement).
/// - S'appuie fortement sur le `Consumer` du package `provider` pour écouter les
/// changements de `AIChatProvider` et reconstruire l'interface de manière réactive.
///
/// FONCTIONNALITÉS CLÉS :
/// - Affichage chronologique des messages, avec un style distinct pour l'utilisateur et l'IA.
/// - Gestion des états : conversation non active, conversation vide (avec un message
/// de bienvenue et des suggestions), chargement de la réponse de l'IA, et erreurs.
/// - Défilement automatique vers le bas lors de l'arrivée de nouveaux messages.
/// - Capacité à rendre du contenu HTML simple envoyé par l'IA via `flutter_widget_from_html`.
/// - Zone de saisie dynamique avec un bouton d'envoi qui s'active/se désactive.
///
///***************************************************************************************
library;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:hairbnb/pages/ai_chat/providers/ai_chat_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/ai_chat.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/bottom_nav_bar.dart';

/// Widget principal pour la page de chat avec l'IA.
class AiChatPage extends StatefulWidget {
  final dynamic currentUser;

  const AiChatPage({super.key, required this.currentUser});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<AiChatPage> {
  /// Contrôleur pour le champ de saisie de message.
  final TextEditingController _messageController = TextEditingController();
  /// Contrôleur pour faire défiler la liste des messages.
  final ScrollController _scrollController = ScrollController();
  /// Booléen pour suivre si l'utilisateur est en train d'écrire un message.
  bool _isComposing = false;

  @override
  void dispose() {
    // Libère les ressources des contrôleurs pour éviter les fuites de mémoire.
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Fait défiler la liste de messages vers le bas de manière fluide après un nouveau message.
  void _scrollToBottom() {
    // S'assure que le défilement se produit après que le frame a été rendu.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
                gradient: LinearGradient(
                  colors: [primaryColor, primaryColor.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.assistant, color: Colors.white, size: 40),
                  SizedBox(height: 16),
                  Text(
                    'Assistant Hairbnb',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Chat en cours...',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.arrow_back, color: primaryColor),
              title: Text('Retour aux conversations'),
              onTap: () {
                Navigator.pop(context); // Fermer le drawer
                Navigator.pop(context); // Retourner à la liste
              },
            ),
            ListTile(
              leading: Icon(Icons.refresh, color: primaryColor),
              title: Text('Nouvelle conversation'),
              onTap: () {
                Navigator.pop(context);
                _createNewConversation();
              },
            ),
            ListTile(
              leading: Icon(Icons.info, color: primaryColor),
              title: Text('Informations tokens'),
              onTap: () {
                Navigator.pop(context);
                _showTokensInfo(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.analytics, color: primaryColor),
              title: Text('Statistiques'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // En-tête de la page de chat
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
              boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 8, offset: Offset(0, 2))],
            ),
            child: Row(
              children: [
                Icon(Icons.assistant, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assistant Hairbnb',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Consumer<AIChatProvider>(
                        builder: (context, chatProvider, child) {
                          return Text(
                            chatProvider.activeConversation != null
                                ? 'Conversation active • ${chatProvider.activeConversation!.messages.length} messages'
                                : 'Aucune conversation',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                IconButton(icon: Icon(Icons.info_outline, color: Colors.white), onPressed: () => _showTokensInfo(context)),
              ],
            ),
          ),
          // Contenu principal du chat, géré par le Consumer
          Expanded(
            child: Consumer<AIChatProvider>(
              builder: (context, chatProvider, child) {
                // CAS 1: Aucune conversation n'est active.
                if (chatProvider.activeConversation == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 80, color: primaryColor.withOpacity(0.5)),
                        SizedBox(height: 16),
                        Text('Aucune conversation active', style: TextStyle(fontSize: 18, color: primaryColor, fontWeight: FontWeight.w500)),
                        SizedBox(height: 20),
                        ElevatedButton.icon(
                          icon: Icon(Icons.add_circle_outline),
                          label: Text('Créer une conversation'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          ),
                          onPressed: () => _createNewConversation(),
                        ),
                      ],
                    ),
                  );
                }

                // S'assure de faire défiler vers le bas quand la liste est mise à jour.
                _scrollToBottom();

                // CAS 2: Une conversation est active.
                return Column(
                  children: [
                    // Affiche un indicateur de progression linéaire pendant que l'IA répond.
                    if (chatProvider.isLoading)
                      SizedBox(height: 4, child: LinearProgressIndicator(backgroundColor: primaryColor.withOpacity(0.2), valueColor: AlwaysStoppedAnimation<Color>(primaryColor))),
                    // Zone d'affichage des messages.
                    Expanded(
                      child: chatProvider.activeConversation!.messages.isEmpty
                          ? _buildWelcomeMessage(context)
                          : _buildMessagesList(context, chatProvider.activeConversation!.messages),
                    ),
                    // Affiche la bannière d'erreur si une erreur est survenue.
                    if (chatProvider.error != null)
                      Container(
                        decoration: BoxDecoration(color: Colors.red.shade50, border: Border(top: BorderSide(color: Colors.red.shade200, width: 1))),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                            const SizedBox(width: 12),
                            Expanded(child: Text('Erreur: ${chatProvider.error}', style: TextStyle(color: Colors.red.shade700, fontSize: 14))),
                            IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => chatProvider.clearError(), color: Colors.red.shade700),
                          ],
                        ),
                      ),
                    // Affiche le compteur de tokens pour la conversation en cours.
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(color: Colors.grey.shade100, border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.token, size: 16, color: primaryColor),
                              const SizedBox(width: 6),
                              Text('Tokens utilisés: ${chatProvider.activeConversation!.tokensUsed}', style: TextStyle(fontSize: 13, color: primaryColor, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          TextButton.icon(
                            icon: Icon(Icons.help_outline, size: 16),
                            label: Text('Aide'),
                            style: TextButton.styleFrom(foregroundColor: primaryColor, padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                            onPressed: () => _showTokensInfo(context),
                          ),
                        ],
                      ),
                    ),
                    // Construit la zone de saisie en bas de l'écran.
                    _buildInputArea(context),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 4,
        onTap: (index) {},
      ),
    );
  }

  /// Logique pour démarrer une nouvelle conversation (à implémenter via le provider).
  void _createNewConversation() async {
    // La logique spécifique (ex: appeler provider.createNewConversation()) doit être implémentée ici.
  }

  /// Construit l'écran d'accueil affiché lorsqu'une conversation est vide, avec des suggestions.
  Widget _buildWelcomeMessage(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [primaryColor.withOpacity(0.1), primaryColor.withOpacity(0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(Icons.assistant, size: 80, color: primaryColor),
          ),
          const SizedBox(height: 24),
          Text('Bienvenue sur l\'assistant Hairbnb', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text('Je peux vous aider avec les statistiques de votre application, les réservations, les coiffeuses, les salons et bien plus encore.', style: TextStyle(fontSize: 16, color: Colors.grey.shade700, height: 1.4), textAlign: TextAlign.center),
          const SizedBox(height: 32),
          Text('Exemples de questions :', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
          const SizedBox(height: 16),
          _buildExampleQuestion(context, 'Combien de rendez-vous ai-je ce mois-ci ?'),
          _buildExampleQuestion(context, 'Quels sont mes services les plus populaires ?'),
          _buildExampleQuestion(context, 'Quelles sont mes coiffeuses les plus demandées ?'),
          _buildExampleQuestion(context, 'Quel est mon chiffre d\'affaires cette semaine ?'),
          _buildExampleQuestion(context, 'Comment puis-je améliorer mon salon ?'),
          SizedBox(height: 24),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.withOpacity(0.3))),
            child: Row(
              children: [
                Icon(Icons.tips_and_updates, color: Colors.orange),
                SizedBox(width: 12),
                Expanded(child: Text('Astuce: Posez des questions précises pour obtenir des réponses personnalisées !', style: TextStyle(fontSize: 14, color: Colors.orange.withOpacity(0.8), fontStyle: FontStyle.italic))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construit un widget cliquable pour une question d'exemple qui remplit le champ de saisie.
  Widget _buildExampleQuestion(BuildContext context, String question) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _messageController.text = question;
            setState(() {
              _isComposing = true;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.white, Theme.of(context).primaryColor.withOpacity(0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2)),
              boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.1), blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.chat, color: Theme.of(context).primaryColor, size: 18),
                ),
                SizedBox(width: 12),
                Expanded(child: Text(question, style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w500, fontSize: 14))),
                Icon(Icons.arrow_forward_ios, color: Theme.of(context).primaryColor.withOpacity(0.5), size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Construit la liste déroulante des messages de la conversation.
  Widget _buildMessagesList(BuildContext context, List<AIMessage> messages) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _buildMessageBubble(context, message);
      },
    );
  }

  /// Construit une bulle de message unique, avec un style différent pour l'utilisateur et l'IA.
  Widget _buildMessageBubble(BuildContext context, AIMessage message) {
    final isUser = message.isUser;
    final dateFormat = DateFormat('HH:mm');
    final time = dateFormat.format(message.timestamp);
    final Color primaryColor = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              margin: EdgeInsets.only(right: 12),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [primaryColor, primaryColor.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.assistant, color: Colors.white, size: 16),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser
                    ? LinearGradient(colors: [primaryColor, primaryColor.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight)
                    : LinearGradient(colors: [Colors.white, Colors.grey.shade50], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: isUser ? primaryColor.withOpacity(0.3) : Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  isUser ? Text(message.content, style: TextStyle(color: Colors.white, fontSize: 15, height: 1.4)) : _buildMessageContent(message.content),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(time, style: TextStyle(fontSize: 11, color: isUser ? Colors.white.withOpacity(0.8) : Colors.grey.shade600)),
                      if (message.tokensIn > 0 || message.tokensOut > 0) ...[
                        Text(' • ${isUser ? message.tokensIn : message.tokensOut} tokens', style: TextStyle(fontSize: 11, color: isUser ? Colors.white.withOpacity(0.8) : Colors.grey.shade600)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isUser)
            Container(
              margin: EdgeInsets.only(left: 12),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.person, color: primaryColor, size: 16),
            ),
        ],
      ),
    );
  }

  /// Analyse le contenu du message et le rend en tant que HTML si nécessaire, sinon en tant que texte simple.
  Widget _buildMessageContent(String content) {
    bool containsHtml = content.contains('<') && content.contains('>');
    if (containsHtml) {
      return HtmlWidget(content, textStyle: TextStyle(color: Colors.black87, fontSize: 15, height: 1.4));
    }
    return Text(content, style: TextStyle(color: Colors.black87, fontSize: 15, height: 1.4));
  }

  /// Construit la zone de saisie de texte en bas de l'écran, avec le bouton d'envoi.
  Widget _buildInputArea(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.1), blurRadius: 10, spreadRadius: 1, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(25), border: Border.all(color: primaryColor.withOpacity(0.2))),
              child: TextField(
                controller: _messageController,
                onChanged: (text) {
                  setState(() {
                    _isComposing = text.trim().isNotEmpty;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Posez une question...',
                  hintStyle: TextStyle(color: primaryColor.withOpacity(0.6)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: _isComposing ? (_) => _sendMessage(context) : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Consumer<AIChatProvider>(
            builder: (context, chatProvider, child) {
              final isLoading = chatProvider.isLoading;
              return Container(
                decoration: BoxDecoration(
                  gradient: _isComposing && !isLoading
                      ? LinearGradient(colors: [primaryColor, primaryColor.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight)
                      : LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade500]),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(25),
                    onTap: _isComposing && !isLoading ? () => _sendMessage(context) : null,
                    child: Container(
                      padding: EdgeInsets.all(12),
                      child: isLoading
                          ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Gère l'envoi du message via le provider et réinitialise le champ de saisie.
  void _sendMessage(BuildContext context) {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      final provider = Provider.of<AIChatProvider>(context, listen: false);
      provider.sendMessage(text);
      _messageController.clear();
      setState(() {
        _isComposing = false;
      });
    }
  }

  /// Affiche une boîte de dialogue informative sur l'utilisation des tokens.
  void _showTokensInfo(BuildContext context) {
    final provider = Provider.of<AIChatProvider>(context, listen: false);
    final tokensUsed = provider.activeConversation?.tokensUsed ?? 0;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [Icon(Icons.info, color: Theme.of(context).primaryColor), SizedBox(width: 8), Text('Information sur les tokens')]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Icon(Icons.token, color: Theme.of(context).primaryColor, size: 20),
                  SizedBox(width: 8),
                  Text('Tokens utilisés: $tokensUsed', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text('Les tokens sont des unités de texte utilisées par l\'IA. Plus vous échangez de messages, plus vous utilisez de tokens.', style: TextStyle(fontSize: 14)),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('💡 Conseil: Pour économiser des tokens, posez des questions précises et concises.', style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.orange.withOpacity(0.8))),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Compris !', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}







// // lib/screens/ai_chat/chat_page.dart
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
// import 'package:hairbnb/pages/ai_chat/providers/ai_chat_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';
//
// import '../../models/ai_chat.dart';
// import '../../widgets/custom_app_bar.dart';
// import '../../widgets/bottom_nav_bar.dart';
//
// class AiChatPage extends StatefulWidget {
//   final dynamic currentUser;
//
//   const AiChatPage({super.key, required this.currentUser});
//
//   @override
//   _ChatPageState createState() => _ChatPageState();
// }
//
// class _ChatPageState extends State<AiChatPage> {
//   final TextEditingController _messageController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   bool _isComposing = false;
//
//   @override
//   void dispose() {
//     _messageController.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }
//
//   void _scrollToBottom() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (_scrollController.hasClients) {
//         _scrollController.animateTo(
//           _scrollController.position.maxScrollExtent,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     });
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
//                     'Chat en cours...',
//                     style: TextStyle(
//                       color: Colors.white70,
//                       fontSize: 14,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             ListTile(
//               leading: Icon(Icons.arrow_back, color: primaryColor),
//               title: Text('Retour aux conversations'),
//               onTap: () {
//                 Navigator.pop(context); // Fermer le drawer
//                 Navigator.pop(context); // Retourner à la liste
//               },
//             ),
//             ListTile(
//               leading: Icon(Icons.refresh, color: primaryColor),
//               title: Text('Nouvelle conversation'),
//               onTap: () {
//                 Navigator.pop(context);
//                 _createNewConversation();
//               },
//             ),
//             ListTile(
//               leading: Icon(Icons.info, color: primaryColor),
//               title: Text('Informations tokens'),
//               onTap: () {
//                 Navigator.pop(context);
//                 _showTokensInfo(context);
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
//           ],
//         ),
//       ),
//
//       body: Column(
//         children: [
//           // ✅ Header spécialisé pour l'assistant Hairbnb
//           Container(
//             width: double.infinity,
//             padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [primaryColor, primaryColor.withOpacity(0.8)],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               borderRadius: BorderRadius.only(
//                 bottomLeft: Radius.circular(20),
//                 bottomRight: Radius.circular(20),
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: primaryColor.withOpacity(0.3),
//                   blurRadius: 8,
//                   offset: Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: Row(
//               children: [
//                 Icon(Icons.assistant, color: Colors.white, size: 24),
//                 SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Assistant Hairbnb',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       Consumer<AIChatProvider>(
//                         builder: (context, chatProvider, child) {
//                           return Text(
//                             chatProvider.activeConversation != null
//                                 ? 'Conversation active • ${chatProvider.activeConversation!.messages.length} messages'
//                                 : 'Aucune conversation',
//                             style: TextStyle(
//                               color: Colors.white70,
//                               fontSize: 12,
//                             ),
//                           );
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//                 IconButton(
//                   icon: Icon(Icons.info_outline, color: Colors.white),
//                   onPressed: () => _showTokensInfo(context),
//                 ),
//               ],
//             ),
//           ),
//
//           // ✅ Contenu principal du chat
//           Expanded(
//             child: Consumer<AIChatProvider>(
//               builder: (context, chatProvider, child) {
//                 if (chatProvider.activeConversation == null) {
//                   return Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(
//                           Icons.chat_bubble_outline,
//                           size: 80,
//                           color: primaryColor.withOpacity(0.5),
//                         ),
//                         SizedBox(height: 16),
//                         Text(
//                           'Aucune conversation active',
//                           style: TextStyle(
//                             fontSize: 18,
//                             color: primaryColor,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                         SizedBox(height: 20),
//                         ElevatedButton.icon(
//                           icon: Icon(Icons.add_circle_outline),
//                           label: Text('Créer une conversation'),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: primaryColor,
//                             foregroundColor: Colors.white,
//                             padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(25),
//                             ),
//                           ),
//                           onPressed: () => _createNewConversation(),
//                         ),
//                       ],
//                     ),
//                   );
//                 }
//
//                 // Faire défiler vers le bas à chaque mise à jour des messages
//                 _scrollToBottom();
//
//                 return Column(
//                   children: [
//                     // Indicateur de chargement
//                     if (chatProvider.isLoading)
//                       SizedBox(
//                         height: 4,
//                         child: LinearProgressIndicator(
//                           backgroundColor: primaryColor.withOpacity(0.2),
//                           valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
//                         ),
//                       ),
//
//                     // Zone de messages
//                     Expanded(
//                       child: chatProvider.activeConversation!.messages.isEmpty
//                           ? _buildWelcomeMessage(context)
//                           : _buildMessagesList(context, chatProvider.activeConversation!.messages),
//                     ),
//
//                     // Barre d'erreur (visible seulement en cas d'erreur)
//                     if (chatProvider.error != null)
//                       Container(
//                         decoration: BoxDecoration(
//                           color: Colors.red.shade50,
//                           border: Border(
//                             top: BorderSide(color: Colors.red.shade200, width: 1),
//                           ),
//                         ),
//                         padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//                         child: Row(
//                           children: [
//                             Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
//                             const SizedBox(width: 12),
//                             Expanded(
//                               child: Text(
//                                 'Erreur: ${chatProvider.error}',
//                                 style: TextStyle(color: Colors.red.shade700, fontSize: 14),
//                               ),
//                             ),
//                             IconButton(
//                               icon: const Icon(Icons.close, size: 20),
//                               onPressed: () => chatProvider.clearError(),
//                               color: Colors.red.shade700,
//                             ),
//                           ],
//                         ),
//                       ),
//
//                     // Compteur de tokens
//                     Container(
//                       padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//                       decoration: BoxDecoration(
//                         color: Colors.grey.shade100,
//                         border: Border(
//                           top: BorderSide(color: Colors.grey.shade300, width: 1),
//                         ),
//                       ),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Row(
//                             children: [
//                               Icon(Icons.token, size: 16, color: primaryColor),
//                               const SizedBox(width: 6),
//                               Text(
//                                 'Tokens utilisés: ${chatProvider.activeConversation!.tokensUsed}',
//                                 style: TextStyle(
//                                   fontSize: 13,
//                                   color: primaryColor,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ],
//                           ),
//                           TextButton.icon(
//                             icon: Icon(Icons.help_outline, size: 16),
//                             label: Text('Aide'),
//                             style: TextButton.styleFrom(
//                               foregroundColor: primaryColor,
//                               padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                             ),
//                             onPressed: () => _showTokensInfo(context),
//                           ),
//                         ],
//                       ),
//                     ),
//
//                     // Zone de saisie
//                     _buildInputArea(context),
//                   ],
//                 );
//               },
//             ),
//           ),
//         ],
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
//   // ✅ Méthode pour créer une nouvelle conversation
//   void _createNewConversation() async {
//     final provider = Provider.of<AIChatProvider>(context, listen: false);
//     if (kDebugMode) {
//       if (kDebugMode) {
//         if (kDebugMode) {
//           if (kDebugMode) {
//             print("🚀 Création manuelle d'une nouvelle conversation");
//           }
//         }
//       }
//     }
//     // Vous pouvez implémenter la logique de création ici selon votre provider
//   }
//
//   Widget _buildWelcomeMessage(BuildContext context) {
//     final Color primaryColor = Theme.of(context).primaryColor;
//
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(24.0),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             padding: EdgeInsets.all(32),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [primaryColor.withOpacity(0.1), primaryColor.withOpacity(0.05)],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               borderRadius: BorderRadius.circular(30),
//             ),
//             child: Icon(
//               Icons.assistant,
//               size: 80,
//               color: primaryColor,
//             ),
//           ),
//           const SizedBox(height: 24),
//           Text(
//             '🤖 Bienvenue sur l\'assistant Hairbnb',
//             style: TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: primaryColor,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'Je peux vous aider avec les statistiques de votre application, les réservations, les coiffeuses, les salons et bien plus encore.',
//             style: TextStyle(
//               fontSize: 16,
//               color: Colors.grey.shade700,
//               height: 1.4,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 32),
//           Text(
//             '💡 Exemples de questions :',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: primaryColor,
//             ),
//           ),
//           const SizedBox(height: 16),
//           _buildExampleQuestion(context, '📊 Combien de rendez-vous ai-je ce mois-ci ?'),
//           _buildExampleQuestion(context, '⭐ Quels sont mes services les plus populaires ?'),
//           _buildExampleQuestion(context, '👩‍💼 Quelles sont mes coiffeuses les plus demandées ?'),
//           _buildExampleQuestion(context, '💰 Quel est mon chiffre d\'affaires cette semaine ?'),
//           _buildExampleQuestion(context, '📈 Comment puis-je améliorer mon salon ?'),
//           SizedBox(height: 24),
//           Container(
//             padding: EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.orange.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: Colors.orange.withOpacity(0.3)),
//             ),
//             child: Row(
//               children: [
//                 Icon(Icons.tips_and_updates, color: Colors.orange),
//                 SizedBox(width: 12),
//                 Expanded(
//                   child: Text(
//                     'Astuce: Posez des questions précises pour obtenir des réponses personnalisées !',
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Colors.orange.withOpacity(0.8),
//                       fontStyle: FontStyle.italic,
//                     ),
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
//   Widget _buildExampleQuestion(BuildContext context, String question) {
//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 6),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(16),
//           onTap: () {
//             _messageController.text = question;
//             setState(() {
//               _isComposing = true;
//             });
//           },
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Colors.white, Theme.of(context).primaryColor.withOpacity(0.05)],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               borderRadius: BorderRadius.circular(16),
//               border: Border.all(
//                 color: Theme.of(context).primaryColor.withOpacity(0.2),
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: Theme.of(context).primaryColor.withOpacity(0.1),
//                   blurRadius: 4,
//                   offset: Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: Row(
//               children: [
//                 Container(
//                   padding: EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: Theme.of(context).primaryColor.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Icon(Icons.chat, color: Theme.of(context).primaryColor, size: 18),
//                 ),
//                 SizedBox(width: 12),
//                 Expanded(
//                   child: Text(
//                     question,
//                     style: TextStyle(
//                       color: Theme.of(context).primaryColor,
//                       fontWeight: FontWeight.w500,
//                       fontSize: 14,
//                     ),
//                   ),
//                 ),
//                 Icon(
//                   Icons.arrow_forward_ios,
//                   color: Theme.of(context).primaryColor.withOpacity(0.5),
//                   size: 14,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildMessagesList(BuildContext context, List<AIMessage> messages) {
//     return ListView.builder(
//       controller: _scrollController,
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//       itemCount: messages.length,
//       itemBuilder: (context, index) {
//         final message = messages[index];
//         return _buildMessageBubble(context, message);
//       },
//     );
//   }
//
//   Widget _buildMessageBubble(BuildContext context, AIMessage message) {
//     final isUser = message.isUser;
//     final dateFormat = DateFormat('HH:mm');
//     final time = dateFormat.format(message.timestamp);
//     final Color primaryColor = Theme.of(context).primaryColor;
//
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6),
//       child: Row(
//         mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           if (!isUser)
//             Container(
//               margin: EdgeInsets.only(right: 12),
//               padding: EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [primaryColor, primaryColor.withOpacity(0.8)],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Icon(Icons.assistant, color: Colors.white, size: 16),
//             ),
//
//           Flexible(
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//               decoration: BoxDecoration(
//                 gradient: isUser
//                     ? LinearGradient(
//                   colors: [primaryColor, primaryColor.withOpacity(0.8)],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 )
//                     : LinearGradient(
//                   colors: [Colors.white, Colors.grey.shade50],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//                 borderRadius: BorderRadius.circular(20),
//                 boxShadow: [
//                   BoxShadow(
//                     color: isUser
//                         ? primaryColor.withOpacity(0.3)
//                         : Colors.black.withOpacity(0.1),
//                     blurRadius: 6,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//                 children: [
//                   isUser
//                       ? Text(
//                     message.content,
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 15,
//                       height: 1.4,
//                     ),
//                   )
//                       : _buildMessageContent(message.content),
//                   const SizedBox(height: 6),
//                   Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Text(
//                         time,
//                         style: TextStyle(
//                           fontSize: 11,
//                           color: isUser
//                               ? Colors.white.withOpacity(0.8)
//                               : Colors.grey.shade600,
//                         ),
//                       ),
//                       if (message.tokensIn > 0 || message.tokensOut > 0) ...[
//                         Text(
//                           ' • ${isUser ? message.tokensIn : message.tokensOut} tokens',
//                           style: TextStyle(
//                             fontSize: 11,
//                             color: isUser
//                                 ? Colors.white.withOpacity(0.8)
//                                 : Colors.grey.shade600,
//                           ),
//                         ),
//                       ],
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//
//           if (isUser)
//             Container(
//               margin: EdgeInsets.only(left: 12),
//               padding: EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade200,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Icon(Icons.person, color: primaryColor, size: 16),
//             ),
//         ],
//       ),
//     );
//   }
//
//   // Nouvelle méthode pour gérer le contenu des messages
//   Widget _buildMessageContent(String content) {
//     bool containsHtml = content.contains('<') && content.contains('>');
//
//     if (containsHtml) {
//       return HtmlWidget(
//         content,
//         textStyle: TextStyle(
//           color: Colors.black87,
//           fontSize: 15,
//           height: 1.4,
//         ),
//       );
//     }
//
//     return Text(
//       content,
//       style: TextStyle(
//         color: Colors.black87,
//         fontSize: 15,
//         height: 1.4,
//       ),
//     );
//   }
//
//   Widget _buildInputArea(BuildContext context) {
//     final Color primaryColor = Theme.of(context).primaryColor;
//
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: primaryColor.withOpacity(0.1),
//             blurRadius: 10,
//             spreadRadius: 1,
//             offset: const Offset(0, -2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade100,
//                 borderRadius: BorderRadius.circular(25),
//                 border: Border.all(
//                   color: primaryColor.withOpacity(0.2),
//                 ),
//               ),
//               child: TextField(
//                 controller: _messageController,
//                 onChanged: (text) {
//                   setState(() {
//                     _isComposing = text.trim().isNotEmpty;
//                   });
//                 },
//                 decoration: InputDecoration(
//                   hintText: 'Posez une question...',
//                   hintStyle: TextStyle(color: primaryColor.withOpacity(0.6)),
//                   border: InputBorder.none,
//                   contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                 ),
//                 textCapitalization: TextCapitalization.sentences,
//                 keyboardType: TextInputType.multiline,
//                 maxLines: null,
//                 textInputAction: TextInputAction.send,
//                 onSubmitted: _isComposing ? (_) => _sendMessage(context) : null,
//               ),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Consumer<AIChatProvider>(
//             builder: (context, chatProvider, child) {
//               final isLoading = chatProvider.isLoading;
//
//               return Container(
//                 decoration: BoxDecoration(
//                   gradient: _isComposing && !isLoading
//                       ? LinearGradient(
//                     colors: [primaryColor, primaryColor.withOpacity(0.8)],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   )
//                       : LinearGradient(
//                     colors: [Colors.grey.shade400, Colors.grey.shade500],
//                   ),
//                   borderRadius: BorderRadius.circular(25),
//                 ),
//                 child: Material(
//                   color: Colors.transparent,
//                   child: InkWell(
//                     borderRadius: BorderRadius.circular(25),
//                     onTap: _isComposing && !isLoading ? () => _sendMessage(context) : null,
//                     child: Container(
//                       padding: EdgeInsets.all(12),
//                       child: isLoading
//                           ? SizedBox(
//                         width: 20,
//                         height: 20,
//                         child: CircularProgressIndicator(
//                           color: Colors.white,
//                           strokeWidth: 2,
//                         ),
//                       )
//                           : Icon(
//                         Icons.send,
//                         color: Colors.white,
//                         size: 20,
//                       ),
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _sendMessage(BuildContext context) {
//     final text = _messageController.text.trim();
//     if (text.isNotEmpty) {
//       final provider = Provider.of<AIChatProvider>(context, listen: false);
//       provider.sendMessage(text);
//       _messageController.clear();
//       setState(() {
//         _isComposing = false;
//       });
//     }
//   }
//
//   void _showTokensInfo(BuildContext context) {
//     final provider = Provider.of<AIChatProvider>(context, listen: false);
//     final tokensUsed = provider.activeConversation?.tokensUsed ?? 0;
//
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: Row(
//           children: [
//             Icon(Icons.info, color: Theme.of(context).primaryColor),
//             SizedBox(width: 8),
//             Text('Information sur les tokens'),
//           ],
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Container(
//               padding: EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Theme.of(context).primaryColor.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Row(
//                 children: [
//                   Icon(Icons.token, color: Theme.of(context).primaryColor, size: 20),
//                   SizedBox(width: 8),
//                   Text(
//                     'Tokens utilisés: $tokensUsed',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color: Theme.of(context).primaryColor,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: 16),
//             Text(
//               'Les tokens sont des unités de texte utilisées par l\'IA. Plus vous échangez de messages, plus vous utilisez de tokens.',
//               style: TextStyle(fontSize: 14),
//             ),
//             SizedBox(height: 12),
//             Container(
//               padding: EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.orange.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Text(
//                 '💡 Conseil: Pour économiser des tokens, posez des questions précises et concises.',
//                 style: TextStyle(
//                   fontSize: 14,
//                   fontStyle: FontStyle.italic,
//                   color: Colors.orange.withOpacity(0.8),
//                 ),
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: Text(
//               'Compris !',
//               style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
