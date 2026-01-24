#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$ROOT/Culler/Culler.xcodeproj"
SCHEME="CullerE2E"

DERIVED_DATA="${DERIVED_DATA:-$ROOT/.derivedData-e2e}"
RESULT_BUNDLE="${RESULT_BUNDLE:-$ROOT/.xcresult-e2e}"

rm -rf "$DERIVED_DATA" "$RESULT_BUNDLE"

echo "[1/3] Build $SCHEME"
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -derivedDataPath "$DERIVED_DATA" \
  -quiet \
  build

APP="$DERIVED_DATA/Build/Products/Debug/CullerE2E.app"
BIN="$APP/Contents/MacOS/CullerE2E"

if [[ ! -x "$BIN" ]]; then
  echo "Built app not found: $BIN" >&2
  exit 2
fi

echo "[2/3] Run E2E (App self-check)"
set +e
"$BIN" -e2e -ui-testing-reset -ui-testing >"$ROOT/.e2e.log" 2>&1
EXIT_CODE=$?
set -e

echo "[3/3] Parse results"
if ! rg -n "^E2E_START$" "$ROOT/.e2e.log" >/dev/null 2>&1; then
  echo "E2E did not start (missing E2E_START). Tail of .e2e.log:" >&2
  tail -n 120 "$ROOT/.e2e.log" >&2 || true
  exit 1
fi
if ! rg -n "^E2E_RESULT:PASS$" "$ROOT/.e2e.log" >/dev/null 2>&1; then
  echo "E2E did not report PASS. Tail of .e2e.log:" >&2
  tail -n 120 "$ROOT/.e2e.log" >&2 || true
  exit 1
fi
if [[ $EXIT_CODE -ne 0 ]]; then
  echo "E2E run failed (exit $EXIT_CODE). Tail of .e2e.log:" >&2
  tail -n 80 "$ROOT/.e2e.log" >&2
  exit $EXIT_CODE
fi

echo "E2E run succeeded. Tail of .e2e.log:"
tail -n 40 "$ROOT/.e2e.log"
