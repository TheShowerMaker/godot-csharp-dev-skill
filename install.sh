#!/usr/bin/env bash
# install.sh — Cross-tool installer for the godot-csharp-dev skill.
# Installs into ~/.claude/skills/ (Claude Code) and/or ~/.codex/skills/ (Codex).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_SRC="${SCRIPT_DIR}/godot-csharp-dev"

CLAUDE_DEST="${HOME}/.claude/skills"
CODEX_DEST="${HOME}/.codex/skills"

TARGET="${1:-auto}"

usage() {
    cat <<'EOF'
Usage: ./install.sh [target]

Targets:
  --claude       Install into ~/.claude/skills/
  --codex        Install into ~/.codex/skills/
  --both         Install into both
  --dest <path>  Install into <path>/godot-csharp-dev (overrides targets)
  auto           Default: detect existing dirs, install to whichever exists

Environment:
  CLAUDE_SKILLS_DIR  Override Claude skills directory (default: ~/.claude/skills)
  CODEX_SKILLS_DIR   Override Codex skills directory  (default: ~/.codex/skills)
EOF
    exit "${1:-0}"
}

if [ ! -f "${SKILL_SRC}/SKILL.md" ]; then
    echo "Error: ${SKILL_SRC}/SKILL.md not found." >&2
    exit 1
fi

CLAUDE_DEST="${CLAUDE_SKILLS_DIR:-${CLAUDE_DEST}}"
CODEX_DEST="${CODEX_SKILLS_DIR:-${CODEX_DEST}}"

CUSTOM_DEST=""
case "${TARGET}" in
    --claude) INSTALL_CLAUDE=1; INSTALL_CODEX=0 ;;
    --codex)  INSTALL_CLAUDE=0; INSTALL_CODEX=1 ;;
    --both)   INSTALL_CLAUDE=1; INSTALL_CODEX=1 ;;
    --dest)   CUSTOM_DEST="${2:-}"; INSTALL_CLAUDE=0; INSTALL_CODEX=0 ;;
    --help|-h) usage 0 ;;
    auto)
        INSTALL_CLAUDE=0; INSTALL_CODEX=0
        [ -d "${CLAUDE_DEST}" ] && INSTALL_CLAUDE=1
        [ -d "${CODEX_DEST}" ]  && INSTALL_CODEX=1
        if [ $INSTALL_CLAUDE -eq 0 ] && [ $INSTALL_CODEX -eq 0 ]; then
            echo "Neither ${CLAUDE_DEST} nor ${CODEX_DEST} exists." >&2
            echo "Run './install.sh --claude' or specify --dest." >&2
            exit 1
        fi
        ;;
    *) echo "Unknown target: ${TARGET}" >&2; usage 1 ;;
esac

install_to() {
    local dest_parent="$1"
    local dest="${dest_parent}/godot-csharp-dev"
    if [ -e "${dest}" ]; then
        echo "Updating existing ${dest}"
        rm -rf "${dest}"
    else
        echo "Installing to ${dest}"
    fi
    mkdir -p "${dest_parent}"
    cp -R "${SKILL_SRC}" "${dest}"
}

if [ -n "${CUSTOM_DEST}" ]; then
    install_to "${CUSTOM_DEST}"
    echo "Done: ${CUSTOM_DEST}/godot-csharp-dev"
    exit 0
fi

[ $INSTALL_CLAUDE -eq 1 ] && install_to "${CLAUDE_DEST}"
[ $INSTALL_CODEX  -eq 1 ] && install_to "${CODEX_DEST}"

echo "Done."
