import 'package:flutter/material.dart';
import 'config/app_config.dart';
import 'screens/splash_screen.dart';
import 'screens/battle_mode_selection_screen.dart';
import 'screens/language_selection_screen.dart';
import 'screens/matching_screen.dart';
import 'screens/battle_screen.dart';
import 'screens/quiz_selection_screen.dart';
import 'screens/vocabulary_screen.dart';
import 'screens/room_match_screen.dart';
import 'screens/room_invitations_screen.dart';
import 'screens/battle_history_screen.dart';
import 'screens/battle_history_detail_screen.dart';
import 'screens/learning_menu_screen.dart';
import 'screens/learning_history_screen.dart';
import 'screens/learning_history_detail_screen.dart';
import 'widgets/room_invitation_overlay.dart';

// 管理者画面
import 'admin/admin_login_screen.dart';
import 'admin/admin_route_guard.dart';
import 'admin/user_list_admin.dart';
import 'admin/vocabulary_admin.dart';
import 'admin/mondai_admin.dart';
import 'admin/music_admin.dart';
import 'admin/artist_admin.dart';
import 'admin/genre_admin.dart';
import 'admin/badge_admin.dart';
import 'admin/contact_admin.dart';

/// 初期ルートを取得（管理者ルート対応）
String _getInitialRoute() {
  try {
    final uri = Uri.base;
    final path = uri.path;
    // 管理者ルートの場合はそのパスを返す
    if (path.startsWith('/admin')) {
      return path;
    }
  } catch (e) {
    // Web以外の環境では例外が発生する可能性がある
  }
  return '/';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.load();  // 設定ファイルを読み込む

  final initialRoute = _getInitialRoute();
  runApp(MyApp(initialRoute: initialRoute));
}

/// ナビゲーターキー（オーバーレイからのナビゲーション用）
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    final isAdminRoute = initialRoute.startsWith('/admin');

    return MaterialApp(
      title: 'MelodyConnect',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      builder: (context, child) {
        // 管理者ルートの場合はオーバーレイを表示しない
        if (isAdminRoute) {
          return child ?? const SizedBox.shrink();
        }
        // アプリ全体で招待通知を表示
        return RoomInvitationOverlay(
          navigatorKey: navigatorKey,
          child: child ?? const SizedBox.shrink(),
        );
      },
      // 管理者ルートの場合は直接ルーティング、それ以外はスプラッシュ画面
      initialRoute: isAdminRoute ? initialRoute : null,
      home: isAdminRoute ? null : const SplashScreen(),  // セッション検証を行うスプラッシュ画面
      routes: {
        '/battle-mode': (context) => const BattleModeSelectionScreen(),
        '/language-selection': (context) => const LanguageSelectionScreen(),
        '/learning': (context) => const QuizSelectionScreen(),
        '/learning-menu': (context) => const LearningMenuScreen(),
        '/room-invitations': (context) => const RoomInvitationsScreen(),
        '/battle-history': (context) => const BattleHistoryScreen(),
        // 管理者画面
        '/admin/login': (context) => const AdminLoginScreen(),
        '/admin/users': (context) => AdminRouteGuard(child: UserListAdmin()),
        '/admin/vocabularies': (context) => AdminRouteGuard(child: VocabularyAdmin()),
        '/admin/questions': (context) => AdminRouteGuard(child: MondaiAdmin()),
        '/admin/music': (context) => AdminRouteGuard(child: MusicAdmin()),
        '/admin/artists': (context) => AdminRouteGuard(child: ArtistAdmin()),
        '/admin/genres': (context) => AdminRouteGuard(child: GenreAdmin()),
        '/admin/badges': (context) => AdminRouteGuard(child: BadgeAdmin()),
        '/admin/contacts': (context) => AdminRouteGuard(child: ContactAdmin()),
      },
      onGenerateRoute: (settings) {
        // /room-match?roomId=123&isGuest=true&isReturning=true のようなクエリパラメータ付きルートを処理
        if (settings.name?.startsWith('/room-match') == true) {
          final uri = Uri.parse(settings.name!);
          final roomIdStr = uri.queryParameters['roomId'];
          final roomId = roomIdStr != null ? int.tryParse(roomIdStr) : null;
          final isGuest = uri.queryParameters['isGuest'] == 'true';
          final isReturning = uri.queryParameters['isReturning'] == 'true';
          final skipAccept = uri.queryParameters['skipAccept'] == 'true';
          final isFromVocabulary = uri.queryParameters['fromVocabulary'] == 'true';
          return MaterialPageRoute(
            builder: (context) => RoomMatchScreen(
              roomId: roomId,
              isGuest: isGuest,
              isReturning: isReturning,
              skipAccept: skipAccept,
              isFromVocabulary: isFromVocabulary,
            ),
            settings: settings,
          );
        }

        // /matching?language=english のようなクエリパラメータ付きルートを処理
        if (settings.name?.startsWith('/matching') == true) {
          final uri = Uri.parse(settings.name!);
          final language = uri.queryParameters['language'] ?? 'english';
          return MaterialPageRoute(
            builder: (context) => MatchingScreen(language: language),
            settings: settings,
          );
        }

        // /battle?matchId=xxx&isRoomMatch=true&roomId=123 のようなクエリパラメータ付きルートを処理
        if (settings.name?.startsWith('/battle') == true) {
          final uri = Uri.parse(settings.name!);
          final matchId = uri.queryParameters['matchId'];
          if (matchId != null) {
            final isRoomMatch = uri.queryParameters['isRoomMatch'] == 'true';
            final roomIdStr = uri.queryParameters['roomId'];
            final roomId = roomIdStr != null ? int.tryParse(roomIdStr) : null;
            return MaterialPageRoute(
              builder: (context) => BattleScreen(
                matchId: matchId,
                isRoomMatch: isRoomMatch,
                roomId: roomId,
              ),
              settings: settings,
            );
          }
        }

        // /vocabulary?userId=xxx のようなクエリパラメータ付きルートを処理
        if (settings.name?.startsWith('/vocabulary') == true) {
          final uri = Uri.parse(settings.name!);
          final userIdStr = uri.queryParameters['userId'];
          final userId = userIdStr != null ? int.tryParse(userIdStr) ?? 0 : 0;
          final returnRoomIdStr = uri.queryParameters['returnRoomId'];
          final returnRoomId = returnRoomIdStr != null
              ? int.tryParse(returnRoomIdStr)
              : null;
          return MaterialPageRoute(
            builder: (context) => VocabularyScreen(
              userId: userId,
              returnRoomId: returnRoomId,
            ),
            settings: settings,
          );
        }

        // /battle-history/detail?resultId=xxx
        if (settings.name?.startsWith('/battle-history/detail') == true) {
          final uri = Uri.parse(settings.name!);
          final resultIdStr = uri.queryParameters['resultId'];
          final resultId = resultIdStr != null ? int.tryParse(resultIdStr) ?? 0 : 0;
          return MaterialPageRoute(
            builder: (context) => BattleHistoryDetailScreen(resultId: resultId),
            settings: settings,
          );
        }

        // /learning-history?userId=xxx
        if (settings.name?.startsWith('/learning-history/detail') == true) {
          final uri = Uri.parse(settings.name!);
          final historyIdStr = uri.queryParameters['historyId'];
          final historyId = historyIdStr != null ? int.tryParse(historyIdStr) ?? 0 : 0;
          return MaterialPageRoute(
            builder: (context) => LearningHistoryDetailScreen(historyId: historyId),
            settings: settings,
          );
        }

        // /learning-history?userId=xxx
        if (settings.name?.startsWith('/learning-history') == true) {
          final uri = Uri.parse(settings.name!);
          final userIdStr = uri.queryParameters['userId'];
          final userId = userIdStr != null ? int.tryParse(userIdStr) : null;
          return MaterialPageRoute(
            builder: (context) => LearningHistoryScreen(userId: userId),
            settings: settings,
          );
        }

        return null;
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
