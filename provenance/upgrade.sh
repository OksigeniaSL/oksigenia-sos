#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Oksigenia S.L.
#
# Complete the pending OpenTimestamps proofs of the repository you are in
# with their Bitcoin attestation. A fresh seal stays pending for a few hours;
# the provenance-upgrade job runs this every day. Rewrites only the proofs that
# change, leaves no .bak files behind, and commits nothing.
# Exit status 1 if a proof gives an error other than "pending".
#
# Settings (environment, all optional):
#   PROVENANCE_DIR  folder for the proofs (default: provenance)
#   OTS             OpenTimestamps client (default: ots)
set -uo pipefail

root=$(git rev-parse --show-toplevel) || exit 1
cd "$root"
dir=${PROVENANCE_DIR:-provenance}
ots=${OTS:-ots}
fail=0

command -v "$ots" >/dev/null || { echo "upgrade: OpenTimestamps client not found (set OTS)" >&2; exit 1; }

shopt -s nullglob
for proof in "$dir"/*.ots; do
  had_bak=0; [ -e "$proof.bak" ] && had_bak=1
  before=$(sha256sum "$proof" | cut -d' ' -f1)
  if out=$("$ots" upgrade "$proof" 2>&1); then ok=1; else ok=0; fi
  [ $had_bak = 1 ] || rm -f "$proof.bak"
  after=$(sha256sum "$proof" | cut -d' ' -f1)
  if [ $ok = 1 ]; then
    [ "$before" != "$after" ] && echo "completed now: $proof" || echo "complete: $proof"
  elif grep -q 'Pending confirmation' <<<"$out"; then
    echo "pending: $proof"
  else
    echo "error: $proof"; sed 's/^/  /' <<<"$out"; fail=1
  fi
done
exit $fail
