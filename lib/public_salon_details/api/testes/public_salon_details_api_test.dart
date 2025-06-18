// test/api/public_salon_details_api_test_simple.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

import '../PublicSalonDetailsApi.dart';

void main() {
  group('PublicSalonDetailsApi Simple Tests', () {
    test('getSalonDetails - success case', () async {
      // Arrange
      final mockResponse = {
        'id': 123,
        'name': 'Test Salon',
        'description': 'Un salon de test',
        'address': '123 Rue Test',
        'images': [],
        'services': []
      };

      final client = MockClient((request) async {
        return http.Response(json.encode(mockResponse), 200);
      });

      // Act
      var result;
      await http.runWithClient(() async {
        result = await PublicSalonDetailsApi.getSalonDetails(123);
      }, () => client);

      // Assert
      expect(result, isNotNull);
    });

    test('getSalonDetails - 404 error', () async {
      final client = MockClient((request) async {
        return http.Response('Not found', 404);
      });

      expect(() async {
        await http.runWithClient(() async {
          await PublicSalonDetailsApi.getSalonDetails(123);
        }, () => client);
      }, throwsException);
    });

    test('getSalonDetails - invalid JSON', () async {
      final client = MockClient((request) async {
        return http.Response('invalid json', 200);
      });

      expect(() async {
        await http.runWithClient(() async {
          await PublicSalonDetailsApi.getSalonDetails(123);
        }, () => client);
      }, throwsException);
    });
  });
}