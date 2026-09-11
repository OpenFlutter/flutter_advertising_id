import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_advertising_id_example/main.dart';

void main() {
  const channel = MethodChannel('dev.openflutter/flutter_advertising_id');
  final calls = <MethodCall>[];
  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  testWidgets('reading without consent does not request authorization', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    expect(calls, isEmpty);
    await tester.tap(find.text('读取 ID（不申请）'));
    await tester.pumpAndSettle();
    expect(calls.single.method, 'getAdvertisingId');
    expect(calls.single.arguments, false);
    expect(find.text('广告 ID：不可用（未授权或无有效 ID）'), findsOneWidget);
  });
  testWidgets('explicit authorization button sends true', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('申请授权并读取'));
    await tester.pumpAndSettle();
    expect(calls.single.method, 'getAdvertisingId');
    expect(calls.single.arguments, true);
  });

  testWidgets('status query displays restriction without requesting ID', (
    tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return call.method == 'authorizationStatus' ? 2 : true;
        });
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('查询状态'));
    await tester.pumpAndSettle();
    expect(calls.map((call) => call.method), [
      'authorizationStatus',
      'limitAdTrackingEnabled',
    ]);
    expect(find.text('授权状态：denied；限制跟踪：true'), findsOneWidget);
  });
  testWidgets('native error is visible to the user', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
          throw PlatformException(
            code: 'NO_ACTIVITY',
            message: 'No foreground ability',
          );
        });
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('申请授权并读取'));
    await tester.pumpAndSettle();
    expect(find.text('错误：NO_ACTIVITY'), findsOneWidget);
  });
}
