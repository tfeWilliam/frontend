// test/api/gallery_api_simple_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

import '../gallery_api.dart';

void main() {
  group('GalleryApi Simple Tests', () {
    test('getSalonImages - success', () async {
      final mockResponse = [
        {'id': 1, 'image': 'https://example.com/image1.jpg'},
        {'id': 2, 'image': 'https://example.com/image2.jpg'}
      ];

      final client = MockClient((request) async {
        return http.Response(json.encode(mockResponse), 200);
      });

      var result;
      await http.runWithClient(() async {
        result = await GalleryApi.getSalonImages(123);
      }, () => client);

      expect(result, isNotNull);
      expect(result, isList);
    });

    test('getSalonImages - error', () async {
      final client = MockClient((request) async {
        return http.Response('Error', 400);
      });

      expect(() async {
        await http.runWithClient(() async {
          await GalleryApi.getSalonImages(123);
        }, () => client);
      }, throwsException);
    });

    test('deleteImage - success', () async {
      final client = MockClient((request) async {
        return http.Response('', 204);
      });

      var result;
      await http.runWithClient(() async {
        result = await GalleryApi.deleteImage(1);
      }, () => client);

      expect(result, isTrue);
    });

    test('deleteImage - error', () async {
      final client = MockClient((request) async {
        return http.Response('Error', 400);
      });

      expect(() async {
        await http.runWithClient(() async {
          await GalleryApi.deleteImage(1);
        }, () => client);
      }, throwsException);
    });

    // Tests pour les cas simples seulement
    test('uploadImages - basic call', () {
      // Test juste que la méthode existe et accepte les paramètres
      expect(() => GalleryApi.uploadImages(123, []), returnsNormally);
    });

    test('uploadImagesForWeb - basic call', () {
      final webFile = http.MultipartFile.fromBytes(
        'image', [1, 2, 3, 4], filename: 'test.jpg',
      );

      expect(() => GalleryApi.uploadImagesForWeb(123, [webFile]),
          returnsNormally);
    });
  });
}