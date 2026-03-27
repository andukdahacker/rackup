import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rackup/core/config/app_config.dart';
import 'package:rackup/core/routing/app_router.dart';
import 'package:rackup/core/services/device_identity_service.dart';
import 'package:rackup/core/services/room_api_service.dart';
import 'package:rackup/features/lobby/view/join_room_page.dart';

class MockDeviceIdentityService extends Mock
    implements DeviceIdentityService {}

class MockRoomApiService extends Mock implements RoomApiService {}

class MockAppConfig extends Mock implements AppConfig {}

void main() {
  late MockDeviceIdentityService mockDeviceIdentityService;
  late MockRoomApiService mockRoomApiService;
  late MockAppConfig mockAppConfig;

  setUp(() {
    mockDeviceIdentityService = MockDeviceIdentityService();
    mockRoomApiService = MockRoomApiService();
    mockAppConfig = MockAppConfig();
    when(() => mockAppConfig.apiBaseUrl).thenReturn('http://localhost:3000');
    when(() => mockAppConfig.wsBaseUrl).thenReturn('ws://localhost:3000');
  });

  Widget buildApp() {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AppConfig>.value(value: mockAppConfig),
        RepositoryProvider<DeviceIdentityService>.value(
          value: mockDeviceIdentityService,
        ),
        RepositoryProvider<RoomApiService>.value(
          value: mockRoomApiService,
        ),
      ],
      child: MaterialApp.router(
        routerConfig: appRouter,
      ),
    );
  }

  group('AppRouter', () {
    testWidgets('/join/:code route passes initialCode to JoinRoomPage',
        (tester) async {
      appRouter.go('/join/ABCD');
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Verify JoinRoomPage is rendered with pre-filled code heading.
      expect(find.text('Join via Link'), findsOneWidget);
    });

    testWidgets('/join route passes null initialCode', (tester) async {
      appRouter.go('/join');
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Verify JoinRoomPage is rendered with manual entry heading.
      expect(find.text('Enter Room Code'), findsOneWidget);
    });

    testWidgets('/join/:code handles lowercase code', (tester) async {
      appRouter.go('/join/abcd');
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Verify the page renders — router passes lowercase,
      // JoinRoomPage uppercases it.
      expect(find.text('Join via Link'), findsOneWidget);
    });

    testWidgets('/join/:code with single character falls back to manual entry',
        (tester) async {
      appRouter.go('/join/A');
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Invalid code length — ignored, shows manual entry.
      expect(find.text('Enter Room Code'), findsOneWidget);
    });

    testWidgets('/join/:code with numeric code falls back to manual entry',
        (tester) async {
      appRouter.go('/join/1234');
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Non-alpha code — ignored, shows manual entry.
      expect(find.text('Enter Room Code'), findsOneWidget);
    });

    testWidgets('/join/:code with overly long code falls back to manual entry',
        (tester) async {
      appRouter.go('/join/ABCDEFGH');
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Too long — ignored, shows manual entry.
      expect(find.text('Enter Room Code'), findsOneWidget);
    });
  });
}
