// test/api/favorites_api_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

import '../favorites_api.dart';

void main() {
  group('FavoritesApi Tests', () {
    test('getUserFavorites - success', () async {
      final mockResponse = [
        {'id': 1, 'user': 123, 'salon': 456},
        {'id': 2, 'user': 123, 'salon': 789}
      ];

      final client = MockClient((request) async {
        // Vérifie que l'URL contient la bonne route
        if (request.url.toString().contains('get_user_favorites') &&
            request.url.toString().contains('user=123')) {
          return http.Response(json.encode(mockResponse), 200);
        }
        return http.Response('Not found', 404);
      });

      var result;
      await http.runWithClient(() async {
        result = await FavoritesApi.getUserFavorites(123);
      }, () => client);

      expect(result, isNotNull);
      expect(result, isList);
    });

    test('getUserFavorites - error', () async {
      final client = MockClient((request) async {
        return http.Response('Error', 400);
      });

      expect(() async {
        await http.runWithClient(() async {
          await FavoritesApi.getUserFavorites(123);
        }, () => client);
      }, throwsException);
    });

    test('addToFavorites - success', () async {
      final mockResponse = {'id': 1, 'user': 123, 'salon': 456};

      final client = MockClient((request) async {
        if (request.url.toString().contains('favorites/add') &&
            request.method == 'POST') {
          return http.Response(json.encode(mockResponse), 201);
        }
        return http.Response('Error', 400);
      });

      var result;
      await http.runWithClient(() async {
        result = await FavoritesApi.addToFavorites(123, 456);
      }, () => client);

      expect(result, isNotNull);
    });

    test('checkFavorite - not found', () async {
      final client = MockClient((request) async {
        if (request.url.toString().contains('check_favorite')) {
          return http.Response('Not found', 404);
        }
        return http.Response('Error', 400);
      });

      var result;
      await http.runWithClient(() async {
        result = await FavoritesApi.checkFavorite(123, 456);
      }, () => client);

      expect(result, isNull);
    });

    test('checkFavorite - found', () async {
      final mockResponse = {'id': 1, 'user': 123, 'salon': 456};

      final client = MockClient((request) async {
        if (request.url.toString().contains('check_favorite')) {
          return http.Response(json.encode(mockResponse), 200);
        }
        return http.Response('Error', 400);
      });

      var result;
      await http.runWithClient(() async {
        result = await FavoritesApi.checkFavorite(123, 456);
      }, () => client);

      expect(result, isNotNull);
    });

    test('removeFavorite - success', () async {
      final client = MockClient((request) async {
        if (request.url.toString().contains('favorites/remove') &&
            request.method == 'DELETE') {
          return http.Response('', 204);
        }
        return http.Response('Error', 400);
      });

      var result;
      await http.runWithClient(() async {
        result = await FavoritesApi.removeFavorite(1);
      }, () => client);

      expect(result, isTrue);
    });

    test('removeFavorite - error', () async {
      final client = MockClient((request) async {
        return http.Response('Error', 400);
      });

      expect(() async {
        await http.runWithClient(() async {
          await FavoritesApi.removeFavorite(1);
        }, () => client);
      }, throwsException);
    });
  });
}