#!/bin/sh
set -eu
file="${1:?usage: release-sha.sh <release.yaml>}"
tags="$(sed -nE 's/.*tag: (sha-[0-9a-f]{40}).*/\1/p' "$file" | sort -u)"
test "$(printf '%s\n' "$tags" | sed '/^$/d' | wc -l | tr -d ' ')" -eq 1 || {
  echo "$file must contain exactly one immutable release SHA" >&2
  exit 1
}
printf '%s\n' "$tags"
