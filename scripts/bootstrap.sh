#!/usr/bin/env bash
#
# Install repo-managed skills into every agent tool on this machine.
#
#   Claude  ~/.claude/skills/<name>   symlink -> skills/<name>
#   agy     ~/.gemini/skills/<name>   symlink -> skills/<name>
#   Codex   ~/.codex/skills/<name>    real copy of skills/<name> + codex/<name> overlay
#
# Claude and agy read the canonical skill verbatim, so they are symlinked and can
# never drift. Codex cannot be symlinked: its frontmatter validator rejects keys
# Claude uses (argument-hint, disable-model-invocation), and it reads an extra
# agents/openai.yaml. So Codex gets a copy with codex/<name>/ layered on top.
# Re-run this script after editing anything under skills/ or codex/.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
skills_source="$repo_root/skills"
codex_overlay="$repo_root/codex"

claude_skills="${CLAUDE_HOME:-$HOME/.claude}/skills"
gemini_skills="${GEMINI_HOME:-$HOME/.gemini}/skills"
codex_skills="${CODEX_HOME:-$HOME/.codex}/skills"

if [[ ! -d "$skills_source" ]]; then
    echo "No skills directory at $skills_source" >&2
    exit 1
fi

# Skills the overlay marks as not-for-Codex.
codex_excluded() {
    local name="$1"
    [[ -f "$codex_overlay/EXCLUDE" ]] || return 1
    grep -qxF "$name" <(grep -v '^[[:space:]]*#' "$codex_overlay/EXCLUDE") 2>/dev/null
}

# Move an existing non-symlink path aside rather than clobbering it.
back_up_if_real() {
    local path="$1"
    if [[ -L "$path" ]]; then
        rm "$path"
    elif [[ -e "$path" ]]; then
        local backup="$path.backup-$(date +%Y%m%d-%H%M%S)"
        mv "$path" "$backup"
        echo "  backed up existing $path -> $backup"
    fi
}

link_skill() {
    local skill_dir="$1" target_root="$2" name="$3"
    local link_path="$target_root/$name"

    if [[ -L "$link_path" && "$(readlink "$link_path")" == "$skill_dir" ]]; then
        echo "  already linked: $link_path"
        return
    fi

    back_up_if_real "$link_path"
    ln -sfn "$skill_dir" "$link_path"
    echo "  linked $link_path"
}

copy_skill_with_overlay() {
    local skill_dir="$1" target_root="$2" name="$3"
    local dest="$target_root/$name"

    back_up_if_real "$dest"
    rm -rf "$dest"
    cp -r "$skill_dir" "$dest"

    if [[ -d "$codex_overlay/$name" ]]; then
        cp -r "$codex_overlay/$name/." "$dest/"
        echo "  copied $dest (+ overlay)"
    else
        echo "  copied $dest"
    fi
}

mkdir -p "$claude_skills" "$gemini_skills" "$codex_skills"

found=0
for skill_dir in "$skills_source"/*; do
    [[ -d "$skill_dir" && -f "$skill_dir/SKILL.md" ]] || continue
    found=1
    name="$(basename "$skill_dir")"
    echo "$name"

    link_skill "$skill_dir" "$claude_skills" "$name"
    link_skill "$skill_dir" "$gemini_skills" "$name"

    if codex_excluded "$name"; then
        echo "  skipped for codex (listed in codex/EXCLUDE)"
    else
        copy_skill_with_overlay "$skill_dir" "$codex_skills" "$name"
    fi
done

if [[ "$found" -eq 0 ]]; then
    echo "No repo-managed skills found under $skills_source"
    exit 0
fi

echo
echo "Bootstrap complete."
echo "  Claude: $claude_skills"
echo "  agy:    $gemini_skills"
echo "  Codex:  $codex_skills"

validator="${CODEX_HOME:-$HOME/.codex}/skills/.system/skill-creator/scripts/quick_validate.py"
if [[ -f "$validator" ]]; then
    echo
    echo "Validate the Codex copies with:"
    echo "  for d in $codex_skills/*/; do python3 $validator \"\$d\"; done"
fi
