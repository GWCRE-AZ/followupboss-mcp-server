# Cloudflare Tunnel deployment

Use this when the MCP server runs on your desktop/mini PC, but you want ChatGPT, Hermes, Codex, or mobile clients to reach it while you are away from your home Wi-Fi.

Cloudflare Tunnel is a good fit because `cloudflared` makes outbound connections from your desktop to Cloudflare, so you do not need to open an inbound router port or have a public home IP.

## Recommended topology

```text
ChatGPT / Hermes / mobile agent
        ↓ HTTPS
https://fub-mcp.example.com/mcp
        ↓ Cloudflare Tunnel
cloudflared on always-on desktop
        ↓ localhost
http://localhost:3000/mcp
        ↓
Follow Up Boss MCP server
```

## 1. Configure this MCP server

Copy the template and set full access only if you really want delete tools enabled:

```bash
cp .env.always-on.example .env
```

Minimum recommended `.env` values for Cloudflare Tunnel:

```dotenv
FUB_API_KEY=your_api_key_here
FUB_SAFE_MODE=false
MCP_TRANSPORT=http
PORT=3000

# Recommended for ChatGPT custom apps/connectors because this server already
# implements OAuth 2.1 discovery, dynamic client registration, and PKCE.
MCP_AUTH_PASSWORD=replace_with_strong_password

# Leave bearer empty when using OAuth. Use bearer instead for clients that only
# support static Authorization headers.
# MCP_BEARER_TOKEN=replace_with_random_token
MCP_AUTH_DISABLED=false
```

If your desktop/container already injects `FUB_API_KEY` as a secret, leave the key out of `.env`; the running environment can provide it.

Start locally:

```bash
npm run start:http
curl http://localhost:3000/health
```

## 2. Create the Cloudflare Tunnel

In the Cloudflare dashboard, create a Tunnel and publish an application route:

| Setting | Value |
|---|---|
| Public hostname | `fub-mcp.example.com` or another subdomain you control |
| Service type | `HTTP` |
| Service URL | `http://localhost:3000` |

Your public MCP URL will be:

```text
https://fub-mcp.example.com/mcp
```

Do not point Cloudflare at `/mcp`; point it at the local origin root (`http://localhost:3000`) so discovery endpoints such as `/.well-known/oauth-authorization-server`, `/.well-known/oauth-protected-resource`, `/health`, and `/mcp` all pass through.

## 3. Locally managed tunnel example

If you manage `cloudflared` with a local config file instead of the Cloudflare dashboard, your ingress should look like this:

```yaml
tunnel: <Tunnel-UUID>
credentials-file: /home/YOUR_USER/.cloudflared/<Tunnel-UUID>.json

ingress:
  - hostname: fub-mcp.example.com
    service: http://localhost:3000
  - service: http_status:404
```

Route DNS to the tunnel:

```bash
cloudflared tunnel route dns <TUNNEL_NAME_OR_UUID> fub-mcp.example.com
cloudflared tunnel run <TUNNEL_NAME_OR_UUID>
```

For always-on use, install `cloudflared` as a service using Cloudflare's dashboard instructions for your operating system, then also keep this Node server running with PM2/systemd as described in `ALWAYS_ON.md`.

## 4. ChatGPT and other agents

Use the HTTPS MCP endpoint:

```text
https://fub-mcp.example.com/mcp
```

For ChatGPT custom apps/connectors, prefer `MCP_AUTH_PASSWORD` so ChatGPT can use the server's OAuth flow. The server exposes OAuth metadata under `/.well-known/oauth-authorization-server` and protected-resource metadata under `/.well-known/oauth-protected-resource`.

For agents that only support a static token, set `MCP_BEARER_TOKEN` instead and configure the agent to send:

```text
Authorization: Bearer <your-token>
```

Do not enable both Cloudflare Access login pages and MCP OAuth unless you have confirmed your target client supports that extra browser/auth layer. Many MCP clients expect the MCP server's OAuth or bearer-token flow directly.

## 5. Security checklist

- Keep `MCP_AUTH_DISABLED=false` for any public Cloudflare hostname.
- Use a long random `MCP_AUTH_PASSWORD` or `MCP_BEARER_TOKEN`.
- Keep `FUB_SAFE_MODE=true` unless you intentionally want delete tools; use `false` only for full access.
- Disable caching for this hostname in Cloudflare if you have custom cache rules.
- Do not commit `.env`, tunnel credentials JSON, or real API keys.
