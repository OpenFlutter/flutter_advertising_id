import 'package:advertising_id_flutter/flutter_advertising_id.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _plugin = AdvertisingId();
  String _id = '尚未读取';
  String _status = '尚未查询';
  String? _error;

  Future<void> _readId([bool request = false]) async {
    try {
      final id = await _plugin.getAdvertisingId(request);
      if (!mounted) return;
      setState(() {
        _id = id ?? '不可用（未授权或无有效 ID）';
        _error = null;
      });
    } on PlatformException catch (error) {
      if (mounted) setState(() => _error = error.code);
    }
  }

  Future<void> _queryStatus() async {
    try {
      final status = await _plugin.authorizationStatus;
      final limited = await _plugin.limitAdTrackingEnabled;
      if (!mounted) return;
      setState(() {
        _status = '${status.name}；限制跟踪：$limited';
        _error = null;
      });
    } on PlatformException catch (error) {
      if (mounted) setState(() => _error = error.code);
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: const Text('Advertising ID')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('广告 ID：$_id'),
          Text('授权状态：$_status'),
          if (_error != null) Text('错误：$_error'),
          ElevatedButton(
            onPressed: () => _readId(),
            child: const Text('读取 ID（不申请）'),
          ),
          ElevatedButton(
            onPressed: () => _readId(true),
            child: const Text('申请授权并读取'),
          ),
          ElevatedButton(onPressed: _queryStatus, child: const Text('查询状态')),
        ],
      ),
    ),
  );
}
