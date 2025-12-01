#!/usr/bin/env bash
set -euo pipefail

# Portable setup of Wine (Proton-GE by default) with a clean prefix and .NET chain for Affinity-style installers.

REPO="GloriousEggroll/proton-ge-custom"
RELEASE="${GE_TAG:-latest}"          # override with GE_TAG=v9-55 etc., else grabs latest
PROTON_DIR="${PROTON_DIR:-$HOME/.local/share/Proton-GE}"
PREFIX="${WINEPREFIX:-$HOME/.wine-affinity}"
WINVER="${WINVER_TARGET:-win10}"      # win10 or win11
SKIP_DOWNLOAD="${SKIP_DOWNLOAD:-0}"   # set to 1 to skip Proton-GE download
# If you want to use system wine or another build, set WINE_BIN=/path/to/wine and WINESERVER_BIN accordingly.

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { echo "Missing command: $1"; exit 1; }
}

require_cmd winetricks

# Download helpers only needed when we fetch Proton-GE
if [ -z "${WINE_BIN:-}" ] && [ "$SKIP_DOWNLOAD" = "0" ]; then
  require_cmd curl
  require_cmd tar
  require_cmd python3
fi

if [ -z "${WINE_BIN:-}" ]; then
  if [ "$SKIP_DOWNLOAD" = "1" ]; then
    echo "SKIP_DOWNLOAD=1 pero no definiste WINE_BIN. Por favor exporta WINE_BIN=/ruta/a/wine."
    exit 1
  fi

  echo "[1/6] Fetching Proton-GE release metadata ($RELEASE)..."
  if [ "${RELEASE}" != "latest" ]; then
    TAG="$RELEASE"
    ASSET_URL="https://github.com/${REPO}/releases/download/${TAG}/${TAG}.tar.gz"
  else
    release_url="https://api.github.com/repos/${REPO}/releases/latest"
    curl_opts=(-fsSL -H "Accept: application/vnd.github+json" -H "User-Agent: setup-wine-ge")
    [ -n "${GITHUB_TOKEN:-}" ] && curl_opts+=(-H "Authorization: Bearer $GITHUB_TOKEN")
    set +e
    json="$(curl "${curl_opts[@]}" "$release_url")"
    curl_status=$?
    set -e
    if [ $curl_status -ne 0 ] || [ -z "$json" ] || grep -qi "rate limit exceeded" <<<"$json"; then
      echo "Failed to fetch release info via GitHub API (curl status $curl_status)."
      echo "Solución rápida: GE_TAG=GE-Proton10-25 ./setup-wine-ge.sh"
      exit 1
    fi
    if ! printf '%s' "$json" | python3 - <<'PY' >/dev/null 2>&1
import sys, json
json.load(sys.stdin)
PY
    then
      echo "Respuesta de GitHub no es JSON válido. Usa GE_TAG=GE-Proton10-25 ./setup-wine-ge.sh"
      exit 1
    fi
    read -r TAG ASSET_URL <<<"$(python3 - <<'PY'
import json, sys
data = json.load(sys.stdin)
tag = data.get("tag_name", "")
assets = data.get("assets", [])
asset = ""
for a in assets:
    if a.get("name", "").endswith(".tar.gz"):
        asset = a.get("browser_download_url", "")
        break
print(tag, asset)
PY
    <<<"$json")"
    if [ -z "$TAG" ] || [ -z "$ASSET_URL" ]; then
      echo "No pude extraer tag/asset del JSON. Usa GE_TAG=GE-Proton10-25."
      exit 1
    fi
  fi
  echo "Found tag: $TAG"

  echo "[2/6] Downloading $ASSET_URL ..."
  tmp_tar="$(mktemp /tmp/proton-ge-XXXX.tar.gz)"
  curl -L "$ASSET_URL" -o "$tmp_tar"

  echo "[3/6] Extracting to $PROTON_DIR ..."
  mkdir -p "$PROTON_DIR"
  tar -xzf "$tmp_tar" -C "$PROTON_DIR"
  ge_dir="$(tar -tzf "$tmp_tar" | head -n1 | cut -d/ -f1)"
  rm -f "$tmp_tar"

  GE_ROOT="$PROTON_DIR/$ge_dir/files"
  WINE_BIN="$GE_ROOT/bin/wine"
  WINESERVER_BIN="$GE_ROOT/bin/wineserver"
else
  echo "[1/6] Using provided Wine binary: $WINE_BIN"
  WINESERVER_BIN="${WINESERVER_BIN:-$(dirname "$WINE_BIN")/wineserver}"
fi

if [ ! -x "$WINE_BIN" ]; then
  echo "Wine binary not found or not executable at $WINE_BIN"; exit 1;
fi

export WINEPREFIX="$PREFIX"
export WINEARCH=win64
export WINEDEBUG=-all
export WINE="$WINE_BIN"
export WINESERVER="$WINESERVER_BIN"

echo "[4/6] Creating clean prefix at $WINEPREFIX ..."
"$WINE_BIN" wineboot -u

echo "[5/6] Setting Windows version to $WINVER ..."
winetricks -q "$WINVER"

echo "[6/6] Installing core components (.NET chain, fonts, DXVK/VKD3D)..."
WINEDLLOVERRIDES="mscoree,mshtml=" winetricks -q corefonts tahoma dotnet35sp1 dotnet48
winetricks -q dxvk vkd3d

cat <<EOF
Done.
Prefix: $WINEPREFIX
Wine:   $WINE_BIN

To run an installer:
  WINEPREFIX=$WINEPREFIX WINE=$WINE_BIN WINESERVER=$WINESERVER_BIN \\
    $WINE_BIN /path/to/installer.exe

Optional performance flags:
  export WINEESYNC=1 WINEFSYNC=1
EOF
