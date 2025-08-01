import 'package:flutter/material.dart';
import 'search.dart';
import 'tool_bar.dart';
import 'navigate.dart';
import 'admin.dart';
import 'details.dart';
import 'app.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SitesProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomePage(),
      routes: {
        '/SearchPage': (context) => const SearchPage(),
        '/Navigate':(context) =>const Navigate(),
        '/login': (context) => const LoginScreen(), 
        '/admin': (context) => const AdminScreen(),
        
        
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
  title: 'Home',
  actions: [
    TextButton(
      onPressed: () {
        Navigator.pushNamed(context, '/search');
      },
      child: const Text('Search', style: TextStyle(color: Colors.white)),
    ),
    TextButton(
      onPressed: () {
        Navigator.pushNamed(context, '/Navigate');
      },
      child: const Text('Navigate', style: TextStyle(color: Colors.white)),
    ),
  ],
),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/SearchPage');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF9A01B),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text('Search',style:TextStyle(fontSize:28,),),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/Navigate');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C8F4),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text('Navigate', style:TextStyle(fontSize:28,),
                ),
              ),
            ),
            const SizedBox(height: 20),
               SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C8F4),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text('admin', style:TextStyle(fontSize:28,),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

