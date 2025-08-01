/*import 'package:flutter/material.dart';
import 'search.dart';
import 'tool_bar.dart';
import 'navigate.dart';
import 'admin.dart';
import 'details.dart';


void main()  {

  runApp(const MyApp());
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
        //'/AdminScreen':(context) =>const AdminScreen(),
        
        
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
                  Navigator.pushNamed(context, '/AdminScreen');
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
}*/
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'search.dart';
import 'tool_bar.dart';
import 'navigate.dart';
import 'admin.dart';
import 'details.dart';
import 'prenavigate.dart';

// Import your providers and auth classes here:
import 'app.dart'; // Assuming AuthProvider, SitesProvider are here

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomePage(),
      routes: {
        '/SearchPage': (context) => const SearchPage(),
        '/Prenavigate': (context) => const PreNavigatePage(),
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
              Navigator.pushNamed(context, '/SearchPage');
            },
            child: const Text('Search', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/Prenavigate');
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
                child: const Text('Search', style: TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/Prenavigate');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C8F4),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text('Navigate', style: TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AdminAppWrapper(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C8F4),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text('Admin', style: TextStyle(fontSize: 28)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// This widget wraps the admin flow with providers/auth and routing
class AdminAppWrapper extends StatelessWidget {
  const AdminAppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SitesProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Admin Portal',
        theme: ThemeData(
          primaryColor: const Color.fromARGB(255, 8, 113, 165),
          hintColor: const Color(0xFF005B8C),
          visualDensity: VisualDensity.adaptivePlatformDensity,
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.black),
            bodyMedium: TextStyle(color: Colors.black),
          ),
        ),
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/admin': (context) => const AdminScreen(),
        },
      ),
    );
  }
}
