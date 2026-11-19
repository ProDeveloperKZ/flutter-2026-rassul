import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:users_api/features/users/user.dart';

const String _user1Json = r'''
{
  "id": 1,
  "name": "Leanne Graham",
  "username": "Bret",
  "email": "Sincere@april.biz",
  "address": {
    "street": "Kulas Light",
    "suite": "Apt. 556",
    "city": "Gwenborough",
    "zipcode": "92998-3874",
    "geo": {
      "lat": "-37.3159",
      "lng": "81.1496"
    }
  },
  "phone": "1-770-736-8031 x56442",
  "website": "hildegard.org",
  "company": {
    "name": "Romaguera-Crona",
    "catchPhrase": "Multi-layered client-server neural-net",
    "bs": "harness real-time e-markets"
  }
}
''';

void main() {
  group('User / Address / Geo JSON serialization', () {
    test('parses real user 1 JSON and round-trips through toJson', () {
      final decoded = jsonDecode(_user1Json) as Map<String, dynamic>;
      final user = User.fromJson(decoded);

      expect(user.id, 1);
      expect(user.name, 'Leanne Graham');
      expect(user.username, 'Bret');
      expect(user.email, 'Sincere@april.biz');
      expect(user.phone, '1-770-736-8031 x56442');
      expect(user.phoneDigits, '1770736803156442');
      expect(user.website, 'hildegard.org');
      expect(user.address.city, 'Gwenborough');
      expect(user.address.geo.lat, -37.3159);
      expect(user.address.geo.lng, 81.1496);
      expect(user.company.name, 'Romaguera-Crona');
      expect(
        user.company.catchPhrase,
        'Multi-layered client-server neural-net',
      );

      final roundTripped = User.fromJson(user.toJson());
      expect(roundTripped, equals(user));
      expect(roundTripped.name, user.name);
      expect(roundTripped.username, user.username);
      expect(roundTripped.email, user.email);
      expect(roundTripped.phone, user.phone);
      expect(roundTripped.website, user.website);
      expect(roundTripped.address, user.address);
      expect(roundTripped.company, user.company);
    });

    test('phoneDigits preserves + and digits only', () {
      final map = jsonDecode(_user1Json) as Map<String, dynamic>;
      map['phone'] = '+7 (700) 123-45-67 ext. 9';
      final user = User.fromJson(map);
      expect(user.phoneDigits, '+770012345679');
    });

    test('allows website to be null or omitted', () {
      final map = jsonDecode(_user1Json) as Map<String, dynamic>;
      map.remove('website');
      final userWithoutKey = User.fromJson(map);
      expect(userWithoutKey.website, isNull);

      map['website'] = null;
      final userWithNull = User.fromJson(map);
      expect(userWithNull.website, isNull);
    });

    test('equality and hashCode compare by id only', () {
      final map1 = jsonDecode(_user1Json) as Map<String, dynamic>;
      final map2 = jsonDecode(_user1Json) as Map<String, dynamic>;
      map2['name'] = 'Renamed User';

      final u1 = User.fromJson(map1);
      final u2 = User.fromJson(map2);
      expect(u1, equals(u2));
      expect(u1.hashCode, equals(u2.hashCode));
    });

    test('throws TypeError when id is a String instead of int', () {
      final map = jsonDecode(_user1Json) as Map<String, dynamic>;
      map['id'] = '1';
      expect(() => User.fromJson(map), throwsA(isA<TypeError>()));
    });

    test('throws FormatException when geo lat is not a parseable number', () {
      final map = jsonDecode(_user1Json) as Map<String, dynamic>;
      (map['address'] as Map<String, dynamic>)['geo'] = {
        'lat': 'not-a-double',
        'lng': '81.1496',
      };
      expect(() => User.fromJson(map), throwsA(isA<FormatException>()));
    });
  });
}
