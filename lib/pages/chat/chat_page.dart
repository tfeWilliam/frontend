////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                PAGE D'INTERFACE UTILISATEUR POUR LE CHAT INDIVIDUEL        //
//                                                                            //
//  Ce fichier définit l'écran `ChatPage`, où un utilisateur peut échanger des //
//  messages en temps réel avec un autre utilisateur (typiquement une         //
//  coiffeuse).                                                               //
//                                                                            //
//  Fonctionnalités Clés :                                                    //
//  - Affichage des messages en temps réel grâce à un `StreamBuilder` écoutant//
//    la Firebase Realtime Database.                                          //
//  - Envoi de nouveaux messages qui sont instantanément ajoutés à la base de //
//    données.                                                                //
//  - Mécanisme de récupération robuste pour les informations du destinataire, //
//    utilisant plusieurs stratégies d'API et la gestion du refresh de token. //
//  - Affichage d'informations de débogage en mode `kDebugMode` pour faciliter//
//    le développement.                                                       //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:hairbnb/models/current_user.dart';
import 'package:hairbnb/models/message.dart';
import 'package:hairbnb/services/my_drawer_service/my_drawer.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'package:hairbnb/widgets/custom_app_bar.dart';
import 'package:hairbnb/services/firebase_token/token_service.dart';


/// Widget principal de la page de chat entre deux utilisateurs.
class ChatPage extends StatefulWidget {
  /// L'utilisateur actuellement connecté qui utilise l'application.
  final CurrentUser currentUser;
  /// L'UUID de l'autre utilisateur avec qui la conversation a lieu.
  final String otherUserId;

  /// Constructeur de la page, nécessitant l'utilisateur actuel et l'ID de son interlocuteur.
  const ChatPage({super.key,
    required this.otherUserId,
    required this.currentUser,
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

/// Classe d'état pour `ChatPage`.
/// Gère la logique de récupération de données, l'envoi de messages et l'état de l'UI.
class _ChatPageState extends State<ChatPage> {
  //region Déclaration des variables d'état et contrôleurs
  /// Référence à la racine de la Firebase Realtime Database.
  final databaseRef = FirebaseDatabase.instance.ref();
  /// Contrôleur pour le champ de saisie de message.
  final TextEditingController _messageController = TextEditingController();
  /// Contrôleur pour faire défiler la liste des messages.
  final ScrollController _scrollController = ScrollController();
  /// Nœud de focus pour gérer le clavier.
  final FocusNode _focusNode = FocusNode();
  /// L'identifiant unique et prédictible de la conversation.
  late String chatId;
  /// Les informations de l'autre utilisateur dans la conversation.
  CurrentUser? otherUser;
  /// État de chargement pour le profil de l'autre utilisateur.
  bool isLoadingUser = true;
  /// Message d'erreur à afficher si la récupération échoue.
  String? errorMessage;
  /// Informations de débogage affichées en mode debug.
  String? debugInfo;
  /// URL de base pour les appels API.
  final String baseUrl = "https://www.hairbnb.site";
  //endregion

  @override
  void initState() {
    super.initState();
    // Crée un ID de chat unique et cohérent en triant les UUIDs des participants.
    // Cela garantit que le même ID de chat est utilisé quel que soit l'initiateur.
    chatId = widget.currentUser.uuid.compareTo(widget.otherUserId) < 0
        ? "${widget.currentUser.uuid}_${widget.otherUserId}"
        : "${widget.otherUserId}_${widget.currentUser.uuid}";
    _fetchOtherUser(); // Lance la récupération des informations du destinataire.
  }

  //region Logique de récupération de l'utilisateur
  /// Récupère les données de l'autre utilisateur via une série de stratégies d'API.
  Future<void> _fetchOtherUser() async {
    if (!mounted) return;
    setState(() { isLoadingUser = true; errorMessage = null; debugInfo = "Recherche utilisateur..."; });

    try {
      if (kDebugMode) print("Récupération des données pour l'utilisateur: ${widget.otherUserId}");

      final token = await TokenService.getAuthToken();
      if (token == null) {
        if (kDebugMode) print("Aucun token d'authentification disponible");
        setState(() { errorMessage = "Erreur d'authentification"; debugInfo = "Pas de token"; isLoadingUser = false; });
        return;
      }
      if (kDebugMode) print("Token récupéré (longueur: ${token.length})");

      // Essaye plusieurs stratégies pour récupérer les données.
      CurrentUser? user = await _tryUserEndpoints(token);
      user ??= await _tryCoiffeusesEndpoint();

      if (mounted) {
        setState(() {
          otherUser = user;
          isLoadingUser = false;
          if (user != null) {
            debugInfo = "Utilisateur trouvé: ${user.prenom} ${user.nom}";
            errorMessage = null;
          } else {
            errorMessage = "Utilisateur introuvable";
            debugInfo = "Aucune méthode n'a fonctionné";
          }
        });
        if (user != null && kDebugMode) if (kDebugMode) {
          print("Utilisateur récupéré: ${user.prenom} ${user.nom}");
        }
      }
    } catch (error) {
      if (kDebugMode) print("Erreur lors de la récupération de l'utilisateur: $error");
      if (mounted) setState(() { isLoadingUser = false; errorMessage = "Erreur de chargement"; debugInfo = "Erreur: $error"; });
    }
  }

  /// Tente de récupérer les données via une liste d'endpoints standards.
  Future<CurrentUser?> _tryUserEndpoints(String token) async {
    final endpoints = [
      '/api/get_user_by_uuid/${widget.otherUserId}/',
      '/api/get_current_user/${widget.otherUserId}/',
      '/api/user_profile/${widget.otherUserId}/',
    ];

    for (String endpoint in endpoints) {
      try {
        final url = '$baseUrl$endpoint';
        if (kDebugMode) print("🌐 Tentative endpoint: $url");

        final response = await http.get(Uri.parse(url), headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}).timeout(const Duration(seconds: 10));
        if (kDebugMode) print("📡 $endpoint - Status: ${response.statusCode}");

        if (response.statusCode == 200) {
          final data = json.decode(utf8.decode(response.bodyBytes));
          CurrentUser? user = _parseUserResponse(data);
          if (user != null) return user;
        }
        // Gère le cas où le token est expiré et tente de le rafraîchir.
        else if (response.statusCode == 401) {
          if (kDebugMode) print("Token expiré, tentative de refresh");
          final newToken = await TokenService.getAuthToken(forceRefresh: true);
          if (newToken != null) return await _retryWithNewToken(endpoint, newToken);
        }
      } catch (error) {
        if (kDebugMode) print("Erreur avec $endpoint: $error");
        continue; // Passe à l'endpoint suivant en cas d'erreur.
      }
    }
    return null;
  }

  /// Réessaie une requête avec un nouveau token après un refresh.
  Future<CurrentUser?> _retryWithNewToken(String endpoint, String token) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl$endpoint'), headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return _parseUserResponse(json.decode(utf8.decode(response.bodyBytes)));
    } catch (error) {
      if (kDebugMode) print("Erreur retry $endpoint: $error");
    }
    return null;
  }

  /// Tente de récupérer les données via l'endpoint spécialisé pour les coiffeuses.
  Future<CurrentUser?> _tryCoiffeusesEndpoint() async {
    try {
      if (kDebugMode) print("Tentative endpoint coiffeuses");
      final response = await http.post(
        Uri.parse('$baseUrl/api/get_coiffeuses_info/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"uuids": [widget.otherUserId]}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData["status"] == "success" && jsonData["coiffeuses"] is List) {
          for (var coiffeuseData in jsonData["coiffeuses"]) {
            if (coiffeuseData['uuid'] == widget.otherUserId) {
              // Transforme la structure "coiffeuse" en une structure "user" standard.
              final userData = {
                'idTblUser': coiffeuseData['idTblUser'] ?? 0, 'uuid': coiffeuseData['uuid'], 'nom': coiffeuseData['nom'] ?? '', 'prenom': coiffeuseData['prenom'] ?? '',
                'email': coiffeuseData['email'] ?? '', 'numero_telephone': coiffeuseData['numero_telephone'], 'date_naissance': coiffeuseData['date_naissance'],
                'is_active': coiffeuseData['is_active'] ?? true, 'photo_profil': coiffeuseData['photo_profil'], 'type': 'coiffeuse',
              };
              return CurrentUser.fromJson(userData);
            }
          }
        }
      }
    } catch (error) {
      if (kDebugMode) print("Erreur endpoint coiffeuses: $error");
    }
    return null;
  }

  /// Fonction utilitaire pour parser différentes structures JSON en `CurrentUser`.
  CurrentUser? _parseUserResponse(Map<String, dynamic> data) {
    try {
      if (data['user'] != null) return CurrentUser.fromJson(data['user']);
      if (data['data'] != null && data['success'] == true) return CurrentUser.fromJson(data['data']);
      if (data['uuid'] != null) return CurrentUser.fromJson(data);
    } catch (e) {
      if (kDebugMode) print("Erreur parsing utilisateur: $e");
    }
    return null;
  }

  /// Construit une URL absolue pour une photo de profil.
  String? _getPhotoUrl(String? photoProfil) {
    if (photoProfil == null || photoProfil.isEmpty) return null;
    if (photoProfil.startsWith('http')) return photoProfil;
    if (photoProfil.startsWith('/')) return baseUrl + photoProfil;
    return '$baseUrl/$photoProfil';
  }

  /// Force le rechargement des données de l'utilisateur (utilisé en debug).
  void _forceRefreshUser() async {
    setState(() { otherUser = null; });
    await _fetchOtherUser();
  }
  //endregion

  //region Logique de Messagerie
  /// Envoie un nouveau message à la Firebase Realtime Database.
  void sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    Message newMessage = Message(
      senderId: widget.currentUser.uuid,
      receiverId: widget.otherUserId,
      text: text.trim(),
      timestamp: DateTime.now(),
      isRead: false,
    );
    await databaseRef.child(chatId).child("messages").push().set(newMessage.toJson());
    _messageController.clear();
    Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
  }

  /// Fait défiler la liste des messages vers le bas.
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }
  //endregion

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      drawer: MyDrawer(currentUser: widget.currentUser),
      body: Column(
        children: [
          // En-tête affichant les informations de l'interlocuteur.
          _buildChatHeader(),
          // Corps principal affichant les messages en temps réel.
          Expanded(
            child: StreamBuilder(
              // Écoute les changements sur le noeud "messages" de la conversation actuelle.
              stream: databaseRef.child(chatId).child("messages").onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return const Center(child: Text("Erreur de chargement des messages."));

                if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                  final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                  List<Message> messages = data.entries.map((entry) => Message.fromJson(entry.value)).toList();
                  messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

                  // Fait défiler vers le bas après la construction de la liste.
                  Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      bool isSender = msg.senderId == widget.currentUser.uuid;
                      return _buildMessageBubble(msg, isSender);
                    },
                  );
                }
                return const Center(child: Text("Aucun message."));
              },
            ),
          ),
          // Zone de saisie du message.
          _buildInputArea(),
        ],
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 3, onTap: (index) {}),
    );
  }

  //region Méthodes de construction de l'UI
  /// Construit l'en-tête de la page de chat.
  Widget _buildChatHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      color: Colors.grey.shade200,
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: Colors.blueAccent, backgroundImage: _buildProfileImage(), radius: 25),
              const SizedBox(width: 10),
              Expanded(child: _buildUserInfo()),
              if (kDebugMode && errorMessage != null)
                IconButton(icon: const Icon(Icons.refresh, color: Colors.blue), onPressed: _forceRefreshUser, tooltip: "Recharger l'utilisateur"),
            ],
          ),
          // Affiche des informations de débogage si elles existent.
          if (kDebugMode && debugInfo != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: errorMessage != null ? Colors.red.shade50 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: errorMessage != null ? Colors.red.shade200 : Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(errorMessage != null ? Icons.error : Icons.info, size: 16, color: errorMessage != null ? Colors.red : Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(child: Text(debugInfo!, style: TextStyle(fontSize: 12, color: errorMessage != null ? Colors.red.shade700 : Colors.blue.shade700))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Construit une bulle de message individuelle.
  Widget _buildMessageBubble(Message msg, bool isSender) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Align(
        alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSender ? Colors.blueAccent : Colors.grey.shade300,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(10), topRight: const Radius.circular(10),
              bottomLeft: isSender ? const Radius.circular(10) : Radius.zero,
              bottomRight: isSender ? Radius.zero : const Radius.circular(10),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(msg.text, style: TextStyle(color: isSender ? Colors.white : Colors.black)),
              const SizedBox(height: 5),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(DateFormat('dd/MM/yyyy HH:mm').format(msg.timestamp.toLocal()), style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construit la zone de saisie de texte en bas de l'écran.
  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              onSubmitted: (text) => sendMessage(text),
              decoration: InputDecoration(
                hintText: "Écrire un message", filled: true, fillColor: Colors.grey.shade200,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 10),
          FloatingActionButton(onPressed: () => sendMessage(_messageController.text), mini: true, child: const Icon(Icons.send)),
        ],
      ),
    );
  }

  /// Construit le `ImageProvider` pour l'avatar de l'utilisateur.
  ImageProvider _buildProfileImage() {
    if (otherUser == null) return const AssetImage("assets/logo_login/avatar.png");

    final photoUrl = _getPhotoUrl(otherUser?.photoProfil);
    if (photoUrl != null) {
      try {
        final uri = Uri.parse(photoUrl);
        if (uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https')) return NetworkImage(photoUrl);
      } catch (e) {
        if (kDebugMode) print("Erreur URL photo: $e");
      }
    }
    return const AssetImage("assets/logo_login/avatar.png");
  }

  /// Construit le widget affichant les informations de l'utilisateur (nom, statut, erreur).
  Widget _buildUserInfo() {
    if (isLoadingUser) {
      return const Row(children: [SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)), SizedBox(width: 8), Text("Chargement...", style: TextStyle(fontSize: 14, color: Colors.grey))]);
    }

    if (otherUser != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("${otherUser!.prenom} ${otherUser!.nom}".trim(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (otherUser!.type == 'coiffeuse') Text("Coiffeuse", style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(errorMessage ?? "Utilisateur introuvable", style: const TextStyle(fontSize: 16, color: Colors.red)),
          Text("ID: ${widget.otherUserId.substring(0, 8)}...", style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      );
    }
  }
//endregion
}






// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:hairbnb/services/firebase_token/token_service.dart';
// import 'package:hairbnb/widgets/custom_app_bar.dart';
// import 'package:hairbnb/models/current_user.dart';
// import 'package:hairbnb/models/message.dart';
// import 'package:hairbnb/widgets/bottom_nav_bar.dart';
// import '../../services/my_drawer_service/my_drawer.dart';
// import 'package:intl/intl.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// class ChatPage extends StatefulWidget {
//   final CurrentUser currentUser;
//   final String otherUserId;
//
//   const ChatPage({super.key,
//     required this.otherUserId,
//     required this.currentUser,
//   });
//
//   @override
//   _ChatPageState createState() => _ChatPageState();
// }
//
// class _ChatPageState extends State<ChatPage> {
//   final databaseRef = FirebaseDatabase.instance.ref();
//   final TextEditingController _messageController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   final FocusNode _focusNode = FocusNode();
//   late String chatId;
//   CurrentUser? otherUser;
//   bool isLoadingUser = true;
//   String? errorMessage;
//   String? debugInfo;
//   final String baseUrl = "https://www.hairbnb.site";
//
//   @override
//   void initState() {
//     super.initState();
//     chatId = widget.currentUser.uuid.compareTo(widget.otherUserId) < 0
//         ? "${widget.currentUser.uuid}_${widget.otherUserId}"
//         : "${widget.otherUserId}_${widget.currentUser.uuid}";
//     _fetchOtherUser();
//   }
//
//   /// Récupération de l'autre utilisateur en utilisant TokenService
//   Future<void> _fetchOtherUser() async {
//     if (!mounted) return;
//
//     setState(() {
//       isLoadingUser = true;
//       errorMessage = null;
//       debugInfo = "🔍 Recherche utilisateur...";
//     });
//
//     try {
//       if (kDebugMode) {
//         print("🔍 Récupération des données pour l'utilisateur: ${widget.otherUserId}");
//       }
//
//       // Utiliser le TokenService pour récupérer le token
//       final token = await TokenService.getAuthToken();
//
//       if (token == null) {
//         if (kDebugMode) {
//           print("❌ Aucun token d'authentification disponible");
//         }
//         setState(() {
//           errorMessage = "Erreur d'authentification";
//           debugInfo = "❌ Pas de token";
//           isLoadingUser = false;
//         });
//         return;
//       }
//
//       if (kDebugMode) {
//         print("🔑 Token récupéré (longueur: ${token.length})");
//       }
//
//       // Essayer différents endpoints
//       CurrentUser? user = await _tryUserEndpoints(token);
//
//       user ??= await _tryCoiffeusesEndpoint();
//
//       if (mounted) {
//         setState(() {
//           otherUser = user;
//           isLoadingUser = false;
//           if (user != null) {
//             debugInfo = "✅ Utilisateur trouvé: ${user.prenom} ${user.nom}";
//             errorMessage = null;
//           } else {
//             errorMessage = "Utilisateur introuvable";
//             debugInfo = "❌ Aucune méthode n'a fonctionné";
//           }
//         });
//
//         if (user != null && kDebugMode) {
//           if (kDebugMode) {
//             print("✅ Utilisateur récupéré: ${user.prenom} ${user.nom}");
//           }
//           if (kDebugMode) {
//             print("📷 Photo profil: ${user.photoProfil}");
//           }
//         }
//       }
//     } catch (error) {
//       if (kDebugMode) {
//         print("❌ Erreur lors de la récupération de l'utilisateur: $error");
//       }
//       if (mounted) {
//         setState(() {
//           isLoadingUser = false;
//           errorMessage = "Erreur de chargement";
//           debugInfo = "❌ Erreur: $error";
//         });
//       }
//     }
//   }
//
//   /// Essayer les endpoints utilisateur avec le token
//   Future<CurrentUser?> _tryUserEndpoints(String token) async {
//     final endpoints = [
//       '/api/get_user_by_uuid/${widget.otherUserId}/',
//       '/api/get_current_user/${widget.otherUserId}/',
//       '/api/user_profile/${widget.otherUserId}/',
//     ];
//
//     for (String endpoint in endpoints) {
//       try {
//         final url = '$baseUrl$endpoint';
//         if (kDebugMode) {
//           print("🌐 Tentative endpoint: $url");
//         }
//
//         final response = await http.get(
//           Uri.parse(url),
//           headers: {
//             'Authorization': 'Bearer $token',
//             'Content-Type': 'application/json',
//           },
//         ).timeout(Duration(seconds: 10));
//
//         if (kDebugMode) {
//           print("📡 $endpoint - Status: ${response.statusCode}");
//         }
//
//         if (response.statusCode == 200) {
//           final decodedBody = utf8.decode(response.bodyBytes);
//           final data = json.decode(decodedBody);
//
//           // Essayer différentes structures de réponse
//           CurrentUser? user = _parseUserResponse(data);
//           if (user != null) {
//             if (kDebugMode) {
//               print("✅ Utilisateur trouvé via $endpoint");
//             }
//             return user;
//           }
//         } else if (response.statusCode == 401) {
//           if (kDebugMode) {
//             print("❌ Token expiré, tentative de refresh");
//           }
//           // Utiliser TokenService pour refresh
//           final newToken = await TokenService.getAuthToken(forceRefresh: true);
//           if (newToken != null) {
//             // Réessayer avec le nouveau token
//             return await _retryWithNewToken(endpoint, newToken);
//           }
//         }
//       } catch (error) {
//         if (kDebugMode) {
//           print("❌ Erreur avec $endpoint: $error");
//         }
//         continue;
//       }
//     }
//     return null;
//   }
//
//   /// Réessayer un endpoint avec un nouveau token
//   Future<CurrentUser?> _retryWithNewToken(String endpoint, String token) async {
//     try {
//       final url = '$baseUrl$endpoint';
//       final response = await http.get(
//         Uri.parse(url),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//       ).timeout(Duration(seconds: 10));
//
//       if (response.statusCode == 200) {
//         final decodedBody = utf8.decode(response.bodyBytes);
//         final data = json.decode(decodedBody);
//         return _parseUserResponse(data);
//       }
//     } catch (error) {
//       if (kDebugMode) {
//         print("❌ Erreur retry $endpoint: $error");
//       }
//     }
//     return null;
//   }
//
//   /// Essayer l'endpoint spécialisé pour les coiffeuses
//   Future<CurrentUser?> _tryCoiffeusesEndpoint() async {
//     try {
//       if (kDebugMode) {
//         print("🔄 Tentative endpoint coiffeuses");
//       }
//
//       final response = await http.post(
//         Uri.parse('$baseUrl/api/get_coiffeuses_info/'),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode({"uuids": [widget.otherUserId]}),
//       ).timeout(Duration(seconds: 10));
//
//       if (response.statusCode == 200) {
//         final jsonData = jsonDecode(response.body);
//         if (jsonData["status"] == "success" && jsonData["coiffeuses"] is List) {
//           for (var coiffeuseData in jsonData["coiffeuses"]) {
//             if (coiffeuseData['uuid'] == widget.otherUserId) {
//               // Convertir les données coiffeuse en CurrentUser
//               final userData = {
//                 'idTblUser': coiffeuseData['idTblUser'] ?? 0,
//                 'uuid': coiffeuseData['uuid'],
//                 'nom': coiffeuseData['nom'] ?? '',
//                 'prenom': coiffeuseData['prenom'] ?? '',
//                 'email': coiffeuseData['email'] ?? '',
//                 'numero_telephone': coiffeuseData['numero_telephone'],
//                 'date_naissance': coiffeuseData['date_naissance'],
//                 'is_active': coiffeuseData['is_active'] ?? true,
//                 'photo_profil': coiffeuseData['photo_profil'],
//                 'type': 'coiffeuse',
//               };
//
//               return CurrentUser.fromJson(userData);
//             }
//           }
//         }
//       }
//     } catch (error) {
//       if (kDebugMode) {
//         print("❌ Erreur endpoint coiffeuses: $error");
//       }
//     }
//     return null;
//   }
//
//   /// Parser la réponse utilisateur
//   CurrentUser? _parseUserResponse(Map<String, dynamic> data) {
//     try {
//       if (data['user'] != null) {
//         return CurrentUser.fromJson(data['user']);
//       } else if (data['data'] != null && data['success'] == true) {
//         return CurrentUser.fromJson(data['data']);
//       } else if (data['uuid'] != null) {
//         return CurrentUser.fromJson(data);
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print("❌ Erreur parsing utilisateur: $e");
//       }
//     }
//     return null;
//   }
//
//   /// Construire l'URL de la photo
//   String? _getPhotoUrl(String? photoProfil) {
//     if (photoProfil == null || photoProfil.isEmpty) {
//       return null;
//     }
//
//     if (photoProfil.startsWith('http://') || photoProfil.startsWith('https://')) {
//       return photoProfil;
//     }
//
//     if (photoProfil.startsWith('/')) {
//       return baseUrl.replaceAll(RegExp(r'/$'), '') + photoProfil;
//     }
//
//     return '${baseUrl.replaceAll(RegExp(r'/$'), '')}/$photoProfil';
//   }
//
//   /// Forcer le rechargement de l'utilisateur
//   void _forceRefreshUser() async {
//     setState(() {
//       otherUser = null;
//     });
//     await _fetchOtherUser();
//   }
//
//   /// Envoyer un message
//   void sendMessage(String text) async {
//     if (text.trim().isEmpty) return;
//
//     Message newMessage = Message(
//       senderId: widget.currentUser.uuid,
//       receiverId: widget.otherUserId,
//       text: text.trim(),
//       timestamp: DateTime.now(),
//       isRead: false,
//     );
//
//     await databaseRef.child(chatId).child("messages").push().set(newMessage.toJson());
//     _messageController.clear();
//
//     Future.delayed(Duration(milliseconds: 300), () {
//       _scrollToBottom();
//     });
//   }
//
//   void _scrollToBottom() {
//     if (_scrollController.hasClients) {
//       _scrollController.animateTo(
//         _scrollController.position.maxScrollExtent,
//         duration: Duration(milliseconds: 300),
//         curve: Curves.easeOut,
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: CustomAppBar(),
//       drawer: MyDrawer(currentUser: widget.currentUser),
//       body: Column(
//         children: [
//           Container(
//             width: double.infinity,
//             padding: EdgeInsets.all(10),
//             color: Colors.grey.shade200,
//             child: Column(
//               children: [
//                 Row(
//                   children: [
//                     CircleAvatar(
//                       backgroundColor: Colors.blueAccent,
//                       backgroundImage: _buildProfileImage(),
//                       radius: 25,
//                       onBackgroundImageError: (exception, stackTrace) {
//                         if (kDebugMode) {
//                           print("❌ Erreur de chargement d'image: $exception");
//                         }
//                       },
//                     ),
//                     SizedBox(width: 10),
//                     Expanded(child: _buildUserInfo()),
//                     if (kDebugMode && errorMessage != null)
//                       IconButton(
//                         icon: Icon(Icons.refresh, color: Colors.blue),
//                         onPressed: _forceRefreshUser,
//                         tooltip: "Recharger l'utilisateur",
//                       ),
//                   ],
//                 ),
//                 if (kDebugMode && debugInfo != null)
//                   Container(
//                     margin: EdgeInsets.only(top: 8),
//                     padding: EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: errorMessage != null ? Colors.red.shade50 : Colors.blue.shade50,
//                       borderRadius: BorderRadius.circular(4),
//                       border: Border.all(
//                           color: errorMessage != null ? Colors.red.shade200 : Colors.blue.shade200
//                       ),
//                     ),
//                     child: Row(
//                       children: [
//                         Icon(
//                           errorMessage != null ? Icons.error : Icons.info,
//                           size: 16,
//                           color: errorMessage != null ? Colors.red : Colors.blue,
//                         ),
//                         SizedBox(width: 8),
//                         Expanded(
//                           child: Text(
//                             debugInfo!,
//                             style: TextStyle(
//                               fontSize: 12,
//                               color: errorMessage != null ? Colors.red.shade700 : Colors.blue.shade700,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//               ],
//             ),
//           ),
//           Expanded(
//             child: StreamBuilder(
//               stream: databaseRef.child(chatId).child("messages").onValue,
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//
//                 if (snapshot.hasError) {
//                   return const Center(child: Text("Erreur de chargement des messages."));
//                 }
//
//                 if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
//                   final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
//                   List<Message> messages = data.entries.map((entry) {
//                     return Message.fromJson(entry.value);
//                   }).toList();
//
//                   messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
//
//                   Future.delayed(Duration(milliseconds: 300), () {
//                     _scrollToBottom();
//                   });
//
//                   return ListView.builder(
//                     controller: _scrollController,
//                     itemCount: messages.length,
//                     itemBuilder: (context, index) {
//                       final msg = messages[index];
//                       bool isSender = msg.senderId == widget.currentUser.uuid;
//
//                       return Padding(
//                         padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
//                         child: Align(
//                           alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
//                           child: Container(
//                             constraints: BoxConstraints(
//                               maxWidth: MediaQuery.of(context).size.width * 0.7,
//                             ),
//                             padding: const EdgeInsets.all(10),
//                             decoration: BoxDecoration(
//                               color: isSender ? Colors.blueAccent : Colors.grey.shade300,
//                               borderRadius: BorderRadius.only(
//                                 topLeft: const Radius.circular(10),
//                                 topRight: const Radius.circular(10),
//                                 bottomLeft: isSender ? const Radius.circular(10) : Radius.zero,
//                                 bottomRight: isSender ? Radius.zero : const Radius.circular(10),
//                               ),
//                             ),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   msg.text,
//                                   style: TextStyle(color: isSender ? Colors.white : Colors.black),
//                                 ),
//                                 const SizedBox(height: 5),
//                                 Align(
//                                   alignment: Alignment.bottomRight,
//                                   child: Text(
//                                     DateFormat('dd/MM/yyyy HH:mm').format(msg.timestamp.toUtc()),
//                                     style: const TextStyle(fontSize: 10, color: Colors.grey),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       );
//                     },
//                   );
//                 }
//                 return const Center(child: Text("Aucun message."));
//               },
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _messageController,
//                     focusNode: _focusNode,
//                     onSubmitted: (text) {
//                       sendMessage(text);
//                     },
//                     decoration: InputDecoration(
//                       hintText: "Écrire un message",
//                       filled: true,
//                       fillColor: Colors.grey.shade200,
//                       contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(20),
//                         borderSide: BorderSide.none,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 FloatingActionButton(
//                   onPressed: () {
//                     sendMessage(_messageController.text);
//                   },
//                   mini: true,
//                   child: const Icon(Icons.send),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//       bottomNavigationBar: BottomNavBar(
//         currentIndex: 3,
//         onTap: (index) {},
//       ),
//     );
//   }
//
//   /// Construire l'image de profil
//   ImageProvider _buildProfileImage() {
//     if (otherUser == null) {
//       return AssetImage("assets/logo_login/avatar.png") as ImageProvider;
//     }
//
//     final photoUrl = _getPhotoUrl(otherUser?.photoProfil);
//     if (photoUrl != null) {
//       try {
//         final uri = Uri.parse(photoUrl);
//         if (uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https')) {
//           return NetworkImage(photoUrl);
//         }
//       } catch (e) {
//         if (kDebugMode) {
//           print("❌ Erreur URL photo: $e");
//         }
//       }
//     }
//
//     return AssetImage("assets/logo_login/avatar.png") as ImageProvider;
//   }
//
//   /// Construire les informations utilisateur
//   Widget _buildUserInfo() {
//     if (isLoadingUser) {
//       return Row(
//         children: [
//           SizedBox(
//             width: 16,
//             height: 16,
//             child: CircularProgressIndicator(strokeWidth: 2),
//           ),
//           SizedBox(width: 8),
//           Text("Chargement...", style: TextStyle(fontSize: 14, color: Colors.grey)),
//         ],
//       );
//     }
//
//     if (otherUser != null) {
//       return Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             "${otherUser!.prenom} ${otherUser!.nom}".trim(),
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           if (otherUser!.type == 'coiffeuse')
//             Text(
//               "Coiffeuse",
//               style: TextStyle(fontSize: 14, color: Colors.grey[600]),
//             ),
//         ],
//       );
//     } else {
//       return Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             errorMessage ?? "Utilisateur introuvable",
//             style: TextStyle(fontSize: 16, color: Colors.red),
//           ),
//           Text(
//             "ID: ${widget.otherUserId.substring(0, 8)}...",
//             style: TextStyle(fontSize: 12, color: Colors.grey),
//           ),
//         ],
//       );
//     }
//   }
// }
