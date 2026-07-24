#!/usr/bin/env sh
set -eu

remote=${MONERO_TESTNET_REMOTE:-https://github.com/XMRChat/monero.git}
ref=${MONERO_TESTNET_REF:-fcmpp-testing}
commit=${MONERO_TESTNET_COMMIT:-025b00208b2fc2a48b30c65e2ae0871c10a0074a}

git submodule update --init monero
git -C monero fetch "${remote}" "${ref}"
git -C monero checkout --detach "${commit}"
git -C monero submodule update --init --recursive

actual=$(git -C monero rev-parse HEAD)
if [ "${actual}" != "${commit}" ]; then
    echo "monero submodule is at ${actual}, expected ${commit}" >&2
    exit 1
fi

echo "monero testnet source ready at ${actual}"
