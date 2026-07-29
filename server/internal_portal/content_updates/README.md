# 工作手册内容更新

内容文件使用 TOML 格式，通过 Django 管理命令预览或应用。所有命令均从
`server` 目录执行。

```powershell
python manage.py update_handbook `
  --file internal_portal/content_updates/2026-07-communication.toml `
  --check

python manage.py update_handbook `
  --file internal_portal/content_updates/2026-07-communication.toml `
  --apply `
  --actor <用户名>
```

未指定 `--apply` 时也只进行预览。预览在事务内执行完整校验后回滚，因此可以
验证同一文件中相互依赖的新章节和新条目。

支持的顶层列表为 `areas`、`sections`、`entries` 和 `updates`。章节通过项目
板块 `area` 与章节 `key` 定位；条目通过 `area` 与稳定 `key` 定位。删除必须
显式设置 `action = "delete"`，隐藏内容应设置 `is_visible = false`。

应用模式必须通过 `--actor` 指定一个现有的有效用户。命令逐对象保存或删除，
由项目现有的 django-auditlog 记录字段变化、执行时间和执行人。
