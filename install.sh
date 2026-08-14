#!/usr/bin/env bash
# openstate — installer (binary distribution)
#
# Downloads the prebuilt openstate bundle (engine + plugin + skill) from a
# GitHub Release and deploys it into a repository's .opencode/ directory:
#
#   .opencode/plugins/openstate.js         server plugin (tools + engine IPC)
#   .opencode/plugins/openstate-tui.tsx    TUI sidebar plugin (OpenTUI)
#   .opencode/skills/openstate/SKILL.md    AI usage skill
#   .opencode/tui.json                     registers the TUI plugin
#   .opencode/bin/openstate-engine         the state engine binary
#   .opencode/package.json (+ deps)        @opentui/solid for the TUI plugin JSX
#
# openstate is PER-REPO: it only activates in repos that run this installer.
# Nothing touches ~/.config/opencode or any other repo.
#
# No compiler or Node toolchain is required at install time — the engine is a
# prebuilt, hardened binary shipped as a release asset.
#
# Usage:
#   curl -fsSL https://github.com/<owner>/<repo>/raw/main/install.sh | bash
#   OPENSTATE_CONFIG_DIR=/path/repo/.opencode ./install.sh   # install elsewhere
#   OPENSTATE_VERSION=v0.1.0 ./install.sh                    # pin a version
#   ./install.sh --check                                     # verify install
#
# Private repos: set GH_TOKEN (or GITHUB_TOKEN) to authenticate the download.
set -euo pipefail

# --- configuration (overridable) ---
REPO="${OPENSTATE_REPO:-Michael-A-Kuykendall/openstate}"
VERSION="${OPENSTATE_VERSION:-}"            # empty = latest release
CONFIG_DIR="${OPENSTATE_CONFIG_DIR:-$(pwd)/.opencode}"

say()  { printf '\033[1m%s\033[0m\n' "$*"; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; }
fail() { printf '  \033[31m✗\033[0m %s\n' "$*" >&2; exit 1; }

# --- platform detection ---
OS="$(uname -s)"
ARCH="$(uname -m)"
case "$OS" in
  Linux)  OS=linux ;;
  Darwin) OS=macos ;;
  MINGW*|MSYS*|CYGWIN*) OS=windows ;;
  *) fail "unsupported OS: $OS" ;;
esac
case "$ARCH" in
  x86_64|amd64) ARCH=x86_64 ;;
  aarch64|arm64) ARCH=aarch64 ;;
  *) fail "unsupported architecture: $ARCH" ;;
esac
PLATFORM="$OS-$ARCH"
ENGINE_NAME="openstate-engine"; [ "$OS" = "windows" ] && ENGINE_NAME="openstate-engine.exe"

# --- auth header for private repos ---
AUTH=()
if [ -n "${GH_TOKEN:-}${GITHUB_TOKEN:-}" ]; then
  AUTH=(-H "Authorization: Bearer ${GH_TOKEN:-$GITHUB_TOKEN}")
fi

# --- resolve version (default: latest release) ---
if [ -z "$VERSION" ]; then
  say "resolving latest openstate release..."
  TAG="$(curl -fsSL "${AUTH[@]}" "https://api.github.com/repos/$REPO/releases/latest" \
    | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p')"
  [ -n "$TAG" ] || fail "could not resolve latest release for $REPO"
else
  TAG="$VERSION"
fi
say "openstate installer — $REPO @ $TAG ($PLATFORM)"

# --- download release asset (public: browser URL; private: API endpoint) ---
OPENCODE_DIR="$CONFIG_DIR"
PLUGIN_DIR="$OPENCODE_DIR/plugins"
SKILL_DIR="$OPENCODE_DIR/skills/openstate"
BIN_DIR="$OPENCODE_DIR/bin"
ASSET="openstate-$TAG-$PLATFORM.tar.gz"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

say "downloading $ASSET"
RELEASE_JSON="https://api.github.com/repos/$REPO/releases/tags/$TAG"
if [ ${#AUTH[@]} -gt 0 ]; then
  # Private repo: resolve the asset id, download via the API endpoint.
  RELEASE_JSON="$(curl -fsSL "${AUTH[@]}" "$RELEASE_JSON")"
  ASSET_ID="$(printf '%s' "$RELEASE_JSON" | python3 -c "
import sys, json
d = json.load(sys.stdin)
for a in d.get('assets', []):
    if a['name'] == '$ASSET':
        print(a['id']); break
" 2>/dev/null)"
  [ -n "$ASSET_ID" ] || fail "asset $ASSET not found in release $TAG (python3 required for private-repo installs)"
  curl -fsSL "${AUTH[@]}" -H "Accept: application/octet-stream" \
    -o "$TMPDIR/$ASSET" \
    "https://api.github.com/repos/$REPO/releases/assets/$ASSET_ID" \
    || fail "download failed"
else
  # Public repo: plain browser download URL.
  curl -fL -o "$TMPDIR/$ASSET" \
    "https://github.com/$REPO/releases/download/$TAG/$ASSET" \
    || fail "download failed — is $TAG published for $PLATFORM?"
fi

# --- verify checksum (published alongside the asset) ---
if [ ${#AUTH[@]} -gt 0 ]; then
  SHA_ASSET_ID="$(printf '%s' "$RELEASE_JSON" | python3 -c "
import sys, json
d = json.load(sys.stdin)
for a in d.get('assets', []):
    if a['name'] == '$ASSET.sha256':
        print(a['id']); break
" 2>/dev/null)"
  if [ -n "$SHA_ASSET_ID" ]; then
    curl -fsSL "${AUTH[@]}" -H "Accept: application/octet-stream" \
      -o "$TMPDIR/$ASSET.sha256" \
      "https://api.github.com/repos/$REPO/releases/assets/$SHA_ASSET_ID"
    (cd "$TMPDIR" && sha256sum -c --status "$ASSET.sha256") \
      || fail "checksum mismatch — aborting (possible corruption or tampering)"
    ok "checksum verified"
  fi
else
  if curl -fsSL -o "$TMPDIR/$ASSET.sha256" \
     "https://github.com/$REPO/releases/download/$TAG/$ASSET.sha256" 2>/dev/null; then
    (cd "$TMPDIR" && sha256sum -c --status "$ASSET.sha256") \
      || fail "checksum mismatch — aborting (possible corruption or tampering)"
    ok "checksum verified"
  fi
fi

# --- smoke test the engine before touching anything ---
say "smoke-testing engine"
mkdir -p "$TMPDIR/x"
tar -xzf "$TMPDIR/$ASSET" -C "$TMPDIR/x"
[ -x "$TMPDIR/x/bin/$ENGINE_NAME" ] || fail "release asset missing engine binary"
SMOKE_DIR="$(mktemp -d)"
RESPONSE="$(
  printf '%s\n' \
    '{"type":"observation","event":"file.edited","data":{"path":"smoke.rs"}}' \
    '{"type":"query","query":"state"}' \
  | OPENSTATE_STATE="$SMOKE_DIR/state.jsonl" "$TMPDIR/x/bin/$ENGINE_NAME" 2>/dev/null \
  | tail -1
)"
echo "$RESPONSE" | grep -q '"facts"' || fail "engine smoke test failed: $RESPONSE"
rm -rf "$SMOKE_DIR"
ok "engine responds to observation + state query"

# ---------- check mode ----------
if [ "${1:-}" = "--check" ]; then
  MISSING=""
  [ -f "$PLUGIN_DIR/openstate.js" ]          || MISSING="$MISSING openstate.js"
  [ -f "$PLUGIN_DIR/openstate-tui.tsx" ]     || MISSING="$MISSING openstate-tui.tsx"
  [ -x "$BIN_DIR/$ENGINE_NAME" ]             || MISSING="$MISSING openstate-engine"
  [ -f "$SKILL_DIR/SKILL.md" ]               || MISSING="$MISSING SKILL.md"
  [ -f "$OPENCODE_DIR/tui.json" ]            || MISSING="$MISSING tui.json"
  [ -f "$OPENCODE_DIR/package.json" ]        || MISSING="$MISSING package.json"
  [ -n "$MISSING" ] && fail "incomplete install in $OPENCODE_DIR, missing:$MISSING"
  ok "complete bundle verified in $OPENCODE_DIR"
  exit 0
fi

# ---------- install ----------
say "installing to $OPENCODE_DIR"
mkdir -p "$PLUGIN_DIR" "$SKILL_DIR" "$BIN_DIR"

# stop a previous install's engine BEFORE replacing the binary (a running
# process keeps the OLD code in memory; two engines on one state file would
# fight over the lock). The next tool call respawns the new binary.
if [ -x "$BIN_DIR/$ENGINE_NAME" ]; then
  pkill -f "$BIN_DIR/$ENGINE_NAME" 2>/dev/null || true
  sleep 0.2
  say "  stopped prior engine process"
fi

cp "$TMPDIR/x/plugins/openstate.js"      "$PLUGIN_DIR/openstate.js"
cp "$TMPDIR/x/plugins/openstate-tui.tsx" "$PLUGIN_DIR/openstate-tui.tsx"
cp "$TMPDIR/x/skills/openstate/SKILL.md" "$SKILL_DIR/SKILL.md"

# Engine binary: retry up to 5 times (old process may still hold the file lock).
ENGINE_DEST="$BIN_DIR/$ENGINE_NAME"
for i in 1 2 3 4 5; do
  if cp -f "$TMPDIR/x/bin/$ENGINE_NAME" "$ENGINE_DEST" 2>/dev/null; then
    break
  fi
  if [ "$i" -eq 5 ]; then
    fail "engine binary still busy after 5 retries — close opencode and retry"
  fi
  sleep 0.5
done
chmod +x "$ENGINE_DEST"

# WSL2: if .openstate would live on a Windows-mounted FS (/mnt/c/...),
# the engine's atomic writes block in D-state. Move state to native Linux
# FS and symlink from the repo so writes never cross the bridge.
STATE_DIR="$OPENCODE_DIR/../.openstate"
if grep -qiE "microsoft|wsl" /proc/version 2>/dev/null; then
  REPO_ROOT="$(dirname "$OPENCODE_DIR")"
  REPO_NAME="$(basename "$REPO_ROOT")"
  LINUX_STATE="$HOME/.openstate/$REPO_NAME"
  if [ -d "$STATE_DIR" ] && [ ! -L "$STATE_DIR" ]; then
    # Existing real dir — move to Linux FS and symlink
    mkdir -p "$(dirname "$LINUX_STATE")"
    mv "$STATE_DIR" "$LINUX_STATE"
    ln -s "$LINUX_STATE" "$STATE_DIR"
    say "  WSL2: state moved to $LINUX_STATE (symlinked from repo)"
  elif [ ! -e "$STATE_DIR" ]; then
    # First install — create on Linux FS and symlink so the plugin
    # never creates it on the Windows FS
    mkdir -p "$LINUX_STATE"
    ln -s "$LINUX_STATE" "$STATE_DIR"
    say "  WSL2: state linked to $LINUX_STATE (native Linux FS)"
  fi
fi

# tui.json — MERGE instead of overwrite: append openstate plugin if not present.
TUI_JSON="$OPENCODE_DIR/tui.json" node -e '
  const fs = require("fs");
  const p = process.env.TUI_JSON;
  const plugin = "./plugins/openstate-tui.tsx";
  let obj = { "$schema": "https://opencode.ai/tui.json", plugin: [plugin] };
  try {
    obj = JSON.parse(fs.readFileSync(p, "utf8"));
    if (!Array.isArray(obj.plugin)) obj.plugin = [];
    if (!obj.plugin.includes(plugin)) obj.plugin.push(plugin);
  } catch {}
  fs.writeFileSync(p, JSON.stringify(obj, null, 2) + "\n");
'

# package.json — MERGE dependencies: preserve existing, add openstate deps.
PKG_JSON="$OPENCODE_DIR/package.json" node -e '
  const fs = require("fs");
  const p = process.env.PKG_JSON;
  const add = {
    "@opencode-ai/plugin": "1.18.13",
    "@opentui/solid": "^0.5.1"
  };
  let obj = { dependencies: add };
  try {
    obj = JSON.parse(fs.readFileSync(p, "utf8"));
    obj.dependencies = { ...add, ...(obj.dependencies || {}) };
  } catch {}
  fs.writeFileSync(p, JSON.stringify(obj, null, 2) + "\n");
'

if [ -f "$OPENCODE_DIR/package-lock.json" ] || [ -f "$OPENCODE_DIR/yarn.lock" ] || [ -f "$OPENCODE_DIR/bun.lock" ]; then
  (cd "$OPENCODE_DIR" && npm install --silent) || say "  (npm install deferred — opencode will install at startup)"
else
  (cd "$OPENCODE_DIR" && npm install --silent) || say "  (npm install deferred — opencode will install at startup)"
fi

ok "server plugin: .opencode/plugins/openstate.js"
ok "tui plugin:    .opencode/plugins/openstate-tui.tsx"
ok "skill:          .opencode/skills/openstate/SKILL.md"
ok "engine:         .opencode/bin/$ENGINE_NAME"
ok "tui.json:       .opencode/tui.json"
ok "package.json:   .opencode/package.json (deps installed)"

# ---------- done ----------
say "done"
cat <<EOF

openstate is installed for this repo at $OPENCODE_DIR.
Only repos that run this installer will have openstate active —
nothing is written outside this .opencode/ directory.

Restart OpenCode. You will see:
  • 13 AI tools: state, why, checkpoint, capsule, export, reset, assess, report, report_timeline, close, sessions, doctor, restart
  • the openstate skill, which tells the AI when to use them
  • "● openstate / battery ready · backing up" in the session sidebar (TUI)
  • to pull an already-running session's history into the battery, run
    openstate_assess (idempotent — re-running never duplicates)

State lives per-project in .openstate/state.jsonl.

Verify later with: ./install.sh --check
EOF