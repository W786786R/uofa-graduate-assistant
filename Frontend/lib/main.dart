import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uofa_graduate_assistant/logger.dart';
import 'screens/login_screen.dart';
import  'screens/conversation_list_screen.dart';

/*
This is the main method of the app.
It is used to setup the logger and run the app.
*/
void main() {
  setupLogger();
  runApp(const MyApp());
}

/*
This is the route observer of the app.
It is used to observe the routes of the app. To keep track of the screens the user is visiting.
*/
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
RouteObserver<PageRoute> getRouteObserver() => routeObserver;

/*
This is the main widget of the app.
It is load the first screen of the app based on the user's login status.
*/
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance(); //This will load the user's id from the shared preferences.
    return prefs.getString('user_id');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'U of A Graduate Application Assistant',
      navigatorObservers: [routeObserver],
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<String?>(
        future: getUserId(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 6, 63, 10))));
          } else if (snapshot.hasData && snapshot.data != null) {  //If the shared preferences have a user id, the user is redirected to the conversation list screen.
            return ConversationListScreen(userId: snapshot.data!);
          } else {
            return const LoginScreen(); //If the shared preferences do not have a user id, the user is redirected to the login screen.
          }
        },
      ),
    );
  }
}
