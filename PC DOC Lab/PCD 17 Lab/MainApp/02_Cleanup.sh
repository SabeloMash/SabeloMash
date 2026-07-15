#!/bin/bash

# === Paths to delete ===
DESKTOP_DIR="$HOME/Desktop"
FOLDERS=("2025" "Testlogs")

for folder in "${FOLDERS[@]}"; do
  TARGET="$DESKTOP_DIR/$folder"
  if [[ -d "$TARGET" ]]; then
    rm -rf "$TARGET"
  fi
done

exit 0

