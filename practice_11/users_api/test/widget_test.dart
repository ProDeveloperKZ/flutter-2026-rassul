import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:users_api/core/api/api_client.dart';
import 'package:users_api/features/users/user_repository.dart';
import 'package:users_api/features/users/users_model.dart';
import 'package:users_api/features/users/users_screen.dart';

List<Map<String, dynamic>> _sampleUsers() => [
  {
    'id': 1,
    'name': 'Leanne Graham',
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
  },
  {
    'id': 2,
    'name': 'Ervin Howell',
    'username': 'Antonette',
    'email': 'Shanna@melissa.tv',
    'address': {
      'street': 'Victor Plains',
      'suite': 'Suite 879',
      'city': 'Wisokyburgh',
      'zipcode': '90566-7771',
      'geo': {'lat': '-43.9509', 'lng': '-34.4618'},
    },
    'phone': '010-692-6593 x09125',
    'website': 'anastasia.net',
    'company': {
      'name': 'Deckow-Crist',
      'catchPhrase': 'Proactive didactic contingency',
    },
  },
];

Widget _buildTestApp(http.Client client) {
  return ChangeNotifierProvider(
    create: (_) {
      final model = UsersModel(UserRepository(ApiClient(client)));
      unawaited(model.load());
      return model;
    },
    child: const MaterialApp(home: UsersScreen()),
  );
}

void main() {
  testWidgets('loads users, opens detail screen with phoneDigits and website', (
    tester,
  ) async {
    final completer = Completer<http.Response>();
    final client = MockClient((request) => completer.future);

    await tester.pumpWidget(_buildTestApp(client));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(http.Response(jsonEncode(_sampleUsers()), 200));
    await tester.pumpAndSettle();

    expect(find.text('Leanne Graham'), findsOneWidget);
    expect(find.text('Ervin Howell'), findsOneWidget);
    expect(find.textContaining('Gwenborough'), findsOneWidget);

    await tester.tap(find.text('Leanne Graham'));
    await tester.pumpAndSettle();

    expect(find.text('@Bret'), findsOneWidget);
    expect(find.textContaining('1770736803156442'), findsOneWidget);
    expect(find.text('hildegard.org'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Romaguera-Crona'), 200);
    expect(find.text('Romaguera-Crona'), findsOneWidget);
    expect(find.text('Multi-layered client-server neural-net'), findsOneWidget);
  });

  testWidgets('pull-to-refresh reloads users', (tester) async {
    var loads = 0;
    final client = MockClient((request) async {
      loads++;
      return http.Response(jsonEncode(_sampleUsers()), 200);
    });

    await tester.pumpWidget(_buildTestApp(client));
    await tester.pumpAndSettle();
    expect(loads, 1);

    await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
    await tester.pumpAndSettle();
    expect(loads, 2);
  });

  testWidgets('shows 404 request error view', (tester) async {
    final client404 = MockClient((_) async => http.Response('{}', 404));
    await tester.pumpWidget(_buildTestApp(client404));
    await tester.pumpAndSettle();
    expect(find.text('Not found'), findsOneWidget);
  });

  testWidgets('shows 401 request error view', (tester) async {
    final client401 = MockClient((_) async => http.Response('', 401));
    await tester.pumpWidget(_buildTestApp(client401));
    await tester.pumpAndSettle();
    expect(find.text('Unauthorized'), findsOneWidget);
  });

  testWidgets('shows OfflineView on SocketException and recovers on Retry', (
    tester,
  ) async {
    var attempts = 0;
    final client = MockClient((request) async {
      attempts++;
      if (attempts == 1) {
        throw const SocketException('Failed host lookup');
      }
      return http.Response(jsonEncode(_sampleUsers()), 200);
    });

    await tester.pumpWidget(_buildTestApp(client));
    await tester.pumpAndSettle();

    expect(find.text('No connection'), findsOneWidget);
    expect(find.byKey(const ValueKey('retry-button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('retry-button')));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('Leanne Graham'), findsOneWidget);
  });

  testWidgets('shows ServerErrorView on 503 and GenericErrorView on bad JSON', (
    tester,
  ) async {
    var status = 503;
    final client = MockClient((request) async {
      if (status == 503) {
        return http.Response('unavailable', 503);
      }
      return http.Response('{bad json', 200);
    });

    await tester.pumpWidget(_buildTestApp(client));
    await tester.pumpAndSettle();

    expect(find.text('Server error (503)'), findsOneWidget);
    expect(find.byKey(const ValueKey('retry-button')), findsOneWidget);

    status = 200;
    await tester.tap(find.byKey(const ValueKey('retry-button')));
    await tester.pumpAndSettle();

    expect(find.text('Unexpected response'), findsOneWidget);
    expect(find.byKey(const ValueKey('retry-button')), findsNothing);
  });

  testWidgets(
    'NewUserScreen disables Save while in flight and inserts returned user at top',
    (tester) async {
      var postCount = 0;
      final postCompleter = Completer<http.Response>();

      final client = MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(jsonEncode(_sampleUsers()), 200);
        }
        postCount++;
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        return postCompleter.future.then(
          (_) => http.Response(jsonEncode({...body, 'id': 11}), 201),
        );
      });

      await tester.pumpWidget(_buildTestApp(client));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('add-user-fab')));
      await tester.pumpAndSettle();

      // Validation rejects empty/bad fields.
      await tester.tap(find.byKey(const ValueKey('new-user-save')));
      await tester.pump();
      expect(
        find.text('Name must contain at least 2 characters'),
        findsOneWidget,
      );
      expect(postCount, 0);

      await tester.enterText(
        find.byKey(const ValueKey('new-user-name')),
        'Rassul Tampekov',
      );
      await tester.enterText(
        find.byKey(const ValueKey('new-user-username')),
        'rassul',
      );
      await tester.enterText(
        find.byKey(const ValueKey('new-user-email')),
        'rassul@kbtu.kz',
      );

      // Double tap Save while request is in flight.
      await tester.tap(find.byKey(const ValueKey('new-user-save')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('new-user-save')));
      await tester.pump();

      final saveButton = tester.widget<FilledButton>(
        find.byKey(const ValueKey('new-user-save')),
      );
      expect(saveButton.onPressed, isNull);
      expect(postCount, 1);

      postCompleter.complete(http.Response('', 201));
      await tester.pumpAndSettle();

      // Popped back to list with the newly created user at the top (id 11).
      expect(find.text('New user'), findsOneWidget); // FAB label on UsersScreen
      expect(find.text('Rassul Tampekov'), findsOneWidget);
      expect(find.text('11'), findsOneWidget);
    },
  );

  testWidgets('NewUserScreen shows SnackBar and stays open on 500 error', (
    tester,
  ) async {
    final client = MockClient((request) async {
      if (request.method == 'GET') {
        return http.Response(jsonEncode(_sampleUsers()), 200);
      }
      return http.Response('server error', 500);
    });

    await tester.pumpWidget(_buildTestApp(client));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('add-user-fab')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('new-user-name')),
      'Rassul Tampekov',
    );
    await tester.enterText(
      find.byKey(const ValueKey('new-user-username')),
      'rassul',
    );
    await tester.enterText(
      find.byKey(const ValueKey('new-user-email')),
      'rassul@kbtu.kz',
    );

    await tester.tap(find.byKey(const ValueKey('new-user-save')));
    await tester.pumpAndSettle();

    expect(find.text('Server error (500). Try again.'), findsOneWidget);
    // Form stays open and Save is enabled again.
    expect(find.byKey(const ValueKey('new-user-name')), findsOneWidget);
    final saveButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('new-user-save')),
    );
    expect(saveButton.onPressed, isNotNull);
  });
}
