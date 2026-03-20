#!/usr/bin/env bash

set -euo pipefail

# Helm post-renderer for the Backstage chart.
#
# Purpose:
# - Read the fully rendered manifest stream from stdin.
# - Find the Backstage Deployment in the "backstage" namespace.
# - Inject `spec.strategy.type = Recreate` if it is missing.
#
# Why:
# - Rolling updates can briefly run more than one Backstage pod.
# - Backstage startup runs database migrations, and concurrent pods can
#   contend on the shared PostgreSQL migration lock.
# - Forcing `Recreate` ensures the old pod is terminated before the new pod
#   starts, which avoids that contention during upgrades or replacements.
#
# Notes:
# - This script is invoked by the Helm provider `postrender` hook in
#   `modules/backstage/main.tf`.
# - The match currently assumes the Deployment namespace is literally
#   `backstage`, so it should be updated if the release namespace becomes
#   configurable in practice.

tmp_file="$(mktemp)"
trap 'rm -f "$tmp_file"' EXIT

cat >"$tmp_file"

awk '
function patch_doc(doc) {
  if (doc !~ /kind:[[:space:]]*Deployment/ || doc !~ /name:[[:space:]]*backstage/ || doc !~ /namespace:[[:space:]]*"backstage"/) {
    return doc
  }

  if (doc ~ /\n  strategy:\n    type: Recreate\n/) {
    return doc
  }

  sub(/\nspec:\n/, "\nspec:\n  strategy:\n    type: Recreate\n", doc)
  return doc
}

BEGIN {
  RS = "\n---\n"
  ORS = ""
}

{
  if (NR > 1) {
    printf "\n---\n"
  }

  printf "%s", patch_doc($0)
}
' "$tmp_file"
