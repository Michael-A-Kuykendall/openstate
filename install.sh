#!/usr/bin/env bash
# openstate — installer (binary distribution)
#
# Downloads the prebuilt openstate bundle (engine + plugin + skill) from a
# GitHub Release and deploys it into a repository's .opencode/ directory:
#
#   .opencode/plugins/openstate/index.js        server plugin (tools + engine IPC)
#   .opencode/plugins/openstate/tui.js          sidebar plugin (OpenTUI, auto-discovered)
#   .opencode/skills/openstate/SKILL.md         AI usage skill
#   .opencode/bin/openstate-engine              the state engine binary
#   .opencode/bin/ast-grep                      structural search/edit backend
#   .opencode/mcp/openstate-mcp.mjs              MCP server for other hosts (Claude Code, Muse, Kiro, Copilot)
#   .opencode/structural-tools-profile.json     structural tools profile (enforce/shadow/off)
#   .opencode/package.json (+ deps)             @opentui/solid for the TUI plugin JSX
#
# openstate installs GLOBALLY by default: the bundle is placed once under your
# OpenCode config root (a single repository is used only with --repo or
# OPENSTATE_CONFIG_DIR). Every repo inherits it; per-repo state stays segregated
# in each repository's .openstate/ with its own lock, so the shared bundle has
# no shared mutable state.
#
# No compiler is required — the engine is a prebuilt, hardened binary shipped as
# a release asset. Node.js 18+ IS required (the installer uses it to update your
# JSON config and refuses to run without it).
#
# Usage:
#   curl -fsSL https://github.com/<owner>/<repo>/raw/main/install.sh | bash
#   OPENSTATE_CONFIG_DIR=/path/repo/.opencode ./install.sh   # install elsewhere
#   OPENSTATE_VERSION=v0.1.0 ./install.sh                    # pin a version
#   ./install.sh --check                                     # verify install
#   ./install.sh --uninstall                                 # remove openstate (preserves .openstate/ state)
#   ./install.sh --purge                                     # uninstall + delete this repo's .openstate/ state
#
# Private repos: set GH_TOKEN (or GITHUB_TOKEN) to authenticate the download.
set -euo pipefail

# --- configuration (overridable) ---
REPO="${OPENSTATE_REPO:-Michael-A-Kuykendall/openstate}"
VERSION="${OPENSTATE_VERSION:-}"            # empty = latest release
TAG=""                                      # resolved below (or from local bundle)
STRUCTURAL_MODE="${OPENSTATE_STRUCTURAL_TOOLS:-}"
STRUCTURAL_MODE_EXPLICIT=1
if [ -z "$STRUCTURAL_MODE" ]; then
  STRUCTURAL_MODE="off"
  STRUCTURAL_MODE_EXPLICIT=0
fi
case "$STRUCTURAL_MODE" in
  off|shadow|enforce) ;;
  *) fail "OPENSTATE_STRUCTURAL_TOOLS must be off, shadow, or enforce" ;;
esac
# --global | OPENSTATE_GLOBAL=1 installs the bundle ONCE at the host config
# root (openstate-dyf.5.8) so every repo inherits it, instead of per-repo
# .opencode/. OpenCode loads plugins + skills from that root into every
# session; per-repo state stays segregated via resolveStateDir (per-repo
# state.jsonl, own lock), so the shared bundle has NO shared mutable state.
GLOBAL_MODE=0
for arg in "$@"; do
  [ "$arg" = "--global" ] && GLOBAL_MODE=1
done
[ "${OPENSTATE_GLOBAL:-0}" = "1" ] && GLOBAL_MODE=1
INSTALL_SCOPE="${OPENSTATE_INSTALL_SCOPE:-}"
for arg in "$@"; do
  [ "$arg" = "--repo" ] && INSTALL_SCOPE="repo"
done
if [ "$GLOBAL_MODE" -eq 1 ]; then INSTALL_SCOPE="global"; fi
if [ -z "$INSTALL_SCOPE" ]; then
  [ -n "${OPENSTATE_CONFIG_DIR:-}" ] && INSTALL_SCOPE="repo" || INSTALL_SCOPE="global"
fi
[ "$INSTALL_SCOPE" = "repo" ] || [ "$INSTALL_SCOPE" = "global" ] || fail "OPENSTATE_INSTALL_SCOPE must be repo or global"

global_config_root() {
  # Linux/macOS XDG; Windows %APPDATA%.
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -u "$APPDATA" 2>/dev/null || printf '%s' "$APPDATA"
  elif [ -n "${XDG_CONFIG_HOME:-}" ]; then
    printf '%s' "$XDG_CONFIG_HOME"
  else
    printf '%s' "${HOME:-$USERPROFILE}/.config"
  fi
}

CONFIG_DIR="${OPENSTATE_CONFIG_DIR:-$(pwd)/.opencode}"
if [ "$GLOBAL_MODE" -eq 1 ] && [ -z "${OPENSTATE_CONFIG_DIR:-}" ]; then
  CONFIG_DIR="$(global_config_root)/opencode"
fi

say()  { printf '\033[1m%s\033[0m\n' "$*"; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; }
fail() { printf '  \033[31m✗\033[0m %s\n' "$*" >&2; exit 1; }

# openstate-s9bf.27: every mode edits JSON config with node, and the MCP server
# runs on it. Refuse before anything is downloaded or written.
if ! command -v node >/dev/null 2>&1; then
  fail "Node.js 18 or newer is required (the installer uses it to update JSON config, and the MCP server runs on it). Install Node.js, then run this again. Nothing was changed."
fi
NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)"
if [ "${NODE_MAJOR:-0}" -lt 18 ] 2>/dev/null; then
  fail "Node.js 18 or newer is required; found $(node --version 2>/dev/null || echo 'an unknown version'). Upgrade Node.js, then run this again. Nothing was changed."
fi

# version_cmp A B: prints "<" ">" or "=" depending on how A compares to B.
# Handles leading "v" and dotted numeric versions; unknown/non-numeric sorts
# below any numeric version so a legacy install reads as "upgradable".
version_cmp() {
  local a="$1" b="$2"
  a="$(printf '%s' "$a" | sed 's/^[vV]//')"
  b="$(printf '%s' "$b" | sed 's/^[vV]//')"
  if [ "$a" = "$b" ]; then echo "="; return; fi
  # Portable dotted-numeric compare (no GNU sort -V; works on stock macOS).
  # Compare component-wise as integers; missing components are 0 (1.2==1.2.0).
  local aa bb i
  a="$(printf '%s' "$a" | sed 's/[^0-9.]//g' | sed 's/\.$//')"
  b="$(printf '%s' "$b" | sed 's/[^0-9.]//g' | sed 's/\.$//')"
  if [ -z "$a" ] || [ -z "$b" ]; then
    # Non-numeric (e.g. "legacy"): lower than any numeric.
    [ -n "$a" ] && [ -z "$b" ] && echo ">" && return
    [ -z "$a" ] && [ -n "$b" ] && echo "<" && return
    echo "="; return
  fi
  while [ -n "$a" ] || [ -n "$b" ]; do
    aa="${a%%.*}"; bb="${b%%.*}"
    aa="${aa:-0}"; bb="${bb:-0}"
    [ "$aa" -gt "$bb" ] && echo ">" && return
    [ "$aa" -lt "$bb" ] && echo "<" && return
    # Remove the consumed component (or clear if no dot remains).
    case "$a" in *.*) a="${a#*.}";; *) a="";; esac
    case "$b" in *.*) b="${b#*.}";; *) b="";; esac
  done
  echo "="
}

# sha256_for FILE -> prints the lowercase sha256 hex of FILE. Portable across
# Linux (sha256sum), stock macOS (shasum -a 256), and Windows git-bash/OpenSSL.
sha256_for() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  elif command -v openssl >/dev/null 2>&1; then
    openssl dgst -sha256 "$1" | sed 's/^.*= //'
  else
    echo "" >&2
    echo "error: no sha256 tool available (sha256sum/shasum/openssl)" >&2
    return 1
  fi
}

# sha256_verify FILE EXPECTED: exits nonzero unless the file's sha256 matches.
sha256_verify() {
  local got
  got="$(sha256_for "$1")"
  [ -n "$got" ] && [ "$got" = "$2" ]
}

# sha256_verify_companion FILE SHAFILE: verify FILE against "HEX  name" SHAFILE.
sha256_verify_companion() {
  local expected
  expected="$(awk 'NR==1 {print $1; exit}' "$2")"
  [ -n "$expected" ] || return 1
  sha256_verify "$1" "$expected"
}

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
# openstate-ah60.13: release asset names. Must equal the list
# tools/publish-release.sh publishes (the release exam, item I3, checks it).
OPENSTATE_PUBLISHED_PLATFORMS="linux-x86_64 macos-x86_64 macos-arm64 windows-x86_64"
case "$PLATFORM" in
  macos-aarch64) PLATFORM=macos-arm64 ;;  # Apple Silicon assets are named arm64
esac
ENGINE_NAME="openstate-engine"; [ "$OS" = "windows" ] && ENGINE_NAME="openstate-engine.exe"
AST_GREP_NAME="ast-grep"; [ "$OS" = "windows" ] && AST_GREP_NAME="ast-grep.exe"

OPENCODE_DIR="$CONFIG_DIR"
PLUGIN_DIR="$OPENCODE_DIR/plugins"
SKILL_DIR="$OPENCODE_DIR/skills/openstate"
MCP_DIR="$OPENCODE_DIR/mcp"
BIN_DIR="$OPENCODE_DIR/bin"
VERSION_FILE="$OPENCODE_DIR/VERSION"          # installed bundle tag
MANIFEST_FILE="$OPENCODE_DIR/BUNDLE.sha256"   # integrity: engine hash at install
PROFILE_FILE="$OPENCODE_DIR/structural-tools-profile.json"
PROFILE_MODE_FILE="$OPENCODE_DIR/structural-tools.mode"
PROFILE_BACKUP="$OPENCODE_DIR/opencode.jsonc.structural-tools-backup"
SCOPE_FILE="$OPENCODE_DIR/openstate-install.json"

# openstate-fleet: a bare reinstall (no OPENSTATE_STRUCTURAL_TOOLS) must not
# silently downgrade the mode a repo already runs — a plain bundle upgrade
# wiped enforce across the whole fleet before this guard existed. Inherit the
# installed mode when the flag was not given explicitly.
if [ "$STRUCTURAL_MODE_EXPLICIT" -eq 0 ] && [ -f "$PROFILE_MODE_FILE" ]; then
  STRUCTURAL_MODE="$(head -n 1 "$PROFILE_MODE_FILE" 2>/dev/null | tr -d '[:space:]')"
  case "$STRUCTURAL_MODE" in
    off|shadow|enforce) ;;
    *) STRUCTURAL_MODE="off" ;;
  esac
fi

# ---------------------------------------------------------------------------
# Skill validation: the AI's primary interface is the SKILL.md file — if it is
# missing or its YAML front matter is broken (no `name:` / `description:`), the
# repo cannot load the openstate skill. EVERY install and --check must verify
# it. Returns 0 if valid, 1 if missing/broken.
# ---------------------------------------------------------------------------
skill_is_valid() {
  local skill="$1"
  [ -f "$skill" ] || return 1
  # Must open with YAML front matter and carry the required keys.
  local head
  head="$(head -6 "$skill" 2>/dev/null)"
  printf '%s' "$head" | grep -q '^---' || return 1
  printf '%s' "$head" | grep -qE '^name:\s*' || return 1
  printf '%s' "$head" | grep -qE '^description:\s*' || return 1
  return 0
}

# ---------------------------------------------------------------------------
# State-path validation (openstate-es8): .openstate must be absent, a real
# directory, or a symlink resolving to a directory. Anything else — a regular
# file holding a path, a dangling symlink — means every engine run stalls
# (seen in a real install) while bundle --check stays green. Fail HERE with
# the one-line fix instead of letting sessions die mysteriously later.
# ---------------------------------------------------------------------------
validate_state_path() {
  local repo_root="$1"
  local state_dir="$repo_root/.openstate"
  if [ -L "$state_dir" ]; then
    if [ ! -d "$state_dir" ]; then
      fail "broken .openstate symlink ($(readlink "$state_dir" 2>/dev/null)) — target missing or not a directory, so every engine run stalls. Fix: rm \"$state_dir\" && ln -s /path/to/state-dir \"$state_dir\""
    fi
  elif [ -d "$state_dir" ]; then
    return 0
  elif [ -f "$state_dir" ]; then
    # Pointer-file layout is SUPPORTED: resolveStateDir reads the state
    # directory path from the file's first line and hands the engine the
    # resolved path. Only reject it when the recorded target is unusable —
    # that is the corruption shape that stalls every run.
    # s9bf.25: first line, trimmed at the ends (spaces inside the path are
    # kept), relative to the repository: the same rule as resolveStateDir.
    local pointer
    pointer="$(head -n 1 "$state_dir" 2>/dev/null | tr -d '\r' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    case "$pointer" in /*|[A-Za-z]:[\\/]*) ;; ?*) pointer="$repo_root/$pointer" ;; esac
    if [ -n "$pointer" ] && [ -d "$pointer" ]; then
      return 0
    fi
    fail "$state_dir is a regular file whose recorded path ('$pointer') is missing or not a directory — every engine run stalls. Fix: point the file's first line at an existing state directory, or rm \"$state_dir\" && mkdir -p \"$state_dir\""
  fi
}

# ---------------------------------------------------------------------------
# Lock-holder engine stop (openstate-es8): the per-repo pkill above only
# matches engines whose binary path is $BIN_DIR/openstate-engine. A
# GLOBAL-mode engine (~/.config/opencode/bin) that holds THIS repo's state
# lock survives that pkill, and the freshly installed engine then refuses to
# start ("second engine cannot own the same state"). Read the repo's
# state.jsonl.lock and stop the recorded pid — but ONLY after confirming via
# /proc that its working directory is this repo, so an unrelated engine on a
# recycled pid is never killed. Locks whose pid is unverifiable (non-Linux,
# /proc absent) are left for the plugin's stale-lock reaper; nothing is
# killed without positive ownership evidence.
# ---------------------------------------------------------------------------
stop_lock_holder_engines() {
  local repo_root
  repo_root="$(cd "$(dirname "$OPENCODE_DIR")" 2>/dev/null && pwd)" || repo_root=""
  local lock_path="$repo_root/.openstate/state.jsonl.lock"
  [ -f "$lock_path" ] || return 0
  local pid
  # Guard every pipeline with || true: the installer runs under set -e -o
  # pipefail, and a lock whose content doesn't match (legacy numeric pid,
  # foreign format) must degrade to "no pid found", never kill the install.
  pid="$(grep -oE '"pid":[[:space:]]*[0-9]+' "$lock_path" 2>/dev/null | grep -oE '[0-9]+' | head -n 1 || true)"
  if [ -z "$pid" ]; then
    pid="$(grep -E '^[0-9]+$' "$lock_path" 2>/dev/null | head -n 1 || true)"
  fi
  case "$pid" in
    ''|*[!0-9]*) return 0 ;;
  esac
  local pid_cwd
  pid_cwd="$(readlink "/proc/$pid/cwd" 2>/dev/null || true)"
  if [ -z "$pid_cwd" ]; then
    say "  note: state lock held by pid $pid but its cwd is unverifiable on this platform — leaving it for the plugin's stale-lock reaper"
    return 0
  fi
  case "$pid_cwd" in
    "$repo_root"|"$repo_root"/*)
      kill "$pid" 2>/dev/null || true
      sleep 0.3
      say "  stopped engine holding this repo's state lock (pid $pid)"
      rm -f "$lock_path" 2>/dev/null || true
      ;;
    *)
      say "  note: state lock names pid $pid whose cwd ($pid_cwd) is outside this repo — not touching it"
      ;;
  esac
}

# ---------- uninstall mode (extricate openstate from this repo) ----------
# Removes ONLY openstate-owned artifacts. Restores the structural-tools config
# backup when present. NEVER touches user state in .openstate/ (that requires
# --purge). Leaves unrelated repo files untouched. Idempotent: exit 0 if
# nothing is installed.
# openstate-s9bf.11: --purge is uninstall plus deleting this repository's
# state. It follows a symlink or pointer file to the real state directory, and
# deletes a target only if it holds state.jsonl or is empty (never $HOME or /).
purge_state() {
  local link="$1" target=""
  if [ -L "$link" ]; then
    target="$(cd "$link" 2>/dev/null && pwd -P)"
  elif [ -f "$link" ]; then
    target="$(head -n 1 "$link" | tr -d '\r' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    case "$target" in /*|[A-Za-z]:[\\/]*) ;; ?*) target="$(dirname "$link")/$target" ;; esac
    [ -d "$target" ] && target="$(cd "$target" && pwd -P)" || target=""
  elif [ -d "$link" ]; then
    target="$(cd "$link" && pwd -P)"
  else
    say "  no .openstate/ state to delete"
    return 0
  fi
  if [ -n "$target" ]; then
    case "$target" in
      /|"$HOME"|"$(cd "$HOME" && pwd -P)") fail "refusing to delete $target named by $link; remove the state yourself" ;;
    esac
    if [ -e "$target/state.jsonl" ] || [ -z "$(ls -A "$target" 2>/dev/null)" ]; then
      rm -rf "$target"
      say "  deleted state: $target"
    else
      fail "$target (named by $link) does not look like OpenState state (no state.jsonl); not deleting it"
    fi
  fi
  rm -rf "$link" 2>/dev/null || true
}

PURGE=0
if [ "${1:-}" = "--purge" ] || [ "${1:-}" = "purge" ]; then
  [ "${GLOBAL_MODE:-0}" = 1 ] && fail "--purge deletes one repository's state; run it in that repository without --global"
  PURGE=1
fi
if [ "${1:-}" = "--uninstall" ] || [ "${1:-}" = "uninstall" ] || [ "$PURGE" = 1 ]; then
  say "uninstalling openstate from $OPENCODE_DIR"

  # Restore the pre-profile opencode.jsonc if enforce/shadow left a backup.
  if [ -f "$PROFILE_BACKUP" ]; then
    cp -f "$PROFILE_BACKUP" "$OPENCODE_DIR/opencode.jsonc"
    rm -f "$PROFILE_BACKUP"
    say "  restored .opencode/opencode.jsonc from structural-tools backup"
  fi
  rm -f "$PROFILE_MODE_FILE" "$SCOPE_FILE"

  # Remove only the installer-owned instruction block from repo guidance.
  # Any surrounding user or tool instructions remain untouched.
  AGENTS_FILE="$(dirname "$OPENCODE_DIR")/AGENTS.md"
  if [ -f "$AGENTS_FILE" ]; then
    AGENTS_FILE="$AGENTS_FILE" node -e '
      const fs = require("fs");
      const p = process.env.AGENTS_FILE;
      const text = fs.readFileSync(p, "utf8");
      // openstate-bs4: strip every variant, not just the enforce one.
      const re = /<!-- OPENSTATE-STRUCTURAL(?::[a-z]+)? -->[\s\S]*?<!-- \/OPENSTATE-STRUCTURAL -->\r?\n*/g;
      fs.writeFileSync(p, text.replace(re, ""));
    '
  fi

  # openstate-n3s.7/8: V2 CLI plugins are auto-discovered from the server
  # plugin list — tui.json is no longer an openstate artifact and is NOT
  # touched by install or uninstall. User-authored tui.json stays verbatim.

  # Remove openstate deps from package.json (preserve others) — best effort.
  # The V2 server plugin needs @opencode/plugin + @opencode/client; the TUI
  # still needs @opentui/solid (SlotClaim.render returns JSX from it), which
  # other TUI plugins may share — so uninstall removes ONLY the openstate
  # server-plugin deps and leaves @opentui/solid in place.
  if [ -f "$OPENCODE_DIR/package.json" ]; then
    PKG_JSON="$OPENCODE_DIR/package.json" node -e '
      const fs = require("fs");
      const p = process.env.PKG_JSON;
      try {
        const obj = JSON.parse(fs.readFileSync(p, "utf8"));
        if (obj.dependencies) {
          delete obj.dependencies["@opencode-ai/plugin"];
          delete obj.dependencies["@opencode/plugin"];
          delete obj.dependencies["@opencode/client"];
          fs.writeFileSync(p, JSON.stringify(obj, null, 2) + "\n");
        }
      } catch {}
    '
  fi

  # Remove install-created residue that is now empty/fragile. These files were
  # CREATED by install (not user-authored): tui.json with an empty plugin list,
  # package.json with empty deps, package-lock.json, and node_modules/. Leave
  # them if they carry non-openstate content. tui.json is NOT openstate-owned
  # anymore (V2 CLI auto-discovery) and is never removed.
  PKG_JSON="$OPENCODE_DIR/package.json" node -e '
    const fs = require("fs");
    const p = process.env.PKG_JSON;
    try {
      const obj = JSON.parse(fs.readFileSync(p, "utf8"));
      const deps = obj.dependencies && Object.keys(obj.dependencies);
      const devDeps = obj.devDependencies && Object.keys(obj.devDependencies);
      const onlyOpenstate = (!deps || deps.length === 0) && (!devDeps || devDeps.length === 0);
      if (onlyOpenstate) fs.unlinkSync(p);
    } catch {}
  '
  # Never remove package-manager state: it may belong to the user's other plugins.

  # Remove openstate-owned files/dirs under .opencode/ (NOT the config dir itself
  # unless it is now empty of everything we added; never remove user data).
  rm -rf "$PLUGIN_DIR/openstate"
  rm -f "$BIN_DIR/$ENGINE_NAME" "$BIN_DIR/$AST_GREP_NAME"
  rm -rf "$SKILL_DIR"
  rm -f "$MCP_DIR/openstate-mcp.mjs"; rmdir "$MCP_DIR" 2>/dev/null || true
  rm -f "$PROFILE_FILE" "$VERSION_FILE" "$MANIFEST_FILE"
  # Remove empty dirs we created (plugins/bin/skills + the skills parent) only
  # if now empty.
  rmdir "$PLUGIN_DIR" 2>/dev/null || true
  rmdir "$BIN_DIR" 2>/dev/null || true
  rmdir "$SKILL_DIR" 2>/dev/null || true
  rmdir "$OPENCODE_DIR/skills" 2>/dev/null || true

  say "done — openstate removed from $OPENCODE_DIR"
  say "  removed: plugins, skill, engine, ast-grep, profile, manifest, and marked AGENTS instructions"
  if [ "$PURGE" = 1 ]; then
    purge_state "$(dirname "$OPENCODE_DIR")/.openstate"
  else
    say "  note: user state in .openstate/ was preserved. To delete it too: $0 --purge"
  fi
  exit 0
fi

# ---------- check mode (verifies an installed bundle; NO network) ----------
if [ "${1:-}" = "--check" ]; then
  MISSING=""
  [ -f "$PLUGIN_DIR/openstate/index.js" ]    || MISSING="$MISSING plugins/openstate/index.js"
  [ -f "$PLUGIN_DIR/openstate/tui.js" ]       || MISSING="$MISSING plugins/openstate/tui.js"
  [ -x "$BIN_DIR/$ENGINE_NAME" ]             || MISSING="$MISSING openstate-engine"
  [ -x "$BIN_DIR/$AST_GREP_NAME" ]           || MISSING="$MISSING $AST_GREP_NAME"
  [ -f "$SKILL_DIR/SKILL.md" ]               || MISSING="$MISSING SKILL.md"
  [ -f "$MCP_DIR/openstate-mcp.mjs" ]         || MISSING="$MISSING mcp/openstate-mcp.mjs"
  [ -f "$PROFILE_FILE" ]                    || MISSING="$MISSING structural-tools-profile.json"
  [ -n "$MISSING" ] && fail "incomplete install in $OPENCODE_DIR, missing:$MISSING"

  # openstate-es8: the state path is load-bearing for every engine run —
  # validate it in check mode too, so corruption is caught here, not as a
  # mystery stall in a future session.
  validate_state_path "$(dirname "$OPENCODE_DIR")"

  # Structural-tools mode drift: the mode marker and the actual opencode.jsonc
  # must agree. enforce -> the V2 permissions ARRAY shape present; shadow/off
  # -> none. The V1 object keys no longer count (openstate-n3s.6).
  if [ -f "$PROFILE_MODE_FILE" ]; then
    MODE="$(cat "$PROFILE_MODE_FILE")"
    if grep -q '"permissions"' "$OPENCODE_DIR/opencode.jsonc" \
      && grep -qE '"action"[[:space:]]*:[[:space:]]*"shell"' "$OPENCODE_DIR/opencode.jsonc" \
      && grep -qE '"resource"[[:space:]]*:[[:space:]]*"sed \*"' "$OPENCODE_DIR/opencode.jsonc"; then
      HAS_ENFORCE=1
    else
      HAS_ENFORCE=0
    fi
    case "$MODE" in
      enforce)
        [ "$HAS_ENFORCE" = "1" ] || fail "profile drift: mode=enforce but opencode.jsonc is missing the V2 permissions array (a shell deny rule such as 'sed *' with effect deny)"
        # openstate-ii7: per-agent permission overrides take precedence over
        # the top-level config in OpenCode, so an agent file carrying its own
        # permission block re-allows denied tools inside that agent (the
        # chat-chronicle dev.md incident). The plugin re-applies profile
        # denies at runtime regardless, but the stale override must be named
        # loudly so it gets removed instead of silently diverging. The scan
        # covers V1 frontmatter keys (bash/edit/grep) and V2 (permission(s)).
        AGENT_CONFLICTS=""
        for agent_file in "$OPENCODE_DIR"/agent/*.md "$OPENCODE_DIR"/agents/*.md; do
          [ -f "$agent_file" ] || continue
          if grep -qE '^[[:space:]]*(bash|edit|grep|permission|permissions):' "$agent_file"; then
            AGENT_CONFLICTS="$AGENT_CONFLICTS $agent_file"
          fi
        done
        if [ -n "$AGENT_CONFLICTS" ]; then
          fail "agent permission override conflicts with enforce:$AGENT_CONFLICTS — remove the permission block from those agent files so they inherit the enforce config (the openstate plugin now re-applies profile denies at runtime, but the override must not stand)"
        fi
        ;;
      *)
        [ "$HAS_ENFORCE" = "0" ] || fail "profile drift: mode=$MODE but opencode.jsonc still carries the V2 permissions array"
        ;;
    esac
  fi
  # The skill file must be PRESENT and have VALID YAML front matter — a broken
  # or missing skill means the repo cannot load openstate at all.
  skill_is_valid "$SKILL_DIR/SKILL.md" \
    || fail "invalid skill file: $SKILL_DIR/SKILL.md (must open with '---' and carry name: + description:)"

  # The profile is the single structural-tool manifest. Every tool must be
  # listed in both the manifest and the installed skill, so stale bundles fail
  # loudly instead of silently hiding supported navigation/edit operations.
  PROFILE_FILE="$PROFILE_FILE" SKILL_FILE="$SKILL_DIR/SKILL.md" PLUGIN_FILE="$PLUGIN_DIR/openstate/index.js" node -e '
    const fs = require("fs");
    const profile = JSON.parse(fs.readFileSync(process.env.PROFILE_FILE, "utf8"));
    const tools = profile.structural_tools;
    if (!Array.isArray(tools) || tools.length < 18 || new Set(tools).size !== tools.length) {
      console.error("structural-tools manifest must contain at least 18 unique tools (found " + tools.length + ")"); process.exit(1);
    }
    const skill = fs.readFileSync(process.env.SKILL_FILE, "utf8");
    const plugin = fs.readFileSync(process.env.PLUGIN_FILE, "utf8");
    const missingSkill = tools.filter((name) => !skill.includes(name));
    const missingPlugin = tools.filter((name) => !plugin.includes(name));
    if (missingSkill.length) { console.error("skill missing structural tools: " + missingSkill.join(", ")); process.exit(1); }
    if (missingPlugin.length) { console.error("plugin missing structural tools: " + missingPlugin.join(", ")); process.exit(1); }
  ' || fail "structural-tools manifest/skill/plugin mismatch"

  # Integrity: the installed engine must hash-match what the installer recorded.
  if [ -n "${OPENSTATE_EXPECT_SHA:-}" ]; then
    ACTUAL="$(sha256_for "$BIN_DIR/$ENGINE_NAME" 2>/dev/null)"
    [ -n "$ACTUAL" ] || fail "engine binary missing or unreadable"
    [ "$ACTUAL" = "$OPENSTATE_EXPECT_SHA" ] \
      || fail "engine binary MISMATCH: expected $OPENSTATE_EXPECT_SHA got $ACTUAL"
  elif [ -f "$MANIFEST_FILE" ]; then
    EXPECTED="$(cat "$MANIFEST_FILE")"
    ACTUAL="$(sha256_for "$BIN_DIR/$ENGINE_NAME" 2>/dev/null)"
    [ "$ACTUAL" = "$EXPECTED" ] \
      || fail "engine binary replaced since install (expected $EXPECTED, got $ACTUAL)"
  fi

  # Version awareness: report what is installed, honor an expected version.
  INSTALLED="$(cat "$VERSION_FILE" 2>/dev/null || echo unknown)"
  if [ -n "${OPENSTATE_EXPECT_VERSION:-}" ] && [ "$INSTALLED" != "$OPENSTATE_EXPECT_VERSION" ]; then
    fail "version mismatch: installed=$INSTALLED expected=$OPENSTATE_EXPECT_VERSION"
  fi
  [ "$INSTALLED" = "unknown" ] && say "  warning: install predates VERSION tracking — reinstall to upgrade"
  ok "complete bundle verified in $OPENCODE_DIR ($INSTALLED)"
  exit 0
fi

# --- auth header for private repos ---
AUTH=()
if [ -n "${GH_TOKEN:-}${GITHUB_TOKEN:-}" ]; then
  AUTH=(-H "Authorization: Bearer ${GH_TOKEN:-$GITHUB_TOKEN}")
fi

# --- resolve version (default: latest release) ---
# Skipped in local-bundle mode (the bundle's tag is embedded in its name).
if [ -z "${OPENSTATE_LOCAL_BUNDLE:-}" ]; then
if [ -z "$VERSION" ]; then
  say "resolving latest openstate release..."
  TAG="$(curl -fsSL "${AUTH[@]}" "https://api.github.com/repos/$REPO/releases/latest" \
    | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p')"
  [ -n "$TAG" ] || fail "could not resolve latest release for $REPO"
else
  TAG="$VERSION"
fi
fi
say "openstate installer — $REPO @ ${TAG:-local} ($PLATFORM)"

# --- download release asset (public: browser URL; private: API endpoint) ---
ASSET="openstate-$TAG-$PLATFORM.tar.gz"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

# --- LOCAL BUNDLE MODE: install from a prebuilt tarball (dev/offline) ---
# OPENSTATE_LOCAL_BUNDLE=/path/openstate-v0.1.0-linux-x86_64.tar.gz ./install.sh
# Skips the download + checksum (the tarball is local), installs idempotently,
# and REPLACES any existing skill/plugin/engine (cp overwrites). For dogfooding
# the current build before a release exists.
if [ -n "${OPENSTATE_LOCAL_BUNDLE:-}" ]; then
  say "using local bundle: $OPENSTATE_LOCAL_BUNDLE"
  [ -f "$OPENSTATE_LOCAL_BUNDLE" ] || fail "local bundle not found: $OPENSTATE_LOCAL_BUNDLE"
  # Derive TAG from the filename openstate-<TAG>-<PLATFORM>.tar.gz
  BASE="$(basename "$OPENSTATE_LOCAL_BUNDLE")"
  TAG="$(printf '%s' "$BASE" | sed -E 's/^openstate-([^-]+)-.*/\1/')"
  cp "$OPENSTATE_LOCAL_BUNDLE" "$TMPDIR/$ASSET"
else
case " $OPENSTATE_PUBLISHED_PLATFORMS " in
  *" $PLATFORM "*) ;;
  *) fail "no prebuilt openstate bundle for $PLATFORM (available: $OPENSTATE_PUBLISHED_PLATFORMS)" ;;
esac
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
fi

# --- verify checksum (published alongside the asset) ---
# Skipped in local-bundle mode: the tarball is trusted local input.
if [ -z "${OPENSTATE_LOCAL_BUNDLE:-}" ]; then
if [ ${#AUTH[@]} -gt 0 ]; then
  SHA_ASSET_ID="$(printf '%s' "$RELEASE_JSON" | python3 -c "
import sys, json
d = json.load(sys.stdin)
for a in d.get('assets', []):
    if a['name'] == '$ASSET.sha256':
        print(a['id']); break
" 2>/dev/null)"
  [ -n "$SHA_ASSET_ID" ] || fail "checksum asset $ASSET.sha256 not found in release $TAG"
  curl -fsSL "${AUTH[@]}" -H "Accept: application/octet-stream" \
    -o "$TMPDIR/$ASSET.sha256" \
    "https://api.github.com/repos/$REPO/releases/assets/$SHA_ASSET_ID"
  sha256_verify_companion "$TMPDIR/$ASSET" "$TMPDIR/$ASSET.sha256" \
    || fail "checksum mismatch — aborting (possible corruption or tampering)"
  ok "checksum verified"
else
  curl -fsSL -o "$TMPDIR/$ASSET.sha256" \
    "https://github.com/$REPO/releases/download/$TAG/$ASSET.sha256" \
    || fail "checksum asset missing for $ASSET"
  sha256_verify_companion "$TMPDIR/$ASSET" "$TMPDIR/$ASSET.sha256" \
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
    '{"type":"observation","event":"file.edited","data":{"path":"smoke.rs"},"repo_root":"'"$SMOKE_DIR"'"}' \
    '{"type":"query","query":"state","repo_root":"'"$SMOKE_DIR"'"}' \
  | OPENSTATE_STATE="$SMOKE_DIR/state.jsonl" "$TMPDIR/x/bin/$ENGINE_NAME" 2>/dev/null \
  | tail -1
)"
echo "$RESPONSE" | grep -q '"facts"' || fail "engine smoke test failed: $RESPONSE"
rm -rf "$SMOKE_DIR"
ok "engine responds to observation + state query"

# ---------- install ----------
# Version awareness: detect a prior install so upgrade/downgrade/reinstall
# is announced and the new VERSION marker is written on success.
PRIOR_VERSION="$(cat "$VERSION_FILE" 2>/dev/null || echo "")"
if [ -n "$PRIOR_VERSION" ]; then
  CMP="$(version_cmp "$PRIOR_VERSION" "${TAG:-local}")"
  case "$CMP" in
    "=")  say "reinstalling $PRIOR_VERSION (already current — idempotent overwrite)" ;;
    "<")  say "upgrading $PRIOR_VERSION -> ${TAG:-local}" ;;
    ">")  say "downgrading $PRIOR_VERSION -> ${TAG:-local} (explicitly requested)" ;;
  esac
else
  say "fresh install -> ${TAG:-local}"
fi

# openstate-es8: catch a corrupt state path BEFORE writing anything, so the
# fix happens before the new engine ever spawns against it.
validate_state_path "$(dirname "$OPENCODE_DIR")"

say "installing to $OPENCODE_DIR"
mkdir -p "$PLUGIN_DIR" "$SKILL_DIR" "$BIN_DIR" "$MCP_DIR"
if [ "$INSTALL_SCOPE" = "repo" ]; then
  printf '{"version":1,"scope":"repo"}\n' > "$SCOPE_FILE"
else
  rm -f "$SCOPE_FILE"
fi

# stop a previous install's engine BEFORE replacing the binary (a running
# process keeps the OLD code in memory; two engines on one state file would
# fight over the lock). The next tool call respawns the new binary.
if [ -x "$BIN_DIR/$ENGINE_NAME" ]; then
  pkill -f "$BIN_DIR/$ENGINE_NAME" 2>/dev/null || true
  sleep 0.2
  say "  stopped prior engine process"
fi

# openstate-es8: also stop engines holding THIS repo's state lock whose
# binary lives elsewhere (global-mode installs survive the pkill above).
stop_lock_holder_engines

mkdir -p "$PLUGIN_DIR/openstate"
cp "$TMPDIR/x/plugins/openstate/index.js" "$PLUGIN_DIR/openstate/index.js"
cp "$TMPDIR/x/plugins/openstate/tui.js"    "$PLUGIN_DIR/openstate/tui.js"
cp "$TMPDIR/x/bin/$AST_GREP_NAME"         "$BIN_DIR/$AST_GREP_NAME"
chmod +x "$BIN_DIR/$AST_GREP_NAME"
cp "$TMPDIR/x/skills/openstate/SKILL.md" "$SKILL_DIR/SKILL.md"
cp "$TMPDIR/x/mcp/openstate-mcp.mjs"      "$MCP_DIR/openstate-mcp.mjs"
cp "$TMPDIR/x/structural-tools-profile.json" "$PROFILE_FILE"
# Guarantee the skill landed with VALID front matter before we call it done.
skill_is_valid "$SKILL_DIR/SKILL.md" \
  || fail "installed skill is missing or malformed: $SKILL_DIR/SKILL.md"

# Bootstrap a minimal opencode.jsonc if the repo has none. This is the signal
# that tells OpenCode ".opencode/ is a config dir here" — without it, skill
# discovery can be skipped in some OpenCode versions. Harmless if one exists.
if [ ! -f "$OPENCODE_DIR/opencode.jsonc" ]; then
  cat > "$OPENCODE_DIR/opencode.jsonc" <<'OEC'
{
  "$schema": "https://opencode.ai/config.json"
}
OEC
  say "  bootstrapped minimal .opencode/opencode.jsonc (skill discovery marker)"
fi

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

# Record installed version + engine integrity hash (atomic, after success).
printf '%s\n' "${TAG:-local}" > "${VERSION_FILE}.tmp" \
  && mv -f "${VERSION_FILE}.tmp" "$VERSION_FILE"
sha256_for "$ENGINE_DEST" > "${MANIFEST_FILE}.tmp" \
  && mv -f "${MANIFEST_FILE}.tmp" "$MANIFEST_FILE"

# WSL2: if .openstate would live on a Windows-mounted FS (/mnt/c/...),
# the engine's atomic writes block in D-state. Move state to native Linux
# FS and symlink from the repo so writes never cross the bridge.
STATE_DIR="$OPENCODE_DIR/../.openstate"
# s9bf.25: only for a repository on a Windows mount, as described above; a
# repository on the Linux FS keeps its own .openstate/ (and a test install in
# a temp dir never writes into ~/.openstate).
REPO_ROOT="$(cd "$(dirname "$OPENCODE_DIR")" && pwd -P)"
if grep -qiE "microsoft|wsl" /proc/version 2>/dev/null && case "$REPO_ROOT" in /mnt/[a-zA-Z]/*) true ;; *) false ;; esac; then
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

# Structural-tools profile is opt-in. Shadow records the selected mode without
# changing OpenCode permissions; enforce denies the direct edit/search escape
# hatches (edit/write/apply_patch via `edit`, the builtin grep tool, and shell
# grep/sed invocations) while retaining reads, glob, and FULL shell/build
# access (cargo/git/npm/node untouched). off restores the pre-profile config.
# Config changes require restart.
if [ "$STRUCTURAL_MODE" = "enforce" ]; then
  [ -f "$PROFILE_BACKUP" ] || cp -f "$OPENCODE_DIR/opencode.jsonc" "$PROFILE_BACKUP"
  OPENCODE_CONFIG="$OPENCODE_DIR/opencode.jsonc" OPENSTATE_PROFILE="$PROFILE_FILE" node - <<'NODE'
const fs = require("fs");
const path = process.env.OPENCODE_CONFIG;
const profile = JSON.parse(fs.readFileSync(process.env.OPENSTATE_PROFILE, "utf8"));
function parseJsonc(text) {
  let out = "", string = false, escaped = false, line = false, block = false;
  for (let i = 0; i < text.length; i++) {
    const ch = text[i], next = text[i + 1];
    if (line) { if (ch === "\n") { line = false; out += ch; } continue; }
    if (block) { if (ch === "*" && next === "/") { block = false; i++; } else if (ch === "\n") out += ch; continue; }
    if (string) { out += ch; if (escaped) escaped = false; else if (ch === "\\") escaped = true; else if (ch === '"') string = false; continue; }
    if (ch === '"') { string = true; out += ch; continue; }
    if (ch === "/" && next === "/") { line = true; i++; continue; }
    if (ch === "/" && next === "*") { block = true; i++; continue; }
    out += ch;
  }
  return JSON.parse(out.replace(/,\s*([}\]])/g, "$1"));
}
const obj = parseJsonc(fs.readFileSync(path, "utf8"));
// openstate-n3s.6: V2 permissions are an ORDERED array of
// { action, resource, effect } rules (last match wins). Merge only the
// installer-owned rules; NEVER delete unrelated rules. The plugin-layer
// enforce tables still come from the profile file itself (readStructuralProfile);
// this config shape is what the V2 host permission system evaluates.
const priorRules = Array.isArray(obj.permissions) ? obj.permissions : [];
const ownedRules = Array.isArray(profile.permissions_v2) ? profile.permissions_v2 : [];
const merged = [...priorRules.filter((rule) => !ownedRules.some((owned) =>
  owned.action === rule.action && owned.resource === rule.resource)), ...ownedRules];
obj.permissions = merged;
if (Array.isArray(profile.instructions_override)) {
  obj.instructions = profile.instructions_override;
}
fs.writeFileSync(path, JSON.stringify(obj, null, 2) + "\n");
NODE
  printf '%s\n' enforce > "$PROFILE_MODE_FILE"
elif [ "$STRUCTURAL_MODE" = "shadow" ]; then
  # Shadow records selections without ever denying: undo a prior enforce.
  if [ -f "$PROFILE_BACKUP" ]; then
    cp -f "$PROFILE_BACKUP" "$OPENCODE_DIR/opencode.jsonc"
    rm -f "$PROFILE_BACKUP"
  fi
  printf '%s\n' shadow > "$PROFILE_MODE_FILE"
elif [ -f "$PROFILE_BACKUP" ]; then
  cp -f "$PROFILE_BACKUP" "$OPENCODE_DIR/opencode.jsonc"
  rm -f "$PROFILE_BACKUP" "$PROFILE_MODE_FILE"
else
  rm -f "$PROFILE_MODE_FILE"
fi

AGENTS_FILE="$(dirname "$OPENCODE_DIR")/AGENTS.md"
if [ "$STRUCTURAL_MODE" = "enforce" ] && [ -f "$AGENTS_FILE" ]; then
  # Single source of truth (openstate-los): AGENTS.md's enforce block comes
  # from the SAME installed profile the opencode.jsonc writer uses — a
  # hard-coded heredoc here drifted from tools/structural-tools-profile.json.
  OPENSTATE_AGENTS_FILE="$AGENTS_FILE" OPENSTATE_PROFILE="$PROFILE_FILE" node -e '
    const fs = require("fs");
    const p = process.env.OPENSTATE_AGENTS_FILE;
    const profile = JSON.parse(fs.readFileSync(process.env.OPENSTATE_PROFILE, "utf8"));
    const lines = Array.isArray(profile.instructions_override) ? profile.instructions_override : ["Use the openstate structural tools for repository navigation and edits."];
    const template = lines.join("\n");
    // openstate-bs4: match EVERY structural block this installer has ever
    // written - enforce, shadow, off - so a block written by another mode can
    // never survive beside a fresh one and contradict it. The write path is
    // deterministic rather than branch-on-match: strip all, then emit exactly
    // one newline-terminated block, so a second run is byte-identical.
    const marker = "<!-- OPENSTATE-STRUCTURAL:enforce -->";
    const re = /<!-- OPENSTATE-STRUCTURAL(?::[a-z]+)? -->[\s\S]*?<!-- \/OPENSTATE-STRUCTURAL -->\r?\n*/g;
    const block = marker + "\n" + template + "\n" + "<!-- /OPENSTATE-STRUCTURAL -->\n";
    const text = fs.readFileSync(p, "utf8").replace(re, "").replace(/^\n+/, "");
    fs.writeFileSync(p, block + "\n" + text);
  '
  say "AGENTS.md: structural-tools instructions injected (enforce)"
elif [ -f "$AGENTS_FILE" ] && [ "$STRUCTURAL_MODE" != "enforce" ]; then
  OPENSTATE_AGENTS_FILE="$AGENTS_FILE" node -e '
    const fs = require("fs");
    const p = process.env.OPENSTATE_AGENTS_FILE;
    const text = fs.readFileSync(p, "utf8");
    // openstate-bs4: strip every variant, not just the enforce one.
    const re = /<!-- OPENSTATE-STRUCTURAL(?::[a-z]+)? -->[\s\S]*?<!-- \/OPENSTATE-STRUCTURAL -->\r?\n*/g;
    fs.writeFileSync(p, text.replace(re, ""));
  '
fi

# openstate-n3s.7/8: no tui.json — V2 CLI plugins are discovered from the
# server plugin list, so the installer neither creates nor edits tui.json.

# package.json — MERGE dependencies: preserve existing, add openstate deps.
# @opentui/solid stays (the TUI's JSX runtime); @opencode/plugin +
# @opencode/client power the V2 server plugin.
PKG_JSON="$OPENCODE_DIR/package.json" node -e '
  const fs = require("fs");
  const p = process.env.PKG_JSON;
  const add = {
    "@opencode/plugin": "2.0.18",
    "@opencode/client": "2.0.18",
    "@opentui/solid": "0.5.12"
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

ok "server plugin: .opencode/plugins/openstate/index.js"
ok "sidebar plugin: .opencode/plugins/openstate/tui.js (auto-discovered)"
ok "skill:          .opencode/skills/openstate/SKILL.md"
ok "engine:         .opencode/bin/$ENGINE_NAME"
ok "ast-grep:       .opencode/bin/$AST_GREP_NAME"
ok "MCP server:     .opencode/mcp/openstate-mcp.mjs (for other hosts; see README)"
ok "profile:        $STRUCTURAL_MODE"
ok "package.json:   .opencode/package.json (deps installed)"

# ---------- done ----------
say "done"
cat <<EOF

openstate is installed for this repo at $OPENCODE_DIR.
Only repos that run this installer will have openstate active —
nothing is written outside this .opencode/ directory.

>>> RESTART OPENCODE NOW <<<
The skill + tools are compiled into the agent at session start, so they
will NOT appear until you quit and relaunch OpenCode in this repo.

After restart you will see:
  • state/lifecycle tools plus the full structural suite: diagnostics, AST search, references, symbol overview, declarations, implementations, create_file, and preview/apply edit pairs for symbol/text replacement, move, delete, rename, and insertion
  • the openstate skill, which tells the AI when to use them
  • "● openstate · battery ready" in the session sidebar (CLI plugin, auto-discovered)
  • to pull an already-running session's history into the battery, run
    openstate_assess (idempotent — re-running never duplicates)

  Structural-tools edit profile: $STRUCTURAL_MODE
    • re-run this installer with OPENSTATE_STRUCTURAL_TOOLS=shadow|enforce|off
    • enforce denies edit + grep + shell sed/grep (build/test stay allowed); shadow records selections without blocking
    • CONFIG CHANGES REQUIRE AN OPENCODE RESTART

State lives per-project in .openstate/state.jsonl.

Installed version: ${TAG:-local} (recorded in $VERSION_FILE)
  • re-run this installer to update in place (idempotent, overwrites bundle)
  • check status anytime with: ./install.sh --check
  • pin a version with: OPENSTATE_VERSION=vX.Y.Z ./install.sh
  • verify a specific version: OPENSTATE_EXPECT_VERSION=vX.Y.Z ./install.sh --check

Verify later with: ./install.sh --check
EOF