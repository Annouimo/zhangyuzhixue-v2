import 'package:flutter/material.dart';
import 'package:flutter_app/data/api/api_client.dart';
import 'package:flutter_app/data/api/sync_api.dart';
import 'package:flutter_app/data/database/database_provider.dart';
import 'package:flutter_app/data/network/connectivity_monitor.dart';
import 'package:flutter_app/data/prefs/app_prefs.dart';
import 'package:flutter_app/data/daos/sync_queue_dao.dart';
import 'package:flutter_app/data/sync/sync_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppPrefs().init();
  ApiClient().init(baseUrl: 'https://zhangyuzhixue.top/api/v1/');
  await DatabaseProvider().init();
  ConnectivityMonitor().init();

  final syncApi = SyncApi(ApiClient());
  SyncManager().init(
    SyncQueueDao(DatabaseProvider().appDb),
    syncApi,
    DatabaseProvider(),
  );

  runApp(const ZhangyuzhixueApp());

  // 启动后推送积压（不阻塞首帧）
  SyncManager().onAppStart();
}

class ZhangyuzhixueApp extends StatelessWidget {
  const ZhangyuzhixueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '章鱼智学',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('章鱼智学 v2'),
        ),
      ),
    );
  }
}
