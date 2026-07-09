#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ICON_DIR="${ROOT_DIR}/public/icons"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

mkdir -p "${ICON_DIR}"

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

fetch_icon() {
  local url="$1"
  local output="$2"
  local tmp_file="${TMP_DIR}/${output}"
  local fallback_url

  printf 'Updating %s\n' "${output}"

  if ! curl -fsSL --retry 3 --retry-all-errors --retry-delay 2 \
    -A "rules-icon-updater/1.0" \
    "${url}" \
    -o "${tmp_file}"; then
    fallback_url="$(github_raw_fallback_url "${url}")"
    printf '  raw source failed, retrying via jsDelivr\n'
    curl -fsSL --retry 3 --retry-all-errors --retry-delay 2 \
      -A "rules-icon-updater/1.0" \
      "${fallback_url}" \
      -o "${tmp_file}"
  fi

  if [[ ! -s "${tmp_file}" ]]; then
    printf 'Error: downloaded icon is empty: %s\n' "${output}" >&2
    return 1
  fi

  mv "${tmp_file}" "${ICON_DIR}/${output}"
}

while IFS='|' read -r url output; do
  [[ -z "${url}" || "${url}" == \#* ]] && continue
  fetch_icon "${url}" "${output}"
done <<'ICONS'
https://raw.githubusercontent.com/Irrucky/Tool/main/Surge/icon/surge_2.png|proxy.png
https://raw.githubusercontent.com/fmz200/wool_scripts/main/icons/apps/Apple_Arcade.png|apple.png
https://raw.githubusercontent.com/fmz200/wool_scripts/main/icons/apps/ChatGPT5.png|openai.png
https://raw.githubusercontent.com/fmz200/wool_scripts/main/icons/apps/Claude_01.png|claude.png
https://raw.githubusercontent.com/fmz200/wool_scripts/main/icons/apps/Telegram_01.png|telegram.png
https://raw.githubusercontent.com/Koolson/Qure/master/IconSet/Color/Netflix.png|netflix.png
https://raw.githubusercontent.com/Koolson/Qure/master/IconSet/Color/Disney.png|disney.png
https://raw.githubusercontent.com/fmz200/wool_scripts/main/icons/apps/YouTube_01.png|youtube.png
https://raw.githubusercontent.com/fmz200/wool_scripts/main/icons/apps/Spotify_01.png|spotify.png
https://raw.githubusercontent.com/fmz200/wool_scripts/main/icons/apps/TikTok_01.png|tiktok.png
https://raw.githubusercontent.com/Koolson/Qure/master/IconSet/Color/bilibili.png|bilibili.png
https://raw.githubusercontent.com/Koolson/Qure/master/IconSet/Color/HKMTMedia.png|globalmedia.png
https://raw.githubusercontent.com/Koolson/Qure/master/IconSet/Color/Windows_11.png|microsoft.png
https://raw.githubusercontent.com/Koolson/Qure/master/IconSet/Color/Game.png|gamer.png
https://raw.githubusercontent.com/Semporia/Hand-Painted-icon/master/Rounded_Rectangle/United_States.png|country-us.png
https://raw.githubusercontent.com/Semporia/Hand-Painted-icon/master/Rounded_Rectangle/Taiwan.png|country-tw.png
https://raw.githubusercontent.com/Semporia/Hand-Painted-icon/master/Rounded_Rectangle/Singapore.png|country-sg.png
https://raw.githubusercontent.com/Semporia/Hand-Painted-icon/master/Rounded_Rectangle/United_Kingdom.png|country-uk.png
ICONS

printf 'Done. Icons are updated in %s\n' "${ICON_DIR}"
