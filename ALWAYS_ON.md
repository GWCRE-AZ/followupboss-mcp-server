# Always-on desktop deployment

Use this guide when you want this Follow Up Boss MCP server to keep running on an always-on desktop or mini PC and be reachable from desktop apps, mobile apps, Codex, or any MCP client that supports Streamable HTTP.

## 1. Install and configure

```bash
npm install
cp .env.always-on.example .env
```

Edit `.env` and replace the placeholders with your real values. Keep this file private; it is ignored by git.

For full access, set:

```dotenv
FUB_SAFE_MODE=false
```

Full access enables delete tools. Back up Follow Up Boss first and protect the HTTP endpoint with either `MCP_BEARER_TOKEN` or `MCP_AUTH_PASSWORD`.

## 2. Start the HTTP MCP server

```bash
npm run start:http
```

The server listens on `http://localhost:3000/mcp` by default. Check it with:

```bash
curl http://localhost:3000/health
```

## 3. Keep it running after reboot

### Option A: PM2 (cross-platform)

```bash
npm install -g pm2
pm2 start npm --name followupboss-mcp -- run start:http
pm2 save
pm2 startup
```

Run the command printed by `pm2 startup`, then reboot and verify `/health` responds.

### Option B: systemd (Linux)

Create `/etc/systemd/system/followupboss-mcp.service`:

```ini
[Unit]
Description=Follow Up Boss MCP Server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=/workspace/followupboss-mcp-server
EnvironmentFile=/workspace/followupboss-mcp-server/.env
ExecStart=/usr/bin/npm run start:http
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Then enable it:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now followupboss-mcp
sudo systemctl status followupboss-mcp
```

## 4. Local desktop vs LAN vs cloud access

This server can absolutely run on your local desktop PC. You do **not** need a cloud host if the agents that need the MCP can reach that desktop. The important distinction is network reachability:

| Where the client/agent runs | URL to use | Tunnel/cloud required? | Notes |
|---|---|---|---|
| Same desktop PC | `http://localhost:3000/mcp` | No | Works for local desktop apps and local Codex/CLI agents running on that PC. |
| Phone or another computer on the same Wi-Fi/LAN | `http://<desktop-lan-ip>:3000/mcp` | No | The desktop must stay powered on, not asleep, and the firewall must allow inbound TCP port `3000`. |
| Agent running in an external cloud/container | Public `https://.../mcp` URL | Yes | A remote cloud agent cannot reach your private `localhost` or LAN IP unless you expose the desktop through a tunnel, VPN, reverse proxy, or cloud deployment. |
| Mobile app away from home/Wi-Fi | Public `https://.../mcp` URL | Usually yes | Use a secure tunnel/VPN/reverse proxy with authentication. Do not expose this MCP unauthenticated. |

“Always-on” means the server process keeps running on a machine that remains awake and connected. It does **not** automatically make a private desktop reachable from the public internet. For off-network access, add a tunnel/VPN/reverse proxy or deploy the server to a cloud host.

## 5. Connect clients

Use this MCP URL from clients on the same machine:

```text
http://localhost:3000/mcp
```

For phones or other devices on your LAN, use the always-on PC's LAN IP, for example:

```text
http://192.168.1.25:3000/mcp
```

To find the desktop's LAN IP, run one of these on the desktop:

```bash
# macOS/Linux
ipconfig getifaddr en0 2>/dev/null || hostname -I

# Windows PowerShell
Get-NetIPAddress -AddressFamily IPv4
```

For internet access, put the server behind HTTPS with a reverse proxy, VPN, or tunnel. Do not expose it without authentication.

## 6. Using existing environment secrets

If your runtime environment already injects `FUB_API_KEY` as a secret, you do not need to write it into `.env`. Environment variables supplied by the shell, service manager, container, or secrets manager are read by `index.js` before `.env` fallback values. Keep real API keys out of git and out of copied examples.
