import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hairbnb/pages/ai_chat/providers/ai_chat_provider.dart';
import 'package:hairbnb/pages/ai_chat/services/ai_chat_service.dart';
import 'package:hairbnb/pages/ai_chat/services/coiffeuse_ai_chat_service.dart';
import 'package:hairbnb/pages/home_page.dart';
import 'package:hairbnb/services/providers/cart_provider.dart';
import 'package:hairbnb/services/providers/coiffeuse_ai_chat_provider.dart';
import 'package:hairbnb/services/providers/disponibilites_provider.dart';
import 'package:hairbnb/services/routes_services/route_service.dart';
import 'firebase_options.dart';
import 'package:hairbnb/pages/splash_screen.dart';
import 'package:provider/provider.dart';
import 'services/providers/current_user_provider.dart';



class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        authDomain: "hairbnb-7eeb9.firebaseapp.com",
        databaseURL: "https://hairbnb-7eeb9-default-rtdb.europe-west1.firebasedatabase.app",
        projectId: "hairbnb-7eeb9",
        storageBucket: "hairbnb-7eeb9.firebasestorage.app",
        messagingSenderId: "523426514457",
        appId: "1:523426514457:web:c12474ba6a3bed7ef08c88",
        measurementId: "G-E9GTDH2YCN"
      ),
    );
  } else {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );}

  HttpOverrides.global = MyHttpOverrides();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CurrentUserProvider()),
        ChangeNotifierProvider(create: (context) => CartProvider()),//
        ChangeNotifierProvider(create: (_) => DisponibilitesProvider()),
        ChangeNotifierProvider(create: (context) => AIChatProvider(AIChatService(
              baseUrl: 'https://www.hairbnb.site/api',
              token: '',
            ),
          ),
        ),
        ChangeNotifierProvider(create: (context) => CoiffeuseAIChatProvider(
          CoiffeuseAIChatService(
            baseUrl: 'https://www.hairbnb.site/api',
            token: '',
          ),
        ),
        ),
      ],
      //child: const AppRoot(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hairbnb app',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const SplashScreen(), // Utilisation de SplashScreen

      debugShowCheckedModeBanner: false,

      onGenerateRoute: (settings) {
        // Si c'est la route d'accueil
        if (settings.name == '/' || settings.name == null) {
          return MaterialPageRoute(
            builder: (context) => const HomePage(),
          );
        }

        // Sinon, utilisez le RouteService pour les autres routes
        return RouteService().generateRoute(settings);
      },
    );
  }

}
