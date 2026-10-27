#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Oksigenia S.L.
#
# Check every seal of the repository you are in:
#   - each manifest's tree matches its commit;
#   - each OpenTimestamps proof (a proof still waiting for its Bitcoin block
#     is reported as pending, not as a failure);
#   - the SSH signature of each provenance-* tag against <dir>/allowed_signers,
#     and that the tag sits on a sealed commit. Older tags (ots-priority-*,
#     prior-art-*) are checked for their signature only.
# Exit status 1 if anything fails. Fetch the tags first (git fetch --tags).
#
# Settings (environment, all optional):
#   PROVENANCE_DIR  folder for the proofs (default: provenance)
#   OTS             OpenTimestamps client (default: ots)
set -uo pipefail

root=$(git rev-parse --show-toplevel) || exit 1
cd "$root"
dir=${PROVENANCE_DIR:-provenance}
ots=${OTS:-ots}
signers="$dir/allowed_signers"
fail=0
bad() { echo "  FAIL: $*"; fail=1; }

command -v "$ots" >/dev/null || { echo "verify: OpenTimestamps client not found (set OTS)" >&2; exit 1; }
[ -f "$signers" ] || { echo "verify: $signers is missing" >&2; exit 1; }

shopt -s nullglob
for proof in "$dir"/*.ots; do
  manifest=${proof%.ots}
  echo "== $manifest"
  [ -f "$manifest" ] || { bad "manifest missing"; continue; }

  # Current format "Commit:"/"Tree:"; the first VivaWebs seals used "Git commit (HEAD):"/"Git tree (contenido):".
  commit=$(grep -m1 -E '^(Commit|Git commit)[^:]*:' "$manifest" | awk '{print $NF}')
  tree=$(grep -m1 -E '^(Tree|Git tree)[^:]*:' "$manifest" | awk '{print $NF}')
  if [ -z "$commit" ] || [ -z "$tree" ]; then
    echo "  tree: not in this manifest (old format)"
  elif actual=$(git rev-parse -q --verify "$commit^{tree}"); then
    [ "$actual" = "$tree" ] && echo "  tree: matches commit ${commit:0:12}" || bad "tree $tree does not match commit $commit ($actual)"
  else
    bad "commit $commit is not in this clone"
  fi

  out=$("$ots" verify "$proof" 2>&1)
  if grep -q '^Success!' <<<"$out"; then
    echo "  ots: $(grep -m1 '^Success!' <<<"$out")"
  elif grep -qi 'pending' <<<"$out"; then
    echo "  ots: pending, run upgrade.sh in a few hours"
  else
    bad "ots verify"; sed 's/^/    /' <<<"$out"
  fi
done

for tag in $(git tag -l 'provenance-*' 'ots-priority-*' 'prior-art-*'); do
  echo "== tag $tag"
  if out=$(git -c gpg.ssh.allowedSignersFile="$signers" verify-tag "$tag" 2>&1); then
    echo "  signature: $(grep -o 'Good "git" signature for [^ ]*' <<<"$out")"
  else
    bad "signature does not verify against $signers"
  fi
  case $tag in
    provenance-*)
      c=$(git rev-parse "$tag^{commit}")
      grep -qsF "$c" "$dir"/*.manifest.txt && echo "  sealed commit: ${c:0:12}" || bad "tag is not on a sealed commit ($c)" ;;
  esac
done

[ $fail = 0 ] && echo "All checks passed." || echo "Some checks failed."
exit $fail
