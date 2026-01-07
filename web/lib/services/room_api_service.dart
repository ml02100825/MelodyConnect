import 'dart:convert';
import 'package:http/http.dart' as http;

/// ルームマッチAPI サービス
class RoomApiService {
  static const String baseUrl = 'http://localhost:8080/api/rooms';

  /// 部屋を作成
  Future<Map<String, dynamic>> createRoom({
    required int hostId,
    required int matchType,
    required String language,
    String? problemType,
    String? questionFormat,
    required String accessToken,
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'hostId': hostId,
        'matchType': matchType,
        'language': language,
        'problemType': problemType ?? 'mixed',
        'questionFormat': questionFormat ?? 'mixed',
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? '部屋の作成に失敗しました');
    }
  }

  /// 部屋情報を取得
  Future<Map<String, dynamic>> getRoom({
    required int roomId,
    required String accessToken,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$roomId'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? '部屋情報の取得に失敗しました');
    }
  }

  /// フレンドを招待
  Future<Map<String, dynamic>> inviteFriend({
    required int roomId,
    required int hostId,
    required int friendId,
    required String accessToken,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$roomId/invite'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'hostId': hostId,
        'friendId': friendId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? '招待の送信に失敗しました');
    }
  }

  /// 受信招待一覧を取得
  Future<List<Map<String, dynamic>>> getInvitations({
    required int userId,
    required String accessToken,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/invitations?userId=$userId'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? '招待一覧の取得に失敗しました');
    }
  }

  /// 招待を受理
  Future<Map<String, dynamic>> acceptInvitation({
    required int roomId,
    required int userId,
    required String accessToken,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/invitations/$roomId/accept'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'userId': userId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? '招待の受理に失敗しました');
    }
  }

  /// 招待を拒否
  Future<void> rejectInvitation({
    required int roomId,
    required int userId,
    required String accessToken,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/invitations/$roomId/reject'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'userId': userId,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? '招待の拒否に失敗しました');
    }
  }

  /// 部屋から退出
  Future<Map<String, dynamic>> leaveRoom({
    required int roomId,
    required int userId,
    required String accessToken,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$roomId/leave?userId=$userId'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? '退出に失敗しました');
    }
  }

  /// 部屋をリセット（再戦用）
  Future<Map<String, dynamic>> resetRoom({
    required int roomId,
    required int hostId,
    required String accessToken,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$roomId/reset'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'hostId': hostId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'リセットに失敗しました');
    }
  }

  /// 招待済みユーザー一覧を取得
  Future<List<Map<String, dynamic>>> getInvitedUsers({
    required int roomId,
    required String accessToken,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$roomId/invited'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? '招待済みユーザーの取得に失敗しました');
    }
  }

  /// フレンド一覧を取得（招待用）
  Future<List<Map<String, dynamic>>> getFriends({
    required int userId,
    required String accessToken,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/friends?userId=$userId'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'フレンド一覧の取得に失敗しました');
    }
  }
}
