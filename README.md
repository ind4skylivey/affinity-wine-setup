## Affinity Wine Setup

Portable Wine runtime bootstrap for Affinity CLI users on Arch/CachyOS (or any distro). It fetches Proton-GE (or uses your provided Wine build), creates a clean 64‑bit prefix, sets Windows 10/11, and installs corefonts, Tahoma, .NET 3.5 SP1, .NET 4.8, DXVK, and VKD3D.

### Quick start (recommended)
```bash
GE_TAG=GE-Proton10-25 ./setup-wine-ge.sh
```
This downloads Proton-GE `GE-Proton10-25`, creates prefix `~/.wine-affinity`, sets Windows 10, installs .NET chain and DXVK/VKD3D.

### Reuse an already downloaded Proton-GE
```bash
WINE_BIN=$HOME/.local/share/Proton-GE/GE-Proton10-25/files/bin/wine \
WINESERVER_BIN=$HOME/.local/share/Proton-GE/GE-Proton10-25/files/bin/wineserver \
SKIP_DOWNLOAD=1 \
./setup-wine-ge.sh
```

### Use your own Wine build
```bash
WINE_BIN=/usr/bin/wine \
WINESERVER_BIN=/usr/bin/wineserver \
SKIP_DOWNLOAD=1 \
./setup-wine-ge.sh
```
(Only advised if your build includes full 32/64 userspace; Arch’s WoW64-only packages often break dotnet/winetricks.)

### Run installers or Affinity CLI after setup
```bash
WINEPREFIX=$HOME/.wine-affinity \
WINE=$HOME/.local/share/Proton-GE/GE-Proton10-25/files/bin/wine \
$WINE /path/to/installer.exe
```
Use the same `WINEPREFIX`, `WINE`, and `WINESERVER` for Affinity CLI commands.

### Configuration knobs
- `GE_TAG`: Proton-GE tag to fetch (default: `latest` via GitHub API). Pinning a tag is recommended.
- `WINVER_TARGET`: `win10` (default) or `win11`.
- `WINEPREFIX`: prefix path (default `~/.wine-affinity`).
- `PROTON_DIR`: where Proton-GE is stored (default `~/.local/share/Proton-GE`).
- `WINE_BIN` / `WINESERVER_BIN`: override to use an existing Wine build; set `SKIP_DOWNLOAD=1`.
- `GITHUB_TOKEN`: optional; avoids GitHub API rate limits when using `latest`.

### Prerequisites
`winetricks`, `curl`, `tar`, `python3` installed on the host.

### What the script does
1. (Optional) downloads Proton-GE and extracts it.
2. Creates a fresh 64-bit prefix.
3. Sets Windows version to Win10/Win11.
4. Installs corefonts, Tahoma, .NET 3.5 SP1, .NET 4.8, DXVK, and VKD3D.
5. Prints how to launch installers with the configured prefix.

### Verification
```bash
WINEPREFIX=$HOME/.wine-affinity \
WINE=$HOME/.local/share/Proton-GE/GE-Proton10-25/files/bin/wine \
$WINE winecfg
```
If `winecfg` opens without “WoW64 experimental” warnings, the runtime is correct.

### Notes
- All content is in English (project rule).
- Do not commit credentials or tokens. Use `GITHUB_TOKEN` as an env var only. 
- No summary files; documentation lives here.
