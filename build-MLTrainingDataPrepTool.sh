#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

xcodebuild build \
  -project Driveline.xcodeproj \
  -scheme MLTrainingDataPrepTool \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath build \
  CLANG_ENABLE_CODE_COVERAGE=NO \
  SWIFT_ENABLE_TESTABILITY=NO

mkdir -p ~/bin
cp build/Build/Products/Release/MLTrainingDataPrepTool ~/bin/MLTrainingDataPrepTool
rm -rf build

echo "Installed to ~/bin/MLTrainingDataPrepTool"
