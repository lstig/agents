#!/usr/bin/env bash
# PreToolUse gate: a spec needs an accepted intent, a plan needs an approved spec.
# Reads a hook payload on stdin; exit 2 blocks the write.
#
# An artifact is recognised by shape, not by a fixed path: a write to
# <...>/<container>/NNNN-slug/<stage>.md is gated wherever that sits in the tree,
# where <container> is a directory named "$SDLC_DIR" (default "changes").
#
# Write and Edit name their target outright, and that path is normalised before
# it is matched, so any spelling of it -- "//", "/./", "a/../a" -- gates the same
# file. Symlinks are not followed, so a path reaching the artifact through a
# symlinked directory is not recognised. A shell command names nothing outright,
# so its coverage is best-effort: the path has to appear literally next to a
# redirect or a mutating command, spelled in ordinary path characters and without
# "." or ".." segments. A path built from a variable, or one holding a space,
# still slips through.
set -euo pipefail

command -v jq >/dev/null 2>&1 || exit 0

container=${SDLC_DIR:-changes}

# Folds "//", "/./" and "x/.." out of a path. The decomposition below requires
# the container to be the chain directory's immediate parent, so an unnormalised
# spelling of a gated file decomposes to a parent that never matches and is
# waved through -- the silent fail-open this gate exists to avoid. Done by text
# rather than realpath because the target is a proposed write and need not exist.
normalize() {
  local p=$1 lead= out= part rest
  case $p in /*) lead=/ ;; esac
  rest=$p
  while [[ -n $rest ]]; do
    part=${rest%%/*}
    if [[ $part == "$rest" ]]; then rest=; else rest=${rest#*/}; fi
    # The patterns are quoted: unquoted "." and ".." are globs, and would match
    # any one- or two-character component.
    case $part in
      ''|'.') ;;
      '..')
        case $out in
          # Nothing to pop. A relative path keeps its leading "..", which names a
          # real directory; an absolute one cannot climb above "/".
          ''|'..'|*/'..') [[ -n $lead ]] || out=${out:+$out/}.. ;;
          */*) out=${out%/*} ;;
          *) out= ;;
        esac
        ;;
      *) out=${out:+$out/}$part ;;
    esac
  done
  printf '%s\n' "$lead$out"
}

payload=$(cat)
cwd=$(jq -r '.cwd // empty' <<<"$payload")
file_path=$(jq -r '.tool_input.file_path // empty' <<<"$payload")
[[ -n $file_path ]] && file_path=$(normalize "$file_path")
cmd=$(jq -r '.tool_input.command // empty' <<<"$payload")
# What the write proposes to put in the file: Write sends the whole thing, Edit a
# substitution to apply to it, Bash neither.
content=$(jq -r '.tool_input.content // empty' <<<"$payload")
# Distinguished from an absent key: writing an empty file is a proposal too, and
# it is one that removes the change-id.
has_content=$(jq -r 'if (.tool_input? | objects | has("content")) then 1 else empty end' <<<"$payload")
old_string=$(jq -r '.tool_input.old_string // empty' <<<"$payload")
new_string=$(jq -r '.tool_input.new_string // empty' <<<"$payload")
replace_all=$(jq -r '.tool_input.replace_all // empty' <<<"$payload")
# A batched edit puts its substitutions in an array instead of naming one pair.
# The hook matcher is a substring match on the tool name, so MultiEdit-shaped
# payloads arrive here too and have to be reconstructed rather than waved past
# the change-id check.
edits_count=$(jq -r '(.tool_input? | objects | .edits? | arrays | length) // empty' <<<"$payload")

writes=$'(^|[[:space:];&|(])(tee|cp|mv|rm|touch|install|ln|dd|truncate)([[:space:]]|$)|sed[[:space:]]+-[^[:space:]]*i|>'
candidates=$file_path
if [[ -n $cmd ]] && grep -qE "$writes" <<<"$cmd"; then
  candidates+=$'\n'$cmd
fi

# Path characters only: a broader class swallows a shell prefix like f=<path>,
# which then derives a garbage root and blocks a chain whose upstream is fine.
# The last component is matched whole rather than as "spec.md" or "plan.md": a
# pattern anchored only at the front also matches the prefix of "spec.md.bak",
# and would gate a file that is not an artifact. The stage is decided below,
# from the complete component.
pattern='[A-Za-z0-9_./-]*/[0-9]{4}-[A-Za-z0-9_.-]*/[A-Za-z0-9_.-]+'
targets=$(grep -oE "$pattern" <<<"$candidates" | sort -u) || exit 0

# Reads one frontmatter key from a document on stdin. A YAML scalar may be
# quoted -- "0003" and 0003 are the same value -- so surrounding quotes are
# stripped, or the comparison fails against two strings that print identically.
key_of() {
  local value
  value=$(sed -n '/^---$/,/^---$/p' | sed -n "s/^$1:[[:space:]]*//p" | head -1)
  value=${value%"${value##*[![:space:]]}"}
  case $value in
    \"*\") value=${value#\"}; value=${value%\"} ;;
    \'*\') value=${value#\'}; value=${value%\'} ;;
  esac
  printf '%s\n' "$value"
}

while IFS= read -r path; do
  [[ -n $path ]] || continue

  # The extracted substring stops at the first character outside the path class,
  # so a checkout under "/My Repo/" yields a truncated path that resolves to
  # nothing. When the payload names the file outright, trust that instead and
  # keep the grep result for shell commands, which name nothing.
  target=$path
  [[ -n $file_path && $file_path == *"$path" ]] && target=$file_path
  target=$(normalize "$target")

  stage_file=${target##*/}
  chain_dir=${target%/*}
  chain=${chain_dir##*/}
  # The container is matched as a directory name, so the chain directory's parent
  # has to be exactly that name — "mychanges/0003-x/spec.md" is not an artifact.
  parent=${chain_dir%/*}
  [[ $parent == "$container" || $parent == */"$container" ]] || continue

  number=${chain%%-*}
  [[ $number =~ ^[0-9]{4}$ ]] || continue

  case $stage_file in
    spec.md) stage=spec; upstream=intent; want=accepted ;;
    plan.md) stage=plan; upstream=spec;   want=approved ;;
    *) continue ;;
  esac

  if [[ $target == /* ]]; then abs=$target; else abs=${cwd:-.}/$target; fi

  # The artifact has to agree with the directory holding it, checked against the
  # text the write proposes rather than the text already on disk. Checking the
  # disk would block the edit that fixes a wrong or missing change-id, which is
  # the one write a misfiled or pre-migration artifact needs. A shell write
  # proposes text the hook cannot reconstruct, so it is left to the next Write or
  # Edit -- letting a mismatch through beats trapping it with no way out.
  proposed=
  have_proposed=
  if [[ -n $file_path && $target == "$file_path" ]]; then
    if [[ -n $has_content ]]; then
      proposed=$content
      have_proposed=1
    elif [[ -n $edits_count && $edits_count -gt 0 && -f $abs ]]; then
      # A batched edit applies its substitutions in order, so replaying them in
      # order over the current text reconstructs what the tool will write.
      proposed=$(cat "$abs"; printf x)
      proposed=${proposed%x}
      for (( i = 0; i < edits_count; i++ )); do
        e_old=$(jq -r --argjson i "$i" '.tool_input.edits[$i].old_string // empty' <<<"$payload")
        e_new=$(jq -r --argjson i "$i" '.tool_input.edits[$i].new_string // empty' <<<"$payload")
        e_all=$(jq -r --argjson i "$i" '.tool_input.edits[$i].replace_all // empty' <<<"$payload")
        # An empty old_string has no insertion point to replay; substituting it
        # would splice new_string between every character.
        [[ -n $e_old ]] || continue
        if [[ $e_all == true ]]; then
          proposed=${proposed//"$e_old"/"$e_new"}
        else
          proposed=${proposed/"$e_old"/"$e_new"}
        fi
      done
      have_proposed=1
    elif [[ ( -n $old_string || -n $new_string ) && -f $abs ]]; then
      # An empty new_string is a deletion -- the write that makes a change-id
      # missing -- so it has to be reconstructed and checked like any other.
      proposed=$(cat "$abs"; printf x)
      proposed=${proposed%x}
      if [[ $replace_all == true ]]; then
        proposed=${proposed//"$old_string"/"$new_string"}
      else
        proposed=${proposed/"$old_string"/"$new_string"}
      fi
      have_proposed=1
    fi
  fi
  if [[ -n $have_proposed ]]; then
    change_id=$(key_of change-id <<<"$proposed")
    if [[ $change_id != "$number" ]]; then
      echo "Blocked: $stage change-id is '${change_id:-unset}', but $chain_dir is change $number." >&2
      exit 2
    fi
  fi

  upstream_file=${abs%/*}/$upstream.md
  if [[ ! -f $upstream_file ]]; then
    echo "Blocked: $stage $number has no $upstream — $chain_dir/$upstream.md is missing." >&2
    exit 2
  fi

  status=$(key_of status <"$upstream_file")
  if [[ $status != "$want" ]]; then
    echo "Blocked: $upstream $number is '${status:-unset}', not '$want'. A human moves that gate." >&2
    exit 2
  fi
done <<<"$targets"
