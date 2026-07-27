#!/usr/bin/env sh
# Package a portable, extractable Windows testnet bundle of monero-gui.
#
# The Windows cross-compile (Dockerfile.windows, STATIC=ON, static Qt) produces
# a self-contained monero-wallet-gui.exe that needs no Qt/Boost/OpenSSL DLLs,
# so this archive only ships the executables plus a launcher and testnet
# settings. This mirrors scripts/package-testnet-ubuntu.sh.
set -eu

build_dir=${1:-build/x86_64-w64-mingw32/release/bin}
version=${2:-local}
out_dir=${3:-dist}

package_name="monero-gui-${version}-windows-x64"
stage="${out_dir}/${package_name}"

if [ ! -f "${build_dir}/monero-wallet-gui.exe" ]; then
    echo "missing executable: ${build_dir}/monero-wallet-gui.exe" >&2
    exit 1
fi

if [ ! -f "${build_dir}/monerod.exe" ]; then
    echo "missing executable: ${build_dir}/monerod.exe" >&2
    exit 1
fi

rm -rf "${stage}"
mkdir -p "${stage}/monero-storage" "${out_dir}"

cp "${build_dir}/monero-wallet-gui.exe" "${stage}/"
cp "${build_dir}/monerod.exe" "${stage}/"
# monero-wallet-cli is optional; include it when present for power users.
if [ -f "${build_dir}/monero-wallet-cli.exe" ]; then
    cp "${build_dir}/monero-wallet-cli.exe" "${stage}/"
fi

cat > "${stage}/start-testnet.bat" <<'EOF'
@echo off
setlocal

REM Monero GUI Testnet launcher (Windows)
REM Testnet coins have no real value. This package is not for mainnet XMR.

set "DIR=%~dp0"
set "DIR=%DIR:~0,-1%"

if not exist "%DIR%\logs" mkdir "%DIR%\logs"

start "" "%DIR%\monero-wallet-gui.exe" ^
    --disable-check-updates ^
    --log-file "%DIR%\logs\monero-wallet-gui.log"
EOF

cat > "${stage}/monero-storage/settings.ini" <<'EOF'
[General]
nettype=1
walletMode=2
useRemoteNode=false
askDesktopShortcut=false
checkForUpdates=false
EOF

cat > "${stage}/README-TESTNET.txt" <<'EOF'
Monero GUI Testnet Windows Package
==================================

This package is testnet-only. It is not for mainnet XMR.
Testnet coins have no real value.

Run:

  start-testnet.bat

The launcher starts the Monero GUI from this folder. The GUI is patched to
stay on Monero testnet and to reject non-testnet wallets. When using a local
node, the GUI starts the bundled monerod with testnet settings.

Logs are written to:

  logs\monero-wallet-gui.log

Portable GUI settings are kept in:

  monero-storage\settings.ini

The monero-wallet-gui.exe is statically linked, so no external Qt/Boost/OpenSSL
DLLs are required. Just extract this archive anywhere and run start-testnet.bat.
EOF

chmod 755 "${stage}/start-testnet.bat"

# Build the zip from outside the staging tree so the archive root is the
# package directory itself (clean extraction: a single top-level folder).
( cd "${out_dir}" && zip -qr "${package_name}.zip" "${package_name}" )

if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "${out_dir}/${package_name}.zip" > "${out_dir}/${package_name}.zip.sha256"
else
    sha256 -r "${out_dir}/${package_name}.zip" > "${out_dir}/${package_name}.zip.sha256"
fi

echo "${out_dir}/${package_name}.zip"
