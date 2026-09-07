#!/usr/bin/env bash
# Prints the next unused four-digit artifact number across all three stages.
set -euo pipefail

root=${1:-docs/sdlc}
highest=$(find "$root" -type f -name '[0-9][0-9][0-9][0-9]-*.md' 2>/dev/null |
  sed 's|.*/||; s|-.*||' | sort -n | tail -1)
printf '%04d\n' $(( 10#${highest:-0} + 1 ))
