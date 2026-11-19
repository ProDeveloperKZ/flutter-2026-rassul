import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import 'user.dart';

class UserRepository {
  UserRepository(this._api);

  final ApiClient _api;

  Future<List<User>> getAll() async {
    final uri = Uri.https(_api.host, '/users');
    final decoded = await _api.get(uri);
    try {
      final list = decoded as List<dynamic>;
      return list
          .map((item) => User.fromJson(item as Map<String, dynamic>))
          .toList();
    } on TypeError catch (e) {
      throw BadResponseException('users: $e');
    } on FormatException catch (e) {
      throw BadResponseException('users: $e');
    }
  }

  Future<User> getById(int id) async {
    final uri = Uri.https(_api.host, '/users/$id');
    final decoded = await _api.get(uri);
    try {
      return User.fromJson(decoded as Map<String, dynamic>);
    } on TypeError catch (e) {
      throw BadResponseException('users/$id: $e');
    } on FormatException catch (e) {
      throw BadResponseException('users/$id: $e');
    }
  }

  Future<User> create(User draft) async {
    final uri = Uri.https(_api.host, '/users');
    final decoded = await _api.post(
      uri,
      body: draft.toJson(),
      expectedStatus: 201,
    );
    try {
      return User.fromJson(decoded as Map<String, dynamic>);
    } on TypeError catch (e) {
      throw BadResponseException('users/create: $e');
    } on FormatException catch (e) {
      throw BadResponseException('users/create: $e');
    }
  }

  void close() => _api.close();
}
