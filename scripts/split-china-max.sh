#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="${1:-${ROOT_DIR}/public/surge/blackmatrix7/ChinaMax_All.list}"
OUTPUT_DIR="${2:-${ROOT_DIR}/public/surge/custom/china_max}"
SHARD_COUNT=32
# Operational guardrail, not a documented Surge limit.
MAX_SHARD_BYTES=$((256 * 1024))
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

SOURCE_BYTES="$(wc -c < "${SOURCE}")"

# First pass counts records and detects whether the final line has a newline.
# Second pass copies contiguous complete lines, measuring bytes in the C locale.
awk -v count="${SHARD_COUNT}" -v bytes="${SOURCE_BYTES}" -v dir="${TMP_DIR}" '
  BEGIN {
    target = int((bytes + count - 1) / count)
    part = 1
    for (i = 1; i <= count; i++) {
      path = sprintf("%s/part-%02d.list", dir, i)
      printf "%s", "" > path
      close(path)
    }
  }
  FNR == NR {
    records++
    newline_bytes += length($0) + 1
    next
  }
  {
    ending = (FNR == records && newline_bytes > bytes) ? "" : "\n"
    size = length($0) + length(ending)
    if (used > 0 && used + size > target && part < count) {
      close(path)
      part++
      used = 0
    }
    path = sprintf("%s/part-%02d.list", dir, part)
    printf "%s%s", $0, ending > path
    used += size
    if ($0 !~ /^[[:space:]]*($|#|\/\/|;)/) rules++
  }
  END {
    if (!rules) {
      print "Error: source contains no rules" > "/dev/stderr"
      exit 1
    }
  }
' "${SOURCE}" "${SOURCE}"

cat "${TMP_DIR}"/part-*.list > "${TMP_DIR}/reconstructed"
if ! cmp -s "${SOURCE}" "${TMP_DIR}/reconstructed"; then
  printf 'Error: shard reconstruction differs from upstream\n' >&2
  exit 1
fi

# Validate every shard before replacing published output. Never add URLs silently.
LARGEST=0
for shard in "${TMP_DIR}"/part-*.list; do
  if [[ ! -s "${shard}" ]]; then
    printf '# Empty shard. Reserved for future rules.\n' > "${shard}"
  fi
  size="$(wc -c < "${shard}")"
  if (( size > MAX_SHARD_BYTES )); then
    printf 'Error: %s exceeds the %s-byte guardrail (%s bytes). Review shard layout and Surge configuration.\n' \
      "$(basename "${shard}")" "${MAX_SHARD_BYTES}" "${size}" >&2
    exit 1
  fi
  if (( size > LARGEST )); then LARGEST="${size}"; fi
done

mkdir -p "${OUTPUT_DIR}"
for shard in "${TMP_DIR}"/part-*.list; do
  target="${OUTPUT_DIR}/$(basename "${shard}")"
  if ! cmp -s "${shard}" "${target}"; then
    cp "${shard}" "${target}"
  fi
done
printf 'ChinaMax: %s bytes -> %s shards; largest %s bytes\n' \
  "${SOURCE_BYTES// /}" "${SHARD_COUNT}" "${LARGEST// /}"
