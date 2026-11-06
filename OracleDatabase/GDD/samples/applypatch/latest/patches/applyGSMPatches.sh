#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
#
# Since: January, 2019
# Author: sanjay.singh@oracle.com, paramdeep.saini@oracle.com
# Description: Applies all patches to the Oracle Home
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Make sure Oracle perl binary is in PATH

set -Eeuo pipefail
shopt -s nullglob
export LC_ALL=C

die() {
  echo "ERROR: $*" >&2
  exit 1
}

trap 'status=$?; echo "ERROR: Patch script failed at line ${LINENO} (status ${status})." >&2; exit "$status"' ERR

[[ $# -le 1 ]] || die "Usage: $0 [patch-directory]"
[[ -n "${GSM_HOME:-}" && -d "$GSM_HOME" ]] || die "GSM_HOME must name an installed GSM home."
GSM_HOME=$(cd -- "$GSM_HOME" && pwd -P)
GSM_USER=${GSM_USER:-oracle}
PATCH_INSTALL_DIR=${1:-${PATCH_INSTALL_DIR:-/tmp/patches}}
[[ -d "$PATCH_INSTALL_DIR" ]] || die "Patch directory does not exist: $PATCH_INSTALL_DIR"
PATCH_INSTALL_DIR=$(cd -- "$PATCH_INSTALL_DIR" && pwd -P)

export GSM_HOME PATCH_INSTALL_DIR
export ORACLE_HOME="$GSM_HOME"
export PATH="$GSM_HOME/perl/bin:$GSM_HOME/OPatch:$PATH"

INVENTORY_POINTER="$GSM_HOME/oraInst.loc"
[[ -r "$INVENTORY_POINTER" && -s "$INVENTORY_POINTER" ]] || die "Missing or unreadable inventory pointer: $INVENTORY_POINTER"
command -v unzip >/dev/null || die "unzip is required."

# Validate every numbered patch slot before changing the Oracle home.
# Use zero-padded directory names (001, 002, ...) for the required order.
PATCH_SLOTS=("$PATCH_INSTALL_DIR/$GSM_USER/"*/)
[[ ${#PATCH_SLOTS[@]} -gt 0 ]] || die "No patch directories found under $PATCH_INSTALL_DIR/$GSM_USER."
PATCH_ZIPS=()
for slot in "${PATCH_SLOTS[@]}"; do
  archives=("${slot}"*.zip)
  [[ ${#archives[@]} -eq 1 ]] || die "Expected exactly one patch ZIP in $slot; found ${#archives[@]}."
  [[ -f "${archives[0]}" ]] || die "Not a regular patch ZIP: ${archives[0]}"
  PATCH_ZIPS+=("${archives[0]}")
done

# An OPatch update is optional, but multiple update archives are ambiguous.
OPATCH_ZIPS=("$PATCH_INSTALL_DIR/opatch/"p6880880*.zip)
[[ ${#OPATCH_ZIPS[@]} -le 1 ]] || die "Provide at most one p6880880 ZIP in $PATCH_INSTALL_DIR/opatch."

WORK_DIR=$(mktemp -d "$PATCH_INSTALL_DIR/.gsm-patch-work.XXXXXX")
KEEP_WORK_DIR=0
cleanup() {
  local status=$?
  if [[ "$KEEP_WORK_DIR" -eq 0 ]]; then
    rm -rf -- "$WORK_DIR" || echo "WARNING: Could not remove $WORK_DIR" >&2
  else
    echo "Recovery files retained in $WORK_DIR" >&2
  fi
  return "$status"
}
trap cleanup EXIT

if [[ ${#OPATCH_ZIPS[@]} -eq 1 ]]; then
  echo "Preparing OPatch update: ${OPATCH_ZIPS[0]}"
  mkdir -- "$WORK_DIR/opatch-update"
  unzip -q -o "${OPATCH_ZIPS[0]}" -d "$WORK_DIR/opatch-update"
  [[ -x "$WORK_DIR/opatch-update/OPatch/opatch" ]] || die "The OPatch ZIP does not contain an executable OPatch/opatch."

  # Keep the existing tool until the new tool has been installed and checked.
  HAD_OPATCH=0
  if [[ -e "$GSM_HOME/OPatch" || -L "$GSM_HOME/OPatch" ]]; then
    mv -- "$GSM_HOME/OPatch" "$WORK_DIR/previous-OPatch"
    HAD_OPATCH=1
  fi

  if mv -- "$WORK_DIR/opatch-update/OPatch" "$GSM_HOME/OPatch" && \
     "$GSM_HOME/OPatch/opatch" version; then
    echo "OPatch update installed."
  else
    # Retain the backup if restoration itself fails.
    KEEP_WORK_DIR=1
    rm -rf -- "$GSM_HOME/OPatch"
    if [[ "$HAD_OPATCH" -eq 1 ]]; then
      mv -- "$WORK_DIR/previous-OPatch" "$GSM_HOME/OPatch"
    fi
    KEEP_WORK_DIR=0
    die "OPatch update failed; any previous OPatch installation was restored."
  fi
else
  [[ -x "$GSM_HOME/OPatch/opatch" ]] || die "No installed OPatch found, and no OPatch update ZIP was supplied."
  "$GSM_HOME/OPatch/opatch" version
fi

# Check the supplied inventory before applying any patch.
"$GSM_HOME/OPatch/opatch" lsinventory \
  -oh "$GSM_HOME" -invPtrLoc "$INVENTORY_POINTER"

APPLIED_COUNT=0
for index in "${!PATCH_ZIPS[@]}"; do
  archive=${PATCH_ZIPS[$index]}
  extract_dir="$WORK_DIR/patch-$index"
  mkdir -- "$extract_dir"
  echo "Extracting patch: $archive"
  unzip -q -o "$archive" -d "$extract_dir"

  # This layout supports one top-level OPatch patch directory per ZIP.
  # Bundles requiring nested patches or opatchauto need README-specific handling.
  patch_roots=("$extract_dir/"*/)
  [[ ${#patch_roots[@]} -eq 1 ]] || die "Expected one top-level patch directory in $archive; found ${#patch_roots[@]}. Check the patch README."

  echo "Applying patch from $archive"
  (
    cd -- "${patch_roots[0]}"
    "$GSM_HOME/OPatch/opatch" apply -silent \
      -oh "$GSM_HOME" -invPtrLoc "$INVENTORY_POINTER"
  )
  APPLIED_COUNT=$((APPLIED_COUNT + 1))
done

"$GSM_HOME/OPatch/opatch" lsinventory \
  -oh "$GSM_HOME" -invPtrLoc "$INVENTORY_POINTER"
echo "Completed $APPLIED_COUNT patch apply operation(s). Review the inventory above for the expected patch IDs."
