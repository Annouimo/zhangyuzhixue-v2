import 'package:flutter/material.dart';

void main() {
  runApp(const ZhangyuzhixueApp());
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
