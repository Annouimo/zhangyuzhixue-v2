#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# Non-Windows compatibility entry. Windows acceptance uses run_tests.ps1,
# which explicitly selects the Windows desktop device.
cd "$(dirname "$0")/../flutter_app"
flutter --no-version-check test integration_test/windows_smoke_test.dart \
  --tags integration --reporter expanded --timeout 5m
