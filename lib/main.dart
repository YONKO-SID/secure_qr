import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
  print("Starting up");
}

// stateless widget means it simply won't change its state over time
class MyApp extends StatelessWidget {
  int counter = 0;
  bool isDarkMode = false;
  bool isLightMode = true;
  String? stack;

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    print("Hello you can scan any qr with this");
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Secure qr',
      home: Scaffold(
        backgroundColor: Colors.lightBlue,

        appBar: AppBar(
          title: Text('Secure QR'),
          backgroundColor: Colors.deepPurpleAccent,
          leading: IconButton(icon: Icon(Icons.menu), onPressed: () {}),
          actions: [IconButton(icon: Icon(Icons.settings), onPressed: () {})],
        ),
        body: Center(
          child: Container(
            height: 200,
            width: 200,
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              // this curves the corners
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            padding: EdgeInsets.all(25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person, size: 50, color: Colors.white),
                Text(
                  "Hello , Scan any qr with this app",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
