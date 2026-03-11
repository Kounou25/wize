import 'package:flutter/material.dart';
import 'package:wize_writter/pages/Wize_reader.dart';
import 'package:wize_writter/pages/Wize_writter.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const NfcReadScreen(),
    );
  }
}
