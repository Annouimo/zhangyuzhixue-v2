/// 测试全局钩子：将 FlutterError 转为测试失败
///
/// 在 widget test 文件的 main() 中调用：
/// ```dart
/// import '../test_setup.dart';
/// // ...
/// void main() {
///   setUp(() => setupTestHooks());
///   // ...
/// }
/// ```
library;
import 'package:flutter/foundation.dart';

void setupTestHooks() {
  FlutterError.onError = (details) => throw details.exception;
}
