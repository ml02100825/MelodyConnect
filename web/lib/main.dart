import 'package:flutter/material.dart';
import 'admin/vocabulary_admin.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MelodyConnect',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const VocabularyAdmin(),
      debugShowCheckedModeBanner: false,
    );
  }
}
