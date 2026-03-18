#!/usr/bin/env bash
# Install all Adams skills into the current project.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/bthornton191/adams_skills/main/install.sh | bash
#   ./install.sh                          # auto-detect skills folder
#   ./install.sh ~/.agents/skills         # explicit destination
set -euo pipefail

REPO="bthornton191/adams_skills"

# --- Resolve destination ---
if [ $# -ge 1 ]; then
    DEST="$1"
else
    # Scan for existing .*/skills folders in the current directory
    candidates=()
    for d in .*/skills; do
        [ -d "$d" ] && candidates+=("$d")
    done

    if [ ${#candidates[@]} -eq 1 ]; then
        DEST="${candidates[0]}"
        echo "Found existing skills folder: $DEST"
    elif [ ${#candidates[@]} -gt 1 ]; then
        echo "Multiple skills folders found:"
        for i in "${!candidates[@]}"; do
            echo "  [$((i + 1))] ${candidates[$i]}"
        done
        printf "Choose a folder (1-%d): " "${#candidates[@]}"
        read -r choice
        idx=$((choice - 1))
        if [ "$idx" -lt 0 ] || [ "$idx" -ge "${#candidates[@]}" ]; then
            echo "Invalid selection." >&2
            exit 1
        fi
        DEST="${candidates[$idx]}"
    else
        DEST=".agents/skills"
    fi
fi

mkdir -p "$DEST"

# --- Download and install ---
urls=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
    | grep -oP '"browser_download_url"\s*:\s*"\K[^"]+\.zip')

if [ -z "$urls" ]; then
    echo "ERROR: No .zip assets found in the latest release." >&2
    exit 1
fi

for url in $urls; do
    name=$(basename "$url" .zip)
    tmp="/tmp/$name.zip"
    echo "Installing $name ..."
    curl -fsSL "$url" -o "$tmp"
    unzip -oq "$tmp" -d "$DEST"
    rm -f "$tmp"
done

echo ""
echo "Done. Skills installed to $DEST"
