#!/bin/bash
set -e

INCLUDE_ALPHA=0
for arg in "$@"; do
    case "$arg" in
        --allow-alpha)
            INCLUDE_ALPHA=1
            ;;
        *)
            echo "Unknown option: $arg"
            echo "Usage: $0 [--allow-alpha]"
            exit 1
            ;;
    esac
done

echo "Starting update and build process..."

# Stash any uncommitted changes
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "Stashing uncommitted changes..."
    git stash push -m "WIP: Auto-stashed before update"
    STASHED=1
else
    STASHED=0
fi

# Pull latest changes
echo "Pulling latest changes..."
git pull

# Apply stashed changes if any
if [ $STASHED -eq 1 ]; then
    echo "Applying stashed changes..."
    if ! git stash pop; then
        echo "WARNING: Merge conflicts detected. Please resolve them manually."
        echo "Your stashed changes are still available with 'git stash list'"
        exit 1
    fi
fi

# Build release
cd codex-rs

echo "Getting latest version tag..."
if [ $INCLUDE_ALPHA -eq 1 ]; then
    latest=$(git tag --list 'rust-v*' --sort=-v:refname | head -n1 | sed 's/^rust-v//')
else
    latest=$(git tag --list 'rust-v*' --sort=-v:refname | grep -v '\-alpha' | head -n1 | sed 's/^rust-v//')
fi

if [[ $latest == *-alpha* ]]; then
    echo "Using pre-release tag $latest (enabled via --allow-alpha)."
fi

echo "Updating workspace package version to $latest..."
LATEST_VERSION="$latest" python3 <<'PY'
import pathlib
import re
import os

latest = os.environ["LATEST_VERSION"]
manifest_path = pathlib.Path("Cargo.toml")

text = manifest_path.read_text()
workspace_pkg_pattern = re.compile(r'^(\s*version\s*=\s*")([^"]+)("\s*)$', re.MULTILINE)

def replace_version(match):
    return f"{match.group(1)}{latest}{match.group(3)}"

if "[workspace.package]" not in text:
    raise SystemExit("Could not locate [workspace.package] in Cargo.toml")

new_text, count = workspace_pkg_pattern.subn(replace_version, text, count=1)

if count == 0:
    raise SystemExit("Failed to update workspace package version")

manifest_path.write_text(new_text)
PY

echo "Building release without debug info..."
RUSTFLAGS='-Cdebuginfo=0' cargo build --release --workspace --all-features

echo ""
echo "Build complete! Binary at: codex-rs/target/release/codex"
