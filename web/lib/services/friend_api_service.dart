import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_webapp/config/app_config.dart';

/// フレンドAPIサービス
/// バックエンドのフレンドエンドポイントとの通信を行います
class FriendApiService {
  String get baseUrl => '${AppConfig.apiBaseUrl}/api/friend';

  /// UUIDでユーザーを検索
  Future<Map<String, dynamic>> searchUser(
      String userUuid, String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/search/$userUuid'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'ユーザーが見つかりません');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('ネットワークエラーが発生しました');
    }
  }

  /// フレンド申請を送信
  Future<void> sendFriendRequest(
      int userId, String targetUserUuid, String accessToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$userId/request'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'targetUserUuid': targetUserUuid,
        }),
      );

      if (response.statusCode != 201) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'フレンド申請に失敗しました');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('ネットワークエラーが発生しました');
    }
  }

  /// フレンド申請を承認（friendId ベース）
  Future<void> acceptFriendRequest(
      int userId, int friendId, String accessToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$userId/accept/$friendId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'フレンド申請の承認に失敗しました');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('ネットワークエラーが発生しました');
    }
  }

  /// フレンド申請を承認（相手ユーザーIDベース）
  Future<void> acceptFriendRequestbyId(
      int userId, int otherUserId, String accessToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/accept'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'loginUserId': userId,
          'otherUserId': otherUserId,
        }),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'フレンド申請の承認に失敗しました');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('ネットワークエラーが発生しました');
    }
  }

  /// フレンド申請を拒否（friendId ベース）
  Future<void> rejectFriendRequest(
      int userId, int friendId, String accessToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$userId/reject/$friendId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'フレンド申請の拒否に失敗しました');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('ネットワークエラーが発生しました');
    }
  }

  /// フレンド申請を拒否（相手ユーザーIDベース）
  Future<void> rejectFriendRequestById(
      int userId, int otherUserId, String accessToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reject'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'loginUserId': userId,
          'otherUserId': otherUserId,
        }),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'フレンド申請の拒否に失敗しました');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('ネットワークエラーが発生しました');
    }
  }

  /// フレンド一覧を取得
  Future<List<dynamic>> getFriendList(int userId, String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$userId/list'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'フレンド一覧の取得に失敗しました');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('ネットワークエラーが発生しました');
    }
  }

  /// フレンド申請一覧を取得
  Future<List<dynamic>> getPendingRequests(
      int userId, String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$userId/requests'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'フレンド申請一覧の取得に失敗しました');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('ネットワークエラーが発生しました');
    }
  }

  /// フレンドプロフィールを取得
  Future<Map<String, dynamic>> getFriendProfile(
      int userId, int friendUserId, String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$userId/profile/$friendUserId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'プロフィールの取得に失敗しました');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('ネットワークエラーが発生しました');
    }
  }

  /// フレンドを削除
  Future<void> deleteFriend(
      int userId, int friendId, String accessToken) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/$userId/delete/$friendId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'フレンドの削除に失敗しました');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('ネットワークエラーが発生しました');
    }
  }
}
