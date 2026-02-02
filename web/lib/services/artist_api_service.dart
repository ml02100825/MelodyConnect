import 'dart:convert';
import 'package:http/http.dart' as http;

/// アーティスト検索結果モデル
class SpotifyArtist {
  final String spotifyId;
  final String name;
  final String? imageUrl;
  final List<String> genres;
  final int popularity;

  SpotifyArtist({
    required this.spotifyId,
    required this.name,
    this.imageUrl,
    required this.genres,
    required this.popularity,
  });

  factory SpotifyArtist.fromJson(Map<String, dynamic> json) {
    return SpotifyArtist(
      spotifyId: json['spotifyId'] ?? '',
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'],
      genres: (json['genres'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      popularity: json['popularity'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'spotifyId': spotifyId,
      'name': name,
      'imageUrl': imageUrl,
      // バックエンドの自動振り分けに任せるため、空の場合は空文字を送る
      'genre': genres.isNotEmpty ? genres.first : '',
    };
  }
}

/// アーティストAPIサービス
class ArtistApiService {
  final String baseUrl;

  // 環境に合わせて変更 (Androidエミュレーターなら 'http://10.0.2.2:8080')
  ArtistApiService({this.baseUrl = 'http://localhost:8080'});

  /// ジャンル一覧を取得
  Future<List<Map<String, dynamic>>> getGenres(String accessToken) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/genres'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('ジャンルの取得に失敗しました: ${response.statusCode}');
    }
  }

  /// アーティストを検索 (修正版: queryParametersを使用)
  Future<List<SpotifyArtist>> searchArtists(
      String query, String accessToken) async {
    
    // ★修正: queryParametersを使って安全にURLエンコードを行う
    // これにより genre:"bossa nova" などの記号やスペースを含むクエリも正しく送信されます
    final uri = Uri.parse('$baseUrl/api/artist/search').replace(
      queryParameters: {
        'q': query,
        'limit': '10',
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((json) => SpotifyArtist.fromJson(json)).toList();
    } else {
      throw Exception('アーティスト検索に失敗しました: ${response.statusCode}');
    }
  }

  /// お気に入りアーティストを登録
  Future<void> registerLikeArtists(
      List<SpotifyArtist> artists, String accessToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/artist/like'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: json.encode({
        'artists': artists.map((a) => a.toJson()).toList(),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('アーティスト登録に失敗しました: ${response.statusCode}');
    }
  }

  /// 初期設定完了状態を確認
  Future<bool> isInitialSetupCompleted(String accessToken) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/artist/setup-status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['initialSetupCompleted'] ?? false;
    } else {
      throw Exception('初期設定状態の確認に失敗しました: ${response.statusCode}');
    }
  }
}