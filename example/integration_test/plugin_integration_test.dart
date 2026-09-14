import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:advertising_id_flutter/flutter_advertising_id.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('advertising ID may be unavailable without authorization', (
    tester,
  ) async {
    final plugin = AdvertisingId();
    final id = await plugin.getAdvertisingId(false);
    expect(id, anyOf(isNull, isNotEmpty));
    expect(
      await plugin.authorizationStatus,
      isA<AdTrackingAuthorizationStatus>(),
    );
    expect(await plugin.limitAdTrackingEnabled, anyOf(isNull, isA<bool>()));
  });
}
