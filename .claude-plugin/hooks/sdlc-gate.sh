#!/usr/bin/env bash
# PreToolUse gate: a spec needs an accepted intent, a plan needs an approved spec.
# Reads a hook payload on stdin; exit 2 blocks the write.
set -euo pipefail

command -v jq >/dev/null 2>&1 || exit 0

path=$(jq -r '.tool_input.file_path // empty')
[[ -n $path ]] || exit 0

case $path in
  */docs/sdlc/spec/*) stage=spec; upstream=intent; want=accepted ;;
  */docs/sdlc/plan/*) stage=plan; upstream=spec;   want=approved ;;
  *) exit 0 ;;
esac

base=${path##*/}
number=${base%%-*}
[[ $number =~ ^[0-9]{4}$ ]] || exit 0

root=${path%/docs/sdlc/*}
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
