#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PUBLIC_DIR="${ROOT_DIR}/public"
SURGE_DIR="${PUBLIC_DIR}/surge"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

mkdir -p "${SURGE_DIR}"

github_raw_fallback_url() {
  local url="$1"
  local remainder owner repo branch path rest

  remainder="${url#https://raw.githubusercontent.com/}"
  owner="${remainder%%/*}"
  rest="${remainder#*/}"
  repo="${rest%%/*}"
  rest="${rest#*/}"
  branch="${rest%%/*}"
  path="${rest#*/}"

  printf 'https://cdn.jsdelivr.net/gh/%s/%s@%s/%s' "${owner}" "${repo}" "${branch}" "${path}"
}

fetch_rule() {
  local url="$1"
  local output_path="$2"
  local tmp_file="${TMP_DIR}/$(basename "${output_path}")"
  local target_file="${SURGE_DIR}/${output_path}"
  local fallback_url

  printf 'Updating %s\n' "${output_path}"

  if ! curl -fsSL --retry 3 --retry-all-errors --retry-delay 2 \
    -A "rules-updater/1.0" \
    "${url}" \
    -o "${tmp_file}"; then
    fallback_url="$(github_raw_fallback_url "${url}")"
    printf '  raw source failed, retrying via jsDelivr\n'
    curl -fsSL --retry 3 --retry-all-errors --retry-delay 2 \
      -A "rules-updater/1.0" \
      "${fallback_url}" \
      -o "${tmp_file}"
  fi

  if [[ ! -s "${tmp_file}" ]]; then
    printf 'Error: downloaded file is empty: %s\n' "${output_path}" >&2
    return 1
  fi

  mkdir -p "$(dirname "${target_file}")"
  mv "${tmp_file}" "${target_file}"
}

while IFS='|' read -r url output_path; do
  [[ -z "${url}" || "${url}" == \#* ]] && continue
  fetch_rule "${url}" "${output_path}"
done <<'RULES'
https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Surge/Apple/Apple_All_No_Resolve.list|blackmatrix7/Apple_All_No_Resolve.list
https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Surge/OpenAI/OpenAI.list|blackmatrix7/OpenAI.list
https://raw.githubusercontent.com/xiaolai/anthropic-claude-surge-rules-set/main/dist/anthropic.list|xiaolai/anthropic.list
https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Surge/GitHub/GitHub.list|blackmatrix7/GitHub.list
https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Surge/Microsoft/Microsoft.list|blackmatrix7/Microsoft.list
https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Surge/Telegram/Telegram.list|blackmatrix7/Telegram.list
https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Surge/Epic/Epic.list|blackmatrix7/Epic.list
https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Surge/Sony/Sony.list|blackmatrix7/Sony.list
https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Surge/Steam/Steam.list|blackmatrix7/Steam.list
https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Surge/Nintendo/Nintendo.list|blackmatrix7/Nintendo.list
https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Surge/YouTube/YouTube.list|blackmatrix7/YouTube.list
https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Surge/Netflix/Netflix.list|blackmatrix7/Netflix.list
https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Surge/Disney/Disney.list|blackmatrix7/Disney.list
https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Surge/Spotify/Spotify.list|blackmatrix7/Spotify.list
https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Surge/TikTok/TikTok.list|blackmatrix7/TikTok.list
https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Surge/BiliBili/BiliBili.list|blackmatrix7/BiliBili.list
https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Surge/ChinaMedia/ChinaMedia.list|blackmatrix7/ChinaMedia.list
https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Surge/GlobalMedia/GlobalMedia_All_No_Resolve.list|blackmatrix7/GlobalMedia_All_No_Resolve.list
https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Surge/Proxy/Proxy_All_No_Resolve.list|blackmatrix7/Proxy_All_No_Resolve.list
https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Surge/ChinaMax/ChinaMax_All.list|blackmatrix7/ChinaMax_All.list
RULES

printf 'Done. Surge rules are updated in %s\n' "${SURGE_DIR}"
