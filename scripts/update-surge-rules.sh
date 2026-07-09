#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PUBLIC_DIR="${ROOT_DIR}/public"
SURGE_DIR="${PUBLIC_DIR}/surge"
SOURCE_NAME="blackmatrix7"
SOURCE_DIR="${SURGE_DIR}/${SOURCE_NAME}"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

mkdir -p "${SOURCE_DIR}"

fetch_rule() {
  local url="$1"
  local output="$2"
  local tmp_file="${TMP_DIR}/${output}"
  local fallback_path
  local fallback_url

  printf 'Updating %s\n' "${output}"

  if ! curl -fsSL --retry 3 --retry-all-errors --retry-delay 2 \
    -A "rules-updater/1.0" \
    "${url}" \
    -o "${tmp_file}"; then
    fallback_path="${url#https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/}"
    fallback_url="https://cdn.jsdelivr.net/gh/blackmatrix7/ios_rule_script@master/${fallback_path}"
    printf '  raw source failed, retrying via jsDelivr\n'
    curl -fsSL --retry 3 --retry-all-errors --retry-delay 2 \
      -A "rules-updater/1.0" \
      "${fallback_url}" \
      -o "${tmp_file}"
  fi

  if [[ ! -s "${tmp_file}" ]]; then
    printf 'Error: downloaded file is empty: %s\n' "${output}" >&2
    return 1
  fi

  mv "${tmp_file}" "${SOURCE_DIR}/${output}"
}

while IFS='|' read -r url output; do
  [[ -z "${url}" || "${url}" == \#* ]] && continue
  fetch_rule "${url}" "${output}"
done <<'RULES'
https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Surge/Apple/Apple_All_No_Resolve.list|Apple_All_No_Resolve.list
https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Surge/OpenAI/OpenAI.list|OpenAI.list
https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Surge/GitHub/GitHub.list|GitHub.list
https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Surge/Microsoft/Microsoft.list|Microsoft.list
https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Surge/Telegram/Telegram.list|Telegram.list
https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Surge/Epic/Epic.list|Epic.list
https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Surge/Sony/Sony.list|Sony.list
https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Surge/Steam/Steam.list|Steam.list
https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Surge/Nintendo/Nintendo.list|Nintendo.list
https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Surge/YouTube/YouTube.list|YouTube.list
https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Surge/Netflix/Netflix.list|Netflix.list
https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Surge/Disney/Disney.list|Disney.list
https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Surge/Spotify/Spotify.list|Spotify.list
https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Surge/TikTok/TikTok.list|TikTok.list
https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Surge/BiliBili/BiliBili.list|BiliBili.list
https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Surge/ChinaMedia/ChinaMedia.list|ChinaMedia.list
https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Surge/GlobalMedia/GlobalMedia_All_No_Resolve.list|GlobalMedia_All_No_Resolve.list
https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Surge/Proxy/Proxy_All_No_Resolve.list|Proxy_All_No_Resolve.list
https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Surge/ChinaMax/ChinaMax_All.list|ChinaMax_All.list
RULES

printf 'Done. %s Surge rules are updated in %s\n' "${SOURCE_NAME}" "${SOURCE_DIR}"
