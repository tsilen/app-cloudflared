# Home Assistant App: Cloudflared (hardened fork)

Connect to Home Assistant through a Cloudflare Tunnel without opening ports on
your router.

This is a hardened fork of
[homeassistant-apps/app-cloudflared](https://github.com/homeassistant-apps/app-cloudflared):

- built locally by the Supervisor from this repository (no prebuilt image),
- cloudflared binary pinned and verified by SHA256 for `aarch64` and `amd64`,
- base image pinned by digest,
- remote-managed tunnels (token mode) only, no account-wide `cert.pem`,
- no access to the Home Assistant configuration, no `hassio_api`, no ports,
- tunnel token never on the command line or in logs,
- no automatic dependency updates.

[:books: Read the full documentation](cloudflared/DOCS.md)

## Installation

1. In Home Assistant open **Settings → Add-ons → Add-on store** (called
   **Apps → App store** in newer versions), click **⋮ → Repositories** and add
   `https://github.com/tsilen/app-cloudflared`.
2. Install **Cloudflared (hardened)**. The first installation builds the image
   on your device and takes a few minutes.
3. Create a tunnel in the Cloudflare Zero Trust dashboard, paste its token into
   the app configuration and start the app. See [DOCS.md](cloudflared/DOCS.md)
   for routing, Cloudflare Access and the Home Assistant `trusted_proxies`
   setting.

## Disclaimer

Make sure you comply with the
[Cloudflare Self-Serve Subscription Agreement](https://www.cloudflare.com/terms/)
when using this app.

## Authors & contributors

The original setup of this repository is by [Tobias Brenner][tobias].

For a full list of all authors and contributors,
check [the contributor's page][contributors].

## License

MIT License

Copyright (c) 2026 Unofficial Home Assistant Apps
Copyright (c) 2026 Tuomas Silen (hardening changes)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

[contributors]: https://github.com/homeassistant-apps/app-cloudflared/graphs/contributors
[tobias]: https://github.com/brenner-tobias
