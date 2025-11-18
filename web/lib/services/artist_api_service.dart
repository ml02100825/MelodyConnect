import 'dart:convert';
import 'package:http/http.dart' as http;

/// アーティスト検索結果
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
      'genre': genres.isNotEmpty ? genres.first : 'pop',
    };
  }
}

/// アーティストAPIサービス
class ArtistApiService {
  final String baseUrl;

  ArtistApiService({this.baseUrl = 'http://localhost:8080'});

  /// アーティストを検索
  Future<List<SpotifyArtist>> searchArtists(
      String query, String accessToken) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/artist/search?q=$query&limit=10'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
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
