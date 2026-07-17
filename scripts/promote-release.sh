#!/bin/sh
set -eu
from="${1:?usage: promote-release.sh <from> <to> [sha]}"
to="${2:?usage: promote-release.sh <from> <to> [sha]}"
expected="${3:-}"
case "$from:$to" in dev:sit|sit:uat|uat:prod) ;; *) echo "invalid promotion $from -> $to" >&2; exit 1 ;; esac
source_file="releases/$from/release.yaml"
target_file="releases/$to/release.yaml"
sha="$(scripts/release-sha.sh "$source_file")"
test -z "$expected" || test "$sha" = "sha-$expected" || { echo "source is $sha, not sha-$expected" >&2; exit 1; }
cp "$source_file" "$target_file"
echo "Promoted $sha from $from to $to"
