#!/usr/bin/env sh
set -eu

build_dir=${1:-build/release/bin}
version=${2:-local}
out_dir=${3:-dist}

package_name="monero-gui-testnet-ubuntu-x86_64-${version}"
stage="${out_dir}/${package_name}"

if [ ! -x "${build_dir}/monero-wallet-gui" ]; then
    echo "missing executable: ${build_dir}/monero-wallet-gui" >&2
    exit 1
fi

if [ ! -x "${build_dir}/monerod" ]; then
    echo "missing executable: ${build_dir}/monerod" >&2
    exit 1
fi

rm -rf "${stage}"
mkdir -p "${stage}/monero-storage" "${out_dir}"

cp "${build_dir}/monero-wallet-gui" "${stage}/"
cp "${build_dir}/monerod" "${stage}/"

cat > "${stage}/start-testnet.sh" <<'EOF'
#!/usr/bin/env sh
set -eu

DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "${DIR}"

mkdir -p monero-storage logs

exec "${DIR}/monero-wallet-gui" \
    --disable-check-updates \
    --log-file "${DIR}/logs/monero-wallet-gui.log"
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
Monero GUI Testnet Ubuntu Package
=================================

This package is testnet-only. It is not for mainnet XMR.
Testnet coins have no real value.

Run:

  ./start-testnet.sh

The launcher starts the Monero GUI from this folder. The GUI is patched to
stay on Monero testnet and to reject non-testnet wallets. When using a local
node, the GUI starts the bundled monerod with testnet settings.

Logs are written to:

  logs/monero-wallet-gui.log

Portable GUI settings are kept in:

  monero-storage/settings.ini
EOF

chmod 755 "${stage}/start-testnet.sh"

tar -C "${out_dir}" -czf "${out_dir}/${package_name}.tar.gz" "${package_name}"
if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "${out_dir}/${package_name}.tar.gz" > "${out_dir}/${package_name}.tar.gz.sha256"
else
    sha256 -r "${out_dir}/${package_name}.tar.gz" > "${out_dir}/${package_name}.tar.gz.sha256"
fi

echo "${out_dir}/${package_name}.tar.gz"
