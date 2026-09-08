#!/usr/bin/env bash
# PreToolUse gate: a spec needs an accepted intent, a plan needs an approved spec.
# Reads a hook payload on stdin; exit 2 blocks the write.
#
# Write and Edit name their target outright. A shell command does not, so its
# coverage is best-effort: the path has to appear literally next to a redirect or
# a mutating command. A path built from a variable still slips through.
set -euo pipefail

command -v jq >/dev/null 2>&1 || exit 0

payload=$(cat)
cwd=$(jq -r '.cwd // empty' <<<"$payload")
file_path=$(jq -r '.tool_input.file_path // empty' <<<"$payload")
cmd=$(jq -r '.tool_input.command // empty' <<<"$payload")

writes=$'(^|[[:space:];&|(])(tee|cp|mv|rm|touch|install|ln|dd|truncate)([[:space:]]|$)|sed[[:space:]]+-[^[:space:]]*i|>'
candidates=$file_path
if [[ -n $cmd ]] && grep -qE "$writes" <<<"$cmd"; then
  candidates+=$'\n'$cmd
fi

# Path characters only: a broader class swallows a shell prefix like f=<path>,
# which then derives a garbage root and blocks a chain whose upstream is fine.
pattern='[A-Za-z0-9_./-]*docs/sdlc/(spec|plan)/[0-9]{4}[A-Za-z0-9_./-]*'
targets=$(grep -oE "$pattern" <<<"$candidates" | sort -u) || exit 0

while IFS= read -r path; do
  [[ -n $path ]] || continue
  case $path in
    *docs/sdlc/spec/*) stage=spec; upstream=intent; want=accepted ;;
    *docs/sdlc/plan/*) stage=plan; upstream=spec;   want=approved ;;
    *) continue ;;
  esac

  base=${path##*/}
  number=${base%%-*}
  [[ $number =~ ^[0-9]{4}$ ]] || continue

  root=${path%%docs/sdlc/*}
  root=${root%/}
  [[ -n $root ]] || root=${cwd:-.}

  shopt -s nullglob
  matches=("$root/docs/sdlc/$upstream/$number-"*.md)
  file=${matches[0]:-}

  if [[ -z $file ]]; then
    echo "Blocked: $stage $number has no $upstream in docs/sdlc/$upstream/." >&2
    exit 2
  fi

  status=$(sed -n '/^---$/,/^---$/p' "$file" | sed -n 's/^status:[[:space:]]*//p' | head -1)
  if [[ $status != "$want" ]]; then
    echo "Blocked: $upstream $number is '${status:-unset}', not '$want'. A human moves that gate." >&2
    exit 2
  fi
done <<<"$targets"
