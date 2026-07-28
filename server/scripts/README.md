# 服务端脚本

本目录保留与 Django、生产 hook 和服务器 cron 紧密耦合的脚本，避免为了目录外观改变已验证的生产路径。

- `build_*.py`、`release_db_bundle.py`：题库和讲义数据包构建发布。
- `dump_data.py`、`load_data.py`、`backup_db.sh`：业务数据导出与备份。
- `deploy_*.sh`、`post-receive.prod`、`pre-receive.prod`：生产部署。
- `drill_*.sh`：恢复和回滚演练。
- `fixes/`：一次性、可审查的数据修复逻辑。
- `tests/`：构建和发布脚本测试。

迁移或修复生产数据前，先在生产数据库副本上运行并检查 SQLite `integrity_check` 与 `foreign_key_check`。
