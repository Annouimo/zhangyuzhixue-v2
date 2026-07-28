# 开发与测试

最后核验：2026-07-28

## 常用入口

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\run_tests.ps1 -Suite Quick
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\run_tests.ps1 -Suite Student
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\run_tests.ps1 -Suite Server
```

Flutter SDK 位于 `D:\Programs\flutter`。Flutter 命令必须串行运行，避免争用 SDK 锁。

修改 Drift 表后，在 `flutter_app` 运行：

```powershell
D:\Programs\flutter\bin\flutter.bat --no-version-check pub run build_runner build
```

修改 Django 模型后必须生成迁移，并通过服务端 migration check 和 pytest。不要提交 `.env`、本地数据库、构建目录或 Flutter 临时目录。
