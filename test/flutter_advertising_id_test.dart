import 'package:advertising_id_flutter/flutter_advertising_id.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dev.openflutter/flutter_advertising_id');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final advertisingId = AdvertisingId();

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test(
    'reading an ID defaults to not requesting tracking authorization',
    () async {
      MethodCall? received;
      messenger.setMockMethodCallHandler(channel, (call) async {
        received = call;
        return 'test-oaid';
      });

      expect(await advertisingId.getAdvertisingId(), 'test-oaid');
      expect(received!.method, 'getAdvertisingId');
      expect(received!.arguments, false);
    },
  );

  test('caller can explicitly request tracking authorization', () async {
    MethodCall? received;
    messenger.setMockMethodCallHandler(channel, (call) async {
      received = call;
      return 'test-oaid';
    });

    expect(await advertisingId.getAdvertisingId(true), 'test-oaid');
    expect(received!.method, 'getAdvertisingId');
    expect(received!.arguments, true);
  });

  test('an unavailable advertising ID remains null', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => null);

    expect(await advertisingId.getAdvertisingId(false), isNull);
  });
}
