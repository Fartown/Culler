#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/Culler/Culler.xcodeproj"
SCHEME="Culler"

OUT_DIR="${1:-$ROOT_DIR/artifacts/e2e}"
DERIVED_DATA="$OUT_DIR/DerivedData"
RESULT_BUNDLE="$OUT_DIR/TestResults.xcresult"
ATTACHMENTS_DIR="$OUT_DIR/screenshots"
export ATTACHMENTS_DIR

mkdir -p "$OUT_DIR"
rm -rf "$DERIVED_DATA" "$RESULT_BUNDLE" "$ATTACHMENTS_DIR"

echo "[E2E] project: $PROJECT_PATH"
echo "[E2E] scheme:  $SCHEME"
echo "[E2E] out:     $OUT_DIR"

set -o pipefail

xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination "platform=macOS" \
  -derivedDataPath "$DERIVED_DATA" \
  -resultBundlePath "$RESULT_BUNDLE" \
  test | tee "$OUT_DIR/xcodebuild.log"

mkdir -p "$ATTACHMENTS_DIR"
xcrun xcresulttool export attachments \
  --path "$RESULT_BUNDLE" \
  --output-path "$ATTACHMENTS_DIR" >/dev/null

# 把导出的 UUID 文件名重命名为更可读的截图名（优先用 suggestedHumanReadableName）
if [[ -f "$ATTACHMENTS_DIR/manifest.json" ]]; then
  python3 - <<'PY'
import json
import os
from pathlib import Path

base = Path(os.environ["ATTACHMENTS_DIR"])
manifest = json.loads((base / "manifest.json").read_text())
for entry in manifest:
    for a in entry.get("attachments", []):
        exported = a.get("exportedFileName")
        suggested = a.get("suggestedHumanReadableName")
        if not exported or not suggested:
            continue
        src = base / exported
        dst = base / suggested
        if src.exists():
            try:
                src.rename(dst)
            except OSError:
                pass
PY
fi

echo "[E2E] xcresult:     $RESULT_BUNDLE"
echo "[E2E] screenshots:  $ATTACHMENTS_DIR"
echo "[E2E] manifest:     $ATTACHMENTS_DIR/manifest.json"
