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

## 4. Connect clients

Use this MCP URL from clients on the same machine:

```text
http://localhost:3000/mcp
```

For phones or other devices on your LAN, use the always-on PC's LAN IP, for example:

```text
http://192.168.1.25:3000/mcp
```

For internet access, put the server behind HTTPS with a reverse proxy or tunnel. Do not expose it without authentication.
