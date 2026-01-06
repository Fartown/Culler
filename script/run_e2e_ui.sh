#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$ROOT/Culler/Culler.xcodeproj"
SCHEME="Culler"

DERIVED_DATA="${DERIVED_DATA:-$ROOT/.derivedData-e2e-ui}"

rm -rf "$DERIVED_DATA"

echo "[1/2] Build $SCHEME"
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -derivedDataPath "$DERIVED_DATA" \
  -quiet \
  build

APP="$DERIVED_DATA/Build/Products/Debug/Culler.app"
BIN="$APP/Contents/MacOS/Culler"

if [[ ! -x "$BIN" ]]; then
  echo "Built app not found: $BIN" >&2
  exit 2
fi

echo "[2/2] Run E2E UI (visible app launch)"
set +e
E2E_UI_PAUSE_SECONDS="${E2E_UI_PAUSE_SECONDS:-2}" "$BIN" -e2e-ui -ui-testing-reset -ui-testing >"$ROOT/.e2e-ui.log" 2>&1
EXIT_CODE=$?
set -e

if ! rg -n "^E2E_START$" "$ROOT/.e2e-ui.log" >/dev/null 2>&1; then
  echo "E2E UI did not start (missing E2E_START). Tail of .e2e-ui.log:" >&2
  tail -n 120 "$ROOT/.e2e-ui.log" >&2 || true
  exit 1
fi
if ! rg -n "^E2E_RESULT:PASS$" "$ROOT/.e2e-ui.log" >/dev/null 2>&1; then
  echo "E2E UI did not report PASS. Tail of .e2e-ui.log:" >&2
  tail -n 120 "$ROOT/.e2e-ui.log" >&2 || true
  exit 1
fi
if [[ $EXIT_CODE -ne 0 ]]; then
  echo "E2E UI run failed (exit $EXIT_CODE). Tail of .e2e-ui.log:" >&2
  tail -n 80 "$ROOT/.e2e-ui.log" >&2
  exit $EXIT_CODE
fi

echo "E2E UI run succeeded. Tail of .e2e-ui.log:"
tail -n 40 "$ROOT/.e2e-ui.log"
