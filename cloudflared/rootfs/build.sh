#!/bin/sh
# ==============================================================================
# Home Assistant App: Cloudflared (hardened)
#
# Container build: downloads the pinned cloudflared release binary and verifies
# its SHA256 checksum. The build fails if the architecture is unsupported or the
# checksum does not match.
# ==============================================================================

set -eu

fail() {
    echo "build.sh: $*" >&2
    exit 1
}

[ -n "${CLOUDFLARED_VERSION:-}" ] || fail "CLOUDFLARED_VERSION is not set"

case "${BUILD_ARCH:-}" in
"aarch64")
    cloudflared_arch="arm64"
    expected_sha256="${CLOUDFLARED_SHA256_ARM64:-}"
    ;;
"amd64")
    cloudflared_arch="amd64"
    expected_sha256="${CLOUDFLARED_SHA256_AMD64:-}"
    ;;
*)
    fail "unsupported BUILD_ARCH '${BUILD_ARCH:-}' (supported: aarch64, amd64)"
    ;;
esac

echo "${expected_sha256}" | grep -Eq '^[0-9a-f]{64}$' ||
    fail "no valid SHA256 configured for ${BUILD_ARCH}"

url="https://github.com/cloudflare/cloudflared/releases/download/${CLOUDFLARED_VERSION}/cloudflared-linux-${cloudflared_arch}"
tmp_bin="/tmp/cloudflared.download"

echo "Downloading ${url}"
wget -q -O "${tmp_bin}" "${url}" || fail "download failed: ${url}"

actual_sha256="$(sha256sum "${tmp_bin}" | cut -d ' ' -f 1)"
if [ "${actual_sha256}" != "${expected_sha256}" ]; then
    rm -f "${tmp_bin}"
    fail "SHA256 mismatch for cloudflared-linux-${cloudflared_arch} ${CLOUDFLARED_VERSION}: expected ${expected_sha256}, got ${actual_sha256}"
fi
echo "SHA256 verified: ${actual_sha256}"

install -m 0755 "${tmp_bin}" /usr/bin/cloudflared
rm -f "${tmp_bin}"

# Remove legacy cont-init.d services
rm -rf /etc/cont-init.d

# Remove s-6 legacy/deprecated (and not needed) services
rm -f /package/admin/s6-overlay/etc/s6-rc/sources/base/contents.d/legacy-cont-init
rm -f /package/admin/s6-overlay/etc/s6-rc/sources/base/contents.d/fix-attrs
rm -f /package/admin/s6-overlay/etc/s6-rc/sources/top/contents.d/legacy-services

# Do not depend on the executable bit being preserved in git
chmod 0755 /run.sh

# The build script is not needed at runtime
rm -f /build.sh
