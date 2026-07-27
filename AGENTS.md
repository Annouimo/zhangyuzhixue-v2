# Project Agent Instructions

## Flutter SDK on Windows

- The installed Flutter SDK is `D:\Programs\flutter` and the executable is
  `D:\Programs\flutter\bin\flutter.bat`.
- The SDK is outside the writable workspace. Flutter writes cache lock files
  even for commands such as `flutter --version`, so a default sandbox command
  can wait indefinitely without output.
- Do not diagnose that wait as a project test hang first. Run Flutter commands
  with sandbox escalation from the start, using the narrow executable prefix
  `D:\Programs\flutter\bin\flutter.bat`.
- Use `--no-version-check` and set `FLUTTER_SUPPRESS_ANALYTICS=true` for automated
  local runs to avoid unrelated startup work.
- Never start multiple Flutter commands concurrently. The Flutter tool shares an
  SDK lock; run student, teacher, and integration tests serially.
- Prefer the repository runner for normal test suites:
  `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\run_tests.ps1`.
  A Codex shell invocation of this runner still needs sandbox escalation because
  it launches the SDK outside the workspace.
- Windows integration tests must explicitly select the desktop target with
  `-d windows`.
- After a tool timeout, identify processes by executable path, start time, and
  window handle. Stop only processes started by that test command. Do not stop a
  visible student or teacher application that may belong to the user.

Recommended environment probe:

```powershell
$env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
D:\Programs\flutter\bin\flutter.bat --no-version-check --version
```

Recommended minimal project probe:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\run_tests.ps1 -Suite Quick
```

## Sandbox and Tooling Baseline

- The repository is owned by the interactive Windows user, while sandboxed
  commands run as a different account. Plain Git commands can report dubious
  ownership. Use:
  `git -c safe.directory=D:/Hermes/zhangyuzhixue_app_v2 <command>`.
  Do not change the user's global Git configuration merely to avoid this error.
- The project Python command resolves to the Hermes agent Python 3.11
  environment and has the Django test dependencies installed. Use the repository
  test runner for pytest; it redirects pytest cache writes to
  `.hermes/tmp/pytest-cache` because the existing `server/.pytest_cache` is not
  writable by the sandbox account.
- `server/.env` contains local secrets. Its presence may be checked, but never
  print or include its contents in logs or responses.
- Node is not on the ordinary sandbox `PATH`. When Node tooling is actually
  needed, call `codex_app__load_workspace_dependencies` and use the returned
  bundled Node and pnpm paths. The current `landing` site is static and can be
  served with `python -m http.server`; it does not require npm.
- CMake and Ninja are not on the ordinary `PATH`, but the installed Visual
  Studio toolchain is healthy and Flutter locates them correctly. Do not report
  them missing based only on `Get-Command`. Verify Windows builds through
  Flutter.
- Windows build infrastructure verified on 2026-07-27:
  Visual Studio Community 2022 17.14.35, Windows SDK 10.0.26100.0, and a
  successful student Debug build.
- Android infrastructure is installed and healthy: Android SDK 36 and Java 17.
  No Android device was connected during the baseline check. iOS builds cannot
  be performed on this Windows host.
- Inno Setup is installed outside `PATH` at
  `D:\Programs\Inno Setup 7\ISCC.exe`. Use that exact path for the `.iss` files
  under `docs\07-工作流`. Packaging commands may need sandbox escalation because
  the compiler and its temporary paths are outside the workspace. The compiler
  command was verified on 2026-07-27.
- GitHub CLI (`gh`) is not installed. Use Git directly for local operations. If
  a future task specifically requires GitHub CLI, report the missing tool before
  proposing installation or use an available repository connector.
- Network access from the default sandbox is restricted. Dependency downloads,
  remote Git operations, Flutter Doctor, Flutter builds, and similar commands
  should be retried with narrowly scoped sandbox escalation when a network or
  external-cache failure occurs.
- Browser or Windows computer-control operations can take the foreground. Tell
  the user immediately before using them and wait for coordination; ordinary
  Flutter tests and builds do not require mouse or keyboard control.
- The `landing` directory is a static site. A local smoke server was verified
  with `python -m http.server`; use the in-app browser only when visual or
  interaction inspection is needed.

Verified baseline commands:

```powershell
# Git metadata without changing global configuration
git -c safe.directory=D:/Hermes/zhangyuzhixue_app_v2 status --short

# Student Windows build (run with Flutter sandbox escalation)
D:\Programs\flutter\bin\flutter.bat --no-version-check build windows --debug

# Server tests with writable caches and Flutter suites in serial order
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\run_tests.ps1 -Suite Server
```

## Production Deployment Baseline

- Production server: `root@82.157.115.219`. The old server address
  `81.70.243.63` is retired and must not be used for deployment or audit
  scripts.
- The local Git remote named `server` points to
  `ssh://root@82.157.115.219/opt/zhangyuzhixue-v2.git`. Use the existing
  Windows key `C:\Users\Annouimo\.ssh\id_rsa` through a narrowly scoped
  `GIT_SSH_COMMAND` when the sandbox cannot access the key automatically.
- The production worktree is `/opt/zhangyuzhixue-v2`; its bare repository is
  `/opt/zhangyuzhixue-v2.git`. The service is
  `zhangyuzhixue-web.service`, Gunicorn listens on `127.0.0.1:8001`, and nginx
  terminates TLS and proxies to that port.
- The supported deployment path is `git push server master`. Never use
  `--force` or delete the production branch. The post-receive hook backs up the
  SQLite database, checks out only `server/`, runs migrations and collectstatic,
  restarts Gunicorn, and restores the previous code/database on failure.
- The hook intentionally does not deploy `landing/`, Flutter artifacts, or
  other work-in-progress files. Those require a separately reviewed release
  commit and deployment procedure.
- Production `server/.env` exists only on the server. Never create, print, or
  upload it from the local workspace. Required non-secret settings include
  `ENVIRONMENT=production`, `DEBUG=False`, `SECURE_SSL_REDIRECT=False`, and
  `SECURE_HSTS_SECONDS=3600`; verify secret presence/length without printing
  values.
- Before any production mutation, perform read-only checks and verify a recent
  backup. SQLite backups must use the Online Backup API because the database
  runs in WAL mode. Backups are stored under
  `/var/backups/zhangyuzhixue-v2/db/`; pre-deploy snapshots are under
  `/var/backups/zhangyuzhixue-v2/pre-deploy/`.
- Ubuntu cron jobs run database backup at 04:00, data export at 04:10, and
  deleted-account anonymization at 04:20. The anonymization command is
  `python manage.py anonymize_deleted_accounts`.
- For migration or data-repair changes, first run the migration against a copy
  of the production database in a fixed `/tmp` shadow directory and check both
  `PRAGMA integrity_check` and `PRAGMA foreign_key_check`. Do not hand-edit
  production SQLite data when a reversible Django migration is possible.
- A successful deployment must verify the Gunicorn service, local port 8001,
  both public HTTPS domains, applied migrations, and database foreign-key
  integrity. Expected remaining `check --deploy` warnings are the deliberate
  proxy/HSTS policy choices and existing OpenAPI schema warnings.
