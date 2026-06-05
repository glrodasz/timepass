#!/usr/bin/env bash
# Regenerate Resources/timezone_catalog.json from the system tzdata.
# Run this only when macOS ships an updated /usr/share/zoneinfo/zone.tab.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
OUT="${SCRIPT_DIR}/../Resources/timezone_catalog.json"

grep -v '^#' /usr/share/zoneinfo/zone.tab \
  | awk -F'\t' 'NF>=3 { print $1"\t"$3 }' \
  | awk -F'\t' '
      BEGIN { print "[" }
      {
        if ($1 != prev) {
          if (prev != "") printf "]},\n"
          printf "{\"iso\":\"%s\",\"zones\":[", $1
          prev = $1
          first = 1
        }
        if (!first) printf ","
        printf "\"%s\"", $2
        first = 0
      }
      END {
        if (prev != "") printf "]}\n"
        print "]"
      }' > "$OUT"

echo "Wrote $OUT ($(wc -l < "$OUT") lines)"
