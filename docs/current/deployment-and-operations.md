# 发布与运维

最后核验：2026-07-28

## 服务端

生产服务器为 `root@82.157.115.219`，受支持的服务端部署入口是：

```powershell
git push server master
```

post-receive hook 只部署 `server/`，执行数据库备份、迁移、静态文件收集和 Gunicorn 重启。部署前后必须检查数据库完整性、服务、端口和公网 HTTPS。

## 官网

官网位于 `landing/`，不随服务端 hook 部署。使用 `scripts/release/deploy_landing.ps1` 的独立审核流程。

## 学生端

Windows 构建入口为 `scripts/release/build_windows_release.ps1`，安装脚本为 `scripts/release/windows_installer.iss`。版本和发布清单由同目录脚本管理。

## 数据包

题库和讲义数据包由 `server/scripts/build_assets.py`、`server/scripts/build_courses.py` 构建，发布前执行完整性、版本和 manifest 审计。
