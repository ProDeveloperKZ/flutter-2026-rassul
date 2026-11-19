import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:users_api/core/api/api_client.dart';
import 'package:users_api/core/api/api_exception.dart';
import 'package:users_api/features/users/user.dart';
import 'package:users_api/features/users/user_repository.dart';

Map<String, dynamic> _sampleUserMap({
  int id = 1,
  String name = 'Leanne Graham',
}) {
  return {
    'id': id,
    'name': name,
    'username': 'Bret',
    'email': 'Sincere@april.biz',
    'address': {
      'street': 'Kulas Light',
      'suite': 'Apt. 556',
      'city': 'Gwenborough',
      'zipcode': '92998-3874',
      'geo': {'lat': '-37.3159', 'lng': '81.1496'},
    },
    'phone': '1-770-736-8031 x56442',
    'website': 'hildegard.org',
    'company': {
      'name': 'Romaguera-Crona',
      'catchPhrase': 'Multi-layered client-server neural-net',
    },
  };
}

void main() {
  group('ApiClient & UserRepository', () {
    test(
      'getAll builds Uri.https, sends Accept header, and returns users',
      () async {
        late http.Request captured;
        final client = MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode([
              _sampleUserMap(id: 1),
              _sampleUserMap(id: 2, name: 'Ervin Howell'),
            ]),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });

        final repo = UserRepository(ApiClient(client));
        addTearDown(repo.close);

        final users = await repo.getAll();
        expect(
          captured.url,
          Uri.https('jsonplaceholder.typicode.com', '/users'),
        );
        expect(captured.headers['Accept'], 'application/json');
        expect(users, hasLength(2));
        expect(users.first.name, 'Leanne Graham');
        expect(users.last.id, 2);
      },
    );

    test('getById checks 404 before decoding empty JSON body {}', () async {
      final client = MockClient((request) async {
        expect(
          request.url,
          Uri.https('jsonplaceholder.typicode.com', '/users/999'),
        );
        return http.Response('{}', 404);
      });

      final repo = UserRepository(ApiClient(client));
      addTearDown(repo.close);

      await expectLater(repo.getById(999), throwsA(isA<NotFoundException>()));
    });

    test(
      'maps 401 to UnauthorizedException and 5xx to ServerException',
      () async {
        final unauthorizedRepo = UserRepository(
          ApiClient(MockClient((_) async => http.Response('', 401))),
        );
        addTearDown(unauthorizedRepo.close);

        await expectLater(
          unauthorizedRepo.getAll(),
          throwsA(isA<UnauthorizedException>()),
        );

        final serverErrorRepo = UserRepository(
          ApiClient(MockClient((_) async => http.Response('fail', 503))),
        );
        addTearDown(serverErrorRepo.close);

        await expectLater(
          serverErrorRepo.getAll(),
          throwsA(
            isA<ServerException>().having((e) => e.status, 'status', 503),
          ),
        );
      },
    );

    test(
      'maps SocketException and TimeoutException to NoConnectionException',
      () async {
        final socketRepo = UserRepository(
          ApiClient(
            MockClient(
              (_) async => throw const SocketException('No route to host'),
            ),
          ),
        );
        addTearDown(socketRepo.close);

        await expectLater(
          socketRepo.getAll(),
          throwsA(isA<NoConnectionException>()),
        );

        final timeoutRepo = UserRepository(
          ApiClient(
            MockClient((_) => Completer<http.Response>().future),
            timeout: const Duration(milliseconds: 50),
          ),
        );
        addTearDown(timeoutRepo.close);

        await expectLater(
          timeoutRepo.getAll(),
          throwsA(isA<NoConnectionException>()),
        );
      },
    );

    test(
      'maps malformed JSON and wrong field types to BadResponseException',
      () async {
        final invalidJsonRepo = UserRepository(
          ApiClient(MockClient((_) async => http.Response('{not-json', 200))),
        );
        addTearDown(invalidJsonRepo.close);

        await expectLater(
          invalidJsonRepo.getById(1),
          throwsA(isA<BadResponseException>()),
        );

        final badField = _sampleUserMap(id: 1)..['id'] = '1';
        final wrongTypeRepo = UserRepository(
          ApiClient(
            MockClient((_) async => http.Response(jsonEncode(badField), 200)),
          ),
        );
        addTearDown(wrongTypeRepo.close);

        await expectLater(
          wrongTypeRepo.getById(1),
          throwsA(
            isA<BadResponseException>().having(
              (e) => e.detail,
              'detail',
              contains('users/1:'),
            ),
          ),
        );
      },
    );

    test('create sends POST with JSON body and expects 201', () async {
      late http.Request captured;
      final client = MockClient((request) async {
        captured = request;
        final sent = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({...sent, 'id': 11}),
          201,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final repo = UserRepository(ApiClient(client));
      addTearDown(repo.close);

      final draft = User.fromJson(_sampleUserMap(id: 0, name: 'Rassul'));
      final created = await repo.create(draft);

      expect(captured.method, 'POST');
      expect(captured.url, Uri.https('jsonplaceholder.typicode.com', '/users'));
      expect(captured.headers['Content-Type'], startsWith('application/json'));
      expect(captured.headers['Accept'], 'application/json');
      expect(created.id, 11);
      expect(created.name, 'Rassul');
    });
  });
}
