import 'dart:convert';
import 'package:http/http.dart' as http;
import 'admin_token_storage_service.dart';
import 'admin_auth_service.dart';
import '../../config/app_config.dart';

class AdminApiException implements Exception {
  final String message;
  final int? statusCode;

  AdminApiException(this.message, {this.statusCode});

  @override
  String toString() {
    if (statusCode == null) {
      return message;
    }
    return '$message (status: $statusCode)';
  }
}

/// 管理者API共通サービス
class AdminApiService {
  static String get _baseUrl => AppConfig.apiBaseUrl;

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

  static Map<String, dynamic> _decodeResponse(http.Response response) {
    final body = utf8.decode(response.bodyBytes);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body.isEmpty) {
        return {};
      }
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'data': decoded};
    }

    String message = 'リクエストに失敗しました';
    if (body.isNotEmpty) {
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          message = (decoded['error'] ?? decoded['message'] ?? message).toString();
        }
      } catch (_) {
        // ignore decode errors
      }
    }
    throw AdminApiException(message, statusCode: response.statusCode);
  }

  static void _ensureSuccess(http.Response response) {
    _decodeResponse(response);
  }

  static String _toIsoStart(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.toIso8601String();
  }

  static String _toIsoEnd(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
    return normalized.toIso8601String();
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
    DateTime? createdFrom,
    DateTime? createdTo,
    DateTime? offlineFrom,
    DateTime? offlineTo,
    DateTime? expiresFrom,
    DateTime? expiresTo,
    DateTime? canceledFrom,
    DateTime? canceledTo,
    String? sortDirection,
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
    if (createdFrom != null) queryParams['createdFrom'] = _toIsoStart(createdFrom);
    if (createdTo != null) queryParams['createdTo'] = _toIsoEnd(createdTo);
    if (offlineFrom != null) queryParams['offlineFrom'] = _toIsoStart(offlineFrom);
    if (offlineTo != null) queryParams['offlineTo'] = _toIsoEnd(offlineTo);
    if (expiresFrom != null) queryParams['expiresFrom'] = _toIsoStart(expiresFrom);
    if (expiresTo != null) queryParams['expiresTo'] = _toIsoEnd(expiresTo);
    if (canceledFrom != null) queryParams['canceledFrom'] = _toIsoStart(canceledFrom);
    if (canceledTo != null) queryParams['canceledTo'] = _toIsoEnd(canceledTo);
    if (sortDirection != null) queryParams['sortDirection'] = sortDirection;

    final response = await get('/api/admin/users', queryParams: queryParams);
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> getUserDetail(int userId) async {
    final response = await get('/api/admin/users/$userId');
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> freezeUsers(List<int> userIds) async {
    final response = await post('/api/admin/users/freeze', body: {'userIds': userIds});
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> unfreezeUsers(List<int> userIds) async {
    final response = await post('/api/admin/users/unfreeze', body: {'userIds': userIds});
    return _decodeResponse(response);
  }

  static Future<void> deleteUser(int userId) async {
    final response = await delete('/api/admin/users/$userId');
    _ensureSuccess(response);
  }

  static Future<void> restoreUser(int userId) async {
    final response = await put('/api/admin/users/$userId/restore');
    _ensureSuccess(response);
  }

  // ========== 単語管理API ==========

  static Future<Map<String, dynamic>> getVocabularies({
    int page = 0,
    int size = 20,
    String? idSearch,
    String? word,
    String? partOfSpeech,
    bool? isActive,
    DateTime? createdFrom,
    DateTime? createdTo,
    String? sortDirection,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
    };
    if (idSearch != null) queryParams['idSearch'] = idSearch;
    if (word != null) queryParams['word'] = word;
    if (partOfSpeech != null) queryParams['partOfSpeech'] = partOfSpeech;
    if (isActive != null) queryParams['isActive'] = isActive.toString();
    if (createdFrom != null) queryParams['createdFrom'] = _toIsoStart(createdFrom);
    if (createdTo != null) queryParams['createdTo'] = _toIsoEnd(createdTo);
    if (sortDirection != null) queryParams['sortDirection'] = sortDirection;

    final response = await get('/api/admin/vocabularies', queryParams: queryParams);
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> getVocabulary(int vocabId) async {
    final response = await get('/api/admin/vocabularies/$vocabId');
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> createVocabulary(Map<String, dynamic> data) async {
    final response = await post('/api/admin/vocabularies', body: data);
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> updateVocabulary(int vocabId, Map<String, dynamic> data) async {
    final response = await put('/api/admin/vocabularies/$vocabId', body: data);
    return _decodeResponse(response);
  }

  static Future<void> deleteVocabulary(int vocabId) async {
    final response = await delete('/api/admin/vocabularies/$vocabId');
    _ensureSuccess(response);
  }

  static Future<void> restoreVocabulary(int vocabId) async {
    final response = await put('/api/admin/vocabularies/$vocabId/restore');
    _ensureSuccess(response);
  }

  static Future<Map<String, dynamic>> enableVocabularies(List<int> ids) async {
    final response = await post('/api/admin/vocabularies/enable', body: {'ids': ids});
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> disableVocabularies(List<int> ids) async {
    final response = await post('/api/admin/vocabularies/disable', body: {'ids': ids});
    return _decodeResponse(response);
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
    String? questionText,
    String? answer,
    String? songName,
    String? artistName,
    DateTime? addedFrom,
    DateTime? addedTo,
    String? sortDirection,
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
    if (questionText != null) queryParams['questionText'] = questionText;
    if (answer != null) queryParams['answer'] = answer;
    if (songName != null) queryParams['songName'] = songName;
    if (artistName != null) queryParams['artistName'] = artistName;
    if (addedFrom != null) queryParams['addedFrom'] = _toIsoStart(addedFrom);
    if (addedTo != null) queryParams['addedTo'] = _toIsoEnd(addedTo);
    if (sortDirection != null) queryParams['sortDirection'] = sortDirection;

    final response = await get('/api/admin/questions', queryParams: queryParams);
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> getQuestion(int questionId) async {
    final response = await get('/api/admin/questions/$questionId');
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> createQuestion(Map<String, dynamic> data) async {
    final response = await post('/api/admin/questions', body: data);
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> updateQuestion(int questionId, Map<String, dynamic> data) async {
    final response = await put('/api/admin/questions/$questionId', body: data);
    return _decodeResponse(response);
  }

  static Future<void> deleteQuestion(int questionId) async {
    final response = await delete('/api/admin/questions/$questionId');
    _ensureSuccess(response);
  }

  static Future<void> restoreQuestion(int questionId) async {
    final response = await put('/api/admin/questions/$questionId/restore');
    _ensureSuccess(response);
  }

  static Future<Map<String, dynamic>> enableQuestions(List<int> ids) async {
    final response = await post('/api/admin/questions/enable', body: {'ids': ids});
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> disableQuestions(List<int> ids) async {
    final response = await post('/api/admin/questions/disable', body: {'ids': ids});
    return _decodeResponse(response);
  }

  // ========== 楽曲管理API ==========

  static Future<Map<String, dynamic>> getSongs({
    int page = 0,
    int size = 20,
    String? idSearch,
    String? songname,
    String? artistName,
    bool? isActive,
    DateTime? createdFrom,
    DateTime? createdTo,
    String? sortDirection,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
    };
    if (idSearch != null) queryParams['idSearch'] = idSearch;
    if (songname != null) queryParams['songname'] = songname;
    if (artistName != null) queryParams['artistName'] = artistName;
    if (isActive != null) queryParams['isActive'] = isActive.toString();
    if (createdFrom != null) queryParams['createdFrom'] = _toIsoStart(createdFrom);
    if (createdTo != null) queryParams['createdTo'] = _toIsoEnd(createdTo);
    if (sortDirection != null) queryParams['sortDirection'] = sortDirection;

    final response = await get('/api/admin/songs', queryParams: queryParams);
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> getSong(int songId) async {
    final response = await get('/api/admin/songs/$songId');
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> createSong(Map<String, dynamic> data) async {
    final response = await post('/api/admin/songs', body: data);
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> updateSong(int songId, Map<String, dynamic> data) async {
    final response = await put('/api/admin/songs/$songId', body: data);
    return _decodeResponse(response);
  }

  static Future<void> deleteSong(int songId) async {
    final response = await delete('/api/admin/songs/$songId');
    _ensureSuccess(response);
  }

  static Future<void> restoreSong(int songId) async {
    final response = await put('/api/admin/songs/$songId/restore');
    _ensureSuccess(response);
  }

  static Future<Map<String, dynamic>> enableSongs(List<int> ids) async {
    final response = await post('/api/admin/songs/enable', body: {'ids': ids});
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> disableSongs(List<int> ids) async {
    final response = await post('/api/admin/songs/disable', body: {'ids': ids});
    return _decodeResponse(response);
  }

  // ========== アーティスト管理API ==========

  static Future<Map<String, dynamic>> getArtists({
    int page = 0,
    int size = 20,
    String? idSearch,
    String? artistName,
    bool? isActive,
    String? genreName,
    DateTime? createdFrom,
    DateTime? createdTo,
    String? sortDirection,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
    };
    if (idSearch != null) queryParams['idSearch'] = idSearch;
    if (artistName != null) queryParams['artistName'] = artistName;
    if (isActive != null) queryParams['isActive'] = isActive.toString();
    if (genreName != null) queryParams['genreName'] = genreName;
    if (createdFrom != null) queryParams['createdFrom'] = _toIsoStart(createdFrom);
    if (createdTo != null) queryParams['createdTo'] = _toIsoEnd(createdTo);
    if (sortDirection != null) queryParams['sortDirection'] = sortDirection;

    final response = await get('/api/admin/artists', queryParams: queryParams);
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> getArtist(int artistId) async {
    final response = await get('/api/admin/artists/$artistId');
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> createArtist(Map<String, dynamic> data) async {
    final response = await post('/api/admin/artists', body: data);
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> updateArtist(int artistId, Map<String, dynamic> data) async {
    final response = await put('/api/admin/artists/$artistId', body: data);
    return _decodeResponse(response);
  }

  static Future<void> deleteArtist(int artistId) async {
    final response = await delete('/api/admin/artists/$artistId');
    _ensureSuccess(response);
  }

  static Future<void> restoreArtist(int artistId) async {
    final response = await put('/api/admin/artists/$artistId/restore');
    _ensureSuccess(response);
  }

  static Future<Map<String, dynamic>> enableArtists(List<int> ids) async {
    final response = await post('/api/admin/artists/enable', body: {'ids': ids});
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> disableArtists(List<int> ids) async {
    final response = await post('/api/admin/artists/disable', body: {'ids': ids});
    return _decodeResponse(response);
  }

  // ========== ジャンル管理API ==========

  static Future<Map<String, dynamic>> getGenres({
    int page = 0,
    int size = 20,
    String? idSearch,
    String? name,
    bool? isActive,
    DateTime? createdFrom,
    DateTime? createdTo,
    String? sortDirection,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
    };
    if (idSearch != null) queryParams['idSearch'] = idSearch;
    if (name != null) queryParams['name'] = name;
    if (isActive != null) queryParams['isActive'] = isActive.toString();
    if (createdFrom != null) queryParams['createdFrom'] = _toIsoStart(createdFrom);
    if (createdTo != null) queryParams['createdTo'] = _toIsoEnd(createdTo);
    if (sortDirection != null) queryParams['sortDirection'] = sortDirection;

    final response = await get('/api/admin/genres', queryParams: queryParams);
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> getGenre(int genreId) async {
    final response = await get('/api/admin/genres/$genreId');
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> createGenre(Map<String, dynamic> data) async {
    final response = await post('/api/admin/genres', body: data);
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> updateGenre(int genreId, Map<String, dynamic> data) async {
    final response = await put('/api/admin/genres/$genreId', body: data);
    return _decodeResponse(response);
  }

  static Future<void> deleteGenre(int genreId) async {
    final response = await delete('/api/admin/genres/$genreId');
    _ensureSuccess(response);
  }

  static Future<void> restoreGenre(int genreId) async {
    final response = await put('/api/admin/genres/$genreId/restore');
    _ensureSuccess(response);
  }

  static Future<Map<String, dynamic>> enableGenres(List<int> ids) async {
    final response = await post('/api/admin/genres/enable', body: {'ids': ids});
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> disableGenres(List<int> ids) async {
    final response = await post('/api/admin/genres/disable', body: {'ids': ids});
    return _decodeResponse(response);
  }

  // ========== バッジ管理API ==========

  static Future<Map<String, dynamic>> getBadges({
    int page = 0,
    int size = 20,
    String? idSearch,
    String? badgeName,
    String? acquisitionCondition,
    int? mode,
    bool? isActive,
    DateTime? createdFrom,
    DateTime? createdTo,
    String? sortDirection,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
    };
    if (idSearch != null) queryParams['idSearch'] = idSearch;
    if (badgeName != null) queryParams['badgeName'] = badgeName;
    if (acquisitionCondition != null) queryParams['acquisitionCondition'] = acquisitionCondition;
    if (mode != null) queryParams['mode'] = mode.toString();
    if (isActive != null) queryParams['isActive'] = isActive.toString();
    if (createdFrom != null) queryParams['createdFrom'] = _toIsoStart(createdFrom);
    if (createdTo != null) queryParams['createdTo'] = _toIsoEnd(createdTo);
    if (sortDirection != null) queryParams['sortDirection'] = sortDirection;

    final response = await get('/api/admin/badges', queryParams: queryParams);
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> getBadge(int badgeId) async {
    final response = await get('/api/admin/badges/$badgeId');
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> createBadge(Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data);
    final modeValue = payload['mode'];
    if (modeValue is String) {
      final parsed = int.tryParse(modeValue);
      if (parsed != null) {
        payload['mode'] = parsed;
      }
    }
    final response = await post('/api/admin/badges', body: payload);
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> updateBadge(int badgeId, Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data);
    final modeValue = payload['mode'];
    if (modeValue is String) {
      final parsed = int.tryParse(modeValue);
      if (parsed != null) {
        payload['mode'] = parsed;
      }
    }
    final response = await put('/api/admin/badges/$badgeId', body: payload);
    return _decodeResponse(response);
  }

  static Future<void> deleteBadge(int badgeId) async {
    final response = await delete('/api/admin/badges/$badgeId');
    _ensureSuccess(response);
  }

  static Future<void> restoreBadge(int badgeId) async {
    final response = await put('/api/admin/badges/$badgeId/restore');
    _ensureSuccess(response);
  }

  static Future<Map<String, dynamic>> enableBadges(List<int> ids) async {
    final response = await post('/api/admin/badges/enable', body: {'ids': ids});
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> disableBadges(List<int> ids) async {
    final response = await post('/api/admin/badges/disable', body: {'ids': ids});
    return _decodeResponse(response);
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
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> getContact(int contactId) async {
    final response = await get('/api/admin/contacts/$contactId');
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> updateContactStatus(int contactId, String status, String? adminMemo) async {
    final response = await put('/api/admin/contacts/$contactId/status', body: {
      'status': status,
      if (adminMemo != null) 'adminMemo': adminMemo,
    });
    return _decodeResponse(response);
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
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> getVocabularyReport(int reportId) async {
    final response = await get('/api/admin/vocabulary-reports/$reportId');
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> updateVocabularyReportStatus(int reportId, String status, String? adminMemo) async {
    final response = await put('/api/admin/vocabulary-reports/$reportId/status', body: {
      'status': status,
      if (adminMemo != null) 'adminMemo': adminMemo,
    });
    return _decodeResponse(response);
  }

  static Future<void> deleteVocabularyReport(int reportId) async {
    final response = await delete('/api/admin/vocabulary-reports/$reportId');
    _ensureSuccess(response);
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
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> getQuestionReport(int reportId) async {
    final response = await get('/api/admin/question-reports/$reportId');
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> updateQuestionReportStatus(int reportId, String status, String? adminMemo) async {
    final response = await put('/api/admin/question-reports/$reportId/status', body: {
      'status': status,
      if (adminMemo != null) 'adminMemo': adminMemo,
    });
    return _decodeResponse(response);
  }

  static Future<void> deleteQuestionReport(int reportId) async {
    final response = await delete('/api/admin/question-reports/$reportId');
    _ensureSuccess(response);
  }
}
