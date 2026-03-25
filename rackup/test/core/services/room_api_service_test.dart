import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rackup/core/services/room_api_service.dart';

void main() {
  group('RoomApiService', () {
    test('createRoom returns CreateRoomResponse on 201', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), 'http://localhost:8080/rooms');
        expect(request.method, 'POST');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['deviceIdHash'], 'test-hash');

        return http.Response(
          jsonEncode({'roomCode': 'WXYZ', 'jwt': 'test-jwt-token'}),
          201,
        );
      });

      final service = RoomApiService(
        apiBaseUrl: 'http://localhost:8080',
        client: mockClient,
      );

      final response = await service.createRoom('test-hash');
      expect(response.roomCode, 'WXYZ');
      expect(response.jwt, 'test-jwt-token');
    });

    test('createRoom throws RoomApiException on 400', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'action': 'error',
            'payload': {
              'code': 'INVALID_REQUEST',
              'message': 'deviceIdHash is required',
            },
          }),
          400,
        );
      });

      final service = RoomApiService(
        apiBaseUrl: 'http://localhost:8080',
        client: mockClient,
      );

      expect(
        () => service.createRoom(''),
        throwsA(
          isA<RoomApiException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having(
                (e) => e.message,
                'message',
                'deviceIdHash is required',
              ),
        ),
      );
    });

    test('createRoom throws RoomApiException on 503', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'action': 'error',
            'payload': {
              'code': 'CAPACITY_EXCEEDED',
              'message': 'Server at capacity',
            },
          }),
          503,
        );
      });

      final service = RoomApiService(
        apiBaseUrl: 'http://localhost:8080',
        client: mockClient,
      );

      expect(
        () => service.createRoom('test-hash'),
        throwsA(
          isA<RoomApiException>()
              .having((e) => e.statusCode, 'statusCode', 503),
        ),
      );
    });

    test('createRoom handles non-JSON error response', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = RoomApiService(
        apiBaseUrl: 'http://localhost:8080',
        client: mockClient,
      );

      expect(
        () => service.createRoom('test-hash'),
        throwsA(
          isA<RoomApiException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having(
                (e) => e.message,
                'message',
                'Server error (500)',
              ),
        ),
      );
    });
  });
}
