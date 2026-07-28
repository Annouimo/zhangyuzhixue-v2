# 仓库脚本

稳定入口保留在 `scripts/` 根目录：

- `run_tests.ps1`：学生端、服务端和快速测试入口。
- `run_e2e.bat`、`run_e2e.sh`：端到端测试入口。

其余脚本按职责分类：

- `audit/`：Landing、发布输入和生产只读检查。
- `release/`：版本、Windows 安装包、发布清单、官网和数据包发布。
- `operations/`：生产部署初始化、nginx 和 tunnel 配置。
- `assets/`：应用图标、启动图和颜色资产生成。

脚本移动时必须同步仓库内全部调用方，并至少执行 Python 编译、PowerShell 解析和相关 dry-run。生产脚本默认不得因目录调整改变目标服务器或扩大部署范围。
