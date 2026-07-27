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
