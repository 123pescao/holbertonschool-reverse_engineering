#!/usr/bin/env bash

set -euo pipefail

#Helpers 
die() { echo "Error: $*" >&2; exit 1; }

need() {
    command -v "$1" >/dev/null 2>&1 || die "Missing requied tool: $1"
}

#checks
need readelf
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

#Source messages.sh
source "${SCRIPT_DIR}/messages.sh" || die "Could not source messages.sh"

if [[ $# -ne 1 ]]; then
  die "Usage: $0 <elf_file>"
fi

file_path="$1"
[[ -f "$file_path" ]] || die "File not found: $file_path"

#ELF check
if ! file "$file_path" | grep -q 'ELF'; then
  die "Not an ELF file: $file_path"
fi

#extract fields via readelf
#Magic line
magic_number="$(
  readelf -h "$file_path" | awk '/Magic:/{ $1=""; sub(/^ +/,""); print }'
)"

#Class line
class="$(
  readelf -h "$file_path" | awk -F: '/Class:/{gsub(/^[ \t]+/,"",$2); print $2}'
)"

#Data Normalize 
byte_order="$(
  readelf -h "$file_path" | awk -F: '/Data:/{gsub(/^[ \t]+/,"",$2); print $2}'
)"
if grep -qi "little endian" <<<"$byte_order"; then
  byte_order="Little endian"
elif grep -qi "big endian" <<<"$byte_order"; then
  byte_order="Big endian"
fi

#Entry point line
entry_point_address="$(
  readelf -h "$file_path" | awk -F: '/Entry point address/{gsub(/^[ \t]+/,"",$2); print $2}'
)"

#Variables messages.sh expects
file_name="$(basename -- "$file_path")"

#Display 
display_elf_header_info
