#!/usr/bin/env bash
# Run every numokit test file and summarise.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FAILED=0

for t in "$HERE"/test-*.sh; do
    [[ -f "$t" ]] || continue
    echo "▶ $(basename "$t")"
    bash "$t" || FAILED=1
    echo
done

if [[ "$FAILED" -eq 0 ]]; then
    echo "ALL TESTS PASSED"
else
    echo "SOME TESTS FAILED"
fi
exit "$FAILED"
