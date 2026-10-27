#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Oksigenia S.L.
#
# Seal the current commit of the repository you are in:
#   1. write <dir>/<name>-<date>.manifest.txt (repository, commit, git tree,
#      UTC date and holder);
#   2. timestamp it with OpenTimestamps (<manifest>.ots);
#   3. create the SSH-signed tag provenance-<date> on the sealed commit and
#      check it against <dir>/allowed_signers.
# Needs a clean tree with HEAD pushed. It commits and pushes nothing.
#
# Settings (environment, all optional):
#   PROVENANCE_KEY     key that signs the tag: a public key file whose private
#                      half is in the ssh-agent, or "key::ssh-ed25519 AAAA...".
#                      Default: git config user.signingkey.
#   PROVENANCE_DIR     folder for the proofs (default: provenance)
#   PROVENANCE_NAME    manifest prefix (default: the repository name)
#   PROVENANCE_HOLDER  owner named in the manifest (default: Oksigenia S.L.)
#   OTS                OpenTimestamps client (default: ots)
set -euo pipefail

die() { echo "seal: $*" >&2; exit 1; }

root=$(git rev-parse --show-toplevel)
cd "$root"
dir=${PROVENANCE_DIR:-provenance}
ots=${OTS:-ots}
holder=${PROVENANCE_HOLDER:-Oksigenia S.L.}
key=${PROVENANCE_KEY:-$(git config --get user.signingkey || true)}
signers="$dir/allowed_signers"

# owner/name from the origin URL (https or ssh); never a local path or credentials
url=$(git remote get-url origin 2>/dev/null || true)
repo=$(printf '%s\n' "$url" | sed -E 's#\.git$##; s#^.*[:/]([^/:]+/[^/:]+)$#\1#')
[ -n "$repo" ] && [ "$repo" != "$url" ] || repo=$(basename "$root")
name=${PROVENANCE_NAME:-${repo##*/}}

command -v "$ots" >/dev/null || die "OpenTimestamps client not found: pip install --require-hashes -r ots-requirements.txt, or set OTS"
if [ -d timestamps ] && [ ! -d "$dir" ]; then
  die "old seals in timestamps/: run 'git mv timestamps $dir', update its README, commit and push, then seal"
fi
[ -f "$signers" ] || die "$signers is missing: add the public key of the signing identity first"
[ -n "$key" ] || die "no signing key: set PROVENANCE_KEY or git config user.signingkey"

# The tag only proves authorship if its key is the one published in allowed_signers.
case $key in
  key::*) pub=${key#key::} ;;
  *) f=${key/#\~/$HOME}; [ -f "$f.pub" ] && f="$f.pub"; pub=$(cat "$f") || die "cannot read $key" ;;
esac
blob=$(printf '%s\n' "$pub" | awk '{print $2}')
[ -n "$blob" ] && grep -qF -- "$blob" "$signers" || die "the signing key is not in $signers"

[ -z "$(git status --porcelain --untracked-files=no)" ] || die "there are uncommitted changes"
git fetch -q origin
upstream=$(git rev-parse -q --verify '@{u}' || true)
[ -n "$upstream" ] && [ "$(git rev-parse HEAD)" = "$upstream" ] || die "HEAD is not pushed to its upstream branch"

day=$(date -u +%F)
tag="provenance-$day"
manifest="$dir/$name-$day.manifest.txt"
git rev-parse -q --verify "refs/tags/$tag" >/dev/null && die "tag $tag already exists"
! git ls-remote --exit-code --tags origin "refs/tags/$tag" >/dev/null 2>&1 || die "tag $tag already exists on origin"
[ ! -e "$manifest" ] || die "$manifest already exists"

commit=$(git rev-parse HEAD)
tree=$(git rev-parse 'HEAD^{tree}')
cat > "$manifest" <<TXT
Provenance seal (OpenTimestamps)
================================

Repository:   $repo
Holder:       $holder
Commit:       $commit
Tree:         $tree
Commit date:  $(git show -s --format=%cI HEAD)
Sealed (UTC): $(date -u +%FT%TZ)
Signed tag:   $tag

This file pins the state of the repository. Its .ots proof anchors it in the
Bitcoin blockchain through OpenTimestamps: the content existed no later than
the time of that block. The tree hash identifies the content alone, so a later
copy with the same files has the same tree. The signed tag adds who sealed it.

Verify:
  git rev-parse $commit^{tree}
  ots verify $name-$day.manifest.txt.ots
  git -c gpg.ssh.allowedSignersFile=$signers verify-tag $tag
TXT

"$ots" stamp "$manifest" || { rm -f "$manifest"; die "ots stamp failed"; }
git -c gpg.format=ssh -c user.signingkey="$key" tag -s "$tag" -m "Provenance seal $day ($manifest)" "$commit"
if ! git -c gpg.ssh.allowedSignersFile="$signers" verify-tag "$tag" >/dev/null 2>&1; then
  git tag -d "$tag" >/dev/null
  die "the new tag does not verify against $signers (deleted)"
fi

cat <<EOF
Sealed $commit
  manifest: $manifest (+ .ots, pending until Bitcoin confirms it)
  tag:      $tag, signed by $(git config --get user.email || echo '?')
Next:
  1. commit $dir/ and push it (through a pull request if the branch is protected);
  2. git push origin $tag
  3. in a few hours, upgrade.sh completes the proof (the provenance-upgrade job does it, where installed).
EOF
