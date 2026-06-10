#!/usr/bin/env bash
# Follow Up Boss MCP — One-Command Mac Setup
# Run with: bash install-mac.sh
#
# Installs:
#   • Follow Up Boss MCP (137 tools, API key pre-loaded, Safe Mode on)
#   • Puppeteer MCP (lets Claude open and control Chrome/browser — no extension needed)
# Configures:
#   • Claude Desktop (merges into existing config without overwriting other MCPs)

set -e

# ── Colors ─────────────────────────────────────────────────────────────────────
R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'; B='\033[1;34m'; NC='\033[0m'
ok()   { echo -e "  ${G}✓${NC} $1"; }
warn() { echo -e "  ${Y}⚠${NC}  $1"; }
err()  { echo -e "  ${R}✗${NC} $1"; exit 1; }

echo ""
echo -e "${B}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${B}  Follow Up Boss MCP — Mac Setup${NC}"
echo -e "${B}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ── 1. Check Node.js ───────────────────────────────────────────────────────────
echo "Checking requirements..."
if ! command -v node &>/dev/null; then
  err "Node.js not found. Install from https://nodejs.org (LTS version) then re-run."
fi
NODE_VER=$(node -v | cut -dv -f2 | cut -d. -f1)
if [ "$NODE_VER" -lt 18 ]; then
  err "Node.js 18+ required. You have $(node -v). Update at https://nodejs.org"
fi
ok "Node.js $(node -v)"

# ── 2. Check Git ───────────────────────────────────────────────────────────────
if ! command -v git &>/dev/null; then
  err "Git not found. Run: xcode-select --install"
fi
ok "Git $(git --version | awk '{print $3}')"

# ── 3. Install / update Follow Up Boss MCP server ─────────────────────────────
echo ""
echo "Setting up Follow Up Boss MCP server..."

INSTALL_DIR="$HOME/followupboss-mcp-server"

if [ -d "$INSTALL_DIR/.git" ]; then
  warn "Existing install found — pulling latest updates"
  cd "$INSTALL_DIR"
  git pull origin main --quiet 2>/dev/null || true
else
  echo "  Cloning repository..."
  git clone https://github.com/gwcre-az/followupboss-mcp-server "$INSTALL_DIR" --quiet
  cd "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"
echo "  Installing dependencies..."
npm install --quiet 2>/dev/null
echo "  Applying security patches..."
npm audit fix --quiet 2>/dev/null || true
ok "Dependencies installed and patched"

# ── 4. Write .env with API key ─────────────────────────────────────────────────
cat > "$INSTALL_DIR/.env" <<'ENVEOF'
FUB_API_KEY=fka_0xNZOve5UNDqxFujKafwtnBT40ZGfmzoTR
FUB_SAFE_MODE=true
ENVEOF
ok ".env written (API key + Safe Mode)"

# ── 5. Verify API connection ────────────────────────────────────────────────────
echo ""
echo "Verifying Follow Up Boss connection..."
TEST_OUT=$(npm test --silent 2>&1 || true)
if echo "$TEST_OUT" | grep -q "3 passed"; then
  ok "API connection verified — 137 tools ready"
else
  warn "Test output:"
  echo "$TEST_OUT" | grep -E "(PASS|FAIL|passed|failed|Error)" || echo "$TEST_OUT"
  warn "Check your API key if you see errors. Continuing config setup..."
fi

# ── 6. Configure Claude Desktop ────────────────────────────────────────────────
echo ""
echo "Configuring Claude Desktop..."

node - "$INSTALL_DIR" <<'JSEOF'
const fs   = require('fs');
const path = require('path');
const os   = require('os');

const installDir = process.argv[2];
const configDir  = path.join(os.homedir(), 'Library', 'Application Support', 'Claude');
const configPath = path.join(configDir, 'claude_desktop_config.json');

fs.mkdirSync(configDir, { recursive: true });

// Load existing config (preserve any other MCPs already configured)
let cfg = {};
try {
  cfg = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  process.stdout.write('  Merging with existing Claude Desktop config\n');
} catch(_) {
  process.stdout.write('  Creating new Claude Desktop config\n');
}

cfg.mcpServers = cfg.mcpServers || {};

// Follow Up Boss — 137 tools, API key embedded, Safe Mode on
cfg.mcpServers.followupboss = {
  command: 'node',
  args:    [path.join(installDir, 'index.js')],
  env: {
    FUB_API_KEY:    'fka_0xNZOve5UNDqxFujKafwtnBT40ZGfmzoTR',
    FUB_SAFE_MODE:  'true'
  }
};

// Puppeteer — lets Claude open URLs, read pages, fill forms, click buttons
// in Chrome (no Chrome extension needed — this works at the server level)
cfg.mcpServers.puppeteer = {
  command: 'npx',
  args:    ['-y', '@modelcontextprotocol/server-puppeteer']
};

fs.writeFileSync(configPath, JSON.stringify(cfg, null, 2));
process.stdout.write('  Saved: ' + configPath + '\n');
JSEOF

ok "Claude Desktop configured"

# ── 7. Show final config for reference ─────────────────────────────────────────
CLAUDE_CONFIG="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
echo ""
echo -e "${B}Claude Desktop config (for reference):${NC}"
echo -e "${B}$CLAUDE_CONFIG${NC}"

# ── 8. Done ────────────────────────────────────────────────────────────────────
echo ""
echo -e "${B}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${G}  Setup complete!${NC}"
echo -e "${B}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${Y}  NEXT STEPS — do these in order:${NC}"
echo ""
echo "  1. Quit Claude Desktop completely"
echo "     (Menu bar → Claude → Quit, or Cmd+Q)"
echo ""
echo "  2. Reopen Claude Desktop"
echo ""
echo "  3. Verify it's working — ask Claude:"
echo "     \"Use the about tool to verify Follow Up Boss is connected\""
echo ""
echo "  4. Enable Computer Control (to let Claude operate your Mac):"
echo "     Claude Desktop → Settings → Features → Enable 'Computer use'"
echo ""
echo -e "${Y}  WHAT'S NOW CONNECTED:${NC}"
echo ""
echo "  • Follow Up Boss MCP  — 137 tools (contacts, stages, pipelines,"
echo "    custom fields, tasks, templates, action plans, and more)"
echo "    Safe Mode ON — no accidental deletes"
echo ""
echo "  • Puppeteer MCP — Claude can open Chrome, navigate pages,"
echo "    read content, fill forms, click buttons"
echo "    (no Chrome extension needed)"
echo ""
echo "  • Computer Use — enable in Claude Desktop Settings to let"
echo "    Claude take screenshots and control your Mac directly"
echo ""
