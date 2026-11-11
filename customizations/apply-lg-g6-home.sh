#!/bin/sh
# Reapply the LG G6 Home changes after updating the Glasshouse checkout.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
PATCH="$ROOT/customizations/lg-g6-home.patch"

cd "$ROOT"

if git apply --check "$PATCH" >/dev/null 2>&1; then
  git apply "$PATCH"
  echo "Applied the LG G6 Home customisations."
elif git apply --reverse --check "$PATCH" >/dev/null 2>&1; then
  echo "The LG G6 Home customisations are already applied."
else
  echo "The patch does not apply cleanly to this checkout; nothing was changed." >&2
  echo "Review the upstream changes and update customizations/lg-g6-home.patch before retrying." >&2
  exit 1
fi
