import 'package:advertising_id_flutter/flutter_advertising_id.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Exercise the public API through the real channel adapter. Only the native
// system boundary is mocked; these tests do not run HarmonyOS permission UI.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dev.openflutter/flutter_advertising_id');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final advertisingId = AdvertisingId();

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  for (final limited in <bool?>[true, false, null]) {
    test(
      'tracking restriction query preserves $limited without requesting authorization',
      () async {
        MethodCall? received;
        messenger.setMockMethodCallHandler(channel, (call) async {
          received = call;
          return limited;
        });

        expect(await advertisingId.limitAdTrackingEnabled, limited);
        expect(received!.method, 'limitAdTrackingEnabled');
        expect(received!.arguments, isNull);
      },
    );
  }

  const statuses = <int, AdTrackingAuthorizationStatus>{
    0: AdTrackingAuthorizationStatus.notDetermined,
    1: AdTrackingAuthorizationStatus.restricted,
    2: AdTrackingAuthorizationStatus.denied,
    3: AdTrackingAuthorizationStatus.authorized,
  };
  for (final entry in statuses.entries) {
    test(
      'native status ${entry.key} is exposed as ${entry.value.name}',
      () async {
        MethodCall? received;
        messenger.setMockMethodCallHandler(channel, (call) async {
          received = call;
          return entry.key;
        });

        expect(await advertisingId.authorizationStatus, entry.value);
        expect(received!.method, 'authorizationStatus');
        expect(received!.arguments, isNull);
      },
    );
  }

  for (final status in <int?>[4, null]) {
    test(
      'invalid native authorization status $status is reported as an error',
      () async {
        messenger.setMockMethodCallHandler(channel, (_) async => status);

        await expectLater(advertisingId.authorizationStatus, throwsException);
      },
    );
  }

  final operations = <String, Future<Object?> Function()>{
    'getAdvertisingId': () => advertisingId.getAdvertisingId(),
    'limitAdTrackingEnabled': () => advertisingId.limitAdTrackingEnabled,
    'authorizationStatus': () => advertisingId.authorizationStatus,
  };
  for (final operation in operations.entries) {
    test('${operation.key} preserves native error details', () async {
      messenger.setMockMethodCallHandler(channel, (_) async {
        throw PlatformException(
          code: 'PERMISSION_ERROR',
          message: 'Permission lookup failed',
          details: <String, Object>{'nativeCode': 123},
        );
      });

      await expectLater(
        operation.value(),
        throwsA(
          isA<PlatformException>()
              .having((error) => error.code, 'code', 'PERMISSION_ERROR')
              .having(
                (error) => error.message,
                'message',
                'Permission lookup failed',
              )
              .having((error) => error.details, 'details', <String, Object>{
                'nativeCode': 123,
              }),
        ),
      );
    });
  }
}
