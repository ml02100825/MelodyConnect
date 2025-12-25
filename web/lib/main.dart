import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/battle_mode_selection_screen.dart';
import 'screens/language_selection_screen.dart';
import 'screens/matching_screen.dart';
import 'screens/battle_screen.dart';
import 'screens/quiz_selection_screen.dart';
import 'screens/vocabulary_screen.dart';

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
      home: const SplashScreen(),  // セッション検証を行うスプラッシュ画面
      routes: {
        '/battle-mode': (context) => const BattleModeSelectionScreen(),
        '/language-selection': (context) => const LanguageSelectionScreen(),
        '/learning': (context) => const QuizSelectionScreen(),
        '/vocabulary': (context) => const VocabularyScreen(),
      },
      onGenerateRoute: (settings) {
        // /matching?language=english のようなクエリパラメータ付きルートを処理
        if (settings.name?.startsWith('/matching') == true) {
          final uri = Uri.parse(settings.name!);
          final language = uri.queryParameters['language'] ?? 'english';
          return MaterialPageRoute(
            builder: (context) => MatchingScreen(language: language),
            settings: settings,
          );
        }

        // /battle?matchId=xxx のようなクエリパラメータ付きルートを処理
        if (settings.name?.startsWith('/battle') == true) {
          final uri = Uri.parse(settings.name!);
          final matchId = uri.queryParameters['matchId'];
          if (matchId != null) {
            return MaterialPageRoute(
              builder: (context) => BattleScreen(matchId: matchId),
              settings: settings,
            );
          }
        }

        return null;
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
