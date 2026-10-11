# Changelog

## 7.0.17-ts1

Hardened fork of homeassistant-apps/app-cloudflared (based on upstream main
after 7.0.17, cloudflared 2026.10.0, base image 21.0.8).

- Build locally by the Supervisor (no `image:`), add `repository.yaml`.
- Verify the cloudflared binary with a pinned SHA256 per architecture.
- Pin the base image by multi-arch digest.
- Support only remote-managed tunnels (token mode); remove the local-managed
  mode with `cert.pem`, DNS management and generated ingress config.
- Remove the Home Assistant config mapping, the app config mapping, `hassio_api`
  access and the published metrics port.
- Pass the tunnel token via `TUNNEL_TOKEN` and never log it; disallow
  cloudflared debug logging.
- Bind metrics to `127.0.0.1:36500` and disable management diagnostics.
- Disable Renovate and the upstream release/deploy workflows; keep a minimal
  CI with a SHA-pinned checkout action and read-only permissions.
