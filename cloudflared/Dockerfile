# Base image pinned by tag and multi-arch index digest (amd64 + arm64).
# Update both together after reviewing the new base image release.
FROM ghcr.io/hassio-addons/base:21.0.8@sha256:52f79347fa3e0ceb58af92aecca8165c34099067dde8c5f767e95d9cdd56099f

# Set S6 verbosity level
ENV S6_VERBOSITY="1"

# Provided by the Supervisor (aarch64 or amd64)
ARG BUILD_ARCH

# cloudflared release and the SHA256 of each supported binary, taken from the
# release notes of https://github.com/cloudflare/cloudflared/releases and
# verified by downloading the binaries. Update all three together.
ARG CLOUDFLARED_VERSION="2026.10.0"
ARG CLOUDFLARED_SHA256_AMD64="d33ff2d14475178d2012c2c56beba87389ac5ded27649519f198a7d3134a99db"
ARG CLOUDFLARED_SHA256_ARM64="e6422b9d4f72d3194bc5a38676f13667c06666523217b842a877d72a80b5ac08"

# Copy root filesystem
COPY rootfs /

# Download cloudflared and verify its checksum (the build fails on mismatch)
RUN ["/bin/sh", "/build.sh"]

CMD ["/run.sh"]

# Build arguments
ARG BUILD_DATE
ARG BUILD_DESCRIPTION
ARG BUILD_NAME
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION

# Labels
LABEL \
    io.hass.name="${BUILD_NAME}" \
    io.hass.description="${BUILD_DESCRIPTION}" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="app" \
    io.hass.version="${BUILD_VERSION}" \
    maintainer="Tuomas Silen <https://github.com/tsilen>" \
    org.opencontainers.image.title="${BUILD_NAME}" \
    org.opencontainers.image.description="${BUILD_DESCRIPTION}" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.url="https://github.com/tsilen/app-cloudflared" \
    org.opencontainers.image.source="https://github.com/tsilen/app-cloudflared" \
    org.opencontainers.image.documentation="https://github.com/tsilen/app-cloudflared/blob/main/cloudflared/DOCS.md" \
    org.opencontainers.image.created="${BUILD_DATE}" \
    org.opencontainers.image.revision="${BUILD_REF}" \
    org.opencontainers.image.version="${BUILD_VERSION}"
