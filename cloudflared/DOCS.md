# Home Assistant App: Cloudflared (hardened fork)

This app runs a [Cloudflare Tunnel][cf-tunnel] connector inside Home Assistant.
The connector opens an outbound connection to Cloudflare, so no ports have to be
opened on your router.

This is a hardened fork of [homeassistant-apps/app-cloudflared][upstream]. It is
built locally by the Supervisor from this repository and only supports
remote-managed tunnels (token mode).

## What is different from upstream

- **Built locally, no prebuilt image.** `config.yaml` has no `image:` key, so
  the Supervisor builds the container from the `Dockerfile` in this repository
  instead of pulling an image from a container registry.
- **Verified cloudflared binary.** The cloudflared version is pinned and the
  downloaded binary is checked against a SHA256 checksum for each architecture
  (`aarch64`, `amd64`). The build fails on a mismatch.
- **Pinned base image.** The base image is pinned by tag and multi-arch digest.
- **Token mode only.** The local-managed mode (`cloudflared tunnel login` and an
  account-wide `cert.pem` that can create tunnels and DNS records) is removed.
  The app only stores a token for one tunnel. Hostname routes are managed in the
  Cloudflare Zero Trust dashboard.
- **Least privilege.** No access to the Home Assistant configuration folder, no
  mapped folders, no published ports and no `hassio_api` (only the
  app's own info/options endpoints that every app can read).
- **No secrets in logs or process list.** The tunnel token is passed to
  cloudflared via the `TUNNEL_TOKEN` environment variable, not as a command
  line argument, and is never logged. cloudflared debug logging (which logs
  request headers such as access tokens) cannot be enabled.
- **Metrics only on localhost.** cloudflared metrics listen on
  `127.0.0.1:36500` inside the container. The in-depth management diagnostics
  (`/debug/pprof` etc.) are disabled.
- **No automatic updates.** Renovate and the upstream release workflows are
  disabled. Updates are reviewed and applied by hand (see "Updating").

## Installation

1. In Home Assistant open **Settings → Add-ons → Add-on store** (called
   **Apps → App store** in newer versions), click **⋮ → Repositories** and add
   `https://github.com/tsilen/app-cloudflared`.
2. Install **Cloudflared (hardened)**. The first installation takes a few
   minutes because the image is built on your device.
3. Set up the tunnel in Cloudflare as described below, paste the token into the
   app configuration and start the app.

If the upstream Cloudflared app is also installed, stop it so that only one
connector is running for your tunnel.

## Cloudflare setup (token mode)

### 1. Create the tunnel

1. Open the [Cloudflare Zero Trust dashboard][cf-dash] and go to
   **Networks → Tunnels → Create a tunnel**.
2. Choose **Cloudflared** as connector type and give the tunnel a name, for
   example `homeassistant`.
3. On the "Install and run connectors" page, copy the **token** from the shown
   command (the long string after `--token`). Do not run the command.
4. Paste the token into the app option **Cloudflare Tunnel Token** and save.
   Treat the token like a password: anyone who has it can run your tunnel.

### 2. Route a hostname to Home Assistant

In the tunnel settings add a **public hostname** (also called a published
application route):

- Subdomain / domain: for example `ha-mcp.example.com`
- Service type: `HTTP`
- URL: `homeassistant:8123`

`homeassistant` is the internal name of Home Assistant on the Supervisor
network. If Home Assistant itself serves HTTPS, use type `HTTPS` and enable
**No TLS Verify** under the route's TLS settings, because the internal hostname
does not match the certificate. Cloudflare creates the DNS record for you.

Requests to hostnames without a route are answered by Cloudflare with an error;
the app does not add any catch-all routes.

### 3. Protect the hostname with Cloudflare Access

A public hostname is reachable from the whole internet unless it is protected.
To allow only a specific client (for example an MCP client) to reach the Home
Assistant MCP server:

1. Go to **Access → Service Auth → Service Tokens → Create Service Token**.
   Save the Client ID and Client Secret; the secret is shown only once.
2. Go to **Access → Applications → Add an application → Self-hosted**.
   - Application domain: `ha-mcp.example.com`, path `api/mcp`.
   - Add a policy with action **Service Auth** and an **Include** rule
     **Service Token → (your token)**. Do not add other rules.
3. If the hostname is only meant for this client, add a second application for
   the same hostname without a path (whole hostname) with the same policy, so
   nothing else in Home Assistant is reachable through the tunnel.

The client must send the headers `CF-Access-Client-Id` and
`CF-Access-Client-Secret` with every request. Home Assistant's own
authentication (a long-lived access token of a dedicated non-admin user) still
applies on top of this.

## Home Assistant configuration

Home Assistant rejects proxied requests unless the proxy is trusted. Add this to
`configuration.yaml` and restart Home Assistant:

```yaml
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 172.30.33.0/24
```

`172.30.33.0/24` is the Supervisor network that apps run in.

## App options

### Option: `tunnel_token` (required)

The token of the remote-managed tunnel (see above). The app refuses to start
without a valid-looking token.

### Option: `post_quantum`

Makes the tunnel use post-quantum cryptography. This restricts the tunnel to
the QUIC protocol, which may not work on every network.

### Option: `run_parameters`

Additional cloudflared parameters. Only these are allowed, each as one list
item in the form `--name=value`:

`--edge-bind-address`, `--edge-ip-version`, `--grace-period`,
`--ha-connections`, `--protocol`, `--region`, `--retries`, `--tag` and
`--loglevel` with one of `info`, `warn`, `error`, `fatal`.

```yaml
run_parameters:
  - "--protocol=http2"
  - "--loglevel=warn"
```

### Option: `log_level`

Log level of the app's start-up script (`trace`, `debug`, `info`, `notice`,
`warning`, `error`, `fatal`). It does not change cloudflared's log level.

## Updating

The app is not updated automatically. To update cloudflared:

1. Read the release notes of the new [cloudflared release][cf-releases].
2. In `cloudflared/Dockerfile`, update `CLOUDFLARED_VERSION` and both
   `CLOUDFLARED_SHA256_*` values. Take the checksums from the release notes and
   verify them by downloading the `cloudflared-linux-amd64` and
   `cloudflared-linux-arm64` binaries and running `sha256sum`.
3. Bump `version` in `cloudflared/config.yaml` (for example `7.0.17-ts2`) and
   add an entry to `CHANGELOG.md`.
4. In Home Assistant, check for updates in the app store and update the app;
   the Supervisor rebuilds the image.

To update the base image, update the tag and the digest in the `FROM` line
together, after checking that the digest is a multi-arch index containing
`linux/arm64` and `linux/amd64`:

```sh
docker buildx imagetools inspect ghcr.io/hassio-addons/base:<tag>
```

## License

MIT License. See [LICENSE.md](../LICENSE.md). Original work by Tobias Brenner
and the contributors of [homeassistant-apps/app-cloudflared][upstream].

[cf-tunnel]: https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/
[cf-dash]: https://one.dash.cloudflare.com/
[cf-releases]: https://github.com/cloudflare/cloudflared/releases
[upstream]: https://github.com/homeassistant-apps/app-cloudflared
