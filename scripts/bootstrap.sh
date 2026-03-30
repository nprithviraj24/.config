#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
skills_source="$repo_root/skills"
claude_home="${CLAUDE_HOME:-$HOME/.claude}"
claude_skills_path="$claude_home/skills"

mkdir -p "$claude_skills_path"

found_skills=0

for skill_dir in "$skills_source"/*; do
    if [[ ! -d "$skill_dir" ]]; then
        continue
    fi

    if [[ ! -f "$skill_dir/SKILL.md" ]]; then
        continue
    fi

    found_skills=1
    skill_name="$(basename "$skill_dir")"
    link_path="$claude_skills_path/$skill_name"

    if [[ -L "$link_path" ]]; then
        current_target="$(readlink "$link_path" || true)"
        if [[ "$current_target" == "$skill_dir" ]]; then
            echo "Already linked: $link_path"
            continue
        fi

        rm "$link_path"
    elif [[ -e "$link_path" ]]; then
        backup_path="$link_path.backup-$(date +%Y%m%d-%H%M%S)"
        mv "$link_path" "$backup_path"
        echo "Backed up existing path to $backup_path"
    fi

    ln -sfn "$skill_dir" "$link_path"
    echo "Linked $link_path -> $skill_dir"
done

if [[ "$found_skills" -eq 0 ]]; then
    echo "No repo-managed skills found under $skills_source"
    exit 0
fi

echo
echo "Bootstrap complete."
echo "Claude skills path: $claude_skills_path"
