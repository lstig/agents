#!/usr/bin/env bash
# Prints the next unused four-digit change number in a container of chain
# directories. The container is the required argument: this script deliberately
# does not know where a repo puts one -- that default lives only in
# SDLC-FORMAT.md -- because guessing wrong means scanning an empty path and
# handing back a number already in use.
set -euo pipefail

root=${1:-}
if [[ -z $root ]]; then
  echo "usage: sdlc-next.sh <container>" >&2
  exit 1
fi

# A container that is empty or does not exist yet is the first change, not an
# error: find exits non-zero there, and pipefail would otherwise kill the script.
highest=$(find "$root" -mindepth 1 -maxdepth 1 -type d -name '[0-9][0-9][0-9][0-9]-*' 2>/dev/null |
  sed 's|.*/||; s|-.*||' | sort -n | tail -1) || true
printf '%04d\n' $(( 10#${highest:-0} + 1 ))
