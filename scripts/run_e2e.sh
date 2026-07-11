#!/bin/bash
# 一键运行 E2E 测试（需要连接模拟器或真机）
cd "$(dirname "$0")/../flutter_app"
flutter test integration_test/ -v
