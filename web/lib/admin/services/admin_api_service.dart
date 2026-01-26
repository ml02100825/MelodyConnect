import 'dart:convert';
import 'package:http/http.dart' as http;
import 'admin_token_storage_service.dart';
import 'admin_auth_service.dart';

/// 管理者API共通サービス
class AdminApiService {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  /// 認証ヘッダー付きでGETリクエスト
  static Future<http.Response> get(String path, {Map<String, String>? queryParams}) async {
    final token = await AdminTokenStorageService.getAccessToken();

    Uri uri = Uri.parse('$_baseUrl$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    var response = await http.get(
      uri,
      headers: _buildHeaders(token),
    );

    // 401の場合はトークンリフレッシュを試みる
    if (response.statusCode == 401) {
      if (await AdminAuthService.refreshToken()) {
        final newToken = await AdminTokenStorageService.getAccessToken();
        response = await http.get(
          uri,
          headers: _buildHeaders(newToken),
        );
      }
    }

    return response;
  }

  /// 認証ヘッダー付きでPOSTリクエスト
  static Future<http.Response> post(String path, {dynamic body}) async {
    final token = await AdminTokenStorageService.getAccessToken();

    var response = await http.post(
      Uri.parse('$_baseUrl$path'),
      headers: _buildHeaders(token),
      body: body != null ? jsonEncode(body) : null,
    );

    if (response.statusCode == 401) {
      if (await AdminAuthService.refreshToken()) {
        final newToken = await AdminTokenStorageService.getAccessToken();
        response = await http.post(
          Uri.parse('$_baseUrl$path'),
          headers: _buildHeaders(newToken),
          body: body != null ? jsonEncode(body) : null,
        );
      }
    }

    return response;
  }

  /// 認証ヘッダー付きでPUTリクエスト
  static Future<http.Response> put(String path, {dynamic body}) async {
    final token = await AdminTokenStorageService.getAccessToken();

    var response = await http.put(
      Uri.parse('$_baseUrl$path'),
      headers: _buildHeaders(token),
      body: body != null ? jsonEncode(body) : null,
    );

    if (response.statusCode == 401) {
      if (await AdminAuthService.refreshToken()) {
        final newToken = await AdminTokenStorageService.getAccessToken();
        response = await http.put(
          Uri.parse('$_baseUrl$path'),
          headers: _buildHeaders(newToken),
          body: body != null ? jsonEncode(body) : null,
        );
      }
    }

    return response;
  }

  /// 認証ヘッダー付きでDELETEリクエスト
  static Future<http.Response> delete(String path) async {
    final token = await AdminTokenStorageService.getAccessToken();

    var response = await http.delete(
      Uri.parse('$_baseUrl$path'),
      headers: _buildHeaders(token),
    );

    if (response.statusCode == 401) {
      if (await AdminAuthService.refreshToken()) {
        final newToken = await AdminTokenStorageService.getAccessToken();
        response = await http.delete(
          Uri.parse('$_baseUrl$path'),
          headers: _buildHeaders(newToken),
        );
      }
    }

    return response;
  }

  static Map<String, String> _buildHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ========== ユーザー管理API ==========

  static Future<Map<String, dynamic>> getUsers({
    int page = 0,
    int size = 20,
    int? id,
    String? userUuid,
    String? username,
    String? email,
    bool? banFlag,
    bool? subscribeFlag,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
    };
    if (id != null) queryParams['id'] = id.toString();
    if (userUuid != null) queryParams['userUuid'] = userUuid;
    if (username != null) queryParams['username'] = username;
    if (email != null) queryParams['email'] = email;
    if (banFlag != null) queryParams['banFlag'] = banFlag.toString();
    if (subscribeFlag != null) queryParams['subscribeFlag'] = subscribeFlag.toString();

    final response = await get('/api/admin/users', queryParams: queryParams);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getUserDetail(int userId) async {
    final response = await get('/api/admin/users/$userId');
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> freezeUsers(List<int> userIds) async {
    final response = await post('/api/admin/users/freeze', body: {'userIds': userIds});
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> unfreezeUsers(List<int> userIds) async {
    final response = await post('/api/admin/users/unfreeze', body: {'userIds': userIds});
    return jsonDecode(response.body);
  }

  // ========== 単語管理API ==========

  static Future<Map<String, dynamic>> getVocabularies({
    int page = 0,
    int size = 20,
    String? idSearch,
    String? word,
    String? partOfSpeech,
    bool? isActive,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
    };
    if (idSearch != null) queryParams['idSearch'] = idSearch;
    if (word != null) queryParams['word'] = word;
    if (partOfSpeech != null) queryParams['partOfSpeech'] = partOfSpeech;
    if (isActive != null) queryParams['isActive'] = isActive.toString();

    final response = await get('/api/admin/vocabularies', queryParams: queryParams);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getVocabulary(int vocabId) async {
    final response = await get('/api/admin/vocabularies/$vocabId');
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> createVocabulary(Map<String, dynamic> data) async {
    final response = await post('/api/admin/vocabularies', body: data);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateVocabulary(int vocabId, Map<String, dynamic> data) async {
    final response = await put('/api/admin/vocabularies/$vocabId', body: data);
    return jsonDecode(response.body);
  }

  static Future<void> deleteVocabulary(int vocabId) async {
    await delete('/api/admin/vocabularies/$vocabId');
  }

  static Future<Map<String, dynamic>> enableVocabularies(List<int> ids) async {
    final response = await post('/api/admin/vocabularies/enable', body: {'ids': ids});
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> disableVocabularies(List<int> ids) async {
    final response = await post('/api/admin/vocabularies/disable', body: {'ids': ids});
    return jsonDecode(response.body);
  }

  // ========== 問題管理API ==========

  static Future<Map<String, dynamic>> getQuestions({
    int page = 0,
    int size = 20,
    String? idSearch,
    int? artistId,
    String? questionFormat,
    String? language,
    int? difficultyLevel,
    bool? isActive,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
    };
    if (idSearch != null) queryParams['idSearch'] = idSearch;
    if (artistId != null) queryParams['artistId'] = artistId.toString();
    if (questionFormat != null) queryParams['questionFormat'] = questionFormat;
    if (language != null) queryParams['language'] = language;
    if (difficultyLevel != null) queryParams['difficultyLevel'] = difficultyLevel.toString();
    if (isActive != null) queryParams['isActive'] = isActive.toString();

    final response = await get('/api/admin/questions', queryParams: queryParams);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getQuestion(int questionId) async {
    final response = await get('/api/admin/questions/$questionId');
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> createQuestion(Map<String, dynamic> data) async {
    final response = await post('/api/admin/questions', body: data);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateQuestion(int questionId, Map<String, dynamic> data) async {
    final response = await put('/api/admin/questions/$questionId', body: data);
    return jsonDecode(response.body);
  }

  static Future<void> deleteQuestion(int questionId) async {
    await delete('/api/admin/questions/$questionId');
  }

  static Future<Map<String, dynamic>> enableQuestions(List<int> ids) async {
    final response = await post('/api/admin/questions/enable', body: {'ids': ids});
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> disableQuestions(List<int> ids) async {
    final response = await post('/api/admin/questions/disable', body: {'ids': ids});
    return jsonDecode(response.body);
  }

  // ========== 楽曲管理API ==========

  static Future<Map<String, dynamic>> getSongs({
    int page = 0,
    int size = 20,
    String? idSearch,
    String? songname,
    int? artistId,
    String? language,
    bool? isActive,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
    };
    if (idSearch != null) queryParams['idSearch'] = idSearch;
    if (songname != null) queryParams['songname'] = songname;
    if (artistId != null) queryParams['artistId'] = artistId.toString();
    if (language != null) queryParams['language'] = language;
    if (isActive != null) queryParams['isActive'] = isActive.toString();

    final response = await get('/api/admin/songs', queryParams: queryParams);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getSong(int songId) async {
    final response = await get('/api/admin/songs/$songId');
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> createSong(Map<String, dynamic> data) async {
    final response = await post('/api/admin/songs', body: data);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateSong(int songId, Map<String, dynamic> data) async {
    final response = await put('/api/admin/songs/$songId', body: data);
    return jsonDecode(response.body);
  }

  static Future<void> deleteSong(int songId) async {
    await delete('/api/admin/songs/$songId');
  }

  static Future<Map<String, dynamic>> enableSongs(List<int> ids) async {
    final response = await post('/api/admin/songs/enable', body: {'ids': ids});
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> disableSongs(List<int> ids) async {
    final response = await post('/api/admin/songs/disable', body: {'ids': ids});
    return jsonDecode(response.body);
  }

  // ========== アーティスト管理API ==========

  static Future<Map<String, dynamic>> getArtists({
    int page = 0,
    int size = 20,
    String? idSearch,
    String? artistName,
    bool? isActive,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
    };
    if (idSearch != null) queryParams['idSearch'] = idSearch;
    if (artistName != null) queryParams['artistName'] = artistName;
    if (isActive != null) queryParams['isActive'] = isActive.toString();

    final response = await get('/api/admin/artists', queryParams: queryParams);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getArtist(int artistId) async {
    final response = await get('/api/admin/artists/$artistId');
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> createArtist(Map<String, dynamic> data) async {
    final response = await post('/api/admin/artists', body: data);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateArtist(int artistId, Map<String, dynamic> data) async {
    final response = await put('/api/admin/artists/$artistId', body: data);
    return jsonDecode(response.body);
  }

  static Future<void> deleteArtist(int artistId) async {
    await delete('/api/admin/artists/$artistId');
  }

  static Future<Map<String, dynamic>> enableArtists(List<int> ids) async {
    final response = await post('/api/admin/artists/enable', body: {'ids': ids});
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> disableArtists(List<int> ids) async {
    final response = await post('/api/admin/artists/disable', body: {'ids': ids});
    return jsonDecode(response.body);
  }

  // ========== ジャンル管理API ==========

  static Future<Map<String, dynamic>> getGenres({
    int page = 0,
    int size = 20,
    String? idSearch,
    String? name,
    bool? isActive,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
    };
    if (idSearch != null) queryParams['idSearch'] = idSearch;
    if (name != null) queryParams['name'] = name;
    if (isActive != null) queryParams['isActive'] = isActive.toString();

    final response = await get('/api/admin/genres', queryParams: queryParams);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getGenre(int genreId) async {
    final response = await get('/api/admin/genres/$genreId');
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> createGenre(Map<String, dynamic> data) async {
    final response = await post('/api/admin/genres', body: data);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateGenre(int genreId, Map<String, dynamic> data) async {
    final response = await put('/api/admin/genres/$genreId', body: data);
    return jsonDecode(response.body);
  }

  static Future<void> deleteGenre(int genreId) async {
    await delete('/api/admin/genres/$genreId');
  }

  static Future<Map<String, dynamic>> enableGenres(List<int> ids) async {
    final response = await post('/api/admin/genres/enable', body: {'ids': ids});
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> disableGenres(List<int> ids) async {
    final response = await post('/api/admin/genres/disable', body: {'ids': ids});
    return jsonDecode(response.body);
  }

  // ========== バッジ管理API ==========

  static Future<Map<String, dynamic>> getBadges({
    int page = 0,
    int size = 20,
    String? idSearch,
    String? badgeName,
    int? mode,
    bool? isActive,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
    };
    if (idSearch != null) queryParams['idSearch'] = idSearch;
    if (badgeName != null) queryParams['badgeName'] = badgeName;
    if (mode != null) queryParams['mode'] = mode.toString();
    if (isActive != null) queryParams['isActive'] = isActive.toString();

    final response = await get('/api/admin/badges', queryParams: queryParams);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getBadge(int badgeId) async {
    final response = await get('/api/admin/badges/$badgeId');
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> createBadge(Map<String, dynamic> data) async {
    final response = await post('/api/admin/badges', body: data);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateBadge(int badgeId, Map<String, dynamic> data) async {
    final response = await put('/api/admin/badges/$badgeId', body: data);
    return jsonDecode(response.body);
  }

  static Future<void> deleteBadge(int badgeId) async {
    await delete('/api/admin/badges/$badgeId');
  }

  static Future<Map<String, dynamic>> enableBadges(List<int> ids) async {
    final response = await post('/api/admin/badges/enable', body: {'ids': ids});
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> disableBadges(List<int> ids) async {
    final response = await post('/api/admin/badges/disable', body: {'ids': ids});
    return jsonDecode(response.body);
  }

  // ========== お問い合わせ管理API ==========

  static Future<Map<String, dynamic>> getContacts({
    int page = 0,
    int size = 20,
    String? status,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
    };
    if (status != null) queryParams['status'] = status;

    final response = await get('/api/admin/contacts', queryParams: queryParams);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getContact(int contactId) async {
    final response = await get('/api/admin/contacts/$contactId');
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateContactStatus(int contactId, String status, String? adminMemo) async {
    final response = await put('/api/admin/contacts/$contactId/status', body: {
      'status': status,
      if (adminMemo != null) 'adminMemo': adminMemo,
    });
    return jsonDecode(response.body);
  }

  // ========== 単語報告管理API ==========

  static Future<Map<String, dynamic>> getVocabularyReports({
    int page = 0,
    int size = 20,
    String? status,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
    };
    if (status != null) queryParams['status'] = status;

    final response = await get('/api/admin/vocabulary-reports', queryParams: queryParams);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getVocabularyReport(int reportId) async {
    final response = await get('/api/admin/vocabulary-reports/$reportId');
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateVocabularyReportStatus(int reportId, String status, String? adminMemo) async {
    final response = await put('/api/admin/vocabulary-reports/$reportId/status', body: {
      'status': status,
      if (adminMemo != null) 'adminMemo': adminMemo,
    });
    return jsonDecode(response.body);
  }

  static Future<void> deleteVocabularyReport(int reportId) async {
    await delete('/api/admin/vocabulary-reports/$reportId');
  }

  // ========== 問題報告管理API ==========

  static Future<Map<String, dynamic>> getQuestionReports({
    int page = 0,
    int size = 20,
    String? status,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
    };
    if (status != null) queryParams['status'] = status;

    final response = await get('/api/admin/question-reports', queryParams: queryParams);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getQuestionReport(int reportId) async {
    final response = await get('/api/admin/question-reports/$reportId');
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateQuestionReportStatus(int reportId, String status, String? adminMemo) async {
    final response = await put('/api/admin/question-reports/$reportId/status', body: {
      'status': status,
      if (adminMemo != null) 'adminMemo': adminMemo,
    });
    return jsonDecode(response.body);
  }

  static Future<void> deleteQuestionReport(int reportId) async {
    await delete('/api/admin/question-reports/$reportId');
  }
}
