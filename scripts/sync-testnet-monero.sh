#!/usr/bin/env sh
set -eu

remote=${MONERO_TESTNET_REMOTE:-https://github.com/XMRChat/monero.git}
ref=${MONERO_TESTNET_REF:-v0.19.0.0-beta.2.0}
commit=${MONERO_TESTNET_COMMIT:-8ed2f782517db08bd6069517b7dcc2959b816e69}
repo_root="$(pwd)"

register_safe_dir() {
    git config --global --add safe.directory "$1"
}

register_safe_dir "${repo_root}"
register_safe_dir "${repo_root}/monero"
register_safe_dir "*"

git submodule update --init monero

if [ -f monero/.gitmodules ]; then
    git -C monero config -f .gitmodules --get-regexp '^submodule\..*\.path$' | while read -r _ submodule_path; do
        register_safe_dir "${repo_root}/monero/${submodule_path}"
    done
fi

if [ -f monero/external/rapidjson/.gitmodules ]; then
    git -C monero/external/rapidjson config -f .gitmodules --get-regexp '^submodule\..*\.path$' | while read -r _ submodule_path; do
        register_safe_dir "${repo_root}/monero/external/rapidjson/${submodule_path}"
    done
fi

git -C monero fetch "${remote}" "${ref}"
git -C monero checkout --detach "${commit}"
git -C monero submodule update --init --recursive

actual=$(git -C monero rev-parse HEAD)
if [ "${actual}" != "${commit}" ]; then
    echo "monero submodule is at ${actual}, expected ${commit}" >&2
    exit 1
fi

echo "monero testnet source ready at ${actual}"
