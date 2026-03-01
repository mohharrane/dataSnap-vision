import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(DataSnapVisionApp());
}

class DataSnapVisionApp extends StatelessWidget {
  DataSnapVisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DataSnap Vision',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: AppBarTheme(
          color: Colors.blue[800],
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: HomeScreen(),
    );
  }
}
